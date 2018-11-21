from flask import current_app

from itsdangerous import (TimedJSONWebSignatureSerializer as Serializer,
                          SignatureExpired, BadSignature)

import sqlalchemy as sa

from pypnusershub.db.tools import (
    InsufficientRightsError,
    AccessRightsExpiredError, 
    UnreadableAccessRightsError
) 

from geonature.core.permissions.models import VUsersPermissions


def user_from_token(token, secret_key=None):
    secret_key = secret_key or current_app.config['SECRET_KEY']

    try:
        s = Serializer(current_app.config['SECRET_KEY'])
        return s.loads(token)
        
    except SignatureExpired:
        raise AccessRightsExpiredError("Token expired")

    except BadSignature:
        raise UnreadableAccessRightsError('Token BadSignature', 403)

def get_user_from_token_and_raise(
    token,
    secret_key=None,
    redirect_on_expiration=None,
    redirect_on_invalid_token=None,
):
    """
    Deserialize the token
    catch excetpion and return appropriate Response(403, 302 ...)
    """
    try:
        user = user_from_token(token, secret_key)

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



def get_user_permissions(user, code_action, code_filter_type, code_module=None):
    """
        Get all the filters code of a user (could be multiples)
        for an action, a module and a filter_type
        Parameters:
            token(str)
            code_action(str): <C,R,U,V,E,D>
            code_filter_type(str): <SCOPE, GEOGRAPHIC ...>
            code_module(str): 'GEONATURE', 'OCCTAX'
        Return:
            Array<VUsersPermissions>
    """
    id_role = user['id_role']
    id_app_parent = user['id_application']

    ors = [VUsersPermissions.id_application == id_app_parent]
    q = (
        VUsersPermissions
        .query
        .filter(VUsersPermissions.id_role == id_role)
        .filter(VUsersPermissions.code_action == code_action)
        .filter(VUsersPermissions.code_filter_type == code_filter_type)
        .filter(VUsersPermissions.module_code.ilike('GEONATURE'))
    )
    module_code_for_error = 'GEONATURE'
    if code_module:
        q = q.filter(VUsersPermissions.module_code == code_module)
        module_code_for_error = code_module
    
    user_cruved = q.filter(sa.or_(*ors)).all()

    try:
        assert len(user_cruved) > 0
        return user_cruved
    except AssertionError:
        raise InsufficientRightsError(
            'User "{}" cannot "{}" in module/app "{}"'.format(
                id_role, action, module_code_for_error
            )
        )

