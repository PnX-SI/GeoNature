from flask import request, render_template, Blueprint, flash, current_app, redirect, url_for

from sqlalchemy.exc import IntegrityError 
from sqlalchemy.sql import func

from geonature.utils.env import DB 
from geonature.core.gn_permissions.backoffice.forms import CruvedScopeForm
from geonature.core.gn_permissions.tools import cruved_scope_for_user_in_module
from geonature.core.gn_permissions.models import(
    TFilters, BibFiltersType, TActions,
    CorRoleActionFilterModuleObject, TObjects, CorObjectModule
)
from geonature.core.users.models import CorRole
from geonature.core.gn_commons.models import TModules
from geonature.core.gn_permissions import decorators as permissions


from pypnusershub.db.models import User

routes = Blueprint('gn_permissions_backoffice', __name__, template_folder='templates')

@routes.route('cruved_form/module/<int:id_module>/role/<int:id_role>/<int:id_object>', methods=["GET", "POST"])
@routes.route('cruved_form/module/<int:id_module>/role/<int:id_role>', methods=["GET", "POST"])
@permissions.check_cruved_scope('R', True, object_code='PERMISSIONS')
def permission_form(info_role, id_module, id_role, id_object=1):
    print(info_role)
    form = None
    module = DB.session.query(TModules).get(id_module)
    # get module associed objects to set specific Cruved
    module_objects = DB.session.query(TObjects).join(
        CorObjectModule, CorObjectModule.id_object == TObjects.id_object
    ).filter(
        CorObjectModule.id_module == id_module
    ).all()
    user = DB.session.query(User).get(id_role)
    if request.method == 'GET':
        cruved, herited = cruved_scope_for_user_in_module(id_role, module.module_code, get_id=True)
        form = CruvedScopeForm(**cruved)
 
        # get the real cruved of user to set a warning
        real_cruved = DB.session.query(CorRoleActionFilterModuleObject).filter_by(
            **{'id_module':id_module, 'id_role': id_role, 'id_object': id_object}
        ).all()
        if len(real_cruved) == 0:
            flash(
                """
                Attention ce role n'a pas encore de CRUVED dans ce module. 
                Celui-ci lui est hérité de son groupe et/ou du module parent GEONATURE
                """
            )
        return render_template(
            'cruved_scope_form.html',
            form=form,
            user=user,
            module=module,
            module_objects=module_objects,
            config=current_app.config
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
                    'id_role': id_role,
                    'id_action': id_action,
                    'id_module': id_module,
                    'id_object': id_object
                }
                # check if a row already exist for a module, a role and an action
                instance = DB.session.query(
                    CorRoleActionFilterModuleObject
                ).filter_by(
                        **privilege
                ).first()
                # if already exist update the id_filter
                if instance:
                    instance.id_filter = int(form.data[code_action])
                    DB.session.merge(instance)
                else:
                    permission_row = CorRoleActionFilterModuleObject(
                        id_role=id_role,
                        id_action=id_action,
                        id_filter = int(form.data[code_action]),
                        id_module=id_module,
                        id_object=id_object
                    )
                    DB.session.add(permission_row)
                DB.session.commit()
            flash(
                'CRUVED mis à jour pour le role {}'.format(user.id_role)
            )
        return redirect(url_for('gn_permissions_backoffice.users'))




@routes.route('/users', methods=["GET", "POST"])
def users():
    
    data = DB.session.query(
        User,
        func.count(CorRoleActionFilterModuleObject.id_role)
    ).outerjoin(
        CorRoleActionFilterModuleObject, CorRoleActionFilterModuleObject.id_role == User.id_role
    ).group_by(
        User
    ).order_by(
        User.groupe.desc(),
        User.nom_role.asc()
    ).all()
    users = []
    for user in data:
        user_dict = user[0].as_dict()
        user_dict['nb_cruved'] = user[1]
        users.append(user_dict)
    return render_template('users.html',users=users, config=current_app.config)


@routes.route('/user_cruved/<id_role>', methods=["GET", "POST"])
def user_cruved(id_role):
    user = DB.session.query(User).get(id_role).as_dict()
    modules = [module.as_dict() for module in DB.session.query(TModules).all()]
    groupes_data = DB.session.query(CorRole).filter(CorRole.id_role_utilisateur==id_role).all()
    for module in modules:
        module['module_cruved'] = cruved_scope_for_user_in_module(id_role, module['module_code'])
    return render_template(
        'cruved_user.html',
        user=user,
        groupes=[groupe.role.as_dict() for groupe in groupes_data],
        modules=modules,
        config=current_app.config
    )