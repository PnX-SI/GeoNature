from pypnusershub.authentification import Authentification, DefaultConfiguration


class AuthManager:
    """
    Manages authentication providers.
    """

    def __init__(self) -> None:
        """
        Initializes the AuthManager instance.
        """
        self.provider_authentication_cls = {"default": DefaultConfiguration}
        self.selected_provider = "default"

    def __contains__(self, item) -> bool:
        """
        Checks if a provider is registered.

        Parameters
        ----------
        item : str
            The provider name.

        Returns
        -------
        bool
            True if the provider is registered, False otherwise.
        """
        return item in self.provider_authentication_cls

    def add_provider(self, provider_name: str, provider_authentification: Authentification) -> None:
        """
        Registers a new authentication provider.

        Parameters
        ----------
        provider_name : str
            The name of the provider.
        provider : Authentification
            The authentication provider class.

        Returns
        -------
        None

        Raises
        ------
        AssertionError
            If the provider is not an instance of Authentification.
        """
        if not issubclass(provider_authentification, Authentification):
            raise AssertionError("Provider must be an instance of Authentification")
        self.provider_authentication_cls[provider_name] = provider_authentification

    def init_app(self, app) -> None:
        """
        Initializes the Flask application with the AuthManager.

        Parameters
        ----------
        app : Flask
            The Flask application instance.

        Returns
        -------
        None
        """
        app.auth_manager = self

    def get_current_provider(self) -> Authentification:
        """
        Returns the current authentication provider.

        Returns
        -------
        Authentification
            The current authentication provider.
        """
        return self.provider_authentication_cls[self.selected_provider]()

    def set_auth_provider(
        self, provider_name: str, provider_authentification_cls: Authentification = None
    ) -> None:
        """
        Sets the authentication provider.

        Parameters
        ----------
        provider_name : str
            The name of the provider.
        provider_cls : Authentification, optional
            The authentication provider class, by default None.

        Returns
        -------
        None
        """
        if provider_authentification_cls and provider_name not in self:
            self.add_provider(provider_name, provider_authentification_cls)
        self.selected_provider = provider_name
        return self.get_current_provider()


auth_manager = AuthManager()
