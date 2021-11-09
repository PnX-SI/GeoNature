import json
import datetime

import pytest
from flask import testing, url_for
from werkzeug.datastructures import Headers
from sqlalchemy import func
from shapely.geometry import Point
from geoalchemy2.shape import from_shape

from geonature import create_app
from geonature.utils.env import DB as db
from geonature.core.gn_permissions.models import TActions, BibFiltersType, CorRoleActionFilterModuleObject
from geonature.core.gn_commons.models import TModules
from geonature.core.gn_meta.models import TAcquisitionFramework, TDatasets, CorDatasetActor
from geonature.core.gn_synthese.models import TSources, Synthese

from pypnusershub.db.models import User, Organisme, Application, Profils as Profil, UserApplicationRight
from pypnnomenclature.models import TNomenclatures, BibNomenclaturesTypes
from apptax.taxonomie.models import Taxref


__all__ = ['app', 'users', 'acquisition_frameworks', 'datasets',
           'temporary_transaction', 'synthese_data']


class JSONClient(testing.FlaskClient):
    def open(self, *args, **kwargs):
        headers = kwargs.pop('headers', Headers())
        if 'Accept' not in headers:
            headers.extend(Headers({
                'Accept': 'application/json, text/plain, */*',
            }))
        if 'Content-Type' not in headers and 'data' in kwargs:
            kwargs['data'] = json.dumps(kwargs['data'])
            headers.extend(Headers({
                'Content-Type': 'application/json',
            }))
        kwargs['headers'] = headers
        return super().open(*args, **kwargs)


@pytest.fixture(scope='session')
def app():
    app = create_app()
    app.testing = True
    app.test_client_class = JSONClient
    app.config['SERVER_NAME'] = 'test.geonature.fr'  # required by url_for

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


@pytest.fixture(scope='class')
def users(app):  # an app context is required
    app = Application.query.filter(Application.code_application=='GN').one()
    profil = Profil.query.filter(Profil.nom_profil=='Lecteur').one()

    modules_codes = ["GEONATURE", "SYNTHESE", "IMPORT", "OCCTAX"]
    modules = TModules.query.filter(TModules.module_code.in_(modules_codes)).all()

    actions = { code: TActions.query.filter(TActions.code_action == code).one()
                for code in 'CRUVED' }
    scope = BibFiltersType.query.filter_by(code_filter_type='SCOPE').one()

    def create_user(username, organisme=None, scope_value=None):
        # do not commit directly on current transaction, as we want to rollback all changes at the end of tests
        with db.session.begin_nested():
            user = User(groupe=False, active=True, organisme=organisme,
                        identifiant=username, password=username)
            db.session.add(user)
        # user must have been commited for user.id_role to be defined
        with db.session.begin_nested():
            # login right
            right = UserApplicationRight(id_role=user.id_role,
                                         id_application=app.id_application,
                                         id_profil=profil.id_profil)
            db.session.add(right)
            if scope_value:
                for action in actions.values():
                    for module in modules:
                        permission = CorRoleActionFilterModuleObject(
                                            role=user,
                                            action=action,
                                            filter_type=scope,
                                            value_filter=scope_value,
                                            module=module
                                    )
                        db.session.add(permission)
            return user

    users = {}

    organisme = Organisme(nom_organisme='test imports')
    db.session.add(organisme)

    users_to_create = [
        ('noright_user', organisme, '0'),
        ('stranger_user', None, '2'),
        ('associate_user', organisme, '2'),
        ('self_user', organisme, '1'),
        ('user', organisme, '2'),
        ('admin_user', organisme, '3'),
    ]

    for username, *args in users_to_create:
        users[username] = create_user(username, *args)

    return users


@pytest.fixture(scope='class')
def acquisition_frameworks(users):
    def create_af(creator=None):
        with db.session.begin_nested():
            af = TAcquisitionFramework(
                            acquisition_framework_name='test',
                            acquisition_framework_desc='test',
                            creator=creator)
            db.session.add(af)
        return af
    return {
        'own_af': create_af(creator=users['user']),
        'associate_af': create_af(creator=users['associate_user']),
        'stranger_af': create_af(creator=users['stranger_user']),
        'orphan_af': create_af(),
    }


@pytest.fixture(scope='class')
def datasets(users, acquisition_frameworks):
    af = acquisition_frameworks['orphan_af']
    principal_actor_role = TNomenclatures.query.filter(
                                BibNomenclaturesTypes.mnemonique=='ROLE_ACTEUR',
                                TNomenclatures.mnemonique=='Contact principal').one()
    def create_dataset(digitizer=None):
        with db.session.begin_nested():
            dataset = TDatasets(
                            id_acquisition_framework=af.id_acquisition_framework,
                            dataset_name='test',
                            dataset_shortname='test',
                            dataset_desc='test',
                            marine_domain=True,
                            terrestrial_domain=True,
                            id_digitizer=digitizer.id_role if digitizer else None)
            db.session.add(dataset)
            if digitizer and digitizer.organisme:
                actor = CorDatasetActor(
                            organism=digitizer.organisme,
                            nomenclature_actor_role=principal_actor_role)
                dataset.cor_dataset_actor.append(actor)
        return dataset
    return {
        'own_dataset': create_dataset(digitizer=users['user']),
        'associate_dataset': create_dataset(digitizer=users['associate_user']),
        'stranger_dataset': create_dataset(digitizer=users['stranger_user']),
        'orphan_dataset': create_dataset(),
    }


@pytest.fixture(scope='function')
def temporary_transaction(app):
    """
    We start two nested transaction (SAVEPOINT):
        - The outer one will be used to rollback all changes made by the current test function.
        - The inner one will be used to catch all commit() / rollback() made in tested code.
          After starting the inner transaction, we install a listener on transaction end events,
          and each time the inner transaction is closed, we restart a new transaction to catch
          potential new commit() / rollback().
    Note: When we rollback the inner transaction at the end of the test, we actually rollback
    only the last inner transaction but previous inner transaction may have been committed by the
    tested code! This is why we need an outer transaction to rollback all changes made by the test.
    """
    outer_transaction = db.session.begin_nested()
    inner_transaction = db.session.begin_nested()

    def restart_savepoint(session, transaction):
        nonlocal inner_transaction
        if transaction == inner_transaction:
            session.expire_all()
            inner_transaction = session.begin_nested()

    db.event.listen(db.session, "after_transaction_end", restart_savepoint)

    yield

    db.event.remove(db.session, "after_transaction_end", restart_savepoint)

    inner_transaction.rollback()  # probably rollback not so much
    outer_transaction.rollback()  # rollback all changes made during this test


@pytest.fixture()
def releve_data(client, datasets):
    """
        Releve associated with dataset created by "user"
    """
    id_dataset = datasets["own_dataset"].id_dataset
    response = client.get(url_for("pr_occtax.getDefaultNomenclatures"))
    default_nomenclatures = response.get_json()
    data = {
        "depth": 2,
        "geometry": {"type": "Point", "coordinates": [3.428936004638672, 44.276611357355904],},
        "properties": {
            "id_dataset": id_dataset,
            "id_digitiser": 1,
            "date_min": "2018-03-02",
            "date_max": "2018-03-02",
            "hour_min": None,
            "hour_max": None,
            "altitude_min": None,
            "altitude_max": None,
            "meta_device_entry": "web",
            "comment": None,
            "id_nomenclature_obs_technique": default_nomenclatures["TECHNIQUE_OBS"],
            "observers": [1],
            "observers_txt": "tatatato",
            "id_nomenclature_grp_typ": default_nomenclatures["TYP_GRP"],
        },
    }

    return data


@pytest.fixture()
def synthese_data(users, datasets):
    with db.session.begin_nested():
        source = TSources(name_source='Fixture',
                          desc_source='Synthese data from fixture')
        db.session.add(source)
    now = datetime.datetime.now()
    geom_4326 = from_shape(Point(3.63492965698242, 44.3999389306734), srid=4326)
    with db.session.begin_nested():
        taxon = Taxref.query.filter_by(cd_nom=713776).one()
        s = Synthese(id_source=source.id_source,
                     dataset=datasets['own_dataset'],
                     digitiser=users['self_user'],
                     nom_cite='Ashmeadopria Kieffer',
                     cd_nom=taxon.cd_nom,
                     cd_hab=3,
                     the_geom_4326=geom_4326,
                     the_geom_point=geom_4326,
                     the_geom_local=func.st_transform(geom_4326, 2154),
                     date_min=now,
                     date_max=now)
        db.session.add(s)
    return [s]
