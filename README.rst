=========
GeoNature 
=========

.. image:: https://travis-ci.org/PnX-SI/GeoNature.svg?branch=develop
    :target: https://travis-ci.org/PnX-SI/GeoNature

GeoNature V2 est une refonte complète de la BDD et changement de technologies : 

* Python
* Flask
* Leaflet
* Angular 4
* Bootstrap

Documentation sur https://geonature.readthedocs.io.

**Application de saisie, de gestion, de synthèse et de diffusion d'observations faune et flore.**

GeoNature est une application permettant de regrouper l'ensemble des données provenant des **protocoles Faune et Flore**, de saisir dans différents protocoles et de consulter l'ensemble de ces données dans une application de **synthèse**.

Celle-ci regroupe toutes les données des différents protocoles FAUNE et FLORE en les limitant au niveau QUI QUOI QUAND OU, en s'appuyant sur les référentiels, les standards et les nomenclatures du SINP.

Il est possible d'ajouter d'autres protocoles dans GeoNature sous forme de modules.

Une instance de démo est disponible sur http://demo.geonature.fr/geonature (admin / admin).

.. image :: http://geonature.fr/docs/img/user-manual/05-occtax-create-taxon-2.jpg

Présentation de GeoNature sur http://geonature.fr et dans http://geonature.fr/documents

=======================
Modules et projets liés
=======================

* UsersHub (gestion des utilisateurs et de leurs droits) : https://github.com/PnX-SI/UsersHub
* Sous-module d'authentification UsersHub : https://github.com/PnX-SI/UsersHub-authentification-module
* TaxHub (gestion des taxons) : https://github.com/PnX-SI/TaxHub
* Nomenclature API (gestion des nomenclatures) : https://github.com/PnX-SI/Nomenclature-api-module
* GeoNature-atlas (portail web de diffusion des observations) : https://github.com/PnX-SI/GeoNature-atlas
* GeoNature-mobile (saisie mobile dans les protocoles de GeoNature v1) : https://github.com/PnEcrins/GeoNature-mobile
* Occtax-mobile (saisie mobile dans le module Occtax) : https://github.com/PnX-SI/gn_mobile_occtax
* GeoNature module Interopérabilité/export : https://github.com/PnX-SI/gn_module_export
* GeoNature module Import : https://github.com/PnX-SI/gn_module_import
* GeoNature module Dashboard : https://github.com/PnX-SI/gn_module_dashboard
* GeoNature module Validation : https://github.com/PnX-SI/gn_module_validation
* GeoNature module Suivi des habitats : https://github.com/PnX-SI/gn_module_suivi_habitat_territoire
* GeoNature module Suivi des stations d'habitat : https://github.com/PnX-SI/gn_module_suivi_habitat_station
* GeoNature module Suivi de la flore territoire : https://github.com/PnX-SI/gn_module_suivi_flore_territoire
* Suivi-Flore-Territoire-mobile : https://github.com/PnX-SI/gn_mobile_sft
* GeoNature module Suivi chiroptères : https://github.com/PnCevennes/gn_module_suivi_chiro
* Protocoles de suivi (frontend) : https://github.com/PnCevennes/projet_suivis_frontend
* GeoNature-citizen (portail de collecte citoyenne) : https://github.com/PnX-SI/GeoNature-citizen

========================
Gestion des utilisateurs
========================

La gestion des utilisateurs est déportée dans l'application UsersHub (https://github.com/PnX-SI/UsersHub).
Celle-ci permet de centraliser les utilisateurs et observateurs, de les ajouter dans un groupe et d'hériter directement de droits dans l'ensemble des applications (GeoNature, Faune, Flore, Geotrek, Police...).

A chaque ajout ou modification dans l'application UsersHub sa base de données est mise à jour ainsi que tous les schémas ``utilisateurs`` des applications qui sont connectées à UsersHub. 

Ne jamais modifier une donnée dans le schéma ``utilisateurs`` de GeoNature. Celui-ci est synchronisé automatiquement par les modifications apportées depuis l'application UsersHub dans le schéma ``utilisateurs`` de la BDD de UsersHub.

Attention aussi à ne jamais supprimer un utilisateur auquel serait associé des observations dans GeoNature. Vous pouvez lui supprimer ses identifiants de connexion et ses droits dans UsersHub mais surtout pas le supprimer car sinon le lien avec ses observations serait cassé.

=======================
Gestion de la taxonomie
=======================

GeoNature et les protocoles qui y sont intégrés s'appuient sur différentes listes de taxons. Celles-ci sont basées sur le référentiel national TAXREF du MNHN. 

Pour chaque observation d'une espèce il est en effet crucial de garder un identifiant de référence du taxon pour pouvoir échanger et agglomérer les données avec d'autres structures. 

Cependant, il est souvent nécessaire de limiter la liste des taxons à certaines espèces ou groupes. Voir d'ajouter des informations spécifiques sur chaque taxons (patrimonialité, statuts...). 

Pour cela GeoNature s'appuie sur l'application TaxHub et sa structure de BDD qui est dupliquée dans le schéma ``taxonomie``. Détails sur `<https://github.com/PnX-SI/TaxHub>`_

=======
Licence
=======

* OpenSource - GPL-3.0
* Copyleft 2014-2019 - Parc National des Écrins - Parc national des Cévennes


.. image:: http://geonature.fr/img/logo-pne.jpg
    :target: http://www.ecrins-parcnational.fr

.. image:: http://geonature.fr/img/logo-pnc.jpg
    :target: http://www.cevennes-parcnational.fr
