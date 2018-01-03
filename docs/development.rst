===========
DEVELOPMENT
===========

General
=======

GeoNature has been developped by Gil Deluermoz since 2010 with PHP/Symfony/ExtJS.

In 2017, French national parks decided to rebuild GeoNature totally with a new version (V2) with Python/Flask/Angular 4. 

Maintainers : 

- Gil DELUERMOZ (PnEcrins) : Database / SQL / Installation / Update
- Amandine SAHL (PnCevennes) : Backend / Python Flask / API
- Theo LECHEMIA (PnEcrins) : Frontend / Angular 4
- Camille MONCHICOURT (PnEcrins) : Documentation / Project management


Architecture
============

- UsersHub and its Flask module (https://github.com/PnX-SI/UsersHub-authentification-module) are used to manage ``ref_users`` database schema
- TaxHub (https://github.com/PnX-SI/TaxHub) is used to manage ``ref_taxonomy`` database schema. We also use TaxHub API to get information about taxons, species...
- A Flask module has been created to manage nomenclatures datas and their API (https://github.com/PnX-SI/Nomenclature-api-module/)
- ``ref_geo`` is a geographical referentials to manage areas, DEM and spatial functions


Database
========

In GeoNature V2, the whole database is still done with PostgreSQL/PostGIS but it has also been rebuilt. 

It is based on MNHN SINP standard Occurrences de Taxons.
Details at https://github.com/PnX-SI/GeoNature/issues/183.

The database has also been translated into English and supports multilingual values. 

Database schemas prefixs : ``ref_`` for external referentials, ``gn_`` for GeoNature core schemas, ``pr_`` for protocols schemas.

- Noms de tables, commentaires et fonctions en anglais
- meta_create_date et meta_update_date dans les différentes tables
- deleted (boolean)
- pas de nom de table dans les noms de champs
- nom de schema eventuellement dans nom de table

Latest version of the database (2017-12-13) : 

.. image :: https://raw.githubusercontent.com/PnX-SI/GeoNature/frontend-contact/docs/2017-12-13-GN2-MCD.png

Sorry for the relations, it is too long to arrange...

Here is a simplified model of the database (2017-12-15) : 

.. image :: https://raw.githubusercontent.com/PnX-SI/GeoNature/frontend-contact/docs/2017-12-15-GN2-MCD-simplifie.jpg

Gestion des droits :
--------------------

La gestion des droits est centralisée dans UsersHub. Dans la version 1 de GeoNature, il était possible d'attribuer des droits selon 6 niveaux à des rôles (utilisateurs ou groupes). Pour la version 2 de GeoNature, des évolutions ont été réalisées pour étendre les possibilités d'attribution de droits et les rendre plus génériques. 

Pour cela un système d'étiquettes (``utilisateurs.t_tags``) a été mis en place. Il permet d'attribuer des étiquettes génériques à des rôles (utilisateurs ou groupes d'utilisateurs). 

- Dans GeoNature V2 cela permet d'attribuer des actions possibles à un rôle sur une portée dans une application ou un module (définis dans ``utilisateurs.cor_app_privileges``).
- 6 actions sont possibles dans GeoNature : Create / Read / Update / Validate / Export / Delete (aka CRUVED).
- 3 portées de ces actions sont possibles : Mes données / Les données de mon organisme / Toutes les données.
- Une vue permet de retourner toutes les actions, leur portée et leur module de GeoNature pour tous les rôles (``utilisateurs.v_usersaction_forall_gn_modules``)
- Des fonctions PostgreSQL ont aussi été intégrés pour faciliter la récupération de ces informations (``utilisateurs.cruved_for_user_in_module``, ``utilisateurs.can_user_do_in_module``, ...)
- Une hiérarchie a été rendue possible entre applications et entre organismes pour permettre un système d'héritage
- Si un utilisateur n'a aucune action possible sur un module, alors il ne lui sera pas affiché et il ne pourra pas y accéder
- Tous ces éléments sont en train d'être intégrés dans le schéma ``utilisateurs`` de UsersHub pour supprimer le schéma spécifique ``utilisateurs`` de GeoNature
- Il est aussi possible de ne pas utiliser UsersHub pour gérer les utilisateurs et de connecter GeoNature à un CAS (voir configuration). Actuellement ce paramétrage est fonctionnel en se connectant au CAS de l'INPN (MNHN)

Nomenclatures :
---------------

- Toutes les listes déroulantes sont gérées dans une table générique ``ref_nomenclatures.t_nomenclatures``
- Elles s'appuient sur les nomenclatures du SINP (http://standards-sinp.mnhn.fr/nomenclature/) qui peuvent être désactivées ou completées
- Chaque nomenclature est associée à un type et une vue par type de nomenclature a été ajoutée pour simplifier leur usage 
- Ces nomenclatures sont gérées dans un sous-module pour pouvoir les réutiliser (ainsi que leur mécanisme) dans d'autres applications : https://github.com/PnX-SI/Nomenclature-api-module/
- Chaque nomenclature peut être associée à un règne ou un group2inpn (``ref_nomenclatures.cor_taxref_nomenclature``) pour proposer des nomenclatures correspondants à un taxon
- Les valeurs par défaut sont définies dans chaque module
- Pour OCCTAX c'est dans ``pr_contact.defaults_nomenclatures_value``. Elle peut être définie pour chaque type de nomenclature ainsi que par organisme, règne et/ou group2inpn
- Si organisme = 0 alors la valeur par défaut s'applique à tous les organismes. Idem pour les règnes et group2inpn
- La fonction ``pr_contact.get_default_nomenclature_value`` permet de renvoyer l'id de la nomenclature par défaut
- Ces valeurs par défaut sont aussi utilisées pour certains champs qui sont cachés (statut_observation, floutage, statut_validation...) mais ne sont donc pas modifiables par l'utilisateur
- Il existe aussi une table pour définir des valeurs par défaut de nomenclature générales (``ref_nomenclatures.defaults_nomenclatures_value``)

Métadonnées :
-------------

- Elles sont gérées dans le schéma ``gn_meta`` basé sur le standard Métadonnées du SINP (http://standards-sinp.mnhn.fr/category/standards/metadonnees/)
- Elles permettent de gérer des jeux de données, des cadres d'acquisition, des acteurs (propriétaire, financeur, producteur...) et des protocoles

Données SIG :
-------------

- Le schéma ``ref_geo`` permet de gérer les données SIG (zonages, communes, MNT...) de manière centralisée, potentiellement partagé avec d'autres BDD
- Il contient une table des zonages, des types de zonages, des communes, des grilles (mailles) et du MNT vectorisé (https://github.com/PnX-SI/GeoNature/issues/235)
- La fonction ``ref_geo.fct_get_area_intersection`` permet de renvoyer les zonages intersectés par une observation en fournissant sa géométrie
- La fonction ``ref_geo.fct_get_altitude_intersection`` permet de renvoyer l'altitude min et max d'une observation en fournissant sa géométrie
- L'intersection d'une observation avec les zonages sont stockés au niveau de la synthèse (``gn_synthese.cor_area_synthese``) et pas de la donnée source pour alléger et simplifier leur gestion


Modularité
==========

Chaque module doit avoir son propre schéma dans la BDD, avec ses propres fichiers SQL de création comme le module Contact (OCCTAX) : https://github.com/PnX-SI/GeoNature/tree/frontend-contact/data/modules/contact

Côté backend chaque module a aussi son modèle et ses routes : https://github.com/PnX-SI/GeoNature/tree/frontend-contact/backend/src/modules/pr_contact

Idem côté FRONT, où chaque module a sa config et ses composants : https://github.com/PnX-SI/GeoNature/tree/frontend-contact/backend/src/modules/pr_contact

Mais en pouvant utiliser des composants du CORE comment expliqué ci-dessous.


Configuration
=============

Pour configurer GeoNature, actuellement il y a : 

- Une configuration pour l'installation : https://github.com/PnX-SI/GeoNature/blob/frontend-contact/config/settings.ini.sample
- Une configuration globale du backend : https://github.com/PnX-SI/GeoNature/blob/frontend-contact/backend/config.py.sample
- Une configuration globale du frontend : https://github.com/PnX-SI/GeoNature/blob/frontend-contact/frontend/src/conf/app.config.sample.ts
- Une configuration frontend par module : https://github.com/PnX-SI/GeoNature/blob/frontend-contact/frontend/src/modules/contact/contact.config.ts
- Une table ``gn_meta.t_parameters`` pour des paramètres gérés dans la BDD


API
=============

GeoNature utilise : 

- l'API de TaxHub (recherche taxon, règne et groupe d'un taxon...)
- l'API du sous-module Nomenclatures (typologies et listes déroulantes)
- l'API du sous-module d'authentification de UsersHub (login/logout, récupération du CRUVED d'un utilisateur)
- l'API de GeoNature (get, post, update des données des différents modules, métadonnées, intersections géographiques, exports...)

Pour avoir des infos et la documentation de ces API, on utilise PostMan. Documentation API à venir


Frontend
========

Modules
-------

Bonnes pratiques:

Chaque module de GeoNature doit être un module Angular indépendant https://angular.io/guide/ngmodule. 

Ce module peut s'appuyer sur une série de composants génériques intégrés dans le module GN2CommonModule et réutilisables dans n'importe quel module. 

**Les composants génériques**

1. Les composant cartographiques

- **MapComponent**
        Ce composant affiche une carte Leaflet ainsi qu'un outil de recherche de lieux dits et d'adresses (basé sur l'API OpenStreetMap). 

        **Selector**: ``pnx-map``

        **Inputs**:

        :``baseMaps``:
                tableau de fonds de carte (Voir `example  <https://github.com/PnX-SI/GeoNature/blob/e0ab36a6c30835afbf17179d30ad640b9873983a/frontend/src/conf/app.config.sample.ts#L7>`_)

                *Type*: ``Array<any>``
        :``center``:
                coordonnées du centrage de la carte: [long,lat]

                *Type*: ``Array<number>``
        :``zoom``:
                niveaux de zoom à l'initialisation de la carte

                *Type*: ``number``

        Dans ce composant les *inputs* sont facultatifs. Si ceux ci ne sont pas renseignés, ce sont les paramètres du `fichier de configuration de l'application  <https://github.com/PnX-SI/GeoNature/blob/e0ab36a6c30835afbf17179d30ad640b9873983a/frontend/src/conf/app.config.sample.ts>`_ qui seront appliqués. Si les *inputs* sont renseignés, ceux-ci surchagent les paramètres par défault. 

        Exemple d'utilisation: ``<pnx-map [center]="center" [zoom]="zoom"> </pnx-map>`` Ici le niveau de zoom et le centrage sont modifiés, mais les fonds de carte restent ceux renseignés par défault.

- **MarkerComponent**
        Ce composant permet d'afficher un marker au clic sur la carte ainsi qu'un controleur permettant d'afficher/désafficher le marker. NB: Doit être utiliser à l'interieur d'une balise ``pnx-map``
        
        **Selector**: ``pnx-marker``
        
        **Ouputs**:
        
        :``markerChanged``:
                Output permettant de récupérer les coordonnées du marker quand celui-ci est déplacé. Retourne un geojson des coordonnées du marker

- **LeafletDrawComponent**
        Ce composant permet d'activer le `plugin leaflet-draw <https://github.com/Leaflet/Leaflet.draw>`_
        
        **Selector**: ``pnx-leaflet-draw``
        
        **Inputs**:
        
        :``options``:
                Objet permettant de paramettrer le plugin et les différentes formes dessinables (point, ligne, cercle etc...)
                
                Par défault le fichier ``leaflet-draw.option.ts` est passé au composant. Il est possible de surcharger l'objet pour activer/désactiver certaines formes. Voir `exemple <https://github.com/PnX-SI/GeoNature/blob/d3b0e1ba4f88494fd492bb5f24c3782756162124/frontend/src/modules/contact/contact-form/contact-form.component.ts#L22>`_ 
                
        **Output**
        
        :``layerDrawed``:
                Output renvoyant le geojson de l'objet dessiné.

- **GPSComponent**
        Affiche une modale permettant de renseigner les coordonnées d'une observation, puis affiche un marker à la position renseignée. Ce composant hérite du composant MarkerComponent: il dispose donc des mêmes inputs et outputs.
        
        **Selector**: ``pnx-gps``
        
- **GeojsonComponent**
        Affiche sur la carte les geojson passé en *input*
        
        **Selector**: ``pnx-geojson``
        
        **Inputs**:
        
        :``geojson``:
                Objet geojson à afficher sur la carte
                
                Type: ``GeoJSON``
                
        :``onEachFeature``:
                Fonction permettant d'effectuer un traitement sur chaque layer du geojson (afficher une popup, définir un style etc...)
                
                Type: ``any``: fonction définit par la librairie leaflet: ``onEachFeature(feature, layer)``. `Voir doc leaflet <http://leafletjs.com/examples/geojson/>`_
        :``style``: 
                Fonction ou object définissant le style des layers du geojson
                
                Type: ``any`` `voir doc leaflet <http://leafletjs.com/examples/geojson/>`_
