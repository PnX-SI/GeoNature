Gestion de la sensibilité
-------------------------

Introduction
""""""""""""

Les régles de sensibilité définies par défaut sont issues des règles du SINP.
Elles dépendent de l'espèce et de l'observation. C'est-à-dire que pour une espèce donnée,
plusieurs niveaux de sensibilité sont possibles selon l'observation.

Critères de sensibilité
```````````````````````

* Taxon
* Emplacement
* Ancienneté
* Période de l’année
* Statut biologique
* Comportement de l’occurence

Certaines règles de sensibilité peuvent porter uniquement sur l’espèce,
rendant l’entièreté des observations d’une espèce (et donc une espèce) sensible.

Niveaux de sensibilité
``````````````````````

Voici les 5 niveaux de sensibilité définis par le SINP :

* Sensible - Aucune diffusion
* Sensible - Diffusion au département
* Sensible - Diffusion à la maille 10km
* Sensible - Diffusion à la Commune ou Znieff
* Non sensible - Diffusion précise

Pour plus d'informations
````````````````````````

Vous pouvez consulter :

- La page du site du `SINP traitant de la sensibilité <https://inpn.mnhn.fr/programme/donnees-observations-especes/references/sensibilite>`_.
- Le rapport de 2020 sur `La sensibilité des données du système  d’information  de l’inventaire  du  patrimoine naturel : méthodes, pratiques et usages (J. Ichter et S. Robert) <https://inpn.mnhn.fr/docs-web/docs/download/355449>`_.


.. warning::
    L'objectif de ce document n'est pas de modifier les règles établies par
    le SINP. Il est donc conseillé de respecter ces règles définies au niveau
    régional et national et donc de ne pas ajouter de règles locales.

Intégration dans GeoNature
""""""""""""""""""""""""""

Stockage des règles en base
````````````````````````````

Les règles de sensibilité sont stockées dans le schéma ``gn_sensitivity``
qui contient 3 tables :

* ``t_sensitivity_rules`` qui relie notamment une espèce à un niveau de
  sensibilité
* ``cor_sensitivity_criteria`` qui permet de restreindre une règle de
  sensibilité en fonction d'un critère (par exemple, statut biologique)
* ``cor_sensitivity_area`` qui permet de restreindre une règle de
  sensibilité à une zone géographique

S'il n'y a aucune entrée dans ``cor_sensitivity_criteria``, le niveau de
sensibilité défini dans ``t_sensitivity_rules`` est appliqué peu importe
le statut biologique ou le comportement de l’occurence.
De même, s’il n’y a aucune entrée dans ``cor_sensitivity_area``, le niveau
de sensibilité est appliqué peu importe la localisation de l’observation.
À l’inverse, s’il y a plusieurs entrées, la sensibilité est appliquée dès
que l’un des critères ou l’une des zones correspond à l’observation.

Si des règles de sensibilité sont définies avec des conditions de critères 
sur une nomenclature (Statut biologique ou Comportement), 
alors ces règles sont appliquées aussi si la nomenclature n'est pas renseignée 
(par principe de précaution), en associant aussi des critères à ces règles 
(dans la table `gn_sensitivity.cor_sensitivity_criteria`) pour les valeurs 
de nomenclature "Non renseigné", "Ne sait pas", "Indéterminé",... 
(https://github.com/PnX-SI/GeoNature/blob/30c27266495b4affc635f79748c9984feb81a6d7/backend/geonature/core/sensitivity/utils.py#L37-L54).

Certaines règles sont définies non pas pour une espèce donnée mais pour un
rang supérieur. Ces règles sont artificiellement dupliquées pour chaques espèces
sous-jacentes dans la vue matérialisée ``t_sensitivity_rules_cd_ref``.
Il est nécessaire de la rafraichir lors de l’évolution du référentiel
de sensibilité.

Attribution aux observations de la synthèse
```````````````````````````````````````````

La sensibilité des observations de la synthèse est stockée dans la
colonne ``id_nomenclature_sensitivity``.

A chaque insertion d'une donnée dans la table ``gn_synthese.synthese``,
un trigger (``tri_insert_calculate_sensitivity``) fait appel à une
fonction (``fct_tri_cal_sensitivity_on_each_statement``) qui appelle
elle-même la fonction ``gn_sensitivity.get_id_nomenclature_sensitivity``
pour le calcul de la sensibilité.

Gestion du référentiel
``````````````````````

GeoNature fournit la commande ``geonature sensitivity`` pour gérer son référentiel
de sensibilité :

* ``geonature sensitivity info`` : statistiques sur les règles présentes
* ``geonature sensitivity add-referential`` : import de nouvelles règles
* ``geonature sensitivity remove-referential`` : suppression de règles
* ``geonature sensitivity refresh-rules-cache`` : mise à jour de la vue matérialisées des règles
* ``geonature sensitivity update-synthese`` : recalcul de la sensibilité des observations de la synthèse

Le référentiel de sensibilité fourni par le SINP est normalement intégré
à GeoNature lors de son installation. Sinon, il peut être manuellement
intégré ou mis à jour avec l’une ou l’autre des commandes suivantes (selon votre version de Taxref) :

Taxref v17 :
   .. code-block:: bash

      geonature sensitivity add-referential \
               --source-name "Référentiel sensibilité TAXREF v17 20240325" \
               --url https://geonature.fr/data/inpn/sensitivity/RefSensibiliteV17_20240325.zip \
               --zipfile RefSensibiliteV17_20240325.zip \
               --csvfile RefSensibilite_17.csv  \
               --encoding=utf-8

Taxref v16 :
   .. code-block:: bash

      geonature sensitivity add-referential \
               --source-name "Référentiel sensibilité TAXREF v16 20230203" \
               --url https://geonature.fr/data/inpn/sensitivity/RefSensibiliteV16_20230203.zip \
               --zipfile RefSensibiliteV16_20230203.zip \
               --csvfile RefSensibiliteV16_20230203/RefSensibilite_16.csv  \
               --encoding=iso-8859-15

Taxref v15 :
   .. code-block:: bash

      geonature sensitivity add-referential \
               --source-name "Référentiel sensibilité TAXREF v15 20220331" \
               --url https://inpn.mnhn.fr/docs-web/docs/download/401875 \
               --zipfile RefSensibiliteV15_20220331.zip \
               --csvfile RefSensibilite_V15_31032022/RefSensibilite_15.csv  \
               --encoding=iso-8859-15

Taxref v14 :
   .. code-block:: bash

      geonature sensitivity add-referential \
               --source-name "Référentiel sensibilité TAXREF v14 20220331" \
               --url https://inpn.mnhn.fr/docs-web/docs/download/401876 \
               --zipfile RefSensibiliteV14_20220331.zip \
               --csvfile RefSensibilite_V14_31032022/RefSensibilite_14.csv  \
               --encoding=iso-8859-15

Le jeu de règles est fourni pour chaque version précise de Taxref, certaines
espèces sensibles pouvant voir leur *cd_nom* changer d’une version à l’autre.

Si vous mettez à jour votre version du référentiel de sensibilité, il faut ensuite relancer 
le calcul des règles de sensibilité avec la commande ``geonature sensitivity refresh-rules-cache``.

Personnalisation
````````````````

Pour l'instant, seule la personnalisation de la sensibilité pour
une espèce donnée (peu importe l'observation) est abordée ici.

#. Dans ``gn_sensitivity.t_sensitivity_rules`` : Changez le niveau de
   sensibilité ``id_nomenclature_sensitivity`` par celui désiré. Pour la
   valeur à renseigner, voir dans ``t_nomenclature`` en filtrant avec
   ``id_type=ref_nomenclatures.get_id_nomenclature_type('SENSIBILITE')``.
#. Dans ``cor_sensitivity_criteria`` : s'il y a une correspondance
   d'``id_sensitivity`` avec ``t_sensitivity_rules``, modifiez ou supprimez cette ligne.
#. Rafraichissez le cache des règles extrapolées aux espèces :

   .. code-block:: bash

    geonature sensitivity refresh-rules-cache

   Ceci est équivalent à lancer manuellement la commande SQL suivante :

   .. code-block:: sql

       REFRESH MATERIALIZED VIEW gn_sensitivity.t_sensitivity_rules_cd_ref

#. Il est maintenant nécessaire de mettre à jour la sensibilité de vos
   observations présentes dans la synthèse. Pour cela, lancez la commande suivante :

   .. code-block:: bash

      geonature sensitivity update-synthese

Les valeurs dans la colonne ``id_nomenclature_sensitivity`` des observations sensibles
de la table ``gn_synthese.synthese`` auront alors 
changé. Vous pouvez le vérifier en navigant dans le module Synthèse
puis dans les détails d'une observation de votre/vos espèce(s).

Utilisation
```````````

Un lien entre la synthèse et la sensibilité a été mis en place : le floutage des données sensibles.

L'objectif et de pouvoir donner accès aux utilisateurs à des données sensibles mais pas de façon précise.
C'est-à-dire, en fonction du niveau de sensibilité de l'observation, un utilisateur pourra voir uniquement 
l'observation à la maille de 10km par exemple.

Comme décrit ci-dessous, un paramètre en configuration a été ajouté pour donner la possibilité d'exclure 
toutes les données sensibles plutôt que de les flouter.

Implementation
^^^^^^^^^^^^^^

Basée sur le nouveau système de permissions (v2.13), l'implémentation dans ce système se résout à 
l'ajout d'un filtre : exclure/flouter les données sensibles.
Le choix entre l'exclusion et le floutage est défini par le paramètre en configuration : 

.. code-block:: toml

   [SYNTHESE]
   BLUR_SENSITIVE_OBSERVATIONS = true

Si ``BLUR_SENSITIVE_OBSERVATIONS=true`` alors les observations seront floutées. Sinon exclues.

L'exclusion des données sensibles est simple : si le filtre "exclure les données sensibles" est coché, 
l'utilisateur n'aura pas accès (pour un scope défini) aux données sensibles quelque soit leur niveau 
de sensibilité soit :

- Sensible - Diffusion à la Commune ou Znieff
- Sensible - Diffusion à la maille 10km
- Sensible - Diffusion au département
- Sensible - Aucune diffusion

Pour la suite de la documentation, le paramètre est considéré comme le suivant : ``BLUR_SENSITIVE_OBSERVATIONS=true``.
Donc toute donnée sensible avec restriction d'accès sera floutée.

Si ce filtre n'est pas activé, la récupération des données de la synthèse en backend reste inchangée.
En effet, l'ajout du floutage des données nuit forcément aux performances.

S'il est activé, une requête SQL est construite comme suit : 

.. image :: https://raw.githubusercontent.com/PnX-SI/GeoNature/develop/docs/images/blurring_query.svg

Le but est d'ajouter à la requête principale une sous-requête exécutant deux requêtes ``SELECT`` dans 
la table de synthèse afin de séparer les données précises des données floutées. Ensuite un ``UNION`` 
est fait afin de rassembler les données avec priorité sur les données précises.

Dans ces deux requêtes, les permissions ainsi que les filtres utilisateurs sont pris en comptes, donc 
l'utilisateur n'a pas obligatoirement accès à toutes les données, c'est à la charge de l'administrateur.
Le fait de prendre en compte les filtres dans chacune des deux requêtes permet une cohérence dans les 
résultats renvoyés par ces deux requêtes (car un ``LIMIT`` est souvent présent).

Ce floutage des données a été implémenté sur 3 routes de la synthèse : 

* ``/for_web``
* ``/vsynthese/<id_synthese>``
* ``/export_observations``

Des tests unitaires ont également été écrits.


Traitement des problématiques liés aux zonages
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

**Traitement de l'affichage en mode maille**

Il a été décidé d'exclure les données sensibles dont la géométrie floutée est plus grande que la 
maille affichée en mode maille dans la synthèse.

C'est-à-dire que si une observation est dégradée/floutée à la maille M10 (10km²) et que le mode maille 
affiche les observations regroupées dans les mailles de type M5 (5km), l'observation n'apparaitra dans 
aucune maille mais dans seulement dans la liste des observations.

Pour rappel la maille de regroupement pour affichage dans le mode maille est définie par le paramètre 
suivant :

.. code-block:: toml
   [SYNTHESE]
   AREA_AGGREGATION_TYPE = "M5"

Pour que ce filtrage soit effectué, il était nécessaire d'introduire une nouvelle colonne dans la table 
``ref_geo.bib_area_types`` : ``size_hierarchy`` qui permet d'ordonner les types de zones par leur 
taille moyenne. Pour les mailles cela est simple, pour les départements et les communes notamment 
utilisées pour flouter la donnée, cela est plus complexe. Leur taille a donc été donnée arbitrairement.
Le floutage des données est censé évoluer vers des zonages de floutage basées exclusivement sur des 
mailles. Le problème de la taille arbitraire ne sera alors plus d'actualité.


**Traitement des zonages associés**

L'introduction de la nouvelle colone ``size_hierarchy`` permet également d'afficher uniquement les 
zonages plus grands que la géométrie floutée dans l'onglet "Zonage" des détails d'une observation en 
synthèse. Par exemple, les mailles M1 (1km²) et M5 (5km²) d'une observation floutée à la maille M10 
(10km²) n'apparaitront pas. 


**Traitement du filtre de type "zonage"**

Pour rappel, ce filtre permet de rechercher si des observations intersectent des zones choisies par 
l'utilisateur. Ces zones sont disponibles dans la section "Où" dans le module Synthèse.

En backend, quand l'utilisateur voit les données précisément, le filtre fonctionne grâce à la 
table ``gn_synthese.cor_area_synthese``, évitant de procéder à l'appel de ``ST_Intersects`` plus lent.

Ce filtre fonctionne différemment quand l'utilisateur dispose de permissions floutant les 
données. En effet, un ``ST_Intersects`` est effectué sur la géométrie floutée car l'utilisation de 
``gn_synthese.cor_area_synthese`` pourrait donner trop d'informations à l'utilisateur et ce dernier 
pourrait obtenir des données plus précises que souhaité par recherche sur différentes communes alors
que l'observation est floutée au département par exemple.
