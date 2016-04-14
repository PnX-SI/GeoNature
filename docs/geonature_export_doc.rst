Note d'utilisation du module d'export de GeoNature
==================================================

Ce module permet d'exporter les données de geoNature. 

Il suffit de créer des vues personnalisées dans la base de données GeoNature et de déclarer ces vues dans la variable de configuration du module.
Le module crééra automatiquement un lien par vue renvoyant les données de la vue **avec tous les champs de la vue**. 

Pour des questions de performances sur de gros volumes de données, le fichier est compressé au format zip.

Seuls les utilisateurs de geonature déclarés dans la configuration du module peuvent voir les liens et exporter les données mises à disposition.
Vous devez connaitre l'id_role des utilisateurs auxquels vous souhaitez attribuer des droits d'export (voir la table utilisateurs.t_roles)


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
    * Seuls les formats csv et xls sont possibles. Si un autre format est spécifié, le format csv sera retourné par défaut.
    * Le séparateur csv est le ';'. Le séparateur xls est la tabulation '\\t'.
    * Attention, la syntaxe PHP de cette variable ``$exports_config`` ne doit pas comporter d'erreur sous peine de plantage. 
    Il s'agit d'un tableau multidimentionnel PHP, veillez à respecter la syntaxe des tableaux [] et objets "key"=>"value", de les séparer par une virgule et de bien terminer la variable par un point virgule.
.. image :: images/export_module.jpg

