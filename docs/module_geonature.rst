Documentation de développement et d'installation d'un module GeoNature
======================================================================

Geonature a été conçu pour fonctionner en briques modulaires.
Chaque protocole, répondant à une question scientifique est ammené avoir son propre module GeoNature 
comportant son modèle de base de données, son API et son interface utilisateur.

Les modules développés s'appueyrons sur le coeur de GeoNature qui est constitué d'un ensemble de briques réutilisables.
En base de données, le coeur de GeoNature est constitué de l'ensemble des référentiels (utilisateurs, taxonomique, géographique)
et du schéma 'synthèse' regroupant l'ensemble données saisis dans les différents protocoles.
L'api du coeur ( `voir doc <https://github.com/PnX-SI/GeoNature/blob/develop/docs/development.rst#api>`__) permet d'intéroger les schémas de la base de données "coeur" de GeoNature.
Du côté interface utilisateur, Geonature met à disposition un ensemble de composant Angular réutilisable (`voir doc <https://github.com/PnX-SI/GeoNature/blob/develop/docs/development.rst#d%C3%A9veloppement-frontend>`__), pour l'affichage
des cartes, des formulaires etc...

Développer un module GeoNature
-------------------------------

Avant de développer un module, assurez-vous d'avoir GeoNature bien installé sur votre machine (`voir doc <https://github.com/PnX-SI/GeoNature/blob/develop/docs/development.rst>`__).

Afin de pouvoir connecter ce module au "coeur", Il est impératif de suivre une arborescence prédéfinie par l'équipe GeoNature.
Voici la structure minimale que le module doit comporter (voir le dossier `contrib <https://github.com/PnX-SI/GeoNature/blob/develop/docs/development.rst#api>`__ de GeoNature pour trouver un exemple):

- Le module se placera dans un dossier à part du dossier "GeoNature" et portera le suffixe "gn_module"

  Exemple: *gn_module_validation*

- La racine du module comportera les fichiers suivants: 

  - ``install_app.sh``: script bash d'installation des librairies python ou npm necessaires au module
  - ``install_env.sh``: script bash d'installation des paquets Linux
  - ``requirements.txt``: liste des librairies python necessaires au module
  - ``manifest.toml``: fichier de description du module (nom, version du module, version de GeoNature compatible)
  - ``conf_gn_module.toml``: fichier de configuration de l'application (livé en version sample)
  - ``conf_schema_toml.py``: schéma 'marshmallow' (https://marshmallow.readthedocs.io/en/latest/) du fichier de configuration (permet de s'assurer la conformité des paramètres renseignés par l'utilisateur)
  - ``install_gn_module.py`` : script python lançant les commandes relatives à l'installation du module (Bas de données, ...). Ce fichier doit comprendre une fonction ``gnmodule_install_app(gn_db, gn_app)`` qui est utilisée pour installer le module (`Voir exemple < https://github.com/PnX-SI/gn_module_validation/blob/master/install_gn_module.py>`__)
 

- La racine du module comportera les dossiers suivants:

  - ``backend``: dossier comportant l'API du module utilisant un blueprint Flask
    
    - Le fichier ``blueprint.py`` comprend les routes du module (ou instancie les nouveaux blueprints du module)
    - Le fichier ``models.py`` comprend les modèles SQLAlchemy des tables du module.
  
  - ``frontend``: le dossier ``app`` comprend les fichiers typescript du module, et  le dossier ``assets`` l'ensemble des médias (images, son).

    - Le dossier ``app`` doit lui comprendre le "module Angular racine", celui-ci doit impérativement s'appeler ``gnModule.ts`` 
  
  - ``data`` le dossier comprenant les scripts SQL d'installation du module




Bonnes pratiques:
-----------------

Frontend:
**********

- Pour l'ensemble des composants cartographiques et des formulaires (taxonomie, nomenclature), il est conseillé d'utiliser les composants présents dans le module 'GN2CommonModule'.
  
  Importez ce module dans le module racine de la manière suivante:

  ``import { GN2CommonModule } from '@geonature_common/GN2Common.module';``

- Installer le linter ``tslint`` dans son éditeur de texte (TODO: définir un style à utiliser) 

Backend:
*********

- Respecter la norme PEP8


Installer un module
--------------------

Pour installer un module, rendez vous dans le dossier ``backend`` de GeoNature.

Activer ensuite le virtualenv pour rendre disponible les commandes Geonature:

``source venv/bin/activate``

Lancez ensuite la commande ``geonature install_gn_module <mon_chemin_absolu_vers_le_module> <url_api>``

Le premier paramètre est l'emplacement absolu du module sur votre machine et le 2ème le chemin derière lequel on retrouvera les routes de l'API du module.

Ex 'validation' pour atteindre les routes du module de validation à l'adresse 'http://mon-geonature.fr/api/geonature/validation'

Cette commande execute les actions suivantes:

- Vérification de la conformité de la structure du module (présence des fichiers et dossiers obligatoires)
- Intégration du blueprint du module dans l'API de GeoNature
- Vérification de la conformité des paramètres utilisateurs
- Génération du routing Angular pour le frontend
- Re-build du frontend pour une mise en production
