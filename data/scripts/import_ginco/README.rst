Scripts de migration GINCO -> GeoNature
=======================================

Ce dossier comprends plusieurs scripts permettant d'effectuer la migration des données de GINCO vers GeoNature.

* ``restore_ginco_db.sh``: Ce script restaure une BDD GINCO à partir d'un DUMP SQL, puis crée un Foreign Data Wrapper entre la base restaurée et la base GeoNature cible. Un nouveau schéma ``ginco_migration`` est créé, comportant les table des schéma ``website`` et ``raw_data`` de la base Ginco source
* ``insert_data.sh``: Ce script vient lire dans le FDW précedemment créé pour insérer les données en synthese.
* ``import_mtd.sh``: Script contenant un script python permettant de récupérer les cadres d'acquisitions et les informations détaillées de chaque JDD présent dans la base Ginco à partir du web-service MTD.
* ``find_conflicts.sql`` Script permettant de remonter les erreurs d'integrité des données sources (voir plus bas)
Désampler le fichier ``settings.ini.sample``, le remplir puis lancer les scripts dans l'ordre décrit ci-dessous. Pour chaque script un fichier de log est crée dans le répertoire ``log``.

Quels données sont rappatriées ?
********************************

- L'ensemble des organismes sont rappatriés depuis la table ``providers``. Les utilisateurs ne sont pas importé pour éviter les doublons lors de la connexion au CAS.
- Les jeux de données sont rappatriés depuis les tables ``jdd`` et ``jdd_fields`` vers la table ``gn_meta.t_datasets``. Les JDD taggués comme ``deleted`` ne sont pas importés. Le rattachement du JDD à son cadre d'acquisition ainsi que l'ensemble des informations liés aux métadonnées sont récupérées via le script ``import_mtd.sh``. Celui-ci insert également des organismes et des utilisateurs en récupérant les acteurs des JDD et CA.
- Les données d'occurrence de taxon présent dans la table ``raw_data.<NOM_DU_MODELE_GINCO>`` sont rappatriées dans la table ``gn_synthese.synthese``. Les données ne possédant pas de géomtrie, de cd_nom, appartenant à une JDD supprimés ou étant en doublon (UUID non unique dans la table source) ne sont pas intégrées.
- Une table ``ginco_migration.doublons`` a été créé pour repérer les données doublonnées. On y retrouve l'uuid et son nombre d'occurrence dans la table source.

Gestion des droits
*******************

L'ensemble des permissions présentes dans GINCO ne sont pas encore existantes dans GeoNature (voir les données publiques, voir les données sensible etc...).
Dans l'attente de ces évolutuons, deux groupes on été créee (reprenant des groupes existans dans GINCO):
- Un groupe "Administrateur": 
  C:3 R:3 U:3 V:3 E:3 D:3 sur tous les modules
  Accès aux module Occtax, Occhab, Metadata, Admin, Synthese, Validation
- Un groupe "Producteur":
    GeoNature / Synthese / Occtax / Occhab :
    C:3 R:2 U:1 V:0 E:2 D:1
    Metadonnées:
    C:0 R:2
    Pas d'accès: Validation, Admin

- Les personnes du groupe 'Administateur' on accès à Usershub et Taxhub avec un profil 'administateur'.
Après sa première connexion au CAS, l'administrateur devra se connecter à UserHub pour s'ajouter au groupe 'Administrateur'.

Version Taxref
**************

Ginco est actuellement en version Taxref 12. GeoNature ne s'installe lui qu'avec la version 11 ou 13 du référentiel. 
e script ``import_taxref/import_new_taxref_version.sh`` permet d'importer Taxref en version 12. Il doit être réalisé sur un GeoNature vierge de toute donnée pour ne pas créer de conflit d'integrité.

Erreurs d'integrité
*******************

Le script SQL ``find_conflicts.sql`` permet de créer des tables faisant remonter les erreurs d'intégrité.
En effet, durant le scripts d'insertion des données, plusieurs contraintes d'integrité on été désactivé et certaines données exclus pour que l'insertion dans la table synthese fonctionne.


- La table ``ginco_migration.cd_nom_invalid`` liste toutes les données dont le cd_nom est absent de la table ``taxonomie.taxref`` (en version 12)
- La table ``ginco_migration.cd_nom_null`` liste les données dont le cd_nom est null.
- La table ``ginco_migration.date_invalid`` liste les données dont la date fin est superieur à la date debut.
- La table ``ginco_migration.count_invalid`` liste les données dont la dénombrement max est superieur au dénombrement min.
- La table ``ginco_migration.doublons`` liste les données l'uuid n'est pas unique ainsi que leur nombre d'occurrence.

Après avoir corrigé les données dans la table ``gn_synthese.synthese``, vous pouvez réactiver les contraintes suivantes:

:: 

    ALTER TABLE gn_synthese.synthese
    ADD CONSTRAINT check_synthese_count_max CHECK (count_max >= count_min);

    ALTER TABLE gn_synthese.synthese
   ADD CONSTRAINT check_synthese_date_max CHECK (date_max >= date_min);


Connexion au CAS INPN
*********************

Le paramètre ``BDD.ID_USER_SOCLE_1`` contrôle le groupe (et donc les droits) de toute nouvelle personne se connecter à la plateforme via la CAS INPN. 
Mettre l'id du groupe producteur auquel on a affecté des droits (voir plus haut).

Autre configuration
====================
- Carto 
- Limiter le nombre d'observation dans le module validation 
- Monter le timeout gunicorn