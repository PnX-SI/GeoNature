DEVELOPPEMENT
=============

Général
-------

GeoNature a été développé par Gil Deluermoz depuis 2010 avec PHP/Symfony/ExtJS.

En 2017, les parcs nationaux français ont décidé de refondre GeoNature complètement avec une nouvelle version (V2) réalisée en Python/Flask/Angular 4. 

Mainteneurs : 

- Gil DELUERMOZ (PnEcrins) : Base de données / SQL / Installation / Mise à jour
- Amandine SAHL (PnCevennes) : Backend / Python Flask / API
- Theo LECHEMIA (PnEcrins) : Frontend / Angular 4
- Camille MONCHICOURT (PnEcrins) : Documentation / Gestion du projet


API
---

GeoNature utilise : 

- l'API de TaxHub (recherche taxon, règne et groupe d'un taxon...)
- l'API du sous-module Nomenclatures (typologies et listes déroulantes)
- l'API du sous-module d'authentification de UsersHub (login/logout, récupération du CRUVED d'un utilisateur)
- l'API de GeoNature (get, post, update des données des différents modules, métadonnées, intersections géographiques, exports...)

Pour avoir des infos et la documentation de ces API, on utilise PostMan. Documentation API : https://documenter.getpostman.com/view/2640883/RWaPskTw

.. image :: https://raw.githubusercontent.com/PnX-SI/GeoNature/develop/docs/images/api_services.png


*@TODO : Doc API à mettre à jour*

Release
-------

Pour sortir une nouvelle version de GeoNature : 

- Faites les éventuelles Releases des dépendances (UsersHub, TaxHub, UsersHub-authentification-module, Nomenclature-api-module, GeoNature-atlas)
- Mettez à jour la version de GeoNature et éventuellement des dépendances dans ``install/install_all/install_all.ini``, ``config/settings.ini.sample``, ``backend/requirements.txt`` et ``backend/requirements-travis.txt``
- Compléter le fichier ``docs/CHANGELOG.rst`` (en comparant les branches https://github.com/PnX-SI/GeoNature/compare/develop) et dater la version à sortir
- Mettez à jour le fichier ``VERSION``
- Remplir le tableau de compatibilité des dépendances (``docs/versions-compatibility.rst``)
- Mergez la branche ``develop`` dans la branche ``master``
- Faites la release (https://github.com/PnX-SI/GeoNature/releases) en la taguant ``X.Y.Z`` (sans ``v`` devant) et en copiant le contenu du Changelog
- Dans la branche ``develop``, modifiez le fichier ``VERSION`` en ``X.Y.Z.dev0`` et pareil dans le fichier ``docs/CHANGELOG.rst``

Pratiques
---------

- Ne jamais faire de commit dans la branche ``master`` mais dans la branche ``develop`` ou idéalement dans une branche dédiée à la fonctionnalité
- Faire des pull request vers la branche ``develop`` regroupant plusieurs commits depuis la branche de sa fonctionnalité pour plus de lisibilité, éviter les conflits et déclencher les tests automatiques Travis avant d'intégrer la branche ``develop``
- Faire des ``git pull`` avant chaque développement et avant chaque commit
- Les messages de commits font référence à ticket ou le ferme (``ref #12`` ou ``fixes #23``)

Développer et installer un gn_module
------------------------------------

GeoNature a été conçu pour fonctionner en briques modulaires.

Chaque protocole, répondant à une question scientifique, est amené à avoir son propre module GeoNature comportant son modèle de base de données, son API et son interface utilisateur.

Les modules développés s'appuieront sur le coeur de GeoNature qui est constitué d'un ensemble de briques réutilisables.

En base de données, le coeur de GeoNature est constitué de l'ensemble des référentiels (utilisateurs, taxonomique, géographique)
et du schéma ``synthese`` regroupant l'ensemble données saisies dans les différents protocoles.

L'API du coeur (`voir doc <https://github.com/PnX-SI/GeoNature/blob/develop/docs/development.rst#api>`__) permet d'interroger les schémas de la base de données "coeur" de GeoNature.

Du côté interface utilisateur, GeoNature met à disposition un ensemble de composants Angular réutilisables (`voir doc <https://github.com/PnX-SI/GeoNature/blob/develop/docs/development.rst#d%C3%A9veloppement-frontend>`__), pour l'affichage
des cartes, des formulaires etc...

Développer un gn_module
"""""""""""""""""""""""

Avant de développer un gn_module, assurez-vous d'avoir GeoNature bien installé sur votre machine (`voir doc <https://github.com/PnX-SI/GeoNature/blob/develop/docs/installation-standalone.rst>`__).

Afin de pouvoir connecter ce module au "coeur", il est impératif de suivre une arborescence prédéfinie par l'équipe GeoNature.

Voici la structure minimale que le module doit comporter (voir le dossier `contrib <https://github.com/PnX-SI/GeoNature/tree/develop/contrib/module_example>`__ de GeoNature pour trouver un exemple) :

- Le module se placera dans un dossier à part du dossier "GeoNature" et portera le suffixe "gn_module"

  Exemple : *gn_module_validation*

- La racine du module comportera les fichiers suivants : 

  - ``install_app.sh`` : script bash d'installation des librairies python ou npm necessaires au module
  - ``install_env.sh`` : script bash d'installation des paquets Linux
  - ``requirements.txt`` : liste des librairies python necessaires au module
  - ``manifest.toml`` : fichier de description du module (nom, version du module, version de GeoNature compatible)
  - ``conf_gn_module.toml`` : fichier de configuration de l'application (livré en version sample)
  - ``conf_schema_toml.py`` : schéma 'marshmallow' (https://marshmallow.readthedocs.io/en/latest/) du fichier de configuration (permet de s'assurer la conformité des paramètres renseignés par l'utilisateur). Ce fichier doit contenir une classe ``GnModuleSchemaConf`` dans laquelle toutes les configurations sont synchronisées.
  - ``install_gn_module.py`` : script python lançant les commandes relatives à l'installation du module (Base de données, ...). Ce fichier doit comprendre une fonction ``gnmodule_install_app(gn_db, gn_app)`` qui est utilisée pour installer le module (Voir l'`exemple du module validation <https://github.com/PnX-SI/gn_module_validation/blob/master/install_gn_module.py>`__)
 

- La racine du module comportera les dossiers suivants :

  - ``backend`` : dossier comportant l'API du module utilisant un blueprint Flask
    
    - Le fichier ``blueprint.py`` comprend les routes du module (ou instancie les nouveaux blueprints du module)
    - Le fichier ``models.py`` comprend les modèles SQLAlchemy des tables du module.
  
  - ``frontend`` : le dossier ``app`` comprend les fichiers typescript du module, et le dossier ``assets`` l'ensemble des médias (images, son).

    - Le dossier ``app`` doit comprendre le "module Angular racine", celui-ci doit impérativement s'appeler ``gnModule.module.ts`` 
    - Le dossier ``app`` doit contenir un fichier ``module.config.ts``. Ce fichier est automatiquement synchronisé avec le fichier de configuration du module ``<GEONATURE_DIRECTORY>/external_modules/<nom_module>/conf_gn_module.toml`` grâce à la commande ``geonature update_module_configuration <nom_module>``. C'est à partir de ce fichier que toutes les configuration doivent pointer.
    - A la racine du dossier ``frontend``, on retrouve également un fichier ``package.json`` qui décrit l'ensemble des librairies JS necessaires au module.
      
  - ``data`` : ce dossier comprenant les scripts SQL d'installation du module


Bonnes pratiques
""""""""""""""""

Frontend
********

- Pour l'ensemble des composants cartographiques et des formulaires (taxonomie, nomenclatures...), il est conseillé d'utiliser les composants présents dans le module 'GN2CommonModule'.
  
  Importez ce module dans le module racine de la manière suivante :

  ::

    import { GN2CommonModule } from '@geonature_common/GN2Common.module';

- Les librairies JS seront installées par npm dans un dossier ``node_modules`` à la racine du dossier ``frontend`` du module. (Il n'est pas nécessaire de réinstaller toutes les librairies déjà présentes dans GeoNature (Angular, Leaflet, ChartJS ...). Le ``package.json`` de GeoNature liste l'ensemble des librairies déjà installées et réutilisable dans le module.

Lancer ``npm init`` pour initialiser le module.

- Les fichiers d'assets sont à ranger dans le dossier ``assets`` du frontend. Angular-cli impose cependant que tous les assets soient dans le répertoire mère de l'application (celui de GeoNature). Un lien symbolique est créé à l'installation du module pour faire entre le dossier d'assets du module et celui de Geonature.

Pour les utiliser à l'interieur du module, utiliser la syntaxe suivante :

::

    <img src="external_assets/<MY_MODULE_NAME>/afb.png">

Exemple pour le module de validation :

::

    <img src="external_assets/<gn_module_validation>/afb.png">

- Installer le linter ``tslint`` dans son éditeur de texte (TODO: définir un style à utiliser) 

Backend
*******

- Respecter la norme PEP8


Installer un gn_module
""""""""""""""""""""""

Renseignez l'éventuel fichier ``config/settings.ini`` du module.

Pour installer un module, rendez vous dans le dossier ``backend`` de GeoNature.

Activer ensuite le virtualenv pour rendre disponible les commandes GeoNature :

::

    source venv/bin/activate

Lancez ensuite la commande : 

::

    geonature install_gn_module <mon_chemin_absolu_vers_le_module> <url_api>

Le premier paramètre est l'emplacement absolu du module sur votre machine et le 2ème le chemin derrière lequel on retrouvera les routes de l'API du module.

Exemple pour atteindre les routes du module de validation à l'adresse 'http://mon-geonature.fr/api/geonature/validation'

Cette commande exécute les actions suivantes :

- Vérification de la conformité de la structure du module (présence des fichiers et dossiers obligatoires)
- Intégration du blueprint du module dans l'API de GeoNature
- Vérification de la conformité des paramètres utilisateurs
- Génération du routing Angular pour le frontend
- Re-build du frontend pour une mise en production

Complétez l'éventuelle configuration du module (``config/conf_gn_module.toml``) à partir des paramètres présents dans ``config/conf_gn_module.toml.example`` dont vous pouvez surcoucher les valeurs par défaut. Puis relancez la mise à jour de la configuration (depuis le répertoire ``geonature/backend`` et une fois dans le venv (``source venv/bin/activate``) : ``geonature update_module_configuration nom_du_module``)


Développement Backend
----------------------

Démarrage du serveur de dev backend
"""""""""""""""""""""""""""""""""""

    ::

    (venv)...$ geonature dev_back


Base de données
"""""""""""""""

Session sqlalchemy
******************

- ``geonature.utils.env.DB``


Fournit l'instance de connexion SQLAlchemy


Python ::

    from geonature.utils.env import DB

    result = DB.session.query(MyModel).get(1)


Serialisation des modèles
"""""""""""""""""""""""""


- ``geonature.utils.utilssqlalchemy.serializable``

Décorateur pour les modèles SQLA : Ajoute une méthode as_dict qui retourne un dictionnaire des données de l'objet sérialisable json


Fichier définition modèle ::

    from geonature.utils.env import DB
    from geonature.utils.utilssqlalchemy import serializable

    @serializable
    class MyModel(DB.Model):
        __tablename__ = 'bla'
        ...


Fichier utilisation modele ::

    instance = DB.session.query(MyModel).get(1)
    result = instance.as_dict()



- ``geonature.utils.utilssqlalchemy.geoserializable``


Décorateur pour les modèles SQLA : Ajoute une méthode as_geofeature qui retourne un dictionnaire serialisable sous forme de Feature geojson.


Fichier définition modèle ::

    from geonature.utils.env import DB
    from geonature.utils.utilssqlalchemy import geoserializable

    @geoserializable
    class MyModel(DB.Model):
        __tablename__ = 'bla'
        ...


Fichier utilisation modele ::

    instance = DB.session.query(MyModel).get(1)
    result = instance.as_geofeature()

- ``geonature.utils.utilsgeometry.shapeserializable``

Décorateur pour les modèles SQLA:

- Ajoute une méthode ``as_list`` qui retourne l'objet sous forme de tableau (utilisé pour créer des shapefiles)
- Ajoute une méthode de classe ``to_shape`` qui crée des shapefiles à partir des données passées en paramètre 

Fichier définition modèle ::

    from geonature.utils.env import DB
    from geonature.utils.utilsgeometry import shapeserializable

    @shapeserializable
    class MyModel(DB.Model):
        __tablename__ = 'bla'
        ...


Fichier utilisation modele ::


    # utilisation de as_shape()
    data = DB.session.query(MyShapeserializableClass).all()
    MyShapeserializableClass.as_shape(
        geom_col='geom_4326',
        srid=4326,
        data=data,
        dir_path=str(ROOT_DIR / 'backend/static/shapefiles'),
        file_name=file_name
    )

- ``geonature.utils.utilsgeometry.FionaShapeService``

Classe utilitaire pour crer des shapefiles.

La classe contient 3 méthode de classe:

- FionaShapeService.create_shapes_struct(): crée la structure de 3 shapefiles (point, ligne, polygone) à partir des colonens et de la geom passé en paramètre

- FionaShapeService.create_feature(): ajoute un enregistrement aux shapefiles

- FionaShapeService.save_and_zip_shapefiles(): sauvegarde et zip les shapefiles qui ont au moin un enregistrement

::

        data = DB.session.query(MySQLAModel).all()
        
        for d in data:
                FionaShapeService.create_shapes_struct(
                        db_cols=db_cols,
                        srid=current_app.config['LOCAL_SRID'],
                        dir_path=dir_path,
                        file_name=file_name,
                        col_mapping=current_app.config['SYNTHESE']['EXPORT_COLUMNS']
                )
        FionaShapeService.create_feature(row_as_dict, geom)
                FionaShapeService.save_and_zip_shapefiles()



- ``geonature.utils.utilssqlalchemy.json_resp``


Décorateur pour les routes : les données renvoyées par la route sont automatiquement serialisées en json (ou geojson selon la structure des données)

S'insère entre le décorateur de route flask et la signature de fonction


Fichier routes ::

    from flask import Blueprint
    from geonature.utils.utilssqlalchemy import json_resp

    blueprint = Blueprint(__name__)

    @blueprint.route('/myview')
    @json_resp
    def my_view():
        return {'result': 'OK'}


    @blueprint.route('/myerrview')
    @json_resp
    def my_err_view():
        return {'result': 'Not OK'}, 400



Export des données
""""""""""""""""""

TODO


Utilisation de la configuration
"""""""""""""""""""""""""""""""

La configuration globale de l'application est controlée par le fichier ``config/geonature_config.toml`` qui contient un nombre limité de paramètre. De nombreux paramètres sont néammoins passés à l'application via un schéma Marshmallow (voir fichier ``backend/geonature/utils/config_schema.py).
Dans l'application flask, l'ensemble des paramètres de configuration sont utilisables via le dictionnaire ``config`` de l'application Flask:

    ::

        from flask import current_app
        MY_PARAMETER = current_app.config['MY_PARAMETER']

Chaque module GeoNature dispose de son propre fichier de configuration, (``module/config/cong_gn_module.toml``) contrôlé de la même manière par un schéma Marshmallow (``module/config/conf_schema_toml.py``).
Pour récupérer la configuration du module dans l'application Flask, il existe deux méthodes:

Dans le fichier ``blueprint.py``: 
    ::
        # Methode 1: 

        from flask import current_app
        MY_MODULE_PARAMETER = current_app.config['MY_MODULE_NAME']['MY_PARAMETER]
        # ou MY_MODULE_NAME est le nom du module tel qu'il est définit dans le fichier ``manifest.toml`` et la table ``gn_commons.t_modules``

        #Méthode 2
        MY_MODULE_PARAMETER = blueprint.config['MY_MODULE_PARAMETER']

Il peut-être utile de récupérer l'ID du module GeoNature (notamment pour des questions droits). De la même manière que précédement, à l'interieur d'une route, on peut récupérer l'ID du module ce la manière suivante:

    ::

        ID_MODULE = blueprint.config['ID_MODULE']
        # ou
        ID_MODULE = current_app.config['MODULE_NAME']['ID_MODULE']

Si on souhaite récupérer l'ID du module en dehors du contexte d'une route, il faut utiliser la méthode suivante:

    ::
        from geonature.utils.env import get_id_module
        ID_MODULE = get_id_module(current_app, 'occtax')


Authentification avec pypnusershub
""""""""""""""""""""""""""""""""""


Vérification des droits des utilisateurs
****************************************


- ``pypnusershub.routes.check_auth``


Décorateur pour les routes : vérifie les droits de l'utilisateur et le redirige en cas de niveau insuffisant ou d'informations de session erronés
(deprecated) Privilegier `check_auth_cruved`

params :

* level <int>: niveau de droits requis pour accéder à la vue
* get_role <bool:False>: si True, ajoute l'id utilisateur aux kwargs de la vue
* redirect_on_expiration <str:None> : identifiant de vue  sur laquelle rediriger l'utilisateur en cas d'expiration de sa session
* redirect_on_invalid_token <str:None> : identifiant de vue sur laquelle rediriger l'utilisateur en cas d'informations de session invalides


    ::

        from flask import Blueprint
        from pypnusershub.routes import check_auth
        from geonature.utils.utilssqlalchemy import json_resp

        blueprint = Blueprint(__name__)

        @blueprint.route('/myview')
        @check_auth(
                1,
                True,
                redirect_on_expiration='my_reconnexion_handler',
                redirect_on_invalid_token='my_affreux_pirate_handler'
                )
        @json_resp
        def my_view(id_role):
                return {'result': 'id_role = {}'.format(id_role)}



- ``pypnusershub.routes.check_auth_cruved``

Décorateur pour les routes : Vérifie les droits de l'utilisateur à effectuer une action sur la donnée et le redirige en cas de niveau insuffisant ou d'informations de session erronées

params :

* action <str:['C','R','U','V','E','D']> type d'action effectuée par la route (Create, Read, Update, Validate, Export, Delete)
* get_role <bool:False>: si True, ajoute l'id utilisateur aux kwargs de la vue
* redirect_on_expiration <str:None> : identifiant de vue  sur laquelle rediriger l'utilisateur en cas d'expiration de sa session
* redirect_on_invalid_token <str:None> : identifiant de vue sur laquelle rediriger l'utilisateur en cas d'informations de session invalides


    ::

        from flask import Blueprint
        from pypnusershub.routes import check_auth_cruved
        from pypnusershub.db.tools import get_or_fetch_user_cruved
        from geonature.utils.utilssqlalchemy import json_resp

        blueprint = Blueprint(__name__)

        @blueprint.route('/mysensibleview', methods=['GET'])
        @check_auth_cruved(
                'R',
                True,
                redirect_on_expiration='my_reconnexion_handler',
                redirect_on_invalid_token='my_affreux_pirate_handler'
                )
        @json_resp
        def my_sensible_view(info_role):
            # Récupérer l'id de l'utilisateur qui demande la route
            id_role = user.id_role
            # Récupérer la portée autorisée à l'utilisateur pour l'action 'R' (read)
            read_scope = user.tag_object_code
            #récupérer le CRUVED complet de l'utilisateur courant
            user_cruved = get_or_fetch_user_cruved(
                    session=session,
                    id_role=info_role.id_role,
                    id_application=ID_MODULE,
                    id_application_parent=current_app.config['ID_APPLICATION_GEONATURE']
            )
            return {'result': 'id_role = {}'.format(info_role.id_role)}



- ``pypnusershub.routes.db.tools.cruved_for_user_in_app``


Fonction qui retourne le cruved d'un utilisateur pour une application donnée.
Si aucun cruved n'est définit pour l'application, c'est celui de l'application mère qui est retourné.
Le cruved de l'application enfant surcharge toujours celui de l'application mère.

params :
* id_role <integer:None>
* id_application: id du module surlequel on veut avoir le cruved
* id_application_parent: id l'application parent du module

Valeur retournée : <dict> {'C': '1', 'R':'2', 'U': '1', 'V':'2', 'E':'3', 'D': '3'}

    ::

    from pypnusershub.db.tools import cruved_for_user_in_app

    cruved = cruved_for_user_in_app(id_role=5, id_application=18, id_application_parent=14)


Développement Frontend
----------------------

Modules
"""""""

Bonnes pratiques :

Chaque gn_module de GeoNature doit être un module Angular indépendant https://angular.io/guide/ngmodule. 

Ce gn_module peut s'appuyer sur une série de composants génériques intégrés dans le module GN2CommonModule et réutilisables dans n'importe quel module. 

**Les composants génériques**
------------------------------
1. Les composants formulaires
""""""""""""""""""""""""""""""
Les composants décrits ci-dessous sont intégrés dans le coeur de GeoNature et permettent aux développeurs de simplifier la mise en place de formulaires. Ces composants générent des balises HTML de type ``input`` ou ``select`` et seront souvent réutilisés dans les différents module de GeoNature.

*Input et Output communs* :

Ces composants partagent une logique commune et ont des ``Inputs`` et des ``Outputs`` communs (voir https://github.com/PnX-SI/GeoNature/blob/develop/frontend/src/app/GN2CommonModule/form/genericForm.component.ts).

- Inputs
        - L'input ``parentFormControl`` de type ``FormControl`` (https://angular.io/api/forms/FormControl) permet de contrôler la logique et les valeurs du formulaire depuis l'extérieur du composant. Cet input est **obligatoire** pour le fonctionnement du composant.

        - L'input ``label`` (string) permet d'afficher un label au dessus de l'input.

        - L'input ``displayAll`` (boolean, défaut = false) permet d'ajouter un item 'tous' sur les inputs de type select (Exemple: pour selectionner tous les jeux de données de la liste)

        - L'input ``multiSelect`` (boolean, défaut = false) permet de passer les composants de type select en "multiselect" (sélection multiple sur une liste déroulante). Le parentFormControl devient par conséquent un tableau

        - L'input ``searchBar`` (boolean, défaut = false) permet de rajouter une barre de recherche sur les composants multiselect

        - L'input ``disabled`` (boolean) permet de rendre le composant non-saisissable

        - L'input ``debounceTime`` définit une durée en ms après laquelle les évenements ``onChange`` et ``onDelete`` sont déclenchés suite à un changement d'un formulaire. (Par défault à 0)

- Outputs
        Plusieurs ``Output`` communs à ses composants permettent d'émettre des événements liés aux formulaires.

        - ``onChange`` : événement émit à chaque fois qu'un changement est effectué sur le composant. Renvoie la valeur fraiche de l'input.

        - ``onDelete`` : événement émit chaque fois que le champ du formulaire est supprimé. Renvoie un évenement vide.


Ces composants peuvent être considérés comme des "dump components" ou "presentation components", puisque que la logique de contrôle est déporté au composant parent qui l'accueil (https://blog.angular-university.io/angular-2-smart-components-vs-presentation-components-whats-the-difference-when-to-use-each-and-why/)

- **NomenclatureComponent**
        Ce composant permet de créer un "input" de type "select" ou "multiselect" à partir d'une liste d'items définie dans le référentiel de nomenclatures (thésaurus) de GeoNature (table ``ref_nomenclature.t_nomenclature``).

        En mode "multiselect" (Input ``multiSelect=true``), une barre de recherche permet de filtrée les nomenclatures sur leur label.

        **Selector**: ``pnx-nomenclature``

        **Inputs**:

        :``codeNomenclatureType``:
                Mnémonique du type de nomenclature qui doit être affiché dans la liste déroulante. Table``ref_nomenclatures.bib_nomenclatures_types`` (obligatoire)
                 
                *Type*: ``string``

        :``keyValue``:
                Attribut de l'objet nomenclature renvoyé au formControl (facultatif, par défaut ``id_nomenclature``). Valeur possible: n'importequel attribut de l'objet ``nomenclature`` renvoyé par l'API (ex: ``cd_nomenclature``, ``label_default`` etc...
                *Type*: ``string``

        :``bindAllItem``:
                Booléan qui permet de passer tout l'objet au formControl, et pas seulement une propriété de l'objet renvoyé par l'API. Facultatif, par défaut à ``false``, c'est alors l'attribut passé en Input ``keyValue`` qui est renvoyé au formControl. Lorsque l'on passe ``true`` à cet Input, l'Input ``keyValue```devient inutile.
                *Type*: ``boolean``
                 
        :``regne``:
                Permet de filter les items de nomenclature corespondant à un règne (facultatif)

                *Type*: ``string``
        :``group2Inpn``:
                Permet de filter les items de nomenclature corespondant à un group2Inpn (facultatif)

                *Type*: ``string``

        **Valeur retourné par le FormControl**:

        Dépend de la valeur passée à l'input ``keyValue`` (par défaut ``id_nomenclature`` donc ``number`` *Type*: any)
        Si l'input ``multiSelect = true``, le FormControl est un tableau


        NB: La table ``ref_nomenclatures.cor_taxref_nomenclature`` permet de faire corespondre des items de nomenclature à des groupe INPN et des règne. A chaque fois que ces deux derniers input sont modifiés, la liste des items est rechargée. Ce composant peut ainsi être couplé au composant taxonomy qui renvoie le regne et le groupe INPN de l'espèce saisie.

        Exemple d'utilisation:
        ::

                <pnx-nomenclature
                  [parentFormControl]="occtaxForm.controls.id_nomenclature_etat_bio"
                  codeNomenclatureType="ETA_BIO"
                  regne="Animalia"
                  group2Inpn="Mammifères"
                  >
                </pnx-nomenclature>``

                <pnx-nomenclature
                  [parentFormControl]="occtaxForm.controls.id_nomenclature_etat_bio"
                  codeNomenclatureType="ETA_BIO"
                  [multiSelect]=true
                  keyValue='cd_nomenclature'
                  regne="Animalia"
                  group2Inpn="Mammifères"
                  >
                </pnx-nomenclature>``


- **TaxonomyComponent**
        Ce composant permet de créer un "input" de type "typeahead" pour rechercher des taxons à partir d'une liste définit dans schéma taxonomie. Table ``taxonomie.bib_listes`` et ``taxonomie.cor_nom_listes``.

        **Selector**: ``pnx-taxonomy``

        **Inputs**:

        :``idList``:
                Id de la liste de taxon (obligatoire)

                *Type*: ``number``
        
        :``charNumber``:
                Nombre de charactere avant que la recherche AJAX soit lançé (obligatoire)

                *Type*: ``number``
        :``listLength``:
                Nombre de résultat affiché (obligatoire)

                *Type*: ``number``
        
        **Valeur retourné par le FormControl**:

        Taxon séléctionné. *Type*: any

        ::

                {
                  "nom_valide": "Alburnus alburnus (Linnaeus, 1758)",
                  "id_liste": 1001,
                  "lb_nom": "Alburnus alburnus",
                  "group2_inpn": "Poissons",
                  "regne": "Animalia",
                  "cd_nom": 67111,
                  "search_name": "Ablette = Alburnus alburnus (Linnaeus, 1758)"
                }


- **DatasetComponent**
        Ce composant permet de créer un "input" de type "select" ou "multiselect" affichant l'ensemble des jeux de données sur lesquels l'utilisateur connecté a des droits (table ``gn_meta.t_datasets`` et ``gn_meta.cor_dataset_actor``)

        **Selector**: ``pnx-dataset``

        **Inputs**:

        :``multiSelect``:
                Passe le composant du mode select à multiselect (facultatif)

                *Type*: ``boolean`` défaut ``false``

        :``displayAll``:
                Est-ce que le composant doit afficher l'item "tous" dans les options du select ? (facultatif)

                *Type*: ``boolean``

        :``idAcquisitionFrameworks``:
                Permet de filtrer les JDD en fonction d'un tableau d'ID cadre d'acqusition. A connecter avec le formControl du composant ``pnx-acquisition-framework``.  Utiliser cet Input lorsque le composant ``pnx-acquisition-framework`` est en mode multiselect.

                *Type*: ``Array<number>``

        :``idAcquisitionFramework``:
                Permet de filtrer les JDD en fonction de l'ID cadre d'acqusition. A connecter avec le formControl du composant ``pnx-acquisition-framework``.  Utiliser cet Input lorsque le composant ``pnx-acquisition-framework`` est en mode select simple.

                *Type*: ``number``
        
        :``bindAllItem``:
                Booléan qui permet de passer tout l'objet au formControl, et pas seulement une propriété de l'objet renvoyé par l'API. Facultatif, par défaut à ``false``, c'est alors l'id_dataset qui est renvoyé au formControl.
                *Type*: ``boolean``

        :``displayOnlyActive``:
                Booléan qui controle si on affiche seulement les JDD actifs ou également ceux qui sont inatif
                *Type*: ``boolean`` defaut: ``true``
        **Valeur retourné par le FormControl**:

        En mode select simple: Id du dataset sélectionné: *Type*: number
 
        En mode multiselect: Tableau d'ID des datasets sélectionnés: *Type*: Array<number>

        Exemple d'utilisation:
        ::
                
                <pnx-datasets
                  [idAcquisitionFrameworks]="formService.searchForm.controls.id_acquisition_frameworks.value" 
                  [multiSelect]='true'
                  [displayAll]="true" 
                  [parentFormControl]="formService.searchForm.controls.id_dataset" 
                  label="{{ 'MetaData.Datasets' | translate}}">
                </pnx-datasets>


- **AcquisitionFrameworksComposant**
        Ce composant permet de créer un "input" de type "select" ou "multiselect" affichant l'ensemble des cadres d'acquisition sur lesquels l'utilisateur connecté a des droits (table ``gn_meta.t_acqusitions_framework`` et ``gn_meta.cor_acquisition_framework_actor``)

        **Selector**: ``pnx-acqusitions-framework``

        **Inputs**:

        :``multiSelect``:
                Passe le composant du mode select à multiselect (facultatif)

                *Type*: ``boolean`` défaut ``false``
        :``displayAll``:
                Est-ce que le composant doit afficher l'item "tous" dans les options du select ? (facultatif)

                *Type*: ``boolean``

        :``bindAllItem``:
                Booléan qui permet de passer tout l'objet au formControl, et pas seulement une propriété de l'objet renvoyé par l'API. Facultatif, par défaut à ``false``, c'est alors l'id_acquisition_frameworks qui est passé au formControl. Lorsque l'on passe ``true`` à cet Input, l'Input ``keyValue```devient inutile.
                *Type*: ``boolean``

        
        **Valeur retourné par le FormControl**:

        En mode select simple: Id du dataset sélectionné: *Type*: number
 
        En mode multiselect: Tableau d'ID des datasets sélectionnés: *Type*: Array<number>


        Exemple d'utilisation:
        ::

                <pnx-acquisition-frameworks 
                  [multiSelect]='true'
                  [displayAll]="true" 
                  [parentFormControl]="formService.searchForm.controls.id_acquisition_frameworks"
                  label="{{ 'MetaData.AcquisitionFramework' | translate}}">
                </pnx-acquisition-frameworks>

- **DateComponent**
        Ce composant permet de créer un input de type "datepicker". Crée à parti de https://github.com/ng-bootstrap/ng-bootstrap

        **Selector**: ``pnx-date``

        **Valeur retourné par le FormControl**:

        Date sélectionnée: *Type*: any

        ::

                {
                  "year": 2018,
                  "month": 3,
                   "day": 9
                } 

- **ObserversComponent**
        Ce composant permet d'afficher un input de type "autocomplete" sur un liste d'observateur définit dans le schéma ``utilisateur.t_menus`` et ``utilisateurs.cor_role_menu``. Il permet de séléctionner plusieurs utilisateurs dans le même input.
        Composant basé sur https://www.primefaces.org/primeng/#/autocomplete

        **Selector**: ``pnx-observers``

        **Inputs**:

        :``idMenu``:
                Id de la liste d'utilisateur (table ``utilisateur.t_menus``) (obligatoire)

                *Type*: ``number``

        :``bindAllItem``:
                Booléan qui permet de passer tout l'objet au formControl, et pas seulement une propriété de l'objet renvoyé par l'API. Facultatif, par défaut à ``false``, c'est alors l'id_role qui est passé au formControl. Lorsque l'on passe ``true`` à cet Input, l'Input ``keyValue```devient inutile.
                *Type*: ``boolean``
        
        **Valeur retourné par le FormControl**:

        Observateur sélectionné: *Type*: any

        ::

                {
                  "nom_complet": "ADMINISTRATEUR test",
                  "nom_role": "Administrateur",
                  "id_role": 1,
                  "prenom_role": "test",
                  "id_menu": 9
                }

        

- **ObserversTextComponent**
      Ce composant permet d'afficher un input de type "text" de saisi libre d'une observateur

      **Selector**: ``pnx-observers-text``        

      **Valeur retourné par le FormControl**:
      
      Valeur du champ. *Type*: string


- **MultiSelectComponent**
      Ce composant permet d'afficher un input de type multiselect à partir d'une liste de valeurs passé en Input

      **Selector**: ``pnx-observers-text``

      **Inputs**:

      :``values``:
              Valeurs à afficher dans la liste déroulante. Doit être un tableau de dictionnaire

      *Type*: ``Array<any>`` *Obligatoire*

      :``keyLabel``:
              Clé du dictionnaire de valeur que le composant doit prendre pour l'affichage de la liste déroulante


              Example, pour un input ``values =  [{'id':1, 'label': "mon item"}] ``, pour afficher "mon item", ``keyLabel`` doit valoir "label"

      *Type*: ``string`` *Obligatoire*

      :``keyValue``:
          Clé du dictionnaire que le composant doit passer au formControl

          Exemple, pour un input ``values =  [{'id':1, 'label': "mon item"}] ``, pour passer "1", ``keyValue`` doit valoir "id"

      *Type*: ``string``

      :``bindAllItem``:
          Booléan qui permet de passer tout l'objet au formControl, et pas seulement une propriété de l'objet renvoyé par l'API. Facultatif, par défaut à ``false``, c'est alors l'attribut passé en Input ``keyValue`` qui est renvoyé au formControl. Lorsque l'on passe ``true`` à cet Input, l'Input ``keyValue`` devient inutile.

      *Type*: ``boolean`` *Facultatif*  défaut ``false``

      :``displayAll``:
              Est-ce que le composant doit afficher l'item "tous" dans les options du select ? 

      *Type*: ``boolean`` *Facultatif*  défaut ``false``

      :``displayAll``:
              Est-ce que le composant doit afficher une barre de recherche dans la liste déroulante? 

      *Type*: ``boolean`` *Facultatif*  défaut ``false``

      **Ouputs**:

      :``onSearch``:
              Renvoie la saisie de l'utilisateur dans la barre de recherche

      
      **Valeur retourné par le FormControl**:
      
      Valeur du champ. *Type*: Array<any>

      **Exemple d'utilisation**

        ::

                <pnx-multiselect
                 [values]="organisms" 
                 [parentFormControl]="form.controls.organisms" 
                 [keyLabel]="'nom_organisme'" 
                 [keyValue]="'id_organisme"'
                 [label]="'Organisme'"
                 (onChange)="doWhatever($event)
                 (onDelete)="deleteCallback($event)"
                 (onSearch)="filterItems($event)">
                </pnx-multiselect>



2. Les composants cartographiques
"""""""""""""""""""""""""""""""""

- **MapComponent**
        Ce composant affiche une carte Leaflet ainsi qu'un outil de recherche de lieux dits et d'adresses (basé sur l'API OpenStreetMap). 

        **Selector**: ``pnx-map``

        **Inputs**:

        :``baseMaps``:
                tableau de fonds de carte (Voir `example  <https://github.com/PnX-SI/GeoNature/blob/develop/frontend/src/conf/map.config.ts.sample>`_)

                *Type*: ``Array<any>``
        :``center``:
                coordonnées du centrage de la carte: [long,lat]

                *Type*: ``Array<number>``
        :``zoom``:
                niveaux de zoom à l'initialisation de la carte

                *Type*: ``number``

        Dans ce composant les *inputs* sont facultatifs. Si ceux ci ne sont pas renseignés, ce sont les paramètres du `fichier de configuration de l'application  <https://github.com/PnX-SI/GeoNature/blob/develop/frontend/src/conf/map.config.ts.sample>`_ qui seront appliqués. Si les *inputs* sont renseignés, ceux-ci surchagent les paramètres par défault. 

        Exemple d'utilisation: ``<pnx-map [center]="center" [zoom]="zoom"> </pnx-map>`` Ici le niveau de zoom et le centrage sont modifiés, mais les fonds de carte restent ceux renseignés par défault.

- **MarkerComponent**
        Ce composant permet d'afficher un marker au clic sur la carte ainsi qu'un controleur permettant d'afficher/désafficher le marker. NB: Doit être utiliser à l'interieur d'une balise ``pnx-map``
        
        **Selector**: ``pnx-marker``

        **Inputs**:

        :``zoomLevel``:
                Niveau de zoom à partir du quel on peut ajouter un marker sur la carte

                *Type*: ``number``
        
        **Ouputs**:
        
        :``markerChanged``:
                Output permettant de récupérer les coordonnées du marker quand celui-ci est déplacé. Retourne un geojson des coordonnées du marker

- **LeafletDrawComponent**
        Ce composant permet d'activer le `plugin leaflet-draw <https://github.com/Leaflet/Leaflet.draw>`_
        
        **Selector**: ``pnx-leaflet-draw``
        
        **Inputs**:
        
        :``options``:
                Objet permettant de paramettrer le plugin et les différentes formes dessinables (point, ligne, cercle etc...)
                
                Par défault le fichier ``leaflet-draw.option.ts`` est passé au composant. Il est possible de surcharger l'objet pour activer/désactiver certaines formes. Voir `exemple <https://github.com/PnX-SI/GeoNature/blob/develop/frontend/src/modules/occtax/occtax-map-form/occtax-map-form.component.ts#L27>`_ 

        :``zoomLevel``:
                Niveau de zoom à partir du quel on peut dessiner sur la carte

                *Type*: ``number``

        **Output**
        
        :``layerDrawed``:
                Output renvoyant le geojson de l'objet dessiné.
        :``layerDeleted``:
                Output renvoyant les layers sont supprimées.

- **GPSComponent**
        Affiche une modale permettant de renseigner les coordonnées d'une observation, puis affiche un marker à la position renseignée. Ce composant hérite du composant MarkerComponent: il dispose donc des mêmes inputs et outputs.
        
        **Selector**: ``pnx-gps``
        
- **GeojsonComponent**
        Affiche sur la carte les geojson passé en *input*
        
        **Selector**: ``pnx-geojson``
        
        **Inputs**:
        
        :``geojson``:
                Objet geojson à afficher sur la carte
                
                Type: ``GeoJSON``
                
        :``onEachFeature``:
                Fonction permettant d'effectuer un traitement sur chaque layer du geojson (afficher une popup, définir un style etc...)
                
                Type: ``any``: fonction définit par la librairie leaflet: ``onEachFeature(feature, layer)``. `Voir doc leaflet <http://leafletjs.com/examples/geojson/>`_
        :``style``: 
                Fonction ou object définissant le style des layers du geojson
                
                Type: ``any`` `voir doc leaflet <http://leafletjs.com/examples/geojson/>`_

- **MapListComponent**
	Le composant MapList fournit une carte pouvant être synchronisé avec une liste. La liste, pouvant être spécifique à chaque module, elle n'est pas intégré dans le composant et est laissé à la responsabilité du développeur. Le service ``MapListService`` offre cependant des fonctions permettant facilement de synchroniser les deux éléments.

	Fonctionnalité et comportement offert par le le composant et le service:

	- Charger les données
		Le service expose la fonction ``getData(apiEndPoint, params?)`` permettant de charger les données pour la carte et la liste. Cette fonction doit être utilisée dans le composant qui utilise le composant ``MapListComponent``. Elle se charge de faire appel à l'API passé en paramètre et de rendre les données disponibles au service.
		Le deuxième paramètre ``params`` est un tableau de paramètre(s) (facultatif). Il permet de filtrer les données sur n'importe quelle propriété du GeoJson, et également de gérer la pagination.

		Exemple: afficher les 10 premiers relevés du cd_nom 212 :

		``mapListService.getData('occtax/releve', [{'param': 'limit', 'value': 10'},{'param': 'cd_nom', 'value': 212'}])``

		`Exemple dans le module OccTax  <https://github.com/PnX-SI/GeoNature/blob/develop/frontend/src/modules/occtax/occtax-map-list/occtax-map-list.component.ts#L84/>`_

		L'API doit necessairement renvoyer un objet comportant un GeoJson. La structure du l'objet doit être la suivante :

		::

			'total': nombre d'élément total,
			'total_filtered': nombre d'élément filtré,
			'page': numéro de page de la liste,
			'limit': limite d'élément renvoyé,
			'items': le GeoJson

		Pour un liste simple sans pagination, seule la propriété 'items' est obligatoire.				

	- Rafraichir les données
		La fonction ``refreshData(apiEndPoint, method, params?)`` permet de raffrachir les données en fonction de filtres personnalisés.
		Les paramètres ``apiEndPoint`` et ``params`` sont les mêmes que pour la fonction ``getData``. Le paramètre ``method`` permet lui de chosir si on ajoute - ``append``- , ou si on initialise (ou remplace) -``set``- un filtre.
		
		Exemple 1 : Pour filtrer sur l'observateur 1, puis ajouter un filtre sur l'observateur 2.

		``mapListService.refreshData('occtax/relevé', 'append, [{'param': 'observers', 'value': 1'}])``

		puis

		``refreshData('occtax/relevé', 'append, [{'param': 'observers', 'value': 2'}])``

		Exemple 2: pour filtrer sur le cd_nom 212, supprimer ce filtre et filtrer sur  le cd_nom 214

		``mapListService.refreshData('occtax/relevé', 'set, [{'param': 'cd_nom', 'value': 1'}])``

		puis

		``mapListService.refreshData('occtax/relevé', 'set, [{'param': 'cd_nom', 'value': 2'}])``
		
	- Gestion des évenements:
		- Au clic sur un marker de la carte, le service ``MapListService`` expose la propriété ``selectedRow`` qui est un tableau contenant l'id du marker sélectionné. Il est ainsi possible de surligner l'élément séléctionné dans le liste.

		- Au clic sur une ligne du tableau, utiliser la fonction ``MapListService.onRowSelected(id)`` (id étant l'id utilisé dans le GeoJson) qui permet de zoomer sur le point séléctionner et de changer la couleur de celui-ci.
	
	La service contient également deux propriétés publiques ``geoJsonData`` (le geojson renvoyé par l'API) et ``tableData``  (le tableau de features du Geojson) qui sont respectivement passées à la carte et à la liste. Ces deux propriétés sont utilisables pour intéragir (ajouter, supprimer) avec les données de la carte et de la liste.

	**Selector**: ``pnx-map-list``

	**Inputs**:

	:``idName``:
			Libellé de l'id du geojson (id_releve, id)
			
			Type: ``string``
	:``height``:
			Taille de l'affichage de la carte leaflet
			
			Type: ``string``

	
	Exemple d'utilisation avec une liste simple:
	::

		<pnx-map-list 
			idName="id_releve_occtax"
			height="80vh">
		</pnx-map-list>
		<table>
			<tr ngFor="let row of mapListService.tableData" [ngClass]=" {'selected': mapListService.selectedRow[0]} == row.id ">
				<td (click)="mapListService.onRowSelect(row.id)"> Zoom on map </td>
				<td > {{row.observers}} </td>
				<td > {{row.date}} </td>
			</tr>
		</table>
                

Outils d'aide à la qualité du code
----------------------------------

Des outils d'amélioration du code pour les développeurs peuvent être utilisés : flake8, pylint, mypy, pytest, coverage.

La documentation peut être générée avec Sphinx.

Les fichiers de configuration de ces outils se trouvent à la racine du projet :

* .flake8
* .pylint
* .mypy
* .pytest
* .coverage

Un fichier ``.editorconfig`` permettant de définir le comportement de votre éditeur de code 
est également disponible à la racine du projet.

Installation des outils
"""""""""""""""""""""""

::

        pip install --user pipenv
        pipenv install --dev

La documentation de ces outils est disponible en ligne :

* http://flake8.pycqa.org/en/latest/
* https://www.pylint.org/ - Doc : https://pylint.readthedocs.io/en/latest/
* https://mypy.readthedocs.io/en/latest/
* https://docs.pytest.org/en/latest/contents.html
* https://coverage.readthedocs.io/en/coverage-4.4.2/
* http://www.sphinx-doc.org/en/stable/ -  Doc : http://www.sphinx-doc.org/en/stable/contents.html

Usage
"""""

Pour utiliser ces outils il faut se placer dans le virtualenv

::

        pipenv shell


Sphinx
""""""

Sphinx est un générateur de documentation.

Pour générer la documentation HTML, se placer dans le répertoire ``docs`` et modifier les fichiers .rst

::

        cd docs
        make html


Flake8
""""""

Flake8 inspecte le code et pointe tous les écarts à la norme PEP8. Il recherche également toutes les erreurs syntaxiques et stylistiques courantes.

::

        cd backend
        flake8


Pylint
""""""

Pylint fait la même chose que Flake8 mais il est plus complet, plus configurable mais aussi plus exigeant.

Pour inspecter le répertoire ``geonature``

::

        cd backend
        pylint geonature

tslint
""""""

tslint fait la même chose que pylint mais pour la partie frontend en typescript.

::

        cd frontend
        ng lint


Mypy
""""

Mypy vérifie les erreurs de typage.
Mypy est utilisé pour l'éditeur de texte en tant que linter.

Pytest
""""""

Pytest permet de mettre en place des tests fonctionnels et automatisés du code Python.

Les fichiers de test sont dans le répertoire ``backend/tests``

::

        cd backend
        pytest


Coverage
""""""""

Coverage permet de donner une indication concernant la couverture du code par les tests.

::

        cd backend
        pytest --cov=geonature --cov-report=html

Ceci génénère un rapport html disponible dans  ``backend/htmlcov/index.html``.
