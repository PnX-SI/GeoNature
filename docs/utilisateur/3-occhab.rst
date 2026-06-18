.. Module OccHab : Saisir des occurences d'habitats

Module OccHab : Saisir des occurences d'habitats
================================================

1. Description du module
------------------------

Ce module permet de saisir des données selon le standard Occurrence d'habitat du SINP.

Les données sont organisées en relevés (localisation, jeu de données, date, observateur...) qui sont composés d'observations 
d'un ou plusieurs habitats.

Chaque relevé est associé à un jeu de données. Pour saisir dans un jeu de données, il faut donc que vous ayez créé au 
préalable les jeux de données dans l'application Métadonnées (MTD) du SINP.

Quand on accède au module OccHab, celui-ci affiche vos données présentes dans le module, sur la carte ainsi que dans une liste. La carte et la liste sont interactives. 

.. image:: ../../../_static/img/occhab/occhab_1_module.png

Il est possible de : 

* se déplacer et de zoomer dans la carte (avec la souris et la molette ou les bouton + et -). 
* changer le fond de carte affiché.
* faire apparaître plus de filtre pour faire une recherche sur les habitats en cliquant sur le bouton 

.. image:: ../../../_static/img/occhab/occhab_2_filtrer.png

* télécharger les habitats des stations en cliquant sur le bouton en bas à droite de la liste

.. image:: ../../../_static/img/occhab/occhab_4_export.png

* afficher sur la carte un habitat en particulier en cliquant sur la liste 

Selon les droits dont vous disposez, il est possible d’afficher, de modifier ou de supprimer un relevé :

.. image:: ../../../_static/img/occtax/02-occtax-tools.jpg


2. Fonctionnalités du module
----------------------------

Ajouter un relevé
"""""""""""""""""

Depuis la liste des relevés, cliquer sur le bouton de création d'une nouvelle station d'habitat : 

.. image:: ../../../_static/img/occhab/occhab_5_ajouter.png

Vous accédez alors à un formulaire de saisie à compléter : 

.. image:: ../../../_static/img/occhab/occhab_5_formulaire_saisi.png

Commencez par localiser le relevé, sous forme :

1. De **point** (en cliquant sur la carte ou en saisissant les coordonnées GPS du point) : 

.. image:: ../../../_static/img/occtax/05-occtax-create-point.png

2. De **ligne** (en recliquant sur le dernier point de la ligne pour la terminer) : 

.. image:: ../../../_static/img/occtax/05-occtax-create-line.png

3. Ou de **polygone** (en recliquant sur le premier point du polygone pour le terminer) : 

.. image:: ../../../_static/img/occtax/05-occtax-create-polygon.png

Les localisations peuvent être modifiées : 

1. Pour les **points**, il suffit de les déplacer ou de recliquer ailleurs sur la carte. 

2. Pour les **lignes** et les **polygones**, il faut cliquer sur le bouton de modification. 

.. image:: ../../../_static/img/occtax/05-occtax-create-polygon-edit.jpg


Vous pouvez alors déplacer les sommets existants ou en créer de nouveaux pour affiner le tracé en cliquant sur les sommets transparents.

.. note:: Cliquer sur ``SAVE`` pour enregistrer les modifications apportées à une ligne ou un polygone.

Les altitudes minimum et maximum du relevé sont calculées automatiquement mais peuvent être modifiées manuellement. 

Les informations géographiques du relevé (communes notamment) sont aussi calculées automatiquement.

Pour les afficher, il faut cliquer sur le bouton d'information : 

.. image:: ../../../_static/img/occtax/03-occtax-detail-geo-button.jpg

.. image:: ../../../_static/img/occtax/05-occtax-create-geo.jpg

Une fois les informations de la station renseignées (observateurs, jeu de données, date et commentaire optionnel), 
vous pouvez ajouter un premier habitat à la station en cliquant sur ``Ajouter un habitat à la station`` :

.. image:: ../../../_static/img/occhab/occhab_5_habitat_ajout.png

Pour sélectionner un habitat, saisissez au moins les 3 premières lettres de son nom latin ou français. Le champ `habitat` peut être filtrer par sa typologie en cliquant sur le bouton situé à droite du champ.
Renseignez ensuite les autres champs relatifs à l'habitat. Des valeurs par défaut sont renseignées pour certains.

Une fois l(habitat renseigné, cliquer sur ``VALIDER CET HABITAT`` pour l'enregistrer : 

.. image:: ../../../_static/img/occhab/occhab_5_habitat_valider.png

Vous pouvez alors :

- Modifier l'habitat enregistré
- Supprimer l'habitat enregistré
- Ajouter un autre habitat à la station
- Enregistrer la station pour revenir à la liste des relevés.

Pour ajouter un habitat à la station, il faut cliquer sur ``Ajouter un habitat sur cette station`` et le renseigner comme le précédent. 

Afficher un relevé
""""""""""""""""""

Pour afficher une station, cliquer sur le bouton d'information. Vous accéderez à la fiche complète.

.. image:: ../../../_static/img/occhab/occhab_6_afficher.png

Si vous cliquez sur un des habitats observés sur cette station, cela affichera le détail de l'observation de l'habitat : 

.. image:: ../../../_static/img/occhab/occhab_6_detail.png

Selon les droits dont vous disposez, il est possible de modifier et de supprimer un relevé directement depuis sa fiche Détail : 

.. image:: ../../../_static/img/occhab/occhab_6_actions.png

Modifier un relevé
""""""""""""""""""

Si vous modifiez un relevé existant, vous accédez à sa fiche renseignée, sur laquelle vous pouvez modifier 

1. La localisation,
2. L'habitat observé,
3. Les informations de la station
4. Vous pouvez ajouter un habitat sur la station en cliquant sur ``Ajouter un habitat à la station``

.. image:: ../../../_static/img/occhab/occhab_7_modifier.png


Exporter un relevé
""""""""""""""""""

Une fois que vous avez saisi vos stations et observations depuis le formulaire, vous pouvez exporter ces données en CSV selon le standard Occurrence d'habitat du SINP.

Pour exporter les données depuis le module "OccHab" : 

1. Depuis la liste de vos stations de l'interface carte-liste, filtrez d'abord par **jeu de données** (ou autre) et cliquez sur le bouton ``Rechercher``. 
2. Puis cliquez sur le bouton ``Télécharger les données`` en bas de la liste des relevés.
3. Une fenêtre s'ouvre, fournissant des informations sur le téléchargement des données. Selectionnez ensuite le format CSV pour GINCO :

.. image:: ../../../_static/img/occhab/occhab_4_export.png



