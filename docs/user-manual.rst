MANUEL UTILISATEUR
==================

Authentification
----------------

Accéder à l'application sur http://demo.geonature.fr/geonature

Si vous n'êtes pas déjà authentifié avec votre compte INPN, vous serez invité à le faire : 

.. image :: http://geonature.fr/docs/img/user-manual/00-login-inpn.jpg

Accueil
-------

Vous accédez alors à la page d'accueil de l'application GeoNature, permettant la saisie puis l'export 
de données brutes de biodiversité. 

.. image :: http://geonature.fr/docs/img/user-manual/01-home-MTES.jpg

Le Menu de navigation à gauche permet d'accéder aux différents modules de l'application

.. image :: http://geonature.fr/docs/img/user-manual/01-home-menu.jpg

Le bouton à gauche du nom de la page permet de rabattre ou d'ouvrir le Menu de navigation

.. image :: http://geonature.fr/docs/img/user-manual/01-home-sidebar.jpg

Un bouton en haut à droite permet de se déconnecter de l'application

.. image :: http://geonature.fr/docs/img/user-manual/01-home-logout.jpg

OCCTAX
------

Ce module permet de saisir des données selon le standard Occurrence de taxon du SINP 
(https://inpn.mnhn.fr/telechargement/standard-occurrence-taxon). 

Les données sont organisées en relevés (localisation, jeu de données, date, observateur...) qui sont composés d'observations 
d'un ou plusieurs taxons (méthode, état, statut, détermination...).

Pour chaque taxon observé, il est possible de renseigner un plusieurs dénombrements. 

Chaque dénombrement correspond à un stade de vie et un sexe.

Chaque relevé est associé à un jeu de données. Pour saisir dans un jeu de données, il faut donc que vous ayez créé au 
préalable les jeux de données dans l'application Métadonnées (MTD) du SINP.

.. image :: http://geonature.fr/docs/img/user-manual/02-occtax.jpg

Quand on accède au module OccTax, celui-ci affiche vos données présentes dans le module, sur la carte ainsi que dans une liste. 

La carte et la liste sont interactives. 

Il est possible de se déplacer et de zoomer dans la carte (avec la souris et la molette ou les bouton + et -).

Il est aussi possible de changer le fond de carte affiché.

.. image :: http://geonature.fr/docs/img/user-manual/02-occtax-layers.jpg

Les relevés affichés peuvent être filtrés. 

Le premier filtre permet de limiter les relevés à ceux contenant un taxon en particulier. 

Pour sélectionner un taxon, saisir au moins 3 lettres de l'espèce (en français ou en latin). 

Il est aussi possible de saisir les premières lettres de l'espèce et de la sous-espèce. 

.. image :: http://geonature.fr/docs/img/user-manual/02-occtax-filters.jpg

Il est possible de filtrer la liste des taxons par règne, en affichant le filtre :

.. image :: http://geonature.fr/docs/img/user-manual/02-occtax-filters-regne.jpg

Il est possible d'afficher des filtres complémentaires : 

.. image :: http://geonature.fr/docs/img/user-manual/02-occtax-filters-more.jpg

Cela permet de filtrer sur tous les champs du module mais aussi de modifier les colonnes affichées dans la liste des résultats : 

.. image :: http://geonature.fr/docs/img/user-manual/02-occtax-filters-more-tools.jpg

Selon les droits dont vous disposez, il est possible d'afficher, de modifier ou de supprimer un relevé : 

.. image :: http://geonature.fr/docs/img/user-manual/02-occtax-tools.jpg

AFFICHER UN RELEVE
------------------

Si vous afficher un relevé, vous accéderez à sa fiche complète : 

.. image :: http://geonature.fr/docs/img/user-manual/03-occtax-detail.jpg

Si vous cliquez sur un des taxons observé dans ce relevé, cela affichera le détail de l'observation du taxon : 

.. image :: http://geonature.fr/docs/img/user-manual/03-occtax-detail-info.jpg

Vous pouvez aussi consultez les dénombrement du taxon observé : 

.. image :: http://geonature.fr/docs/img/user-manual/03-occtax-detail-counting.jpg

Il est aussi possible d'afficher les informations géographiques liées au relevé : 

.. image :: http://geonature.fr/docs/img/user-manual/03-occtax-detail-geo-button.jpg

.. image :: http://geonature.fr/docs/img/user-manual/03-occtax-detail-geo.jpg

Selon les droits dont vous disposez, il est possible de modifier un relevé directement depuis sa fiche Détail : 

.. image :: http://geonature.fr/docs/img/user-manual/03-occtax-detail-edit.jpg

AJOUTER UN RELEVE
-----------------

Depuis la liste des relevés, cliquer sur le bouton de création d'un relevé : 

.. image :: http://geonature.fr/docs/img/user-manual/05-occtax-create.jpg

Vous accédez alors à un formulaire de saisie à compléter : 

.. image :: http://geonature.fr/docs/img/user-manual/05-occtax-add.jpg

Commencez par localiser le relevé, sous forme de point (en cliquant sur la carte ou en saisissant les coordonnées GPS du point) : 

.. image :: http://geonature.fr/docs/img/user-manual/05-occtax-create-point.jpg

De ligne (en recliquant sur le dernier point de la ligne pour la terminer) : 

.. image :: http://geonature.fr/docs/img/user-manual/05-occtax-create-line.jpg

Ou de polygone (en recliquant sur le premier point du polygone pour le terminer) : 

.. image :: http://geonature.fr/docs/img/user-manual/05-occtax-create-polygon.jpg

Les localisations peuvent être modifiées. 

Pour les points, il suffit de les déplacer ou de recliquer ailleurs sur la carte. 

Pour les lignes et les polygones, il faut cliquer sur le bouton de modification. 

.. image :: http://geonature.fr/docs/img/user-manual/05-occtax-create-polygon-edit.jpg

Vous pouvez alors déplacer les sommets existants ou en créer de nouveaux pour affiner le tracé en cliquant sur les sommets transparents.

Cliquer sur ``SAVE`` pour enregistrer les modifications apportées à une ligne ou un polygone.

Les altitudes minimum et maximum du relevé sont calculées automatiquement mais peuvent être modifiées manuellement. 

Les informations géographiques du relevé (communes notamment) sont aussi calculés automatiquement.

Pour les afficher, il faut cliquer sur le bouton d'information : 

.. image :: http://geonature.fr/docs/img/user-manual/03-occtax-detail-geo-button.jpg

.. image :: http://geonature.fr/docs/img/user-manual/05-occtax-create-geo.jpg

Une fois les informations du relevé renseignées (observateurs, jeu de données, date et commentaire optionnel), 
vous pouvez ajouter un premier taxon à celui-ci : 

.. image :: http://geonature.fr/docs/img/user-manual/05-occtax-create-taxon.jpg

Pour sélectionner un taxon, saisissez au moins les 3 premières lettres de son nom latin ou français. 

Vous pouvez aussi saisir les 3 premières lettres de l'espèce et de la sous-espèce.

Renseignez ensuite les autres champs relatifs au taxon. Les valeurs proposées dans les listes dépendent 
du rang et du groupe du taxon selectionné : 

.. image :: http://geonature.fr/docs/img/user-manual/05-occtax-create-taxon-plus.jpg

Des valeurs par défaut sont renseignées par défaut pour certains.

Vous pouvez ensuite renseigner un ou plusieurs dénombrements pour le taxon observé. 

Par défaut, un dénombrement indéterminé d'un individu est renseigné : 

.. image :: http://geonature.fr/docs/img/user-manual/05-occtax-create-taxon-counting.jpg

Une fois le taxon renseigné, cliquer sur AJOUTER LE TAXON pour l'enregistrer : 

.. image :: http://geonature.fr/docs/img/user-manual/05-occtax-create-taxon-save.jpg

Vous pouvez alors :

- Modifier le taxon enegistré
- Supprimer le taxon enregistrés
- Ajouter un autre taxon au relevé
- Enregistrer le relevé pour revenir à la liste des relevés.

Pour ajouter un taxon au relevé, il faut cliquer sur TAXON et le renseigner comme le précédent : 

.. image :: http://geonature.fr/docs/img/user-manual/05-occtax-create-taxon-2.jpg

MODIFIER UN RELEVE
------------------

Si vous modifier un relevé existant, vous accédez à sa fiche renseignée, sur laquelle vous pouvez modifier la localisation, les informations du relevé, les taxons observés et leurs dénombrements : 

.. image :: http://geonature.fr/docs/img/user-manual/04-occtax-edit.jpg

Vous pouvez ajouter un taxon au relevé en cliquant sur TAXON : 

.. image :: http://geonature.fr/docs/img/user-manual/04-occtax-edit-taxon.jpg

Ou modifier une observation existante d'un taxon en le selectionnant dans la liste des taxons déjà enregistrés : 

.. image :: http://geonature.fr/docs/img/user-manual/04-occtax-edit-taxon-list.jpg

.. image :: http://geonature.fr/docs/img/user-manual/04-occtax-edit-taxon-2.jpg

EXPORT
------

Une fois que vous avez saisi vos relevés et observations dans le module OccTax, vous pouvez exporter ces données en CSV selon le standard Occurrence de taxon du SINP. 

Les exports se font jeu de données par jeu de données.

.. image :: http://geonature.fr/docs/img/user-manual/06-export.jpg

Vous obtenez alors un CSV par jeu de données.

Pour disposer de toutes les informations saisies dans l'export, une ligne correspond à un dénombrement d'un taxon. 

.. image :: http://geonature.fr/docs/img/user-manual/06-export-csv.jpg
