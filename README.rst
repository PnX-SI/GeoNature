GeoNature
=========

Application de synthèse des observations faune et flore.

GeoNature est une application permettant de regrouper l'ensemble des données provenant des **protocoles Faune et Flore**, de saisir les protocoles de **contact occasionnel faune** et **Flore station** et de consulter l'ensemble de ces données dans une application de **synthèse**.

Elle regroupe toutes les données des différents protocoles FAUNE et FLORE en les limitant au niveau QUI QUOI QUAND OU.

Il est possible d'ajouter d'autres protocoles dans GeoNature. Pour cela suivez les indications ici : `<https://github.com/PnEcrins/GeoNature/issues/54>`_.

Technologies
------------

- Langages : PHP, HTML, JS, CSS
- BDD : PostgreSQL, PostGIS
- Serveur : Debian ou Ubuntu
- Framework PHP : Symfony
- Framework JS : ExtJS
- Framework carto : GeoExtJS, MapFish et Openlayers
- Serveur carto : MapServer
- Fonds rasters : Geoportail, OpenStreetMap, Google Maps, WMS

Présentation
------------

**Principe général** : Un protocole = Un outil = Une BDD + Une BDD et une application de SYNTHESE regroupant les données des différents protocoles sur la base des champs communs à tous les protocoles (QUI a vu QUOI, OU et QUAND).

.. image :: docs/images/schema-general.jpg

Les données des différents protocoles sont saisies avec des outils différents. Il peut s'agir d'un simple tableur ou couche SIG pour les besoins simples concernant peu d'utilisateurs comme d'une base Access plus ou moins élaborée ou encore d'une base de données PostGIS accompagnée d'une interface web lorsque les utilisateurs sont nombreux. Certaines données sont même saisies directement sur le terrain grâce aux applications et aux outils nomades. Les données sont stockées par protocole, dans des schémas différents. Chaque schéma possède un modèle de données correspondant strictement au protocole. Il est structuré pour répondre aux besoins spécifiques de ce protocole. On respecte bien ici le principe UN BESOIN = UN PROTOCOLE = UN MODELE DE DONNEES = UN OUTIL.

Grâce aux REFERENTIELS tels que le taxref pour la taxonomie ou encore les référentiels géographiques de l'IGN, les informations communes à tous les protocoles peuvent être regroupées dans un schéma de SYNTHESE. En résumé qui a vu quoi, quand, où et comment (le protocole) ? Ce schéma de synthèse est automatiquement alimenté par des déclencheurs (triggers) au sein de la base de données ou périodiquement grâce à un outil ETL (Extract Transform and Load) tel que Talend Open Studio pour les données saisies avec d'autres outils tels que des bases de données fichiers (Access) ou des tableurs.

Le schéma de chacun des protocoles répond donc au besoin du protocole et le schéma de synthèse qui regroupe toutes les données produites répond lui aux besoins d'agglomération et d'échange des données ainsi qu'au besoin de porter à connaissance. Une vue spécifique est mise en place sur la base de données de synthèse pour chaque organisme partenaire (SINP, LPO, INPN...). Elles leur permettent d'extraire les données en temps réel en totale autonomie. 

Pour en savoir plus :  `<docs/pdf/protocoles-locaux-echanges-nationaux.pdf>`_

.. image :: docs/images/capture-application.png

Gestion des utilisateurs
------------------------

La gestion des utilisateurs est déportée dans l'application UsersHub (https://github.com/PnEcrins/UsersHub).
Celle-ci permet de centraliser les utilisateurs et observateurs, de les ajouter dans un groupe et d'hériter directement de droits dans l'ensemble des applications (GeoNature, Faune, Flore, Geotrek, Police...).

A chaque ajout ou modification dans l'application UsersHub sa base de données est mise à jour ainsi que tous les schémas ``utilisateurs`` des applications qui sont connectées à UsersHub. 

Ne jamais modifier une donnée dans le schéma ``utilisateurs`` de GeoNature. Celui-ci est synchronisé automatiquement par les modifications apportées depuis l'application UsersHub dans le schéma ``utilisateurs`` de la BDD de UsersHub.

Attention aussi à ne jamais supprimer un utilisateur auquel serait associé des observations dans GeoNature. Vous pouvez lui supprimer ses identifiants de connexion et ses droits dans UsersHub mais surtout pas le supprimer car sinon le lien avec ses observations serait cassé.

Gestion de la taxonomie
-----------------------

GeoNature et les protocoles qui y sont intégrés s'appuient sur différentes listes de taxons. Celles-ci sont basées sur le référentiel national TAXREF du MNHN. 

Pour chaque observation d'une espèce il est en effet crucial de garder un identifiant de référence du taxon pour pouvoir échanger et agglomérer les données avec d'autres structures. 

Cependant, il est souvent nécessaire de limiter la liste des taxons à certaines espèces ou groupes. Voir d'ajouter des informations spécifiques sur chaque taxons (patrimonialité, statuts...). 

Pour cela GeoNature s'appuie depuis sa version 1.4.0 sur l'application TaxHub et sa structure de BDD qui est dupliquée dans le schéma ``taxonomie``. Détails sur `<https://github.com/PnX-SI/TaxHub>`_

Installation
------------

Consulter la documentation :  `<http://geonature.rtfd.org>`_

License
-------

* OpenSource - BSD
* Copyright (c) 2014 - Parc National des Écrins - Parc national des Cévennes


.. image:: http://pnecrins.github.io/GeoNature/img/logo-pne.jpg
    :target: http://www.ecrins-parcnational.fr

.. image:: http://pnecrins.github.io/GeoNature/img/logo-pnc.jpg
    :target: http://www.cevennes-parcnational.fr
