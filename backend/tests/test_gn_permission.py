import pytest


from flask import url_for, current_app, request

from .bootstrap_test import app, json_of_response, get_token
from pypnusershub.db.tools import InsufficientRightsError
from geonature.core.gn_permissions.models import VUsersPermissions
from geonature.utils.env import DB


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

    def test_post_cruved_scope_form(self):
        token = get_token(self.client)
        self.client.set_cookie('/', 'token', token)
        # WARNING: wet set ID not code in the form !
        data = {
            'C': '4',
            'R': '3',
            'U': '3',
            'V': '4',
            'E': '2',
            'D': '3',
        }
        response = self.client.post(
            url_for(
                'gn_permissions_backoffice.permission_form',
                id_role=9,
                id_module=3,
                id_object=None
            ),
            data=data,
            content_type='multipart/form-data'
        )
        assert response.status_code == 302

        permissions = DB.session.query(
            VUsersPermissions
        ).filter_by(
            id_role=9,
            module_code='GEONATURE',
            code_object='ALL',
            code_filter_type='SCOPE'
        ).all()

        # check no multiple permission per action
        assert len(permissions) == 6
        cruved_dict = {perm.code_action: perm.value_filter for perm in permissions}
        assert cruved_dict['C'] == '3'
        assert cruved_dict['R'] == '2'
        assert cruved_dict['U'] == '2'
        assert cruved_dict['V'] == '3'
        assert cruved_dict['E'] == '1'
        assert cruved_dict['D'] == '2'


        
