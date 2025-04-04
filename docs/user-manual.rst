Manuel utilisateur
==================

Authentification
----------------

Accéder à l'application de démonstration à l'adresse https://demo.geonature.fr/geonature.

Connectez-vous avec l'utilisateur ``admin`` et le mot de passe ``admin``.

Accueil
-------

Vous accédez alors à la page d'accueil de l'application GeoNature. 

.. image :: https://geonature.fr/docs/img/user-manual/01-home-MTES.jpg

Le Menu de navigation à gauche permet d'accéder aux différents modules de l'application.

.. image :: https://geonature.fr/docs/img/user-manual/01-home-menu.jpg

Le bouton à gauche du nom de la page permet de rabattre ou d'ouvrir le Menu de navigation.

.. image :: https://geonature.fr/docs/img/user-manual/01-home-sidebar.jpg

Un bouton en haut à droite permet de se déconnecter de l'application.

.. image :: https://geonature.fr/docs/img/user-manual/01-home-logout.jpg


Metadonnées
-----------

Ce module permet de gérer les métadonnées (Cadres d'acquisition et jeux de données) de votre instance GeoNature, basées sur le standard Métadonnées du SINP (https://standards-sinp.mnhn.fr/category/standards/metadonnees/).

Ces métadonnées permettent de décrire et d'organiser les données (occurrences de taxons, d'habitats, données protocolées...) au sein de lots de données cohérents et documentés. Les métadonnées ainsi créées sont propres à chaque instance de GeoNature, mais leur format standard permet de les diffuser vers d'autres outils ou dans le cadre du SINP.

Pour les utilisateurs disposant des droits suffisants, le module Métadonnées est accessible depuis le menu gauche de GeoNature. 

.. image :: https://geonature.fr/docs/img/user-manual/mtd/mtd_00_Acceder_au_module.png


Structure des métadonnées
"""""""""""""""""""""""""

Les métadonnées comprennent deux niveaux distincts, comportant chacun un ensemble d'informations descriptives : 

- Le cadre d'acquisition, qui permet de décrire le contexte ou le projet dans lequel les données ont été produites
- Le jeu de données, qui permet de regrouper un sous-ensemble ou lot de données similaires (groupées par protocole, localités, périodes...)

Un Cadre d'acquisition peut comporter un ou plusieurs Jeux de données, comportant eux-mêmes les données de biodiversité. GeoNature permet également de regrouper des Cadres d'acquisitions ensemble, au sein d'un Cadre d'acquisition dit "parent". Dans le cas le plus complet, l'outil permet ainsi d'organiser les données selon le schéma suivant : 

- Un cadre d'acquisition "parent" (ou méta-cadre selon le standard SINP) décrit un projet complexe
- Ce cadre d'acquisition parent comporte un ou plusieurs Cadres d'acquisitions, décrivant des "sous-projets" simples
- Ces Cadres d'acquisition comportent chacun un ou plusieurs Jeux de données
- Ces Jeux de données comportent chacun un ensemble de données de biodiversité : données protocolées, occurrences de taxons, occurrences d'habitats etc

.. image :: https://geonature.fr/docs/img/user-manual/mtd/mtd_01_Imbrication_notions.png


Utilisation des métadonnées dans GeoNature
""""""""""""""""""""""""""""""""""""""""""

Les métadonnées jouent un rôle central dans GeoNature, et sont nécessaires dans les différents modules de saisie ou de consultation des données. **La gestion des métadonnées est donc la première étape à effectuer, avant de pouvoir produire ou exploiter les données de biodiversité en elles-mêmes**. La notion de jeux de données intervient notamment pour les fonctionnalités suivantes :

**- Saisie ou import de données**

Lors de sa création dans GeoNature, chaque donnée doit être obligatoirement associée à un jeu de données préalablement créé. Ainsi le module d'import et la majorité des modules de saisie (Occtax, OccHab...) nécessitent de sélectionner le jeu de données auquel seront rattachées la ou les données en cours de création. 
Dans certains cas plus spécifiques (Monitorings par exemple), le module peut ne pas demander cette information à l'utilisateur car le jeu de données est sélectionné de manière "transparente" par la configuration du module.

.. image :: https://geonature.fr/docs/img/user-manual/mtd/mtd_exemple_selection_jdd.png
	
**- Requêtage**
	
Les métadonnées constituent des "boîtes" dans lesquelles sont rangées les données. Tous les modules de GeoNature permettant de requêter des données (Synthèse, Dashboard, Validation, Occtax...) offrent la possibilité de filtrer par cadre d'acquisition ou par jeu de données. 
De cette manière, l'outil permet de rechercher ou exporter facilement ses données par "campagnes", par "études", par "projet" etc, selon l'organisation des métadonnées mise en place au sein de chaque instance.

.. image :: https://geonature.fr/docs/img/user-manual/mtd/mtd_exemple_requetage.png

**- Permissions**

Les métadonnées sont également utilisées pour l'application des permissions ou restrictions imposées à chaque utilisateur au sein de l'instance (cf https://docs.geonature.fr/admin-manual.html#gestion-des-droits). 
Ainsi les acteurs associés à chaque jeu de données permettront de définir les utilisateurs pouvant consulter ou alimenter les jeux de données en question selon les paramètres définis : 

- un utilisateur disposant uniquement des droits sur ses propres données pourra alimenter/consuter les données des jeux de données dont il est personnellement acteur, 
- un utilisateur ayant des droits sur les données de son organisme pourra potentiellement alimenter/consulter les données des jeux de données dont sa structure est actrice,
- enfin un utilisateur ayant les droits sur toutes les données pourra alimenter/consulter les données de tous les jeux de données, quelques soient les acteurs associés

**- Champs additionnels**

GeoNature permet de configurer des champs additionnels "personnalisés" (https://docs.geonature.fr/admin-manual.html#administration-des-champs-additionnels), qui viennent compléter les champs du standard du sinp (sexe, stade de vie etc). Ces champs additionnels sont implémentés dans le module de saisie Occtax notamment, et peuvent être rendus disponibles uniquement pour certains jeux de données. Il devient ainsi possible, pour un jeu de données en particulier, de recueillir une variable ou une information supplémentaire qui n'apparaitrait pas dans les champs "standards".


Fonctionnement du module Métadonnées
""""""""""""""""""""""""""""""""""""

Le module Métadonnées de GeoNature permet de consulter, rechercher et gérer ses cadres d'acquisitions et jeux de données, nécessaires à la gestion des données.

**Consulter, rechercher ou modifier ses métadonnées**

L'accueil du module Métadonnées liste l'ensemble des Cadres d'acquisition disponibles dans l'instance GeoNature. Chaque cadre d'acquisition peut être "déplié" pour afficher les jeux de données qu'il contient. 

.. image :: https://geonature.fr/docs/img/user-manual/mtd/mtd_02_Catalogue_mtd.png

Cette page comporte également une barre de recherche pour effectuer une recherche rapide dans les métadonnées disponibles, et une fonctionnalité de "recherche avancée". Elle permet également de consulter les fiches détaillées, de modifier, ou de supprimer les métadonnées existantes. 

.. image :: https://geonature.fr/docs/img/user-manual/mtd/mtd_03_Actions_catalogue.png

.. image :: https://geonature.fr/docs/img/user-manual/mtd/mtd_04_RechercheAvancee.png

**Créer un cadre d'acquisition**

Cette page permet également d'accéder au formulaire de création des Cadres d'acquisition via le bouton "Ajouter un Cadre d'acquisition". 

.. image :: https://geonature.fr/docs/img/user-manual/mtd/mtd_05_AjouterCA.png

Ce formulaire permet de renseigner les différentes informations descriptions du Cadre d'acquisition (projet/programme). Les champs obligatoires (Nom, description, objectifs, territoire...) sont marqués d'un trait rouge.

Les cadres d'acquisition doivent également comporter un ou des acteurs associés (organismes, utilisateurs, ou les deux). 

.. image :: https://geonature.fr/docs/img/user-manual/mtd/mtd_06_FormulaireCA.png

Il est également possible d'associer des références bibliographiques (publications etc) au cadre d'acquisition. 

.. image :: https://geonature.fr/docs/img/user-manual/mtd/mtd_07_BiblioCA.png

En cliquant sur la case à cocher "est un cadre d'acquisition parent", l'utilisateur peut créer un "métacadre" d'acquisition, qui pourra ensuite regrouper plusieurs cadres d'acquisition "simples". A l'inverse, en sélectionnant un cadre d'acquisition parent, l'utilisateur pourra associer son cadre d'acquisition à un cadre "parent" créé préalablement. 


**Créer un jeu de données**

De la même manière que pour les Cadres d'acquisition, la page d'accueil du module Métadonnées comporte un bouton "Ajouter un jeu de données" qui  permet d'accéder au formulaire de création d'un nouveau Jeu de Données. 

.. image :: https://geonature.fr/docs/img/user-manual/mtd/mtd_08_AjoutJDD.png

Ce formulaire permet à l'utilisateur de décrire son lot de données (nom, description, méthodes...) et d'indiquer à quel cadre d'acquisition (projet) il est rattaché. 

Enfin comme pour les cadres d'acquisition, l'utilisateur devra définir le (ou les) acteur(s) associé(s) au jeu de données en question (producteur, financeur etc) : organismes, personnes, ou les deux. Ces choix permettront de définir les utilisateurs qui pourront - ou non - alimenter et consulter les données du jeu de données considéré en fonction des permissions configurées.

.. image :: https://geonature.fr/docs/img/user-manual/mtd/mtd_09_Formulaire_JDD.png

La case à cocher "actif à la saisie" permet d'ouvrir ou fermer le jeu de données, qui sera ou non proposé aux utilisateurs dans les modules de saisie ou d'import. De même, les jeux de données peuvent être - ou non - rendus validables.

Ce formulaire permet également d'associer les jeux de données à un (ou des) module(s) de GeoNature, et éventuellement à une liste de taxons.

.. image :: https://geonature.fr/docs/img/user-manual/mtd/mtd_10_SpecifiqueGeoNature.png


**Association entre jeux de données et modules**

Afin de faciliter la saisie et limiter les erreurs, GeoNature permet d'associer chaque jeu de données à un (ou des) module(s). De cette manière, il est possible de définir depuis quel(s) module(s) le jeu de données considéré pourra être alimenté par les différents utilisateurs.

Cette association se fait depuis le formulaire de création/d'édition du jeu de données.

**Association entre Jeu de données et liste de taxons**

De la même manière, GeoNature permet d'associer un jeu de données à une liste de taxons. Cette association n'est pas obligatoire (par défaut, c'est la liste du module de saisie ou tout Taxref qui seront disponibles).

Cela permet notamment de réduire le nombre de taxons proposés à la saisie dans des jeux de données dédiés à un groupe d'espèces restreint (protocoles, suivis etc).

Cette association se fait depuis le formulaire de création/d'édition du jeu de données.


.. include:: ./utilisateur/occtax.rst

Synthèse
--------

Ce module permet de consulter, rechercher et exporter les données provenant des différentes sources et protocoles avec leur tronc commun, basé sur le standard Occurrences de taxon du SINP (https://inpn.mnhn.fr/telechargement/standard-occurrence-taxon).

Il permet aussi d'afficher la fiche détaillée de chaque occurrence et de revenir à sa fiche source si elle a été saisie dans un module de GeoNature.

.. image :: https://geonature.fr/docs/img/user-manual/2018-09-geonature-synthese.gif

Accéder à la synthèse
"""""""""""""""""""""

Cliquez sur le module Synthèse, dans le menu de navigation : 

.. image :: https://geonature.fr/docs/img/user-manual/synthese/01-acces-synthese.jpg

Présentation de la synthèse
"""""""""""""""""""""""""""

La page principale de la synthèse est composée de 3 blocs :

- Rechercher dans les résultats
- Visualiser les résultats sur la carte
- Visualiser les résultats en liste

.. image :: https://geonature.fr/docs/img/user-manual/synthese/02-presentation-synthese.jpg

Par défaut, la synthèse affiche les 100 observations les plus récentes. Il est possible d’accéder aux données souhaitées en appliquant un ensemble de filtres.

Détail d’une observation
""""""""""""""""""""""""

Il est possible d’accéder au détail d’une observation en cliquant sur le symbole (i) à gauche d’une observation. Le détail d’une observation correspond à l’ensemble des informations contenues dans la synthèse pour cette observation. 

Une observation au sens de la synthèse ne correspond pas tout à fait à la donnée saisie initialement. C’est une représentation simplifiée et unifiée des données qui repose sur le standard SINP et qui répond aux questions suivantes : 

- Où ? 
- Quand ? : Date et heure de l’observation
- Qui ? : Observateur 
- Quoi ? : Taxon, nombre et type d’individus, état biologique, ...
- Dans quel cadre ? 

Toutes les données de la synthèse sont ramenées au niveau du dénombrement de taxon (exemple : 1 individu mâle adulte de Chevêche). Si une occurrence est constituée de 2 dénombrements, il y aura 2 enregistrements dans la synthèse (exemple : 1 individu mâle adulte et 1 individu femelle indéterminée de Chevêche).

.. image :: https://geonature.fr/docs/img/user-manual/synthese/03-detail-synthese.jpg

Rechercher des observations
"""""""""""""""""""""""""""

**1. Filtrer les données géographiquement :**

Il y a 3 façons de filtrer géographiquement les données :
 
- en sélectionnant une commune
- en dessinant une zone sur la carte à l’aide des outils de dessin (rectangle, polygone ou cercle)
- en important un fichier de la zone

**Filtrer par communes :**

Dans le panneau filtre : 

- cliquez sur le champ Communes
- saisissez les premières lettre de la commune
- sélectionnez la commune souhaitée

Il est possible de sélectionner plusieurs communes.

.. image :: https://geonature.fr/docs/img/user-manual/synthese/04-recherche-communes.jpg

**Dessiner une zone :**

Sur la carte, choisir un outil de dessin (rectangle, polygone ou cercle) et réaliser votre selection sur la carte.

.. image :: https://geonature.fr/docs/img/user-manual/synthese/05-recherche-polygone.jpg

Après avoir dessiné une zone, il est nécessaire de cliquer sur le bouton Rechercher.

**Importer un fichier :**

Il est possible d'importer une/des zone(s) de sélection directement à partir d’un fichier GeoJson.

Vous pouvez préparer ce fichier avec QGIS depuis un fichier SHP ou autre. Le fichier doit être enregistré au format GeoJson (projection 4326).

Sur la couche souhaitée :

- Faire un clic droit sur la couche puis sélectionner Exporter > Sauvegarder les entités sous...

.. image :: https://geonature.fr/docs/img/user-manual/synthese/06-qgis-geojson.jpg

- Enregistrer le fichier en sélectionnant les bons paramètres :
   - Format : GeoJson
   -  SCR : WGS 84 (4326)
   - Pour des questions de performance il est possible de ne pas exporter les données attributaires
   
.. image :: https://geonature.fr/docs/img/user-manual/synthese/06b-qgis-geojson.jpg

Importer le fichier dans la synthèse GeoNature :

- Cliquer sur l’icône ouvrir un fichier
- Sélectionner le fichier
- La ou les zone(s) apparaissent sur la carte
- Lancer la recherche

.. image :: https://geonature.fr/docs/img/user-manual/synthese/07-filtre-geojson.jpg

**2. Filtrer les données via la taxonomie**

Il est possible de rechercher les données en utilisant des critères taxonomiques, en recherchant soit sur un taxon ou un groupe taxonomique en particulier, soit en se basant sur des critères taxonomiques (statut de protection, attributs)

**Recherche simple :**

Dans le panneau filtre : 

- cliquez sur le champ taxon
- saisissez les premières lettre du taxon
- sélectionnez le taxon souhaité

Il est possible de sélectionner plusieurs taxons.

.. image :: https://geonature.fr/docs/img/user-manual/synthese/08-filtre-taxons.jpg

**Recherche avancée :**

Dans le panneau filtre dans la section « Quoi ? » cliquer sur Avancé.

Vous pourrez :

- Sélectionner un ou des groupes taxonomiques (exemple Chiroptera)
- Filtrer sur les listes rouge UICN,...
- Filtrer sur des attributs spécifiés dans TaxHub : patrimonialité, enjeu prioritaire, ...

.. image :: https://geonature.fr/docs/img/user-manual/synthese/08-filtre-taxons-avances.jpg

**3. Autres filtres**

Il est également possible de filtrer :

- sur une date ou une période donnée
- sur un observateur
- sur un jeu de données

.. image :: https://geonature.fr/docs/img/user-manual/synthese/09-filtre-autres.jpg

Admin
-----

C'est le module "backoffice" de GeoNature.
Il permet notamment de gérer les permissions (CRUVED et autres filtres), les nomenclatures (typologies et vocabulaires) utilisées dans les différents modules de GeoNature ainsi que les champs additionnels.

Gestion des permissions
"""""""""""""""""""""""

Depuis le version 2.13.0 de GeoNature, le système des permissions a été entièrement revu pour : 
- pouvoir leur associer d'autres types de filtres (sensibilité notamment), 
- les simplifier et clarifier en supprimant l'héritage et en définissant les permissions disponibles pour chaque module

Le modèle de données des permissions et leur logique ayant été revu, il a fallu faire évoluer leur interface d'administration.

Il a été retenu de réaliser cette nouvelle interface d'administration des permissions dans le module ADMIN existant de GeoNature.

Il y est possible de lister toutes les permissions attribuées dans une instance GeoNature : 

.. image :: https://github.com/PnX-SI/GeoNature/assets/4418840/2002df3e-733e-4894-b001-2b3608bb896e

Il est possible de filtrer rapidement cette liste en saisissant un nom d'utilisateur ou de groupe, ou en appliquant un filtre par module, action, par utilisateur ou groupe... : 

.. image :: https://github.com/PnX-SI/GeoNature/assets/4418840/8649033a-21cf-489d-b522-01f7b88333dc

-----------------------------

Il est possible de modifier, supprimer ou ajouter une nouvelle permission : 

.. image :: https://github.com/PnX-SI/GeoNature/assets/4418840/c07beff6-197c-4f28-b8d1-43ead470b00d

La liste des permissions ne contient que celles qui ont un réel usage car elles sont déclarées par chaque module.
Une fois que l'on a sélectionné un groupe ou utilisateur, la liste des permissions ne propose que des permissions qui n'ont pas été définies pour celui-ci, ou alors pour lesquelles on peut définir plusieurs permissions se combinant (Exemple du Read de la Synthèse pour lequel on peut créer une permission indiquant qu'un utilisateur voit toutes les données de son organisme sans filtre de sensibilité, mais qu'il voit toutes les données avec un filtre de sensibilité) : 

.. image :: https://github.com/PnX-SI/GeoNature/assets/4418840/7aa6ec8c-2244-4a18-9af6-c11140af9afc

Une fois qu'une permission a été selectionnée, si des filtres peuvent être appliqués à celle-ci dans ce module, alors les filtres sont affichés : 

.. image :: https://github.com/PnX-SI/GeoNature/assets/4418840/6f90e1cc-d71d-44bd-81c8-47bc6dfe11d9

Si aucun filtre n'est sélectionné, alors la permission s'applique sur toutes les données concernées.

----------------------------

Il est aussi possible d'afficher et de gérer les permissions par groupes ou par utilisateurs : 

.. image :: https://github.com/PnX-SI/GeoNature/assets/4418840/1f59af83-683e-4e1b-ba85-95649558ea0f

Quand on clique sur un groupe ou utilisateur pour en consulter le détail des permissions, toutes les permissions disponibles de tous les modules sont affichées : 

.. image :: https://github.com/PnX-SI/GeoNature/assets/4418840/6cd94fc1-b597-423e-99de-c58e48291a0f

Les permissions sur fond rouge, qui affichent uniquement un + indiquent que le groupe ou utilisateur n'a pas cette permission et qu'on peut lui ajouter en cliquant sur ce +.

Les permissions dont disposent le groupe ou l'utilisateur sont indiquées en vert (si sans filtre) ou en bleu (si avec filtre) : 

.. image :: https://github.com/PnX-SI/GeoNature/assets/4418840/6a3bb721-0741-4aec-b8ad-eb0bbeade675

------------------------------

Pour les utilisateurs sont listées les permissions qui lui sont attribués directement individuellement, mais aussi les permissions effectives qui s'appliquent à lui (selon les groupes auquel il appartient) : 

.. image :: https://github.com/PnX-SI/GeoNature/assets/4418840/75486b5c-a571-4c3a-9fd5-ff57328776c7


.. include:: utilisateur/import.rst
