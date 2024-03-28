class AuthManager:

    # TODO : que le authentication_cls soit un tableau de provider d'autentification disponible
    # pour qu'on puisse fournir plusieurs mécanisme d'authent : Github, CAS, autre GeoNature etc...
    def __init__(self) -> None:
        self.authentication_cls = None

    def init_app(self, app):
        app.auth_manager = self

    def set_auth_provider(self, provider_cls):
        self.authentication_cls = provider_cls


auth_manager = AuthManager()
