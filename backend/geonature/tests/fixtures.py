import json
import pkg_resources
import datetime

import pytest
from flask import testing, url_for
from werkzeug.datastructures import Headers
from sqlalchemy import func
from shapely.geometry import Point
from geoalchemy2.shape import from_shape

from geonature import create_app
from geonature.utils.env import db
from geonature.core.gn_permissions.models import (
    TActions,
    BibFiltersType,
    CorRoleActionFilterModuleObject,
)
from geonature.core.gn_commons.models import TModules
from geonature.core.gn_meta.models import (
    TAcquisitionFramework,
    TDatasets,
    CorDatasetActor,
    CorAcquisitionFrameworkActor,
)
from geonature.core.gn_synthese.models import TSources, Synthese

from pypnusershub.db.models import (
    User,
    Organisme,
    Application,
    Profils as Profil,
    UserApplicationRight,
)
from pypnnomenclature.models import TNomenclatures, BibNomenclaturesTypes
from apptax.taxonomie.models import Taxref
from utils_flask_sqla.tests.utils import JSONClient


__all__ = ["datasets", "acquisition_frameworks", "synthese_data", "source"]


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


@pytest.fixture(scope="session")
def users(app):
    app = Application.query.filter(Application.code_application == "GN").one()
    profil = Profil.query.filter(Profil.nom_profil == "Lecteur").one()

    modules_codes = ["GEONATURE", "SYNTHESE", "IMPORT", "OCCTAX", "METADATA"]
    modules = TModules.query.filter(TModules.module_code.in_(modules_codes)).all()

    actions = {
        code: TActions.query.filter(TActions.code_action == code).one() for code in "CRUVED"
    }
    scope = BibFiltersType.query.filter_by(code_filter_type="SCOPE").one()

    def create_user(username, organisme=None, scope_value=None):
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
            if scope_value:
                for action in actions.values():
                    for module in modules:
                        permission = CorRoleActionFilterModuleObject(
                            role=user,
                            action=action,
                            filter_type=scope,
                            value_filter=scope_value,
                            module=module,
                        )
                        db.session.add(permission)
            return user

    users = {}

    organisme = Organisme(nom_organisme="test imports")
    db.session.add(organisme)

    users_to_create = [
        ("noright_user", organisme, "0"),
        ("stranger_user", None, "2"),
        ("associate_user", organisme, "2"),
        ("self_user", organisme, "1"),
        ("user", organisme, "2"),
        ("admin_user", organisme, "3"),
    ]

    for username, *args in users_to_create:
        users[username] = create_user(username, *args)

    return users


@pytest.fixture
def _session(app):
    return db.session


@pytest.fixture(scope="function")
def acquisition_frameworks(users):
    principal_actor_role = TNomenclatures.query.filter(
        BibNomenclaturesTypes.mnemonique == "ROLE_ACTEUR",
        TNomenclatures.mnemonique == "Contact principal",
    ).one()

    def create_af(creator=None):
        with db.session.begin_nested():
            af = TAcquisitionFramework(
                acquisition_framework_name="test",
                acquisition_framework_desc="test",
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
        "own_af": create_af(creator=users["user"]),
        "associate_af": create_af(creator=users["associate_user"]),
        "stranger_af": create_af(creator=users["stranger_user"]),
        "orphan_af": create_af(),
    }

    return afs


@pytest.fixture(scope="function")
def datasets(users, acquisition_frameworks):
    af = acquisition_frameworks["orphan_af"]
    principal_actor_role = TNomenclatures.query.filter(
        BibNomenclaturesTypes.mnemonique == "ROLE_ACTEUR",
        TNomenclatures.mnemonique == "Contact principal",
    ).one()

    def create_dataset(name, digitizer=None):
        with db.session.begin_nested():
            dataset = TDatasets(
                id_acquisition_framework=af.id_acquisition_framework,
                dataset_name=name,
                dataset_shortname=name,
                dataset_desc=name,
                marine_domain=True,
                terrestrial_domain=True,
                id_digitizer=digitizer.id_role if digitizer else None,
            )
            db.session.add(dataset)
            if digitizer and digitizer.organisme:
                actor = CorDatasetActor(
                    organism=digitizer.organisme, nomenclature_actor_role=principal_actor_role
                )
                dataset.cor_dataset_actor.append(actor)
        return dataset

    datasets = {
        name: create_dataset(name, digitizer)
        for name, digitizer in [
            ("own_dataset", users["user"]),
            ("associate_dataset", users["associate_user"]),
            ("stranger_dataset", users["stranger_user"]),
            ("orphan_dataset", None),
        ]
    }

    return datasets


# @pytest.fixture(scope='class')
# def sample_data(app):
#    with db.session.begin_nested():
#        for sql_file in ['delete_sample_data.sql', 'sample_data.sql']:
#            operations = pkg_resources.resource_string("geonature.tests", f"data/{sql_file}") \
#                                      .decode('utf-8')
#            db.session.execute(operations)


@pytest.fixture()
def taxon_attribut():
    from apptax.taxonomie.models import BibAttributs, BibNoms, CorTaxonAttribut

    nom = BibNoms.query.filter_by(cd_ref=209902).one()
    attribut = BibAttributs.query.filter_by(nom_attribut="atlas_milieu").one()
    with db.session.begin_nested():
        c = CorTaxonAttribut(bib_nom=nom, bib_attribut=attribut, valeur_attribut="eau")
        db.session.add(c)
    return c


@pytest.fixture()
def source():
    with db.session.begin_nested():
        source = TSources(name_source="Fixture", desc_source="Synthese data from fixture")
        db.session.add(source)
    return source


@pytest.fixture()
def synthese_data(app, users, datasets, source):
    now = datetime.datetime.now()
    map_center_point = Point(
        app.config["MAPCONFIG"]["CENTER"][1],
        app.config["MAPCONFIG"]["CENTER"][0],
    )
    geom_4326 = from_shape(map_center_point, srid=4326)
    data = []
    with db.session.begin_nested():
        taxons = [
            Taxref.query.filter_by(cd_nom=713776).one(),
            Taxref.query.filter_by(cd_nom=2497).one(),
        ]
        for taxon in taxons:
            s = Synthese(
                id_source=source.id_source,
                unique_id_sinp=func.uuid_generate_v4(),
                dataset=datasets["own_dataset"],
                digitiser=users["self_user"],
                nom_cite=taxon.lb_nom,
                cd_nom=taxon.cd_nom,
                cd_hab=3,
                the_geom_4326=geom_4326,
                the_geom_point=geom_4326,
                the_geom_local=func.st_transform(geom_4326, 2154),
                date_min=now,
                date_max=now,
            )
            db.session.add(s)
            data.append(s)

    return data
