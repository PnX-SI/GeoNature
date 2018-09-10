GeoNature
=========

**Attention** : GeoNature a été totalement refondu entre aout 2017 et septembre 2018 pour sortir une nouvelle version en Python (Flask) et Angular. 

Cette branche conserve le code de la version 1 de GeoNature.

Documentation de la V1 de GeoNature : https://geonature.readthedocs.io/fr/1.9.1/

**Application de saisie et de synthèse des observations faune et flore.**

GeoNature est une application permettant de regrouper l'ensemble des données provenant des **protocoles Faune et Flore**, de saisir les protocoles de **contact occasionnel faune** et **Flore station** et de consulter l'ensemble de ces données dans une application de **synthèse**.

Elle regroupe toutes les données des différents protocoles FAUNE et FLORE en les limitant au niveau QUI QUOI QUAND OU.

Il est possible d'ajouter d'autres protocoles dans GeoNature. Pour cela suivez les indications ici : `<https://github.com/PnX-SI/GeoNature/issues/54>`_.

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

- GeoNature comprend une application WEB de synthèse des observations 
- GeoNature comprend aussi les formulaires de saisie des protocoles ContactFaune (vertébrés, invertébrés et mortalité), Flore station et Bryophytes. Ces protocoles peuvent être activés ou désactivés. Une discussion est aussi en cours pour y intégrer un Contact Flore sur le modèle de la Faune : https://github.com/PnX-SI/GeoNature/issues/59. Les protocoles de contact intègrent une orientation de la saisie en fonction de 3 critères combinés (localisation x date de la dernière observation x patrimonialité)
- GeoNature-mobile permet de saisir 4 de ces protocoles sur appareil mobile Android. https://github.com/PnEcrins/GeoNature-mobile, https://github.com/PnEcrins/GeoNature-mobile-sync, https://github.com/PnEcrins/GeoNature-mobile-webapi
- Chaque protocole dispose de son propre schéma dans la base de données de GeoNature. Il est possible d'y ajouter d'autres schémas pour ses propres protocoles ou l'intégration des données des partenaires.
- Il est aussi possible d'alimenter la synthèse de GeoNature depuis des protocoles qui ont leur propre base de données (SICEN, Suivi_chiro...) par des triggers, des jobs Talend ou depuis version 1.6.0 par une API REST.
- Des webservices permettent de diffuser les données de la synthèse à des partenaires
- Enfin un atlas public basé sur les données de la synthèse de GeoNature (https://github.com/PnEcrins/GeoNature-atlas). 

.. image :: docs/images/schema-geonature-environnement.jpg


**Principe général** : Un protocole = Un outil = Une BDD + Une BDD et une application de SYNTHESE regroupant les données des différents protocoles sur la base des champs communs à tous les protocoles (QUI a vu QUOI, OU et QUAND).

.. image :: docs/images/schema-general.jpg

Les données des différents protocoles sont saisies avec des outils différents. Il peut s'agir d'un simple tableur ou couche SIG pour les besoins simples concernant peu d'utilisateurs comme d'une base Access plus ou moins élaborée ou encore d'une base de données PostGIS accompagnée d'une interface web lorsque les utilisateurs sont nombreux. Certaines données sont même saisies directement sur le terrain grâce aux applications et aux outils nomades. Les données sont stockées par protocole, dans des schémas différents. Chaque schéma possède un modèle de données correspondant strictement au protocole. Il est structuré pour répondre aux besoins spécifiques de ce protocole. On respecte bien ici le principe UN BESOIN = UN PROTOCOLE = UN MODELE DE DONNEES = UN OUTIL.

Grâce aux REFERENTIELS tels que le taxref pour la taxonomie ou encore les référentiels géographiques de l'IGN, les informations communes à tous les protocoles peuvent être regroupées dans un schéma de SYNTHESE. En résumé qui a vu quoi, quand, où et comment (le protocole) ? Ce schéma de synthèse est automatiquement alimenté par des déclencheurs (triggers) au sein de la base de données ou périodiquement grâce à un outil ETL (Extract Transform and Load) tel que Talend Open Studio pour les données saisies avec d'autres outils tels que des bases de données fichiers (Access) ou des tableurs.

Le schéma de chacun des protocoles répond donc au besoin du protocole et le schéma de synthèse qui regroupe toutes les données produites répond lui aux besoins d'agglomération et d'échange des données ainsi qu'au besoin de porter à connaissance. Une vue spécifique est mise en place sur la base de données de synthèse pour chaque organisme partenaire (SINP, LPO, INPN...). Elles leur permettent d'extraire les données en temps réel en totale autonomie. 

Pour en savoir plus :  `<docs/pdf/protocoles-locaux-echanges-nationaux.pdf>`_

.. image :: docs/images/capture-application.png

Les protocoles intégrés
-----------------------

Certains protocoles et leurs formulaires de saisie sont disponibles dans GeoNature. Ils peuvent être désactivés pour ceux qui ne souhaitent pas les utiliser. 

- **Contact Faune (vertébrés, invertébrés, mortalité)**

Il s'agit d'un protocole de contact occasionnel de la faune.

Il faut commencer par localiser l'observation sur la carte ou avec ses coordonnées GPS. L'altitude et la commune sont alors automatiquement calculés.

Il faut ensuite renseigner le(s) observateur(s) et la date de l'observation.

Il faut ensuite renseigner le taxon, le critère d'observation (vu, entendu, nid...) qui peuvent varier selon le groupe, le dénombrement, éventuellement un commentaire et un déterminateur. 

Il est possible d'ajouter plusieurs taxons (``contactfaune.t_releves_cf``) sur une même localisation (``contactfaune.t_fiches_cf``).

La particularité de ce protocole est que le territoire a été découpé en plusieurs unités géographiques (153 polygones au Parc national des Ecrins dans ``layers.l_unites_geo``) pour orienter la saisie en fonction de 3 critères combinés (localisation x date de la dernière observation x patrimonialité). Cela permet une meilleure répartition spatiale et taxonomique des relevés. Pour chaque unité géographique (UG), la dernière observation de chaque taxon est calculée automatiquement. Chaque taxon est ainsi affiché comme prioritaire (pas noté dans l'UG depuis 1 an si patrimonial ou 3 ans si non patrimonial), facultatif (déjà noté récemment dans l'UG) ou nouveau (jamais vu dans l'UG) accompagné de la date de dernière observation et du nombre d'observations du taxon dans l'UG. 

.. image :: docs/images/protocole-contact-faune.jpg 

Ce protocole peut aussi être saisi sur tablette avec https://github.com/PnEcrins/GeoNature-mobile qui tire notamment profit du GPS.

- **Flore station**

L'esprit de ce protocole est d'observer une espèce ou une liste d'espèces dans le milieu physique qu'elle(s) occupe(nt). Il peut accessoirement servir d'inventaire de type « atlas », c'est à dire avec une information réduite sur les conditions de milieu (Etape 3 de la fiche de relevé), ou avec une liste partielle des espèces présentes dans l'espace du relevé (Etape 4 de la fiche de relevé).

Objectif : Relever l'ensemble des éléments d'une station floristique : données de l'observation (ou métadonnées) (étapes 1 et 2), données stationnelles (étapes 1 et 3), espèces présentes dans les limites du relevé, avec leurs abondances relatives notée pour chaque strate occupée (étape 4).

Ce protocole est à réaliser de manière partielle par tous les agents, et de manière complète au moins par les agents du groupe opérationnel flore.

- **Bryophytes**

Il s'agit d'une copie de Flore station limitée aux mousses et sans relevé statifié.

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

Consulter la documentation de GeoNature V1 :  `<https://geonature.readthedocs.io/fr/1.9.1/>`_

License
-------

* OpenSource - BSD
* Copyright (c) 2014-2018 - Parc National des Écrins - Parc national des Cévennes


.. image:: http://geonature.fr/img/logo-pne.jpg
    :target: http://www.ecrins-parcnational.fr

.. image:: http://geonature.fr/img/logo-pnc.jpg
    :target: http://www.cevennes-parcnational.fr
