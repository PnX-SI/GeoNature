
CHANGELOG
=========

2.0.0alpha.dev0 (unreleased)
----------------------------

Refonte complète de GeoNature en Python (Flask) + Angular4, Leaflet, Bootstrap, Material Design

>> A mettre en forme sous forme de Changelog >> Camille

**Récapitulatif 07/09/2017**

Ces derniers mois ont été marqués par :

- un travail de refonte du MCD de GeoNature V2
- une importante réflexion et des tests sur les technologies et la généricité/modularité
- la mise en place des briques de développements et de l'interface ACCUEIL + SAISIE CONTACT par notre stagiaire Quang

Puis la semaine du 21 au 25 aout a eu lieu le workshop GeoNature V2 à Briançon avec Amandine, Quang, Theo, Gil, Olivier Gavotto et moi-même.
Ils ont commencé par 2 jours de finalisation du MCD, définition des méthodes de travail et de développements puis de 3 jours de développements (intenses) :

- Finalisation BDD Contact Faune-Flore (sur la base du standard SINP Occurrences de taxons, de CAMPanule et des nomenclatures SINP). MCD : https://github.com/PnX-SI/GeoNature/issues/183
- Mise en place multilingue au niveau de l'interface et des listes de valeurs (https://github.com/PnX-SI/GeoNature/issues/173)
- Mise en place d'un mécanisme générique de centralisation des listes de valeurs (nomenclatures) pour ne pas créer des tables pour chaque liste : https://github.com/PnX-SI/Nomenclature-api-module. Les valeurs de chaque nomenclature s'adaptent en fonction du regne/group2inpn.
- Mise en place de l'API qui renvoie les infos à l'application à partir de la BDD
- Mise en place de composants génériques pour pouvoir les utiliser dans plusieurs modules sans avoir à les redévelopper ni les dupliquer (composant CARTE, composant RECHERCHE TAXON, composant OBSERVATEURS, composant NOMENCLATURES...)
- Conception d'un référentiel géographique partageable entre applications
- Installation automatique de la BDD (https://github.com/PnX-SI/GeoNature/blob/frontend-contact/install_db.sh) et début de documentation (https://github.com/PnX-SI/GeoNature/blob/frontend-contact/docs/installation.rst)
- Des prises de tête comme https://github.com/PnX-SI/GeoNature/issues/205
- Mise en place d'un mécanisme de calcul automatique de la sensibilité d'un espèce directement dans la BDD (sur la base des règles nationales et régionales du SINP + locales éventuellement)
- Intégration calcul automatique ID permanent SINP (https://github.com/PnX-SI/GeoNature/issues/209)

Suite à cela les développements continuent avec Gil, Amandine, Quang (fin de stage le 22 septembre) et Théo (désormais à 100% sur le projet) :

- Mise en place d'un référentiel géographique avec un schéma dédié, partageable avec d'autres applications, une table des communes, une table générique des zonages, une table pour le MNT et des fonctions pour intersecter point/ligne/polygones avec les communes et le MNT (https://github.com/PnX-SI/GeoNature/issues/228)
- Intégration automatique des communes et MNT 250m France métropole lors de l'installation automatique
- Développements formulaire saisie CONTACT et interactions avec la BDD (https://github.com/PnX-SI/GeoNature/issues/203)

**ORGANISATION et SUIVI des DÉVELOPPEMENTS**

- Les taches sont suivies sur le dépôt du projet sous forme de tickets : https://github.com/PnX-SI/GeoNature/issues
- Les taches sont associées à des sprints mensuels (Milestones) :

  - Taches réalisées sur le sprint d'aout : https://github.com/PnX-SI/GeoNature/issues?q=is%3Aissue+milestone%3A%22V2+-+Sprint+August+2017%22+is%3Aclosed
  - Taches en cours pour le mois de septembre : https://github.com/PnX-SI/GeoNature/issues?q=is%3Aopen+is%3Aissue+milestone%3A%22V2+-+Sprint+September%22
  - Taches terminées pour le sprint de septembre : https://github.com/PnX-SI/GeoNature/issues?q=is%3Aopen+is%3Aissue+milestone%3A%22V2+-+Sprint+September%22
- Le suivi des taches peut aussi être visualisé sous forme de projet : https://github.com/PnX-SI/GeoNature/projects/1

**A SUIVRE**

- Finalisation formulaire CONTACT
- Schéma utilisateurs et gestion des droits: (https://github.com/PnX-SI/GeoNature/issues/238)
- Révision MCD de la synthèse (https://github.com/PnX-SI/GeoNature/issues/207)
- Module générique Recherche/Carte/Liste/Export pour la synthèse et les interface de consultation dans chaque protocole

Le document de définition des fonctionnalités a été mis à jour : http://geonature.fr/documents/2017-09-GN2-Fonctionnalites-0.2.pdf

Et pour tester la première démo c'est ici http://51.254.242.81/geonature/ (premier aperçu de Accueil + Formulaire Contact FF)

- Les taxons présents dans la démo sont https://github.com/PnX-SI/TaxHub/blob/develop/data/taxhubdata_taxon_example.sql#L23-L30
- Les listes de valeurs (nomenclature) s'adaptent en fonction du regne/groupe du taxon sélectionné
- Il est possible de saisir plusieurs taxons sur un même relevé
- Il est possible de faire plusieurs dénombrements sur un même taxon
- Le référentiel géographique de la BDD permet de calculer automatiquement commun(s) et altitude min/max d'une localisation point/ligne ou polygone


1.9.1 (unreleased)
----------------------

.....
