from flask import (
    request,
    render_template,
    Blueprint,
    flash,
    current_app,
    redirect,
    url_for,
)

from sqlalchemy.exc import IntegrityError, SQLAlchemyError
from sqlalchemy.sql import func
from sqlalchemy import or_


from geonature.utils.env import DB
from geonature.core.gn_permissions.backoffice.forms import (
    CruvedScopeForm,
    OtherPermissionsForm,
    FilterForm,
)
from geonature.core.gn_permissions.tools import (
    cruved_scope_for_user_in_module,
    beautifulize_cruved,
)
from geonature.core.gn_permissions.models import (
    TFilters,
    BibFiltersType,
    TActions,
    CorRoleActionFilterModuleObject,
    TObjects,
    CorObjectModule,
    VUsersPermissions,
)
from geonature.core.users.models import BibOrganismes
from geonature.core.users.models import CorRole
from geonature.core.gn_commons.models import TModules
from geonature.core.gn_permissions import decorators as permissions


from pypnusershub.db.models import User, AppRole

routes = Blueprint("gn_permissions_backoffice", __name__, template_folder="templates")


@routes.route(
    "cruved_form/module/<int:id_module>/role/<int:id_role>/object/<int:id_object>",
    methods=["GET", "POST"],
)
@routes.route(
    "cruved_form/module/<int:id_module>/role/<int:id_role>", methods=["GET", "POST"]
)
@permissions.check_cruved_scope(
    "R",
    True,
    object_code="PERMISSIONS",
    redirect_on_expiration=current_app.config["URL_APPLICATION"] + "/#/login",
    redirect_on_invalid_token=current_app.config["URL_APPLICATION"] + "/#/login",
)
def permission_form(info_role, id_module, id_role, id_object=None):
    """
    .. :quickref: View_Permission;
    """
    # TODO: check post permissions
    form = None
    module = DB.session.query(TModules).get(id_module)
    object_instance = None
    module_objects = []
    if id_object:
        object_instance = DB.session.query(TObjects).get(id_object)
    else:
        object_instance = (
            DB.session.query(TObjects).filter_by(code_object="ALL").first()
        )

    user = DB.session.query(User).get(id_role)
    if request.method == "GET":
        cruved, herited = cruved_scope_for_user_in_module(
            id_role=id_role,
            module_code=module.module_code,
            object_code=object_instance.code_object,
            get_id=True,
        )
        form = CruvedScopeForm(**cruved)
        # get the real cruved of user to set a warning
        real_cruved = (
            DB.session.query(CorRoleActionFilterModuleObject)
            .filter_by(
                id_module=id_module,
                id_role=id_role,
                id_object=object_instance.id_object,
            )
            .all()
        )
        if len(real_cruved) == 0 and not module.module_code == "ADMIN":
            flash(
                """
                Attention ce role n'a pas encore de CRUVED dans ce module. 
                Celui-ci lui est hérité de son groupe et/ou du module parent GEONATURE
                """
            )
        return render_template(
            "cruved_scope_form.html",
            form=form,
            user=user,
            module=module,
            object_instance=object_instance,
            id_object=id_object,
            config=current_app.config,
        )

    else:
        form = CruvedScopeForm(request.form)
        if form.validate_on_submit():
            actions_id = {
                action.code_action: action.id_action
                for action in DB.session.query(TActions).all()
            }
            for code_action, id_action in actions_id.items():
                privilege = {
                    "id_role": id_role,
                    "id_action": id_action,
                    "id_module": id_module,
                    "id_object": object_instance.id_object,
                }
                # check if a row already exist for a module, a role and an action
                # force to not set several filter for the same role-action-module-object
                permission_instance = (
                    DB.session.query(CorRoleActionFilterModuleObject)
                    .filter_by(**privilege)
                    .join(
                        TFilters,
                        TFilters.id_filter == CorRoleActionFilterModuleObject.id_filter,
                    )
                    .join(
                        BibFiltersType,
                        BibFiltersType.id_filter_type == TFilters.id_filter_type,
                    )
                    .filter(BibFiltersType.code_filter_type == "SCOPE")
                    .first()
                )
                # if already exist update the id_filter
                if permission_instance:
                    permission_instance.id_filter = int(form.data[code_action])
                    DB.session.merge(permission_instance)
                else:
                    permission_row = CorRoleActionFilterModuleObject(
                        id_role=id_role,
                        id_action=id_action,
                        id_filter=int(form.data[code_action]),
                        id_module=id_module,
                        id_object=object_instance.id_object,
                    )
                    DB.session.add(permission_row)
                DB.session.commit()
            flash("CRUVED mis à jour pour le role {}".format(user.id_role))
        return redirect(
            url_for("gn_permissions_backoffice.user_cruved", id_role=id_role)
        )


@routes.route("/users", methods=["GET"])
@permissions.check_cruved_scope(
    "R",
    True,
    object_code="PERMISSIONS",
    redirect_on_expiration=current_app.config["URL_APPLICATION"] + "/#/login",
    redirect_on_invalid_token=current_app.config["URL_APPLICATION"] + "/#/login",
)
def users(info_role):
    """
    .. :quickref: View_Permission;
    Render a list with all users with their number of cruved
    Link to edit cruved and other permissions
    Only display user which have profil in GeoNature and active user
    """

    q = (
        DB.session.query(AppRole, func.count(CorRoleActionFilterModuleObject.id_role))
        .outerjoin(
            CorRoleActionFilterModuleObject,
            CorRoleActionFilterModuleObject.id_role == AppRole.id_role,
        )
        .filter(
            AppRole.id_application == current_app.config["ID_APPLICATION_GEONATURE"]
        )
        .group_by(AppRole)
        .order_by(AppRole.groupe.desc(), AppRole.nom_role.asc())
    )
    # filter with cruved auth
    if info_role.value_filter == "2":
        q = q.join(
            BibOrganismes, BibOrganismes.id_organisme == info_role.id_organisme
        ).filter(BibOrganismes == info_role.id_organisme)
    elif info_role.value_filter == "1":
        q = q.filter(User.id_role == info_role.id_role)

    data = q.all()

    users = []
    for user in data:
        user_dict = user[0].as_dict()
        user_dict["nb_cruved"] = user[1]
        users.append(user_dict)
    return render_template("users.html", users=users, config=current_app.config)


@routes.route("/user_cruved/<id_role>", methods=["GET"])
@permissions.check_cruved_scope(
    "R",
    object_code="PERMISSIONS",
    redirect_on_expiration=current_app.config["URL_APPLICATION"] + "/#/login",
    redirect_on_invalid_token=current_app.config["URL_APPLICATION"] + "/#/login",
)
def user_cruved(id_role):
    """
    .. :quickref: View_Permission;
    Get all scope CRUVED (with heritage) for a user in all modules
    """
    user = DB.session.query(User).get(id_role).as_dict()
    modules_data = DB.session.query(TModules).all()
    groupes_data = (
        DB.session.query(CorRole).filter(CorRole.id_role_utilisateur == id_role).all()
    )
    actions_label = {}
    for action in DB.session.query(TActions).all():
        actions_label[action.code_action] = action.description_action
    modules = []
    for module in modules_data:
        module = module.as_dict()
        # for each module get its related object
        module_objects = (
            DB.session.query(TObjects)
            .join(CorObjectModule, CorObjectModule.id_object == TObjects.id_object)
            .filter_by(id_module=module["id_module"])
            .all()
        )
        # get cruved for all object

        module_objects_as_dict = []
        for _object in module_objects:
            object_as_dict = _object.as_dict()
            object_cruved, herited = cruved_scope_for_user_in_module(
                id_role=id_role,
                module_code=module["module_code"],
                object_code=_object.code_object,
            )
            object_as_dict["cruved"] = beautifulize_cruved(actions_label, object_cruved)
            module_objects_as_dict.append(object_as_dict)

        module["module_objects"] = module_objects_as_dict

        # do not display cruved for module which have objects

        cruved, herited = cruved_scope_for_user_in_module(
            id_role, module["module_code"]
        )
        cruved_beautiful = beautifulize_cruved(actions_label, cruved)
        # print(cruved_beautiful)
        module["module_cruved"] = (cruved_beautiful, herited)
        modules.append(module)
    return render_template(
        "cruved_user.html",
        user=user,
        groupes=[groupe.role.as_dict() for groupe in groupes_data],
        modules=modules,
        config=current_app.config,
    )


@routes.route("/user_other_permissions/<id_role>", methods=["GET"])
@permissions.check_cruved_scope(
    "R",
    object_code="PERMISSIONS",
    redirect_on_expiration=current_app.config["URL_APPLICATION"] + "/#/login",
    redirect_on_invalid_token=current_app.config["URL_APPLICATION"] + "/#/login",
)
def user_other_permissions(id_role):
    """
    .. :quickref: View_Permission;
    Get all the permissions define for a user expect SCOPE permissions
    """
    user = DB.session.query(User).get(id_role).as_dict()

    permissions = (
        DB.session.query(VUsersPermissions)
        .filter(VUsersPermissions.code_filter_type != "SCOPE")
        .filter(VUsersPermissions.id_role == id_role)
        .order_by(VUsersPermissions.module_code, VUsersPermissions.code_filter_type)
        .all()
    )

    filter_types = DB.session.query(BibFiltersType).filter(
        BibFiltersType.code_filter_type != "SCOPE"
    )

    return render_template(
        "user_other_permissions.html",
        user=user,
        filter_types=filter_types,
        permissions=permissions,
    )


@routes.route(
    "/other_permissions_form/id_permission/<int:id_permission>/user/<int:id_role>/filter_type/<int:id_filter_type>",
    methods=["GET", "POST"],
)
@routes.route(
    "/other_permissions_form/user/<int:id_role>/filter_type/<int:id_filter_type>",
    methods=["GET", "POST"],
)
@permissions.check_cruved_scope(
    "R",
    object_code="PERMISSIONS",
    redirect_on_expiration=current_app.config["URL_APPLICATION"] + "/#/login",
    redirect_on_invalid_token=current_app.config["URL_APPLICATION"] + "/#/login",
)
def other_permissions_form(id_role, id_filter_type, id_permission=None):
    """
    Form to define permisisons for a user expect SCOPE permissions
    .. :quickref: View_Permission;
    """
    if id_permission:
        perm = DB.session.query(CorRoleActionFilterModuleObject).get(id_permission)
        form = OtherPermissionsForm(
            id_filter_type,
            action=perm.id_action,
            filter=perm.id_filter,
            module=perm.id_module,
        )
    else:
        form = OtherPermissionsForm(id_filter_type)
    user = DB.session.query(User).get(id_role).as_dict()
    filter_type = DB.session.query(BibFiltersType).get(id_filter_type)

    if request.method == "POST" and form.validate_on_submit():

        permInstance = CorRoleActionFilterModuleObject(
            id_permission=id_permission,
            id_role=id_role,
            id_action=int(form.data["action"]),
            id_filter=int(form.data["filter"]),
            id_module=int(form.data["module"]),
        )
        if id_permission:
            DB.session.merge(permInstance)
        else:
            DB.session.add(permInstance)
        DB.session.commit()

        return redirect(
            url_for("gn_permissions_backoffice.user_other_permissions", id_role=id_role)
        )

    return render_template(
        "other_permissions_form.html", user=user, form=form, filter_type=filter_type
    )


@routes.route(
    "/filter_form/id_filter_type/<int:id_filter_type>/id_filter/<int:id_filter>",
    methods=["GET", "POST"],
)
@routes.route(
    "/filter_form/id_filter_type/<int:id_filter_type>", methods=["GET", "POST"]
)
@permissions.check_cruved_scope(
    "R",
    object_code="PERMISSIONS",
    redirect_on_expiration=current_app.config["URL_APPLICATION"] + "/#/login",
    redirect_on_invalid_token=current_app.config["URL_APPLICATION"] + "/#/login",
)
def filter_form(id_filter_type, id_filter=None):
    """
    .. :quickref: View_Permission;
    """
    # TODO: check post permissions
    filter_type = DB.session.query(BibFiltersType).get(id_filter_type)
    # if id_filter: its an edit, preload the form
    if id_filter:
        filter_value = DB.session.query(TFilters).get(id_filter).as_dict()
        form = FilterForm(**filter_value)
    else:
        form = FilterForm()
    if request.method == "POST" and form.validate_on_submit():
        filter_instance = TFilters(
            id_filter=id_filter,
            label_filter=form.data["label_filter"],
            value_filter=form.data["value_filter"],
            description_filter=form.data["description_filter"],
            id_filter_type=id_filter_type,
        )
        if id_filter:
            DB.session.merge(filter_instance)
            flash("Filtre édité avec succès")
        else:
            DB.session.add(filter_instance)
            flash("Filtre ajouté avec succès")
        DB.session.commit()
        return redirect(
            url_for(
                "gn_permissions_backoffice.filter_list", id_filter_type=id_filter_type
            )
        )
    return render_template(
        "filter_form.html", form=form, filter_type=filter_type, id_filter=id_filter
    )


@routes.route("/filter_list/id_filter_type/<int:id_filter_type>", methods=["GET"])
@permissions.check_cruved_scope(
    "R",
    object_code="PERMISSIONS",
    redirect_on_expiration=current_app.config["URL_APPLICATION"] + "/#/login",
    redirect_on_invalid_token=current_app.config["URL_APPLICATION"] + "/#/login",
)
def filter_list(id_filter_type):
    """
    .. :quickref: View_Permission;
    """
    filters = DB.session.query(TFilters).filter(
        TFilters.id_filter_type == id_filter_type
    )
    filter_type = DB.session.query(BibFiltersType).get(id_filter_type)
    return render_template("filter_list.html", filters=filters, filter_type=filter_type)


@routes.route("/filter/<id_filter>", methods=["POST"])
@permissions.check_cruved_scope(
    "D",
    object_code="PERMISSIONS",
    redirect_on_expiration=current_app.config["URL_APPLICATION"] + "/#/login",
    redirect_on_invalid_token=current_app.config["URL_APPLICATION"] + "/#/login",
)
def delete_filter(id_filter):
    """
    .. :quickref: View_Permission;
    """
    my_filter = DB.session.query(TFilters).get(id_filter)
    DB.session.delete(my_filter)
    DB.session.commit()
    flash("Filtre supprimé avec succès")
    return redirect(
        url_for(
            "gn_permissions_backoffice.filter_list",
            id_filter_type=my_filter.id_filter_type,
        )
    )

