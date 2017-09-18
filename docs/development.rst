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


