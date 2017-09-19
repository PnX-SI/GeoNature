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
- TaxHub (https://github.com/PnX-SI/TaxHub) is used to manage ref_taxonomy database schema. We also use TaxHub API to get information about taxons, species...
- A Flask module has been created to manage nomenclatures datas and their API (https://github.com/PnX-SI/Nomenclature-api-module/)
- ``ref_geo`` is a geographical referentials to manage areas, DEM and spatial functions

Database
========

In GeoNature V2, the whole database is still done with PostgreSQL/PostGIS but it has also been rebuilt. 

It is based on MNHN SINPN standard Occurrences de Taxons.
Details at https://github.com/PnX-SI/GeoNature/issues/183.

The database has also been translated into English and supports multilingual values. 

Database schemas prefixs : ``ref_`` for external referentials, ``gn_`` for GeoNature core schemas, ``pr_`` for protocols schemas.

- Noms de tables, commentaires et fonctions en anglais
- meta_create_date et meta_update_date dans les différentes tables
- deleted (boolean)
- pas de nom de table dans les noms de champs
- nom de schema eventuellement dans nom de table

Latest version of the database : 

.. image :: https://user-images.githubusercontent.com/4418840/29674737-56042e8a-88f3-11e7-934f-2042696fb2c5.png
        
Frontend
========
Documentation pour developpeur
------------------------------
Bonnes pratiques:

Chaque module de Géonature doit être un module Angular indépendant https://angular.io/guide/ngmodule. Ce module peut s'appuyer sur une série de composants génériques intégrés dans le module GN2CommonModule. 

**Les composants génériques**

1. Les composant cartographiques

- **MapComponent**
        Ce composant affiche une carte leaflet ainsi qu'un outil de recherche de lieux dits et d'adresse (basé sur l'API OpenStreetMap). 

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
        Ce composant permet d'afficher un marker au clic sur la carte ainsi qu'un légende permettant d'afficher/désafficher le marker. NB: Doit être utiliser à l'interieur d'une balise ``pnx-map``
        
        **Selector**: ``pnx-marker``
        
        **Inputs**:
        
        :``onclick``:
                Fonction executée au clic sur le marker
                
                *Type*: ``any``: fonction prenant en paramètre un `event leaflet <http://leafletjs.com/reference-1.2.0.html#event>`_

        **Ouputs**:
        
        :``markerChanged``:
                Output permettant de récupérer les coordonnées du marker quand celui-ci est déplacé. Retourne un geojson des coordonnées du marker.
 
 

