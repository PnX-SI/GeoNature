======================
Suivi Flore Territoire
======================

Module GeoNature permettant de proposer un tableau de bord contenant plusieurs graphiques et cartes basés sur les données présentes dans la synthèse de GeoNature. Développé par Elsa Guilley, stagiaire au Parc national des Ecrins en 2019. 

.. image :: https://user-images.githubusercontent.com/38694819/57705368-0ab5bb00-7664-11e9-9b40-fe5c43d4d29e.png

**Fonctionnalités** :

* Nombre d'observations et de taxons par année
* Nombre d'observations et de taxons par zonage (communes, mailles...)
* Réparatition des observations par rang taxonomique
* Nombre d'observations par cadre d'acquisition par année
* Taxons recontactés, non recontactés et nouveaux par année
* Filtres divers sur chaque élément

**Présentation** :

* Rapport de stage de Elsa Guilley : http://geonature.fr/documents/xxxxxxxxxxxxxxxxxx
* Présentation de soutenance de stage de Elsa Guilley : http://geonature.fr/documents/xxxxxxxxxxxxxxxxxxxxx

Installation
============

* Installez GeoNature (https://github.com/PnX-SI/GeoNature)
* Téléchargez la dernière version stable du module (``wget https://github.com/PnX-SI/gn_module_dashboard/archive/X.Y.Z.zip``) dans ``/home/myuser/``
* Dézippez la dans ``/home/myuser/`` (``unzip X.Y.Z.zip``)
* Placez-vous dans le répertoire ``backend`` de GeoNature et lancez les commandes ``source venv/bin/activate`` puis ``geonature install_gn_module <mon_chemin_absolu_vers_le_module> <url_relative_du_module>`` (exemple ``geonature install_gn_module /home/`whoami`/gn_module_dashboard-X.Y.Z /dashboard``)
* Complétez la configuration du module (``config/conf_gn_module.toml`` à partir des paramètres présents dans ``config/conf_gn_module.toml.example`` dont vous pouvez surcoucher les valeurs par défaut. Puis relancez la mise à jour de la configuration (depuis le répertoire ``geonature/backend`` et une fois dans le venv (``source venv/bin/activate``) : ``geonature update_module_configuration suivi_flore_territoire``)
* Vous pouvez sortir du venv en lançant la commande ``deactivate``

Configuration
=============

Un certain nombre de paramètres permettent de customiser le module en modifiant le fichier ``conf/conf_gn_module.toml`` (vous pouvez vous inspirer du fichier ``conf_gn_module.toml.example`` qui liste l'ensemble des paramètres dispobinibles et leurs valeurs par défaut) :

- Paramétrage des zonages affichables sur la carte "Synthese par entité géographique" : ``AREA_TYPE``. Passer un tableau de ``type_code`` (table ``ref_geo.bib_areas_types``).
- Paramétrage du nombre de classes sur la cartographie "Synthese par entité géographique". Voir ``BORNE_TAXON`` et ``BORNE_OBS`` pour changer respectivement l'affichage en mode 'nombre d'observation et 'nombre de taxon'.

Licence
=======

* OpenSource - GPL-3.0
* Copyleft 2019 - Parc National des Écrins

.. image:: http://geonature.fr/img/logo-pne.jpg
    :target: http://www.ecrins-parcnational.fr
