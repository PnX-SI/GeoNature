Fichiers relatifs à l'installation
==================================

* manifest.tml (Obligatoire): fichier contenant la description du module (nom, version de gn supportée, ...)
* install_env.sh: installation des paquets debian
* install_gn_module.py: installation du module :
    * commande sql
    * extra commandes python
    * ce fichier doit contenir la méthode suivante : gnmodule_install_app(gn_db, gn_app)
* requirements.txt: liste des paquets python
* packages.json: liste des paquets JS

* conf_schema_toml.py : Scpécification des paramètres du module
* conf_gn_module.toml.sample : Configuration du module

Fichiers relatifs au bon fonctionnement du module
=================================================


Backend
-------
Si votre module comporte des routes il doit comporter le fichier suivant : backend/blueprint.py
avec une variable blueprint qui contient toutes les routes

::

    blueprint = Blueprint('gn_module_validation', __name__)


Frontend
--------
