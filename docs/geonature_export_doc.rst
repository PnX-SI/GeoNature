Note d'utilisation du module d'export de GeoNature
==================================================

Ce module permet d'exporter les données de geoNature. 
Il suffit de créer des vues personnalisées dans la base de données GeoNature et de déclarer ces vues dans la variable de configuration du module.
Le module crééra automatiquement des liens renvoyant les données des vues au format csv avec tous les champs de la vue. Pour des questions de performances sur de gros volumes de données, le fichier csv est compressé au format zip.
Seuls les utilisateurs de geonature déclarés dans la configuration du module peuvent voir les liens et exporter les données mises à disposition.


Pré-requis
----------

* Commencer par créer la ou les vues renvoyant les données que vous souhaitez mettre à disposition des utilisateurs. Le contenu et le schéma de la vue sont libres.
* Le ou les utilisateurs doivent disposer de droits d'accès à GeoNature ; A minima des droits de consultation : id_droit = 1 dans ``utilisateurs.cor role_droit_application``.


Configuration
-------------

Il est possible de configurer plusieurs modules d'export. A chaque module correspond une page dédiée, automatiquement générée par GeoNature. 
Le lien (bouton) vers chacune de ces pages est affiché sur la page d'accueil de GeoNature.

Pour qu'un utilisateur puisse voir le ou les liens vers les pages d'export qui le concerne, son ``id_role`` doit figurer dans le tableau ``authorized_roles_ids`` du module.

* Editer le fichier ``lib/sfGeonatureConfig.php`` et recherche la partie ``//configuration du module d'export``. Voir ``lib/sfGeonatureConfig.php.sample`` si besoin.
* La variable générale ``$appname_export`` défini le titre de la ou des pages du module d'export.
* La variable ``$exports_config`` contient toute la configuration de la ou des pages du module d'export.
* Le schéma ci-dessous résume le rôle de chacun des paramètres de configuration.
.. image :: images/export_module.jpg

