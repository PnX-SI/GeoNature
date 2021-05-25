import json

import pytest
from flask import testing
from werkzeug.datastructures import Headers

from geonature import create_app
from geonature.utils.env import DB as db
from geonature.core.gn_permissions.models import TActions, TFilters, CorRoleActionFilterModuleObject
from geonature.core.gn_commons.models import TModules
from geonature.core.gn_meta.models import TAcquisitionFramework, TDatasets

from pypnusershub.db.models import User, Organisme, Application, Profils as Profil, UserApplicationRight


class JSONClient(testing.FlaskClient):
    def open(self, *args, **kwargs):
        headers = kwargs.pop('headers', Headers())
        if 'Accept' not in headers:
            headers.extend(Headers({
                'Accept': 'application/json, text/plain, */*',
            }))
        if 'Content-Type' not in headers:
            headers.extend(Headers({
                'Content-Type': 'application/json',
            }))
            if 'data' in kwargs:
                kwargs['data'] = json.dumps(kwargs['data'])
        kwargs['headers'] = headers
        return super().open(*args, **kwargs)


@pytest.fixture(scope='session')
def app():
    app = create_app()
    app.testing = True
    app.test_client_class = JSONClient
    app.config['SERVER_NAME'] = 'test.geonature.fr'  # required by url_for

    with app.app_context():
        transaction = db.session.begin_nested()  # execute tests in a savepoint
        yield app
        transaction.rollback()  # rollback all database changes


@pytest.fixture(scope='class')
def users(app):  # an app context is required
    app = Application.query.filter(Application.code_application=='GN').one()
    profil = Profil.query.filter(Profil.nom_profil=='Lecteur').one()

    import_module = TModules.query.filter_by(module_code='IMPORT').one()
    actions = { code: TActions.query.filter(TActions.code_action == code).one()
                for code in 'CRUVED' }
    filters = [
        TFilters.query.filter(TFilters.value_filter == str(scope)).one()
        for scope in [ 0, 1, 2, 3 ]
    ]

    def create_user(username, organisme=None, scope=None):
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
            if scope:
                for action in actions.values():
                    permission = CorRoleActionFilterModuleObject(
                                        role=user,
                                        action=action,
                                        filter=scope,
                                        module=import_module)
                    db.session.add(permission)
            return user

    users = {}

    organisme = Organisme(nom_organisme='test imports')
    db.session.add(organisme)

    users_to_create = [
        ('noright_user', organisme, filters[0]),
        ('stranger_user',),
        ('associate_user', organisme),
        ('self_user', organisme, filters[1]),
        ('user', organisme, filters[2]),
        ('admin_user', organisme, filters[3]),
    ]

    for username, *args in users_to_create:
        users[username] = create_user(username, *args)

    return users


@pytest.fixture(scope='class')
def datasets(users):
    af = TAcquisitionFramework.query.first()
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
        return dataset
    return {
        'own_dataset': create_dataset(digitizer=users['user']),
        'associate_dataset': create_dataset(digitizer=users['associate_user']),
        'stranger_dataset': create_dataset(digitizer=users['stranger_user']),
        'orphan_dataset': create_dataset(),
    }



@pytest.fixture(scope='function')
def client(app):
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

    with app.test_client() as client:
        yield client

    db.event.remove(db.session, "after_transaction_end", restart_savepoint)

    inner_transaction.rollback()  # probably rollback not so much
    outer_transaction.rollback()  # rollback all changes made during this test
