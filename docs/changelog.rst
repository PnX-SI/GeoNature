=========
CHANGELOG
=========

TODO
----

 - Revoir le où de la synthese pour mettre des choses plus génériques
 - optimiser la création des taxons flore
 - rendre le schéma taxonomie totalement compatible avec taxhub
 - tests complémentaires et bug fix
 
 
1.4.0.dev0
------------------

**Note de version**

* La gestion de la taxonomie a été mis en conformité avec le schéma ``taxonomie`` de la base de données de TaxHub (https://github.com/PnX-SI/TaxHub). Ainsi le schéma ``taxonomie`` intégré à GeoNature 1.3.0 doit être globalement revu. L'ensemble des modifications peuvent être réalisées en éxecutant la partie correspondante dans le fichier ``data/migration_xxxxxxx.sql`` (https://github.com/PnEcrins/GeoNature/blob/master/data/xxxxxxx.sql).
* Le fonctionnement avec GoogleMaps (au lieu de OpenLayers 2) ne fonctionne plus, car leur API a évolué depuis mais n'a pas été mise à jour dans Police.
* De nouveaux paramètres ont été ajoutés à l'application. Après avoir récupéré le fichier de conf ``xxxxx`` de votre version 1.3.0, ajoutez les manuellement (``xxxx``, ``xxx``, ``xxx`` et ``xxx``).
* Suivez la procédure classique de mise à jour : https://github.com/PnEcrins/GeoNature/blob/master/docs/installation.rst#mise-à-jour-de-lapplication

**Changements**

 - Chargement en base des zones à statuts juridiques pour toute la France métropolitaine à partir des sources de l'INPN
 - Mise en place partiel de la compatibilité de la base avec le schema de taxhub
 - Modification du nom du host hébergeant la base de données. databases --> geonatdbhost. A changer ou ajouter dans le /etc/hosts si vous avez déjà installer GeoNature


1.3.0 (2015-02-11)
------------------

Pré-Version de GeoNature - Faune ET Flore. Le fonctionnement de l'ensemble n'a pas été totalement testé, des bugs sont identifiés, d'autres subsistent certainement.

**Changements**

 - Grosse évolution de la base de données
 - ajout de deux applications de saisie flore (flore station et bryophytes)
 - intégration de la flore en sythese
 - ajouter un id_lot, id_organisme, id_protocole dans toutes les tables pour que ces id soit ajoutés vers la synthese en trigger depuis les tables et pas avec des valeurs en dur dans les triggers. Ceci permet d'utiliser les paramètres de conf de GeoNature
 - ajout d'une fonction à la base pour correction du dysfonctionnement du wms avec mapserver
 - suppression du champ id_taxon en synthese et lien direct de la synthese avecle taxref. ceci permet d'ajouter des données en synthese directement dans la base sans ajouter tous les taxons manquants dans la table bib_taxons
 - suppression de la notion de coeur dans les critère de recherche en synthese
 - Ajout d'un filtre faune flore fonge dans la synthese
 - Ajout de l'embranchement et du regne dans les exports
 - permettre à des partenaires de saisir mais d'exporter uniquement leurs données perso
 - ajout du déterminateur dans les formulaires invertébrés et contactfaune + en synthese
 - ajout du référentiel géographique de toutes les communes de France métropolitaine
 - ajout des zones à statuts juridiques de la région sud-est (national à venir)
 - bugs fix
 
**BUG à identifier**

Installation :
 - corriger l'insertion de données flore station qui ne fonctionne pas
Bryophythes :
 - Corriger la recherche avancée par date sans années
Synthèse :
 - la construction de l'arbre pour choisir plusieurs taxons ne tient pas compte des filtres
 - le fonctionnement des unités geographiques n'a pas été testé (initialement conçu uniquement pour la faune)


1.2.0 (2015-02-11)
------------------

Version stabilisée de GeoNature - Faune uniquement (Synthèse Faune + Saisie ContactFauneVertebre, ContactFauneInvertebre et Mortalité).

**Changements**

 - Modification du nom de l'application de FF-synthese en GeoNature
 - Changement du nom des utilisateurs PostgreSQL
 - Changement du nom de la base de données
 - Mise à jour de la documentation (http://geonature.readthedocs.org/)
 - Automatisation de l'installation de la BDD
 - Renommer les tables pour plus de généricité
 - Supprimer les tables inutiles ou trop spécifiques
 - Gestion des utilisateurs externalisée et centralisée avec UsersHub (https://github.com/PnEcrins/UsersHub)
 - Correction de bugs
 - Préparation de l'intégration de la Flore pour passer de GeoNature Faune à GeoNature Faune-Flore


1.1.0 (2014-12-11)
------------------

**Changements**

 - Modification du schéma de la base pour être compatible taxref v7
 - Import automatisé de taxref v7
 - Suppression des tables de hiérarchie taxonomique (famille, ordre, ...) afin de simplifier l'utilisation de la taxonomie.
 - Création de la notion de groupe (para-taxonomique) à la place de l'utilisation des classes.
 - Ajout de données pour pouvoir tester de façon complète l'application (invertébrés, vertébrés)
 - Ajout de données exemples
 - Bugs fix


1.0.0 (2014-12-10)
------------------

Version fonctionnelle des applications : visualisation de la synthèse faune, saisie d'une donnée de contact (vertébrés, invertébrés, mortalité)

**Changements**

 - Documentation de l'installation d'un serveur Debian wheezy pas à pas
 - Documentation de la mise en place de la base de données
 - Documentation de la mise en place de l'application et de son paramétrage
 - Script d'insertion d'un jeu de données test
 - Passage à PostGIS v2
 - Mise en paramètre de la notion de lot, protocole et source

**Prochaines évolutions**

 - Script d'import de taxref v7
 - Utilisation préférentielle de la taxonomie de taxref plutôt que les tables de hiérarchie taxonomique


0.1.0 (2014-12-01)
------------------

* Création du projet et de la documentation
