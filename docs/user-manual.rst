MANUEL UTILISATEUR
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

OccTax
------

Ce module permet de saisir des données selon le standard Occurrence de taxon du SINP 
(https://inpn.mnhn.fr/telechargement/standard-occurrence-taxon). 

.. image :: https://geonature.fr/docs/img/user-manual/2018-09-geonature-occtax.gif

Les données sont organisées en relevés (localisation, jeu de données, date, observateur...) qui sont composés d'observations 
d'un ou plusieurs taxons (méthode, état, statut, détermination...).

Pour chaque taxon observé, il est possible de renseigner un ou plusieurs dénombrements. 

Chaque dénombrement correspond à un stade de vie et un sexe.

Chaque relevé est associé à un jeu de données. Pour saisir dans un jeu de données, il faut donc que vous ayez créé au 
préalable les jeux de données dans l'application Métadonnées (MTD) du SINP.

.. image :: https://geonature.fr/docs/img/user-manual/02-occtax.jpg

Quand on accède au module OccTax, celui-ci affiche vos données présentes dans le module, sur la carte ainsi que dans une liste. 

La carte et la liste sont interactives. 

Il est possible de se déplacer et de zoomer dans la carte (avec la souris et la molette ou les bouton + et -).

Il est aussi possible de changer le fond de carte affiché.

.. image :: https://geonature.fr/docs/img/user-manual/02-occtax-layers.jpg

Les relevés affichés peuvent être filtrés. 

Le premier filtre permet de limiter les relevés à ceux contenant un taxon en particulier. 

Pour sélectionner un taxon, saisir au moins 3 lettres de l'espèce (en français ou en latin). 

Il est aussi possible de saisir les premières lettres de l'espèce et de la sous-espèce. 

.. image :: https://geonature.fr/docs/img/user-manual/02-occtax-filters.jpg

Il est possible de filtrer la liste des taxons par règne, en affichant le filtre :

.. image :: https://geonature.fr/docs/img/user-manual/02-occtax-filters-regne.jpg

Il est possible d'afficher des filtres complémentaires, et de supprimer les filtres existants : 

.. image :: https://geonature.fr/docs/img/user-manual/02-occtax-filters-more.jpg

Cela permet de filtrer sur tous les champs du module : 

.. image :: https://geonature.fr/docs/img/user-manual/02-occtax-filters-more-tools.jpg

Selon les droits dont vous disposez, il est possible d'afficher, de modifier ou de supprimer un relevé : 

.. image :: https://geonature.fr/docs/img/user-manual/02-occtax-tools.jpg

Sur la liste, il est également possible de modifier les colonnes affichées :

.. image :: https://geonature.fr/docs/img/user-manual/02-occtax-modify-columns.jpg

.. image :: https://geonature.fr/docs/img/user-manual/02-occtax-modify-columns-2.jpg


Afficher un relevé
""""""""""""""""""

Si vous affichez un relevé, vous accéderez à sa fiche complète : 

.. image :: https://geonature.fr/docs/img/user-manual/03-occtax-detail.jpg

Si vous cliquez sur un des taxons observés dans ce relevé, cela affichera le détail de l'observation du taxon : 

.. image :: https://geonature.fr/docs/img/user-manual/03-occtax-detail-info.jpg

Vous pouvez aussi consulter les dénombrements du taxon observé : 

.. image :: https://geonature.fr/docs/img/user-manual/03-occtax-detail-counting.jpg

Il est aussi possible d'afficher les informations géographiques liées au relevé : 

.. image :: https://geonature.fr/docs/img/user-manual/03-occtax-detail-geo-button.jpg

.. image :: https://geonature.fr/docs/img/user-manual/03-occtax-detail-geo.jpg

Selon les droits dont vous disposez, il est possible de modifier un relevé directement depuis sa fiche Détail : 

.. image :: https://geonature.fr/docs/img/user-manual/03-occtax-detail-edit.jpg

Ajouter un relevé
"""""""""""""""""

Depuis la liste des relevés, cliquer sur le bouton de création d'un relevé : 

.. image :: https://geonature.fr/docs/img/user-manual/05-occtax-create.jpg

Vous accédez alors à un formulaire de saisie à compléter : 

.. image :: https://geonature.fr/docs/img/user-manual/05-occtax-add.jpg

Commencez par localiser le relevé, sous forme de point (en cliquant sur la carte ou en saisissant les coordonnées GPS du point) : 

.. image :: https://geonature.fr/docs/img/user-manual/05-occtax-create-point.jpg

De ligne (en recliquant sur le dernier point de la ligne pour la terminer) : 

.. image :: https://geonature.fr/docs/img/user-manual/05-occtax-create-line.jpg

Ou de polygone (en recliquant sur le premier point du polygone pour le terminer) : 

.. image :: https://geonature.fr/docs/img/user-manual/05-occtax-create-polygon.jpg

Les localisations peuvent être modifiées. 

Pour les points, il suffit de les déplacer ou de recliquer ailleurs sur la carte. 

Pour les lignes et les polygones, il faut cliquer sur le bouton de modification. 

.. image :: https://geonature.fr/docs/img/user-manual/05-occtax-create-polygon-edit.jpg

Vous pouvez alors déplacer les sommets existants ou en créer de nouveaux pour affiner le tracé en cliquant sur les sommets transparents.

Cliquer sur ``SAVE`` pour enregistrer les modifications apportées à une ligne ou un polygone.

Les altitudes minimum et maximum du relevé sont calculées automatiquement mais peuvent être modifiées manuellement. 

Les informations géographiques du relevé (communes notamment) sont aussi calculées automatiquement.

Pour les afficher, il faut cliquer sur le bouton d'information : 

.. image :: https://geonature.fr/docs/img/user-manual/03-occtax-detail-geo-button.jpg

.. image :: https://geonature.fr/docs/img/user-manual/05-occtax-create-geo.jpg

Une fois les informations du relevé renseignées (observateurs, jeu de données, date et commentaire optionnel), 
vous pouvez ajouter un premier taxon à celui-ci en cliquant sur ``Ajouter un taxon sur ce relevé`` :

.. image :: https://geonature.fr/docs/img/user-manual/05-occtax-add-taxon.jpg

.. image :: https://geonature.fr/docs/img/user-manual/05-occtax-create-taxon.jpg

Par défaut l'ensemble des taxons de Taxref sont disponibles à la saisie. Il est possible de resteindre cette liste pour mettre une liste personalisée via les listes TaxHub:
- au niveau du module (paramètre `id_taxon_list`. La paramètre doit être un entier correspondant à l'identifiant de la liste de la table `taxonomie.bib_listes` )
- au niveau d'un jeu de données (via le formulaire de saisie des JDD, rubriques "spécificités GeoNature")

Pour sélectionner un taxon, saisissez au moins les 3 premières lettres de son nom latin ou français. 

Vous pouvez aussi saisir les 3 premières lettres de l'espèce et de la sous-espèce.

Renseignez ensuite les autres champs relatifs au taxon. Les valeurs proposées dans les listes dépendent 
du rang et du groupe du taxon selectionné : 

.. image :: https://geonature.fr/docs/img/user-manual/05-occtax-create-taxon-plus.jpg

Des valeurs par défaut sont renseignées pour certains.

Vous pouvez ensuite renseigner un ou plusieurs dénombrements pour le taxon observé. 

Par défaut, un dénombrement indéterminé d'un individu est renseigné : 

.. image :: https://geonature.fr/docs/img/user-manual/05-occtax-create-taxon-counting.jpg

Une fois le taxon renseigné, cliquer sur ``VALIDER LE TAXON`` pour l'enregistrer : 

.. image :: https://geonature.fr/docs/img/user-manual/05-occtax-create-taxon-save.jpg

Vous pouvez alors :

- Modifier le taxon enregistré
- Supprimer le taxon enregistré
- Ajouter un autre taxon au relevé
- Enregistrer le relevé pour revenir à la liste des relevés.

Pour ajouter un taxon au relevé, il faut cliquer sur ``Ajouter un taxon sur ce relevé`` et le renseigner comme le précédent : 

.. image :: https://geonature.fr/docs/img/user-manual/05-occtax-create-taxon-2.jpg

Modifier un relevé
""""""""""""""""""

Si vous modifiez un relevé existant, vous accédez à sa fiche renseignée, sur laquelle vous pouvez modifier la localisation, les informations du relevé, les taxons observés et leurs dénombrements : 

.. image :: https://geonature.fr/docs/img/user-manual/04-occtax-edit.jpg

Vous pouvez ajouter un taxon au relevé en cliquant sur ``Ajouter un taxon sur ce relevé`` : 

.. image :: https://geonature.fr/docs/img/user-manual/04-occtax-edit-taxon.jpg

Ou modifier une observation existante d'un taxon en le selectionnant dans la liste des taxons déjà enregistrés : 

.. image :: https://geonature.fr/docs/img/user-manual/04-occtax-edit-taxon-list.jpg

.. image :: https://geonature.fr/docs/img/user-manual/04-occtax-edit-taxon-2.jpg

Exports
"""""""

Une fois que vous avez saisi vos relevés et observations depuis le formulaire, vous pouvez exporter ces données en CSV selon le standard Occurrence de taxon du SINP.

Deux méthodes sont possibles pour exporter les données :

- Depuis le module "Occtax"

Depuis la liste de vos relevés de l'interface carte-liste, filtrez d'abord vos relevés par **jeu de données** (ou autre) et cliquez sur le bouton ``Rechercher``. 

.. image :: https://geonature.fr/docs/img/user-manual/06-occtax-search-bar.jpg

Puis cliquez sur le bouton ``Télécharger les données`` en bas de la liste des relevés.

.. image :: https://geonature.fr/docs/img/user-manual/06-occtax-download-data.jpg

Une fenêtre s'ouvre, fournissant des informations sur le téléchargement des données. Selectionnez ensuite le format CSV pour GINCO :

.. image :: https://geonature.fr/docs/img/user-manual/06-occtax-download.jpg

- Depuis le module d'export :

  Les exports se font par jeu de données.

.. image :: https://geonature.fr/docs/img/user-manual/06-export.jpg

Vous obtenez alors un CSV par jeu de données.

Pour disposer dans l'export de toutes les informations saisies, une ligne correspond à un dénombrement d'un taxon. 

.. image :: https://geonature.fr/docs/img/user-manual/06-export-csv.jpg

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



Metadonnées
-----------

Ce module permet de gérer les métadonnées (Cadres d'acquisition et jeux de données) de votre instance GeoNature, basées sur le standard Métadonnées du SINP (https://standards-sinp.mnhn.fr/category/standards/metadonnees/).

Ces métadonnées permettent de décrire et d'organiser les données (occurrences de taxons, d'habitats, données protocolées...) au sein de lots de données cohérents et documentés. Les métadonnées ainsi créées sont propres à chaque instance de GeoNature. Pour autant, leur format standard permet aisément de les diffuser et les partager vers d'autres outils.


Structure des métadonnées
"""""""""""""""""""""""""

Les métadonnées comprennent deux niveaux distincts, comportant chacun un ensemble d'informations descriptives : 

- Le cadre d'acquisition, qui permet de décrire le contexte ou le projet dans lequel les données ont été produites
- Le jeu de données, qui permet de regrouper un sous-ensemble ou lot de données similaires (groupées par protocole, localités, périodes...)

Dans GeoNature, un Cadre d'Acquisition peut comporter un ou plusieurs jeux de données, comportant eux-mêmes les données de biodiversité. GeoNature permet également de regrouper des Cadres d'Acquisitions ensemble, au sein d'un Cadre d'Acquisition dit "parent". Dans le cas le plus complet, l'outil permet ainsi d'organiser les données selon le schéma suivant : 

- Un cadre d'acquisition "parent" (ou méta-cadre selon le standard SINP) décrit un projet complexe
- Ce cadre d'acquisition parent comporte un ou plusieurs cadres d'acquisitions, décrivant des "sous-projets" d'un niveau inférieur
- Ces cadres d'acquisition comportent chacun un ou plusieurs jeux de données
- Ces jeux de données comportent chacun un ensemble de données de biodiversité : données protocoles, occurrences de taxons, occurrences d'habitats etc

--> Schéma


Utilisation des métadonnées dans GeoNature
""""""""""""""""""""""""""""""""""""""""""

Les métadonnées jouent un rôle central dans GeoNature, et sont nécessaires dans les différents module de saisie ou de consultation des données. La gestion des métadonnées est donc la première étape à effectuer, avant de pouvoir produire ou exploiter les données de biodiversité en elles-mêmes. La notion de jeux de données intervient notamment pour les fonctionnalités suivantes :

**Saisie ou import de données**

	Lors de sa création dans GeoNature, chaque donnée est obligatoirement associée à un jeu de données. Ainsi le module d'import et la majorité des modules de saisie (Occtax, OccHab...) nécessitent de sélectionner le jeu de données auquel seront rattachées les données en cours de création. 
	Dans certains cas plus spécifiques (monitorings par exemple), le module peut ne pas demander cette information à l'utilisateur. Pour autant, les données en cours de création sont automatiquement rattachées à un jeu de données défini dans la configuration, de manière transparente pour l'utilisateur. 

	
**Requêtage**
	
	Les métadonnées constituent des "boîtes" dans lesquelles sont rangées les données. Tous les modules de GeoNature permettant de requêter des données (Synthèse, Dashboard, Validation, Occtax...) offrent la possibilité de filtrer par cadre d'acquisition ou par jeu de données. 
	De cette manière, l'outil permet aisément de rechercher ou exporter ses données par "campagnes", par "études", par "projet" etc, selon l'organisation des métadonnées mise en place au sein de l'instance et selon la manière de produire les données de chaque utilisateur.


**Permissions**

	Enfin, les métadonnées font également partie des critères d'application des permissions ou restrictions imposées à chaque utilisateur au sein de l'instance (cf https://docs.geonature.fr/admin-manual.html#gestion-des-droits). 
	Ainsi les acteurs associés aux métadonnées pourront définir les utilisateurs pouvant alimenter les jeux de données en question selon les paramètres définis : un utilisateur disposant uniquement des droits sur ses propres données pourra alimenter un jeu de données sont il est personnellement acteur, tandis qu'un utilisateur ayant des droits sur les données de son organisme pourra potentiellement alimenter tous jeux de données associés à sa structure.

**Champs additionnels**

	GeoNature permet de configurer des champs additionnels "personnalisés", qui viennent compléter les champs du standard du sinp (sexe, stade de vie etc). Ces champs additionnels sont implémentés dans le module de saisie Occtax notamment, et peuvent être rendus disponibles uniquement pour certains jeux de données. Il devient ainsi possible, pour un jeu de données en particulier, de recueillir une variable ou une information supplémentaire.


Fonctionnement du module métadonnées
""""""""""""""""""""""""""""""""""""

	Le module métadonnées de GeoNature permet de consulter, rechercher et gérer ses cadres d'acquisitions et jeux de données, nécessaires à la gestion des données.

**Consulter, rechercher ou modifier ses métadonnées**
TODO

**Créer un cadre d'acquisition**
Le module permet la création d'un nouveau cadre d'acquisition en appuyant sur "Ajouter un cadre d'acquisition". Il suffit ensuite d'alimenter le formulaire en décrivant le cadre d'acquisition (le projet ou programme) qui conduit à la production de données de biodiversité.

Les champs obligatoires (Nom, description, objectifs, territoire...) sont marqués d'un trait rouge.

Les cadres d'acquisition doivent comporter un ou des acteurs associés (organismes, utilisateurs, ou les deux). 

L'outil permet également d'associer des références bibliographiques (publications etc) à un cadre d'acquisition. 

En cliquant sur la case à cocher "est un cadre d'acquisition parent", l'utilisateur peut créer un cadre d'acquisition "supra", qui pourra ensuite regrouper plusieurs cadres d'acquisition "simples". A l'inverse, en sélectionnant un cadre d'acquisition parent, l'utilisateur pourra associer son cadre d'acquisition à un cadre "parent", de niveau supérieur. 

-> Captures d'écran

**Créer un jeu de données**
De la même manière que pour les cadres d'acquisition, le module "métadonnées" permet de créer des jeux de données en cliquant sur "Ajouter un jeu de données". 

L'utilisateur est alors invité à décrire son lot de données (nom, description, méthodes...) et à indiquer à quel cadre d'acquisition son jeu de données est rattaché. 
La case à cocher "actif à la saisie" permet d'ouvrir ou fermer le jeu de données, qui sera ou non proposé aux utilisateurs dans les modules de saisie et/ou module d'import. De même, les données peuvent être - ou non - rendues validables.

Enfin comme pour les cadres d'acquisition, l'utilisateur devra définir le ou les acteurs associés au jeu de données en question (producteur, financeur etc) : organismes, personnes, ou les deux. Ces choix pourront influer sur les permissions des utilisateurs à alimenter, ou non, le jeu de données considéré. 

	*Associer un jeu de données à des modules*

Afin de faciliter la saisie et limiter les erreurs, GeoNature nécessite d'associer chaque jeu de données à un ou des modules. De cette manière, l'utilisateur peut choisir depuis quel(s) module(s) (de saisie ou d'import) son jeu de données pourra être sélectionné et alimenté. Cette association se fait depuis le formulaire de création/d'édition du jeu de données.

	*Associer un jeu de données à une liste de taxons*

De la même manière, GeoNature permet d'associer un jeu de données à une liste de taxons. Cette association n'est pas obligatoire (par défaut, c'est la liste du module de saisie ou tout taxref qui seront disponibles). Cela permet notamment de réduire le nombre de taxons proposés à la saisie dans des jeux de données dédiés à un groupe d'espèces restreints (protocoles, suivis etc).
Cette association se fait depuis le formulaire de création/d'édition du jeu de données.

