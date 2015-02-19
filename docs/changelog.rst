=========
CHANGELOG
=========

next
----

## Changements
 - passage en faune flore = grosse évolution
 

1.2.0 (2015-01-29)
------------------

Version stabilisée de GeoNature - Faune uniquement (Synthèse Faune + Saisie ContactFauneVertebre, ContactFauneInvertebre et Mortalité).

## Changements
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

## Changements
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

## Changements
 - Documentation de l'installation d'un serveur Debian wheezy pas à pas
 - Documentation de la mise en place de la base de données
 - Documentation de la mise en place de l'application et de son paramétrage
 - Script d'insertion d'un jeu de données test
 - Passage à PostGIS v2
 - Mise en paramètre de la notion de lot, protocole et source

## Prochaines évolutions
 - Script d'import de taxref v7
 - Utilisation préférentielle de la taxonomie de taxref plutôt que les tables de hiérarchie taxonomique


0.1.0 (2014-12-01)
------------------

* Création du projet et de la documentation
