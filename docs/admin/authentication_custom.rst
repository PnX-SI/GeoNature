
Se connecter à d'autres fournisseurs d'identité
"""""""""""""""""""""""""""""""""""""""""""""""
Depuis la version 2.3 du module ``UsersHub-authentification-module``, il est maintenant possible de se connecter à GeoNature à l'aide de fournisseurs d'identités externes (comme Google, GitHub ou INPN).
Pour cela, il est nécessaire d'implémenter le protocole de connexion pour permettre à GeoNature de communiquer avec ces fournisseurs.
Par défaut, GeoNature vient avec plusieurs protocoles de connexion implémentés, tels que :

- OpenID
- OpenIDConnect (OAuth2.0)
- GeoNature Externe

Configurer un nouveau fournisseur d'identité
````````````````````````````````````````````

Pour ajouter un nouveau fournisseur d'identité à votre instance de GeoNature, vous devez ajouter une section ``[[AUTHENTICATION.PROVIDERS]]`` dans la partie ``AUTHENTICATION`` de votre fichier de configuration.
Chaque section doit comporter deux variables obligatoires: ``module`` et ``id_provider``. La variable ``module`` indique le chemin vers la classe Python qui implémente le protocole de connexion, tandis que ``id_provider`` indique l'identifiant unique du fournisseur d'identité.
Vous pouvez également ajouter des variables de configuration spécifiques au protocole de connexion correspondant.
Dans l'exemple ci-dessous, on déclare deux fournisseurs d'identités: le premier est le fournisseur d'identité par défaut (local) et le deuxième permet de se connecter à l'INPN.

.. code:: toml

    [AUTHENTICATION]
        DEFAULT_RECONCILIATION_GROUP_ID = 2
        [[AUTHENTICATION.PROVIDERS]]
            module="pypnusershub.auth.providers.default.LocalProvider"
            id_provider="local_provider"
            
        [[AUTHENTICATION.PROVIDERS]]
            module="pypnusershub.auth.providers.cas_inpn_provider.AuthenficationCASINPN"
            id_provider="connexion_inpn_1"
            WS_ID ="secret"
            WS_PASSWORD ="secret"

.. note:: 
    La list des protocoles de connexion implémentés :
     - ``pypnusershub.auth.providers.default.LocalProvider`` : protocole de connexion par défaut dans GeoNature.
     - ``pypnusershub.auth.providers.cas_inpn_provider.AuthenficationCASINPN`` : CAS de l'INPN.
     - ``pypnusershub.auth.providers.openid_provider.OpenIDConnectProvider`` : OpenIDConnect.
     - ``pypnusershub.auth.providers.openid_provider.OpenIDProvider`` : OpenID.
     - ``pypnusershub.auth.providers.usershub_provider.ExternalUsersHubAuthProvider`` : Autre application utilisant ``UsersHub-authentification-module`` comme système d'authentification.

.. warning:: 
    Soyez prudent lors de la modification de la variable de configuration ``AUTHENTICATION.PROVIDERS``. Si vous supprimez le fournisseur d'identité par défaut, vous ne pourrez plus vous connecter à GeoNature avec l'authentification par défaut. Par conséquent, si vous souhaitez également utiliser l'authentification par défaut de GeoNature en plus d'un autre fournisseur d'identité, vous devez redéclarer celui-ci dans la configuration. (voir exemple ci-dessus)

Se connecter à un autre GeoNature
``````````````````````````````````

Si vous souhaitez ajouter le moyen de se connecter à l'aide d'un autre GeoNature, nous avons crée un module décrivant le protocole de connexion nécessaire : ``pypnusershub.auth.providers.usershub_provider.ExternalUsersHubAuthProvider``.

Pour utiliser ce dernier, ajouter la section ``[[AUTHENTICATION.PROVIDERS]]`` suivante dans la partie ``AUTHENTICATION`` de la configuration : 

.. code:: toml
    
    [[AUTHENTICATION.PROVIDERS]]
        module="pypnusershub.auth.providers.usershub_provider.ExternalUsersHubAuthProvider"
        id_provider="autre_geonature"
        login_url="<UrlVersAPIdeVotreGeoNature>/login"
        logout_url="<UrlVersAPIdeVotreGeoNature>/logout"

Créer son propre module de connexion
````````````````````````````````````

Si les protocoles de connexion que nous avons implémentés ne sont pas suffisant pour votre application, vous pouvez ajouter votre propre protocole de connexion à l'aide de la classe ``pypnusershub.auth.Authentication``.

.. code:: python

    from marshmallow import Schema, fields
    from typing import Any, Optional, Tuple, Union

    from pypnusershub.auth import Authentication, ProviderConfigurationSchema
    from pypnusershub.db import models, db
    from flask import Response


    class NEW_PROVIDER(Authentication):
        is_external = True # go through an external connection portal

        def authenticate(self, *args, **kwargs) -> Union[Response, models.User]:
            pass # doit retourner un utilisateur (User) ou rediriger (flask.Redirect) vers le portail de connexion du fournisseur d'identités

        def authorize(self):
            # appeler par /auth/authorize si redirection d'un portail de connexion externe
            pass # doit retourner un utilisateur

        def revoke(self):
            pass # si une action spécifique doit être faite lors de la déconnexion

        def configure(self, configuration: Union[dict, Any]):
            pass # Indique la configuration d'un fournisseur d'identités


.. note::
    Plus de détails sur la classe ``pypnusershub.auth.Authentication`` sont disponibles dans la documentation de l'`API <https://github.com/PnX-SI/UsersHub-authentification-module>`_. 
