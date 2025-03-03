Développement
=============

Général
-------

GeoNature 1, créé en 2010, a été développé par Gil Deluermoz avec PHP/Symfony/ExtJS.

GeoNature 2 est une refonte initiée en 2017 par les parcs nationaux français en Python/Flask/Angular.

Mainteneurs actuels :

- Jacques FIZE (PnEcrins)
- Pierre NARCISI (Patrinat)
- Vincent CAUCHOIS (Patrinat)
- Élie BOUTTIER (PnEcrins)
- Théo LECHEMIA (PnEcrins)
- Amandine SAHL (PnCevennes)
- Camille MONCHICOURT (PnEcrins)

.. image :: _static/geonature-techno.png

.. _api:

API
---

GeoNature utilise :

- l'API de TaxHub (recherche taxon, règne et groupe d'un taxon...), intégrée à GeoNature depuis sa version 2.15
- l'API du sous-module Nomenclatures (typologies et listes déroulantes)
- l'API du sous-module d'authentification de UsersHub (login/logout, récupération du CRUVED d'un utilisateur)
- l'API de GeoNature (get, post, update des données des différents modules, métadonnées, intersections géographiques, exports...)

.. image :: _static/api_services.png

Liste des routes
****************

Vous pouvez obtenir la liste des routes de GeoNature avec la commande suivante :

.. code-block:: bash

    geonature routes


Documentation des routes
************************

Génération automatique actuellement hors-service :-(


Pratiques et règles de developpement
------------------------------------

Afin de partager des règles communes de développement et faciliter l'intégration de 
nouveau code, veuillez lire les recommandations et bonnes pratiques recommandées pour contribuer
au projet GeoNature.

Git
***

- Assurez-vous d’avoir récupéré les dépendances dans les sous-modules git : ``git submodule init && git submodule update``
- Après un ``git pull``, il faut mettre à jour les sous-modules : ``git submodule update``

- Ne jamais faire de commit dans la branche ``master`` mais dans la branche ``develop`` ou idéalement dans une branche dédiée à la fonctionnalité (feature branch)
- Faire des pull requests vers la branche ``develop``
- Faire des ``git pull`` avant chaque développement et avant chaque commit
- Les messages des commits font référence à un ticket ou le ferment (``ref #12`` ou ``fixes #23``)
- Les messages des commits sont en anglais (dans la mesure du possible)
- Privilégier les rebases afin de conserver un historique linéaire
- Privilégier l’amendement (``git commit --amend`` ou ``git commit --fixup``) des commits existants lorsque vous portez des corrections à votre PR, en particulier pour l’application du style.


Backend
*******

- Une fonction ou classe doit contenir une docstring en français. Les doctrings doivent suivre le modèle NumPy/SciPy (voir https://numpydoc.readthedocs.io/en/latest/format.html et https://realpython.com/documenting-python-code/#numpyscipy-docstrings-example)
- Les commentaires dans le codes doivent être en anglais (ne pas s'empêcher de mettre un commentaire en français sur une partie du code complexe !)
- Utiliser *blake* comme formateur de texte et activer l'auto-formatage dans son éditeur de texte (Tuto pour VsCode : https://medium.com/@marcobelo/setting-up-python-black-on-visual-studio-code-5318eba4cd00)
- La longueur maximale pour une ligne de code est 100 caractères. Pour VSCODE copier ces lignes le fichier ``settings.json`` :

.. code:: python

    "python.formatting.blackArgs": [
      "--line-length",
      "100"
    ]

- Privilégier la snake_case pour les variables, CamelCase pour les classes.

BDD 
***

- Le noms des tables est préfixé par "t\_" pour une table de contenu, de "bib\_" pour les tables de "dictionnaires" et de "cor\_" pour les tables de correspondance (relations N-N)
- Les schémas du coeur de GeoNature sont préfixés de "gn\_"
- Les schémas des protocoles ou modules GeoNature sont préfixés de "pr\_"
- Ne rien écrire dans le schéma ``public``

Modèle Python
"""""""""""""

Les conventions précédentes concernent uniquement la BDD. Pour les modèles Python, on fera attention à :

- Nommer les modèles sans le préfixe "t\_", et à les écrire au singulier. Exemple : ``class Observation:``.
- Ne pas répeter le nom des tables dans les noms des colonnes.

.. _typescript:

Typescript
**********

- Documenter les fonctions et classes grâce au JSDoc en français (https://jsdoc.app/)
- Les commentaires dans le codes doivent être en anglais (ne pas s'empêcher de mettre un commentaire en français sur une partie du code complexe !)
- Les messages renvoyés aux utilisateurs sont en français 
- Installer les outils de devéloppement : ``npm install --only=dev``
- Utiliser *prettier* comme formateur de texte et activer l'autoformatage dans son éditeur de texte (VsCode dispose d'une extension Prettier : https://github.com/prettier/prettier-vscode)
  Pour lancer manuellement prettier depuis le dossier ``frontend`` :

.. code-block:: bash

    nvm use
    npm run format

- La longueur maximale pour une ligne de code est 100 caractères.

Angular
*******

- Suivre les recommandations définies par le styleguide Angular: https://angular.io/guide/styleguide. C'est une ressources très fournie en cas de question sur les pratiques de développement (principe de séparation des principes, organisation des services et des composants)
- On privilégiera l'utilisation des reactive forms pour la construction des formulaires (https://angular.io/guide/reactive-forms). Ce sont des formulaires pilotés par le code, ce qui facilite la lisibilité et le contrôle de ceux-ci.
- Pour l'ensemble des composants cartographiques et des formulaires (taxonomie, nomenclatures...), il est conseillé d'utiliser les composants présents dans le module 'GN2CommonModule'.
 
HTML 
****

- La longueur maximale pour une ligne de code est 100 caractères.
- Revenir à la ligne avant et après le contenue d'une balise.
- Lorsqu'il y a plus d'un attribut sur une balise, revenir à la ligne, aligner les attributs et aller a la ligne pour fermer la balise :

.. code:: html

      <button 
        mat-raised-button
        color="primary"
        class="btn-action hard-shadow uppercase ml-3"
        data-toggle="collapse"
        data-target="#collapseAvance"
      >
        Filtrer
      </button>

- VSCODE fournit un formatteur de HTML par défaut (Dans les options de VsCode, tapez "wrap attributes" et sélectionner "force-expand-multiline")
- En plus du TypeScript/Javascript, Prettier permet de formater le HTML et le SCSS (Se référer à la configuration N’oubliez pas les :ref:`Typescript <typescript>`.)

Style et ergonomie
******************

- Boutons :
  On utilise les boutons d'Angular Material (https://material.angular.io/components/button/overview).
  
  - mat-raised-button pour les boutons contenant du texte 
  - mat-fab ou mat-mini-fab pour les boutons d'actions avec seulement une icone 

- Couleur des boutons :

  - Action : primary 
  - Validation: vert (n'existant pas dans Material : utiliser la classe `button-success`)
  - Suppression: warn 
  - Navigation: basic 

- Librairie d'icones :

  - Utiliser la librairie Material icons fournie avec le projet : https://material.io/resources/icons/?style=baseline (``<mat-icon> add </mat-icon>``)

- Formulaire :

  - Nous utilisons pour l'instant le style des formulaires Bootstrap (https://getbootstrap.com/docs/4.0/components/forms/). Une reflexion de migration vers les formulaires materials est en cours.

- Système de grille et responsive :

  - Utiliser le système de grille de Bootstrap pour assurer le responsive design sur l'application. On ne vise pas l'utilisation sur mobile, mais à minima sur ordinateur portable de petite taille.

.. _mode-dev:

Passer en mode développement
----------------------------

Cette section documente comment passer en mode développement une installation de GeoNature initialement faite en mode production.

Récupération des sources
************************

Si vous avez téléchargé GeoNature zippé (via la procédure d'installation globale ``install_all.sh`` ou en suivant la documentation d'installation standalone), il est nécessaire de rattacher votre répertoire au dépôt GitHub afin de pouvoir télécharger les dernières avancées du coeur en ``git pull``. Pour cela, suivez les commandes suivantes en vous placant à la racine du répertoire de GeoNature.

.. code-block:: bash

  # Se créer un répertoire .git
  mkdir .git
  # Récupérer l'historique du dépôt
  git clone --depth=2 --bare https://github.com/PnX-SI/GeoNature.git .git
  # Initialiser un dépôt git à partir de l'historique téléchargé
  git init
  # Vérifier que le dépôt distant et le contenu local sont synchronisés
  git pull
  # Reset sur HEAD pour mettre à jour les status
  git reset HEAD
  # -> vous êtes à jour sur la branche master
  # Cloner les sous-modules pour récupérer les dépendances
  git submodule init
  git submodule update


Installation du venv en dev
***************************

Il est nécessaire d’installer les dépendances (sous-modules Git présent dans ``backend/dependencies``) en mode éditable afin de travailler avec la dernière version de celles-ci.

.. code-block:: console

  cd backend
  source venv/bin/activate
  pip install -e .. -r requirements-dev.txt


Configuration des URLs de développement
***************************************

Il est nécessaire de changer la configuration du fichier ``config/geonature_config.toml`` pour utiliser les adresses suivantes :

.. code-block:: toml

  URL_APPLICATION = 'http://127.0.0.1:4200'
  API_ENDPOINT = 'http://127.0.0.1:8000'

N’oubliez pas les :ref:`actions à effectuer après modification de la configuration <post_config_change>`.


Autres extensions en développement
**********************************

Il n'est pas forcémment utile de passer toutes les extensions en mode dévelomment.
Pour plus d'informations, référez-vous aux documentations dédiées :

- https://taxhub.readthedocs.io/fr/latest/developpement.html
- https://usershub.readthedocs.io/fr/latest/

Debugger avec un navigateur
***************************

L'extension `Angular DevTools <https://angular.io/guide/devtools>`_ permettra de debugger l'application dans la console du navigateur.
Pour utiliser l'extension vous devez l'installer et passer obligatoirement en mode ``development``.

.. _dev-backend:

Développement Backend
----------------------

Démarrage du serveur de dev backend
***********************************

La commande ``geonature`` fournit la sous-commande ``dev-back`` pour lancer un serveur de test :

.. code:: console

    source <GEONATURE_DIR>backend/venv/bin/activate
    geonature dev-back


L’API est alors accessible à l’adresse http://127.0.0.1:8000.


Base de données avec Flask-SQLAlchemy
*************************************

L’intégration de la base de données à GeoNature repose sur la bibliothèque `Flask-SQLAlchemy <https://flask-sqlalchemy.palletsprojects.com>`_.

Celle-ci fournit un objet ``db`` à importer comme ceci : ``from geonature.utils.env import db``

Cet objet permet d’accéder à la session SQLAlchemy ainsi :

.. code:: python

    from geonature.utils.env import db
    obj = db.session.query(MyModel).get(1)

Mais il fournit une base déclarative ``db.Model`` permettant d’interroger encore plus simplement les modèles via leur attribut ``query`` :

.. code:: python

    from geonature.utils.env import db
    class MyModel(db.Model):
        …

    obj = MyModel.query.get(1)

L’attribut ``query`` fournit `plusieurs fonctions <https://flask-sqlalchemy.palletsprojects.com/en/2.x/api/#flask_sqlalchemy.BaseQuery>`_ très utiles dont la fonction ``get_or_404`` :

.. code:: python

    obj = MyModel.query.get_or_404(1)

Ceci est typiquement la première ligne de toutes les routes travaillant sur une instance (route de type get/update/delete).


Fonctions de filtrages
""""""""""""""""""""""

L’attribut ``query`` est une instance de la classe ``flask_sqlalchemy.BaseQuery`` qui peut être surchargée afin de définir de nouvelles fonctions de filtrage.

On pourra ainsi implémenter une fonction pour filtrer les objets auxquels l’utilisateur a accès, ou encore pour implémenter des filtres de recherche.

.. code:: python

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


Serialisation des modèles avec Marshmallow
******************************************

La bibliothèque `Marshmallow <https://marshmallow.readthedocs.io/en/stable/>`_ fournit des outils de sérialisation et desérialisation.

Elle est intégrée à GeoNature par la bibliothèque `Flask-Marshmallow <https://flask-marshmallow.readthedocs.io/en/latest/>`_ qui fournit l’objet ``ma`` à importer comme ceci : ``from geonature.utils.env import ma``.

Cette bibliothèque ajoute notablement une méthode ``jsonify`` aux schémas.

Les schémas Marshmallow peuvent être facilement créés à partir des modèles SQLAlchemy grâce à la bibliothèque `Marshmallow-SQLAlchemy <https://marshmallow-sqlalchemy.readthedocs.io/en/latest/>`_.

.. code:: python

    from geonature.utils.env import ma

    class MyModelSchema(ma.SQLAlchemyAutoSchema):
        class Meta:
            model = MyModel
            include_fk = True


Gestion des relationships
"""""""""""""""""""""""""

L’option ``include_fk=True`` concerne les champs de type ``ForeignKey``, mais pas les ``relationships`` en elles-mêmes. Pour ces dernières, il est nécessaire d’ajouter manuellement des champs ``Nested`` à notre schéma :

.. code:: python

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
Il est donc nécessaire de restreindre les champs à inclure dans la sérialisation lors de la création du schéma :

- avec l’argument ``only`` :
    .. code:: python

        parent_schema = ParentModelSchema(only=['pk', 'childs.pk'])

    L’utilisation de ``only`` a l’inconvénient d’être lourde puisqu’il faut spécifier l’ensemble les champs à sérialiser.
    De plus, l’ajout d’une nouvelle colonne au modèle nécessite de la rajouter partout où le schéma est utilisé.

- avec l’argument ``exclude`` :
    .. code:: python

        parent_schema = ParentModelSchema(exclude=['childs.parent'])


    Cependant, l’utilisation de ``exclude`` est hautement problématique !
    En effet, l’ajout d’un nouveau champs ``Nested`` au schéma nécessiterait de le rajouter dans la liste des exclusions partout où le schéma est utilisé (que ça soit pour éviter une récursion infinie, d’alourdir une réponse JSON avec des données inutiles ou pour éviter un problème n+1 - voir section dédiée).

La bibliothèque Utils-Flask-SQLAlchemy fournit une classe utilitaire ``SmartRelationshipsMixin`` permettant d’exclure par défaut les champs ``Nested``.
Pour demander la sérialisation d’un sous-schéma, il faut le spécifier avec ``only``, mais sans nécessité de spécifier tous les champs basiques (non ``Nested``).

.. code:: python

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


Modèles avec nomenclatures
""""""""""""""""""""""""""

Le convertisseur de modèle ``NomenclaturesConverter`` permet d’automatiquement ajouter un champs ``Nested(NomenclatureSchema)`` pour les relationships vers une nomenclature.


.. code:: python

    from pypnnomenclature.models import TNomenclatures as Nomenclature
    from pypnnomenclature.utils import NomenclaturesConverter

    class MyModel(db.Model):
        id_nomenclature_foo = db.Column(db.Integer, ForeignKey(Nomenclature.id_nomenclature))
        nomenclature_foo = relationships(Nomenclature, foreign_keys=[id_nomenclature_foo])

    class MyModelSchema(ma.SQLAlchemyAutoSchema):
        class Meta:
            model = MyModel
            include_fk = True
            model_converter = NomenclaturesConverter

        # automatically added: nomenclature_foo = ma.Nested(NomenclatureSchema)


Le mixin ``NomenclaturesMixin`` permet de définir une propriété ``__nomenclatures__`` sur un modèle contenant
la liste des champs à nomenclature.
Cette propriété peut être utilisé pour facilement joindre et inclure lors de la sérialisation les champs à nomenclatures.


.. code:: python

    from pypnnomenclature.models import TNomenclatures as Nomenclature
    from pypnnomenclature.utils import NomenclaturesMixin

    class MyModel(NomenclaturesMixin, db.Model):
        id_nomenclature_foo = db.Column(db.Integer, ForeignKey(Nomenclature.id_nomenclature))
        nomenclature_foo = relationships(Nomenclature, foreign_keys=[id_nomenclature_foo])

    # joinedload all nomenclatures
    q = MyModel.query.options(*[joinedload(n) for n in MyModel.__nomenclatures__])
    # include all nomenclatures to serialization
    schema = MyModelSchema(only=MyModel.__nomenclatures__).dump(q.all())


Modèles géographiques
"""""""""""""""""""""

En utilisant ``GeoAlchemyAutoSchema`` à la place de ``SQLAlchemyAutoSchema``, il est facile de créer des schémas pour des modèles possédant des colonnes géométriques :

- Utilisation automatique de ``model_converter = GeoModelConverter`` afin de convertir les colonnes géométriques
- Exclusion par défaut des colonnes géométriques de la sérialisation
- Possibilité de générer du `geojson` en initialisant le schéma avec ``as_geojson=True``

Les options suivantes sont disponible (à rajouter comme propriété de la classe Méta, ou comme paramètre à la création du schéma) :

- ``feature_id`` : Colonne à utiliser pour remplire l’``id`` des features geojson.
  Typiquement la clé primaire du modèle. Exclue si non spécifié.
- ``feature_geometry`` : Colonne à utiliser pour définir la ``geometry`` des features geojson.
  Déterminée automatiquement lorsque le modèle possède une unique colonne géométrique.

.. code:: python

    class MyModel(db.Model):
        pk = db.Column(Integer, primary_key=True)
        geom = db.Column(Geometry("GEOMETRY"))

    class MyModelSchema(GeoAlchemyAutoSchema):
        class Meta:
            model = MyModel
            feature_id = "pk"  # optionnel
            feature_geometry = "geom"  # automatiquement déterminé

.. code:: pycon

    >>> o = MyModel(pk=1, geom=from_shape(Point(6, 10)))
    >>> MyModelSchema().dump(o)
    {"pk": 1}  # la colonne géométrique est automatiquement exclue
    >>> MyModelSchema(as_geojson=True).dump(o)
    {
        "type": "Feature",
        "id": 1,
        "geometry": {"type": "Point", "coordinates": [6, 10]},
        "properties": {"pk": 1}
    }

La sortie sera une `FeatureCollection` lorsque le schéma est utilisé avec ``many=True``.

Les schémas géographiques peuvent également être utilisé pour parser du geojson (`Feature` ou `FeatureCollection`).



Modèles géographiques avec nomenclatures
""""""""""""""""""""""""""""""""""""""""

Si vous avez un modèle possédant à la fois des relations vers des nomenclatures et des colonnes géométriques,
vous pouvez devoir créer votre propre convertisseur de modèle héritant à la fois de ``NomenclaturesConverter`` et de ``GeoModelConverter`` :

.. code:: python

    class NomenclaturesGeoModelConverter(NomenclaturesConverter, GeoModelConverter):
        pass

    class MyModelSchema(GeoAlchemyAutoSchema):
        class Meta:
            model = MyModel
            model_converter = NomenclaturesGeoModelConverter


Modèles de permission
"""""""""""""""""""""

Le mixin ``CruvedSchemaMixin`` permet d’ajouter un champs ``cruved`` à la sérialisation qui contiendra un dictionnaire avec en clé les actions du cruved et en valeur des booléens indiquant si l’action est disponible.

Pour l’utiliser, il faut :

- Définir une propriété ``__module_code__`` (et optionnellement une propriété ``__object_code__``) au niveau du **schéma** Marshmallow.
  Ces propriétés sont passées en argument à la fonction ``get_scopes_by_action``.
- Le **modèle** doit définir une fonction ``has_instance_permission(scope)`` prenant en argument une portée (0, 1, 2 ou 3) et renvoyant un booléen.

Par défaut, le CRUVED est exclu de la sérialisation pour des raisons de performance.
Il faut donc demander sa sérialisation lors de la création du schéma avec ``only=["+cruved"]``.
Le préfixe ``+`` permet de spécifier que l’on souhaite rajouter le cruved aux champs à sérialiser (et non que l’on souhaite sérialiser uniquement le cruved).

.. code:: python

    from geonature.utils.schema import CruvedSchemaMixin

    class MyModel(db.Model):
        # …
        owner = db.relationship(User)

        def has_instance_permission(self, scope):
            return scope == 3 or (scope in (1, 2) and self.owner == g.current_user)

    class MyModelSchema(CruvedSchemaMixin, ma.SQLAlchemyAutoSchema):
        class Meta:
            model = MyModel
            include_fk = True

        __module_code__ = "MODULE_CODE"

        # automatically added: cruved = fields.Method("get_cruved", metadata={"exclude": True})

.. code:: pycon

    >>> o = MyModel.query.first()
    >>> MyModelSchema(only=["+cruved"]).dump(o)
    {"pk": 42, "cruved": {"C": False, "R": True, "U": True, "V": False, "E": False}}


Création d’un objet
"""""""""""""""""""

L’utilisation de ``load_instance=True`` permet, lors de l’appelle de la fonction ``load``, de directement récupérer un objet pouvant être ajouté à la session SQLAlchemy.

.. code:: python

    class MyModelSchema(SmartRelationshipsMixin, ma.SQLAlchemyAutoSchema):
        class Meta:
            model = MyModel
            include_fk = True
            load_instance = True

    o = MyModelSchema().load(request.json)
    db.session.add(o)
    db.session.commit()


Gestion des relationships
'''''''''''''''''''''''''

Many-to-One
```````````

Exemple d’une relation vers une nomenclature :

.. code:: python

    class MyModel(db.Model):
        id_nomenclature_foo = db.Column(db.Integer, ForeignKey(Nomenclature.id_nomenclature))
        nomenclature_foo = relationships(Nomenclature, foreign_keys=[id_nomenclature_foo])

    class MyModelSchema(ma.SQLAlchemyAutoSchema):
        class Meta:
            model = MyModel
            include_fk = True
            model_converter = NomenclaturesConverter

    # Le front spécifie directement la ForeignKey et non la relationship :
    o = MyModelSchema().load({"id_nomenclature_foo": 42})


Many-to-Many
````````````

Exemple d’une relation vers plusieurs utilisateurs :

.. code:: python

    cor_mymodel_user = db.Table(...)

    class MyModel(db.Model):
        owners = relationship(User, secondary=cor_mymodel_user)

    class MyModelSchema(SmartRelationshipsMixin, ma.SQLAlchemyAutoSchema):
        class Meta:
            model = MyModel
            include_fk = True

    # Le front spécifie la ForeignKey, la relationship est ignoré :
    o = MyModelSchema(only=["owners.id_role"]).load({
        "owners": [{"id_role": 42}, {"id_role": 43}]
    })


.. warning:: Prendre garde à bien spécifier ``owners.id_role`` et non simplement ``owners``, sans quoi il devient possible d’utiliser votre route pour créer des utilisateurs !


One-to-Many
```````````

Exemple d’une relation vers des modèles enfants, qui sont rattaché à un unique parent :

.. code:: python

    class Child(db.Model):
        id_parent = db.Column(Integer, ForeignKey(Parent.id))
        parent = relationship(Parent, back_populates="childs")

    class Parent(db.Model):
        id = db.Column(Integer, primary_key=True)
        childs = relationship(Child, cascade="all, delete-orphan", back_populates="parent")

    class ChildSchema(SmartRelationshipsMixin, ma.SQLAlchemyAutoSchema):
        class Meta:
            model = MyModel
            include_fk = True
            load_instance = True

        parent = Nested(ParentSchema)

    class ParentSchema(SmartRelationshipsMixin, ma.SQLAlchemyAutoSchema):
        class Meta:
            model = ParentModel
            include_fk = True
            load_instance = True

        childs = Nested(ChildSchema, many=True)

        @validates_schema
        def validate_childs(self, data, **kwargs):
            """
            Ensure this schema is not leveraged to retrieve childs from other parent
            """
            for child in data["childs"]:
                if child.id_parent is not None and data.get("id") != child.id_parent:
                    raise ValidationError(
                        "Child does not belong to this parent.", field_name="childs"
                    )

    o = ParentSchema(only=["childs"], dump_only=["childs.id_parent"]).load({
        "pk": 1,
        "childs": [
            {"pk": 1},  # validate_childs checks child 1 belongs to parent 1
        ]
    })


.. warning:: Prendre garde à ajouter ``dump_only=["childs.id_parent"]``, sans quoi il devient possible de créer des objets Child appartenant à un autre Parent !

.. warning:: Prendre garde à ajouter une validation sur le modèle parent de l’appartenance des objets Child, sans quoi il devient possible de rattacher à un parent des objets Child appartenant à un autre parent !

.. warning:: Le frontend doit systématiquement listé l’ensemble des childs, sans quoi ceux-ci seront supprimé.


Serialisation des modèles avec le décorateur ``@serializable``
**************************************************************

.. note::
  L’utilisation des schémas Marshmallow est probablement plus performante.

La bibliothèque maison `Utils-Flask-SQLAlchemy <https://github.com/PnX-SI/Utils-Flask-SQLAlchemy>`_ fournit le décorateur ``@serializable`` qui ajoute une méthode ``as_dict`` sur les modèles décorés :

.. code:: python

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

.. code:: python

    child.as_dict(fields=['parent.pk'])

Les `tests unitaires <https://github.com/PnX-SI/Utils-Flask-SQLAlchemy/blob/master/src/utils_flask_sqla/tests/test_serializers.py>`_ fournissent un ensemble d’exemples d’usage du décorateur.

La fonction ``as_dict`` prenait autrefois en argument les paramètres ``recursif`` et ``depth`` qui sont tous les deux obsolètes. Ces derniers ont différents problèmes :

- récursion infinie (contournée par un hack qui ne résoud pas tous les problèmes et qu’il serait souhaitable de voir disparaitre)
- augmentation non prévue des données sérialisées lors de l’ajout d’une nouvelle relationship
- problème n+1 (voir section dédiée)

Modèles géographiques
"""""""""""""""""""""

La bibliothèque maison `Utils-Flask-SQLAlchemy-Geo <https://github.com/PnX-SI/Utils-Flask-SQLAlchemy-Geo>`_ fournit des décorateurs supplémentaires pour la sérialisation des modèles contenant des champs géographiques.

- ``utils_flask_sqla_geo.serializers.geoserializable``
    Décorateur pour les modèles SQLA : Ajoute une méthode as_geofeature qui
    retourne un dictionnaire serialisable sous forme de Feature geojson.


    Fichier définition modèle 

    .. code:: python

        from geonature.utils.env import DB
        from utils_flask_sqla_geo.serializers import geoserializable


        @geoserializable
        class MyModel(DB.Model):
            __tablename__ = 'bla'
            ...


    Fichier utilisation modèle 

    .. code:: python

        instance = DB.session.query(MyModel).get(1)
        result = instance.as_geofeature()

- ``utils_flask_sqla_geo.serializers.shapeserializable``
    Décorateur pour les modèles SQLA :

    - Ajoute une méthode ``as_list`` qui retourne l'objet sous forme de tableau (utilisé pour créer des shapefiles)
    - Ajoute une méthode de classe ``to_shape`` qui crée des shapefiles à partir des données passées en paramètre

    Fichier définition modèle

    .. code:: python

        from geonature.utils.env import DB
        from utils_flask_sqla_geo.serializers import shapeserializable


        @shapeserializable
        class MyModel(DB.Model):
            __tablename__ = 'bla'
            ...


    Fichier utilisation modèle

    .. code:: python

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

    - ``FionaShapeService.create_shapes_struct()`` : crée la structure de 3 shapefiles
    (point, ligne, polygone) à partir des colonens et de la geométrie passée
    en paramètre

    - ``FionaShapeService.create_feature()`` : ajoute un enregistrement
    aux shapefiles

    - ``FionaShapeService.save_and_zip_shapefiles()`` : sauvegarde et zip les
    shapefiles qui ont au moins un enregistrement

    .. code:: python

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
    .. code-block:: python

        def get_foo(pk):
            foo = Foo.query.get_or_404(pk)
            return jsonify(foo.as_dict(fields=...))

        def get_foo(pk):
            foo = Foo.query.get_or_404(pk)
            return FooSchema(only=...).jsonify(foo)

        def list_foo():
            q = Foo.query.filter(...)
            return jsonify([foo.as_dict(fields=...) for foo in q.all()])

        def list_foo():
            q = Foo.query.filter(...)
            return FooSchema(only=...).jsonify(q.all(), many=True)

- Pour les listes vides, ne pas renvoyer le code d’erreur 404 mais une liste vide !
    .. code-block:: python

        return jsonify([])

- Renvoyer une liste et sa longueur dans une structure de données non conventionnelle est strictement inutile, il est très simple d’accéder à la longueur de la liste en javascript via l’attribut ``length``.

- Traitement des erreurs : utiliser `les exceptions prévues à cet effet <https://werkzeug.palletsprojects.com/en/2.0.x/exceptions/>`_ :
    .. code-block:: python

        from werkzeug.exceptions import Fobridden, Badrequest, NotFound

        def restricted_action(pk):
            if not is_allowed():
                raise Forbidden

    
- Penser à utiliser ``get_or_404`` plutôt que de lancer une exception ``NotFound``
- Si l’utilisateur n’a pas le droit d’effectuer une action, utiliser l’exception ``Forbidden`` (code HTTP 403), et non l’exception ``Unauthorized`` (code HTTP 401), cette dernière étant réservée aux utilisateurs non authentifiés.
- Vérifier la validité des données fournies par l’utilisateur (``request.json`` ou ``request.args``) et lever une exception ``BadRequest`` si celles-ci ne sont pas valides (l’utilisateur ne doit pas être en mesure de déclencher une erreur 500 en fournissant une string plutôt qu’un int par exemple !).
    - Marshmallow peut servir à cela
        .. code:: python
        
            from marshmallow import Schema, fields, ValidationError
            def my_route():
                class RequestSchema(Schema):
                    value = fields.Float()
                try:
                    data = RequestSchema().load(request.json)
                except ValidationError as error:
                    raise BadRequest(error.messages)

    - Cela peut être fait avec *jsonschema* :
        .. code:: python
        
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
    .. code-block:: python

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

  .. code:: python

    class AcquisitionFramework(db.Model)
        datasets = db.relationships(Dataset, uselist=True, lazy='joined')
    
  Cependant, cette stratégie s’appliquera (sauf contre-ordre) dans tous les cas, même lorsque les DS ne sont pas nécessaires, alourdissant potentiellement certaines requêtes qui n’en ont pas usage.

- Le spécifier au moment où la requête est effectuée :
    .. code:: python

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
Il est possible d’utiliser un autre fichier de configuration en spécifiant
un autre chemin d’accès dans la variable d’environnement
``GEONATURE_CONFIG_FILE``.

Il est également possible de définir des paramètres de configuration par variable
d’environnement en préfixant le nom du paramètre par ``GEONATURE_`` (*e.g.* ``GEONATURE_SQLALCHEMY_DATABASE_URI``). Cette méthode permet cependant de passer uniquement des valeurs textuelles.

Les paramètres de configuration sont validés par un schéma Marshmallow (voir ``backend/geonature/utils/config_schema.py``).

Dans l'application flask, l'ensemble des paramètres de configuration sont
utilisables via le dictionnaire ``config`` :


.. code-block:: python

    from geonature.utils.config import config

    MY_PARAMETER = config['MY_PARAMETER']

Le dictionnaire ``config`` est également accessible via ``current_app.config``.

La :ref:`configuration des modules <module-config>` est accessible à la clé ``MODULE_CODE`` du dictionnaire de configuration. Elle est également accessible directement via la propriété ``config`` du blueprint du module :

.. code-block:: python

        from flask import current_app

        MY_MODULE_PARAMETER = current_app.config['MODULE_CODE']['MY_MODULE_PARAMETER']
        MY_MODULE_PARAMETER = blueprint.config['MY_MODULE_PARAMETER']


Authentification et autorisations
*********************************

Accéder à l’utilisateur courant
"""""""""""""""""""""""""""""""

L’utilisateur courant est stocké dans l’espace de nom ``g`` :

.. code-block:: pycon

    >>> from flask import g
    >>> print(g.current_user)
    <User ''admin'' id='3'>


Il s’agit d’une instance de ``pypnusershub.db.models.User``.
Si l’utilisateur n’est pas connecté, ``g.current_user`` vaudra ``None``.


Restreindre une route aux utilisateurs connectés
""""""""""""""""""""""""""""""""""""""""""""""""

Utiliser le décorateur ``@login_required`` :

.. code-block:: python

    from geonature.core.gn_permissions.decorators import login_required

    @login_required
    def my_protected_route():
        pass


Si l’utilisateur n’est pas authentifié, celui-ci est redirigé vers une page d’authentification, à moins que la requête contienne un header ``Accept: application/json`` (requête effectuée par le frontend) auquel cas une erreur 401 (Unauthorized) est levé.


Restreindre une route aux utilisateurs avec un certain scope
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

Utiliser le décorateur ``@check_cruved_scope`` :

.. py:decorator:: check_cruved_scope

   :param action: Type d'action effectuée par la route
                  (Create, Read, Update, Validate, Export, Delete)
   :type action: str["C", "R", "U", "V", "E", "D"]
   :param module_code: Code du module sur lequel on veut vérifier les permissions.
   :type module_code: str
   :param object_code: Code de l’objet sur lequel on veut vérifier les permissions.
    Si non fourni, on vérifie la portée sur l’objet ``ALL``.
   :type object_code: str, optional
   :param get_scope: si ``True``, ajoute le scope aux kwargs de la vue
   :type get_scope: bool, optional

Lorsque l’utilisateur n’est pas connecté, le comportement est le même que le décorateur ``@login_required``. Lorsque celui-ci est connecté, le décorateur va récupérer le scope de l’utilisateur pour l’action donnée dans le module donnée (et éventuellement l’objet donnée). Si ce scope est égal à 0, alors une erreur 403 (Forbidden) est levée.

.. warning::

    Le décorateur ne vérifie pas si un scope de 1 ou 2 est suffisant pour accéder
    aux ressources demandées. C’est à votre route d’implémenter cette vérification,
    en utilisant l’argument ``get_scope=True`` afin de récupérer la valeur exacte du
    scope.


Exemple d’utilisation :

.. code-block:: python

    from geonature.core.gn_permissions.decorators import check_cruved_scope

    @blueprint.route('/mysensibleview', methods=['GET'])
    @check_cruved_scope(
            'R',
            module_code="OCCTAX"
            get_scope=True,
    )
    def my_sensible_view(scope):
        if scope < 2:
            raise Forbidden


Récupération manuelle du scope
""""""""""""""""""""""""""""""

La fonction suivante permet de récupérer manuellement le scope pour un rôle, une action et un module donnés :

.. py:function:: get_scope(action_code, id_role, module_code, object_code)

   Retourne le scope de l’utilisateur donnée une action dans le module demandé.

   :param action_code: Code de l’action.
   :type action_code: str["C", "R", "U", "V", "E", "D"]
   :param id_role: Identifiant du role. Utilisation de ``g.current_user`` si non spécifié
                   (nécessite de se trouver dans une route authentifiée).
   :type id_role: int, optional
   :param module_code: Code du module. Si non spécifié, utilisation de ``g.current_module``
   :type module_code: str, optional
   :param object_code: Code de l’objet. Si non spécifié, utilisation de ``g.current_object``,
                       ``ALL`` à défaut.
   :type object_code: str, optional
   :return: Valeur du scope
   :rtype: int[0, 1, 2, 3]

Il est également possible de récupérer les scopes pour l’ensemble des actions possibles grâce à la fonction suivante :

.. py:function:: get_scopes_by_action(id_role, module_code, object_code)

   Retourne un dictionnaire avec pour clé les actions du CRUVED et pour valeur le scope associé
   pour un utilisateur et un module donné (et éventuellement un objet précis).

   :param int id_role: Identifiant du role. Utilisation de ``g.current_user`` si non spécifié
                       (nécessite de se trouver dans une route authentifiée).
   :param str module_code: Code du module. Si non spécifié, utilisation de ``g.current_module``
                           si définie, ``GEONATURE`` sinon.
   :param str object_code: Code de l’objet. ``ALL`` si non précisé.
   :return: Dictionnaire de scope pour chaque action du CRUVED.
   :rtype: dict[str, int]

Exemple d’usage :

.. code-block:: pycon

    >>> from geonature.core.gn_permissions.tools import get_scopes_by_action
    >>> get_scopes_by_action(id_role=3, module_code="METADATA")
    {'C': 3, 'R': 3, 'U': 3, 'V': 3, 'E': 3, 'D': 3}


Restreindre une route aux utilisateurs avec des permissions avancées
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

Utiliser le décorateur ``@permissions_required`` :

.. py:decorator:: permissions_required

   :param action: Type d'action effectuée par la route
                  (Create, Read, Update, Validate, Export, Delete)
   :type action: str["C", "R", "U", "V", "E", "D"]
   :param module_code: Code du module sur lequel on veut vérifier les permissions.
   :type module_code: str
   :param object_code: Code de l’objet sur lequel on veut vérifier les permissions.
    Si non fourni, on vérifie la portée sur l’objet ``ALL``.
   :type object_code: str, optional

Lorsque l’utilisateur n’est pas connecté, le comportement est le même que le décorateur ``@login_required``.
Lorsque celui-ci est connecté, le décorateur va récupérer l’ensemble des permissions pour l’action donnée dans le module donnée (et éventuellement l’objet donnée).
Si aucune permission n’est trouvée, alors une erreur 403 (Forbidden) est levée.

.. warning::

    Le décorateur ne vérifie pas si le jeu de permissions est suffisant pour accéder
    aux ressources demandées. C’est à votre route d’implémenter cette vérification,
    celle-ci recevant le jeu de permissions en argument.


Exemple d’utilisation :

.. code-block:: python

    from geonature.core.gn_permissions.decorators import permissions_required

    @blueprint.route('/mysensibleview', methods=['GET'])
    @permissions_required(
            'R',
            module_code="SYNTHESE"
    )
    def my_sensible_view(permissions):
        for perm in permissions:
            if perm.has_other_filters_than("SCOPE", "SENSITIVITY"):
                continue
            if perm.scope_value > 2 and not perm.sensitivity_filter:
                break
        else:
            raise Forbidden


Récupération manuelle des permissions avancées
""""""""""""""""""""""""""""""""""""""""""""""

Utiliser la fonction ``get_permissions`` :

.. py:function:: get_permissions(action_code, id_role, module_code, object_code)

   Retourne l’ensemble des permissions de l’utilisateur donnée pour l’action, le module et l’objet précisé.

   :param action_code: Code de l’action.
   :type action_code: str["C", "R", "U", "V", "E", "D"]
   :param id_role: Identifiant du role. Utilisation de ``g.current_user`` si non spécifié
                   (nécessite de se trouver dans une route authentifiée).
   :type id_role: int, optional
   :param module_code: Code du module. Si non spécifié, utilisation de ``g.current_module``
   :type module_code: str, optional
   :param object_code: Code de l’objet. Si non spécifié, utilisation de ``g.current_object``,
                       ``ALL`` à défaut.
   :type object_code: str, optional
   :return: Liste de permissions
   :rtype: list[Permission]


À propos de l’API « scope »
"""""""""""""""""""""""""""

Certains modules supportent des permissions avec plusieurs types de filtres (par exemple, filtre d’appartenance et filtre de sensibilité), ce qui amène à devoir définir plusieurs permissions pour une même action dans un module donnée (par exemple, droit de lecteur des données de mon organisme sans restriction de sensibilité + droit de lecteur des données non sensible sans restriction d’appartenance).

Cependant, cet usage est très peu répandu, la plupart des modules acceptant uniquement un filtre d’appartenance, voir aucun filtre.
Ainsi, l’API « scope » (décorateur ``@check_cruved_scope``, fonctions ``get_scope`` et ``get_scopes_by_action``) visent à simplifier l’usage des permissions dans ces modules en résumant les droits de l’utilisateur par un entier de 0 à 4 :

- 0 : aucune donnée (pas de permission)
- 1 : données m’appartenant
- 2 : données appartenant à mon organisme
- 3 : toutes les données (permission sans filtre d’appartenance)

L’utilisateur héritant des permissions des différents groupes auquel il appartient en plus de ses permissions personnelles, l’API « scope » s’occupe de calculer le scope maximal de l’utilisateur.


Rajouter un nouveau type de filtre
""""""""""""""""""""""""""""""""""

On suppose souhaiter l’ajout d’un nouveau type de filtre « foo ».

1. Rajouter une colonne dans la table ``t_permissions`` nommé ``foo_filter`` du type désiré (booléen, entier, …) avec éventuellement une contrainte de clé étrangère.
   Dans le cas où le filtre peut contenir une liste de valeur contrôlées par une Foreign Key, on préfèrera l’ajout d’une nouvelle table contenant une Foreign Key vers ``t_permissions.id_permission`` (par exemple, filtre géographique avec liste d’``id_area`` ou filtre taxonomique avec liste de ``cd_nom``).

2. Rajouter une colonne booléenne dans la table ``t_permissions_available`` nommé ``foo_filter``.

3. Faire évoluer les modèles Python ``Permission`` et ``PermissionAvailable`` pour refléter les changements du schéma de base de données.

4. Compléter ``Permission.filters_fields`` et ``PermissionAvailable.filters_fields`` (*e.g.* ``"FOO": foo_filter``).

5. Vérifier que la propriété ``Permission.filters`` fonctionne correctement avec le nouveau filtre : celui-ci doit être renvoyé uniquement s’il est défini.
   Le cas d’une relationship n’a encore jamais été traité.

6. Optionel : Rajouter une méthode statique ``Permission.__FOO_le__(a, b)``.
   Celle-ci reçoit en argument 2 filtres FOO et doit renvoyer ``True`` lorsque le filtre ``a`` est plus restrictif (au autant) que le filtre ``b``.
   Par exemple, dans le cas d’un filtre géographique, on renvera ``True`` si ``b`` vaut ``None`` (pas de restriction géographique) ou si la liste des zonages ``a`` est un sous-ensemble de la liste des zonages ``b``.
   Cette méthode permet d’optimiser le jeu de permission en supprimant les permissions redondantes.

7. Compléter la classe ``PermFilter`` qui permet l’affichage des permissions dans Flask-Admin (permissions des utilisateurs et des groupes).
   Attention, Flask-Admin utilise FontAwesome version **4**.

8. Faire évoluer Flask-Admin (classes ``PermissionAdmin`` et ``PermissionAvailableAdmin``) pour prendre en charge le nouveau type de filtre.

9. Implémenter le support de son nouveau filtre à l’endroit voulu (typiquement la synthèse).

10. Compléter ou faire évoluer la table ``t_permissions_available`` pour déclarer le nouveau filtre comme disponible pour son module.


Développement Frontend
----------------------

Serveur frontend en développement
*********************************

Lancer le serveur frontent en développement :

.. code-block:: bash

  cd ~/geonature/frontend/
  nvm use
  npm run start

Le frontend est alors accessible à l’adresse http://127.0.0.1:4200.

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
"presentation components", puisque que la logique de contrôle est déportée
au composant parent qui l'accueille
(https://blog.angular-university.io/angular-2-smart-components-vs-presentation-components-whats-the-difference-when-to-use-each-and-why/)

Un ensemble de composants permettant de simplifier l'affichage des cartographies
Leaflet sont disponibles. Notamment un composant "map-list" permettant de
connecter une carte avec une liste d'objets décrits en détail ci-dessous.

MapListComponent
""""""""""""""""

Le composant MapList fournit une carte pouvant être synchronisée
avec une liste. La liste, pouvant être spécifique à chaque module,
elle n'est pas intégrée dans le composant et est laissée à la
responsabilité du développeur. Le service ``MapListService`` offre
cependant des fonctions permettant facilement de synchroniser
les deux éléments.

Fonctionnalité et comportement offerts par le composant et le
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

  .. code:: javascript

        mapListService.getData('occtax/releve',
        [{'param': 'limit', 'value': 10'},
        {'param': 'cd_nom', 'value': 212'}])

  `Exemple dans le module OccTax  <https://github.com/PnX-SI/GeoNature/blob/master/contrib/occtax/frontend/app/occtax-map-list/occtax-map-list.component.ts#L99/>`_

  L'API doit nécessairement renvoyer un objet comportant un
  GeoJson. La structure du l'objet doit être la suivante :

  .. code:: json

    {
        "total": "nombre d'élément total",
        "total_filtered": "nombre d'élément filtré",
        "page": "numéro de page de la liste",
        "limit": "limite d'élément renvoyé",
        "items": "le GeoJson"
    }

  Pour une liste simple sans pagination, seule la propriété 'items'
  est obligatoire.

- Rafraîchir les données
        
  La fonction ``refreshData(apiEndPoint, method, params?)`` permet de raffrachir les données en fonction de filtres personnalisés.
  Les paramètres ``apiEndPoint`` et ``params`` sont les mêmes que pour la fonction ``getData``. Le paramètre ``method`` permet lui de chosir si on ajoute - ``append``- , ou si on initialise (ou remplace) -``set``- un filtre.

  Exemple 1 : Pour filtrer sur l'observateur 1, puis ajouter un filtre sur l'observateur 2 :

  .. code:: javascript

      mapListService.refreshData('occtax/relevé', 'append, [{'param': 'observers', 'value': 1'}])

  puis :

  .. code:: javascript
    
      refreshData('occtax/relevé', 'append, [{'param': 'observers', 'value': 2'}])

  Exemple 2: pour filtrer sur le cd_nom 212, supprimer ce filtre et filtrer sur  le cd_nom 214
    
  .. code:: javascript
    
      mapListService.refreshData('occtax/relevé', 'set, [{'param': 'cd_nom', 'value': 1'}])

  puis :
    
  .. code:: javascript
    
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
        
.. code:: html

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


Gestion des erreurs
*******************

GeoNature utilise un intercepteur générique afin d’afficher un toaster en cas d’erreur lors d’une requête HTTP.
Si vous souhaitez traiter l’erreur vous-même, et empêcher le toaster par défaut de s’afficher, vous pouvez définir un header ``not-to-handle`` à votre requête :

.. code:: typescript

    this._http.get('/url', { headers: { "not-to-handle": 'true' } })


Tests
*****

Pour toute PR ou nouvelle fonctionnalité il est demandé d'écrire des tests. Voir la section dédiée sur l’:ref:`écriture des tests frontend <tests-frontend>`.


.. _tests-backend:

.. include:: tests_backend.rst

.. _tests-frontend:

.. include:: tests_frontend.rst


Développer un module externe
----------------------------

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
composants Angular réutilisables pour l'affichage des cartes, des formulaires etc...

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

- Le backend doit être un paquet Python. Ce paquet peut définir différent *entry points* permettant de renseigner différentes informations sur votre module :

  - ``code`` : le MODULE_CODE de votre module (obligatoire)
  - ``picto`` : le pictogramme par défaut pour l’entrée dans le menu Geonature (facultatif)
  - ``blueprint`` : le blueprint qui sera servit par GeoNature (obligatoire)
  - ``config_schema`` : un schéma Marshmallow permettant de valider la configuration du module (obligatoire)
  - ``migrations`` : l’emplacement de vos migrations Alembic pour le schéma de base de données de votre module (facultatif)
  - ``alembic_branch`` : le nom de la branche Alembic (par défaut, la branche Alembic devra porter le nom du module code en minuscule)
  - ``tasks``: votre fichier de tâches asynchrones Celery (facultatif)

- Le frontend doit être placé dans un sous-dossier ``frontend``. Il comprendra les éléments suivants :

  - Les fichiers ``package.json`` et ``package-lock.json`` avec vos dépendances (facultatif si pas de dépendances)
  - Un dossier ``assets`` avec un sous-dossier du nom du module avec l'ensemble des médias (images, son)
  - Un dossier ``app`` qui comprendra le code de votre module, avec notamment le "module Angular racine" qui doit impérativement s'appeler ``gnModule.module.ts``

Pour l’installation du module, voir :ref:`install-gn-module`.


Bonnes pratiques Frontend
*************************

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

    <img src="assets/<MY_MODULE_CODE>/afb.png">

  Exemple pour le module de validation

  ::

    <img src="assets/<gn_module_validation>/afb.png">

.. include:: development/import-dev.rst


Documentation
-------------

La documentation se trouve dans le dossier ``docs``.
Elle est écrites en ReStructuredText et généré avec Sphinx.

Pour générer la documentation HTML :

- Se placer dans le dossier ``docs`` : ``cd docs``
- Créer un virtualenv : ``python3 -m venv venv``
- Activer le virtualenv : ``source venv/bin/activate``
- Installer les dépendances nécessaires à la génération de la documentation : ``pip install -r requirements.txt``
- Lancer la génération de la documentation : ``make html``

La documentation générée se trouve dans le dossier ``build/html/``.


Release
-------

Pour sortir une nouvelle version de GeoNature :

- Faites les éventuelles Releases des dépendances (UsersHub, TaxHub, UsersHub-authentification-module, Nomenclature-api-module, RefGeo, Utils-Flask-SQLAlchemy, Utils-Flask-SQLAlchemy-Geo)
- Assurez-vous que les sous-modules git de GeoNature pointent sur les bonnes versions des dépendances et que le ``requirements-dependencies.in`` a bien été mis à jour.
- Regénérer les fichiers ``requirements.txt`` et ``requirements-dev.txt`` avec les commandes suivantes dans la plus petite version de python supportée par GeoNature
  ::
    pip-compile requirements.in > requirements.txt
    pip-compile requirements-dev.in > requirements-dev.txt

- Mettez à jour la version de GeoNature et éventuellement des dépendances dans ``install/install_all/install_all.ini``
- Complétez le fichier ``docs/CHANGELOG.md`` (en comparant les branches https://github.com/PnX-SI/GeoNature/compare/develop) et dater la version à sortir
- Mettez à jour le fichier ``VERSION``
- Mergez la branche ``develop`` dans la branche ``master``
- Faites la release (https://github.com/PnX-SI/GeoNature/releases) en la taguant ``X.Y.Z`` (sans ``v`` devant) et en copiant le contenu du Changelog
- Dans la branche ``develop``, modifiez le fichier ``VERSION`` en ``X.Y.Z.dev0`` et pareil dans le fichier ``docs/CHANGELOG.md``
- Faites la release de `GeoNature-Docker-services <https://github.com/PnX-SI/GeoNature-Docker-services>`_ avec la nouvelle version de GeoNature, et éventuellement des modules (Voir un `exemple <https://github.com/PnX-SI/GeoNature-Docker-services/pull/19/files>`_)
