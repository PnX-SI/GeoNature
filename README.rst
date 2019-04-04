===================
Dashboard GeoNature
===================

Module GeoNature permettant d'afficher des graphiques et cartes de synthèse des données présentes dans une instance GeoNature (nombre de données par année, nombre de taxons observés par année, observations par maille, par commune...).

Il ne s'agit pas d'un outil d'analyse statistique des données et ne vise donc pas à remplacer des outils comme R ou QGIS.

Installation
============

* Installez GeoNature (https://github.com/PnX-SI/GeoNature)
* Téléchargez la dernière version stable du module (``wget https://github.com/PnX-SI/gn_module_dashboard/archive/X.Y.Z.zip``) dans ``/home/myuser/``
* Dézippez la dans ``/home/myuser/`` (``unzip X.Y.Z.zip``)
* Créez et adaptez le fichier ``config/settings.ini`` à partir de ``config/settings.ini.sample`` (``cp config/settings.ini.sample config/settings.ini``)
* Data ?
* Placez-vous dans le répertoire ``backend`` de GeoNature et lancez les commandes ``source venv/bin/activate`` puis ``geonature install_gn_module <mon_chemin_absolu_vers_le_module> <url_relative_du_module>`` (exemple ``geonature install_gn_module /home/`whoami`/gn_module_dashboard-X.Y.Z /gn_dashboard``)
* Complétez la configuration du module (``config/conf_gn_module.toml`` à partir des paramètres présents dans ``config/conf_gn_module.toml.example`` dont vous pouvez surcoucher les valeurs par défaut. Puis relancez la mise à jour de la configuration (depuis le répertoire ``geonature/backend`` et une fois dans le venv (``source venv/bin/activate``) : ``geonature update_module_configuration gn_dashboard``)
* Vous pouvez sortir du venv en lançant la commande ``deactivate``

Licence
=======

* OpenSource - GPL-3.0
* Copyleft 2019 - Parc National des Écrins

.. image:: http://geonature.fr/img/logo-pne.jpg
    :target: http://www.ecrins-parcnational.fr
