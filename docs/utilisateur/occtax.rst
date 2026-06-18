Module OccTax : Saisir des occurences de taxons
-----------------------------------------------

1. Description du module
"""""""""""""""""

Ce module permet de saisir des données selon le `standard Occurrence de taxon du SINP <https://inpn.mnhn.fr/telechargement/standard-occurrence-taxon>`_.

Les données sont organisées en relevés (localisation, jeu de données, date, observateur...) qui sont composés d'observations 
d'un ou plusieurs taxons (méthode, état, statut, détermination...).

Pour chaque taxon observé, il est possible de renseigner un ou plusieurs dénombrements. 

Chaque dénombrement correspond à un stade de vie et un sexe.

Chaque relevé est associé à un jeu de données. Pour saisir dans un jeu de données, il faut donc que vous ayez créé au 
préalable les jeux de données dans l'application Métadonnées (MTD) du SINP.

.. image:: /utilisateur/imgs/02-occtaxv2.png

Quand on accède au module OccTax, celui-ci affiche vos données présentes dans le module, sur la carte ainsi que dans une liste. 

La carte et la liste sont interactives. 

Il est possible de se déplacer et de zoomer dans la carte (avec la souris et la molette ou les bouton + et -).

Il est aussi possible de changer le fond de carte affiché.

.. image:: /utilisateur/imgs/02-occtax-layers.jpg

Les relevés affichés peuvent être filtrés. 

Le premier filtre permet de limiter les relevés à ceux contenant un taxon en particulier. 

Pour sélectionner un taxon, saisir au moins 3 lettres de l'espèce (en français ou en latin). 

Il est aussi possible de saisir les premières lettres de l'espèce et de la sous-espèce. 

.. image:: /utilisateur/imgs/02-occtax-filtersv2.png

Il est possible de filtrer la liste des taxons par règne, en affichant le filtre :

.. image:: /utilisateur/imgs/02-occtax-filters-regne.jpg

Il est possible d'afficher des filtres complémentaires, et de supprimer les filtres existants : 

.. image:: /utilisateur/imgs/02-occtax-filters-morev2.jpg

Cela permet de filtrer sur tous les champs du module : 

.. image:: /utilisateur/imgs/02-occtax-filters-more-tools.jpg

Selon les droits dont vous disposez, il est possible d'afficher, de modifier ou de supprimer un relevé : 

.. image:: /utilisateur/imgs/02-occtax-tools.jpg

Sur la liste, il est également possible de modifier les colonnes affichées :

.. image:: /utilisateur/imgs/02-occtax-modify-columns.png

.. image:: /utilisateur/imgs/02-occtax-modify-columns-2.png

    
2. Fonctionnalités du module
"""""""""""""""""

Ajouter un relevé
*****************

Si vous affichez un relevé, vous accéderez à sa fiche complète : 

.. image:: /utilisateur/imgs/03-occtax-detail.png

Si vous cliquez sur un des taxons observés dans ce relevé, cela affichera le détail de l'observation du taxon : 

.. image:: /utilisateur/imgs/03-occtax-detail-info.png

Vous pouvez aussi consulter les dénombrements du taxon observé : 

.. image:: /utilisateur/imgs/03-occtax-detail-counting.png

Il est aussi possible d'afficher les informations géographiques liées au relevé : 

.. image:: /utilisateur/imgs/03-occtax-detail-geo.png

Selon les droits dont vous disposez, il est possible de modifier ou supprimer un relevé directement depuis sa fiche Détail :

.. image:: /utilisateur/imgs/03-occtax-detail-edit.png

Afficher un relevé
******************

Depuis la liste des relevés, cliquer sur le bouton de création d'un relevé : 

.. image:: /utilisateur/imgs/05-occtax-create.png

Vous accédez alors à un formulaire de saisie à compléter : 

.. image:: /utilisateur/imgs/05-occtax-add.png

Commencez par localiser le relevé, sous forme de point (en cliquant sur la carte ou en saisissant les coordonnées GPS du point) : 

.. image:: /utilisateur/imgs/05-occtax-create-point.png

De ligne (en recliquant sur le dernier point de la ligne pour la terminer) : 

.. image:: /utilisateur/imgs/05-occtax-create-line.png

Ou de polygone (en recliquant sur le premier point du polygone pour le terminer) : 

.. image:: /utilisateur/imgs/05-occtax-create-polygon.png

Les localisations peuvent être modifiées. 

Pour les points, il suffit de les déplacer ou de recliquer ailleurs sur la carte. 

Pour les lignes et les polygones, il faut cliquer sur le bouton de modification. 

.. image:: /utilisateur/imgs/05-occtax-create-polygon-edit.jpg

Vous pouvez alors déplacer les sommets existants ou en créer de nouveaux pour affiner le tracé en cliquant sur les sommets transparents.

Cliquer sur ``SAVE`` pour enregistrer les modifications apportées à une ligne ou un polygone.

Les altitudes minimum et maximum du relevé sont calculées automatiquement mais peuvent être modifiées manuellement. 

Les informations géographiques du relevé (communes notamment) sont aussi calculées automatiquement.

Pour les afficher, il faut cliquer sur le bouton d'information : 

.. image:: /utilisateur/imgs/03-occtax-detail-geo-button.jpg

.. image:: /utilisateur/imgs/05-occtax-create-geo.jpg

Une fois les informations du relevé renseignées (observateurs, jeu de données, date et commentaire optionnel), 
vous pouvez ajouter un premier taxon à celui-ci en cliquant sur ``Ajouter un taxon sur ce relevé`` :

.. image:: /utilisateur/imgs/05-occtax-add-taxon.png

.. image:: /utilisateur/imgs/05-occtax-create-taxon.png

Pour sélectionner un taxon, saisissez au moins les 3 premières lettres de son nom latin ou français. 

Vous pouvez aussi saisir les 3 premières lettres de l'espèce et de la sous-espèce.

Renseignez ensuite les autres champs relatifs au taxon. Les valeurs proposées dans les listes dépendent 
du rang et du groupe du taxon selectionné : 

.. image:: /utilisateur/imgs/05-occtax-create-taxon-plus.png

Des valeurs par défaut sont renseignées pour certains.

Vous pouvez ensuite renseigner un ou plusieurs dénombrements pour le taxon observé. 

Par défaut, un dénombrement indéterminé d'un individu est renseigné : 

.. image:: /utilisateur/imgs/05-occtax-create-taxon-counting.png

Une fois le taxon renseigné, cliquer sur ``ENREGISTRER LE TAXON`` pour l'enregistrer :

.. image:: /utilisateur/imgs/05-occtax-create-taxon-save.png

Vous pouvez alors :

- Modifier le taxon enregistré
- Supprimer le taxon enregistré
- Ajouter un autre taxon au relevé
- Enregistrer le relevé pour revenir à la liste des relevés en cliquant sur [Terminer la saisie]

.. image:: /utilisateur/imgs/05-occtax-create-taxon-finish.png

Pour ajouter un taxon au relevé, il faut cliquer sur ``Editer le relevé`` puis sur ``Enregistrer et saisir des taxons`` et renseigner le formulaire comme le précédent :

.. image:: /utilisateur/imgs/05-occtax-create-taxon-2.png


Modifier un relevé
******************

Si vous modifiez un relevé existant, vous accédez à sa fiche renseignée, sur laquelle vous pouvez modifier la localisation, les informations du relevé, les taxons observés et leurs dénombrements : 

.. image:: /utilisateur/imgs/04-occtax-edit.png

Vous pouvez ajouter un taxon au relevé en cliquant sur ``Ajouter un taxon sur ce relevé`` : 

.. image:: /utilisateur/imgs/04-occtax-edit-taxon.png

Ou modifier une observation existante d'un taxon en le selectionnant dans la liste des taxons déjà enregistrés : 

.. image:: /utilisateur/imgs/04-occtax-edit-taxon-list.png

.. image:: /utilisateur/imgs/04-occtax-edit-taxon-2.png


Exporter un relevé
******************

Une fois que vous avez saisi vos relevés et observations depuis le formulaire, vous pouvez exporter ces données en CSV selon le standard Occurrence de taxon du SINP.

Deux méthodes sont possibles pour exporter les données :

- Depuis le module "Occtax"

Depuis la liste de vos relevés de l'interface carte-liste, filtrez d'abord vos relevés par **jeu de données** (ou autre) et cliquez sur le bouton ``Rechercher``. 

.. image:: /utilisateur/imgs/06-occtax-search-bar.png

Puis cliquez sur le bouton ``Télécharger les données`` en bas de la liste des relevés.

Une fenêtre s'ouvre, fournissant des informations sur le téléchargement des données. Selectionnez ensuite le format CSV pour GINCO :

.. image:: /utilisateur/imgs/06-occtax-download.png

- Depuis le module d'export : fonctionnalité en cours de développement !

