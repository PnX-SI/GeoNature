import datetime
import json
import tempfile
import time
from warnings import warn

import pytest
import sqlalchemy as sa

from flask import current_app, testing, url_for, request
from geoalchemy2.shape import from_shape
from PIL import Image
from shapely.geometry import Point
from sqlalchemy import func, select
from werkzeug.datastructures import Headers

from apptax.taxonomie.models import (
    Taxref,
    TaxrefBdcStatutTaxon,
    TaxrefBdcStatutCorTextValues,
    TaxrefBdcStatutText,
)
from geonature import create_app
from geonature.utils.config import config
from geonature.core.gn_commons.models import BibTablesLocation, TMedias, TModules
from geonature.core.gn_meta.models import (
    CorAcquisitionFrameworkActor,
    CorDatasetActor,
    TAcquisitionFramework,
    TDatasets,
)
from geonature.core.gn_permissions.models import PermAction, PermFilterType, Permission, PermObject
from geonature.core.gn_synthese.models import (
    BibReportsTypes,
    Synthese,
    TReport,
    TSources,
)
from geonature.core.sensitivity.models import (
    CorSensitivityCriteria,
    SensitivityRule,
    cor_sensitivity_area,
)
from geonature.utils.env import db
from pypnnomenclature.models import BibNomenclaturesTypes, TNomenclatures
from pypnusershub.db.models import Application, Organisme
from pypnusershub.db.models import Profils as Profil
from pypnusershub.db.models import User, UserApplicationRight
from ref_geo.models import BibAreasTypes, LAreas
from utils_flask_sqla.tests.utils import JSONClient
from werkzeug.datastructures import Headers

from .utils import get_id_nomenclature


__all__ = [
    "datasets",
    "acquisition_frameworks",
    "synthese_data",
    "synthese_sensitive_data",
    "synthese_with_protected_status",
    "source",
    "reports_data",
    "medium",
    "module",
    "perm_object",
    "notifications_enabled",
    "celery_eager",
    "sources_modules",
    "modules",
    "auto_validation_enabled",
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
    config["CELERY"]["task_always_eager"] = True
    app = create_app()
    app.testing = True
    app.test_client_class = GeoNatureClient
    app.config["SERVER_NAME"] = "test.geonature.fr"  # required by url_for

    @app.before_request
    def get_endpoint():
        pytest.endpoint = request.endpoint

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
    other_module = db.session.execute(
        select(TModules).filter_by(module_code="GEONATURE")
    ).scalar_one()
    with db.session.begin_nested():
        new_module = create_module("MODULE_1", "module_1", "module_1", True, False)
        db.session.add(new_module)
    # Copy perission from another module
    with db.session.begin_nested():
        for perm in db.session.scalars(
            select(Permission).filter_by(id_module=other_module.id_module)
        ).all():
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
    app = db.session.execute(
        select(Application).where(Application.code_application == "GN")
    ).scalar_one()

    profil = db.session.execute(select(Profil).where(Profil.nom_profil == "Lecteur")).scalar_one()

    actions = {
        code: db.session.execute(select(PermAction).filter_by(code_action=code)).scalar_one()
        for code in "CRUVED"
    }

    def get_scope(scope, detailed_scopes, module_code, action):
        """
        Return the scope for a module and a given action

        Parameters
        ----------
        scope : int
            default scope
        detailed_scopes : dict
            contains detailed scopes for specific action and modules (given in `create_user`)
        module_code : str
            code of the concerned module
        action : str
            action code ("C","R","U","V","E","D")

        Returns
        -------
        int
            scope
        """
        parse_scope = lambda scope: scope if scope != 3 else None
        scope = parse_scope(scope)
        if not module_code in detailed_scopes:
            # if detailed scope indicate a global scope for an action
            if action in detailed_scopes:
                return parse_scope(detailed_scopes[action])
            # else return the default scope
            return scope

        # If not action indicated in the module detailed scope
        if not action in detailed_scopes[module_code]:
            # If a default scope is defined for the given action
            if action in detailed_scopes:
                return parse_scope(detailed_scopes[action])
            # return the default scope
            return scope

        # if a scope is defined for the given action and modules, return the value
        return parse_scope(detailed_scopes[module_code][action])

    def create_user(
        username,
        organisme=None,
        scope=None,
        sensitivity_filter=False,
        modules_codes=[],
        detailed_scopes={},
        **kwargs,
    ):
        """
        Create a user

        Parameters
        ----------
        username : str
            username
        organisme : str, optional
            organism name, by default None
        scope : int, optional
            general scope, by default None
        sensitivity_filter : bool, optional
            does the user see blurred data concerning sensitive observation , by default False
        modules_codes : list, optional
            list of modules the user may access. If an empty list is given, the user will have access to all modules, by default []
        detailed_scopes : dict, optional
            if needed you can define detailed scopes for each module and action. For example, {"OCCHAB": {"C": 2}} will create a user with scope 2 on OCCHAB when creating a station.
            Every action not declared will we associated with the default scope (see `scope`). By default {}

        Returns
        -------
        User
            a GeoNature user
        """
        modules_query = select(TModules)
        if len(modules_codes) > 0:
            modules_query = modules_query.where(TModules.module_code.in_(modules_codes))

        modules = db.session.scalars(modules_query).all()

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
            if scope > 0 or detailed_scopes:
                object_all = db.session.execute(
                    select(PermObject).filter_by(code_object="ALL")
                ).scalar_one()
                for action in actions.values():
                    for module in modules:
                        for obj in [object_all] + module.objects:
                            scope_value = scope
                            permission = Permission(
                                action=action,
                                module=module,
                                object=obj,
                                scope_value=get_scope(
                                    scope, detailed_scopes, module.module_code, action.code_action
                                ),
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
        (
            (
                "user_restricted_occhab",
                organisme,
                2,
                False,
                [],
                {
                    "C": 2,
                    "OCCHAB": {"R": 2, "U": 1, "E": 2, "D": 1},
                    "OCCTAX": {"R": 2, "U": 1, "E": 2, "D": 1},
                },
            ),
            {},
        ),
        (
            ("user_with_blurring", organisme, 1, True, [], {}),
            {},
        ),
    ]

    for (username, *args), kwargs in users_to_create:
        users[username] = create_user(username, *args, **kwargs)

    return users


@pytest.fixture
def _session(app):
    return db.session


@pytest.fixture
def celery_eager(app, monkeypatch):
    from geonature.utils.celery import celery_app

    monkeypatch.setattr(celery_app.conf, "task_always_eager", True)
    monkeypatch.setattr(celery_app.conf, "task_eager_propagates", True)


@pytest.fixture(scope="function")
def acquisition_frameworks(users):
    principal_actor_role = db.session.execute(
        select(TNomenclatures)
        .join(BibNomenclaturesTypes, BibNomenclaturesTypes.mnemonique == "ROLE_ACTEUR")
        .where(
            TNomenclatures.mnemonique == "Contact principal",
        )
    ).scalar_one()

    def create_af(name, creator, is_parent, parent_af=None):
        with db.session.begin_nested():
            af = TAcquisitionFramework(
                acquisition_framework_name=name,
                acquisition_framework_desc=name,
                creator=creator,
                is_parent=is_parent,
                acquisition_framework_parent_id=(
                    parent_af.id_acquisition_framework if parent_af else None
                ),
            )
            db.session.add(af)
            if creator and creator.organisme:
                actor = CorAcquisitionFrameworkActor(
                    organism=creator.organisme, nomenclature_actor_role=principal_actor_role
                )
                af.cor_af_actor.append(actor)
            db.session.flush()
        return af

    afs = {
        name: create_af(name=name, creator=creator, is_parent=is_parent, parent_af=None)
        for name, creator, is_parent in [
            ("own_af", users["user"], False),
            ("associate_af", users["associate_user"], False),
            ("stranger_af", users["stranger_user"], False),
            ("orphan_af", None, False),
            ("af_1", None, False),
            ("af_2", None, False),
            ("af_3", None, False),
            ("parent_af", users["user"], True),
            ("parent_wo_children_af", users["user"], True),
            ("delete_parent_wo_children_af", users["user"], True),
            ("delete_af", users["user"], False),
        ]
    }
    afs["child_af"] = create_af("child_af", users["user"], False, afs["parent_af"])

    return afs


@pytest.fixture(scope="function")
def datasets(users, acquisition_frameworks, module):
    principal_actor_role = db.session.execute(
        select(TNomenclatures)
        .join(BibNomenclaturesTypes, TNomenclatures.id_type == BibNomenclaturesTypes.id_type)
        .where(
            TNomenclatures.mnemonique == "Contact principal",
            BibNomenclaturesTypes.mnemonique == "ROLE_ACTEUR",
        )
    ).scalar_one()

    # add module code in the list to associate them to datasets
    writable_module_code = ["OCCTAX", "OCCHAB"]
    writable_module = db.session.scalars(
        select(TModules).where(TModules.module_code.in_(writable_module_code))
    ).all()

    def create_dataset(
        name, id_af, digitizer=None, modules=writable_module, active=True, private=False
    ):
        with db.session.begin_nested():
            dataset = TDatasets(
                id_acquisition_framework=id_af,
                dataset_name=name,
                dataset_shortname=name,
                dataset_desc="lorem ipsum" * 22,
                marine_domain=True,
                terrestrial_domain=True,
                id_digitizer=digitizer.id_role if digitizer else None,
                active=active,
            )
            if digitizer and digitizer.organisme:
                actor = CorDatasetActor(
                    organism=digitizer.organisme, nomenclature_actor_role=principal_actor_role
                )
                dataset.cor_dataset_actor.append(actor)

            if private:
                dataset.nomenclature_data_origin = db.session.execute(
                    select(TNomenclatures).where(
                        TNomenclatures.nomenclature_type.has(
                            BibNomenclaturesTypes.mnemonique == "DS_PUBLIQUE"
                        ),
                        TNomenclatures.mnemonique == "Privée",
                    )
                ).scalar_one()

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
    datasets["own_dataset_not_activated"] = create_dataset(
        "own_dataset_not_activated",
        af.id_acquisition_framework,
        users["user"],
        active=False,
    )
    datasets["private"] = create_dataset(
        "private", af.id_acquisition_framework, users["user"], private=True
    )

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
    geom,
    taxon,
    user,
    dataset,
    source,
    uuid=func.uuid_generate_v4(),
    cor_observers=[],
    date_min="",
    date_max="",
    altitude_min=800,
    altitude_max=1200,
    **kwargs,
):
    now = datetime.datetime.now()

    date_min = date_min if date_min else now
    date_max = date_max if date_max else now

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
        date_min=date_min,
        date_max=date_max,
        altitude_min=altitude_min,
        altitude_max=altitude_max,
        cor_observers=cor_observers,
        **kwargs,
    )


@pytest.fixture()
def synthese_data(app, users, datasets, source, sources_modules):
    point1 = Point(5.92, 45.56)
    point2 = Point(-1.54, 46.85)
    point3 = Point(-3.486786, 48.832182)
    date_1 = datetime.datetime(2024, 10, 2, 11, 22, 33)
    date_2 = datetime.datetime(2024, 10, 3, 8, 9, 10)
    date_3 = datetime.datetime(2024, 10, 4, 17, 4, 9)
    date_4 = datetime.datetime(2024, 10, 5, 22, 22, 22)
    altitude_1 = 800
    altitude_2 = 900
    altitude_3 = 1000
    altitude_4 = 1100

    data = {}
    with db.session.begin_nested():
        for (
            name,
            cd_nom,
            point,
            ds,
            comment_description,
            source_m,
            date_min,
            date_max,
            altitude_min,
            altitude_max,
        ) in [
            # Donnnées de gypaète : possède des statuts de protection nationale
            (
                "obs1",
                2852,
                point1,
                datasets["own_dataset"],
                "obs1",
                sources_modules[0],
                date_1,
                date_1,
                altitude_1,
                altitude_1,
            ),
            (
                "obs2",
                212,
                point2,
                datasets["own_dataset"],
                "obs2",
                sources_modules[0],
                date_1,
                date_4,
                altitude_1,
                altitude_4,
            ),
            (
                "obs3",
                2497,
                point3,
                datasets["own_dataset"],
                "obs3",
                sources_modules[1],
                date_2,
                date_3,
                altitude_2,
                altitude_3,
            ),
            (
                "p1_af1",
                713776,
                point1,
                datasets["belong_af_1"],
                "p1_af1",
                sources_modules[1],
                date_1,
                date_3,
                altitude_1,
                altitude_3,
            ),
            (
                "p1_af1_2",
                212,
                point1,
                datasets["belong_af_1"],
                "p1_af1_2",
                sources_modules[1],
                date_3,
                date_3,
                altitude_3,
                altitude_3,
            ),
            (
                "p1_af2",
                212,
                point1,
                datasets["belong_af_2"],
                "p1_af2",
                sources_modules[1],
                date_3,
                date_4,
                altitude_3,
                altitude_4,
            ),
            (
                "p2_af2",
                2497,
                point2,
                datasets["belong_af_2"],
                "p2_af2",
                source,
                date_1,
                date_2,
                altitude_1,
                altitude_2,
            ),
            (
                "p2_af1",
                2497,
                point2,
                datasets["belong_af_1"],
                "p2_af1",
                source,
                date_1,
                date_1,
                altitude_1,
                altitude_1,
            ),
            (
                "p3_af3",
                2497,
                point3,
                datasets["belong_af_3"],
                "p3_af3",
                source,
                date_2,
                date_2,
                altitude_2,
                altitude_2,
            ),
        ]:
            unique_id_sinp = (
                "f4428222-d038-40bc-bc5c-6e977bbbc92b" if not data else func.uuid_generate_v4()
            )
            geom = from_shape(point, srid=4326)
            taxon = db.session.execute(select(Taxref).filter_by(cd_nom=cd_nom)).scalar_one()
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
                date_min,
                date_max,
                altitude_min,
                altitude_max,
                **kwargs,
            )
            db.session.add(s)
            data[name] = s
    return data


@pytest.fixture()
def synthese_sensitive_data(app, users, datasets, source):
    """
    Generate synthese observation with a sensitive status

    Parameters
    ----------
    app : pytest.FixtureDef
        geonature app fixture
    users : pytest.FixtureDef
        geonature users fixture
    datasets : pytest.FixtureDef
        geonature datasets fixture
    source : pytest.FixtureDef
        geonature data source fixture

    Returns
    -------
    pytest.FixtureDef
        fixture
    """
    data = {}

    # Retrieve a cd_nom and point that fit both a sensitivity rule and a protection status
    sensitivity_rule = db.session.execute(
        sa.select(SensitivityRule)
        .join(cor_sensitivity_area, SensitivityRule.id == cor_sensitivity_area.c.id_sensitivity)
        .join(
            CorSensitivityCriteria, SensitivityRule.id == CorSensitivityCriteria.id_sensitivity_rule
        )
        .join(LAreas, cor_sensitivity_area.c.id_area == LAreas.id_area)
        .where(SensitivityRule.active == True)
        .limit(1)
    ).scalar_one()

    sensitive_cd_nom, sensitive_id_area = sensitivity_rule.cd_nom, sensitivity_rule.areas[0].id_area

    sensitive_protected_area = db.session.scalars(
        select(LAreas).where(LAreas.id_area == sensitive_id_area).limit(1)
    ).first()

    # Get one point inside the area : the centroid (assuming the area is convex)
    sensitive_protected_point = db.session.scalar(
        sa.select(
            func.ST_PointOnSurface(func.ST_Transform(sensitive_protected_area.geom, 4326))
        ).limit(1)
    )

    # Add a criteria to the sensitivity rule if needed
    id_nomenclature_bio_status = None
    id_type_nomenclature_bio_status = db.session.scalar(
        sa.select(BibNomenclaturesTypes.id_type).where(
            BibNomenclaturesTypes.mnemonique == "STATUT_BIO"
        )
    )
    id_nomenclature_behaviour = None
    id_type_nomenclature_behaviour = db.session.scalar(
        sa.select(BibNomenclaturesTypes.id_type).where(
            BibNomenclaturesTypes.mnemonique == "OCC_COMPORTEMENT"
        )
    )

    # Get one criteria for the sensitivity rule if needed
    one_criteria_for_sensitive_rule = sensitivity_rule.criterias[0]
    id_type_criteria_for_sensitive_rule = one_criteria_for_sensitive_rule.id_type
    if id_type_criteria_for_sensitive_rule == id_type_nomenclature_bio_status:
        id_nomenclature_bio_status = one_criteria_for_sensitive_rule.id_nomenclature
    elif id_type_criteria_for_sensitive_rule == id_type_nomenclature_behaviour:
        id_nomenclature_behaviour = one_criteria_for_sensitive_rule.id_nomenclature

    id_nomenclature_not_sensitive = get_id_nomenclature(
        nomenclature_type_mnemonique="SENSIBILITE", cd_nomenclature="0"
    )
    id_nomenclature_sensitive = get_id_nomenclature(
        nomenclature_type_mnemonique="SENSIBILITE", cd_nomenclature="2"
    )

    unsensitive_area_centroid = db.session.scalars(
        sa.select(func.ST_Centroid(LAreas.geom_4326)).where(
            LAreas.area_type.has(BibAreasTypes.type_code == "DEP"),
            LAreas.area_code == "01",
        )
    ).one()

    unsensitive_taxon = db.session.execute(
        select(Taxref.cd_nom).filter_by(cd_nom=64357)
    ).scalar_one()

    with db.session.begin_nested():
        obs_metadata = [
            (
                "obs_sensitive",
                sensitive_cd_nom,
                sensitive_protected_point,
                datasets["own_dataset"],
                "obs_sensitive",
                id_nomenclature_sensitive,
            ),
            (
                "obs_not_sensitive",
                unsensitive_taxon,
                unsensitive_area_centroid,
                datasets["own_dataset"],
                "obs_not_sensitive",
                id_nomenclature_not_sensitive,
            ),
            (
                "obs_sensitive_2",
                sensitive_cd_nom,
                sensitive_protected_point,
                datasets["associate_2_dataset_sensitive"],
                "obs_sensitive_2",
                id_nomenclature_sensitive,
            ),
        ]
        for (
            name,
            cd_nom,
            point,
            ds,
            comment_description,
            id_nomenclature_sensitivity,
        ) in obs_metadata:
            geom = point
            taxon = db.session.execute(select(Taxref).filter_by(cd_nom=cd_nom)).scalar_one()
            kwargs = {}
            if id_nomenclature_bio_status:
                kwargs["id_nomenclature_bio_status"] = id_nomenclature_bio_status
            elif id_nomenclature_behaviour:
                kwargs["id_nomenclature_behaviour"] = id_nomenclature_behaviour
            kwargs["comment_description"] = comment_description
            kwargs["id_nomenclature_sensitivity"] = id_nomenclature_sensitivity
            s = create_synthese(geom, taxon, users["self_user"], ds, source, **kwargs)
            db.session.add(s)
            data[name] = s

    return data


@pytest.fixture()
def synthese_with_protected_status(users, datasets, source):
    """
    Generate synthese observations with protected status

    Parameters
    ----------
    users : pytest.Fixture
        users fixture
    datasets : pytest.Fixture
        datasets fixture
    source : pytest.Fixture
        source fixture

    Returns
    -------
    pytest.Fixture
        fixture with synthese observations
    """
    synthese_element = []

    # Retrieve protected taxon from the bdc_statut_taxons table
    protected_taxon = db.session.scalars(
        select(Taxref)
        .where(
            Taxref.cd_nom.in_(
                select(TaxrefBdcStatutTaxon.cd_nom)
                .join(TaxrefBdcStatutCorTextValues)
                .join(
                    TaxrefBdcStatutText,
                    TaxrefBdcStatutCorTextValues.id_text == TaxrefBdcStatutText.id_text,
                )
                .where(
                    TaxrefBdcStatutText.cd_sig == "TERFXFR"
                )  # Protected status in the whole France
                .limit(100)
            ),
        )
        .distinct(Taxref.cd_ref, Taxref.cd_nom)
        .limit(5)
    ).all()
    # dumb geometry

    geom = from_shape(Point(1.11, 48.65), 4326)

    # Generate a Synthese object for each taxon retrieved previously
    with db.session.begin_nested():
        for taxon in protected_taxon:
            synthese = create_synthese(
                geom,
                taxon,
                users["self_user"],
                datasets["own_dataset"],
                source,
                cor_observers=[users["self_user"]],
            )
            db.session.add(synthese)
            synthese_element.append(synthese)

    return synthese_element


def create_media(media_path=""):
    photo_type = db.session.execute(
        select(TNomenclatures)
        .join(BibNomenclaturesTypes, BibNomenclaturesTypes.id_type == TNomenclatures.id_type)
        .where(
            BibNomenclaturesTypes.mnemonique == "TYPE_MEDIA", TNomenclatures.mnemonique == "Photo"
        )
    ).scalar_one()
    location = db.session.execute(
        select(BibTablesLocation)
        .where(BibTablesLocation.schema_name == "gn_commons")
        .where(BibTablesLocation.table_name == "t_medias")
    ).scalar_one()

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
    new_id_media = (db.session.scalar(select(func.max(TMedias.id_media))) or 0) + 1
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
        db.session.scalars(select(BibReportsTypes).where(BibReportsTypes.type == "discussion"))
        .first()
        .id_type
    )
    alertId = (
        db.session.scalars(select(BibReportsTypes).where(BibReportsTypes.type == "alert"))
        .first()
        .id_type
    )
    with db.session.begin_nested():
        reports = [
            (ids[0], users["admin_user"].id_role, "comment1", discussionId, False),
            (ids[1], users["admin_user"].id_role, "comment1", alertId, False),
            (ids[2], users["user"].id_role, "a_comment1", discussionId, True),
            (ids[3], users["user"].id_role, "b_comment1", discussionId, True),
        ]
        for id_synthese, *args in reports:
            data.append(create_report(id_synthese, *args))

    return data


@pytest.fixture()
def notifications_enabled(monkeypatch):
    monkeypatch.setitem(current_app.config, "NOTIFICATIONS_ENABLED", True)


@pytest.fixture()
def auto_validation_enabled(monkeypatch):
    monkeypatch.setitem(current_app.config["VALIDATION"], "AUTO_VALIDATION_ENABLED", True)
