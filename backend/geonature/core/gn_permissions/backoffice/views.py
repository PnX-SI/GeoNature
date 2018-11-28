from flask import request, render_template, Blueprint

from sqlalchemy.exc import IntegrityError 

from geonature.utils.env import DB 
from geonature.core.gn_permissions.backoffice.forms import CruvedScope
from geonature.core.gn_permissions.tools import cruved_scope_for_user_in_module
from geonature.core.gn_permissions.models import(
    TFilters, BibFiltersType, TActions,
    CorRoleActionFilterModuleObject
)
from geonature.core.gn_commons.models import TModules

from pypnusershub.db.models import User

routes = Blueprint('gn_permissions_backoffice', __name__, template_folder='templates')

@routes.route('cruved_form/<int:id_module>/<int:id_role>', methods=["GET", "POST"])
def permission_form(id_module, id_role):
    form = CruvedScope(request.form)
    form.init_choices()
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
    return render_template('cruved_scope_form.html',form=form) 


@routes.route('/users', methods=["GET", "POST"])
def users():
    users = [user.as_dict() for user in DB.session.query(User).all()]
    
    return render_template('users_modules.html',users=users)


@routes.route('/user/<id_role>', methods=["GET", "POST"])
def user_cruved(id_role):
    user = DB.session.query(User).get(id_role).as_dict()
    modules = [module.as_dict() for module in DB.session.query(TModules).all()]
    for module in modules:
        print(module)
        module['module_cruved'] = cruved_scope_for_user_in_module(id_role, module['module_code'])
    #modules = [module.as_dict() for module in DB.session.query(TModules).all()]
    return render_template(
        'cruved_user.html',
        user=user,
        modules=modules
    )