Fichiers relatifs à l'installation
==================================

* ``manifest.tml`` (obligatoire) : Fichier contenant la description du module (nom, version de GeoNature supportée ...)
* ``install_env.sh`` : Installation des paquets Debian
* ``install_gn_module.py`` : Installation du module :

  * commandes SQL
  * extra commandes python
  * ce fichier doit contenir la méthode suivante : ``gnmodule_install_app(gn_db, gn_app)``
* ``requirements.txt`` : Liste des paquets Python
* ``config/conf_schema_toml.py`` : Schéma Marshmallow de spécification des paramètres du module
* ``config/conf_gn_module.toml.sample`` : Fichier de configuration du module


Fichiers relatifs au bon fonctionnement du module
=================================================

Backend
-------

Si votre module comporte des routes, il doit comporter le fichier suivant : ``backend/blueprint.py``
avec une variable ``blueprint`` qui contient toutes les routes

::

    blueprint = Blueprint('gn_module_validation', __name__)


Frontend
--------

Le dossier ``frontend`` comprend les élements suivants :

- le dossier ``app`` comprend le code typescript du module

     Il doit inclure le "module Angular racine", celui-ci doit impérativement s'appeler ``gnModule.module.ts`` 

- le dossier ``assets`` avec l'ensemble des médias (images, son).
    
- Un fichier ``package.json`` qui décrit l'ensemble des librairies JS nécessaires au module.
