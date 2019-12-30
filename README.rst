======================
Dashboard
======================

Module GeoNature permettant de proposer un tableau de bord contenant plusieurs graphiques et cartes basés sur les données présentes dans la synthèse de GeoNature. Développé par Elsa Guilley, stagiaire au Parc national des Ecrins en 2019. 

Démo vidéo : https://geonature.fr/docs/img/2019-09-GN-dashboard-0.1.0.gif

.. image :: https://user-images.githubusercontent.com/38694819/57705368-0ab5bb00-7664-11e9-9b40-fe5c43d4d29e.png

**Fonctionnalités** :

* Nombre d'observations et de taxons par année
* Nombre d'observations et de taxons par zonage (communes, mailles...)
* Répartition des observations par rang taxonomique
* Nombre d'observations par cadre d'acquisition par année
* Taxons recontactés, non recontactés et nouveaux par année
* Filtres divers sur chaque élément

**Présentation** :

* Rapport de stage de Elsa Guilley : https://geonature.fr/documents/2019-09-rapport-stage-Elsa-Guilley-Dashboard-Validation.pdf
* Présentation de soutenance de stage de Elsa Guilley : http://geonature.fr/documents/xxxxxxxxxxxxxxxxxxxxx

Installation
============

* Installez GeoNature (https://github.com/PnX-SI/GeoNature)
* Téléchargez la dernière version stable du module (``wget https://github.com/PnX-SI/gn_module_dashboard/archive/X.Y.Z.zip`` ou en cliquant sur le bouton GitHub "Clone or download" de cette page) dans ``/home/myuser/``
* Dézippez la dans ``/home/myuser/`` (``unzip X.Y.Z.zip``)
* Renommer le répertoire ``mv gn_module_dashboard-X.Y.Z gn_module_dashboard``
* Créer un lien symbolique vers le répertoire ``node_modules`` de GeoNature ``ln -s /home/`whoami`/geonature/frontend/node_modules /home/`whoami`/gn_module_dashboard/frontend``
* Installez les librairies frontend necessaire au module 

::

    cd /home/`whoami`/geonature/frontend 
    npm install angular2-chartjs@0.2.0 chart.js@2.6.0 chartjs-plugin-labels@1.1.0 chartjs-plugin-piechart-outlabels@0.1.4 ng2-charts@1.6.0 ng2-nouislider@1.8.2 nouislider@13.1.5


* Placez-vous dans le répertoire ``backend`` de GeoNature et lancez les commandes ``source venv/bin/activate`` puis ``geonature install_gn_module <mon_chemin_absolu_vers_le_module> <url_relative_du_module>`` pour installer le module (exemple ``geonature install_gn_module /home/`whoami`/gn_module_dashboard /dashboard``)
* Complétez la configuration du module dans le fichier ``config/conf_gn_module.toml`` à partir des paramètres présents dans ``config/conf_gn_module.toml.example``, dont vous pouvez surcoucher les valeurs par défaut. Relancez la mise à jour de la configuration depuis le répertoire ``geonature/backend`` avec les commandes ``source venv/bin/activate`` puis ``geonature update_module_configuration DASHBOARD``
* Vous pouvez sortir du venv en lançant la commande ``deactivate``

Configuration
=============

Un certain nombre de paramètres permettent de customiser le module en modifiant le fichier ``conf/conf_gn_module.toml`` (vous pouvez vous inspirer du fichier ``conf_gn_module.toml.example`` qui liste l'ensemble des paramètres disponibles et leurs valeurs par défaut) :

- Paramétrage du niveau de simplification des zonages sur la carte "Synthèse par entité géographique" : ``SIMPLIFY_LEVEL``. Passer un nombre entier : plus cet entier est grand et plus la simplification est importante. Ce paramètre est nécessaire pour alléger le temps d'affichage des zonages.
- Paramétrage des zonages affichables sur la carte "Synthèse par entité géographique" : ``AREA_TYPE``. Passer un tableau de ``type_code`` (table ``ref_geo.bib_areas_types``).
- Paramétrage du nombre de classes sur la carte "Synthèse par entité géographique" : ``BORNE_OBS`` (mode 'nombre d'observations') et ``BORNE_TAXON`` (mode 'nombre de taxons'). Passer un tableau contenant les limites inférieures des bornes que l'on souhaite implémenter. 

Vues matérialisées
==================

Dans un soucis de performance, des vues matérialisées ont été mises en place. Elles sont renseignées lors de l'installation du module. Il faut rafraichir régulièrement ces vues matérialisées avec la fonction ``REFRESH MATERIALIZED VIEW`` pour prendre en compte les nouvelles données intégrées dans la Synthèse.

Une fonction permet de mettre à jour toutes les vues matérialisées du schéma ``gn_dashboard``.

* Pour lancer manuellement cette fonction, ouvrez une console SQL et exécutez la requête suivante :

  ::

        SELECT gn_dashboard.refresh_materialized_view_data();

* Pour automatiser l'éxecution de cette fonction (toutes les heures dans cet exemple), ajoutez la dans le crontab de l'utilisateur ``postgres`` :

  ::

        sudo su postgres
        crontab -e


Ajouter la ligne suivante en prenant soin de mettre à jour les paramètres de connexion à la base de GeoNature-atlas :

::

    0 * * * * psql -d geonatureatlas -c "SELECT gn_dashboard.refresh_materialized_view_data();"

Pour enregistrer et sortir : ``Ctrl + O``, ENTER puis ``Ctrl + X``


Mise à jour du module
=====================

- Téléchargez la nouvelle version du module

  ```
  wget https://github.com/PnX-SI/gn_module_dashboard/archive/X.Y.Z.zip
  unzip X.Y.Z.zip
  rm X.Y.Z.zip
  ```

- Renommez l'ancien et le nouveau répertoire

  ```
  mv /home/`whoami`/gn_module_dashboard /home/`whoami`/gn_module_dashboard_old
  mv /home/`whoami`/gn_module_dashboard-X.Y.Z /home/`whoami`/gn_module_dashboard
  ```

- Rappatriez les fichiers de configuration

  ````
  cp /home/`whoami`/gn_module_dashboard_old/config/conf_gn_module.toml /home/`whoami`/gn_module_dashboard/config/conf_gn_module.toml
  cp /home/`whoami`/gn_module_dashboard_old/frontend/app/module.config.ts /home/`whoami`/gn_module_dashboard/frontend/app/module.config.ts```
  ````

Licence
=======

* OpenSource - GPL-3.0
* Copyleft 2019 - Parc National des Écrins

.. image:: http://geonature.fr/img/logo-pne.jpg
    :target: http://www.ecrins-parcnational.fr
