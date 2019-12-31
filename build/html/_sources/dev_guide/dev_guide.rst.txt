====================================================
Aide mémoire pour l'utilisation du core de geonature
====================================================


Démarrage du serveur de dev backend
===================================

    ::

    (venv)...$ geonature dev_back


Base de données
===============

Session sqlalchemy
------------------

- ``geonature.utils.env.DB``


Fournit l'instance de connexion SQLAlchemy


Python ::

    from geonature.utils.env import DB

    result = DB.session.query(MyModel).get(1)


Serialisation des modèles
=========================


- ``geonature.utils.utilssqlalchemy.serializable``

Décorateur pour les modèles SQLA : Ajoute une méthode as_dict qui retourne un
dictionnaire des données de l'objet sérialisable json


Fichier définition modèle ::

    from geonature.utils.env import DB
    from utils_flask_sqla.serializers import serializable

    @serializable
    class MyModel(DB.Model):
        __tablename__ = 'bla'
        ...


fichier utilisation modele ::

    instance = DB.session.query(MyModel).get(1)
    result = instance.as_dict()



- ``geonature.utils.utilssqlalchemy.geoserializable``


Décorateur pour les modèles SQLA : Ajoute une méthode as_geofeature qui
retourne un dictionnaire serialisable sous forme de Feature geojson.


Fichier définition modèle ::

    from geonature.utils.env import DB
    from geonature.utils.utilssqlalchemy import geoserializable

    @geoserializable
    class MyModel(DB.Model):
        __tablename__ = 'bla'
        ...


fichier utilisation modele ::

    instance = DB.session.query(MyModel).get(1)
    result = instance.as_geofeature()

- ``geonature.utils.utilsgeometry.shapeserializable``

Décorateur pour les modèles SQLA:

- Ajoute une méthode ``as_list`` qui retourne l'objet sous forme de tableau
  (utilisé pour créer des shapefiles)
- Ajoute une méthode de classe ``to_shape`` qui crée des shapefiles à partir
  des données passées en paramètre

Fichier définition modèle ::

    from geonature.utils.env import DB
    from geonature.utils.utilsgeometry import shapeserializable

    @shapeserializable
    class MyModel(DB.Model):
        __tablename__ = 'bla'
        ...


fichier utilisation modele ::


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

- FionaShapeService.create_shapes_struct(): crée la structure de 3 shapefiles
  (point, ligne, polygone) à partir des colonens et de la geom passé en
  paramètre
- FionaShapeService.create_feature(): ajoute un enregistrement aux shapefiles
- FionaShapeService.save_and_zip_shapefiles(): sauvegarde et zip les shapefiles
  qui ont au moin un enregistrement

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


Décorateur pour les routes : les données renvoyées par la route sont
automatiquement serialisées en json (ou geojson selon la structure des
données).

S'insère entre le décorateur de route flask et la signature de fonction


fichier routes ::

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



Export des données
==================

TODO


Authentification avec pypnusershub
==================================


Vérification des droits des utilisateurs
----------------------------------------


- ``pypnusershub.routes.check_auth``


Décorateur pour les routes : vérifie les droits de l'utilisateur et le
redirige en cas de niveau insuffisant ou d'informations de session erronés.
(deprecated) Privilegier `check_auth_cruved`

params :

* level <int>: niveau de droits requis pour accéder à la vue
* get_role <bool:False>: si True, ajoute l'id utilisateur aux kwargs de la vue
* redirect_on_expiration <str:None> : identifiant de vue  sur laquelle
  rediriger l'utilisateur en cas d'expiration de sa session
* redirect_on_invalid_token <str:None> : identifiant de vue sur laquelle
  rediriger l'utilisateur en cas d'informations de session invalides

::

    from flask import Blueprint
    from pypnusershub.routes import check_auth
    from utils_flask_sqla.response import json_resp

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

Décorateur pour les routes : Vérifie les droits de l'utilisateur à effectuer
une action sur la donnée et le redirige en cas de niveau insuffisant ou
d'informations de session erronées

params :

* action <str:['C','R','U','V','E','D']> type d'action effectuée par la route
  (Create, Read, Update, Validate, Export, Delete)
* get_role <bool:False>: si True, ajoute l'id utilisateur aux kwargs de la vue
* redirect_on_expiration <str:None> : identifiant de vue  sur laquelle
  rediriger l'utilisateur en cas d'expiration de sa session
* redirect_on_invalid_token <str:None> : identifiant de vue sur laquelle
  rediriger l'utilisateur en cas d'informations de session invalides

::

    from flask import Blueprint
    from pypnusershub.routes import check_auth_cruved
    from utils_flask_sqla.response import json_resp

    blueprint = Blueprint(__name__)

    @blueprint.route('/mysensibleview', methods=['GET'])
    @check_auth_cruved(
        'R',
        True,
        redirect_on_expiration='my_reconnexion_handler',
        redirect_on_invalid_token='my_affreux_pirate_handler'
        )
    @json_resp
    def my_sensible_view(id_role):
        return {'result': 'id_role = {}'.format(id_role)}



- ``pypnusershub.routes.db.tools.cruved_for_user_in_app``


Fonction qui retourne le cruved d'un utilisateur pour une application donnée.
Si aucun cruved n'est définit pour l'application, c'est celui de l'application
mère qui est retourné.
Le cruved de l'application enfant surcharge toujours celui de l'application
mère.

params:
* id_role <integer:None>
* id_application: id du module surlequel on veut avoir le cruved
* id_application_parent: id l'application parent du module

Valeur retourné:
<dict> {'C': '1', 'R':'2', 'U': '1', 'V':'2', 'E':'3', 'D': '3'}

::

    from pypnusershub.db.tools import cruved_for_user_in_app

    cruved = cruved_for_user_in_app(id_role=5, id_application=18, id_application_parent=14)
