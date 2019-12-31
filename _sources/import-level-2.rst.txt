IMPORT NIVEAU 2
===============

Description
-----------

L'exercice consiste à importer le fichier 
https://github.com/PnX-SI/Ressources-techniques/blob/master/GeoNature/V2/import-avance/observations.csv dans GeoNature V2.

1 - On charge le fichier CSV dans une table de la base de données.

2 - On prépare la table importée (FK et typage des champs si besoin).

3 - On créé les métadonnées pour que GeoNature sache identifier les nouvelles données.

4 - On mappe les champs de la table d'import avec ceux de la synthèse. 

    Pour cela on utilise une fonction dédiée qui nous prépare le travail. Il ne reste plus qu'à finaliser le mapping (la fonction ne peut pas tout deviner).

5 - On crée la requête d'import. 

    Pour cela on utilise une fonction dédiée qui nous prépare le travail. On adapte la requête produite par la fonction.
    
6 - On importe les données en synthèse.

7 - On gère les nouveaux taxons vis à vis la saisie.

8 - On archive la table où on veut.


1 - Import du fichier CSV
-------------------------

Cette action doit être faite par un superuser PostgreSQL.

:notes:

    * Le fichier CSV doit être présent localement sur le serveur hébergeant la base de données.
    * Il fichier doit être encodé en UTF-8 et la première ligne doit comporter le nom des champs.
    * Le séparateur de champs doit être le point-virgule.
    * La fonction utilise la fonction ``COPY`` capable de lire le système de fichier du serveur. Pour des raisons de sécurité, cette fonction ``COPY`` n'est accessible qu'aux superutilisateurs. Vous devez donc disposer d'un accès superutilisateur PostgreSQL pour utiliser cette fonction d'import. Si l'utilisateur connecté à la base dans pgAdmin n'est pas superuser, on peut le faire dans psql.

DANS UN TERMINAL : 

.. code:: sh

    sudo su postgres
    psql -d geonature2db

Dans les 2 cas, copier-coller les 2 commandes ci-dessous en adaptant les chemins et l'utilisateur.

.. code:: sql

    SELECT gn_imports.load_csv_file('/home/myuser/imports/observations.csv', 'gn_imports.testimport');
    ALTER TABLE gn_imports.testimport OWNER TO geonatuser;

:notes:

    * Attention : si la table existe, elle est supprimée et recréée à partir du CSV fourni.
    * La fonction créé la table et sa structure dans le schéma et la table fournie en paramètre.
    * Le contenu du fichier CSV est chargé dans la table (initialement toutes les colonnes sont de type ``text``).
    * La function tente ensuite d'identifier et de modifier le type de chacune des colonnes à partir du contenu et seuls les types ``integer``, ``real``, et ``date`` sont actuellement reconnus. 
    * Si vous devez modifier manuellement le type d'une colonne, vous pouvez vous inspirer du code ci-dessous.


2 - Préparation de la nouvelle table contenant les données importées
--------------------------------------------------------------------

**Ajouter une clé primaire sur la table importée**

.. code:: sql

    ALTER TABLE gn_imports.testimport ADD PRIMARY KEY (id_data);

Si la table ne comporte pas de champ permettant une identification unique des observations :

.. code:: sql

    ALTER TABLE gn_imports.testimport
      ADD COLUMN gid serial;

    ALTER TABLE gn_imports.testimport
      ADD CONSTRAINT pk_testimport PRIMARY KEY(gid);

**Si besoin de mettre à jour le type de certains champs de la table importée**

.. code:: sql

    ALTER TABLE monschema.matable ALTER COLUMN macolonne TYPE montype USING macolonne::montype;

En l'état vos données sont importées et stockées dans la base GeoNature. Cependant GeoNature ne connait pas ces données. Pour qu'elles soient utilisables, au moins en consultation, vous devez fournir à l'application GeoNature un certain nombre d'informations concernant ces données et à minima les importer dans la synthèse. Vous pouvez également les importer dans un autre module, comme "Occtax" (non abordé dans cet exemple).


3 - Création des métadonnées
----------------------------

Il est nécessaire de rattacher les données importées à un jeu de données qui doit appartenir à un cadre d'acquisition. Si ceux-ci n'ont pas encore été créés dans la base, vous devez le faire dans ``gn_meta.t_acquisition_frameworks`` pour le cadre d'acquisition et dans ``gn_meta.t_datasets`` pour le jeu de données. Vous pouvez pour cela utiliser les formulaires disponibles dans l'interface d'aministration de GeoNature : http://myurl/geonature/#/admin

Le jeu de données doit être rattaché à un protocole décrivant la manière dont les données ont été collectées.

:notes:

    Noter les ID retournés lors des insertions.
    
.. code:: sql

    INSERT INTO gn_meta.sinp_datatype_protocols ( protocol_name, protocol_desc, id_nomenclature_protocol_type, protocol_url)
    VALUES ('ATBI', 'Inventaire ATBI Dans la réserve de Lauvitel - Date_debut : 2013-01-01 - Date_fin : 3000-01-01', 395, NULL) returning id_protocol;

.. code:: sql

    INSERT INTO gn_meta.t_datasets(id_acquisition_framework, dataset_name, dataset_shortname, dataset_desc, id_nomenclature_data_type, keywords, marine_domain, terrestrial_domain, active)
    VALUES (1, 'Observations Flavia 2017', 'Observations Flavia 2017', 'Données ATBI Flavia pour l''année 2017', 326, 'Invertébrés, PNE, ATBI', FALSE, TRUE, TRUE) returning id_dataset;

Il est également nécessaire, pour la synthese, de lui indiquer où sont stockées les données qu'elle contient et comment y accèder. Vous devez pour cela disposer d'une source de données dans ``gn_synthese.t_sources`` correspondant aux données à importer. Pour l'exemple nous allons créer une source de données avec la commande SQL suivante :

.. code:: sql

    INSERT INTO gn_synthese.t_sources(name_source, desc_source)
    VALUES('ATBI', 'Données d''inventaire ATBI') returning id_source;

:notes:

    * D'autres valeurs sont attendues mais pour l'exercice, le fichier source utilise des valeurs insérée à titre d'exemple lors de la création de la base GeoNature.
    * ``id_role`` 3 et 4 dans ``utilisateurs.t_roles``
    * ``id_organisme`` 1 dans ``utilisateurs.bib_organismes``

:notes:

    Il est possible d'utiliser ce mécanisme générique pour insérer des données de n'importe quelle table vers n'importe quelle autre, à partir du moment où il est possible d'établir un mapping cohérent entre les champs et notamment que les types puissent correspondre ou soient "transtypables".


4 - Création du mapping (source --> cible)
------------------------------------------

Le schéma gn_imports comporte trois tables permettant de préparer le mapping des champs entre la table importée (source) et une table de destination (target).

* ``gn_imports.matching_tables`` permet de déclarer la table source et la table de destination. Noter le ``id_matching_table`` généré par la séquence lors de l'insertion d'un nouveau "matching" dans cette table.
* ``gn_imports.matching_fields`` permet de faire le matching entre les champs de la table source et de la table de destination. Vous devez indiquer le type de chacun des champs de la table de destination ainsi que le ``id_matching_table``.
* ``gn_imports.matching_geoms`` permet de préparer la création du geom dans la table de destination à partir du ou des champs constituant le geom fourni dans la table source : champs contenant les x et y pour un format ``xy`` ou le champ comportant le wkt pour le format ``wkt``.

En attendant la création d'une interface permettant de faciliter l'import, vous devez remplir ces tables manuellement. Cependant, la fonction ``gn_imports.fct_generate_mapping('table_source', 'table_cible', forcedelete)`` permet de pré-générer un mapping. 

Si le mapping source/cible existe, la fonction ne fait rien et un message d'erreur est levé. Si le mapping n'existe pas ou si le paramètre ``forcedelete (boolean default = false)`` est à ``true``, la fonction crée le mapping en remplissant la table ``gn_imports.matching_tables`` et la table``gn_imports.matching_fields`` avec une ligne par champ de la table cible. Il ne vous reste plus qu'à manuellement supprimer ou remplacer les valeurs 'replace me' dans le champs source_field ou les valeurs par défaut proposées par la fonction.

**Pré-générer les champs à mapper**

.. code:: sql

    SELECT gn_imports.fct_generate_matching('gn_imports.testimport', 'gn_synthese.synthese');
    SELECT gn_imports.fct_generate_matching('gn_imports.testimport', 'gn_synthese.cor_observer_synthese');

OU si besoin d'écraser un mapping des champs existants

.. code:: sql

    SELECT gn_imports.fct_generate_matching('gn_imports.testimport', 'gn_synthese.synthese', true);
    SELECT gn_imports.fct_generate_matching('gn_imports.testimport', 'gn_synthese.cor_observer_synthese',true);

IL FAUT ICI METTRE A JOUR LA TABLE ``gn_imports_matching_fields`` pour établir manuellement la correspondance des champs entre la table source et la table cible (voir le mapping final pour le fichier CSV fourni en exemple à la fin de cette page).

:notes:

    * Au moins un des 2 champs ``source_field`` ou ``source_default_value`` doit être renseigné.
    * Si le champ ``source_field`` est renseigné, le champ ``source_default_value`` est ignoré.

Une fois que le mapping est renseigné, vous pouvez passer à l'étape suivante.


5 - Construire la requête d'import
----------------------------------

Attention, pgAdmin va tronquer le résultat. Pour obtenir l'ensemble de la requête utiliser le bouton d'export du résultat dans un fichier ou executé la requête avec psql.

**Génération de la requête d'import dans les tables de destination**

.. code:: sql

    SELECT gn_imports.fct_generate_import_query('gn_imports.testimport', 'gn_synthese.synthese');
    SELECT gn_imports.fct_generate_import_query('gn_imports.testimport', 'gn_synthese.cor_observer_synthese');

:notes:

    UTILISER LE BOUTON D'EXPORT DU RESULTAT DE LA REQUETE DE PGADMIN ou utiliser psql.
    IL EST NECESSAIRE D'ADAPTER LA REQUETE SI BESOIN DE FAIRE DES JOIN POUR RECUPERER DES VALEURS DANS D'AUTRES TABLES


6 - Chargement des données dans la table de destination (synthese ici)
----------------------------------------------------------------------

Voir la requête d'import en synthèse à la fin de cette page.


7 - On gère les nouveaux taxons vis à vis la saisie
---------------------------------------------------

Gestion des taxons dans ``taxonomie.bib_noms`` et de la liste des taxons saisissables dans Occtax.

Cette étape est optionnelle et va permettre de rajouter les nouveaux taxons intégrés dans la synthèse dans la table des taxons de votre territoire (``taxonomie.bib_noms``) et dans la liste des taxons saisissables dans Occtax (``cor_nom_liste``).

**Création d'une table temporaire**

.. code:: sql

    CREATE TABLE gn_imports.new_noms
    ( 
      cd_nom integer NOT NULL, 
      cd_ref integer NOT NULL, 
      nom_fr character varying, 
      array_listes integer[],
      CONSTRAINT new_noms_pkey PRIMARY KEY (cd_nom)
    );

**Insertion des nouveaux taxons dans cette table et calcul des listes**

.. code:: sql

    TRUNCATE TABLE gn_imports.new_noms;
    INSERT INTO gn_imports.new_noms
    SELECT DISTINCT 
      i.cd_nom, 
      t.cd_ref, 
      split_part(t.nom_vern, ',', 1),
      array_agg(DISTINCT l.id_liste) AS array_listes
    FROM gn_imports.testimport i
    LEFT JOIN taxonomie.taxref t ON t.cd_nom = i.cd_nom
    LEFT JOIN taxonomie.bib_listes l ON id_liste = 100
    WHERE i.cd_nom NOT IN (SELECT cd_nom FROM taxonomie.bib_noms)
    GROUP BY i.cd_nom, t.cd_ref, nom_vern;

**Insertion dans ``bib_noms``**

.. code:: sql

    SELECT setval('taxonomie.bib_noms_id_nom_seq', (SELECT max(id_nom) FROM taxonomie.bib_noms), true);
    INSERT INTO taxonomie.bib_noms(cd_nom, cd_ref, nom_francais)
    SELECT cd_nom, cd_ref, nom_fr FROM gn_imports.new_noms;

**Insertion dans ``cor_nom_liste``**

.. code:: sql

    INSERT INTO taxonomie.cor_nom_liste (id_liste, id_nom)
    SELECT unnest(array_listes) AS id_liste, n.id_nom 
    FROM gn_imports.new_noms tnn
    JOIN taxonomie.bib_noms n ON n.cd_nom = tnn.cd_nom;

Si on veut nettoyer et qu'on est sur de ne plus en avoir besoin

.. code:: sql

    DROP TABLE gn_imports.new_noms;

8 - Déplacement de la table importée (facultatif)
-------------------------------------------------

On peut si on le souhaite déplacer la table vers une destination d'archivage

.. code:: sql

    ALTER TABLE gn_imports.testimport SET SCHEMA schema_destination;

On peut la mettre dans le schéma gn_exports pour l'exercice afin de tester mais ce n'est pas sa vocation.

RESULTAT FINAL
--------------

.. code:: sql
    
    --DELETE FROM gn_imports.matching_fields WHERE id_matching_table IN (1,2);
    INSERT INTO gn_imports.matching_fields (id_matching_field, source_field, source_default_value, target_field, target_field_type, field_comments, id_matching_table) VALUES (207, NULL, 'uuid_generate_v4()', 'unique_id_sinp', 'uuid', NULL, 1);
    INSERT INTO gn_imports.matching_fields (id_matching_field, source_field, source_default_value, target_field, target_field_type, field_comments, id_matching_table) VALUES (208, NULL, 'uuid_generate_v4()', 'unique_id_sinp_grp', 'uuid', NULL, 1);
    INSERT INTO gn_imports.matching_fields (id_matching_field, source_field, source_default_value, target_field, target_field_type, field_comments, id_matching_table) VALUES (219, NULL, 'gn_synthese.get_default_nomenclature_value(''PREUVE_EXIST''::character varying)', 'id_nomenclature_exist_proof', 'integer', NULL, 1);
    INSERT INTO gn_imports.matching_fields (id_matching_field, source_field, source_default_value, target_field, target_field_type, field_comments, id_matching_table) VALUES (210, 'id_data', NULL, 'entity_source_pk_value', 'character varying', NULL, 1);
    INSERT INTO gn_imports.matching_fields (id_matching_field, source_field, source_default_value, target_field, target_field_type, field_comments, id_matching_table) VALUES (211, 'id_lot', NULL, 'id_dataset', 'integer', NULL, 1);
    INSERT INTO gn_imports.matching_fields (id_matching_field, source_field, source_default_value, target_field, target_field_type, field_comments, id_matching_table) VALUES (209, 'id_source', NULL, 'id_source', 'integer', NULL, 1);
    INSERT INTO gn_imports.matching_fields (id_matching_field, source_field, source_default_value, target_field, target_field_type, field_comments, id_matching_table) VALUES (213, NULL, 'gn_synthese.get_default_nomenclature_value(''TYP_GRP''::character varying)', 'id_nomenclature_grp_typ', 'integer', NULL, 1);
    INSERT INTO gn_imports.matching_fields (id_matching_field, source_field, source_default_value, target_field, target_field_type, field_comments, id_matching_table) VALUES (212, NULL, 'gn_synthese.get_default_nomenclature_value(''NAT_OBJ_GEO''::character varying)', 'id_nomenclature_geo_object_nature', 'integer', NULL, 1);
    INSERT INTO gn_imports.matching_fields (id_matching_field, source_field, source_default_value, target_field, target_field_type, field_comments, id_matching_table) VALUES (214, NULL, 'gn_synthese.get_default_nomenclature_value(''METH_OBS''::character varying)', 'id_nomenclature_obs_meth', 'integer', NULL, 1);
    INSERT INTO gn_imports.matching_fields (id_matching_field, source_field, source_default_value, target_field, target_field_type, field_comments, id_matching_table) VALUES (215, NULL, 'gn_synthese.get_default_nomenclature_value(''TECHNIQUE_OBS''::character varying)', 'id_nomenclature_obs_technique', 'integer', NULL, 1);
    INSERT INTO gn_imports.matching_fields (id_matching_field, source_field, source_default_value, target_field, target_field_type, field_comments, id_matching_table) VALUES (217, NULL, 'gn_synthese.get_default_nomenclature_value(''ETA_BIO''::character varying)', 'id_nomenclature_bio_condition', 'integer', NULL, 1);
    INSERT INTO gn_imports.matching_fields (id_matching_field, source_field, source_default_value, target_field, target_field_type, field_comments, id_matching_table) VALUES (216, NULL, 'gn_synthese.get_default_nomenclature_value(''STATUT_BIO''::character varying)', 'id_nomenclature_bio_status', 'integer', NULL, 1);
    INSERT INTO gn_imports.matching_fields (id_matching_field, source_field, source_default_value, target_field, target_field_type, field_comments, id_matching_table) VALUES (218, NULL, 'gn_synthese.get_default_nomenclature_value(''NATURALITE''::character varying)', 'id_nomenclature_naturalness', 'integer', NULL, 1);
    INSERT INTO gn_imports.matching_fields (id_matching_field, source_field, source_default_value, target_field, target_field_type, field_comments, id_matching_table) VALUES (220, NULL, 'gn_synthese.get_default_nomenclature_value(''STATUT_VALID''::character varying)', 'id_nomenclature_valid_status', 'integer', NULL, 1);
    INSERT INTO gn_imports.matching_fields (id_matching_field, source_field, source_default_value, target_field, target_field_type, field_comments, id_matching_table) VALUES (221, NULL, 'gn_synthese.get_default_nomenclature_value(''NIV_PRECIS''::character varying)', 'id_nomenclature_diffusion_level', 'integer', NULL, 1);
    INSERT INTO gn_imports.matching_fields (id_matching_field, source_field, source_default_value, target_field, target_field_type, field_comments, id_matching_table) VALUES (223, NULL, 'gn_synthese.get_default_nomenclature_value(''SEXE''::character varying)', 'id_nomenclature_sex', 'integer', NULL, 1);
    INSERT INTO gn_imports.matching_fields (id_matching_field, source_field, source_default_value, target_field, target_field_type, field_comments, id_matching_table) VALUES (222, NULL, 'gn_synthese.get_default_nomenclature_value(''STADE_VIE''::character varying)', 'id_nomenclature_life_stage', 'integer', NULL, 1);
    INSERT INTO gn_imports.matching_fields (id_matching_field, source_field, source_default_value, target_field, target_field_type, field_comments, id_matching_table) VALUES (224, NULL, 'gn_synthese.get_default_nomenclature_value(''OBJ_DENBR''::character varying)', 'id_nomenclature_obj_count', 'integer', NULL, 1);
    INSERT INTO gn_imports.matching_fields (id_matching_field, source_field, source_default_value, target_field, target_field_type, field_comments, id_matching_table) VALUES (226, NULL, 'gn_synthese.get_default_nomenclature_value(''SENSIBILITE''::character varying)', 'id_nomenclature_sensitivity', 'integer', NULL, 1);
    INSERT INTO gn_imports.matching_fields (id_matching_field, source_field, source_default_value, target_field, target_field_type, field_comments, id_matching_table) VALUES (225, NULL, 'gn_synthese.get_default_nomenclature_value(''TYP_DENBR''::character varying)', 'id_nomenclature_type_count', 'integer', NULL, 1);
    INSERT INTO gn_imports.matching_fields (id_matching_field, source_field, source_default_value, target_field, target_field_type, field_comments, id_matching_table) VALUES (227, NULL, 'gn_synthese.get_default_nomenclature_value(''STATUT_OBS''::character varying)', 'id_nomenclature_observation_status', 'integer', NULL, 1);
    INSERT INTO gn_imports.matching_fields (id_matching_field, source_field, source_default_value, target_field, target_field_type, field_comments, id_matching_table) VALUES (228, NULL, 'gn_synthese.get_default_nomenclature_value(''DEE_FLOU''::character varying)', 'id_nomenclature_blurring', 'integer', NULL, 1);
    INSERT INTO gn_imports.matching_fields (id_matching_field, source_field, source_default_value, target_field, target_field_type, field_comments, id_matching_table) VALUES (230, NULL, 'gn_synthese.get_default_nomenclature_value(''TYP_INF_GEO''::character varying)', 'id_nomenclature_info_geo_type', 'integer', NULL, 1);
    INSERT INTO gn_imports.matching_fields (id_matching_field, source_field, source_default_value, target_field, target_field_type, field_comments, id_matching_table) VALUES (229, NULL, 'gn_synthese.get_default_nomenclature_value(''STATUT_SOURCE''::character varying)', 'id_nomenclature_source_status', 'integer', NULL, 1);
    INSERT INTO gn_imports.matching_fields (id_matching_field, source_field, source_default_value, target_field, target_field_type, field_comments, id_matching_table) VALUES (233, 'cd_nom', NULL, 'cd_nom', 'integer', NULL, 1);
    INSERT INTO gn_imports.matching_fields (id_matching_field, source_field, source_default_value, target_field, target_field_type, field_comments, id_matching_table) VALUES (237, NULL, 'NULL', 'digital_proof', 'text', NULL, 1);
    INSERT INTO gn_imports.matching_fields (id_matching_field, source_field, source_default_value, target_field, target_field_type, field_comments, id_matching_table) VALUES (238, NULL, 'NULL', 'non_digital_proof', 'text', NULL, 1);
    INSERT INTO gn_imports.matching_fields (id_matching_field, source_field, source_default_value, target_field, target_field_type, field_comments, id_matching_table) VALUES (239, 'altitude_retenue', NULL, 'altitude_min', 'integer', NULL, 1);
    INSERT INTO gn_imports.matching_fields (id_matching_field, source_field, source_default_value, target_field, target_field_type, field_comments, id_matching_table) VALUES (240, 'altitude_retenue', NULL, 'altitude_max', 'integer', NULL, 1);
    INSERT INTO gn_imports.matching_fields (id_matching_field, source_field, source_default_value, target_field, target_field_type, field_comments, id_matching_table) VALUES (244, 'dateobs', NULL, 'date_min', 'timestamp without time zone', NULL, 1);
    INSERT INTO gn_imports.matching_fields (id_matching_field, source_field, source_default_value, target_field, target_field_type, field_comments, id_matching_table) VALUES (245, 'dateobs', NULL, 'date_max', 'timestamp without time zone', NULL, 1);
    INSERT INTO gn_imports.matching_fields (id_matching_field, source_field, source_default_value, target_field, target_field_type, field_comments, id_matching_table) VALUES (246, NULL, 'NULL', 'validator', 'character varying', NULL, 1);
    INSERT INTO gn_imports.matching_fields (id_matching_field, source_field, source_default_value, target_field, target_field_type, field_comments, id_matching_table) VALUES (248, NULL, 'NULL', 'observers', 'character varying', NULL, 1);
    INSERT INTO gn_imports.matching_fields (id_matching_field, source_field, source_default_value, target_field, target_field_type, field_comments, id_matching_table) VALUES (247, NULL, 'NULL', 'validation_comment', 'text', NULL, 1);
    INSERT INTO gn_imports.matching_fields (id_matching_field, source_field, source_default_value, target_field, target_field_type, field_comments, id_matching_table) VALUES (250, NULL, 'gn_synthese.get_default_nomenclature_value(''METH_DETERMIN''::character varying)', 'id_nomenclature_determination_method', 'integer', NULL, 1);
    INSERT INTO gn_imports.matching_fields (id_matching_field, source_field, source_default_value, target_field, target_field_type, field_comments, id_matching_table) VALUES (252, NULL, 'now()', 'meta_validation_date', 'timestamp without time zone', NULL, 1);
    INSERT INTO gn_imports.matching_fields (id_matching_field, source_field, source_default_value, target_field, target_field_type, field_comments, id_matching_table) VALUES (253, NULL, 'now()', 'meta_create_date', 'timestamp without time zone', NULL, 1);
    INSERT INTO gn_imports.matching_fields (id_matching_field, source_field, source_default_value, target_field, target_field_type, field_comments, id_matching_table) VALUES (254, NULL, 'now()', 'meta_update_date', 'timestamp without time zone', NULL, 1);
    INSERT INTO gn_imports.matching_fields (id_matching_field, source_field, source_default_value, target_field, target_field_type, field_comments, id_matching_table) VALUES (255, NULL, '''c''', 'last_action', 'character', NULL, 1);
    INSERT INTO gn_imports.matching_fields (id_matching_field, source_field, source_default_value, target_field, target_field_type, field_comments, id_matching_table) VALUES (235, NULL, 'gn_commons.get_default_parameter(''taxref_version'',NULL)::character varying', 'meta_v_taxref', 'character varying', NULL, 1);
    INSERT INTO gn_imports.matching_fields (id_matching_field, source_field, source_default_value, target_field, target_field_type, field_comments, id_matching_table) VALUES (251, 'remarques', NULL, 'comments', 'text', NULL, 1);
    INSERT INTO gn_imports.matching_fields (id_matching_field, source_field, source_default_value, target_field, target_field_type, field_comments, id_matching_table) VALUES (231, 'effectif_total', NULL, 'count_min', 'integer', NULL, 1);
    INSERT INTO gn_imports.matching_fields (id_matching_field, source_field, source_default_value, target_field, target_field_type, field_comments, id_matching_table) VALUES (232, 'effectif_total', NULL, 'count_max', 'integer', NULL, 1);
    INSERT INTO gn_imports.matching_fields (id_matching_field, source_field, source_default_value, target_field, target_field_type, field_comments, id_matching_table) VALUES (258, 'taxon_saisi', NULL, 'nom_cite', 'character varying', NULL, 1);
    INSERT INTO gn_imports.matching_fields (id_matching_field, source_field, source_default_value, target_field, target_field_type, field_comments, id_matching_table) VALUES (249, NULL, 'u.nom_role || '' '' || u.prenom_role', 'determiner', 'character varying', NULL, 1);
    INSERT INTO gn_imports.matching_fields (id_matching_field, source_field, source_default_value, target_field, target_field_type, field_comments, id_matching_table) VALUES (234, 'taxon_saisi', NULL, 'nom_cite', 'character varying', NULL, 1);
    INSERT INTO gn_imports.matching_fields (id_matching_field, source_field, source_default_value, target_field, target_field_type, field_comments, id_matching_table) VALUES (256, 'id_data', NULL, 'entity_source_pk_value', 'integer', NULL, 2);
    INSERT INTO gn_imports.matching_fields (id_matching_field, source_field, source_default_value, target_field, target_field_type, field_comments, id_matching_table) VALUES (257, 'observateurs', NULL, 'id_role', 'integer', NULL, 2);
    INSERT INTO gn_imports.matching_geoms (id_matching_geom, source_x_field, source_y_field, source_geom_field, source_geom_format, source_srid, target_geom_field, target_geom_srid, geom_comments, id_matching_table) VALUES (1, 'x', 'y', NULL, 'xy', 2154, 'the_geom_local', 2154, NULL, 1);
    INSERT INTO gn_imports.matching_geoms (id_matching_geom, source_x_field, source_y_field, source_geom_field, source_geom_format, source_srid, target_geom_field, target_geom_srid, geom_comments, id_matching_table) VALUES (2, NULL, NULL, 'POINT(6.064544 44.28787)', 'wkt', 4326, 'the_geom_4326', 4326, NULL, 1);
    INSERT INTO gn_imports.matching_geoms (id_matching_geom, source_x_field, source_y_field, source_geom_field, source_geom_format, source_srid, target_geom_field, target_geom_srid, geom_comments, id_matching_table) VALUES (1, 'x', 'y', NULL, 'xy', 4326, 'the_geom_point', 4326, NULL, 1);

    SELECT pg_catalog.setval('gn_imports.matching_fields_id_matching_field_seq', 258, true);
    SELECT pg_catalog.setval('gn_imports.matching_geoms_id_matching_geom_seq', 3, true);
    SELECT pg_catalog.setval('gn_imports.matching_tables_id_matching_table_seq', 2, true);
    
    ---------------
    --IMPORT DATA--
    ---------------
    --autogenerated query by
    --SELECT gn_imports.fct_generate_import_query('gn_imports.testimport', 'gn_synthese.cor_observer_synthese');
    INSERT INTO gn_synthese.synthese(
    unique_id_sinp
    ,unique_id_sinp_grp
    ,id_nomenclature_exist_proof
    ,entity_source_pk_value
    ,id_dataset
    ,id_source
    ,id_nomenclature_grp_typ
    ,id_nomenclature_geo_object_nature
    ,id_nomenclature_obs_meth
    ,id_nomenclature_obs_technique
    ,id_nomenclature_bio_condition
    ,id_nomenclature_bio_status
    ,id_nomenclature_naturalness
    ,id_nomenclature_valid_status
    ,id_nomenclature_diffusion_level
    ,id_nomenclature_sex
    ,id_nomenclature_life_stage
    ,id_nomenclature_obj_count
    ,id_nomenclature_sensitivity
    ,id_nomenclature_type_count
    ,id_nomenclature_observation_status
    ,id_nomenclature_blurring
    ,id_nomenclature_info_geo_type
    ,id_nomenclature_source_status
    ,cd_nom
    ,digital_proof
    ,non_digital_proof
    ,altitude_min
    ,altitude_max
    ,date_min
    ,date_max
    ,validator
    ,observers
    ,validation_comment
    ,id_nomenclature_determination_method
    ,meta_validation_date
    ,meta_create_date
    ,meta_update_date
    ,last_action
    ,meta_v_taxref
    ,comments
    ,count_min
    ,count_max
    ,nom_cite
    )
    SELECT 
    uuid_generate_v4()::uuid AS unique_id_sinp
    ,uuid_generate_v4()::uuid AS unique_id_sinp_grp
    ,gn_synthese.get_default_nomenclature_value('PREUVE_EXIST'::character varying)::integer AS id_nomenclature_exist_proof
    ,a.id_data::character varying AS entity_source_pk_value
    ,a.id_lot::integer AS id_dataset
    ,a.id_source::integer AS id_source
    ,gn_synthese.get_default_nomenclature_value('TYP_GRP'::character varying)::integer AS id_nomenclature_grp_typ
    ,gn_synthese.get_default_nomenclature_value('NAT_OBJ_GEO'::character varying)::integer AS id_nomenclature_geo_object_nature
    ,gn_synthese.get_default_nomenclature_value('METH_OBS'::character varying)::integer AS id_nomenclature_obs_meth
    ,gn_synthese.get_default_nomenclature_value('TECHNIQUE_OBS'::character varying)::integer AS id_nomenclature_obs_technique
    ,gn_synthese.get_default_nomenclature_value('ETA_BIO'::character varying)::integer AS id_nomenclature_bio_condition
    ,gn_synthese.get_default_nomenclature_value('STATUT_BIO'::character varying)::integer AS id_nomenclature_bio_status
    ,gn_synthese.get_default_nomenclature_value('NATURALITE'::character varying)::integer AS id_nomenclature_naturalness
    ,gn_synthese.get_default_nomenclature_value('STATUT_VALID'::character varying)::integer AS id_nomenclature_valid_status
    ,gn_synthese.get_default_nomenclature_value('NIV_PRECIS'::character varying)::integer AS id_nomenclature_diffusion_level
    ,gn_synthese.get_default_nomenclature_value('SEXE'::character varying)::integer AS id_nomenclature_sex
    ,gn_synthese.get_default_nomenclature_value('STADE_VIE'::character varying)::integer AS id_nomenclature_life_stage
    ,gn_synthese.get_default_nomenclature_value('OBJ_DENBR'::character varying)::integer AS id_nomenclature_obj_count
    ,gn_synthese.get_default_nomenclature_value('SENSIBILITE'::character varying)::integer AS id_nomenclature_sensitivity
    ,gn_synthese.get_default_nomenclature_value('TYP_DENBR'::character varying)::integer AS id_nomenclature_type_count
    ,gn_synthese.get_default_nomenclature_value('STATUT_OBS'::character varying)::integer AS id_nomenclature_observation_status
    ,gn_synthese.get_default_nomenclature_value('DEE_FLOU'::character varying)::integer AS id_nomenclature_blurring
    ,gn_synthese.get_default_nomenclature_value('TYP_INF_GEO'::character varying)::integer AS id_nomenclature_info_geo_type
    ,gn_synthese.get_default_nomenclature_value('STATUT_SOURCE'::character varying)::integer AS id_nomenclature_source_status
    ,a.cd_nom::integer AS cd_nom
    ,NULL::text AS digital_proof
    ,NULL::text AS non_digital_proof
    ,a.altitude_retenue::integer AS altitude_min
    ,a.altitude_retenue::integer AS altitude_max
    ,a.dateobs::timestamp without time zone AS date_min
    ,a.dateobs::timestamp without time zone AS date_max
    ,NULL::character varying AS validator
    ,NULL::character varying AS observers
    ,NULL::text AS validation_comment
    ,gn_synthese.get_default_nomenclature_value('METH_DETERMIN'::character varying)::integer AS id_nomenclature_determination_method
    ,now()::timestamp without time zone AS meta_validation_date
    ,now()::timestamp without time zone AS meta_create_date
    ,now()::timestamp without time zone AS meta_update_date
    ,'c'::character AS last_action
    ,gn_commons.get_default_parameter('taxref_version',NULL)::character varying::character varying AS meta_v_taxref
    ,a.remarques::text AS comments
    ,a.effectif_total::integer AS count_min
    ,a.effectif_total::integer AS count_max
    ,taxon_saisi
    FROM gn_imports.testimport a
    ;
    
    --autogenerated query by
    --SELECT gn_imports.fct_generate_import_query('gn_imports.testimport', 'gn_synthese.cor_observer_synthese');
    INSERT INTO gn_synthese.cor_observer_synthese(
    id_role
    ,id_synthese
    )
     SELECT 
    a.observateurs::integer AS id_role
    ,s.id_synthese::integer AS id_synthese
    FROM gn_imports.testimport a
    --self addition
    JOIN gn_synthese.synthese s ON s.entity_source_pk_value::integer = a.id_data
    WHERE s.id_source = 4;
    ;
