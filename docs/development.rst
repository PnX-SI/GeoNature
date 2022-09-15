DEVELOPPEMENT
=============

Général
-------

GeoNature a été développé par Gil Deluermoz depuis 2010 avec PHP/Symfony/ExtJS.

En 2017, les parcs nationaux français ont décidé de refondre GeoNature
complètement avec une nouvelle version (V2) réalisée en Python/Flask/Angular.

Mainteneurs :

- Elie BOUTTIER (PnEcrins)
- Theo LECHEMIA (PnEcrins)
- Amandine SAHL (PnCevennes)
- Camille MONCHICOURT (PnEcrins)

.. image :: _static/geonature-techno.png

.. _api:

API
---

GeoNature utilise :

- l'API de TaxHub (recherche taxon, règne et groupe d'un taxon...)
- l'API du sous-module Nomenclatures (typologies et listes déroulantes)
- l'API du sous-module d'authentification de UsersHub (login/logout, récupération du CRUVED d'un utilisateur)
- l'API de GeoNature (get, post, update des données des différents modules, métadonnées, intersections géographiques, exports...)

.. image :: _static/api_services.png

Liste des routes
*****************

.. qrefflask:: geonature:create_app()
  :undoc-static:

Documentation des routes
************************

.. autoflask:: geonature:create_app()
  :undoc-static:


Release
-------

Pour sortir une nouvelle version de GeoNature :

- Faites les éventuelles Releases des dépendances (UsersHub, TaxHub, UsersHub-authentification-module, Nomenclature-api-module, GeoNature-atlas)
- Assurez-vous que les sous-modules git de GeoNature pointent sur les bonnes versions des dépendances
- Mettez à jour la version de GeoNature et éventuellement des dépendances dans ``install/install_all/install_all.ini``, ``config/settings.ini.sample``, ``backend/requirements.txt``
- Complétez le fichier ``docs/CHANGELOG.rst`` (en comparant les branches https://github.com/PnX-SI/GeoNature/compare/develop) et dater la version à sortir
- Mettez à jour le fichier ``VERSION``
- Remplissez le tableau de compatibilité des dépendances (``docs/versions-compatibility.rst``)
- Mergez la branche ``develop`` dans la branche ``master``
- Faites la release (https://github.com/PnX-SI/GeoNature/releases) en la taguant ``X.Y.Z`` (sans ``v`` devant) et en copiant le contenu du Changelog
- Dans la branche ``develop``, modifiez le fichier ``VERSION`` en ``X.Y.Z.dev0`` et pareil dans le fichier ``docs/CHANGELOG.rst``

BDD
---

Mettre à jour le ``ref_geo`` à partir des données IGN scan express :

- Télécharger le dernier millésime : http://professionnels.ign.fr/adminexpress
- Intégrer le fichier Shape dans la BDD grâce à QGIS dans une table nommée ``ref_geo.temp_fr_municipalities``
- Générer le SQL de création de la table : ``pg_dump --table=ref_geo.temp_fr_municipalities --column-inserts -U <MON_USER> -h <MON_HOST> -d <MA_BASE> > fr_municipalities.sql``. Le fichier en sortie doit s'appeler ``fr_municipalities.sql``
- Zipper le fichier SQL et le mettre sur le serveur https://geonature.fr/data
- Adapter le script ``install_db.sh`` pour récupérer le nouveau fichier zippé

Pratiques et règles de developpement
------------------------------------

Afin de partager des règles communes de développement et faciliter l'intégration de 
nouveau code, veuillez lire les recommandations et bonnes pratiques recommandées pour contribuer
au projet GeoNature.

Git
***

- Ne jamais faire de commit dans la branche ``master`` mais dans la branche ``develop`` ou idéalement dans une branche dédiée à la fonctionnalité (feature branch)
- Faire des pull request vers la branche ``develop``
- Faire des ``git pull`` avant chaque développement et avant chaque commit
- Les messages de commits font référence à un ticket ou le ferment (``ref #12`` ou ``fixes #23``)
- Les messages des commits sont en anglais (dans la mesure du possible)

Backend
*******

- Une fonction ou classe doit contenir une docstring en français. Les doctrings doivent suivre le modèle NumPy/SciPy (voir https://numpydoc.readthedocs.io/en/latest/format.html et https://realpython.com/documenting-python-code/#numpyscipy-docstrings-example)
- Les commentaires dans le codes doivent être en anglais (ne pas s'empêcher de mettre un commentaire en français sur une partie du code complexe !)
- Assurez-vous d’avoir récupérer les dépendances dans les sous-modules git : ``git submodule init && git submodule update``
  - Après un ``git pull``, il faut mettre à jour les sous-modules : ``git submodule update``
- Installer les requirements-dev (``cd backend && pip install -r requirements-dev.txt``) qui contiennent une série d'outils indispensables au développement dans GeoNature.
- Utiliser *blake* comme formateur de texte et activer l'auto-formatage dans son éditeur de texte (Tuto pour VsCode : https://medium.com/@marcobelo/setting-up-python-black-on-visual-studio-code-5318eba4cd00)
- Utiliser *pylint* comme formatteur de code 
- Respecter la norme PEP8 (assurée par les deux outils précédents)
- La longueur maximale pour une ligne de code est 100 caractères. Pour VsCode copier ces lignes le fichier ``settings.json`` :
- Respecter le snake case

::

    "python.formatting.blackArgs": [
      "--line-length",
      "100"
    ]

- Utiliser des doubles quotes pour les chaines de charactères.

BDD 
***

- Le noms des tables est préfixé par un "t" pour une table de contenu, de "bib" pour les tables de "dictionnaires" et de "cor" pour les tables de correspondance (relations N-N)
- Les schémas du coeur de GeoNature sont préfixés de "gn" 
- Les schémas des protocoles ou modules GeoNature sont préfixés de "pr"
- Ne rien écrire dans le schéma ``public``
- Ne pas répeter le nom des tables dans les noms des colonnes

Typescript
**********

- Documenter les fonctions et classes grâce au JSDoc en français (https://jsdoc.app/)
- Les commentaires dans le codes doivent être en anglais (ne pas s'empêcher de mettre un commentaire en français sur une partie du code complexe !)
- Les messages renvoyés aux utilisateurs sont en français 
- Installer les outils de devéloppement : ``npm install --only=dev``
- Utiliser *prettier* comme formateur de texte et activer l'autoformatage dans son éditeur de texte (VsCode dispose d'une extension Prettier : https://github.com/prettier/prettier-vscode)
- Utiliser ``tslint`` comme linter
- La longueur maximale pour une ligne de code est 100 caractères.

Angular
*******

- Suivre les recommandations définies par le styleguide Angular: https://angular.io/guide/styleguide. C'est une ressources très fournie en cas de question sur les pratiques de développement (principe de séparation des principes, organisation des services et des composants)
- On privilégiera l'utilisation des reactive forms pour la construction des formulaires (https://angular.io/guide/reactive-forms). Ce sont des formulaires pilotés par le code, ce qui facilite la lisibilité et le contrôle de ceux-ci.
- Pour l'ensemble des composants cartographiques et des formulaires (taxonomie, nomenclatures...), il est conseillé d'utiliser les composants présents dans le module 'GN2CommonModule'.
 
HTML 
****

- La longueur maximale pour une ligne de code est 100 caractères.
- Lorsqu'il y a plus d'un attribut sur une balise, revenir à la ligne et aligner les attributs :

::

      <button 
        mat-raised-button
        color="primary"
        class="btn-action hard-shadow uppercase ml-3"
        data-toggle="collapse"
        data-target="#collapseAvance"
      >
        Filtrer
      </button>

- VsCode fournit un formatteur de HTML par défaut (Dans les options de VsCode, tapez "wrap attributes" et sélectionner "force-expand-multiline")

Style et ergonomie
******************

- Boutons :
  On utilise les boutons d'Angular materials (https://material.angular.io/components/button/overview).
  
  - mat-raised-button pour les boutons contenant du texte 
  - mat-fab ou mat-mini-fab pour les boutons d'actions avec seulement une icone 

- Couleur des boutons :

  - Action : primary 
  - Validation: vert (n'existant pas dans material: utiliser la classe `button-success`)
  - Suppression: warn 
  - Navigation: basic 

- Librairie d'icones :

  - Utiliser la librairie material icons fournie avec le projet : https://material.io/resources/icons/?style=baseline (``<mat-icon> add </mat-icon>``)

- Formulaire :

  - Nous utilisons pour l'instant le style des formulaires Bootstrap (https://getbootstrap.com/docs/4.0/components/forms/). Une reflexion de migration vers les formulaires materials est en cours.

- Système de grille et responsive :

  - Utiliser le système de grille de bootstrap pour assurer le responsive design sur l'application. On ne vise pas l'utilisation sur mobile, mais à minima sur ordinateur portable de petite taille.


Développer et installer un gn_module
------------------------------------

GeoNature a été conçu pour fonctionner en briques modulaires. 

Chaque protocole, répondant à une question scientifique, est amené à avoir
son propre module GeoNature comportant son modèle de base de données (dans un
schéma séparé), son API et son interface utilisateur.

Les modules développés s'appuieront sur le coeur de GeoNature qui est
constitué d'un ensemble de briques réutilisables.

En base de données, le coeur de GeoNature est constitué de l'ensemble des
référentiels (utilisateurs, taxonomique, nomenclatures géographique)
et du schéma ``gn_synthese`` regroupant l'ensemble données saisies dans les
différents protocoles (voir doc administrateur pour plus de détail sur le
modèle de données).

L'API du coeur permet d'interroger les schémas de la base de données "coeur"
de GeoNature. Une documentation complète de l'API est disponible dans la
rubrique :ref:`API`.

Du côté interface utilisateur, GeoNature met à disposition un ensemble de
composants Angular réutilisables
(http://pnx-si.github.io/GeoNature/frontend/modules/GN2CommonModule.html),
pour l'affichage des cartes, des formulaires etc...

Développer un gn_module
***********************

Avant de développer un gn_module, assurez-vous d'avoir GeoNature bien
installé sur votre machine (voir :ref:`installation-standalone`).

Afin de pouvoir connecter ce module au "coeur", il est impératif de suivre
une arborescence prédéfinie par l'équipe GeoNature.
Un template GitHub a été prévu à cet effet
(https://github.com/PnX-SI/gn_module_template).
Il est possible de créer un nouveau dépôt GitHub à partir de ce template,
ou alors de copier/coller le contenu du dépôt dans un nouveau.

Cette arborescence implique de développer le module dans les technologies du
coeur de GeoNature à savoir :

- Le backend est développé en Python grâce au framework Flask.
- Le frontend est développé grâce au framework Angular (voir la version actuelle du coeur)

GeoNature prévoit cependant l'intégration de module "externe" dont le
frontend serait développé dans d'autres technologies. La gestion de
l'intégration du module est à la charge du développeur.

- Le module se placera dans un dossier à part du dossier "GeoNature" et portera le suffixe "gn_module". Exemple : *gn_module_validation*

- La racine du module comportera les fichiers suivants :

  - ``install_app.sh`` : script bash d'installation des librairies python ou npm necessaires au module
  - ``install_env.sh`` : script bash d'installation des paquets Linux
  - ``requirements.txt`` : liste des librairies python necessaires au module
  - ``manifest.toml`` : fichier de description du module (nom, version du module, version de GeoNature compatible)
  - ``conf_gn_module.toml`` : fichier de configuration de l'application (livré en version sample)
  - ``conf_schema_toml.py`` : schéma 'marshmallow' (https://marshmallow.readthedocs.io/en/latest/) du fichier de configuration (permet de s'assurer la conformité des paramètres renseignés par l'utilisateur). Ce fichier doit contenir une classe ``GnModuleSchemaConf`` dans laquelle toutes les configurations sont synchronisées.
  - ``install_gn_module.py`` : script python lançant les commandes relatives à 'installation du module (Base de données, ...). Ce fichier doit comprendre une fonction ``gnmodule_install_app(gn_db, gn_app)`` qui est utilisée pour installer le module (Voir l'`exemple du module CMR <https://github.com/PnX-SI/gn_module_cmr/blob/master/install_gn_module.py>`__)

- La racine du module comportera les dossiers suivants :

  - ``backend`` : dossier comportant l'API du module utilisant un blueprint Flask
  - Le fichier ``blueprint.py`` comprend les routes du module (ou instancie les nouveaux blueprints du module)
  - Le fichier ``models.py`` comprend les modèles SQLAlchemy des tables du module.
  - ``frontend`` : le dossier ``app`` comprend les fichiers typescript du module, et le dossier ``assets`` l'ensemble des médias (images, son).

    - Le dossier ``app`` doit comprendre le "module Angular racine", celui-ci doit impérativement s'appeler ``gnModule.module.ts``
    - Le dossier ``app`` doit contenir un fichier ``module.config.ts``. Ce fichier est automatiquement synchronisé avec le fichier de configuration du module `<GEONATURE_DIRECTORY>/external_modules/<nom_module>/conf_gn_module.toml`` grâce à la commande ``geonature update_module_configuration <nom_module>``. C'est à partir de ce fichier que toutes les configuration doivent pointer.
    - A la racine du dossier ``frontend``, on retrouve également un fichier ``package.json`` qui décrit l'ensemble des librairies JS necessaires au module.

  - ``data`` : ce dossier comprenant les scripts SQL d'installation du module

Le module est ensuite installable à la manière d'un plugin grâce à la commande ``geonature install_gn_module`` de la manière suivante :

::

    # se placer dans le répertoire backend de GeoNature
    cd <GEONATURE_DIRECTORY>/backend
    # activer le virtualenv python
    source venv/bin/activate
    # lancer la commande d'installation
    geonature install_gn_module <CHEMIN_ABSOLU_DU_MODULE> <URL_API>
    # example geonature install_gn_module /home/moi/gn_module_validation /validation


Bonnes pratiques Frontend
"""""""""""""""""""""""""

- Pour l'ensemble des composants cartographiques et des formulaires (taxonomie, nomenclatures...), il est conseillé d'utiliser les composants présents dans le module 'GN2CommonModule'.

  Importez ce module dans le module racine de la manière suivante 
  
  ::

    import { GN2CommonModule } from '@geonature_common/GN2Common.module';

- Les librairies JS seront installées dans le dossier ``node_modules`` de GeoNature. (Il n'est pas nécessaire de réinstaller toutes les librairies déjà présentes dans GeoNature (Angular, Leaflet, ChartJS ...). Le ``package.json`` de GeoNature liste l'ensemble des librairies déjà installées et réutilisable dans le module.

- Les fichiers d'assets sont à ranger dans le dossier ``assets`` du frontend. Angular-cli impose cependant que tous les assets soient dans le répertoire mère de l'application (celui de GeoNature). Un lien symbolique est créé à l'installation du module pour faire entre le dossier d'assets du module et celui de Geonature.

- Utiliser node_modules présent dans GeoNature

  Pour utiliser des librairies déjà installées dans GeoNature,
  utilisez la syntaxe suivante
  
  ::

    import { TreeModule } from "@librairies/angular-tree-component";

  L'alias ``@librairies`` pointe en effet vers le repertoire des node_modules
  de GeoNature

  Pour les utiliser à l'interieur du module, utiliser la syntaxe suivante 
  
  ::

    <img src="external_assets/<MY_MODULE_CODE>/afb.png">

  Exemple pour le module de validation 
  
  ::

    <img src="external_assets/<gn_module_validation>/afb.png">


Installer un gn_module
**********************

Renseignez l'éventuel fichier ``config/settings.ini`` du module.

Pour installer un module, rendez vous dans le dossier ``backend`` de GeoNature.

Activer ensuite le virtualenv pour rendre disponible les commandes GeoNature 

.. code-block::

    source venv/bin/activate


Lancez ensuite la commande 

.. code-block::

    geonature install_gn_module <mon_chemin_absolu_vers_le_module> <url_api>


Le premier paramètre est l'emplacement absolu du module sur votre machine et
le 2ème le chemin derrière lequel on retrouvera les routes de l'API du module.

Exemple pour atteindre les routes du module de validation à l'adresse
'http://mon-geonature.fr/api/geonature/validation'

Cette commande exécute les actions suivantes :

- Vérification de la conformité de la structure du module (présence des fichiers et dossiers obligatoires)
- Intégration du blueprint du module dans l'API de GeoNature
- Vérification de la conformité des paramètres utilisateurs
- Génération du routing Angular pour le frontend
- Re-build du frontend pour une mise en production

Complétez l'éventuelle configuration du module (``config/conf_gn_module.toml``) 
à partir des paramètres présents dans
``config/conf_gn_module.toml.example`` dont vous pouvez surcoucher les
valeurs par défaut. Puis relancez la mise à jour de la configuration
(depuis le répertoire ``geonature/backend`` et une fois dans le venv
(``source venv/bin/activate``) :
``geonature update_module_configuration nom_du_module``)

.. _mode-dev:

Passer en mode développement
----------------------------

Récupération des sources
************************

Si vous avez téléchargé GeoNature zippé (via la procédure d'installation globale ``install_all.sh`` ou en suivant la documentation d'installation standalone), il est nécessaire de rattacher votre répertoire au dépôt GitHub afin de pouvoir télécharger les dernières avancées du coeur en ``git pull``. Pour cela, suivez les commandes suivantes en vous placant à la racine du répertoire de GeoNature.

.. code-block:: bash

  --- Se créer un répertoire .git ---
  mkdir .git
  ---  récupérer l'historique du dépôt --- 
  git clone --depth=2 --bare https://github.com/PnX-SI/GeoNature.git .git
  --- initialiser un dépôt git à partir de l'historique téléchargé --- 
  git init
  --- vérifier que le dépôt distant et le contenu local sont synchronisés --- 
  git pull
  --- Reset sur HEAD pour mettre à jour les status --- 
  git reset HEAD
  -> vous êtes à jour sur la branche master
  --- Cloner les sous-modules pour récupérer les dépendances
  git submodule init
  git submodule update

Configuration des URLs de développement
************************************************

il est nécessaire de changer la configuration du fichier ``config/geonature_config.toml`` pour utiliser les adresses suivantes :

.. code-block:: bash
    
  URL_APPLICATION = 'http://127.0.0.1:4200'
  API_ENDPOINT = 'http://127.0.0.1:8000'
  API_TAXHUB =  'http://127.0.0.1:5000/api'



Pour mettre à jour le fichier ``frontend/src/conf/app.config.ts`` et prendre en compte ces modifications, lancer les commandes suivantes :

.. code-block:: bash

  source ~/geonature/backend/venv/bin/activate
  geonature update_configuration
  deactivate

Serveur frontend en développement
*********************************

Lancer le serveur frontent via le virtualenv :

.. code-block:: bash
  
  source ~/geonature/frontend/venv/bin/activate
  geonature dev_front

Notez que vous pouvez aussi utiliser alternativement les commandes ``npm`` standards sans le virtualenv (consultez le fichier `frontend/package.json <https://github.com/PnX-SI/GeoNature/blob/7af2c82a97675daa965024a3879c7168aca2fdb1/frontend/package.json#L7>`_).


API en développement
********************

.. Note::
  Retrouvez plus de'informations dans la section :ref:`dev-backend` dédiée.

Dans un nouveau terminal, stopper le service geonature (gunicorn) et lancer le serveur backend :

.. code-block:: bash
    
  sudo systemctl stop geonature    
  source ~/geonature/backend/venv/bin/activate
  geonature dev_back

Les serveurs seront accessibles via ces adresses (login ``admin`` et password ``admin``) :
  - backend - 127.0.0.1:8000
  - frontend - 127.0.0.1:4200

Autres extensions en développement
**********************************

Il n'est pas forcémment utile de passer toutes les extensions en mode dévelomment.
Pour plus d'informations, référez-vous aux documentations dédiées :

- https://taxhub.readthedocs.io/fr/latest/installation.html#developpement
- https://usershub.readthedocs.io/fr/latest/

Si toutefois TaxHub retourne une erreur 500 et ne répond pas sur l'URL http://127.0.0.1:5000 alors vous pouvez avoir besoin de passer TaxHub en mode développement :

.. code-block:: bash

  source ~/taxhub/venv/bin/activate
  flask run

Debugger avec un navigateur
***************************

L'extension `Angular DevTools <https://angular.io/guide/devtools>`_ permettra de debugger l'application dans la console du navigateur.
Pour utiliser l'extension vous devez l'installer et passer obligatoirement en mode ``development``.

Ouvrez le fichier  ``frontend/src/conf/app.config.ts`` et modifiez la valeur ``PROD_MOD`` pour avoir :

.. code-block:: javascript
  :linenos:

  "PROD_MOD": false

Si le mode production (PROD_MOD) est à true, alors vous n'êtes pas en mode production lors du lancement de la commande ``npm run start``.

.. _dev-backend:

Développement Backend
----------------------

Démarrage du serveur de dev backend
***********************************

La commande ``geonature`` fournit la sous-commande ``dev_back`` pour lancer un serveur de test :

::

    (venv)...$ geonature dev_back


Base de données avec Flask-SQLAlchemy
*************************************

L’intégration de la base de données à GeoNature repose sur la bibliothèque `Flask-SQLAlchemy <https://flask-sqlalchemy.palletsprojects.com>`_.

Celle-ci fournit un objet ``db`` à importer comme ceci : ``from geonature.utils.env import db``

Cet objet permet d’accéder à la session SQLAlchemy ainsi :

::

    from geonature.utils.env import db
    obj = db.session.query(MyModel).get(1)

Mais il fournit une base déclarative ``db.Model`` permettant d’interroger encore plus simplement les modèles via leur attribut ``query`` :

::

    from geonature.utils.env import db
    class MyModel(db.Model):
        …

    obj = MyModel.query.get(1)

L’attribut ``query`` fournit `plusieurs fonctions <https://flask-sqlalchemy.palletsprojects.com/en/2.x/api/#flask_sqlalchemy.BaseQuery>`_ très utiles dont la fonction ``get_or_404`` :

::

    obj = MyModel.query.get_or_404(1)

Ceci est typiquement la première ligne de toutes les routes travaillant sur une instance (route de type get/update/delete).


Fonctions de filtrages
""""""""""""""""""""""

L’attribut ``query`` est une instance de la classe ``flask_sqlalchemy.BaseQuery`` qui peut être sur-chargée afin de définir de nouvelles fonctions de filtrage.

On pourra ainsi implémenter une fonction pour filtrer les objets auxquels l’utilisateur a accès, ou encore pour implémenter des filtres de recherche.

::

    from flask import g
    import sqlalchemy as sa
    from flask_sqlalchemy import BaseQuery
    from geonature.core.gn_permissions import login_required

    class MyModelQuery(BaseQuery):
        def filter_by_scope(self, scope):
            if scope == 0:
                self = self.filter(sa.false())
            elif scope in (1, 2):
                filters = [ MyModel.owner==g.current_user ]
                if scope == 2 and g.current_user.id_organism is not None:
                    filters.append(MyModel.owner.any(id_organism=g.current_user.id_organism)
                self = self.filter(sa.or_(*filters))
            return self

    class MyModel(db.Model):
        query_class = MyModelQuery


    @login_required
    def list_my_model():
        obj_list = MyModel.query.filter_by_scope(2).all()


Serialisation des modèles
*************************

Avec Marshmallow
""""""""""""""""

La bibliothèque `Marshmallow <https://marshmallow.readthedocs.io/en/stable/>`_ fournit des outils de sérialisation et desérialisation.

Elle est intégrée à GeoNature par la bibliothèque `Flask-Marshmallow <https://flask-marshmallow.readthedocs.io/en/latest/>`_ qui fournit l’objet ``ma`` à importer comme ceci : ``from geonature.utils.env import ma``.

Cette bibliothèque ajoute notablement une méthode ``jsonify`` aux schémas.

Les schémas Marshmallow peuvent être facilement créés à partir des modèles SQLAlchemy grâce à la bibliothèque `Marshmallow-SQLAlchemy <https://marshmallow-sqlalchemy.readthedocs.io/en/latest/>`_.

::

    from geonature.utils.env import ma

    class MyModelSchema(ma.SQLAlchemyAutoSchema):
        class Meta:
            model = MyModel
            include_fk = True

La propriété ``include_fk=True`` concerne les champs de type ``ForeignKey``, mais pas les ``relationships`` en elles-même. Pour ces dernières, il est nécessaire d’ajouter manuellement des champs ``Nested`` à son schéma :

::

    class ParentModelSchema(ma.SQLAlchemyAutoSchema):
        class Meta:
            model = ParentModel
            include_fk = True

        childs = ma.Nested("ChildModelSchema", many=True)

    class ChildModelSchema(ma.SQLAlchemyAutoSchema):
        class Meta:
            model = ChildModel
            include_fk = True

        parent = ma.Nested(ParentModelSchema)


Attention, la sérialisation d’un objet avec un tel schéma va provoquer une récursion infinie, le schéma parent incluant le schéma enfant, et le schéma enfant incluant le schéma parent.

Il est donc nécessaire de restreindre les champs à inclure avec l’argument ``only`` ou ``exclude`` lors de la création des schémas :

::

    parent_schema = ParentModelSchema(only=['pk', 'childs.pk'])

L’utilisation de ``only`` est lourde puisqu’il faut re-spécifier tous les champs à sérialiser. On est alors tenté d’utiliser l’argument ``exclude`` :

::

    parent_schema = ParentModelSchema(exclude=['childs.parent'])

Cependant, l’utilisation de ``exclude`` est hautement problématique !

En effet, l’ajout d’un nouveau champs ``Nested`` au schéma nécessiterait de le rajouter dans la liste des exclusions partout où le schéma est utilisé (que ça soit pour éviter une récursion infinie, d’alourdir une réponse JSON avec des données inutiles ou pour éviter un problème n+1 - voir section dédiée).

La bibliothèque Utils-Flask-SQLAlchemy fournit une classe utilitaire ``SmartRelationshipsMixin`` permettant de résoudre ces problématiques.

Elle permet d’exclure par défaut les champs ``Nested``.

Pour demander la sérialisation d’un sous-schéma, il faut le spécifier avec ``only``, mais sans nécessité de spécifier tous les champs basiques (non ``Nested``).

::

    from utils_flask_sqla.schema import SmartRelationshipsMixin

    class ParentModelSchema(SmartRelationshipsMixin, ma.SQLAlchemyAutoSchema):
        class Meta:
            model = ParentModel
            include_fk = True

        childs = ma.Nested("ChildModelSchema", many=True)

    class ChildModelSchema(SmartRelationshipsMixin, ma.SQLAlchemyAutoSchema):
        class Meta:
            model = ChildModel
            include_fk = True

        parent = ma.Nested(ParentModelSchema)


Avec le décorateur ``@serializable``
""""""""""""""""""""""""""""""""""""

.. Note::
  L’utilisation des schémas Marshmallow est probablement plus performante.

La bibliothèque maison `Utils-Flask-SQLAlchemy <https://github.com/PnX-SI/Utils-Flask-SQLAlchemy>`_ fournit le décorateur ``@serializable`` qui ajoute une méthode ``as_dict`` sur les modèles décorés :

::

    from utils_flask_sqla.serializers import serializable

    @serializable
    class MyModel(db.Model):
        …


    obj = MyModel(…)
    obj.as_dict()


La méthode ``as_dict`` fournit les arguments ``fields`` et ``exclude`` permettant de spécifier les champs que l’on souhaite sérialiser.

Par défaut, seules les champs qui ne sont pas des relationshisp sont sérialisées (fonctionnalité similaire à celle fournit par ``SmartRelationshipsMixin`` pour Marshmallow).

Les relations que l’on souhaite voir sérialisées doivent être explicitement déclarées via l’argument ``fields``.

L’argument ``fields`` supporte la « notation à point » permettant de préciser les champs d’un modèle en relation :

::

    child.as_dict(fields=['parent.pk'])

Les `tests unitaires <https://github.com/PnX-SI/Utils-Flask-SQLAlchemy/blob/master/src/utils_flask_sqla/tests/test_serializers.py>`_ fournissent un ensemble d’exemples d’usage du décorateur.

La fonction ``as_dict`` prenait autrefois en argument les paramètres ``recursif`` et ``depth`` qui sont tous les deux obsolètes. Ces derniers ont différents problèmes :

- récursion infinie (contournée par un hack qui ne résoud pas tous les problèmes et qu’il serait souhaitable de voir disparaitre)
- augmentation non prévue des données sérialisées lors de l’ajout d’une nouvelle relationship
- problème n+1 (voir section dédiée)

Cas des modèles géographiques
"""""""""""""""""""""""""""""

La bibliothèque maison `Utils-Flask-SQLAlchemy-Geo <https://github.com/PnX-SI/Utils-Flask-SQLAlchemy-Geo>`_ fournit des décorateurs supplémentaires pour la sérialisation des modèles contenant des champs géographiques.

- ``utils_flask_sqla_geo.serializers.geoserializable``


  Décorateur pour les modèles SQLA : Ajoute une méthode as_geofeature qui
  retourne un dictionnaire serialisable sous forme de Feature geojson.


  Fichier définition modèle ::

    from geonature.utils.env import DB
    from utils_flask_sqla_geo.serializers import geoserializable


    @geoserializable
    class MyModel(DB.Model):
        __tablename__ = 'bla'
        ...


  Fichier utilisation modèle ::

    instance = DB.session.query(MyModel).get(1)
    result = instance.as_geofeature()

- ``utils_flask_sqla_geo.serializers.shapeserializable``

  Décorateur pour les modèles SQLA :

  - Ajoute une méthode ``as_list`` qui retourne l'objet sous forme de tableau (utilisé pour créer des shapefiles)
  - Ajoute une méthode de classe ``to_shape`` qui crée des shapefiles à partir des données passées en paramètre

  Fichier définition modèle ::

    from geonature.utils.env import DB
    from utils_flask_sqla_geo.serializers import shapeserializable


    @shapeserializable
    class MyModel(DB.Model):
        __tablename__ = 'bla'
        ...


  Fichier utilisation modèle :

  .. code-block::
  
      # utilisation de as_shape()
      data = DB.session.query(MyShapeserializableClass).all()
      MyShapeserializableClass.as_shape(
          geom_col='geom_4326',
          srid=4326,
          data=data,
          dir_path=str(ROOT_DIR / 'backend/static/shapefiles'),
          file_name=file_name,
      )



- ``utils_flask_sqla_geo.utilsgeometry.FionaShapeService``

  Classe utilitaire pour créer des shapefiles.

  La classe contient 3 méthodes de classe :

- FionaShapeService.create_shapes_struct() : crée la structure de 3 shapefiles
  (point, ligne, polygone) à partir des colonens et de la geométrie passée
  en paramètre

- FionaShapeService.create_feature() : ajoute un enregistrement
  aux shapefiles

- FionaShapeService.save_and_zip_shapefiles() : sauvegarde et zip les
  shapefiles qui ont au moins un enregistrement::

        data = DB.session.query(MySQLAModel).all()

        for d in data:
                FionaShapeService.create_shapes_struct(
                        db_cols=db_cols,
                        srid=srid,
                        dir_path=dir_path,
                        file_name=file_name,
                        col_mapping=current_app.config['SYNTHESE']['EXPORT_COLUMNS']
                )
        FionaShapeService.create_feature(row_as_dict, geom)
                FionaShapeService.save_and_zip_shapefiles()


Réponses
********

Voici quelques conseils sur l’envoi de réponse dans vos routes.

- Privilégier l’envoi du modèle sérialisé (vues de type create/update), ou d’une liste de modèles sérialisés (vues de type list), plutôt que des structures de données non conventionnelles.

  ::

    def get_foo(pk):
        foo = Foo.query.get_or_404(pk)
        return jsonify(foo.as_dict(fields=…))

    def get_foo(pk):
        foo = Foo.query.get_or_404(pk)
        return FooSchema(only=…).jsonify(foo)

    def list_foo():
        q = Foo.query.filter(…)
        return jsonify([foo.as_dict(fields=…) for foo in q.all()])

    def list_foo():
        q = Foo.query.filter(…)
        return FooSchema(only=…).jsonify(q.all(), many=True)

- Pour les listes vides, ne pas renvoyer le code d’erreur 404 mais une liste vide !

  ::

    return jsonify([])

- Renvoyer une liste et sa longueur dans une structure de données non conventionnelle est strictement inutile, il est très simple d’accéder à la longueur de la liste en javascript via l’attribut ``length``.

- Traitement des erreurs : utiliser `les exceptions prévues à cet effet <https://werkzeug.palletsprojects.com/en/2.0.x/exceptions/>`_ :

  ::

    from werkzeug.exceptions import Forbidden, BadRequest, NotFound

    def restricted_action(pk):
        if …:
            raise Forbidden

    
  - Penser à utiliser ``get_or_404`` plutôt que de lancer une exception ``NotFound``
  - Si l’utilisateur n’a pas le droit d’effectuer une action, utiliser l’exception ``Forbidden`` (code HTTP 403), et non l’exception ``Unauthorized`` (code HTTP 401), cette dernière étant réservée aux utilisateurs non authentifiés.
  - Vérifier la validité des données fournies par l’utilisateur (``request.json`` ou ``request.args``) et lever une exception ``BadRequest`` si celles-ci ne sont pas valides (l’utilisateur ne doit pas être en mesure de déclencher une erreur 500 en fournissant une string plutôt qu’un int par exemple !).

    - Marshmallow peut servir à cela :

    ::

        from marshmallow import Schema, fields, ValidationError
        def my_route():
            class RequestSchema(Schema):
                value = fields.Float()
            try:
                data = RequestSchema().load(request.json)
            except ValidationError as error:
                raise BadRequest(error.messages)

    - Cela peut être fait avec *jsonschema* :

    ::

        from from jsonschema import validate as validate_json, ValidationError

        def my_route():
            request_schema = {
                "type": "object",
                "properties": {
                    "value": { "type": "number", },
                },
                "minProperties": 1,
                "additionalProperties": False,
            }
            try:
                validate_json(request.json, request_schema)
            except ValidationError as err:
                raise BadRequest(err.message)
    
- Pour les réponses vides (exemple : route de type delete), on pourra utiliser le code de retour 204 :

  ::

    return '', 204

  Lorsque par exemple une action est traitée mais aucun résultat n'est à renvoyer, inutile d’envoyer une réponse « OK ». C’est l’envoi d’une réponse HTTP avec un code égale à 400 ou supérieur qui entrainera le traitement d’une erreur côté frontend, plutôt que de se fonder sur le contenu d’une réponse non normalisée.


Le décorateur ``@json_resp``
""""""""""""""""""""""""""""

Historiquement, beaucoup de vues sont décorées avec le décorateur ``@json_resp``.

Celui-ci apparait aujourd’hui superflu par rapport à l’usage directement de la fonction ``jsonify`` fournie par Flask.

- ``utils_flask_sqla_geo.serializers.json_resp``

  Décorateur pour les routes : les données renvoyées par la route sont
  automatiquement serialisées en json (ou geojson selon la structure des
  données).

  S'insère entre le décorateur de route flask et la signature de fonction

  Fichier routes ::

    from flask import Blueprint
    from utils_flask_sqla.response import json_resp

    blueprint = Blueprint(__name__)

    @blueprint.route('/myview')
    @json_resp
    def my_view():
        return {'result': 'OK'}


    @blueprint.route('/myerrview')
    @json_resp
    def my_err_view():
        return {'result': 'Not OK'}, 400

Problème « n+1 »
****************

Le problème « n+1 » est un anti-pattern courant des routes de type « liste » (par exemple, récupération de la liste des cadres d’acquisition).

En effet, on souhaite par exemple afficher la liste des cadres d’acquisitions, et pour chacun d’entre eux, la liste des jeux de données :

::

    af_list = AcquisitionFramwork.query.all()

    # with Marshmallow (and SmartRelationshipsMixin)
    return AcquisitionFrameworkSchema(only=['datasets']).jsonify(af_list, many=True)

    # with @serializable
    return jsonify([ af.as_dict(fields=['datasets']) for af in af_list])

Ainsi, lors de la sérialisation de chaque AF, on demande à sérialiser l’attribut ``datasets``, qui est une relationships vers la liste des DS associés :

::

    class AcquisitionFramework(db.Model)
        datasets = db.relationships(Dataset, uselist=True)

Sans précision, la `stratégie de chargement <https://docs.sqlalchemy.org/en/14/orm/loading_relationships.html>`_ de la relation ``datasets`` est ``select``, c’est-à-dire que l’accès à l’attribut ``datasets`` d’un AF provoque une nouvelle requête select afin de récupérer la liste des DS concernés.

Ceci est généralement peu grave lorsque l’on manipule un unique objet, mais dans le cas d’une liste d’objet, cela génère 1+n requêtes SQL : une pour récupérer la liste des AF, puis une lors de la sérialisation de chaque AF pour récupérer les DS de ce dernier.

Cela devient alors un problème de performance notable !

Afin de résoudre ce problème, il nous faut joindre les DS à la requête de récupération des AF.

Pour cela, plusieurs solutions :

- Le spécifier dans la relationship :

  ::

    class AcquisitionFramework(db.Model)
        datasets = db.relationships(Dataset, uselist=True, lazy='joined')
    
  Cependant, cette stratégie s’appliquera (sauf contre-ordre) dans tous les cas, même lorsque les DS ne sont pas nécessaires, alourdissant potentiellement certaines requêtes qui n’en ont pas usage.

- Le spécifier au moment où la requête est effectuée :

  ::

    from sqlalchemy.orm import joinedload

    af_list = AcquisitionFramework.query.options(joinedload('datasets')).all()

Il est également possible de joindre les relations d’une relation, par exemple le créateur des jeux de données :

::

    af_list = (
        AcquisitionFramework.query
        .options(
            joinedload('datasets').options(
                joinedload('creator'),
            ),
        )
        .all()
    )

Afin d’être sûr d’avoir joint toutes les relations nécessaires, il est possible d’utiliser la stratégie ``raise`` par défaut, ce qui va provoquer le lancement d’une exception lors de l’accès à un attribut non pré-chargé, nous incitant à le joindre également :

::

    from sqlalchemy.orm import raiseload, joinedload

    af_list = (
        AcquisitionFramework.query
        .options(
            raiseload('*'),
            joinedload('datasets'),
        )
        .all()
    )

Pour toutes les requêtes récupérant une liste d’objet, l’utilisation de la stratégie ``raise`` par défaut est grandement encouragée afin de ne pas tomber dans cet anti-pattern.

La méthode ``as_dict`` du décorateur ``@serializable`` accepte l’argument ``unloaded='raise'`` ou ``unloaded='warn'`` pour un résultat similaire (ou un simple warning).

L’utilisation de ``raiseload``, appartenant au cœur de SQLAlchemy, reste à privilégier.


Export des données
******************

TODO


Utilisation de la configuration
*******************************

La configuration globale de l'application est controlée par le fichier
``config/geonature_config.toml`` qui contient un nombre limité de paramètres.

De nombreux paramètres sont néammoins passés à l'application via un schéma
Marshmallow (voir fichier ``backend/geonature/utils/config_schema.py``).

Dans l'application flask, l'ensemble des paramètres de configuration sont
utilisables via le dictionnaire ``config`` ::

    from geonature.utils.config import config
    MY_PARAMETER = config['MY_PARAMETER']

Chaque module GeoNature dispose de son propre fichier de configuration,
(``module/config/cong_gn_module.toml``) contrôlé de la même manière par un
schéma Marshmallow (``module/config/conf_schema_toml.py``).

Pour récupérer la configuration du module dans l'application Flask,
il existe deux méthodes:

Dans le fichier ``blueprint.py`` ::

        # Methode 1 :

        from flask import current_app
        MY_MODULE_PARAMETER = current_app.config['MY_MODULE_NAME']['MY_PARAMETER]
        # ou MY_MODULE_NAME est le nom du module tel qu'il est défini dans le fichier ``manifest.toml`` et la table ``gn_commons.t_modules``

        #Méthode 2 :
        MY_MODULE_PARAMETER = blueprint.config['MY_MODULE_PARAMETER']

Il peut-être utile de récupérer l'ID du module GeoNature (notamment pour des
questions droits). De la même manière que précédement, à l'interieur d'une
route, on peut récupérer l'ID du module de la manière suivante ::

        ID_MODULE = blueprint.config['ID_MODULE']
        # ou
        ID_MODULE = current_app.config['MODULE_NAME']['ID_MODULE']

Si on souhaite récupérer l'ID du module en dehors du contexte d'une route,
il faut utiliser la méthode suivante ::

        from geonature.utils.env import get_id_module
        ID_MODULE = get_id_module(current_app, 'occtax')


Authentification et authorisations
**********************************

Restreindre une route aux utilisateurs connectés
""""""""""""""""""""""""""""""""""""""""""""""""

Utiliser le décorateur ``@login_required`` :

::

    from geonature.core.gn_permissions.decorators import login_required

    @login_required
    def my_protected_route():
        pass


Connaitre l’utilisateur actuellement connecté
"""""""""""""""""""""""""""""""""""""""""""""

L’utilisateur courant est stocké dans l’espace de nom ``g`` :

::

    from flask import g

    print(g.current_user)


Il s’agit d’une instance de ``pypnusershub.db.models.User``.


Vérification des droits des utilisateurs
""""""""""""""""""""""""""""""""""""""""

- ``geonature.core.gn_permissions.decorators.check_cruved_scope``

  Décorateur pour les routes : Vérifie les droits de l'utilisateur à effectuer
  une action sur la donnée et le redirige en cas de niveau insuffisant ou
  d'informations de session erronées

  params :

  * action <str:['C','R','U','V','E','D']> type d'action effectuée par la route
    (Create, Read, Update, Validate, Export, Delete)
  * get_role <bool:False> : si True, ajoute l'id utilisateur aux kwargs de la vue
  * module_code: <str:None> : Code du module (gn_commons.t_modules) sur lequel on
    veut récupérer le CRUVED. Si ce paramètre n'est pas passé, on vérifie le
    CRUVED de GeoNature


  ::

        from flask import Blueprint
        from geonature.core.gn_permissions.tools import get_or_fetch_user_cruved
        from utils_flask_sqla.response import json_resp
        from geonature.core.gn_permissions import decorators as permissions

        blueprint = Blueprint(__name__)

        @blueprint.route('/mysensibleview', methods=['GET'])
        @permissions.check_cruved_scope(
                'R',
                True,
                module_code="OCCTAX"
        )
        @json_resp
        def my_sensible_view(info_role):
            # Récupérer l'id de l'utilisateur qui demande la route
            id_role = info_role.id_role
            # Récupérer la portée autorisée à l'utilisateur pour l'action 'R' (read)
            read_scope = info_role.value_filter
            #récupérer le CRUVED complet de l'utilisateur courant
            user_cruved = get_or_fetch_user_cruved(
                    session=session,
                    id_role=info_role.id_role,
                    module_code=MY_MODULE_CODE,
            )
            return {'result': 'id_role = {}'.format(info_role.id_role)}

- ``geonature.core.gn_permissions.tools.cruved_scope_for_user_in_module``

  * Fonction qui retourne le CRUVED d'un utilisateur pour un module et/ou
    un objet donné.
  * Si aucun CRUVED n'est défini pour le module, c'est celui de GeoNature qui
    est retourné, sinon 0.
  * Le CRUVED du module enfant surcharge toujours celui du module parent.
  * Le CRUVED sur les objets n'est pas hérité du module parent.

  params :

  * id_role <integer:None>
  * module_code <str:None> : code du module sur lequel on veut avoir le CRUVED
  * object_code <str:'ALL'> : code de l'objet sur lequel on veut avoir le CRUVED
  * get_id <boolean: False> : retourne l'id_filter et non le code_filter si True

  Valeur retournée : tuple

  A l'indice 0 du tuple: <dict{str:str}> ou <dict{str:int}>, boolean)
  {'C': '1', 'R':'2', 'U': '1', 'V':'2', 'E':'3', 'D': '3'} ou
  {'C': 2, 'R':3, 'U': 4, 'V':1, 'E':2, 'D': 2} si ``get_id=True``

  A l'indice 1 du tuple: un booléen spécifiant si le CRUVED est hérité depuis
  un module parent ou non.

  ::

    from pypnusershub.db.tools import cruved_for_user_in_app

    # récupérer le CRUVED de l'utilisateur 1 dans le module OCCTAX
    cruved, herited = cruved_scope_for_user_in_module(
            id_role=1
            module_code='OCCTAX
    )
    # récupérer le CRUVED de l'utilisateur 1 sur GeoNature
    cruved, herited = cruved_scope_for_user_in_module(id_role=1)


Développement Frontend
----------------------

Bonnes pratiques
****************

- Chaque gn_module de GeoNature doit être un module Angular indépendant https://angular.io/guide/ngmodule. 
- Ce gn_module peut s'appuyer sur une série de composants génériques intégrés dans le module GN2CommonModule et décrit ci-dessous 

Les composants génériques
*************************

Un ensemble de composants décrits ci-dessous sont intégrés dans le coeur de GeoNature et permettent aux développeurs de simplifier la mise en place de formulaires ou de bloc cartographiques. 

Voir la `DOCUMENTATION COMPLETE <http://pnx-si.github.io/GeoNature/frontend/modules/GN2CommonModule.html>`_ sur les composants génériques. 

NB : les composants de type "formulaire" (balise `input` ou `select`) partagent une logique commune et ont des ``Inputs`` et des ``Outputs`` communs, décrits ci-dessous. (voir https://github.com/PnX-SI/GeoNature/blob/master/frontend/src/app/GN2CommonModule/form/genericForm.component.ts).

Une documentation complète des composants génériques est
`disponible ici <http://pnx-si.github.io/GeoNature/frontend/modules/GN2CommonModule.html>`_

NB : les composants de type "formulaire" (balise `input` ou `select`) partagent
une logique commune et ont des ``Inputs`` et des ``Outputs`` communs, décrits
ci-dessous.
(voir https://github.com/PnX-SI/GeoNature/blob/master/frontend/src/app/GN2CommonModule/form/genericForm.component.ts).

- Inputs

  - L'input ``parentFormControl`` de type ``FormControl`` (https://angular.io/api/forms/FormControl) permet de contrôler la logique et les valeurs du formulaire depuis l'extérieur du composant. Cet input est **obligatoire** pour le fonctionnement du composant.
  - L'input ``label`` (string) permet d'afficher un label au dessus de l'input.
  - L'input ``displayAll`` (boolean, défaut = false) permet d'ajouter un item 'tous' sur les inputs de type select (Exemple : pour sélectionner tous les jeux de données de la liste)
  - L'input ``multiSelect`` (boolean, défaut = false) permet de passer les composants de type select en "multiselect" (sélection multiple sur une liste déroulante). Le parentFormControl devient par conséquent un tableau
  - L'input ``searchBar`` (boolean, défaut = false) permet de rajouter une barre de recherche sur les composants multiselect
  - L'input ``disabled`` (boolean) permet de rendre le composant non-saisissable
  - L'input ``debounceTime`` définit une durée en ms après laquelle les évenements ``onChange`` et ``onDelete`` sont déclenchés suite à un changement d'un formulaire. (Par défault à 0)

- Outputs

  Plusieurs ``Output`` communs à ses composants permettent d'émettre des événements liés aux formulaires.

  - ``onChange`` : événement émit à chaque fois qu'un changement est effectué sur le composant. Renvoie la valeur fraiche de l'input.
  - ``onDelete`` : événement émit chaque fois que le champ du formulaire est supprimé. Renvoie un évenement vide.

Ces composants peuvent être considérés comme des "dump components" ou
"presentation components", puisque que la logique de contrôle est déporté
au composant parent qui l'accueil
(https://blog.angular-university.io/angular-2-smart-components-vs-presentation-components-whats-the-difference-when-to-use-each-and-why/)

Un ensemble de composants permettant de simplifier l'affichage des cartographies
Leaflet sont disponibles. Notamment un composant "map-list" permettant de
connecter une carte avec une liste d'objets décrits en détail ci dessous.

MapListComponent
""""""""""""""""

Le composant MapList fournit une carte pouvant être synchronisée
avec une liste. La liste, pouvant être spécifique à chaque module,
elle n'est pas intégrée dans le composant et est laissée à la
responsabilité du développeur. Le service ``MapListService`` offre
cependant des fonctions permettant facilement de synchroniser
les deux éléments.

Fonctionnalité et comportement offert par le composant et le
service :

- Charger les données
  
  Le service expose la fonction ``getData(apiEndPoint, params?)``
  permettant de charger les données pour la carte et la liste.
  Cette fonction doit être utilisée dans le composant qui utilise
  le composant ``MapListComponent``. Elle se charge de faire
  appel à l'API passée en paramètre et de rendre les données
  disponibles au service.

  Le deuxième paramètre ``params`` est un tableau de paramètre(s)
  (facultatif). Il permet de filtrer les données sur n'importe
  quelle propriété du GeoJson, et également de gérer
  la pagination.

  Exemple : afficher les 10 premiers relevés du cd_nom 212 :

  ::

        mapListService.getData('occtax/releve',
        [{'param': 'limit', 'value': 10'},
        {'param': 'cd_nom', 'value': 212'}])

  `Exemple dans le module OccTax  <https://github.com/PnX-SI/GeoNature/blob/master/contrib/occtax/frontend/app/occtax-map-list/occtax-map-list.component.ts#L99/>`_

  L'API doit nécessairement renvoyer un objet comportant un
  GeoJson. La structure du l'objet doit être la suivante :

  ::

        'total': nombre d'élément total,
        'total_filtered': nombre d'élément filtré,
        'page': numéro de page de la liste,
        'limit': limite d'élément renvoyé,
        'items': le GeoJson

  Pour une liste simple sans pagination, seule la propriété 'items'
  est obligatoire.

- Rafraîchir les données
        
  La fonction ``refreshData(apiEndPoint, method, params?)`` permet de raffrachir les données en fonction de filtres personnalisés.
  Les paramètres ``apiEndPoint`` et ``params`` sont les mêmes que pour la fonction ``getData``. Le paramètre ``method`` permet lui de chosir si on ajoute - ``append``- , ou si on initialise (ou remplace) -``set``- un filtre.

  Exemple 1 : Pour filtrer sur l'observateur 1, puis ajouter un filtre sur l'observateur 2 :

  ::

      mapListService.refreshData('occtax/relevé', 'append, [{'param': 'observers', 'value': 1'}])

  puis :

  ::
    
      refreshData('occtax/relevé', 'append, [{'param': 'observers', 'value': 2'}])

  Exemple 2: pour filtrer sur le cd_nom 212, supprimer ce filtre et filtrer sur  le cd_nom 214
    
  ::
    
      mapListService.refreshData('occtax/relevé', 'set, [{'param': 'cd_nom', 'value': 1'}])

  puis :
    
  ::
    
      mapListService.refreshData('occtax/relevé', 'set, [{'param': 'cd_nom', 'value': 2'}])

- Gestion des évenements :
        
  - Au clic sur un marker de la carte, le service ``MapListService`` expose la propriété ``selectedRow`` qui est un tableau contenant l'id du marker sélectionné. Il est ainsi possible de surligner l'élément séléctionné dans le liste.
  - Au clic sur une ligne du tableau, utiliser la fonction ``MapListService.onRowSelected(id)`` (id étant l'id utilisé dans le GeoJson) qui permet de zoomer sur le point séléctionner et de changer la couleur de celui-ci.

Le service contient également deux propriétés publiques ``geoJsonData`` (le geojson renvoyé par l'API) et ``tableData`` (le tableau de features du Geojson) qui sont respectivement passées à la carte et à la liste. Ces deux propriétés sont utilisables pour interagir (ajouter, supprimer) avec les données de la carte et de la liste.

- Selector : ``pnx-map-list``

- Inputs :

  :``idName``:
                        Libellé de l'id du geojson (id_releve, id)

                        Type: ``string``
  :``height``:
                        Taille de l'affichage de la carte Leaflet

                        Type: ``string``

Exemple d'utilisation avec une liste simple :
        
.. code-block::

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

Test end to end
***************

Pour toute PR ou nouvelle fonctionnalité il est demandé d'écrire des tests.
Pour les test e2e, la librairie Cypress est utilisé. 
Des exemples de tests peuvent être trouvé ici : https://github.com/PnX-SI/GeoNature/tree/develop/frontend/cypress/integration
Les tests sont joués automatiquement sur Github-action lors de commit et PR sur la branch develop et master.
Pour lancer les tests sur sa machine locale, utilisez la commande ``npm run e2e && npm run e2e:coverage``. Celle-ci lance le serveur de frontend, joue les tests cypress et contrôle la couverture de test. Cette dernière est disponible dans le repertoire `frontend/coverage`.


Test end to end
***************

Pour toute PR ou nouvelle fonctionnalité il est demandé d'écrire des tests.
Pour les test e2e, la librairie Cypress est utilisé. 
Des exemples de tests peuvent être trouvé ici : https://github.com/PnX-SI/GeoNature/tree/develop/frontend/cypress/integration
Les tests sont joués automatiquement sur Github-action lors de commit et PR sur la branch develop et master.
Pour lancer les tests sur sa machine locale, utilisez la commande ``npm run e2e && npm run e2e:coverage``. Celle-ci lance le serveur de frontend, joue les tests cypress et contrôle la couverture de test. Cette dernière est disponible dans le repertoire `frontend/coverage`.


* dans les templates : ``[valueFieldName]="'area_code'`` dans les templates
* dans les config (js, ts ou json) (attention à la casse) : ``"value_field_name": "area_code"``
* dans le module Monitoring, ajouter aussi ``"type_util": "area"``

Outils d'aide à la qualité du code
----------------------------------

Des outils d'amélioration du code pour les développeurs peuvent être utilisés :
flake8, pylint, pytest, coverage.

La documentation peut être générée avec Sphinx.

Les fichiers de configuration de ces outils se trouvent à la racine du projet :

* .pylint

Un fichier ``.editorconfig`` permettant de définir le comportement de
votre éditeur de code est également disponible à la racine du projet.


Sphinx
******

Sphinx est un générateur de documentation.

Pour générer la documentation HTML, se placer dans le répertoire ``docs``
et modifier les fichiers .rst::

        cd docs
        make html


Pylint
******

Pylint fait la même chose que Flake8 mais il est plus complet, plus
configurable mais aussi plus exigeant.

Pour inspecter le répertoire ``geonature``::

        cd backend
        pylint geonature

tslint
******

tslint fait la même chose que pylint mais pour la partie frontend en
typescript::

        cd frontend
        npm run lint



.. include:: tests_backend.rst

.. include:: tests_frontend.rst
