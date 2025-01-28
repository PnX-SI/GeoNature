import pytest
from flask import g
import sqlalchemy as sa
from pathlib import Path

from geonature.core.gn_commons.models import TModules
from geonature.utils.env import db

from geonature.core.imports.models import BibFields, Destination, FieldMapping

tests_path = Path(__file__).parent

# ######################################################################################
# Fixtures -- destination
# ######################################################################################


@pytest.fixture(scope="class")
def module_code():  # provide with a default value - should bve overriden
    return "SYNTHESE"


@pytest.fixture(scope="class")
def testfiles_folder():  # provide with a default value - should bve overriden
    return "synthese"


@pytest.fixture(scope="session")
def default_destination(app):
    """
    This fixture set default destination when not specified in call to url_for.
    """

    @app.url_defaults
    def set_default_destination(endpoint, values):
        if (
            app.url_map.is_endpoint_expecting(endpoint, "destination")
            and "destination" not in values
            and hasattr(g, "default_destination")
        ):
            values["destination"] = g.default_destination.code


@pytest.fixture(scope="class")
def import_destination(module_code):
    return Destination.query.filter(
        Destination.module.has(TModules.module_code == module_code)
    ).one()


@pytest.fixture(scope="class")
def default_import_destination(app, default_destination, import_destination):
    g.default_destination = import_destination
    yield
    del g.default_destination


@pytest.fixture(scope="session")
def list_all_module_dest_code():
    module_code_dest = db.session.scalars(
        sa.select(TModules.module_code).join(
            Destination, Destination.id_module == TModules.id_module
        )
    ).all()
    return module_code_dest


@pytest.fixture(scope="session")
def all_modules_destination(list_all_module_dest_code):

    dict_modules_dest = {}

    for module_code in list_all_module_dest_code:
        query = sa.select(Destination).filter(
            Destination.module.has(TModules.module_code == module_code)
        )

        result = db.session.execute(query).scalar_one()

        dict_modules_dest[module_code] = result

    return dict_modules_dest


# ######################################################################################
# Fixtures -- datasets
# ######################################################################################

from geonature.tests.utils import set_logged_user, unset_logged_user
from flask import g, url_for
from geonature.core.gn_meta.models import TDatasets, TAcquisitionFramework
from pypnnomenclature.models import TNomenclatures, BibNomenclaturesTypes
from geonature.core.imports.models import (
    TImports,
    BibFields,
)


@pytest.fixture()
def import_file_name():
    return "valid_file.csv"


@pytest.fixture()
def import_dataset(import_datasets):
    return import_datasets["user"]


def create_dataset(client, module_code, user, active=True, private=False):
    """ """
    set_logged_user(client, user)

    # Generate acquisition framework
    r_af = client.post(
        url_for("gn_meta.create_acquisition_framework"),
        json={
            "acquisition_framework_name": "import_AF",
            "acquisition_framework_desc": "import_AF description",
        },
    )
    assert r_af.status_code == 200, r_af.data
    new_acquisition_framework = db.session.get(
        TAcquisitionFramework, r_af.get_json()["id_acquisition_framework"]
    )

    # Get module
    r_module = client.get(url_for("gn_commons.get_module", module_code=module_code))
    assert r_module.status_code == 200

    modules = [
        r_module.get_json(),
    ]

    # Get principal actor
    id_principal_actor_role = db.session.execute(
        sa.select(TNomenclatures.id_nomenclature)
        .join(BibNomenclaturesTypes, BibNomenclaturesTypes.mnemonique == "ROLE_ACTEUR")
        .where(
            TNomenclatures.mnemonique == "Contact principal",
        )
    ).scalar_one()
    cor_dataset_actor = [
        {
            "id_nomenclature_actor_role": id_principal_actor_role,
            "id_role": user.id_role,
        }
    ]

    # Get default data origin
    id_nomenclature_data_origin = None
    if private:
        id_nomenclature_data_origin = db.session.execute(
            sa.select(TNomenclatures.id_nomenclature).where(
                TNomenclatures.nomenclature_type.has(
                    BibNomenclaturesTypes.mnemonique == "DS_PUBLIQUE"
                ),
                TNomenclatures.mnemonique == "Privée",
            )
        ).scalar_one()

    # Get territory metropole
    territory_metropole = db.session.execute(
        sa.select(TNomenclatures).where(
            TNomenclatures.nomenclature_type.has(BibNomenclaturesTypes.mnemonique == "TERRITOIRE"),
            TNomenclatures.cd_nomenclature == "METROP",
        )
    ).scalar_one()

    json = {
        "id_acquisition_framework": new_acquisition_framework.id_acquisition_framework,
        "dataset_name": "import_dataset",
        "dataset_shortname": "import_dataset",
        "dataset_desc": "import_dataset description",
        "keywords": None,
        "terrestrial_domain": True,
        "marine_domain": False,
        "id_nomenclature_data_origin": id_nomenclature_data_origin,
        "validable": True,
        "active": active,
        "id_taxa_list": None,
        "modules": modules,
        "cor_territories": [territory_metropole.as_dict()],
        "cor_dataset_actor": cor_dataset_actor,
    }

    response = client.post(
        url_for("gn_meta.create_dataset"),
        json=json,
    )

    return db.session.get(TDatasets, response.get_json()["id_dataset"])


@pytest.fixture()
def import_datasets(client, module_code, users):
    datasets = {
        "user": create_dataset(client, module_code, users["user"]),
        "user--private": create_dataset(client, module_code, users["user"], private=True),
        "user--inactive": create_dataset(client, module_code, users["user"], active=False),
        "admin": create_dataset(client, module_code, users["admin_user"]),
    }
    return datasets


# ######################################################################################
# Fixtures -- fieldmapping
# ######################################################################################


@pytest.fixture()
def fieldmapping_unique_dataset_id(import_dataset):
    None


@pytest.fixture(scope="class")
def fieldmapping_preset_name():
    return "Synthese GeoNature"


@pytest.fixture()
def fieldmapping(
    import_file_name,
    autogenerate,
    import_dataset,
    fieldmapping_unique_dataset_id,
    fieldmapping_preset_name,
):
    fieldmapping = {}
    if fieldmapping_preset_name:
        fieldmapping = (
            db.session.execute(
                sa.select(FieldMapping).filter_by(
                    label=fieldmapping_preset_name,
                )
            )
            .unique()
            .scalar_one()
            .values
        )
    else:
        bib_fields = db.session.scalars(sa.select(BibFields).filter_by(display=True)).unique().all()
        fieldmapping = {
            field.name_field: {
                "column_src": (
                    autogenerate
                    if field.autogenerated
                    else (
                        [field.name_field, "additional_data2"] if field.multi else field.name_field
                    )
                )
            }
            for field in bib_fields
        }

    if fieldmapping_unique_dataset_id:
        fieldmapping["unique_dataset_id"] = fieldmapping_unique_dataset_id

    return fieldmapping


# ######################################################################################
# Fixtures -- contentmapping
# ######################################################################################
from sqlalchemy.orm import joinedload


@pytest.fixture(scope="class")
def contentmapping_preset_name():
    return "Nomenclatures SINP (labels)"


@pytest.fixture(scope="function")
def add_in_contentmapping():
    return {"STADE_VIE": {"": "17"}}  # Alevin


@pytest.fixture(scope="function")
def contentmapping(add_in_contentmapping, import_destination, contentmapping_preset_name):
    contentmapping = {}
    if contentmapping_preset_name is not None:
        contentmapping = (
            db.session.scalars(
                sa.select(ContentMapping).filter_by(label=contentmapping_preset_name)
            )
            .unique()
            .one()
            .values
        )
    else:
        fields = (
            db.session.scalars(
                sa.select(BibFields)
                .filter_by(destination=import_destination, display=True)
                .filter(BibFields.nomenclature_type != None)
                .options(
                    joinedload(BibFields.nomenclature_type).joinedload(
                        BibNomenclaturesTypes.nomenclatures
                    ),
                )
            )
            .unique()
            .all()
        )
        contentmapping = {
            field.nomenclature_type.mnemonique: {
                **{
                    nomenclature.mnemonique: nomenclature.cd_nomenclature
                    for nomenclature in field.nomenclature_type.nomenclatures
                },
                **{
                    nomenclature.cd_nomenclature: nomenclature.cd_nomenclature
                    for nomenclature in field.nomenclature_type.nomenclatures
                },
            }
            for field in fields
        }

    for entry, value in add_in_contentmapping.items():
        if contentmapping[entry]:
            contentmapping[entry].update(value)

    return contentmapping


# ######################################################################################
# Fixtures -- override config value
# ######################################################################################
from apptax.taxonomie.models import BibListes, Taxref


@pytest.fixture()
def small_batch(monkeypatch):
    monkeypatch.setitem(current_app.config["IMPORT"], "DATAFRAME_BATCH_SIZE", 10)


@pytest.fixture
def check_private_jdd(monkeypatch):
    monkeypatch.setitem(current_app.config["IMPORT"], "CHECK_PRIVATE_JDD_BLURING", True)


@pytest.fixture()
def no_default_nomenclatures(monkeypatch):
    monkeypatch.setitem(
        current_app.config["IMPORT"], "FILL_MISSING_NOMENCLATURE_WITH_DEFAULT_VALUE", False
    )


@pytest.fixture()
def area_restriction(monkeypatch, sample_area):
    monkeypatch.setitem(current_app.config["IMPORT"], "ID_AREA_RESTRICTION", sample_area.id_area)


@pytest.fixture(scope="function")
def g_permissions():
    """
    Fixture to initialize flask g variable
    Mandatory if we want to run this test file standalone
    """
    g._permissions_by_user = {}
    g._permissions = {}


@pytest.fixture()
def sample_taxhub_list():
    nom = Taxref.query.filter_by(cd_nom=67111).one()
    with db.session.begin_nested():
        taxa_list = BibListes(nom_liste="test", code_liste="test", noms=[nom])
        db.session.add(taxa_list)
    return taxa_list


@pytest.fixture()
def change_id_list_conf(monkeypatch, sample_taxhub_list):
    monkeypatch.setitem(
        current_app.config["IMPORT"], "ID_LIST_TAXA_RESTRICTION", sample_taxhub_list.id_liste
    )


# ######################################################################################
# Fixtures -- immport
# ######################################################################################


from flask import g, url_for, current_app
from werkzeug.datastructures import Headers
from geonature.core.imports.utils import insert_import_data_in_transient_table
from geonature.core.imports.models import (
    TImports,
    FieldMapping,
    ContentMapping,
    BibFields,
)
from ref_geo.models import LAreas


@pytest.fixture()
def sample_area():
    return LAreas.query.filter(LAreas.area_name == "Bouches-du-Rhône").one()


@pytest.fixture()
def autogenerate():
    return True


@pytest.fixture(scope="function")
def override_in_importfile():
    return {}


@pytest.fixture(scope="class")
def imports(import_destination, users):
    def create_import(authors=[]):
        with db.session.begin_nested():
            imprt = TImports(destination=import_destination, authors=authors)
            db.session.add(imprt)
        return imprt

    return {
        "own_import": create_import(authors=[users["user"]]),
        "associate_import": create_import(authors=[users["associate_user"]]),
        "stranger_import": create_import(authors=[users["stranger_user"]]),
        "orphan_import": create_import(),
    }


@pytest.fixture()
def uploaded_import(client, import_file_name, override_in_importfile, users, testfiles_folder):
    set_logged_user(client, users["user"])

    with open(tests_path / "files" / testfiles_folder / import_file_name, "rb") as f:
        f.seek(0)
        data = {"file": (f, import_file_name)}
        r = client.post(
            url_for("import.upload_file"),
            data=data,
            headers=Headers({"Content-Type": "multipart/form-data"}),
        )
        assert r.status_code == 200, r.data
        imprt = db.session.get(TImports, r.get_json()["id_import"])

    for before, after in override_in_importfile.items():
        imprt.source_file = imprt.source_file.replace(
            before.encode("ascii"),
            after.encode("ascii"),
        )
    return imprt


@pytest.fixture()
def decoded_import(client, uploaded_import):
    set_logged_user(client, uploaded_import.authors[0])
    r = client.post(
        url_for(
            "import.decode_file",
            import_id=uploaded_import.id_import,
        ),
        data={
            "encoding": "utf-8",
            "format": "csv",
            "srid": 4326,
            "separator": ";",
        },
    )
    assert r.status_code == 200, r.data
    unset_logged_user(client)
    db.session.refresh(uploaded_import)
    return uploaded_import


@pytest.fixture()
def field_mapped_import(client, decoded_import, fieldmapping):
    with db.session.begin_nested():
        decoded_import.fieldmapping = fieldmapping
    return decoded_import


@pytest.fixture()
def loaded_import(client, field_mapped_import):
    with db.session.begin_nested():
        field_mapped_import.source_count = insert_import_data_in_transient_table(
            field_mapped_import
        )
        field_mapped_import.loaded = True
    return field_mapped_import


@pytest.fixture()
def content_mapped_import(loaded_import, contentmapping):
    loaded_import.contentmapping = contentmapping
    db.session.flush()
    return loaded_import


@pytest.fixture()
def prepared_import(client, content_mapped_import, small_batch, check_private_jdd):
    set_logged_user(client, content_mapped_import.authors[0])
    r = client.post(url_for("import.prepare_import", import_id=content_mapped_import.id_import))
    assert r.status_code == 200, r.data
    unset_logged_user(client)
    db.session.refresh(content_mapped_import)
    return content_mapped_import


@pytest.fixture()
def imported_import(client, g_permissions, prepared_import):
    set_logged_user(client, prepared_import.authors[0])
    r = client.post(url_for("import.import_valid_data", import_id=prepared_import.id_import))
    assert r.status_code == 200, r.data
    unset_logged_user(client)
    db.session.refresh(prepared_import)
    return prepared_import
