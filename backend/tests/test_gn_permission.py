import pytest


from flask import url_for, current_app, request, Response

from pypnusershub.db.tools import (
    InsufficientRightsError,
    AccessRightsExpiredError, 
    UnreadableAccessRightsError
) 
from .bootstrap_test import app, json_of_response, get_token
from pypnusershub.db.tools import InsufficientRightsError
from geonature.core.gn_permissions.models import (
    VUsersPermissions, TFilters, CorRoleActionFilterModuleObject,
    BibFiltersType, TObjects
) 
from geonature.core.gn_commons.models import TModules
from geonature.utils.env import DB


from geonature.core.gn_permissions.tools import(
    get_user_permissions, user_from_token, get_user_from_token_and_raise,
    cruved_scope_for_user_in_module
) 
from geonature.core.gn_permissions.decorators import get_max_perm
from geonature.core.gn_permissions.models import VUsersPermissions

@pytest.mark.usefixtures('client_class')
class TestGnPermissionsTools():
    """ Test of gn_permissions tools functions"""
    def test_user_from_token(self):
        with pytest.raises(UnreadableAccessRightsError): 
            resp = user_from_token('lapojfdzpijdspiv')
        
        token = get_token(self.client)
        user = user_from_token(token)
        assert isinstance(user, dict)
        assert user['nom_role'] == 'Administrateur'


    def test_user_from_token_and_raise_fail(self):
        # set a fake cookie
        self.client.set_cookie('/', 'token', 'fake cookie')
        resp = get_user_from_token_and_raise(request)
        assert isinstance(resp, Response)
        assert resp.status_code == 403

    def test_get_user_permissions(self):
        # set a real cookie
        token = get_token(self.client, login="admin", password="admin")
        self.client.set_cookie('/', 'token', token)
        # fake request to set cookie
        response = self.client.get(
            url_for(
                'gn_permissions_backoffice.filter_list',
                id_filter_type=4,
            )
        )
        resp = get_user_from_token_and_raise(request)
        assert isinstance(resp, dict)


    def test_get_user_permissions(self):
        """
            Test get_user_permissions
        """
        user_ok = {'id_role': 1, 'nom_role': 'Administrateur'}
        perms = get_user_permissions(
            user_ok,
            code_action='C',
            code_filter_type='SCOPE'
        )
        assert isinstance(perms, list)
        assert get_max_perm(perms).value_filter == '3'

        fake_user = {'id_role': 220, 'nom_role': 'Administrateur'}

        with pytest.raises(InsufficientRightsError):
            perms = get_user_permissions(
                fake_user,
                code_action='C',
                code_filter_type='SCOPE'
            )
        # with module code 
        perms = get_user_permissions(
            user_ok,
            code_action='C',
            code_filter_type='SCOPE',
            module_code='ADMIN'
        )
        max_perm = get_max_perm(perms)
        assert max_perm.value_filter == '3'

        # with code_object
        perms = get_user_permissions(
            user_ok,
            code_action='C',
            code_filter_type='SCOPE',
            code_object='PERMISSIONS'
        )
        assert isinstance(perms, list)
        assert get_max_perm(perms).value_filter == '3'

    def test_cruved_scope_for_user_in_module(self):
        # get cruved for geonature
        cruved, herited = cruved_scope_for_user_in_module(
            id_role=9,
            module_code='GEONATURE'
        )
        assert herited == False
        assert cruved == {'C': '3', 'R': '3', 'U': '3', 'V':'3', 'E':'3', 'D': '3'}

        cruved, herited = cruved_scope_for_user_in_module(
            id_role=9,
            module_code='GEONATURE',
            get_id=True
        )

        assert herited == False
        assert cruved == {'C': 4, 'R': 4, 'U': 4, 'V':4, 'E':4, 'D': 4}




@pytest.mark.usefixtures('client_class')
class TestGnPermissionsView():
    def test_get_users(self):
        '''
            Test get page with all roles 
        '''
        token = get_token(self.client)
        self.client.set_cookie('/', 'token', token)
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
        token = get_token(self.client)
        self.client.set_cookie('/', 'token', token)
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
                id_module=1,
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
                    id_module=0,
                    id_object=None
            )
        )

    def test_post_cruved_scope_form(self):
        """
            Test a post an an update on table cor_role_action_filter_module_object
        """
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
                id_role=15,
                id_module=0,
                id_object=None
            ),
            data=data,
            content_type='multipart/form-data'
        )
        assert response.status_code == 302

        permissions = DB.session.query(
            VUsersPermissions
        ).filter_by(
            id_role=15,
            module_code='GEONATURE',
            code_object='ALL',
            code_filter_type='SCOPE'
        ).all()
        cruved_dict = {perm.code_action: perm.value_filter for perm in permissions}
        assert cruved_dict['C'] == '3'
        assert cruved_dict['R'] == '2'
        assert cruved_dict['U'] == '2'
        assert cruved_dict['V'] == '3'
        assert cruved_dict['E'] == '1'
        assert cruved_dict['D'] == '2'

        # check no multiple permission per action        
        assert len(permissions) == 6


        
    def test_get_user_cruved(self):
        '''
            Test of view who return the user cruved in all modules
        '''
        token = get_token(self.client)
        self.client.set_cookie('/', 'token', token)
        response = self.client.get(
            url_for(
                'gn_permissions_backoffice.user_cruved',
                id_role=1
            )
        )
        assert response.status_code == 200
        assert b"CRUVED de l'utilisateur Administrateur" in response.data


    def test_get_user_other_permissions(self):
        '''
            Test of view who return the user permissions expect SCOPE
        '''
        token = get_token(self.client)
        self.client.set_cookie('/', 'token', token)
        response = self.client.get(
            url_for(
                'gn_permissions_backoffice.user_other_permissions',
                id_role=1
            )
        )
        assert response.status_code == 200
        assert b"Permissions du role Administrateur" in response.data


    def test_post_or_update_other_perm(self):
        '''
            Test post/update a permission (no scope)
        '''
        token = get_token(self.client)
        self.client.set_cookie('/', 'token', token)
        valid_data = {
            'module':'0',
            'action': '1',
            'filter': '5'
        }

        response = self.client.post(
            url_for(
                'gn_permissions_backoffice.other_permissions_form',
                id_role=1,
                id_filter_type=4
            ),
            data=valid_data
        )

        permission = DB.session.query(
            VUsersPermissions
        ).filter_by(
            id_role=1,
            module_code='GEONATURE',
            code_object='ALL',
            code_filter_type='TAXONOMIC',
            id_filter=5
        ).one()
        assert response.status_code == 302
        assert permission



        # test wrong parameter in form
        wrong_data = {
            'module':'0',
            'action': '1',
            'filter': 'truc'
        }

        response = self.client.post(
            url_for(
                'gn_permissions_backoffice.other_permissions_form',
                id_role=1,
                id_filter_type=4
            ),
            data=wrong_data
        )

        # if the post return a 200, its an error who render the initial template form
        # the post must return a 302 (redirect code)
        response.status_code == 200

        # change action and filter
        update_data = {
            'module':'0',
            'action': '2',
            'filter': '6'
        }

        response = self.client.post(
            url_for(
                'gn_permissions_backoffice.other_permissions_form',
                id_role=1,
                id_filter_type=4,
                id_permission=permission.id_permission
            ),
            data=update_data
        )

        assert response.status_code == 302

        update_permission = DB.session.query(
            VUsersPermissions
        ).filter_by(
            id_role=1,
            module_code='GEONATURE',
            code_object='ALL',
            code_filter_type='TAXONOMIC',
            id_filter=6
        ).one()
        assert update_permission

        #delete the perm for the next test
        perm = DB.session.query(CorRoleActionFilterModuleObject).get(update_permission.id_permission)
        DB.session.delete(perm)
        DB.session.commit()


    def test_post_or_update_filter(self):
        data = {
            'label_filter': 'Les sonneurs',
            'value_filter': '212',
            'description_filter': 'Filtre de validation des sonneurs'
        }
        token = get_token(self.client)
        self.client.set_cookie('/', 'token', token)

        response = self.client.post(
            url_for(
                'gn_permissions_backoffice.filter_form',
                id_filter_type=4,
            ),
            data=data
        )

        assert response.status_code == 302

        my_filter = DB.session.query(TFilters).filter_by(
            label_filter='Les sonneurs',
            value_filter='212',
            description_filter='Filtre de validation des sonneurs'
        ).first()

        assert my_filter


        # update 

        update_data = {
            'label_filter': 'Les sonneurs bleus',
            'value_filter': '213',
            'description_filter': 'Filtre de validation des sonneurs bleus'
        }

        response = self.client.post(
            url_for(
                'gn_permissions_backoffice.filter_form',
                id_filter_type=4,
                id_filter=my_filter.id_filter
            ),
            data=update_data
        )

        assert response.status_code == 302

        my_filter = DB.session.query(TFilters).filter_by(
            label_filter='Les sonneurs bleus',
            value_filter='213',
            description_filter='Filtre de validation des sonneurs bleus'
        ).first()

        assert my_filter

        # delete the filter for the new tests
        DB.session.delete(my_filter)
        DB.session.commit()


    def test_get_filters_list(self):
        token = get_token(self.client)
        self.client.set_cookie('/', 'token', token)
        response = self.client.get(
            url_for(
                'gn_permissions_backoffice.filter_list',
                id_filter_type=4,
            )
        )
        assert response.status_code == 200

    def test_delete_filter(self):
        token = get_token(self.client)
        self.client.set_cookie('/', 'token', token)
        # add a fake filter
        new_filter = TFilters(
            id_filter=500,
            label_filter='test',
            value_filter='0',
            description_filter='Aucune donnée',
            id_filter_type=1
        )
        DB.session.add(new_filter)
        DB.session.commit()
        response = self.client.post(
            url_for(
                'gn_permissions_backoffice.delete_filter',
                id_filter=500,
            )
        )
        assert response.status_code == 302

