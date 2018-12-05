import pytest


from flask import url_for, current_app, request

from .bootstrap_test import app, json_of_response, get_token
from pypnusershub.db.tools import InsufficientRightsError


@pytest.mark.usefixtures('client_class')
class TestGnPermissions():
    def test_get_users(self):
        '''
            Test get page with all roles 
        '''
        response = self.client.get(
            url_for('gn_permissions_backoffice.users')
        )
        #test = self.get_context_variable('users')
        assert b'Liste des roles' in response.data
        assert b'Grp_admin' in response.data
        assert response.status_code == 200

    def test_get_user_cruveds(self):
        '''
            Test get page with all cruved of a user
        '''
        response = self.client.get(
            url_for(
                'gn_permissions_backoffice.user_cruved',
                id_role=1
            )
        )
        assert response.status_code == 200
        assert b"CRUVED de l'utilisateur Admin" in response.data
        #check if there is a button to edit
        assert b'button' in response.data

    def test_get_cruved_scope_form_allowed(self):
        '''
            Test get user cruved form page
        '''
        # with user admin
        token = get_token(self.client)
        self.client.set_cookie('/', 'token', token)
        response = self.client.get(
            url_for(
                'gn_permissions_backoffice.permission_form',
                id_role=1,
                id_module=3,
                id_object=None
            )
        )
        assert response.status_code == 200

    def test_get_cruved_scope_form_not_allowed(self):
        '''
            Test get user cruved form page
        '''
        # with user agent
        token = get_token(self.client, login="agent", password='admin')
        self.client.set_cookie('/', 'token', token)
        with pytest.raises(InsufficientRightsError):
            response = self.client.get(
                url_for(
                    'gn_permissions_backoffice.permission_form',
                    id_role=1,
                    id_module=3,
                    id_object=None
            )
        )
        
