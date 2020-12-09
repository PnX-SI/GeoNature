================
API DOCS (draft)
================

Api post synthese
=================

 
Le format d'échange
-------------------

Les données d'une ligne de la synthèse sont constituées d'une géométrie et de données associées.
On considère ici un un format de type ``GEOJSON``.

.. code-block:: JSON


  {
      "type":	"Feature"
      "id":	"2"
      "geometry":	{
          "type":	"Point"
          "coordinates": [6.5, 44.85]
      },
      "properties": {	
          "id_synthese":	2
  ...


* Un exemple complet est donné `dans cet exemple <./api_exemple.rst>`_

* Données de type nomenclature

  * La nomenclature reprend la nomenclare de l'inpn ()
  * Tous les champs de type nomenclature (dont le nom commence par ``id_nomenclature_<nom_nomenclature>`` sont remplacés par des champs dont le nom est de la forme ``cd_nomenclature_<nom_nomenclature>``
  * Ces champs contiennent le code des nomenclatures et non les id des nomenclatures.
  * Ces champs spnt facultifs et ont tous une valeur par défaut en base (à confirmer).

      * Cependant l'information qu'ils contiennent reste essentielle 
      * et il est important de passer du temps pour choisir des valeurs pertinentes.

* Les jeux de données et sources sont précicés par  ``id_dataset`` et ``id_source``.
  
  * Les JDD doivent être renseignés dans le module ``métadonnées``
  * Une route permettant de poster/modifier une source est présentée ci-dessous


Les routes
----------

* Synthese :

  * ``GET`` : récupère une ligne de la synthèse au format d'échange
    
    * ``/exchanges/synthese/<int:id_synthese>``: à partir de la clé primaire ``id_synthese``
    * ``/exchanges/synthese/<string:unique_id_sinp>`` : à partir de l'uuid
    * ``/exchanges/synthese/<int:id_source>/<int:entity_source_pk_value>`` : à partir du couple ``(id_source, entity_source_pk_value)``

  * ``DELETE`` : supprime une ligne de la synthèse au format d'échange
    
    * ``/exchanges/synthese/<int:id_source>/<int:entity_source_pk_value>`` : à partir du couple ``(id_source, entity_source_pk_value)``

  * ``POST`` : pour mettre une nouvelle donnée, modifier une donnée existante
    
    * ``/exchanges/synthese/``: 
      
      * les données ``post_data`` doivent être au format d'échange

  * `` PATCH``

    * ``/exchanges/synthese/<int:id_synthese>``: à partir de la clé primaire ``id_synthese``
    * ``/exchanges/synthese/<string:unique_id_sinp>`` : à partir de l'uuid
    * ``/exchanges/synthese/<int:id_source>/<int:entity_source_pk_value>`` : à partir du couple ``(id_source, entity_source_pk_value)``

      * les données ``post_data`` doivent être au format d'échange


* Source : 
  

  * GET : ``/exchanges/sources``

      * Renvoie la liste de toutes les sources.

  * ``GET/DELETE`` : ``/exchanges/source/<int:id_source>``
  * ``POST/PATCH`` : ``/exchanges/source/``
    
    * exemple de données : 

.. code-block:: JSON

    {
        'name_source': 'Source test',
        'desc_source': 'Ceci est une source de test',
        'entity_source_pk_field': 'id_bidule',
        'url_source': '???'
    }


Les erreurs
-----------

En cas d'erreur, la route revoie une réponse ``status_code=500``.

Les données renvoyées sont de la forme: ``{msg, code, data}``

Avec :

* ``msg`` : message qui explicite l'erreur
* ``code`` : code qui permet d'identifier l'erreur
* ``data`` : données qui peuvent être utiles à la résolution de l'erreur, par exemple la liste des nomenclature le cas échéant.

Les codes correspondent au cas suivants:

* ``1`` : pas de correspondance trouvée pour au moins un des codes nomenclature fourni 
* ``2`` : pas de source trouvée pour l'id_source fourni
* ``3`` : pas de JDD trouvé pour l'id_dataset fourni 

TODO
====

* Renseigner des utilisateurs à partir des ``id_role``
  * ajout d'une relation ``observers`` au modèle
* ``from_dict`` -> schémas
* Lien url vers  la source dans la fiche synhtèse ???
