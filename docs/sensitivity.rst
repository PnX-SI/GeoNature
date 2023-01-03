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
rendant l’entiereté des observations d’une espèce (et donc une espèce) sensible.

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
À l’inverse, s’il y a plusieurs entrées, la sensibilité est appliqué dès
que l’un des critères ou l’une des zones correspond à l’observation.

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
intégré avec l’une ou l’autre des commandes suivantes :

TaxRef v15 :

.. code-block::

    geonature sensitivity add-referential \
            --source-name "Référentiel sensibilité TAXREF v15 20220331" \
            --url https://inpn.mnhn.fr/docs-web/docs/download/401875 \
            --zipfile RefSensibiliteV15_20220331.zip \
            --csvfile RefSensibilite_V15_31032022/RefSensibilite_15.csv  \
            --encoding=iso-8859-15

TaxRef v14 :

.. code-block::

    geonature sensitivity add-referential \
            --source-name "Référentiel sensibilité TAXREF v14 20220331" \
            --url https://inpn.mnhn.fr/docs-web/docs/download/401876 \
            --zipfile RefSensibiliteV14_20220331.zip \
            --csvfile RefSensibilite_V14_31032022/RefSensibilite_14.csv  \
            --encoding=iso-8859-15

Le jeu de règles est fourni pour les versions 14 et 15 de TaxRef, certaines
espèces sensibles pouvant voir leur cd_nom changé d’une version à l’autre.

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

Actuellement, le niveau de sensibilité des observations n’est pas exploité par GeoNature.
Le floutage des observations en fonction de leur niveau de sensibilité est une fonctionnalité
souhaitée mais pas encore présente dans GeoNature.
