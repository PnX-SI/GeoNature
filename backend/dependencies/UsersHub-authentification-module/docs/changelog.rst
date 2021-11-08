CHANGELOG
*********

1.5.7 (2021-10-17)
------------------

**🐛 Corrections**

* Correction d’un fichier de migration Alembic

1.5.6 (2021-10-18)
------------------

**🐛 Corrections**

* Correction d’un fichier de migration Alembic

1.5.5 (2021-10-13)
------------------

**🚀 Nouveautés**

* La route de login est désormais capable de récupèrer l’``id_app`` depuis la configuration Flask

**🐛 Corrections**

* Correction d’un fichier de migration Alembic (suppression d’une vue avant sa création)

1.5.4 (2021-10-06)
------------------

**🐛 Corrections**

* Suppression des ``id_organisme`` en dur dans les données d’exemple

1.5.3 (2021-09-29)
------------------

**🐛 Corrections**

* Ajout d’un fichier ``__init__.py`` dont l’absence excluait les révisions Alembic lors du paquetage du module

1.5.2 (2021-09-29)
------------------

**🚀 Nouveautés**

* Ajout d’un champs JSONB ``additional_data`` à la table ``bib_organismes``
* Ajout d’une contrainte d’unicité sur ``bib_organismes.uuid_organisme`` (permet d’utiliser ``ON CONFLICT UPDATE``)
* Possibilité d’installer le schéma ``utilisateurs`` avec Alembic sans passer par une application Flask telle que UsersHub (voir documentation)
* Utilisation d’un dictionnaire ``REGISTER_POST_ACTION_FCT`` pour déclarer les callbacks de post-actions plutôt que l’entrée ``after_USERSHUB_request`` dans la config de Flask

**🐛 Corrections**

* Correction de la vue ``v_roleslist_forall_applications`` (``LEFT JOIN``)
* Correction des SQL d’installation : les évolutions sont amenées par les migrations Alembic


1.5.1 (2021-09-07)
------------------

**🐛 Corrections**

* Corrections du packaging des migrations


1.5.0 (2021-09-06)
------------------

**🚀 Nouveautés**

* Gestion du schéma ``utilisateurs`` avec alembic par ce module (et non plus dans UsersHub)

**🐛 Corrections**

* Corrections mineurs des modèles


1.4.7 (2021-07-22)
------------------

**🚀 Nouveautés**

* Amélioration des messages et e-mails utilisateurs

**🐛 Corrections**

* Corrections de 2 bugs mineurs


1.4.6 (2021-06-03)
------------------

**🚀 Nouveautés**

* Ajout du modèle Organisme et de la table de correspondance ``cor_role``
* Support de la méthode de mot de passe ``hash`` via l’attribut du modèle
* Amélioration des relationships
* Utilisation de @serializable sur les modèles
* Ajout des schémas Marshmallow

**🐛 Corrections**

* Correction du nom d’un n° de séquence


1.4.5 (2021-02-24)
------------------

**🚀 Nouveautés**

* Passage de l'instance de SQLAlchemy du module parent via une variable d'environnement

**🐛 Corrections**

* Les dépendances du fichier ``requirements.txt`` ne sont plus fixées à une version


1.4.4 (2020-10-17)
------------------

**Nouveautés**

* Ajout du nom complet dans le modèle `User` en tant que propriété hybride
* Mise à jour des dépendances (psycopg2 et SQLAlchemy)
* Ajout de l'url de confirmation dans le modèle `TempUser`


1.4.3 (2019-12-18)
------------------

**Corrections**

* Adaptation des méthodes ``as_dict()`` pour compatibilité avec la lib utils-flask-sqla (paramètres ``relationships`` et ``depth``)


1.4.2 (2019-10-08)
------------------

**Corrections**

* Echappement des balises HTML sur le retour de la route "/login" pour corriger une faille XSS (fausse faille car inexploitable)


1.4.1 (2019-09-17)
------------------

**Corrections**

* Correction de la serialisation du modèle TempUser

1.4.0 (2019-09-16)
------------------

**Nouveautés**

* Ajout de routes permettant d'utiliser les actions de gestion de compte de l'API de UsersHub (création d'utilisateurs temporaires, ajout de droits à un utilisateur, récupération des droits d'un utilisateur...) #23
* Ajout d'un mécanisme de proxy permettant d'effectuer des "post_actions" sur chacune des routes de gestion de compte (envoi d'email, gestion applicative)
* Documentation de l'API (https://github.com/PnX-SI/UsersHub-authentification-module/blob/master/README.md#utilisation-de-lapi)
* Mise à jour de Flask (1.0.2 vers 1.1.1)

**Corrections**

* Corrections, optimisations, nettoyage et refactorisations diverses

1.3.3 (2019-05-29)
------------------

**Nouveautés**

* Mise à jour de SQLAlchemy 1.1.13 vers 1.3.3

1.3.2 (2019-02-27)
------------------

**Nouveautés**

* Ajout d'un callback de redirection lorsque les droits sont insuffisants sur le décorateur ``check_auth`` (``redirect_on_insufficient_right``)

**Corrections**

* Correction de conflit d'authentification et de permissions entre les différentes applications utilisant le sous-module sur le même domaine (vérification que le token correspond à l'application courante).

Note pour les développeurs : ce conflit est corrigé en ajoutant un paramètre ``ID_APP`` dans la configuration des applications utilisant ce sous-module (``config.py``). La vérification que le token correspond bien à l'application courante n'est pas assuré si ce paramètre n'est pas passé, pour des raisons de rétro-compatibilité.

1.3.1 (2019-01-15)
------------------

**Corrections**

* Ajout de la classe ``AppRole`` au modèle
* Redirection si les droits de l'utilisateur sont insuffisants

1.3.0 (2019-01-14)
------------------

**Nouveautés**

* Compatibilité avec la version 2 UsersHub
* Suppression des routes et objets du modèle lié au CRUVED qui a été retiré de UsersHub pour le basculer dans GeoNature
* Optimisation des accès à la BDD en utilisant l'instance ``DB`` de l'application dans laquelle est utilisée ce sous-module

**Corrections**

* Précisions dans la documentation (README) sur le script SQL à utiliser depuis le dépôt de UsersHub
* Suppression des scripts SQL locaux pour se n'utiliser que ceux à jour dans le dépôt de UsersHub

1.2.1 (2018-10-08)
------------------

**Corrections**

* Ajout d'un test sur la fonction ``fn_check_password`` pour vérifier si le mot de passe existe

1.2.0 (2018-09-19)
------------------

* Modification de la route de login pour se connecter sans passer par la table ``cor_role_droit_application`` lorsqu'on fonctionne avec le CRUVED
* Mise à jour des dépendances (``requirements.txt``)
* Mise à jour de Flask (0.12.2 à 1.0.2)

**Corrections**

* Correction des droits des applications filles retournées lors du login
* Correction de la redirection après logout

1.1.1 (2018-06-18)
------------------

* Version corrective lié à la récupération du CRUVED des sous-modules

1.1.0 (2018-05-17)
------------------

**Nouveautés**

* Répercussion du changement du modèle de UsersHub. Le sous-module permet maintenant l'authentification en utilisant une des deux méthode de cryptage de mot de passe (MD5 et HASH). Ajout du paramètre ``PASS_METHOD`` (valeur possible : 'hash' ou 'md5') qui contrôle ce comportement.
* Prise en compte des évolutions de la version 1.3.1 de UsersHub intégrant la gestion des droits utilisateurs via des 'tags'.
* Ajout de fonctionnalités nécessaires à GeoNature v2 (gestion des droits avec le CRUVED) :

  * Ajout du décorateur ``@check_auth_cruved`` pour protéger les routes en passant paramètre une action du CRUVED et une application ou un module.
  * Fonction ``cruved_for_user_in_app`` permettant de récupérer le CRUVED d'un utilisateur
* Corrections diverses

**Notes de version**

Cette release n'est compatible avec UsersHub 1.3.1 minimum, qui inclut d'importantes évolutions de la BDD (https://github.com/PnEcrins/UsersHub/blob/develop/data/update_1.3.0to1.3.1.sql).


1.0.2 (2017-12-15)
------------------

**Nouveautés**

Intégration des pull request de @ksamuel 

* Ajout des paramètres : 

  * redirect_on_invalid_token 
  * redirect_on_expiration

* Diverse petites améliorations

1.0.1 (2017-03-10)
------------------

**Nouveautés**

Intégration de la pull request de @ksamuel.

###  Models:

* nouvelles classes pour mapper les tables `bib_droits` et `cor_role_droit_application`
* la classe User utilise md5 pour hasher son password au lieu de sha256. Il faudrait alerter UsersHub de changer le hashing de leur password pour un algo plus robuste et avec un salt. Mais en attendant on doit utiliser le leur.
* `__repr__` pour faciliter le debuggage
* AppUser n'a plus de setter sur le password puisque c'est une vue en lecture seule

###  Auth workflow:

* exceptions plus granulaires et exceptions personnalisées
* obtenir un objet User depuis un token est maintenant une fonction indépendante
* ajout d'une vue pour le log out
* pas de renouvellement de cookie si le token est vide ou en cours d'écriture
* redirection optionnelle sur check_auth
* usage optionnel des codes HTTP standards pour les erreurs
* le modèle user est maintenant attaché à Flask.g
* COOKIE_AUTORENEW passe sur True par défaut pour éviter d'avoir à setter la valeur pour les projets existant. Une erreur de ma part dans la première PR.

1.0.0 (2017-03-03)
------------------

Première version stable du sous-module d'authentification.

Le module peut désormais être intégré de façon indépendante (merci @ksamuel).

0.1.0 (2016-07-07)
------------------

Première version du sous-module d'authentification de UsersHub (https://github.com/PnEcrins/UsersHub/). 

Il permet d'intégrer une authentification dans une application tiers en se basant sur la base de données centralisée de UsersHub.
