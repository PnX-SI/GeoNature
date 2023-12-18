SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET search_path = gn_imports, pg_catalog, public;
SET default_with_oids = false;


--------------
--INSERTIONS--
--------------

INSERT INTO gn_imports.t_user_errors (error_type,"name",description,error_level) VALUES 
('Ouverture du fichier','NO_FILE_DETECTED','Aucun fichier détecté.','ERROR')
,('Erreur de format','INVALID_INTEGER','Format numérique entier incorrect ou négatif dans une des colonnes de type Entier.','ERROR')
,('Erreur de format','INVALID_DATE','Le format de date est incorrect dans une colonne de type Datetime. Le format attendu est YYYY-MM-DD ou DD-MM-YYYY (les heures sont acceptées sous ce format: HH:MM:SS) - Les séparateurs / . : sont également acceptés','ERROR')
,('Erreur de format','INVALID_UUID','L''identifiant permanent doit être un UUID valide, ou sa valeur doit être vide.','ERROR')
,('Erreur de format','INVALID_CHAR_LENGTH','Chaîne de caractères trop longue ; la longueur de la chaîne dépasse la longueur maximale autorisée.','ERROR')
,('Champ obligatoire','MISSING_VALUE','Valeur manquante dans un champs obligatoire','ERROR')
,('Incohérence','DATE_MIN_SUP_DATE_MAX','date_min > date_max','ERROR')
,('Incohérence','COUNT_MIN_SUP_COUNT_MAX','Incohérence entre les champs dénombrement. La valeur de denombrement_min est supérieure à celle de denombrement _max ou la valeur de denombrement _max est inférieur à denombrement_min.','ERROR')
,('Erreur de référentiel','CD_NOM_NOT_FOUND','Le Cd_nom renseigné ne peut être importé car il est absent du référentiel TAXREF ou de la liste de taxons importables configurée par l''administrateur','ERROR')
,('Erreur de référentiel','CD_HAB_NOT_FOUND','Le cdHab indiqué n’est pas dans le référentiel HABREF ; la valeur de cdHab n’a pu être trouvée dans la version courante du référentiel.','ERROR')
,('Erreur d''incohérence','ALTI_MIN_SUP_ALTI_MAX','altitude min > altitude max','ERROR')
,('Erreur d''incohérence','DEPTH_MIN_SUP_ALTI_MAX','profondeur min > profondeur max','ERROR')
,('Doublon','DUPLICATE_ENTITY_SOURCE_PK','Deux lignes du fichier ont la même clé primaire d’origine ; les clés primaires du fichier source ne peuvent pas être dupliquées.','ERROR')
,('Erreur de format','INVALID_REAL','Le format numérique réel est incorrect ou négatif dans une des colonnes de type REEL.','ERROR')
,('Géométrie','GEOMETRY_OUT_OF_BOX','Coordonnées géographiques en dehors du périmètre géographique de l''instance','ERROR')
,('Géométrie','PROJECTION_ERROR','Erreur de projection pour les coordonnées fournies','ERROR')
,('Doublon','EXISTING_UUID','L''identifiant SINP fourni existe déjà en base.  Il faut en fournir une autre ou laisser la valeur vide pour une attribution automatique.','ERROR')
,('Erreur de référentiel','ID_DIGITISER_NOT_EXISITING','id_digitizer n''existe pas dans la table "t_roles"','ERROR')
,('Erreur de référentiel','INVALID_GEOM_CODE','Le code (maille/département/commune) n''existe pas dans le réferentiel géographique actuel','ERROR')
,('Nom du fichier','FILE_NAME_ERROR','Le nom de fichier ne comporte que des chiffres.','ERROR')
,('Doublon','DUPLICATE_ROWS','Deux lignes du fichier sont identiques ; les lignes ne peuvent pas être dupliquées.','ERROR')
,('Duplication','DUPLICATE_UUID','L''identificant sinp n''est pas unique dans le fichier fournis','ERROR')
,('Erreur de format','MULTIPLE_CODE_ATTACHMENT','Plusieurs codes de rattachement fournis pour une même ligne. Une ligne doit avoir un seul code rattachement (code commune OU code maille OU code département)','ERROR')
,('Ouverture du fichier','FILE_WITH_NO_DATA','Le fichier ne comporte aucune donnée.','ERROR')
,('Format du fichier','FILE_EXTENSION_ERROR','L''extension de fichier fournie n''est pas correct','ERROR')
,('Erreur de ligne sur le fichier','ROW_HAVE_LESS_COLUMN','Une ligne du fichier a moins de colonnes que l''en-tête.','ERROR')
,('Nom du fichier','FILE_NAME_TOO_LONG','Nom de fichier trop long ; la longueur du nom de fichier ne doit pas être supérieure à 100 caractères','ERROR')
,('Taille du fichier','FILE_OVERSIZE','La taille du fichier dépasse la taille du fichier autorisée ','ERROR')
,('Lecture du fichier','FILE_FORMAT_ERROR','Erreur de lecture des données ; le format du fichier est incorrect.','ERROR')
,('Lecture du fichier','ENCODING_ERROR','Erreur de lecture des données en raison d''un problème d''encodage.','ERROR')
,('En-tête du fichier','HEADER_COLUMN_EMPTY','Un des noms de colonne de l’en-tête est vide ; tous les noms de colonne doivent avoir une valeur.','ERROR')
,('En-tête du fichier','HEADER_SAME_COLUMN_NAME','Plusieurs colonnes de l''en-tête portent le même nom ; tous les noms de colonne de l''en-tête doivent être uniques.','ERROR')
,('Erreur de ligne sur le fichier','EMPTY_ROW','Une ligne du fichier est vide ; les lignes doivent avoir au moins une cellule non vide.','ERROR')
,('Erreur de ligne sur le fichier','ROW_HAVE_TOO_MUCH_COLUMN','Une ligne du fichier a plus de colonnes que l''en-tête.','ERROR')
,('Erreur de nomenclature','INVALID_NOMENCLATURE','Code nomenclature erroné ; La valeur du champ n’est pas dans la liste des codes attendus pour ce champ. Pour connaître la liste des codes autorisés, reportez-vous au Standard en cours.','ERROR')
,('Géométrie','INVALID_WKT','Géométrie invalide ; la valeur de la géométrie ne correspond pas au format WKT.','ERROR')
,('Géoréférencement','MISSING_GEOM','Géoréférencement manquant ; un géoréférencement doit être fourni, c’est à dire qu’il faut livrer : soit une géométrie, soit une ou plusieurs commune(s), ou département(s), ou maille(s), dont le champ “typeInfoGeo” est indiqué à 1.','ERROR')
,('Erreur de fichier','ERROR_WHILE_LOADING_FILE','Une erreur de chargement s''est produite, probablement à cause d''un mauvais séparateur dans le fichier.','ERROR')
,('Erreur de format','INVALID_URL_PROOF','PreuveNumerique n’est pas une url ; le champ “preuveNumérique” indique l’adresse web à laquelle on pourra trouver la preuve numérique ou l’archive contenant toutes les preuves numériques. Il doit commencer par “http://”, “https://”, ou “ftp://”.','ERROR')
,('Erreur de réferentiel','INVALID_ATTACHMENT_CODE','Le code commune/maille/département indiqué ne fait pas partie du référentiel des géographique; la valeur de codeCommune/codeMaille/codeDepartement n’a pu être trouvée dans la version courante du référentiel.','ERROR')
,('Géométrie','INVALID_GEOMETRY','Géométrie invalide','ERROR')
,('Géométrie','NO-GEOM','Aucune géometrie fournie (ni X/Y, WKT ou code)','ERROR')
,('Géométrie','GEOMETRY_OUTSIDE','La géométrie se trouve à l''extérieur du territoire renseigné','ERROR')
,('Géoréférencement','MULTIPLE_ATTACHMENT_TYPE_CODE','Plusieurs géoréférencements ; un seul géoréférencement doit être livré. Une seule des colonnes codeCommune/codeMaille/codeDépartement doit être remplie pour chaque ligne','ERROR')
,('Ouverture du fichier','NO_FILE_SENDED','Aucun fichier envoyé','ERROR')
,('Champ obligatoire conditionnel','CONDITIONAL_MANDATORY_FIELD_ERROR','Champs obligatoires conditionnels manquants. Il existe des ensembles de champs liés à un concept qui sont “obligatoires conditionnels”, c’est à dire que si l''un des champs du concept est utilisé, alors d''autres champs du concept deviennent obligatoires. ','ERROR')
,('Incohérence','CONDITIONAL_INVALID_DATA','Erreur de valeur','ERROR')
,('Incohérence','INVALID_EXISTING_PROOF_VALUE','Incohérence entre les champs de preuve ; si le champ “preuveExistante” vaut oui, alors l’un des deux champs “preuveNumérique” ou “preuveNonNumérique” doit être rempli. A l’inverse, si l’un de ces deux champs est rempli, alors “preuveExistante” ne doit pas prendre une autre valeur que “oui” (code 1).','ERROR')
,('Incohérence','INVALID_STATUT_SOURCE_VALUE','Référence bibliographique manquante ; si le champ “statutSource” a la valeur “Li” (Littérature), alors une référence bibliographique doit être indiquée.','ERROR')
,('Erreur','UNKNOWN_ERROR','','ERROR')
,('Ouverture du fichier','EMPTY_FILE','Le fichier fournit est vide','ERROR')
,('Avertissement de nomenclature','INVALID_NOMENCLATURE_WARNING','(Non bloquant) Code nomenclature erroné et remplacé par sa valeur par défaut ; La valeur du champ n’est pas dans la liste des codes attendus pour ce champ. Pour connaître la liste des codes autorisés, reportez-vous au Standard en cours.','WARNING')
;


INSERT INTO dict_themes (name_theme, fr_label_theme, eng_label_theme, desc_theme, order_theme) VALUES
	('general_info', 'Informations générales', '', '', 1),
    ('statement_info', 'Informations de relevés', '', '', 2),
    ('occurrence_sensitivity', 'Informations d''occurrences & sensibilité', '', '', 3),
    ('enumeration', 'Dénombrements', '', '', 4),
    ('validation', 'Détermination et validité', '', '', 5),
    ('additional_data', 'Champs additionnels', '', '', 6);


INSERT INTO dict_fields (name_field, fr_label, eng_label, desc_field, type_field, synthese_field, mandatory, autogenerated, nomenclature, id_theme, order_field, display, comment) VALUES
	('entity_source_pk_value', 'Identifiant source', '', '', 'character varying', TRUE, FALSE, FALSE, FALSE, (SELECT id_theme FROM gn_imports.dict_themes WHERE name_theme='general_info'), 1, TRUE, 'Correspondance champs standard: identifiantOrigine'),
	('unique_id_sinp', 'Identifiant SINP (uuid)', '', '', 'uuid', TRUE, FALSE, FALSE, FALSE, (SELECT id_theme FROM gn_imports.dict_themes WHERE name_theme='general_info'), 2, TRUE, 'Correspondance champs standard: idSINPOccTax'),
	('unique_id_sinp_generate', 'Générer l''identifiant SINP', '', 'Génère automatiquement un identifiant de type uuid pour chaque observation', '', FALSE, FALSE, TRUE, FALSE, (SELECT id_theme FROM gn_imports.dict_themes WHERE name_theme='general_info'), 3, TRUE, NULL), 
	('meta_create_date', 'Date de création de la donnée', '', '', 'timestamp without time zone', TRUE, FALSE, FALSE, FALSE, (SELECT id_theme FROM gn_imports.dict_themes WHERE name_theme='general_info'), 4, TRUE, NULL),
	('meta_v_taxref', 'Version du référentiel taxonomique', '', '', 'character varying(50)', TRUE, FALSE, FALSE, FALSE, (SELECT id_theme FROM gn_imports.dict_themes WHERE name_theme='general_info'), 5, FALSE , 'Correspondance champs standard: versionTAXREF'),
	('meta_update_date', 'Date de mise à jour de la donnée', '', '', 'timestamp without time zone', TRUE, FALSE, FALSE, FALSE, (SELECT id_theme FROM gn_imports.dict_themes WHERE name_theme='general_info'), 6, TRUE, NULL),
	('id_nomenclature_grp_typ', 'Type de relevé/regroupement', '', '', 'integer', TRUE, FALSE, FALSE, TRUE, (SELECT id_theme FROM gn_imports.dict_themes WHERE name_theme='statement_info'), 1, TRUE, 'Correspondance champs standard: typeRegroupement'),
	('unique_id_sinp_grp','Identifiant relevé (uuid)','','','uuid', TRUE, FALSE, FALSE, FALSE, (SELECT id_theme FROM gn_imports.dict_themes WHERE name_theme='statement_info'), 2, TRUE, 'UUID du regroupement. Correspondance champs standard: identifiantRegroupementPermanent'),
	('date_min', 'Date début', '', '', 'timestamp without time zone', TRUE, TRUE, FALSE, FALSE, (SELECT id_theme FROM gn_imports.dict_themes WHERE name_theme='statement_info'), 3, TRUE, 'Date de début de l''observation. Le format attendu est YYYY-MM-DD ou DD-MM-YYYY (les heures sont acceptées sous ce format: HH:MM:SS) - Les séparateurs / . : sont également acceptés '),
	('date_max', 'Date fin', '', '', 'timestamp without time zone', TRUE, FALSE, FALSE, FALSE, (SELECT id_theme FROM gn_imports.dict_themes WHERE name_theme='statement_info'), 4, TRUE, 'Date de fin de l''observation. Le format attendu est YYYY-MM-DD ou DD-MM-YYYY (les heures sont acceptées sous ce format: HH:MM:SS) - Les séparateurs / . : sont également acceptés'),
	('hour_min', 'Heure min', '', '', 'text', FALSE, FALSE, FALSE, FALSE, (SELECT id_theme FROM gn_imports.dict_themes WHERE name_theme='statement_info'), 5, TRUE, 'Correspondance champs standard: heureDebut'),
  	('hour_max', 'Heure max', '', '', 'text', FALSE, FALSE, FALSE, FALSE, (SELECT id_theme FROM gn_imports.dict_themes WHERE name_theme='statement_info'), 6, TRUE, 'Correspondance champs standard: heureFin'),
	('altitude_min', 'Altitude min', '', '', 'integer', TRUE, FALSE, FALSE, FALSE, (SELECT id_theme FROM gn_imports.dict_themes WHERE name_theme='statement_info'), 7, TRUE, 'Correspondance champs standard: altitudeMin'),
	('altitude_max', 'Altitude max', '', '', 'integer', TRUE, FALSE, FALSE, FALSE, (SELECT id_theme FROM gn_imports.dict_themes WHERE name_theme='statement_info'), 8, TRUE, 'Correspondance champs standard: altitudeMax'),
	('altitudes_generate', 'Générer les altitudes', '', 'Génère automatiquement les altitudes pour chaque observation', '', FALSE, FALSE, TRUE, FALSE, (SELECT id_theme FROM gn_imports.dict_themes WHERE name_theme='statement_info'), 7, TRUE, NULL),
	('depth_min', 'Profondeur min', '', '', 'integer', TRUE, FALSE, FALSE, TRUE, (SELECT id_theme FROM gn_imports.dict_themes WHERE name_theme='statement_info'), 9, TRUE, 'Correspondance champs standard: profondeurMin. Entier attendu'),
	('depth_max', 'Profondeur max', '', '', 'integer', TRUE, FALSE, FALSE, TRUE, (SELECT id_theme FROM gn_imports.dict_themes WHERE name_theme='statement_info'), 10, TRUE, 'Correspondance champs standard: profondeurMax. Entier attendu'),	
	('observers', 'Observateur(s)', '', '', 'character varying(1000)', TRUE, TRUE, FALSE, FALSE, (SELECT id_theme FROM gn_imports.dict_themes WHERE name_theme='statement_info'), 11, TRUE, 'Correspondance champs standard: identiteObservateur. Format attendu : Nom Prénom (Organisme), Nom Prénom (Organisme)...' ),
	('comment_context', 'Commentaire de relevé', '', '', 'text', TRUE, FALSE, FALSE, FALSE, (SELECT id_theme FROM gn_imports.dict_themes WHERE name_theme='statement_info'), 12, TRUE, 'Commentaire du relevé'),
	('id_nomenclature_info_geo_type', 'Type d''information géographique', '', '', 'integer', TRUE, FALSE, FALSE, TRUE, (SELECT id_theme FROM gn_imports.dict_themes WHERE name_theme='statement_info'), 13, TRUE, 'Correspondance champs standard: typeInfoGeo'),
	('longitude', 'Longitude (coord x)', '', '', 'real', FALSE, TRUE, FALSE, FALSE, (SELECT id_theme FROM gn_imports.dict_themes WHERE name_theme='statement_info'), 14, TRUE, NULL),
	('latitude', 'Latitude (coord y)', '', '', 'real', FALSE, TRUE, FALSE, FALSE, (SELECT id_theme FROM gn_imports.dict_themes WHERE name_theme='statement_info'), 15, TRUE, NULL),
	('WKT', 'Géometrie (WKT)', '', '', 'wkt', FALSE, TRUE, FALSE, FALSE, (SELECT id_theme FROM gn_imports.dict_themes WHERE name_theme='statement_info'), 16, TRUE, NULL),
	('codecommune', 'Code commune', '', '', 'integer', FALSE, TRUE, FALSE, FALSE, (SELECT id_theme FROM gn_imports.dict_themes WHERE name_theme='statement_info'), 17, TRUE, 'Correspondance champs standard: codeCommune. Code INSEE attendu'),
	('codemaille', 'Code maille', '', '', 'integer', FALSE, TRUE, FALSE, FALSE, (SELECT id_theme FROM gn_imports.dict_themes WHERE name_theme='statement_info'), 18, TRUE, 'Correspondance champs standard: codeMaille. Code maille-10 MNHN attendu'),
	('codedepartement', 'Code département', '', '', 'integer', FALSE, TRUE, FALSE, FALSE, (SELECT id_theme FROM gn_imports.dict_themes WHERE name_theme='statement_info'), 19, TRUE, 'Correspondance champs standard: codeDepartement. Code INSEE attendu'),
	('id_nomenclature_geo_object_nature', 'Nature d''objet géographique', '', '', 'integer', TRUE, FALSE, FALSE, TRUE, (SELECT id_theme FROM gn_imports.dict_themes WHERE name_theme='statement_info'), 20, TRUE, 'Correspondance champs standard: natureObjetGeo'),
	('the_geom_point','Geométrie (Point)','','','geometry', TRUE, FALSE, FALSE, FALSE, (SELECT id_theme FROM gn_imports.dict_themes WHERE name_theme='statement_info'), 21, FALSE, NULL),
	('the_geom_local','Geométrie (SRID local)','','','geometry', TRUE, FALSE, FALSE, FALSE, (SELECT id_theme FROM gn_imports.dict_themes WHERE name_theme='statement_info'), 22, FALSE, NULL),
	('the_geom_4326','Geométrie (SRID 4326)','','','geometry', TRUE, FALSE, FALSE, FALSE, (SELECT id_theme FROM gn_imports.dict_themes WHERE name_theme='statement_info'), 23, FALSE, NULL),
	('place_name', 'Nom du lieu', '', '', 'character varying(500)', TRUE, FALSE, FALSE, TRUE, (SELECT id_theme FROM gn_imports.dict_themes WHERE name_theme='statement_info'), 24, TRUE, 'Correspondance champs standard: nomLieu'),
	('precision', 'Précision du pointage (m)', '', '', 'integer', TRUE, FALSE, FALSE, TRUE, (SELECT id_theme FROM gn_imports.dict_themes WHERE name_theme='statement_info'), 25, TRUE, 'Correspondance champs standard: precisionGeometrie. Entier attendu'),	
	('cd_hab', 'Code habitat', '', '', 'integer', TRUE, FALSE, FALSE, TRUE, (SELECT id_theme FROM gn_imports.dict_themes WHERE name_theme='statement_info'), 26, TRUE, 'Correspondance champs standard: CodeHabitatValue. Entier attendu'),
	('grp_method', 'Méthode de regroupement', '', '', 'character varying(255)', TRUE, FALSE, FALSE, TRUE, (SELECT id_theme FROM gn_imports.dict_themes WHERE name_theme='statement_info'), 27, TRUE, 'Correspondance champs standard: methodeRegroupement'),
	('nom_cite', 'Nom du taxon cité', '', '', 'character varying(1000)', TRUE, TRUE, FALSE, FALSE, (SELECT id_theme FROM gn_imports.dict_themes WHERE name_theme='occurrence_sensitivity'), 1, TRUE, 'Correspondance champs standard: nomCite'),
	('cd_nom', 'Cd nom taxref', '', '', 'integer', TRUE, TRUE, FALSE, FALSE, (SELECT id_theme FROM gn_imports.dict_themes WHERE name_theme='occurrence_sensitivity'), 2, TRUE, 'Code Taxref de l''espèce observé Correspondance champs standard: cdNom'),
	('id_nomenclature_obs_technique', 'Techniques d''observation', '', '', 'integer', TRUE, FALSE, FALSE, TRUE, (SELECT id_theme FROM gn_imports.dict_themes WHERE name_theme='occurrence_sensitivity'), 3, TRUE, 'Correspondance champs standard: obsTechnique'),
	('id_nomenclature_bio_status', 'Statut biologique', '', '', 'integer', TRUE, FALSE, FALSE, TRUE, (SELECT id_theme FROM gn_imports.dict_themes WHERE name_theme='occurrence_sensitivity'), 4, TRUE, 'Correspondance champs standard: occStatutBiologique'),
	('id_nomenclature_bio_condition', 'Etat biologique', '', '', 'integer', TRUE, FALSE, FALSE, TRUE, (SELECT id_theme FROM gn_imports.dict_themes WHERE name_theme='occurrence_sensitivity'), 5, TRUE, 'Correspondance champs standard: occEtatBiologique'),
	('id_nomenclature_biogeo_status', 'Statut biogéographique', '', '', 'integer', TRUE, FALSE, FALSE, TRUE, (SELECT id_theme FROM gn_imports.dict_themes WHERE name_theme='occurrence_sensitivity'), 6, TRUE, 'Correspondance champs standard: occStatutBiogeographique'),
	('id_nomenclature_naturalness', 'Naturalité', '', '', 'integer', TRUE, FALSE, FALSE, TRUE, (SELECT id_theme FROM gn_imports.dict_themes WHERE name_theme='occurrence_sensitivity'), 7, TRUE, 'Correspondance champs standard: occNaturalite'),
	('comment_description', 'Commentaire d''occurrence', '', '', 'text', TRUE, FALSE, FALSE, FALSE, (SELECT id_theme FROM gn_imports.dict_themes WHERE name_theme='occurrence_sensitivity'), 8, TRUE, 'Commentaire de l''occurrence. Correspondance champs standard:  comment '),
	('id_nomenclature_sensitivity', 'Sensibilité', '', '', 'integer', TRUE, FALSE, FALSE, TRUE, (SELECT id_theme FROM gn_imports.dict_themes WHERE name_theme='occurrence_sensitivity'), 9, TRUE, 'Sensibilité de l''observation. Correspondance champs standard: sensiNiveau'),
	('id_nomenclature_diffusion_level', 'Niveau de diffusion', '', '', 'integer', TRUE, FALSE, FALSE, TRUE, (SELECT id_theme FROM gn_imports.dict_themes WHERE name_theme='occurrence_sensitivity'), 10, TRUE, 'Correspondance champs standard: diffusionNiveauPrecision'),
	('id_nomenclature_blurring', 'Niveau de Floutage', '', '', 'integer', TRUE, FALSE, FALSE, TRUE, (SELECT id_theme FROM gn_imports.dict_themes WHERE name_theme='occurrence_sensitivity'), 11, TRUE, 'Correspondance champs standard: dEEFloutage'),
	('id_nomenclature_life_stage', 'Stade de vie', '', '', 'integer', TRUE, FALSE, FALSE, TRUE, (SELECT id_theme FROM gn_imports.dict_themes WHERE name_theme='enumeration'), 1, TRUE, 'Correspondance champs standard: occStadeDeVie'),
	('id_nomenclature_sex', 'Sexe', '', '', 'integer', TRUE, FALSE, FALSE, TRUE, (SELECT id_theme FROM gn_imports.dict_themes WHERE name_theme='enumeration'), 2, TRUE, 'Correspondance champs standard: occSexe'),
	('id_nomenclature_type_count', 'Type du dénombrement', '', '', 'integer', TRUE, FALSE, FALSE, TRUE, (SELECT id_theme FROM gn_imports.dict_themes WHERE name_theme='enumeration'), 3, TRUE, 'Correspondance champs standard: typeDenombrement'),
	('id_nomenclature_obj_count', 'Objet du dénombrement', '', '', 'integer', TRUE, FALSE, FALSE, TRUE, (SELECT id_theme FROM gn_imports.dict_themes WHERE name_theme='enumeration'), 4, TRUE, 'Correspondance champs standard: objetDenombrement'),
	('count_min', 'Nombre minimal', '', '', 'integer', TRUE, FALSE, FALSE, FALSE, (SELECT id_theme FROM gn_imports.dict_themes WHERE name_theme='enumeration'), 5, TRUE, 'Correspondance champs standard: denombrementMin. Entier attendu'),
	('count_max', 'Nombre maximal', '', '', 'integer', TRUE, FALSE, FALSE, FALSE, (SELECT id_theme FROM gn_imports.dict_themes WHERE name_theme='enumeration'), 6, TRUE, 'Correspondance champs standard: denombrementMax. Entier attendu'),
	('id_nomenclature_determination_method', 'Méthode de détermination', '', '', 'integer', TRUE, FALSE, FALSE, TRUE, (SELECT id_theme FROM gn_imports.dict_themes WHERE name_theme='validation'), 1, TRUE, 'Correspondance champs standard: occMethodeDetermination'),
	('determiner', 'Déterminateur', '', '', 'character varying(1000)', TRUE, FALSE, FALSE, FALSE, (SELECT id_theme FROM gn_imports.dict_themes WHERE name_theme='validation'), 2, TRUE, 'Correspondance champs standard: determinateur. Format attendu : Nom Prénom (Organisme), Nom Prénom (Organisme)…"'),
	('id_digitiser', 'Identifiant de l''auteur de la saisie (id_role dans l''instance cible)', '', '', 'integer', TRUE, FALSE, FALSE, FALSE, (SELECT id_theme FROM gn_imports.dict_themes WHERE name_theme='validation'), 3, FALSE, 'Fournir un id_role GeoNature'),
	('id_nomenclature_exist_proof', 'Existence d''une preuve', '', '', 'integer', TRUE, FALSE, FALSE, TRUE, (SELECT id_theme FROM gn_imports.dict_themes WHERE name_theme='validation'), 4, TRUE, 'Correspondance champs standard: preuveExistante'),
	('digital_proof', 'Preuve numérique', '', '', 'text', TRUE, FALSE, FALSE, FALSE, (SELECT id_theme FROM gn_imports.dict_themes WHERE name_theme='validation'), 5, TRUE, 'Correspondance champs standard: urlPreuveNumerique'),
	('non_digital_proof', 'Preuve non-numérique', '', '', 'text', TRUE, FALSE, FALSE, FALSE, (SELECT id_theme FROM gn_imports.dict_themes WHERE name_theme='validation'), 6, TRUE, 'Correspondance champs standard: preuveNonNumerique'),
	('id_nomenclature_valid_status', 'Statut de validation', '', '', 'integer', TRUE, FALSE, FALSE, TRUE, (SELECT id_theme FROM gn_imports.dict_themes WHERE name_theme='validation'), 7, TRUE, 'Correspondance champs standard: nivVal. Validation producteur'),
	('validator', 'Validateur', '', '', 'character varying(1000)', TRUE, FALSE, FALSE, FALSE, (SELECT id_theme FROM gn_imports.dict_themes WHERE name_theme='validation'), 8, TRUE, 'Correspondance champs standard: validateur. Format attendu : Nom Prénom (Organisme), Nom Prénom (Organisme)...'),
	('meta_validation_date', 'Date de validation', '', '', 'timestamp without time zone', TRUE, FALSE, FALSE, FALSE, (SELECT id_theme FROM gn_imports.dict_themes WHERE name_theme='validation'), 9, TRUE, 'Correspondance champs standard: DateCtrl (Validation producteur)'),
	('validation_comment', 'Commentaire de validation', '', '', 'text', TRUE, FALSE, FALSE, FALSE, (SELECT id_theme FROM gn_imports.dict_themes WHERE name_theme='validation'), 10, TRUE, NULL),
	('id_nomenclature_observation_status', 'Statut d''observation', '', '', 'integer', TRUE, FALSE, FALSE, TRUE, (SELECT id_theme FROM gn_imports.dict_themes WHERE name_theme='occurrence_sensitivity'), 11, TRUE, 'Correspondance champs standard: statutObservation'),
	('id_nomenclature_source_status', 'Statut de la source', '', '', 'integer', TRUE, FALSE, FALSE, TRUE, (SELECT id_theme FROM gn_imports.dict_themes WHERE name_theme='occurrence_sensitivity'), 12, TRUE, 'Correspondance champs standard: statutSource'),
	('reference_biblio', 'Référence bibliographique', '', '', 'character varying(5000)', TRUE, FALSE, FALSE, FALSE, (SELECT id_theme FROM gn_imports.dict_themes WHERE name_theme='occurrence_sensitivity'), 13, TRUE, 'Correspondance champs standard: referenceBiblio'),
	('id_nomenclature_behaviour', 'Comportement', '', '', 'integer', TRUE, FALSE, FALSE, TRUE, (SELECT id_theme FROM gn_imports.dict_themes WHERE name_theme='occurrence_sensitivity'), 14, TRUE, 'Correspondance champs standard: occComportement'),
	('additional_data', 'Champs additionnels', '', '', 'jsonb', TRUE, FALSE, FALSE, TRUE, (SELECT id_theme FROM gn_imports.dict_themes WHERE name_theme='additional_data'), 1, TRUE, 'Attributs additionnels');
	-- Ajouter un thème dédié à terme et prévoir un widget multiselect qui concatène les infos sous format jsonb ?


INSERT INTO cor_synthese_nomenclature (mnemonique, synthese_col) VALUES
    ('NAT_OBJ_GEO',	'id_nomenclature_geo_object_nature'),
    ('DEE_FLOU',	'id_nomenclature_blurring'),
    ('NIV_PRECIS',	'id_nomenclature_diffusion_level'),
    ('OBJ_DENBR',	'id_nomenclature_obj_count'),
    ('ETA_BIO',	'id_nomenclature_bio_condition'),
    ('NATURALITE',	'id_nomenclature_naturalness'),
    ('SEXE',	'id_nomenclature_sex'),
    ('STADE_VIE',	'id_nomenclature_life_stage'),
    ('STATUT_BIO',	'id_nomenclature_bio_status'),
    ('METH_OBS',	'id_nomenclature_obs_technique'),
    ('PREUVE_EXIST',	'id_nomenclature_exist_proof'),
    ('SENSIBILITE',	'id_nomenclature_sensitivity'),
    ('STATUT_OBS',	'id_nomenclature_observation_status'),
    ('STATUT_SOURCE',	'id_nomenclature_source_status'),
    ('TYP_DENBR',	'id_nomenclature_type_count'),
    ('TYP_INF_GEO',	'id_nomenclature_info_geo_type'),
    ('TYP_GRP',	'id_nomenclature_grp_typ'),
    ('STATUT_VALID',	'id_nomenclature_valid_status'),
    ('METH_DETERMIN',	'id_nomenclature_determination_method'),
    ('OCC_COMPORTEMENT', 'id_nomenclature_behaviour'),
	('STAT_BIOGEO', 'id_nomenclature_biogeo_status')
    ;

-----------------
---PERMISSIONS---
-----------------
DELETE FROM gn_permissions.t_permissions
WHERE id_object = (SELECT id_object FROM gn_permissions.t_objects WHERE code_object = 'MAPPING');

DELETE FROM gn_permissions.cor_object_module
WHERE id_object = (SELECT id_object FROM gn_permissions.t_objects WHERE code_object = 'MAPPING');

DELETE FROM gn_permissions.t_objects
WHERE code_object = 'MAPPING'; 

INSERT INTO gn_permissions.t_objects
(code_object, description_object)
VALUES('MAPPING', 'Représente un mapping dans le module d''import');

INSERT INTO gn_permissions.cor_object_module
(id_object, id_module)
VALUES(
	(SELECT id_object FROM gn_permissions.t_objects WHERE code_object = 'MAPPING'),
	(SELECT id_module FROM gn_commons.t_modules WHERE module_code = 'IMPORT')
);

