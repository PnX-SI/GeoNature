import pytest

from flask import url_for, request, template_rendered
from sqlalchemy import func
from werkzeug.exceptions import Forbidden, Unauthorized

from geonature.core.gn_permissions.models import (
    TFilters,
    CorRoleActionFilterModuleObject
)
from geonature.utils.env import DB


from geonature.core.gn_permissions.tools import (
    get_user_permissions,
    get_user_from_token_and_raise,
    cruved_scope_for_user_in_module,
)

from .utils import set_logged_user_cookie, logged_user_headers
from .fixtures import filters


@pytest.fixture
def captured_templates(app):
    recorded = []

    def record(sender, template, context, **extra):
        recorded.append((template, context))

    template_rendered.connect(record, app)
    try:
        yield recorded
    finally:
        template_rendered.disconnect(record, app)


@pytest.fixture
def unavailable_filter_id():
    return DB.session.query(func.max(TFilters.id_filter)).scalar() + 1


@pytest.fixture
def deactivate_csrf(app):
    # Deactivate the csrf check on the form otherwise it will appear
    # with errors on csrf
    app.config["WTF_CSRF_ENABLED"] = False


@pytest.mark.usefixtures("client_class", "temporary_transaction")
class TestGnPermissionsTools:
    """ Test of gn_permissions tools functions"""

    def test_user_from_token_and_raise_fail(self):
        # no cookie
        with pytest.raises(Unauthorized, match="No token"):
            resp = get_user_from_token_and_raise(request)
        # set a fake cookie
        self.client.set_cookie("/", "token", "fake token")
        # fake request to set cookie
        response = self.client.get(
            url_for("gn_permissions_backoffice.filter_list", id_filter_type=4)
        )
        with pytest.raises(Unauthorized, match="Token corrupted") as exc_info:
            resp = get_user_from_token_and_raise(request)

    def test_get_user_from_token_and_raise(self, app, users):
        with app.test_request_context(headers=logged_user_headers(users["user"])):
            app.preprocess_request()
            resp = get_user_from_token_and_raise(request)
            assert isinstance(resp, dict)

    def test_get_user_permissions_forbidden(self):
        """
        Test get_user_permissions
        """
        fake_user = {"id_role": 220, "nom_role": "Administrateur"}
        # get_user_permissions(fake_user, code_action="C", code_filter_type="SCOPE")
        with pytest.raises(Forbidden):
            get_user_permissions(fake_user, code_action="C", code_filter_type="SCOPE")
        # with module code
    
    def test_cruved_scope_for_user_in_module(self, users):
        admin_user = users['admin_user']
        # get cruved for geonature
        cruved, herited = cruved_scope_for_user_in_module(id_role=admin_user.id_role, module_code="GEONATURE")
        assert herited == False
        assert cruved == {"C": "3", "R": "3", "U": "3", "V": "3", "E": "3", "D": "3"}

        cruved, herited = cruved_scope_for_user_in_module(
            id_role=admin_user.id_role, module_code="GEONATURE", get_id=True
        )

        assert herited == False
        assert cruved == {"C": 4, "R": 4, "U": 4, "V": 4, "E": 4, "D": 4}


@pytest.mark.usefixtures("client_class", "temporary_transaction")
class TestGnPermissionsView:
    def test_get_users(self, users):
        """
        Test get page with all roles
        """
        set_logged_user_cookie(self.client, users['admin_user'])
        response = self.client.get(url_for("gn_permissions_backoffice.users"))
        # test = self.get_context_variable('users')
        assert response.status_code == 200
        assert b"Liste des roles" in response.data
        assert b"Grp_en_poste" in response.data

    def test_get_user_cruveds(self, users, captured_templates):
        """
        Test get page with all cruved of a user
        """
        admin_user = users['admin_user']
        set_logged_user_cookie(self.client, admin_user)

        response = self.client.get(url_for("gn_permissions_backoffice.user_cruved", id_role=admin_user.id_role))

        template, context = captured_templates[0]
        assert template.name == "cruved_user.html"
        assert response.status_code == 200
        user_context = context["user"]
        assert user_context["id_role"] == admin_user.id_role
        assert len(context["modules"]) != 0

    def test_get_cruved_scope_form_allowed(self, users):
        """
        Test get user cruved form page
        """
        admin_user = users['admin_user']
        # with user admin
        set_logged_user_cookie(self.client, admin_user)

        response = self.client.get(
            url_for(
                "gn_permissions_backoffice.permission_form",
                id_role=admin_user.id_role,
                id_module=1,
                id_object=None,
            )
        )

        assert response.status_code == 200

    def test_post_cruved_scope_form(self, users):
        """
        Test a post an an update on table cor_role_action_filter_module_object
        """
        self_user = users["self_user"]
        set_logged_user_cookie(self.client, self_user)
        # WARNING: wet set ID not code in the form !
        data = {"C": "4", "R": "3", "U": "3", "V": "4", "E": "2", "D": "3"}

        response = self.client.post(
            url_for(
                "gn_permissions_backoffice.permission_form",
                id_role=self_user.id_role,
                id_module=0,
                id_object=None,
            ),
            data=data,
            content_type="multipart/form-data",
        )

        assert response.status_code == 302

    def test_get_user_other_permissions(self, users, captured_templates):
        """
        Test of view who return the user permissions expect SCOPE
        """
        admin_user = users["admin_user"]
        set_logged_user_cookie(self.client, admin_user)

        response = self.client.get(
            url_for("gn_permissions_backoffice.user_other_permissions", id_role=admin_user.id_role)
        )

        template, context = captured_templates[0]
        assert template.name == "user_other_permissions.html"
        assert response.status_code == 200
        user_context = context["user"]
        assert user_context["id_role"] == admin_user.id_role

    def test_post_other_perm_wrong(self, users):
        admin_user = users["admin_user"]
        set_logged_user_cookie(self.client, admin_user)
        # test wrong parameter in form
        wrong_data = {"module": "0", "action": "1", "filter": "truc"}

        response = self.client.post(
            url_for(
                "gn_permissions_backoffice.other_permissions_form",
                id_role=1,
                id_filter_type=4,
            ),
            data=wrong_data,
        )

        # if the post return a 200, its an error who render the initial template form
        # the post must return a 302 (redirect code)
        response.status_code == 200

    def test_post_other_perm(self, deactivate_csrf, users, filters):
        """
        Test post/update a permission (no scope)
        """

        admin_user = users["admin_user"]
        set_logged_user_cookie(self.client, admin_user)
        one_filter = filters[list(filters.keys())[0]]
        valid_data = {"module": "1", "action": "1", "filter": one_filter.id_filter}

        response = self.client.post(
            url_for(
                "gn_permissions_backoffice.other_permissions_form",
                id_role=admin_user.id_role,
                id_filter_type=one_filter.id_filter_type,
            ),
            data=valid_data,
        )

        assert response.status_code == 302

    # @pytest.mark.usefixtures('deactivate_csrf') seems not working here 
    def test_update_other_perm(self, deactivate_csrf, users, filters):
        admin_user = users["admin_user"]
        self_user = users['self_user']
        set_logged_user_cookie(self.client, admin_user)
        permission = (
            DB.session.query(CorRoleActionFilterModuleObject).filter(CorRoleActionFilterModuleObject.id_role==self_user.id_role).first()
        )
        id_permission = permission.id_permission
        # Take a 
        one_filter = filters[list(filters.keys())[-1]]
        # change action and filter
        update_data = {"module": "1", "action": "1", "filter": one_filter.id_filter}

        response = self.client.post(
            url_for(
                "gn_permissions_backoffice.other_permissions_form",
                id_role=self_user.id_role,
                id_filter_type=one_filter.id_filter_type,
                id_permission=permission.id_permission,
            ),
            data=update_data,
        )

        assert response.status_code == 302
        # TODO: maybe a better way to do this
        updated_permission = DB.session.query(CorRoleActionFilterModuleObject).get(id_permission)
        assert updated_permission.id_action == int(update_data['action'])

    def test_post_filter(self, deactivate_csrf, users, filters):
        admin_user = users["admin_user"]
        set_logged_user_cookie(self.client, admin_user)
        data = {
            "label_filter": "Les sonneurs",
            "value_filter": "212",
            "description_filter": "Filtre de validation des sonneurs",
        }
        one_filter = filters[list(filters.keys())[0]]
        id_filter_type = one_filter.id_filter_type
        
        response = self.client.post(
            url_for("gn_permissions_backoffice.filter_form", 
                    id_filter_type=id_filter_type),
                    data=data,
        )
        
        assert response.status_code == 302
        

    def test_update_filter(self, deactivate_csrf, users, filters):
        admin_user = users["admin_user"]
        set_logged_user_cookie(self.client, admin_user)
        one_filter = filters[list(filters.keys())[0]]
        update_data = {
            "label_filter": "Les sonneurs bleus",
            "value_filter": "213",
            "description_filter": "Filtre de validation des sonneurs bleus",
            "submit": "Valider"
        }

        response = self.client.post(
            url_for(
                "gn_permissions_backoffice.filter_form",
                id_filter_type=one_filter.id_filter_type,
                id_filter=one_filter.id_filter,
            ),
            data=update_data,
        )

        assert response.status_code == 302

    def test_get_filters_list(self, users, captured_templates, filters):
        admin_user = users["admin_user"]
        set_logged_user_cookie(self.client, admin_user)
        one_filter = filters[list(filters.keys())[0]]
        id_filter_type = one_filter.id_filter_type

        response = self.client.get(
            url_for("gn_permissions_backoffice.filter_list", id_filter_type=id_filter_type)
        )
        
        template, context = captured_templates[0]
        assert template.name == "filter_list.html"
        # Here context["filters"] is of type BaseQuery
        filters_gathered = context["filters"].all()
        assert id_filter_type in [filt.id_filter_type for filt in filters_gathered]
        assert response.status_code == 200

    def test_delete_filter_fail(self, users, unavailable_filter_id):
        admin_user = users["admin_user"]
        set_logged_user_cookie(self.client, admin_user)

        response = self.client.post(
            url_for("gn_permissions_backoffice.delete_filter", id_filter=unavailable_filter_id)
        )

        assert response.status_code == 404
    
    def test_delete_filter(self, users, filters):
        admin_user = users["admin_user"]
        set_logged_user_cookie(self.client, admin_user)
        one_filter = filters[list(filters.keys())[0]]

        response = self.client.post(
            url_for("gn_permissions_backoffice.delete_filter", id_filter=one_filter.id_filter)
        )

        # Since there is a redirection : 302
        assert response.status_code == 302
        assert url_for('gn_permissions_backoffice.filter_list', id_filter_type=one_filter.id_filter_type) in response.location
