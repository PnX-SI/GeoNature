import json
import datetime
import tempfile
from warnings import warn

from PIL import Image
import pytest
from flask import testing, url_for, current_app
from werkzeug.datastructures import Headers
from sqlalchemy import func
from shapely.geometry import Point
from geoalchemy2.shape import from_shape

from geonature import create_app
from geonature.utils.env import db
from geonature.core.gn_permissions.models import (
    PermFilterType,
    PermAction,
    PermObject,
    Permission,
)
from geonature.core.gn_commons.models import TModules, TMedias, BibTablesLocation
from geonature.core.gn_meta.models import (
    TAcquisitionFramework,
    TDatasets,
    CorDatasetActor,
    CorAcquisitionFrameworkActor,
)
from geonature.core.gn_synthese.models import (
    TSources,
    Synthese,
    TReport,
    BibReportsTypes,
    corAreaSynthese,
)
from geonature.core.sensitivity.models import SensitivityRule, cor_sensitivity_area

from pypnusershub.db.models import (
    User,
    Organisme,
    Application,
    Profils as Profil,
    UserApplicationRight,
)
from pypnnomenclature.models import TNomenclatures, BibNomenclaturesTypes
from apptax.taxonomie.models import (
    Taxref,
    TaxrefBdcStatutTaxon,
    TaxrefBdcStatutCorTextValues,
    bdc_statut_cor_text_area,
    TaxrefBdcStatutText,
)
from ref_geo.models import LAreas, BibAreasTypes

from utils_flask_sqla.tests.utils import JSONClient

import sqlalchemy as sa


__all__ = [
    "datasets",
    "acquisition_frameworks",
    "synthese_data",
    "synthese_sensitive_data",
    "source",
    "reports_data",
    "medium",
    "module",
    "perm_object",
    "notifications_enabled",
    "celery_eager",
    "sources_modules",
    "modules",
]


class GeoNatureClient(JSONClient):
    def open(self, *args, **kwargs):
        assert not (
            db.session.new | db.session.dirty | db.session.deleted
        ), "Call db.session.flush() to make your db changes visible before calling any routes"
        response = super().open(*args, **kwargs)
        if response.status_code == 200:
            if db.session.new | db.session.dirty | db.session.deleted:
                warn(
                    f"Route returned 200 with uncommited changes: new: {db.session.new} – dirty: {db.session.dirty} – deleted: {db.session.deleted}"
                )
        else:
            for obj in db.session.new:
                db.session.expunge(obj)
            # Note: we re-add deleted objects **before** expiring dirty objects,
            # because deleted objects may have been also modified.
            for obj in db.session.deleted:
                db.session.add(obj)
            for obj in db.session.dirty:
                db.session.expire(obj)
        return response


@pytest.fixture(scope="session", autouse=True)
def app():
    app = create_app()
    app.testing = True
    app.test_client_class = GeoNatureClient
    app.config["SERVER_NAME"] = "test.geonature.fr"  # required by url_for

    with app.app_context():
        """
        Note: This may seem redundant with 'temporary_transaction' fixture.
        It is not as 'temporary_transaction' has a function scope.
        This nested transaction is useful to rollback class-scoped fixtures.
        Note: As we does not have a complex savepoint restart mechanism here,
        fixtures must commit their database changes in a nested transaction
        (i.e. in a with db.session.begin_nested() block).
        """
        transaction = db.session.begin_nested()  # execute tests in a savepoint
        yield app
        transaction.rollback()  # rollback all database changes


def create_module(module_code, module_label, module_path, active_frontend, active_backend):
    return TModules(
        module_code=module_code,
        module_label=module_label,
        module_path=module_path,
        active_frontend=active_frontend,
        active_backend=active_backend,
    )


@pytest.fixture()
def modules():
    dict_module_to_create = {
        0: {
            "module_code": "MODULE_TEST_1",
            "module_label": "module_test_1",
            "module_path": "module_test_1",
            "active_frontend": True,
            "active_backend": True,
        },
        1: {
            "module_code": "MODULE_TEST_2",
            "module_label": "module_test_2",
            "module_path": "module_test_2",
            "active_frontend": True,
            "active_backend": True,
        },
    }
    modules = []
    for key, module in dict_module_to_create.items():
        modules.append(
            create_module(
                module["module_code"],
                module["module_label"],
                module["module_path"],
                module["active_frontend"],
                module["active_backend"],
            )
        )
    with db.session.begin_nested():
        db.session.add_all(modules)
    return modules


@pytest.fixture(scope="function")
def module(users):
    other_module = TModules.query.filter_by(module_code="GEONATURE").one()
    with db.session.begin_nested():
        new_module = create_module("MODULE_1", "module_1", "module_1", True, False)
        db.session.add(new_module)
    # Copy perission from another module
    with db.session.begin_nested():
        for perm in Permission.query.filter_by(id_module=other_module.id_module):
            new_perm = Permission(
                id_role=perm.id_role,
                id_action=perm.id_action,
                id_module=new_module.id_module,
                id_object=perm.id_object,
                scope_value=perm.scope_value,
            )
            db.session.add(new_perm)
    return new_module


@pytest.fixture(scope="function")
def perm_object():
    with db.session.begin_nested():
        new_object = PermObject(code_object="TEST_OBJECT")
        db.session.add(new_object)
    return new_object


@pytest.fixture(scope="session")
def users(app):
    app = Application.query.filter(Application.code_application == "GN").one()
    profil = Profil.query.filter(Profil.nom_profil == "Lecteur").one()

    modules = TModules.query.all()

    actions = {code: PermAction.query.filter_by(code_action=code).one() for code in "CRUVED"}

    def create_user(username, organisme=None, scope=None, sensitivity_filter=False, **kwargs):
        # do not commit directly on current transaction, as we want to rollback all changes at the end of tests
        with db.session.begin_nested():
            user = User(
                groupe=False, active=True, identifiant=username, password=username, **kwargs
            )
            db.session.add(user)
            user.organisme = organisme
        # user must have been commited for user.id_role to be defined
        with db.session.begin_nested():
            # login right
            right = UserApplicationRight(
                id_role=user.id_role, id_application=app.id_application, id_profil=profil.id_profil
            )
            db.session.add(right)
            if scope > 0:
                object_all = PermObject.query.filter_by(code_object="ALL").one()
                for action in actions.values():
                    for module in modules:
                        for obj in [object_all] + module.objects:
                            permission = Permission(
                                action=action,
                                module=module,
                                object=obj,
                                scope_value=scope if scope != 3 else None,
                                sensitivity_filter=sensitivity_filter,
                            )
                            db.session.add(permission)
                            permission.role = user
        return user

    users = {}

    organisme = Organisme(nom_organisme="test imports")
    db.session.add(organisme)

    users_to_create = [
        (("noright_user", organisme, 0), {}),
        (("stranger_user", None, 2), {}),
        (("associate_user", organisme, 2), {}),
        (("self_user", organisme, 1), {}),
        (("user", organisme, 2), {"nom_role": "Bob", "prenom_role": "Bobby"}),
        (("admin_user", organisme, 3), {}),
        (("associate_user_2_exclude_sensitive", organisme, 2, True), {}),
    ]

    for (username, *args), kwargs in users_to_create:
        users[username] = create_user(username, *args)

    return users


@pytest.fixture
def _session(app):
    return db.session


@pytest.fixture
def celery_eager(app):
    from geonature.utils.celery import celery_app

    old_eager = celery_app.conf.task_always_eager
    celery_app.conf.task_always_eager = True
    yield
    celery_app.conf.task_always_eager = old_eager


@pytest.fixture(scope="function")
def acquisition_frameworks(users):
    # principal_actor_role = TNomenclatures.query.filter(
    #     BibNomenclaturesTypes.mnemonique == "ROLE_ACTEUR"
    #     TNomenclatures.mnemonique == "Contact principal",
    # ).one()
    principal_actor_role = (
        db.session.query(TNomenclatures)
        .join(BibNomenclaturesTypes, BibNomenclaturesTypes.mnemonique == "ROLE_ACTEUR")
        .filter(
            TNomenclatures.mnemonique == "Contact principal",
        )
        .one()
    )

    def create_af(name, creator):
        with db.session.begin_nested():
            af = TAcquisitionFramework(
                acquisition_framework_name=name,
                acquisition_framework_desc=name,
                creator=creator,
            )
            db.session.add(af)
            if creator and creator.organisme:
                actor = CorAcquisitionFrameworkActor(
                    organism=creator.organisme, nomenclature_actor_role=principal_actor_role
                )
                af.cor_af_actor.append(actor)
        return af

    afs = {
        name: create_af(name=name, creator=creator)
        for name, creator in [
            ("own_af", users["user"]),
            ("associate_af", users["associate_user"]),
            ("stranger_af", users["stranger_user"]),
            ("orphan_af", None),
            ("af_1", None),
            ("af_2", None),
            ("af_3", None),
        ]
    }

    return afs


@pytest.fixture(scope="function")
def datasets(users, acquisition_frameworks, module):
    principal_actor_role = db.session.execute(
        db.select(TNomenclatures)
        .join(BibNomenclaturesTypes, TNomenclatures.id_type == BibNomenclaturesTypes.id_type)
        .filter(
            TNomenclatures.mnemonique == "Contact principal",
            BibNomenclaturesTypes.mnemonique == "ROLE_ACTEUR",
        )
    ).scalar_one()

    # add module code in the list to associate them to datasets
    writable_module_code = ["OCCTAX"]
    writable_module = TModules.query.filter(TModules.module_code.in_(writable_module_code)).all()

    def create_dataset(name, id_af, digitizer=None, modules=writable_module):
        with db.session.begin_nested():
            dataset = TDatasets(
                id_acquisition_framework=id_af,
                dataset_name=name,
                dataset_shortname=name,
                dataset_desc="lorem ipsum" * 22,
                marine_domain=True,
                terrestrial_domain=True,
                id_digitizer=digitizer.id_role if digitizer else None,
            )
            if digitizer and digitizer.organisme:
                actor = CorDatasetActor(
                    organism=digitizer.organisme, nomenclature_actor_role=principal_actor_role
                )
                dataset.cor_dataset_actor.append(actor)

            db.session.add(dataset)
            db.session.flush()  # Required to retrieve ids of created object
            [dataset.modules.append(m) for m in modules]
        return dataset

    af = acquisition_frameworks["orphan_af"]
    af_1 = acquisition_frameworks["af_1"]
    af_2 = acquisition_frameworks["af_2"]
    af_3 = acquisition_frameworks["af_3"]

    datasets = {
        name: create_dataset(name, id_af, digitizer)
        for name, id_af, digitizer in [
            ("own_dataset", af.id_acquisition_framework, users["user"]),
            ("associate_dataset", af.id_acquisition_framework, users["associate_user"]),
            ("stranger_dataset", af.id_acquisition_framework, users["stranger_user"]),
            ("orphan_dataset", af.id_acquisition_framework, None),
            ("belong_af_1", af_1.id_acquisition_framework, users["stranger_user"]),
            ("belong_af_2", af_2.id_acquisition_framework, users["stranger_user"]),
            ("belong_af_3", af_3.id_acquisition_framework, users["stranger_user"]),
            (
                "associate_2_dataset_sensitive",
                af.id_acquisition_framework,
                users["associate_user_2_exclude_sensitive"],
            ),
        ]
    }
    datasets["with_module_1"] = create_dataset(
        name="module_1_dataset",
        id_af=af_1.id_acquisition_framework,
        modules=[module],
    )
    return datasets


@pytest.fixture()
def source():
    with db.session.begin_nested():
        source = TSources(name_source="Fixture", desc_source="Synthese data from fixture")
        db.session.add(source)
    return source


@pytest.fixture()
def sources_modules(modules):
    sources = []
    for name_source, module in [("source test 1", modules[0]), ("source test 2", modules[1])]:
        sources.append(TSources(name_source=name_source, module=module))
    with db.session.begin_nested():
        db.session.add_all(sources)
    return sources


def create_synthese(
    geom, taxon, user, dataset, source, uuid=func.uuid_generate_v4(), cor_observers=[], **kwargs
):
    now = datetime.datetime.now()

    return Synthese(
        id_source=source.id_source,
        id_module=source.id_module,
        unique_id_sinp=uuid,
        dataset=dataset,
        digitiser=user,
        nom_cite=taxon.lb_nom,
        cd_nom=taxon.cd_nom,
        cd_hab=3,
        the_geom_4326=geom,
        the_geom_point=geom,
        the_geom_local=func.ST_Transform(geom, 2154),  # FIXME
        date_min=now,
        date_max=now,
        cor_observers=cor_observers,
        **kwargs,
    )


@pytest.fixture()
def synthese_data(app, users, datasets, source, sources_modules):
    point1 = Point(5.92, 45.56)
    point2 = Point(-1.54, 46.85)
    point3 = Point(-3.486786, 48.832182)
    data = {}
    with db.session.begin_nested():
        for name, cd_nom, point, ds, comment_description, source_m in [
            ("obs1", 713776, point1, datasets["own_dataset"], "obs1", sources_modules[0]),
            ("obs2", 212, point2, datasets["own_dataset"], "obs2", sources_modules[0]),
            ("obs3", 2497, point3, datasets["own_dataset"], "obs3", sources_modules[1]),
            ("p1_af1", 713776, point1, datasets["belong_af_1"], "p1_af1", sources_modules[1]),
            ("p1_af1_2", 212, point1, datasets["belong_af_1"], "p1_af1_2", sources_modules[1]),
            ("p1_af2", 212, point1, datasets["belong_af_2"], "p1_af2", sources_modules[1]),
            ("p2_af2", 2497, point2, datasets["belong_af_2"], "p2_af2", source),
            ("p2_af1", 2497, point2, datasets["belong_af_1"], "p2_af1", source),
            ("p3_af3", 2497, point3, datasets["belong_af_3"], "p3_af3", source),
        ]:
            unique_id_sinp = (
                "f4428222-d038-40bc-bc5c-6e977bbbc92b" if not data else func.uuid_generate_v4()
            )
            geom = from_shape(point, srid=4326)
            taxon = Taxref.query.filter_by(cd_nom=cd_nom).one()
            kwargs = {}
            kwargs["comment_description"] = comment_description
            s = create_synthese(
                geom,
                taxon,
                users["self_user"],
                ds,
                source_m,
                unique_id_sinp,
                [users["admin_user"], users["user"]],
                **kwargs,
            )
            db.session.add(s)
            data[name] = s
    return data


@pytest.fixture()
def synthese_sensitive_data(app, users, datasets, source):
    data = {}

    sensitive_area, sensitive_area_centroid = db.session.execute(
        sa.select(LAreas, func.ST_Centroid(LAreas.geom_4326)).where(
            LAreas.area_type.has(BibAreasTypes.type_code == "DEP"),
            LAreas.area_code == "03",
        )  # Allier
    ).one()
    unsensitive_area, unsensitive_area_centroid = db.session.execute(
        sa.select(LAreas, func.ST_Centroid(LAreas.geom_4326)).where(
            LAreas.area_type.has(BibAreasTypes.type_code == "DEP"),
            LAreas.area_code == "01",
        )  # Ain
    ).one()

    sensitive_protected_taxon = Taxref.query.filter_by(cd_nom=139).one()  # Triton crété
    sensitivity_rule = SensitivityRule.query.filter(
        SensitivityRule.cd_nom == sensitive_protected_taxon.cd_nom,
        SensitivityRule.areas.any(LAreas.id_area == sensitive_area.id_area),
        SensitivityRule.nomenclature_sensitivity.has(
            TNomenclatures.cd_nomenclature == "2"
        ),  # diffusion à la maille 10
    ).first()
    assert sensitivity_rule, "Le référentiel de sensibilité ne convient pas aux tests"
    assert (
        sensitivity_rule.criterias == []
    ), "Le référentiel de sensibilité ne convient pas aux tests"

    unsensitive_protected_taxon = Taxref.query.filter_by(cd_nom=64357).one()  # Datte de mer
    sensitivity_rule = SensitivityRule.query.filter(
        SensitivityRule.cd_nom == sensitive_protected_taxon.cd_nom,
        SensitivityRule.areas.any(LAreas.id_area == unsensitive_area.id_area),
    ).first()
    assert sensitivity_rule is None, "Le référentiel de sensibilité ne convient pas aux tests"

    for name, taxon, geom, ds in [
        (
            "obs_sensitive_protected",
            sensitive_protected_taxon,
            sensitive_area_centroid,
            datasets["own_dataset"],
        ),
        (
            "obs_protected_not_sensitive",
            unsensitive_protected_taxon,
            unsensitive_area_centroid,
            datasets["own_dataset"],
        ),
        (
            "obs_sensitive_protected_2",
            sensitive_protected_taxon,
            sensitive_area_centroid,
            datasets["associate_2_dataset_sensitive"],
        ),
    ]:
        s = create_synthese(
            geom,
            taxon,
            users["self_user"],
            ds,
            source,
            comment_description=name,
        )
        db.session.add(s)
        data[name] = s

    # retrieves sensitive nomenclatures computed by trigger
    db.session.flush()
    for s in data.values():
        db.session.refresh(s)

    assert data["obs_sensitive_protected"].nomenclature_sensitivity.cd_nomenclature == "2"
    assert data["obs_sensitive_protected_2"].nomenclature_sensitivity.cd_nomenclature == "2"
    assert data["obs_protected_not_sensitive"].nomenclature_sensitivity.cd_nomenclature == "0"

    for s in data.values():
        assert db.session.execute(
            sa.exists(
                sa.select(sa.literal(1))
                .select_from(TaxrefBdcStatutTaxon)
                .join(
                    TaxrefBdcStatutCorTextValues,
                    TaxrefBdcStatutCorTextValues.id_value_text
                    == TaxrefBdcStatutTaxon.id_value_text,
                )
                .join(
                    TaxrefBdcStatutText,
                    TaxrefBdcStatutText.id_text == TaxrefBdcStatutCorTextValues.id_text,
                )
                .join(
                    bdc_statut_cor_text_area,
                    bdc_statut_cor_text_area.c.id_text == TaxrefBdcStatutText.id_text,
                )
                .join(
                    LAreas,
                    LAreas.id_area == bdc_statut_cor_text_area.c.id_area,
                )
                .join(corAreaSynthese, corAreaSynthese.c.id_area == LAreas.id_area)
                .join(Synthese, Synthese.id_synthese == corAreaSynthese.c.id_synthese)
                .where(Synthese.id_synthese == s.id_synthese)
                .where(TaxrefBdcStatutTaxon.cd_nom == s.cd_nom)
                .where(TaxrefBdcStatutText.enable == True)
            ).select()
        ).scalar()

    return data


def create_media(media_path=""):
    photo_type = (
        TNomenclatures.query.join(
            BibNomenclaturesTypes, BibNomenclaturesTypes.id_type == TNomenclatures.id_type
        )
        .filter(
            BibNomenclaturesTypes.mnemonique == "TYPE_MEDIA", TNomenclatures.mnemonique == "Photo"
        )
        .one()
    )
    location = (
        BibTablesLocation.query.filter(BibTablesLocation.schema_name == "gn_commons")
        .filter(BibTablesLocation.table_name == "t_medias")
        .one()
    )

    new_media = TMedias(
        id_nomenclature_media_type=photo_type.id_nomenclature,
        media_path=media_path,
        title_fr="Test media",
        author="Test author",
        id_table_location=location.id_table_location,
        uuid_attached_row=func.uuid_generate_v4(),
    )

    with db.session.begin_nested():
        db.session.add(new_media)
    return new_media


@pytest.fixture
def medium(app):
    # FIXME: find a better way to get the id_media that will be created
    new_id_media = (db.session.query(func.max(TMedias.id_media)).scalar() or 0) + 1
    image = Image.new("RGBA", size=(1, 1), color=(155, 0, 0))
    # Delete = false since it will be done automatically
    with tempfile.NamedTemporaryFile(
        dir=TMedias.base_dir(), prefix=f"{new_id_media}_", suffix=".png", delete=False
    ) as f:
        image.save(f, "png")
        yield create_media(media_path=str(f.name))


@pytest.fixture()
def reports_data(users, synthese_data):
    data = []

    # do not commit directly on current transaction, as we want to rollback all changes at the end of tests
    def create_report(id_synthese, id_role, content, id_type, deleted):
        new_report = TReport(
            id_synthese=id_synthese,
            id_role=id_role,
            content=content,
            id_type=id_type,
            deleted=deleted,
            creation_date=datetime.datetime.now(),
        )
        db.session.add(new_report)
        return new_report

    ids = [s.id_synthese for s in synthese_data.values()]
    # get id by type
    discussionId = (
        BibReportsTypes.query.filter(BibReportsTypes.type == "discussion").first().id_type
    )
    alertId = BibReportsTypes.query.filter(BibReportsTypes.type == "alert").first().id_type
    with db.session.begin_nested():
        reports = [
            (ids[0], users["admin_user"].id_role, "comment1", discussionId, False),
            (ids[1], users["admin_user"].id_role, "comment1", alertId, False),
        ]
        for id_synthese, *args in reports:
            data.append(create_report(id_synthese, *args))

    return data


@pytest.fixture()
def notifications_enabled(monkeypatch):
    monkeypatch.setitem(current_app.config, "NOTIFICATIONS_ENABLED", True)
