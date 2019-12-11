Template de création d'un module GeoNature
==========================================

Ce template décrit la structure obligatoire d'un module GeoNature.
- Le backend est développé en Python grâce au framework Flask.
- Le frontend est développé grâce au framework Angular (voir la version actuelle du coeur)

GeoNature prévoit cependant l'intégration de module "externe" dont le frontend serait développé dans d'autres technologies. La gestion de l'intégration du module est à la charge du développeur.

Fichiers relatifs à l'installation
==================================

* ``manifest.tml`` (obligatoire) : Fichier contenant la description du module (nom, version de GeoNature supportée ...)
* ``install_env.sh`` : Installation des paquets Debian
* ``install_db.sh`` : Installation d'installation du schéma de BDD du module (non obligatoire, peut être piloté par le code)
* ``install_app.sh`` : Si besoin de manipulation sur le serveur (copie de fichier, desample ... Non obligatoire)
* ``install_gn_module.py`` : Fichier d'installation du module: 

  * commandes SQL
  * extra commandes python
  * ce fichier doit contenir la méthode suivante : ``gnmodule_install_app(gn_db, gn_app)``
* ``requirements.txt`` : Liste des paquets Python
* ``config/conf_schema_toml.py`` : Schéma Marshmallow de spécification des paramètres du module
* ``config/conf_gn_module.toml.sample`` : Fichier de configuration du module (à désampler)


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
