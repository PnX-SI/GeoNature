from flask import request, render_template, Blueprint, flash, current_app

from sqlalchemy.exc import IntegrityError 

from geonature.utils.env import DB 
from geonature.core.gn_permissions.backoffice.forms import CruvedScopeForm
from geonature.core.gn_permissions.tools import cruved_scope_for_user_in_module
from geonature.core.gn_permissions.models import(
    TFilters, BibFiltersType, TActions,
    CorRoleActionFilterModuleObject
)
from geonature.core.gn_commons.models import TModules

from pypnusershub.db.models import User

routes = Blueprint('gn_permissions_backoffice', __name__, template_folder='templates')

@routes.route('cruved_form/module/<int:id_module>/role/<int:id_role>', methods=["GET", "POST"])
def permission_form(id_module, id_role):
    form = None
    if request.method == 'GET':
        module = DB.session.query(TModules).get(id_module)
        user = DB.session.query(User).get(id_role)
        cruved = cruved_scope_for_user_in_module(id_role, module.module_code, get_id=True)
        form = CruvedScopeForm(**cruved)

        # check if user is a group
        if not user.groupe:
            flash(
                "Préferez l'attribution du CRUVED à des groupes plutôt qu'à des utilisateurs"
                )
                
        # get the real cruved of user to set a warning
        real_cruved = DB.session.query(CorRoleActionFilterModuleObject).filter(
            CorRoleActionFilterModuleObject.id_module == id_module
        ).filter(
            CorRoleActionFilterModuleObject.id_role == id_role
        ).all()
        if len(real_cruved) == 0:
            flash(
                "Attention ce role n'a pas encore de CRUVED. Celui-ci lui est hérité de son groupe et/ou du module parent GEONATURE"
            )

    else:
        form = CruvedScopeForm(request.form)
        if form.validate_on_submit():
            actions_id = {
                action.code_action: action.id_action
                for action in DB.session.query(TActions).all()
            }
            for code_action, id_action in actions_id.items():
                if form.data.get(code_action):
                    permission_row = CorRoleActionFilterModuleObject(
                        id_role=1,
                        id_action=id_action,
                        id_filter = int(form.data[code_action]),
                        id_module=id_module,
                        id_object=id_role
                    )
                    DB.session.add(permission_row)
            try:
                DB.session.commit()
            except IntegrityError:
                pass
    return render_template(
        'cruved_scope_form.html',
        form=form,
        user=user,
        module=module,
        config=current_app.config
    ) 


@routes.route('/users', methods=["GET", "POST"])
def users():
    users = [user.as_dict() for user in DB.session.query(User).all()]
    
    return render_template('users.html',users=users, config=current_app.config)


@routes.route('/user/<id_role>', methods=["GET", "POST"])
def user_cruved(id_role):
    user = DB.session.query(User).get(id_role).as_dict()
    modules = [module.as_dict() for module in DB.session.query(TModules).all()]
    for module in modules:
        module['module_cruved'] = cruved_scope_for_user_in_module(id_role, module['module_code'])
    return render_template(
        'cruved_user.html',
        user=user,
        modules=modules,
        config=current_app.config
    )