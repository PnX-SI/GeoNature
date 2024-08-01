import codecs
from io import BytesIO, StringIO, TextIOWrapper
import csv
import json
import unicodedata

from flask import request, current_app, jsonify, g, stream_with_context, send_file
from werkzeug.exceptions import Conflict, BadRequest, Forbidden, Gone, NotFound

# url_quote was deprecated in werkzeug 3.0 https://stackoverflow.com/a/77222063/5807438
from urllib.parse import quote as url_quote
from sqlalchemy import or_, func, desc, select, delete
from sqlalchemy.inspection import inspect
from sqlalchemy.orm import joinedload, Load, load_only, undefer, contains_eager
from sqlalchemy.orm.attributes import set_committed_value
from sqlalchemy.sql.expression import collate, exists


from geonature.utils.env import db
from geonature.utils.sentry import start_sentry_child
from geonature.core.gn_permissions import decorators as permissions
from geonature.core.gn_permissions.decorators import login_required
from geonature.core.gn_permissions.tools import get_scopes_by_action
from geonature.core.gn_meta.models import TDatasets

from pypnnomenclature.models import TNomenclatures

from geonature.core.imports.models import (
    Destination,
    Entity,
    EntityField,
    TImports,
    ImportUserError,
    BibFields,
    FieldMapping,
    ContentMapping,
)
from pypnusershub.db.models import User
from geonature.core.imports.blueprint import blueprint
from geonature.core.imports.utils import (
    ImportStep,
    detect_encoding,
    detect_separator,
    insert_import_data_in_transient_table,
    get_file_size,
    clean_import,
    generate_pdf_from_template,
)
from geonature.core.imports.tasks import do_import_checks, do_import_in_destination

IMPORTS_PER_PAGE = 15


@blueprint.url_value_preprocessor
def resolve_import(endpoint, values):
    if current_app.url_map.is_endpoint_expecting(endpoint, "import_id"):
        import_id = values.pop("import_id")
        if import_id is not None:
            imprt = TImports.query.options(
                joinedload(TImports.destination).joinedload(Destination.module)
            ).get_or_404(import_id)
            if imprt.destination != values.pop("destination"):
                raise NotFound
        else:
            imprt = None
        values["imprt"] = imprt


@blueprint.route("/imports/", methods=["GET"])
@blueprint.route("/<destination>/imports/", methods=["GET"])
@permissions.check_cruved_scope("R", get_scope=True, module_code="IMPORT", object_code="IMPORT")
def get_import_list(scope, destination=None):
    """
    .. :quickref: Import; Get all imports.

    Get all imports to which logged-in user has access.
    """
    page = request.args.get("page", default=1, type=int)
    limit = request.args.get("limit", default=IMPORTS_PER_PAGE, type=int)
    search = request.args.get("search", default=None, type=str)
    sort = request.args.get("sort", default="date_create_import", type=str)
    sort_dir = request.args.get("sort_dir", default="desc", type=str)
    filters = []
    if search:
        filters.append(TImports.full_file_name.ilike(f"%{search}%"))
        filters.append(
            TImports.dataset.has(
                func.lower(TDatasets.dataset_name).contains(func.lower(search)),
            )
        )
        filters.append(
            TImports.authors.any(
                or_(
                    User.prenom_role.ilike(f"%{search}%"),
                    User.nom_role.ilike(f"%{search}%"),
                ),
            )
        )
        filters.append(
            TImports.authors.any(
                func.lower(User.nom_role).contains(func.lower(search)),
            )
        )
    try:
        order_by = get_foreign_key_attr(TImports, sort)
        order_by = order_by() if callable(order_by) else order_by
    except AttributeError:
        raise BadRequest(f"Import field '{sort}' does not exist.")
    if sort_dir == "desc":
        order_by = desc(order_by)

    query = (
        TImports.query.options(
            contains_eager(TImports.dataset),
            contains_eager(TImports.authors),
            contains_eager(TImports.destination).load_only(Destination.label, Destination.label),
        )
        .join(TImports.dataset, isouter=True)
        .join(TImports.authors, isouter=True)
        .join(Destination)
        .filter_by_scope(scope)
        .filter(or_(*filters) if len(filters) > 0 else True)
        .order_by(order_by)
    )

    if destination:
        query = query.filter(TImports.destination == destination)

    imports = query.paginate(page=page, error_out=False, max_per_page=limit)

    data = {
        "imports": [imprt.as_dict() for imprt in imports.items],
        "count": imports.total,
        "limit": limit,
        "offset": page - 1,
    }
    return jsonify(data)


@blueprint.route("/<destination>/imports/<int:import_id>/", methods=["GET"])
@permissions.check_cruved_scope("R", get_scope=True, module_code="IMPORT", object_code="IMPORT")
def get_one_import(scope, imprt):
    """
    .. :quickref: Import; Get an import.

    Get an import.
    """
    # check that the user has read permission to this particular import instance:
    if not imprt.has_instance_permission(scope):
        raise Forbidden
    return jsonify(imprt.as_dict())


@blueprint.route("/<destination>/imports/upload", defaults={"import_id": None}, methods=["POST"])
@blueprint.route("/<destination>/imports/<int:import_id>/upload", methods=["PUT"])
@permissions.check_cruved_scope("C", get_scope=True, module_code="IMPORT", object_code="IMPORT")
def upload_file(scope, imprt, destination=None):  # destination is set when imprt is None
    """
    .. :quickref: Import; Add an import or update an existing import.

    Add an import or update an existing import.

    :form file: file to import
    :form int datasetId: dataset ID to which import data
    """
    if imprt:
        if not imprt.has_instance_permission(scope):
            raise Forbidden
        if not imprt.dataset.active:
            raise Forbidden("Le jeu de données est fermé.")
        destination = imprt.destination
    else:
        assert destination
    author = g.current_user
    f = request.files["file"]
    size = get_file_size(f)
    # value in config file is in Mo
    max_file_size = current_app.config["IMPORT"]["MAX_FILE_SIZE"] * 1024 * 1024
    if size > max_file_size:
        raise BadRequest(
            description=f"File too big ({size} > {max_file_size})."
        )  # FIXME better error signaling?
    if size == 0:
        raise BadRequest(description="Impossible to upload empty files")
    if imprt is None:
        try:
            dataset_id = int(request.form["datasetId"])
        except ValueError:
            raise BadRequest(description="'datasetId' must be an integer.")
        dataset = db.session.get(TDatasets, dataset_id)
        if dataset is None:
            raise BadRequest(description=f"Dataset '{dataset_id}' does not exist.")
        ds_scope = get_scopes_by_action(
            module_code=destination.module.module_code,
            object_code="ALL",  # TODO object_code should be configurable by destination
        )["C"]
        if not dataset.has_instance_permission(ds_scope):
            raise Forbidden(description="Vous n’avez pas les permissions sur ce jeu de données.")
        if not dataset.active:
            raise Forbidden("Le jeu de données est fermé.")
        imprt = TImports(destination=destination, dataset=dataset)
        imprt.authors.append(author)
        db.session.add(imprt)
    else:
        clean_import(imprt, ImportStep.UPLOAD)
    with start_sentry_child(op="task", description="detect encoding"):
        imprt.detected_encoding = detect_encoding(f)
    with start_sentry_child(op="task", description="detect separator"):
        imprt.detected_separator = detect_separator(
            f,
            encoding=imprt.encoding or imprt.detected_encoding,
        )
    imprt.source_file = f.read()
    imprt.full_file_name = f.filename

    db.session.commit()
    return jsonify(imprt.as_dict())


@blueprint.route("/<destination>/imports/<int:import_id>/decode", methods=["POST"])
@permissions.check_cruved_scope("C", get_scope=True, module_code="IMPORT", object_code="IMPORT")
def decode_file(scope, imprt):
    if not imprt.has_instance_permission(scope):
        raise Forbidden
    if not imprt.dataset.active:
        raise Forbidden("Le jeu de données est fermé.")
    if imprt.source_file is None:
        raise BadRequest(description="A file must be first uploaded.")
    if "encoding" not in request.json:
        raise BadRequest(description="Missing encoding.")
    encoding = request.json["encoding"]
    try:
        codecs.lookup(encoding)
    except LookupError:
        raise BadRequest(description="Unknown encoding.")
    imprt.encoding = encoding
    if "format" not in request.json:
        raise BadRequest(description="Missing format.")
    if request.json["format"] not in TImports.AVAILABLE_FORMATS:
        raise BadRequest(description="Unknown format.")
    imprt.format_source_file = request.json["format"]
    if "srid" not in request.json:
        raise BadRequest(description="Missing srid.")
    try:
        imprt.srid = int(request.json["srid"])
    except ValueError:
        raise BadRequest(description="SRID must be an integer.")
    if "separator" not in request.json:
        raise BadRequest(description="Missing separator")
    if request.json["separator"] not in TImports.AVAILABLE_SEPARATORS:
        raise BadRequest(description="Unknown separator")
    imprt.separator = request.json["separator"]

    clean_import(imprt, ImportStep.DECODE)

    db.session.commit()  # commit parameters

    decode = request.args.get("decode", 1)
    try:
        decode = int(decode)
    except ValueError:
        raise BadRequest(description="decode parameter must but an int")
    if decode:
        csvfile = TextIOWrapper(BytesIO(imprt.source_file), encoding=imprt.encoding)
        csvreader = csv.reader(csvfile, delimiter=imprt.separator)
        try:
            columns = next(csvreader)
            while True:  # read full file to ensure that no encoding errors occur
                next(csvreader)
        except UnicodeError:
            raise BadRequest(
                description="Erreur d’encodage lors de la lecture du fichier source. "
                "Avez-vous sélectionné le bon encodage de votre fichier ?"
            )
        except StopIteration:
            pass
        duplicates = set([col for col in columns if columns.count(col) > 1])
        if duplicates:
            raise BadRequest(f"Duplicates column names: {duplicates}")
        imprt.columns = columns
        db.session.commit()

    return jsonify(imprt.as_dict())


@blueprint.route("/<destination>/imports/<int:import_id>/fieldmapping", methods=["POST"])
@permissions.check_cruved_scope("C", get_scope=True, module_code="IMPORT", object_code="IMPORT")
def set_import_field_mapping(scope, imprt):
    if not imprt.has_instance_permission(scope):
        raise Forbidden
    if not imprt.dataset.active:
        raise Forbidden("Le jeu de données est fermé.")
    try:
        FieldMapping.validate_values(request.json)
    except ValueError as e:
        raise BadRequest(*e.args)
    imprt.fieldmapping = request.json
    clean_import(imprt, ImportStep.LOAD)
    db.session.commit()
    return jsonify(imprt.as_dict())


@blueprint.route("/<destination>/imports/<int:import_id>/load", methods=["POST"])
@permissions.check_cruved_scope("C", get_scope=True, module_code="IMPORT", object_code="IMPORT")
def load_import(scope, imprt):
    if not imprt.has_instance_permission(scope):
        raise Forbidden
    if not imprt.dataset.active:
        raise Forbidden("Le jeu de données est fermé.")
    if imprt.source_file is None:
        raise BadRequest(description="A file must be first uploaded.")
    if imprt.fieldmapping is None:
        raise BadRequest(description="File fields must be first mapped.")
    clean_import(imprt, ImportStep.LOAD)
    with start_sentry_child(op="task", description="insert data in db"):
        line_no = insert_import_data_in_transient_table(imprt)
    if not line_no:
        raise BadRequest("File with 0 lines.")
    imprt.source_count = line_no
    imprt.loaded = True
    db.session.commit()
    return jsonify(imprt.as_dict())


@blueprint.route("/<destination>/imports/<int:import_id>/columns", methods=["GET"])
@permissions.check_cruved_scope("R", get_scope=True, module_code="IMPORT", object_code="IMPORT")
def get_import_columns_name(scope, imprt):
    """
    .. :quickref: Import;

    Return all the columns of the file of an import
    """
    if not imprt.has_instance_permission(scope):
        raise Forbidden
    if not imprt.columns:
        raise Conflict(description="Data have not been decoded.")
    return jsonify(imprt.columns)


@blueprint.route("/<destination>/imports/<int:import_id>/values", methods=["GET"])
@permissions.check_cruved_scope("R", get_scope=True, module_code="IMPORT", object_code="IMPORT")
def get_import_values(scope, imprt):
    """
    .. :quickref: Import;

    Return all values present in imported file for nomenclated fields
    """
    # check that the user has read permission to this particular import instance:
    if not imprt.has_instance_permission(scope):
        raise Forbidden
    if not imprt.loaded:
        raise Conflict(description="Data have not been loaded")
    nomenclated_fields = (
        BibFields.query.filter(BibFields.mnemonique != None)
        .filter(BibFields.destination == imprt.destination)
        .options(joinedload(BibFields.nomenclature_type))
        .order_by(BibFields.id_field)
        .all()
    )
    # Note: response format is validated with jsonschema in tests
    transient_table = imprt.destination.get_transient_table()
    response = {}
    for field in nomenclated_fields:
        if field.name_field not in imprt.fieldmapping:
            # this nomenclated field is not mapped
            continue
        source = imprt.fieldmapping[field.name_field]
        if source not in imprt.columns:
            # the file do not contain this field expected by the mapping
            continue
        # TODO: vérifier que l’on a pas trop de valeurs différentes ?
        column = field.source_column
        values = [
            value
            for value, in db.session.execute(
                select(transient_table.c[column])
                .where(transient_table.c.id_import == imprt.id_import)
                .distinct(transient_table.c[column])
            ).fetchall()
        ]
        set_committed_value(
            field.nomenclature_type,
            "nomenclatures",
            TNomenclatures.query.filter_by(nomenclature_type=field.nomenclature_type).order_by(
                collate(TNomenclatures.cd_nomenclature, "fr_numeric")
            ),
        )
        response[field.name_field] = {
            "nomenclature_type": field.nomenclature_type.as_dict(),
            "nomenclatures": [n.as_dict() for n in field.nomenclature_type.nomenclatures],
            "values": values,
        }
    return jsonify(response)


@blueprint.route("/<destination>/imports/<int:import_id>/contentmapping", methods=["POST"])
@permissions.check_cruved_scope("C", get_scope=True, module_code="IMPORT", object_code="IMPORT")
def set_import_content_mapping(scope, imprt):
    if not imprt.has_instance_permission(scope):
        raise Forbidden
    if not imprt.dataset.active:
        raise Forbidden("Le jeu de données est fermé.")
    try:
        ContentMapping.validate_values(request.json)
    except ValueError as e:
        raise BadRequest(*e.args)
    imprt.contentmapping = request.json
    clean_import(imprt, ImportStep.PREPARE)
    db.session.commit()
    return jsonify(imprt.as_dict())


@blueprint.route("/<destination>/imports/<int:import_id>/prepare", methods=["POST"])
@permissions.check_cruved_scope("C", get_scope=True, module_code="IMPORT", object_code="IMPORT")
def prepare_import(scope, imprt):
    """
    Prepare data to be imported: apply all checks and transformations.
    """
    if not imprt.has_instance_permission(scope):
        raise Forbidden
    if not imprt.dataset.active:
        raise Forbidden("Le jeu de données est fermé.")

    # Check preconditions to execute this action
    if not imprt.loaded:
        raise Conflict("Field data must have been loaded before executing this action.")

    # Remove previous errors
    clean_import(imprt, ImportStep.PREPARE)

    # Run background import checks
    sig = do_import_checks.s(imprt.id_import)
    task = sig.freeze()
    imprt.task_id = task.task_id
    db.session.commit()
    sig.delay()

    return jsonify(imprt.as_dict())


@blueprint.route("/<destination>/imports/<int:import_id>/preview_valid_data", methods=["GET"])
@permissions.check_cruved_scope("C", get_scope=True, module_code="IMPORT", object_code="IMPORT")
def preview_valid_data(scope, imprt):
    """Preview valid data for a given import.
    Parameters
    ----------
    scope : int
        The scope of the (C, "IMPORT", "IMPORT") permission for the current user.
    imprt : geonature.core.imports.models.TImports
        The import object.
    Returns
    -------
    flask.wrappers.Response
        A JSON response containing valid data, entities, columns, and data statistics.
    Raises
    ------
    Forbidden
        If the current user has no sufficient permission given the scope and the import object.
    Conflict
        If the import is not processed, i.e. it has not been prepared yet.
    """
    if not imprt.has_instance_permission(scope):
        raise Forbidden
    if not imprt.processed:
        raise Conflict("Import must have been prepared before executing this action.")

    data = {
        "valid_bbox": imprt.destination.import_mixin.compute_bounding_box(imprt),
        "entities": [],
    }

    # Retrieve data for each entity from entries in the transient table which are related to the import
    transient_table = imprt.destination.get_transient_table()
    for entity in (
        Entity.query.filter_by(destination=imprt.destination).order_by(Entity.order).all()
    ):
        fields = BibFields.query.filter(
            BibFields.entities.any(EntityField.entity == entity),
            BibFields.dest_field != None,
            BibFields.name_field.in_(imprt.fieldmapping.keys()),
        ).all()
        columns = [{"prop": field.dest_column, "name": field.name_field} for field in fields]
        valid_data = db.session.execute(
            select(*[transient_table.c[field.dest_column] for field in fields])
            .where(transient_table.c.id_import == imprt.id_import)
            .where(transient_table.c[entity.validity_column] == True)
            .limit(100)
        ).fetchall()
        n_valid_data = db.session.execute(
            select(func.count())
            .select_from(transient_table)
            .where(transient_table.c.id_import == imprt.id_import)
            .where(transient_table.c[entity.validity_column] == True)
        ).scalar()
        n_invalid_data = db.session.execute(
            select(func.count())
            .select_from(transient_table)
            .where(transient_table.c.id_import == imprt.id_import)
            .where(transient_table.c[entity.validity_column] == False)
        ).scalar()
        data["entities"].append(
            {
                "entity": entity.as_dict(),
                "columns": columns,
                "valid_data": valid_data,
                "n_valid_data": n_valid_data,
                "n_invalid_data": n_invalid_data,
            }
        )
    return jsonify(data)


@blueprint.route("/<destination>/imports/<int:import_id>/errors", methods=["GET"])
@permissions.check_cruved_scope("R", get_scope=True, module_code="IMPORT", object_code="IMPORT")
def get_import_errors(scope, imprt):
    """
    .. :quickref: Import; Get errors of an import.

    Get errors of an import.
    """
    if not imprt.has_instance_permission(scope):
        raise Forbidden
    return jsonify([error.as_dict(fields=["type", "entity"]) for error in imprt.errors])


@blueprint.route("/<destination>/imports/<int:import_id>/source_file", methods=["GET"])
@permissions.check_cruved_scope("R", get_scope=True, module_code="IMPORT", object_code="IMPORT")
def get_import_source_file(scope, imprt):
    if not imprt.has_instance_permission(scope):
        raise Forbidden
    if imprt.source_file is None:
        raise Gone
    return send_file(
        BytesIO(imprt.source_file),
        download_name=imprt.full_file_name,
        as_attachment=True,
        mimetype=f"text/csv; charset={imprt.encoding}; header=present",
    )


@blueprint.route("/<destination>/imports/<int:import_id>/invalid_rows", methods=["GET"])
@permissions.check_cruved_scope("R", get_scope=True, module_code="IMPORT", object_code="IMPORT")
def get_import_invalid_rows_as_csv(scope, imprt):
    """
    .. :quickref: Import; Get invalid rows of an import as CSV.

    Export invalid data in CSV.
    """
    if not imprt.has_instance_permission(scope):
        raise Forbidden
    if not imprt.processed:
        raise Conflict("Import must have been prepared before executing this action.")

    filename = imprt.full_file_name.rsplit(".", 1)[0]  # remove extension
    filename = f"{filename}_errors.csv"

    @stream_with_context
    def generate_invalid_rows_csv():
        sourcefile = TextIOWrapper(BytesIO(imprt.source_file), encoding=imprt.encoding)
        destfile = StringIO()
        csvreader = csv.reader(sourcefile, delimiter=imprt.separator)
        csvwriter = csv.writer(destfile, dialect=csvreader.dialect, lineterminator="\n")
        line_no = 1
        for row in csvreader:
            # line_no == 1 → csv header
            if line_no == 1 or line_no in imprt.erroneous_rows:
                csvwriter.writerow(row)
                destfile.seek(0)
                yield destfile.read().encode(imprt.encoding)
                destfile.seek(0)
                destfile.truncate()
            line_no += 1

    response = current_app.response_class(
        generate_invalid_rows_csv(),
        mimetype=f"text/csv; charset={imprt.encoding}; header=present",
    )
    try:
        filename.encode("ascii")
    except UnicodeEncodeError:
        simple = unicodedata.normalize("NFKD", filename)
        simple = simple.encode("ascii", "ignore").decode("ascii")
        quoted = url_quote(filename, safe="")
        names = {"filename": simple, "filename*": f"UTF-8''{quoted}"}
    else:
        names = {"filename": filename}
    response.headers.set("Content-Disposition", "attachment", **names)
    return response


@blueprint.route("/<destination>/imports/<int:import_id>/import", methods=["POST"])
@permissions.check_cruved_scope("C", get_scope=True, module_code="IMPORT", object_code="IMPORT")
def import_valid_data(scope, imprt):
    """
    .. :quickref: Import; Import the valid data.

    Import valid data in destination table.
    """
    if not imprt.has_instance_permission(scope):
        raise Forbidden
    if not imprt.dataset.active:
        raise Forbidden("Le jeu de données est fermé.")
    if not imprt.processed:
        raise Forbidden("L’import n’a pas été préalablement vérifié.")
    transient_table = imprt.destination.get_transient_table()
    if not db.session.execute(
        select(
            exists()
            .where(transient_table.c.id_import == imprt.id_import)
            .where(or_(*[transient_table.c[v] == True for v in imprt.destination.validity_columns]))
        )
    ).scalar():
        raise BadRequest("Not valid data to import")

    clean_import(imprt, ImportStep.IMPORT)

    sig = do_import_in_destination.s(imprt.id_import)
    task = sig.freeze()
    imprt.task_id = task.task_id
    db.session.commit()
    sig.delay()

    return jsonify(imprt.as_dict())


@blueprint.route("/<destination>/imports/<int:import_id>/", methods=["DELETE"])
@permissions.check_cruved_scope("D", get_scope=True, module_code="IMPORT", object_code="IMPORT")
def delete_import(scope, imprt):
    """
    .. :quickref: Import; Delete an import.

    Delete an import.
    """
    if not imprt.has_instance_permission(scope):
        raise Forbidden
    if not imprt.dataset.active:
        raise Forbidden("Le jeu de données est fermé.")
    ImportUserError.query.filter_by(imprt=imprt).delete()
    transient_table = imprt.destination.get_transient_table()
    db.session.execute(
        delete(transient_table).where(transient_table.c.id_import == imprt.id_import)
    )
    imprt.destination.import_mixin.remove_data_from_destination(imprt)
    db.session.delete(imprt)
    db.session.commit()
    return jsonify()


@blueprint.route("/<destination>/export_pdf/<int:import_id>", methods=["POST"])
@permissions.check_cruved_scope("R", get_scope=True, module_code="IMPORT", object_code="IMPORT")
def export_pdf(scope, imprt):
    """
    Downloads the report in pdf format
    """
    if not imprt.has_instance_permission(scope):
        raise Forbidden
    ctx = imprt.as_dict(
        fields=[
            "errors",
            "errors.type",
            "errors.entity",
            "dataset.dataset_name",
            "destination.statistics_labels",
        ]
    )

    ctx["map"] = request.form.get("map")
    if ctx["map"] == "undefined":
        ctx["map"] = None

    ctx["chart"] = request.form.get("chart")
    url_list = [
        current_app.config["URL_APPLICATION"],
        "#",
        current_app.config["IMPORT"].get("MODULE_URL", "").replace("/", ""),
        str(ctx["id_import"]),
        "report",
    ]
    ctx["url"] = "/".join(url_list)

    ctx["statistics_formated"] = {}

    for label_dict in ctx["destination"]["statistics_labels"]:
        key = label_dict["value"]
        if label_dict["key"] in ctx["statistics"]:
            ctx["statistics_formated"][key] = ctx["statistics"][label_dict["key"]]

    pdf_file = generate_pdf_from_template("import_template_pdf.html", ctx)
    return send_file(
        BytesIO(pdf_file),
        mimetype="application/pdf",
        as_attachment=True,
        download_name="rapport.pdf",
    )


def get_foreign_key_attr(obj, field: str):
    """
    Go through a object path to find the class to order on
    """
    elems = dict(inspect(obj).relationships.items())
    fields = field.split(".")
    if len(fields) == 1:
        return getattr(obj, fields[0], "")
    else:
        first_field = fields[0]
        remaining_fields = ".".join(fields[1:])
        return get_foreign_key_attr(elems[first_field].mapper.class_, remaining_fields)


@blueprint.route("/<destination>/report_plot/<int:import_id>", methods=["GET"])
@permissions.check_cruved_scope("R", get_scope=True, module_code="IMPORT", object_code="IMPORT")
def report_plot(scope, imprt: TImports):

    return json.dumps(imprt.destination.import_mixin.report_plot(imprt))
