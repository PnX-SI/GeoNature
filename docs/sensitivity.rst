Gestion de la sensibilité
"""""""""""""""""""""""""

Introduction
````````````

Les régles de sensibilité définies par défaut sont issues des règles du SINP.
Elles dépendent de l'espèce et de l'observation. C'est-à-dire que pour une espèce donnée, 
plusieurs niveaux de sensibilité sont possibles selon l'observation.

Niveaux de sensibilité
^^^^^^^^^^^^^^^^^^^^^^

Voici les 5 niveaux de sensibilité définis par le SINP :

* Sensible - Aucune diffusion
* Sensible - Diffusion au département
* Sensible - Diffusion à la maille 10km
* Sensible - Diffusion à la Commune ou Znieff
* Non sensible - Diffusion précise

Dans certains cas, des demandes consistent à rendre l'entiereté des observations
d'une espèce (et donc une espèce) sensible.
Cette documentation propose une méthode pour y arriver dans l'outil GeoNature.

Pour plus d'informations
^^^^^^^^^^^^^^^^^^^^^^^^

Vous pouvez consulter :

- La page du site du `MNHN traitant de la sensibilité <https://inpn.mnhn.fr/programme/donnees-observations-especes/references/sensibilite>`_.
- Le rapport de 2020 sur `La sensibilité des données du système  d’information  de l’inventaire  du  patrimoine naturel : méthodes, pratiques et usages (J. Ichter et S. Robert) <https://inpn.mnhn.fr/docs-web/docs/download/355449>`_. 

Attention
`````````

L'objectif de ce document n'est pas de modifier les règles établies par
le SINP. Il est donc conseillé de respecter ces règles définies au niveau 
régional et national et donc de ne pas ajouter de règles locales.

Intégration dans GeoNature
``````````````````````````

Le référentiel de sensibilité fournie par l’INPN est normalement intégré
à GeoNature lors de son installation. Sinon, il peut être manuellement
intégré avec la commande :

.. code-block::

    (venv)$ geonature db upgrade ref_sensitivity_inpn@head

Schéma gn_sensitivity
^^^^^^^^^^^^^^^^^^^^^

3 tables sont utilisées par ces fonctions :

* ``t_sensitivity_rules`` qui relie notamment une espèce à un niveau de
  sensibilité
* ``cor_sensitivity_criteria`` qui permet d'appliquer ce niveau de
  sensibilité en fonction d'un critère (par défaut, biologique)
* ``cor_sensitivity_area`` qui permet d'appliquer un niveau de
  sensibilité en fonction de la zone géographique (pas encore abordée
  ici)

S'il n'y a aucune entrée dans ``cor_sensitivity_criteria``, le niveau de
sensibilité défini dans ``t_sensitivity_rules`` est appliqué peu importe
le statut biologique ou le comportement de l’occurence.
De même, s’il n’y a aucune entrée dans ``cor_sensitivity_area``, le niveau
de sensibilité est appliqué peu importe la localisation de l’observation.

Schéma gn_synthese
^^^^^^^^^^^^^^^^^^

A chaque insertion d'une donnée dans la table ``gn_synthese.synthese``,
un trigger (``tri_insert_calculate_sensitivity``) fait appel à une
fonction (``fct_tri_cal_sensitivity_on_each_statement``) qui appelle
elle-même la fonction ``gn_sensitivity.get_id_nomenclature_sensitivity``
pour le calcul de la sensibilité.

La fonction ``get_id_nomenclature_sensitivity`` calcule le niveau de
sensibilité en fonction de l'espèce, du type de sensibilité, de la durée
de validité, de la période d'observation, du statut biologique et du 
comportement de l’occurence.

Personnalisation
````````````````

Pour l'instant, seule la personnalisation de la sensibilité pour
une espèce donnée (peu importe l'observation) est abordée ici.

Sensibilité de l'espèce toute observation confondue
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

#. Dans ``gn_sensitivity.t_sensitivity_rules`` : Changez le niveau de
   sensibilité ``id_nomenclature_sensitivity`` par celui désiré. Pour la
   valeur à renseigner, voir dans ``t_nomenclature`` en filtrant avec
   ``id_type=ref_nomenclatures.get_id_nomenclature_type('SENSIBILITE')``.
   En général l'identifiant varie entre 65 (non sensible) et 69
   (aucune diffusion). Attention ces identifiants peuvent varier en fonction de 
   votre installation.
#. Dans ``cor_sensitivity_criteria`` : s'il y a une correspondance
   d'``id_sensitivity`` avec ``t_sensitivity_rules``, modifiez ou supprimez cette ligne.
#. Lancez la commande SQL suivante :

   .. code-block:: sql

       REFRESH MATERIALIZED VIEW gn_sensitivity.t_sensitivity_rules_cd_ref;

   Pour rafraîchir la vue materialisée utilisée par les fonctions
   appelées par le trigger de ``gn_synthese.synthese``.
#. Il est maintenant nécessaire de mettre à jour la sensibilité de vos
   observations présentent dans la synthèse. Pour cela, lancez la commande suivante :

   .. code-block::

      (venv)$ geonature sensitivity update-synthese

Normalement, les valeurs dans la colonne ``id_nomenclature_sensitivity``
de la table ``gn_synthese.synthese`` ont
changé. Vous pouvez le vérifier en navigant dans le module Synthèse
puis dans les détails d'une observation de votre/vos espèce(s).
