
Se connecter à d'autres fournisseurs d'identités
""""""""""""""""""""""""""""""""""""""""""""""""
Depuis la version 2.15, il est maintenant possible de se connecter à GeoNature à l'aide de fournisseurs d'identités externes (comme Google, GitHub ou INPN).
Pour cela, il est nécessaire d'implémenter le protocole de connexion pour permettre à GeoNature de communiquer avec ces fournisseurs.
Actuellement, GeoNature vient avec plusieurs protocoles de connexion implémentés, tels que :

- OpenID
- OpenIDConnect (OAuth2.0)
- GeoNature Externe

Ajouter un nouveau fournisseur d'identité
````````````````````````````````````````````

Pour ajouter un nouveau fournisseur d'identités à votre instance de GeoNature, vous devez ajouter une section ``[[AUTHENTICATION.PROVIDERS]]`` dans la partie ``AUTHENTICATION`` de votre fichier de configuration.
Chaque section doit comporter deux variables obligatoires: ``module`` et ``id_provider``. La variable ``module`` indique le chemin vers la classe Python qui implémente le protocole de connexion, tandis que ``id_provider`` indique l'identifiant unique du fournisseur d'identité.
Vous devez également ajouter les variables de configuration spécifiques au protocole de connexion correspondant.

Dans l'exemple ci-dessous, on déclare deux fournisseurs d'identités : le premier est le fournisseur d'identité par défaut (local) et le deuxième permet de se connecter à l'INPN.

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
    Les protocoles de connexion implémentés sont les suivants :
     - ``pypnusershub.auth.providers.default.LocalProvider`` : protocole de connexion par défaut dans GeoNature.
     - ``pypnusershub.auth.providers.cas_inpn_provider.AuthenficationCASINPN`` : CAS de l'INPN.
     - ``pypnusershub.auth.providers.openid_provider.OpenIDConnectProvider`` : OpenIDConnect.
     - ``pypnusershub.auth.providers.openid_provider.OpenIDProvider`` : OpenID.
     - ``pypnusershub.auth.providers.usershub_provider.ExternalUsersHubAuthProvider`` : Autre application utilisant ``UsersHub-authentification-module`` comme système d'authentification.
     
    Vous pouvez consulter la documentation détaillée sur le `lien suivant <https://github.com/PnX-SI/UsersHub-authentification-module?tab=readme-ov-file#param%C3%A8tres-de-configurations-des-protocoles-de-connexions-inclus>`_ pour obtenir la liste et les descriptions des paramètres de configuration de chaque protocole de connexion.

.. warning:: 
    Soyez prudent lors de la modification de la variable de configuration ``AUTHENTICATION.PROVIDERS``. Si vous n'indiquez pas le fournisseur d'identité par défaut, vous ne pourrez plus vous connecter à GeoNature avec l'authentification par défaut. Par conséquent, si vous souhaitez également utiliser l'authentification par défaut de GeoNature en plus d'un autre fournisseur d'identité, vous devez le redéclarer dans la configuration. (voir l'exemple ci-dessus)

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

Si les protocoles de connexion que nous avons implémentés ne vous suffisent pas, vous pouvez ajouter votre propre protocole de connexion en utilisant la classe ``pypnusershub.auth.Authentication``.

.. code:: python

    from marshmallow import Schema, fields
    from typing import Any, Optional, Tuple, Union

    from pypnusershub.auth import Authentication, ProviderConfigurationSchema
    from pypnusershub.db import models, db
    from flask import Response


    class NEW_PROVIDER(Authentication):
        is_external = True # si redirection vers un portail de connexion externe

        def authenticate(self, *args, **kwargs) -> Union[Response, models.User]:
            pass # doit retourner un utilisateur (User) ou rediriger (flask.Redirect) vers le portail de connexion du fournisseur d'identités

        def authorize(self):
            # appeler par /auth/authorize si redirection d'un portail de connexion externe
            pass # doit retourner un utilisateur

        def revoke(self):
            pass # si une action spécifique doit être faite lors de la déconnexion

        def configure(self, configuration: Union[dict, Any]):
            class SchemaConf(ProviderConfigurationSchema):
                VAR = fields.String(required=True)
            configuration = SchemaConf().load(configuration) # Si besoin d'un processus de validation
            ...# Configuration du fournisseur d'identités


.. note::
    Plus de détails sur la classe ``pypnusershub.auth.Authentication`` sont disponibles dans la documentation de l'`API <https://github.com/PnX-SI/UsersHub-authentification-module?tab=readme-ov-file#ajouter-son-propre-protocole-de-connexion>`_. 


Désactiver l'authentification par défaut
````````````````````````````````````````

Si vous souhaitez désactiver l'authentification par défaut au profit d'un ou plusieurs autres fournisseurs d'identités, il suffit de ne pas déclarer celui-ci dans la section `[[AUTHENTICATION.PROVIDERS]]` dans la partie `AUTHENTICATION` de la configuration.

.. note:: 
    Si un seul fournisseur d'identités (différent de l'authentification par défaut) est déclaré dans la section `[[AUTHENTICATION.PROVIDERS]]` de la configuration, l'utilisateur sera redirigé automatiquement vers le portail de connexion de ce dernier.
