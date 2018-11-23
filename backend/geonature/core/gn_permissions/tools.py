import logging, json

from flask import current_app, redirect, Response

from itsdangerous import (TimedJSONWebSignatureSerializer as Serializer,
                          SignatureExpired, BadSignature)

import sqlalchemy as sa
from sqlalchemy.sql.expression import func


from pypnusershub.db.tools import (
    InsufficientRightsError,
    AccessRightsExpiredError, 
    UnreadableAccessRightsError
) 

from geonature.core.gn_permissions.models import VUsersPermissions
from geonature.utils.env import DB

log = logging.getLogger(__name__)

def user_from_token(token, secret_key=None):
    secret_key = secret_key or current_app.config['SECRET_KEY']

    try:
        s = Serializer(current_app.config['SECRET_KEY'])
        user = s.loads(token)
        return user
        
    except SignatureExpired:
        raise AccessRightsExpiredError("Token expired")

    except BadSignature:
        raise UnreadableAccessRightsError('Token BadSignature', 403)

def get_user_from_token_and_raise(
    request,
    secret_key=None,
    redirect_on_expiration=None,
    redirect_on_invalid_token=None
):
    """
    Deserialize the token
    catch excetpion and return appropriate Response(403, 302 ...)
    """
    try:
        token = request.cookies['token']
        return user_from_token(token, secret_key)

    except AccessRightsExpiredError:
        if redirect_on_expiration:
            res = redirect(redirect_on_expiration, code=302)
        else:
            res = Response('Token Expired', 403)
        res.set_cookie('token', expires=0)
        return res
    except InsufficientRightsError as e:
        log.info(e)
        if redirect_on_expiration:
            res = redirect(redirect_on_expiration, code=302)
        else:
            res = Response('Forbidden', 403)
        return res
    except KeyError as e:
        if 'token' not in e.args:
            raise
        if redirect_on_expiration:
            return redirect(redirect_on_expiration, code=302)
        return Response('No token', 403)

    except UnreadableAccessRightsError:
        log.info('Invalid Token : BadSignature')
        # invalid token,
        if redirect_on_invalid_token:
            res = redirect(redirect_on_invalid_token, code=302)
        else:
            res = Response('Token BadSignature', 403)
        res.set_cookie('token',  expires=0)
        return res

    except Exception as e:
        trap_all_exceptions = current_app.config.get(
            'TRAP_ALL_EXCEPTIONS',
            True
        )
        if not trap_all_exceptions:
            raise
        log.critical(e)
        msg = json.dumps({'type': 'Exception', 'msg': repr(e)})
        return Response(msg, 403)



def get_user_permissions(user, code_action, code_filter_type, module_code=None):
    """
        Get all the filters code of a user (could be multiples)
        for an action, a module and a filter_type
        Parameters:
            user(dict)
            code_action(str): <C,R,U,V,E,D>
            code_filter_type(str): <SCOPE, GEOGRAPHIC ...>
            module_code(str): 'GEONATURE', 'OCCTAX'
        Return:
            Array<VUsersPermissions>
    """
    id_role = user['id_role']

    ors = [VUsersPermissions.module_code.ilike('GEONATURE')]

    q = (
        VUsersPermissions
        .query
        .filter(VUsersPermissions.id_role == id_role)
        .filter(VUsersPermissions.code_action == code_action)
        .filter(VUsersPermissions.code_filter_type == code_filter_type)
    )
    module_code_for_error = 'GEONATURE'
    if module_code:
        ors.append(VUsersPermissions.module_code.ilike(module_code))
        module_code_for_error = module_code
    
    user_cruved = q.filter(sa.or_(*ors)).all()

    try:
        assert len(user_cruved) > 0
        return user_cruved
    except AssertionError:
        raise InsufficientRightsError(
            'User "{}" cannot "{}" in module/app "{}"'.format(
                id_role, code_action, module_code_for_error
            )
        )

def cruved_scope_for_user_in_module(
    id_role=None,
    module_code=None,
):
    """
    Return the user cruved for an application
    if no cruved for an app, the cruved parent module is taken
    Child app cruved alway overright parent module cruved 
    """
    ors = [VUsersPermissions.module_code == 'GEONATURE']

    q = DB.session.query(
        VUsersPermissions.code_action,
        func.max(VUsersPermissions.code_filter)
    ).distinct(VUsersPermissions.code_action).filter(
        VUsersPermissions.id_role == id_role
    ).filter(
        VUsersPermissions.code_filter_type == 'SCOPE'
    ).group_by(VUsersPermissions.code_action)

    # get max scope cruved for module GEONATURE
    parent_cruved = {
        action_scope[0]: action_scope[1]
        for action_scope in q.filter(VUsersPermissions.module_code.ilike('GEONATURE')).all() 
    }
    # get max scope cruved for module passed in parameter
    module_cruved = {}
    if module_code:
        module_cruved = {
            action_scope[0]: action_scope[1]
            for action_scope in q.filter(VUsersPermissions.module_code.ilike(module_code)).all()
        }
        
    # update cruved with child module if action exist, otherwise take geonature cruved
    update_cruved = {}
    cruved = ['C', 'R', 'U', 'V', 'E', 'D']
    for action in cruved:
        if action in module_cruved:
            update_cruved[action] = module_cruved[action]
        elif action in parent_cruved:
            update_cruved[action] = parent_cruved[action]
        else:
            update_cruved[action] = '0'
    return update_cruved



def get_or_fetch_user_cruved(
    session=None,
    id_role=None,
    module_code=None,
):
    """
        Check if the cruved is in the session
        if not, get the cruved from the DB with 
        cruved_for_user_in_app()
    """
    if module_code in session and 'user_cruved' in session[module_code]:
        return session[module_code]['user_cruved']
    else:
        user_cruved = cruved_scope_for_user_in_module(
            id_role=id_role,
            module_code=module_code,
        )
        session[module_code] = {}
        session[module_code]['user_cruved'] = user_cruved
    return user_cruved
