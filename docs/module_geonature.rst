Documentation de développement et d'installation d'un module GeoNature
======================================================================

Geonature a été conçu pour fonctionner en briques modulaires.
Chaque protocole, répondant à une question scientifique est ammené avoir son propre module GeoNature 
comportant son modèle de base de données, son API et son interface utilisateur.

Les modules développés s'appueyrons sur le coeur de GeoNature qui est constitué d'un ensemble de briques réutilisable.
En base de données, le coeur de GeoNature est constitué de l'ensemble des référentiels (utilisateurs, taxonomique, géographique)
et du schéma 'synthèse' regroupant l'ensemble données saisis dans les différents protocole.
L'api du coeur ( `voir doc <https://github.com/PnX-SI/GeoNature/blob/develop/docs/development.rst#api>`__) permet d'intéroger les schéma de la base de données "coeur" de GeoNature.
Du côté interface utilisateur, Geonature met à disposition un ensemble de composant Angular réutilisable (voir doc), pour l'affichage
des cartes, des formulaires etc...

Développer un module GeoNature
-------------------------------

Avant de développer un module, assurez-vous d'avoir GeoNature bien installé sur votre machine (`voir doc <https://github.com/PnX-SI/GeoNature/blob/develop/docs/development.rst#d%C3%A9veloppement-frontend>`__)
Afin de pouvoir connecter ce module au "coeur", Il est impératif de suivre une arborescence prédéfinie par l'équipe GeoNature.
Voici la structure minimale que le module doit comporter (voir le dossier `contrib <https://github.com/PnX-SI/GeoNature/blob/develop/docs/development.rst#api>`__ de GeoNature pour trouver un exemple):

- Le module se placera dans un dossier à part du dossier "GeoNature" et portera le suffixe "gn_module"

Exemple: *gn_module_validation*

- La racine du module comportera les fichiers suivants

  - ``install_app.sh``: script bash d'installation des librairies python ou npm necessaires au module
  - ``install_env.sh``: script bash d'installation des paquets Linux
  - `` requirements.txt``: liste des librairies python necessaires au module
  - `` manifest.toml``: fichier de description du module (nom, version du module, version de GeoNature compatible)
  - ``conf_gn_module.toml``: fichier de configuration de l'application (livé en version sample)
  - ``conf_schema_toml.py``: schéma 'marshmallow' (https://marshmallow.readthedocs.io/en/latest/) du fichier de configuration (permet de s'assurer la conformité des paramètres renseigné par l'utilisateur)
  - ``install_gn_module.py``: script python lançant l'installation de la BDD et les scripts ``install_app.sh`` et ``install_env.sh``. Ce fichier doit comprendre une fonction ``gnmodule_install_app(gn_db, gn_app)`` qui est utilisé pour installer le module (voir exemple)

- La racine du module comportera les dossiers suivants:

  - ``backend``: dossier comportant l'API du module utilisant un blueprint Flask
    
    - Le fichier ``blueprint.py`` comprend les routes du module (ou instancie les nouveaux blueprint du module)
    - Le fichier ``models.py`` comprend les modeles SQLAlchemy des table du module.
  
  - ``frontend``: le dossier ``app`` comprend les fichiers typescript du module, et  le dossier ``assets`` l'ensemble des médias (images, son).

    - Le dossier ``app`` doit lui comprendre le "module Angular racine", celui-ci doit impérativement s'appeler ``gnModule.ts`` 
    - A la racine du dossier frontend, on retrouve également un fichier package.json qui décrit l'ensemble des librairies JS necessaire au module.
      
  
  - ``data`` le dossier comprenant les scripts SQL d'installation du module




Bonnes pratiques:
-----------------

Frontend:
**********

- Pour l'ensemble des composants cartographique et des formulaires (taxonomie, nomenclature), il est conseillé d'utilisé les composants présents dans le module 'GN2CommonModule'.
  
  Importez ce module dans le module racine de la manière suivante:

  ``import { GN2CommonModule } from '@geonature_common/GN2Common.module';``

- Les librairies JS seront installées par npm dans un dossier 'node_modules' à la racine du dossier frontend du module. (Il n'est pas necessaire de réinstaller toutes les librairies déjà présentes dans GeoNature (Angular, Leaflet, ChartJS ...). Le package.json de GeoNature liste l'ensemble des librairies déjà installées et réutilisable dans le module. 

- Installer le linter ``tslint`` dans son éditeur de texte (TODO: définir un style à utiliser) 

Backend:
*********

- Respecter la norme PEP8


Installer un module
--------------------

Pour installer un module, rendez-vous dans le dossier ``backend`` de GeoNature.

Activer ensuite le virtualenv pour rendre disponible les commandes Geonature:

``source venv/bin/activate``

Lancez ensuite la commande ``geonature install_gn_module <mon_chemin_absolu_vers_le_module> <url_api>``

Le premier paramètre est l'emplacement absolue du module sur votre machine et le 2ème le chemin derière lequel on retrouvera les routes de l'API du module.

Ex 'validation' pour atteindre les routes du module de validation à l'adresse 'http://mon-geonature.fr/api/validation'

Cette commande executes les actions suivantes:

- Vérification de la conformité de la structure du module
- Intégration du blueprint du module dans l'API de GeoNature
- Vérification de la conformité des paramètres utilisateurs
- Génération du routing Angular pour le frontend
- Re-build du frontend pour une mise en production