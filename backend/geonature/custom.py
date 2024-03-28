# a supprimer et gitignorer :
# ici pour exemple

from geonature.auth_manager import auth_manager


class CASAuthProvider:
    # la class du CAS
    pass


auth_manager.set_auth_provider(CASAuthProvider)
