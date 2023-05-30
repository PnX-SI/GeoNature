import json
import datetime
import tempfile

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
from geonature.core.gn_synthese.models import TSources, Synthese, TReport, BibReportsTypes
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
from ref_geo.models import LAreas

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
]


@pytest.fixture(scope="session", autouse=True)
def app():
    app = create_app()
    app.testing = True
    app.test_client_class = JSONClient
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


@pytest.fixture(scope="function")
def module(users):
    other_module = TModules.query.filter_by(module_code="GEONATURE").one()
    with db.session.begin_nested():
        new_module = TModules(
            module_code="MODULE_1",
            module_label="module_1",
            module_path="module_1",
            active_frontend=True,
            active_backend=False,
        )
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

    def create_user(username, organisme=None, scope=None):
        # do not commit directly on current transaction, as we want to rollback all changes at the end of tests
        with db.session.begin_nested():
            user = User(
                groupe=False,
                active=True,
                organisme=organisme,
                identifiant=username,
                password=username,
            )
            db.session.add(user)
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
                                role=user,
                                action=action,
                                module=module,
                                object=obj,
                                scope_value=scope if scope != 3 else None,
                            )
                            db.session.add(permission)
        return user

    users = {}

    organisme = Organisme(nom_organisme="test imports")
    db.session.add(organisme)

    users_to_create = [
        ("noright_user", organisme, 0),
        ("stranger_user", None, 2),
        ("associate_user", organisme, 2),
        ("self_user", organisme, 1),
        ("user", organisme, 2),
        ("admin_user", organisme, 3),
    ]

    for username, *args in users_to_create:
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
    principal_actor_role = TNomenclatures.query.filter(
        BibNomenclaturesTypes.mnemonique == "ROLE_ACTEUR",
        TNomenclatures.mnemonique == "Contact principal",
    ).one()

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
    principal_actor_role = TNomenclatures.query.filter(
        BibNomenclaturesTypes.mnemonique == "ROLE_ACTEUR",
        TNomenclatures.mnemonique == "Contact principal",
    ).one()
    # add module code in the list to associate them to datasets
    writable_module_code = ["OCCTAX"]
    writable_module = TModules.query.filter(TModules.module_code.in_(writable_module_code)).all()

    def create_dataset(name, id_af, digitizer=None, modules=writable_module):
        with db.session.begin_nested():
            dataset = TDatasets(
                id_acquisition_framework=id_af,
                dataset_name=name,
                dataset_shortname=name,
                dataset_desc=name,
                marine_domain=True,
                terrestrial_domain=True,
                id_digitizer=digitizer.id_role if digitizer else None,
            )
            if digitizer and digitizer.organisme:
                actor = CorDatasetActor(
                    organism=digitizer.organisme, nomenclature_actor_role=principal_actor_role
                )
                dataset.cor_dataset_actor.append(actor)
            [dataset.modules.append(m) for m in modules]
            db.session.add(dataset)
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


def create_synthese(geom, taxon, user, dataset, source, uuid, cor_observers, **kwargs):
    now = datetime.datetime.now()

    return Synthese(
        id_source=source.id_source,
        unique_id_sinp=uuid,
        dataset=dataset,
        digitiser=user,
        nom_cite=taxon.lb_nom,
        cd_nom=taxon.cd_nom,
        cd_hab=3,
        the_geom_4326=geom,
        the_geom_point=geom,
        the_geom_local=func.st_transform(geom, 2154),
        date_min=now,
        date_max=now,
        cor_observers=cor_observers,
        **kwargs,
    )


@pytest.fixture()
def synthese_data(app, users, datasets, source):
    point1 = Point(5.92, 45.56)
    point2 = Point(-1.54, 46.85)
    point3 = Point(-3.486786, 48.832182)
    data = {}
    with db.session.begin_nested():
        for name, cd_nom, point, ds in [
            ("obs1", 713776, point1, datasets["own_dataset"]),
            ("obs2", 212, point2, datasets["own_dataset"]),
            ("obs3", 2497, point3, datasets["own_dataset"]),
            ("p1_af1", 713776, point1, datasets["belong_af_1"]),
            ("p1_af1_2", 212, point1, datasets["belong_af_1"]),
            ("p1_af2", 212, point1, datasets["belong_af_2"]),
            ("p2_af2", 2497, point2, datasets["belong_af_2"]),
            ("p2_af1", 2497, point2, datasets["belong_af_1"]),
            ("p3_af3", 2497, point3, datasets["belong_af_3"]),
        ]:
            unique_id_sinp = (
                "f4428222-d038-40bc-bc5c-6e977bbbc92b" if not data else func.uuid_generate_v4()
            )
            geom = from_shape(point, srid=4326)
            taxon = Taxref.query.filter_by(cd_nom=cd_nom).one()
            s = create_synthese(
                geom,
                taxon,
                users["self_user"],
                ds,
                source,
                unique_id_sinp,
                [users["admin_user"], users["user"]],
            )
            db.session.add(s)
            data[name] = s
    return data


@pytest.fixture()
def synthese_sensitive_data(app, users, datasets, source):
    data = {}

    # Retrieve all the taxa with a protection status, and the corresponding areas
    cte_taxa_area_with_status = (
        db.session.query(TaxrefBdcStatutTaxon.cd_nom, LAreas.id_area)
        .select_from(TaxrefBdcStatutTaxon, LAreas)
        .join(
            TaxrefBdcStatutCorTextValues,
            TaxrefBdcStatutTaxon.id_value_text == TaxrefBdcStatutCorTextValues.id_value_text,
        )
        .join(
            bdc_statut_cor_text_area,
            LAreas.id_area == bdc_statut_cor_text_area.c.id_area,
        )
        .join(
            TaxrefBdcStatutText, bdc_statut_cor_text_area.c.id_text == TaxrefBdcStatutText.id_text
        )
        .filter(bdc_statut_cor_text_area.c.id_text == TaxrefBdcStatutCorTextValues.id_text)
        .filter(TaxrefBdcStatutText.enable == True)
    ).cte("taxa_with_status")

    # Retrieve all the taxa with a sensitivity rule, and the corresponding areas
    cte_taxa_area_with_sensitivity = (
        db.session.query(SensitivityRule.cd_nom, cor_sensitivity_area.c.id_area)
        .select_from(SensitivityRule)
        .join(cor_sensitivity_area, SensitivityRule.id == cor_sensitivity_area.c.id_sensitivity)
        .filter(SensitivityRule.active == True)
    ).cte("taxa_with_sensitivity")

    # Retrieve a cd_nom and point that fit both a sensitivity rule and a protection status
    sensitive_protected_cd_nom, sensitive_protected_id_area = (
        db.session.query(
            cte_taxa_area_with_status.c.cd_nom,
            cte_taxa_area_with_status.c.id_area,
        )
        .join(
            cte_taxa_area_with_sensitivity,
            sa.and_(
                cte_taxa_area_with_status.c.cd_nom == cte_taxa_area_with_sensitivity.c.cd_nom,
                cte_taxa_area_with_status.c.id_area == cte_taxa_area_with_sensitivity.c.id_area,
            ),
        )
        .first()
    )
    sensitivity_rule = SensitivityRule.query.filter(
        SensitivityRule.cd_nom == sensitive_protected_cd_nom,
        SensitivityRule.areas.any(LAreas.id_area == sensitive_protected_id_area),
    ).first()
    sensitive_protected_area = LAreas.query.filter(
        LAreas.id_area == sensitive_protected_id_area
    ).first()
    # Get one point inside the area : the centroid (assuming the area is convex)
    sensitive_protected_point = db.session.query(
        func.ST_Centroid(func.ST_Transform(sensitive_protected_area.geom, 4326))
    ).first()[0]
    # Add a criteria to the sensitivity rule if needed
    id_nomenclature_bio_status = None
    id_type_nomenclature_bio_status = (
        BibNomenclaturesTypes.query.filter(BibNomenclaturesTypes.mnemonique == "STATUT_BIO")
        .one()
        .id_type
    )
    id_nomenclature_behaviour = None
    id_type_nomenclature_behaviour = (
        BibNomenclaturesTypes.query.filter(BibNomenclaturesTypes.mnemonique == "OCC_COMPORTEMENT")
        .one()
        .id_type
    )
    # Get one criteria for the sensitivity rule if needed
    list_criterias_for_sensitivity_rule = sensitivity_rule.criterias
    if list_criterias_for_sensitivity_rule:
        one_criteria_for_sensitive_rule = list_criterias_for_sensitivity_rule[0]
        id_type_criteria_for_sensitive_rule = one_criteria_for_sensitive_rule.id_type
        if id_type_criteria_for_sensitive_rule == id_type_nomenclature_bio_status:
            id_nomenclature_bio_status = one_criteria_for_sensitive_rule.id_nomenclature
        elif id_type_criteria_for_sensitive_rule == id_type_nomenclature_behaviour:
            id_nomenclature_behaviour = one_criteria_for_sensitive_rule.id_nomenclature

    # Retrieve a cd_nom and point that fit a protection status but no sensitivity rule
    protected_not_sensitive_cd_nom, protected_not_sensitive_id_area = (
        db.session.query(cte_taxa_area_with_status.c.cd_nom, cte_taxa_area_with_status.c.id_area)
        .filter(
            cte_taxa_area_with_status.c.cd_nom.notin_([cte_taxa_area_with_sensitivity.c.cd_nom])
        )
        .first()
    )
    protected_not_sensitive_area = LAreas.query.filter(
        LAreas.id_area == protected_not_sensitive_id_area
    ).first()
    # Get one point inside the area : the centroid (assuming the area is convex)
    protected_not_sensitive_point = db.session.query(
        func.ST_Centroid(func.ST_Transform(protected_not_sensitive_area.geom, 4326))
    ).first()[0]

    with db.session.begin_nested():
        for name, cd_nom, point, ds, comment_description in [
            (
                "obs_sensitive_protected",
                sensitive_protected_cd_nom,
                sensitive_protected_point,
                datasets["own_dataset"],
                "obs_sensitive_protected",
            ),
            (
                "obs_protected_not_sensitive",
                protected_not_sensitive_cd_nom,
                protected_not_sensitive_point,
                datasets["own_dataset"],
                "obs_protected_not_sensitive",
            ),
        ]:
            unique_id_sinp = func.uuid_generate_v4()
            geom = point
            taxon = Taxref.query.filter_by(cd_nom=cd_nom).one()
            kwargs = {}
            if id_nomenclature_bio_status:
                kwargs["id_nomenclature_bio_status"] = id_nomenclature_bio_status
            elif id_nomenclature_behaviour:
                kwargs["id_nomenclature_behaviour"] = id_nomenclature_behaviour
            kwargs["comment_description"] = comment_description
            s = create_synthese(
                geom, taxon, users["self_user"], ds, source, unique_id_sinp, [], **kwargs
            )
            db.session.add(s)
            data[name] = s

    # Assert that obs_sensitive_protected is a sensitive observation
    id_nomenclature_not_sensitive = (
        TNomenclatures.query.filter(
            TNomenclatures.nomenclature_type.has(BibNomenclaturesTypes.mnemonique == "SENSIBILITE")
        )
        .filter(TNomenclatures.cd_nomenclature == "4")
        .one()
    ).id_nomenclature
    Synthese.query.filter(
        Synthese.cd_nom == sensitive_protected_cd_nom
    ).first().id_nomenclature_sensitivity != id_nomenclature_not_sensitive

    # Assert that obs_protected_not_sensitive is not a sensitive observation
    Synthese.query.filter(
        Synthese.cd_nom == protected_not_sensitive_cd_nom
    ).first().id_nomenclature_sensitivity == id_nomenclature_not_sensitive

    ## Assert that obs_sensitive_protected and obs_protected_not_sensitive are protected observation
    def assert_observation_is_protected(name_observation):
        observation_synthese = data[name_observation]
        list_areas_observation = [area.id_area for area in observation_synthese.areas]
        cd_nom = observation_synthese.cd_nom
        list_id_areas_with_status_for_cd_nom = [
            tuple_id_area[0]
            for tuple_id_area in db.session.query(cte_taxa_area_with_status.c.id_area)
            .filter(cte_taxa_area_with_status.c.cd_nom == cd_nom)
            .all()
        ]
        # assert that intersection of the two lists is not empty
        assert set(list_areas_observation).intersection(set(list_id_areas_with_status_for_cd_nom))

    assert_observation_is_protected("obs_sensitive_protected")
    assert_observation_is_protected("obs_protected_not_sensitive")

    return data


def create_media(media_path=""):
    photo_type = TNomenclatures.query.filter(
        BibNomenclaturesTypes.mnemonique == "TYPE_MEDIA", TNomenclatures.mnemonique == "Photo"
    ).one()
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
