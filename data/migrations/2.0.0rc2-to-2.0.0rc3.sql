--------------------------
--------------------------
------- GN_SYNTHESE ------
--------------------------
--------------------------

-- Créer la fonction qui met à jour observers_txt de gn_synthese

CREATE OR REPLACE FUNCTION gn_synthese.fct_tri_maj_observers_txt()
  RETURNS trigger AS
$BODY$
DECLARE
  theobservers text;
  theidsynthese integer;
BEGIN
  IF (TG_OP = 'UPDATE') OR (TG_OP = 'INSERT') THEN
    theidsynthese = NEW.id_synthese; 
  END IF;
  IF (TG_OP = 'DELETE') THEN
    theidsynthese = OLD.id_synthese;
  END IF;
  -- Construire le texte pour le champ observers de la synthese
  SELECT INTO theobservers array_to_string(array_agg(r.nom_role || ' ' || r.prenom_role), ', ')
  FROM utilisateurs.t_roles r
  WHERE r.id_role IN(SELECT id_role FROM gn_synthese.cor_observer_synthese WHERE id_synthese = theidsynthese);
  -- Mise à jour du champ observers dans la table synthese
  UPDATE gn_synthese.synthese 
  SET observers = theobservers
  WHERE id_synthese =  theidsynthese;
RETURN NULL;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;


-- Créer le trigger qui lance cette fonction quand on insere ou modifie dans gn_synthese.cor_observer_synthese

CREATE TRIGGER trg_maj_synthese_observers_txt
AFTER INSERT OR UPDATE OR DELETE
ON gn_synthese.cor_observer_synthese
FOR EACH ROW
EXECUTE PROCEDURE gn_synthese.fct_tri_maj_observers_txt();


DROP VIEW gn_synthese.v_synthese_for_export;
CREATE OR REPLACE VIEW gn_synthese.v_synthese_for_export AS
   SELECT
    s.id_synthese,
    unique_id_sinp,
    unique_id_sinp_grp,
    s.id_source ,
    entity_source_pk_value ,
    count_min ,
    count_max ,
    nom_cite ,
    meta_v_taxref ,
    sample_number_proof ,
    digital_proof ,
    non_digital_proof ,
    altitude_min ,
    altitude_max ,
    the_geom_4326,
    the_geom_point,
    the_geom_local,
    st_astext(the_geom_4326) AS wkt,
    date_min,
    date_max,
    validator ,
    validation_comment ,
    observers ,
    id_digitiser,
    determiner ,
    comments ,
    meta_validation_date,
    s.meta_create_date,
    s.meta_update_date,
    last_action,
    d.id_dataset,
    d.dataset_name,
    d.id_acquisition_framework,
    deco.nat_obj_geo,
    deco.grp_typ,
    deco.obs_method,
    deco.obs_technique,
    deco.bio_status,
    deco.bio_condition,
    deco.naturalness,
    deco.exist_proof,
    deco.valid_status,
    deco.diffusion_level,
    deco.life_stage,
    deco.sex,
    deco.obj_count,
    deco.type_count,
    deco.sensitivity,
    deco.observation_status,
    deco.blurring,
    deco.source_status,
    sources.name_source,
    sources.url_source,
    t.cd_nom,
    t.cd_ref,
    t.nom_valide,
    t.nom_vern
  FROM gn_synthese.synthese s
  JOIN taxonomie.taxref t ON t.cd_nom = s.cd_nom
  JOIN gn_meta.t_datasets d ON d.id_dataset = s.id_dataset
  JOIN gn_synthese.t_sources sources ON sources.id_source = s.id_source
  JOIN gn_synthese.v_synthese_decode_nomenclatures deco ON deco.id_synthese = s.id_synthese
  ;


---------------------------
---------------------------
-------- REF_GEO ----------
---------------------------
---------------------------

-- Création de la table ref_geo.dem si elle n'existe pas
CREATE TABLE IF NOT EXISTS ref_geo.dem
(
  rid serial NOT NULL,
  rast raster,
  CONSTRAINT dem_pkey PRIMARY KEY (rid)
);

-- La fonction altitude sait désormais interroger le DEM ou le dem_vector
-- selon si dem_vector est rempli ou non
-- TODO : tester si dem vector est rempli sur la zone du geom transmis, sinon utiliser dem


CREATE OR REPLACE FUNCTION ref_geo.fct_get_altitude_intersection(IN mygeom geometry)
  RETURNS TABLE(altitude_min integer, altitude_max integer) AS
$BODY$
DECLARE
    thesrid int;
    is_vectorized int;
BEGIN
    SELECT gn_commons.get_default_parameter('local_srid', NULL) INTO thesrid;
    SELECT COALESCE(gid, NULL) FROM ref_geo.dem_vector LIMIT 1 INTO is_vectorized;
	
  IF is_vectorized IS NULL THEN
    -- Use DEM
    RETURN QUERY
    SELECT min((altitude).val)::integer AS altitude_min, max((altitude).val)::integer AS altitude_max
    FROM (
	SELECT ST_DumpAsPolygons(ST_clip(rast, 1
	, st_transform(myGeom,thesrid), true)) AS altitude
	FROM ref_geo.dem AS altitude 
	WHERE st_intersects(rast,st_transform(myGeom,thesrid))
    ) AS a;		
  -- Use dem_vector
  ELSE
    RETURN QUERY
    WITH d  as (
        SELECT st_transform(myGeom,thesrid) a
     )
    SELECT min(val)::int as altitude_min, max(val)::int as altitude_max
    FROM ref_geo.dem_vector, d
    WHERE st_intersects(a,geom);
  END IF;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;


---------------------------
---------------------------
-------- OCCTAX -----------
---------------------------
---------------------------

-- Update de la fonction Occtax vers Synthèse

-- Fonction utilisée pour les triggers vers synthese
CREATE OR REPLACE FUNCTION pr_occtax.insert_in_synthese(my_id_counting integer)
  RETURNS integer[] AS
$BODY$
DECLARE
new_count RECORD;
occurrence RECORD;
releve RECORD;
id_source integer;
validation RECORD;
id_nomenclature_source_status integer;
myobservers RECORD;
id_role_loop integer;

BEGIN
-- Recupération du counting à partir de son ID
SELECT INTO new_count * FROM pr_occtax.cor_counting_occtax WHERE id_counting_occtax = my_id_counting;

-- Récupération de l'occurrence
SELECT INTO occurrence * FROM pr_occtax.t_occurrences_occtax occ WHERE occ.id_occurrence_occtax = new_count.id_occurrence_occtax;

-- Récupération du relevé
SELECT INTO releve * FROM pr_occtax.t_releves_occtax rel WHERE occurrence.id_releve_occtax = rel.id_releve_occtax;

-- Récupération de la source
SELECT INTO id_source s.id_source FROM gn_synthese.t_sources s WHERE name_source ILIKE 'occtax';

-- Récupération du status de validation du counting dans la table t_validation
SELECT INTO validation v.*, CONCAT(r.nom_role, r.prenom_role) as validator_full_name
FROM gn_commons.t_validations v
LEFT JOIN utilisateurs.t_roles r ON v.id_validator = r.id_role
WHERE uuid_attached_row = new_count.unique_id_sinp_occtax;

-- Récupération du status_source depuis le JDD
SELECT INTO id_nomenclature_source_status d.id_nomenclature_source_status FROM gn_meta.t_datasets d WHERE id_dataset = releve.id_dataset;

--Récupération et formatage des observateurs
SELECT INTO myobservers array_to_string(array_agg(rol.nom_role || ' ' || rol.prenom_role), ', ') AS observers_name,
array_agg(rol.id_role) AS observers_id
FROM pr_occtax.cor_role_releves_occtax cor
JOIN utilisateurs.t_roles rol ON rol.id_role = cor.id_role
WHERE cor.id_releve_occtax = releve.id_releve_occtax;

-- Insertion dans la synthese
INSERT INTO gn_synthese.synthese (
unique_id_sinp,
unique_id_sinp_grp,
id_source,
entity_source_pk_value,
id_dataset,
id_nomenclature_geo_object_nature,
id_nomenclature_grp_typ,
id_nomenclature_obs_meth,
id_nomenclature_obs_technique,
id_nomenclature_bio_status,
id_nomenclature_bio_condition,
id_nomenclature_naturalness,
id_nomenclature_exist_proof,
id_nomenclature_valid_status,
id_nomenclature_diffusion_level,
id_nomenclature_life_stage,
id_nomenclature_sex,
id_nomenclature_obj_count,
id_nomenclature_type_count,
id_nomenclature_observation_status,
id_nomenclature_blurring,
id_nomenclature_source_status,
id_nomenclature_info_geo_type,
count_min,
count_max,
cd_nom,
nom_cite,
meta_v_taxref,
sample_number_proof,
digital_proof,
non_digital_proof,
altitude_min,
altitude_max,
the_geom_4326,
the_geom_point,
the_geom_local,
date_min,
date_max,
validator,
validation_comment,
observers,
determiner,
id_digitiser,
id_nomenclature_determination_method,
comments,
last_action
)

VALUES(
  new_count.unique_id_sinp_occtax,
  releve.unique_id_sinp_grp,
  id_source,
  new_count.id_counting_occtax,
  releve.id_dataset,
  -- Nature de l'objet geo: id_nomenclature_geo_object_nature Le taxon observé est présent quelque part dans l'objet géographique - NSP par défault
  pr_occtax.get_default_nomenclature_value('NAT_OBJ_GEO'),
  releve.id_nomenclature_grp_typ,
  occurrence.id_nomenclature_obs_meth,
  releve.id_nomenclature_obs_technique,
  occurrence.id_nomenclature_bio_status,
  occurrence.id_nomenclature_bio_condition,
  occurrence.id_nomenclature_naturalness,
  occurrence.id_nomenclature_exist_proof,
    -- Statut de validation récupérer à partir de gn_commons.t_validations
  validation.id_nomenclature_valid_status,
  occurrence.id_nomenclature_diffusion_level,
  new_count.id_nomenclature_life_stage,
  new_count.id_nomenclature_sex,
  new_count.id_nomenclature_obj_count,
  new_count.id_nomenclature_type_count,
  occurrence.id_nomenclature_observation_status,
  occurrence.id_nomenclature_blurring,
  -- Status_source récupéré depuis le JDD
  id_nomenclature_source_status,
  -- id_nomenclature_info_geo_type: type de rattachement = géoréferencement
  ref_nomenclatures.get_id_nomenclature('TYP_INF_GEO', '1')	,
  new_count.count_min,
  new_count.count_max,
  occurrence.cd_nom,
  occurrence.nom_cite,
  occurrence.meta_v_taxref,
  occurrence.sample_number_proof,
  occurrence.digital_proof,
  occurrence.non_digital_proof,
  releve.altitude_min,
  releve.altitude_max,
  releve.geom_4326,
  ST_CENTROID(releve.geom_4326),
  releve.geom_local,
  (to_char(releve.date_min, 'DD/MM/YYYY') || ' ' || COALESCE(to_char(releve.hour_min, 'HH24:MI:SS'),'00:00:00'))::timestamp,
  (to_char(releve.date_max, 'DD/MM/YYYY') || ' ' || COALESCE(to_char(releve.hour_max, 'HH24:MI:SS'),'00:00:00'))::timestamp,
  validation.validator_full_name,
  validation.validation_comment,
  COALESCE (myobservers.observers_name, releve.observers_txt),
  occurrence.determiner,
  releve.id_digitiser,
  occurrence.id_nomenclature_determination_method,
  CONCAT(COALESCE('Relevé : '||releve.comment || ' / ', NULL ), COALESCE('Occurrence : '||occurrence.comment, NULL)),
  'I'
);

  RETURN myobservers.observers_id ;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

--UPDATE Occurrence
CREATE OR REPLACE FUNCTION pr_occtax.fct_tri_synthese_update_occ()
  RETURNS trigger AS
$BODY$
DECLARE
  releve RECORD;
BEGIN
  -- Récupération du releve pour le commentaire à concatener
  SELECT INTO releve * FROM pr_occtax.t_releves_occtax WHERE id_releve_occtax = NEW.id_releve_occtax;
  IF releve.comment = '' THEN releve.comment = NULL; END IF;
  IF NEW.comment = '' THEN NEW.comment = NULL; END IF;
  UPDATE gn_synthese.synthese SET
    id_nomenclature_obs_meth = NEW.id_nomenclature_obs_meth,
    id_nomenclature_bio_condition = NEW.id_nomenclature_bio_condition,
    id_nomenclature_bio_status = NEW.id_nomenclature_bio_status,
    id_nomenclature_naturalness = NEW.id_nomenclature_naturalness,
    id_nomenclature_exist_proof = NEW.id_nomenclature_exist_proof,
    id_nomenclature_diffusion_level = NEW.id_nomenclature_diffusion_level,
    id_nomenclature_observation_status = NEW.id_nomenclature_observation_status,
    id_nomenclature_blurring = NEW.id_nomenclature_blurring,
    id_nomenclature_source_status = NEW.id_nomenclature_source_status,
    determiner = NEW.determiner,
    id_nomenclature_determination_method = NEW.id_nomenclature_determination_method,
    cd_nom = NEW.cd_nom,
    nom_cite = NEW.nom_cite,
    meta_v_taxref = NEW.meta_v_taxref,
    sample_number_proof = NEW.sample_number_proof,
    digital_proof = NEW.digital_proof,
    non_digital_proof = NEW.non_digital_proof,
    comments  = CONCAT(COALESCE('Relevé : '||releve.comment || ' / ', NULL ), COALESCE('Occurrence: '||NEW.comment, NULL)),
    last_action = 'U'
  WHERE unique_id_sinp IN (SELECT unique_id_sinp_occtax FROM pr_occtax.cor_counting_occtax WHERE id_occurrence_occtax = NEW.id_occurrence_occtax);
  RETURN NULL;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
  
-- UPDATE Releve
CREATE OR REPLACE FUNCTION pr_occtax.fct_tri_synthese_update_releve()
  RETURNS trigger AS
$BODY$
DECLARE
  theoccurrence RECORD;
  myobservers text;
BEGIN
  -- Calcul de l'observateur. On privilégie le ou les observateur(s) de cor_role_releves_occtax
  -- Récupération et formatage des observateurs
  SELECT INTO myobservers array_to_string(array_agg(rol.nom_role || ' ' || rol.prenom_role), ', ')
  FROM pr_occtax.cor_role_releves_occtax cor
  JOIN utilisateurs.t_roles rol ON rol.id_role = cor.id_role
  WHERE cor.id_releve_occtax = NEW.id_releve_occtax;
  IF myobservers IS NULL THEN
    myobservers = NEW.observers_txt;
  END IF;
  -- Mise à jour en synthese des informations correspondant au relevé uniquement
  UPDATE gn_synthese.synthese SET
      id_dataset = NEW.id_dataset,
      observers = myobservers,
      id_digitiser = NEW.id_digitiser,
      id_nomenclature_obs_technique = NEW.id_nomenclature_obs_technique,
      id_nomenclature_grp_typ = NEW.id_nomenclature_grp_typ,
      date_min = (to_char(NEW.date_min, 'DD/MM/YYYY') || ' ' || COALESCE(to_char(NEW.hour_min, 'HH24:MI:SS'),'00:00:00'))::timestamp,
      date_max = (to_char(NEW.date_max, 'DD/MM/YYYY') || ' ' || COALESCE(to_char(NEW.hour_max, 'HH24:MI:SS'),'00:00:00'))::timestamp, 
      altitude_min = NEW.altitude_min,
      altitude_max = NEW.altitude_max,
      the_geom_4326 = NEW.geom_4326,
      the_geom_point = ST_CENTROID(NEW.geom_4326),
      last_action = 'U'
  WHERE unique_id_sinp IN (SELECT unnest(pr_occtax.get_unique_id_sinp_from_id_releve(NEW.id_releve_occtax::integer)));
  -- Récupération de l'occurrence pour le releve et mise à jour des commentaires avec celui de l'occurence seulement si le commentaire à changé
  IF NEW.comment = '' THEN NEW.comment = NULL; END IF;
  IF(NEW.comment IS DISTINCT FROM OLD.comment) THEN
      FOR theoccurrence IN SELECT * FROM pr_occtax.t_occurrences_occtax WHERE id_releve_occtax = NEW.id_releve_occtax
      LOOP
          UPDATE gn_synthese.synthese SET
                comments = CONCAT(COALESCE('Relevé : '||NEW.comment || ' / ', NULL ), COALESCE('Occurrence: '||theoccurrence.comment, NULL))
          WHERE unique_id_sinp IN (SELECT unnest(pr_occtax.get_unique_id_sinp_from_id_releve(NEW.id_releve_occtax::integer)));
      END LOOP;
  END IF;
  RETURN NULL;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

DROP VIEW pr_occtax.export_occtax_sinp;
CREATE OR REPLACE VIEW pr_occtax.export_occtax_sinp AS 
 SELECT ccc.unique_id_sinp_occtax AS "permId",
    ref_nomenclatures.get_cd_nomenclature(occ.id_nomenclature_observation_status) AS "statObs",
    occ.nom_cite AS "nomCite",
    rel.date_min AS "dateDebut",
    rel.date_max AS "dateFin",
    rel.hour_min AS "heureDebut",
    rel.hour_max AS "heureFin",
    rel.altitude_max AS "altMax",
    rel.altitude_min AS "altMin",
    occ.cd_nom AS "cdNom",
    taxonomie.find_cdref(occ.cd_nom) AS "cdRef",
    gn_commons.get_default_parameter('taxref_version'::text, NULL::integer) AS "versionTAXREF",
    rel.date_min AS datedet,
    occ.comment,
    'NSP'::text AS "dSPublique",
    d.unique_dataset_id AS "jddMetadonneeDEEId",
    ref_nomenclatures.get_cd_nomenclature(occ.id_nomenclature_source_status) AS "statSource",
    '0'::text AS "diffusionNiveauPrecision",
    ccc.unique_id_sinp_occtax AS "idOrigine",
    d.dataset_name AS "jddCode",
    d.unique_dataset_id AS "jddId",
    NULL::text AS "refBiblio",
    ref_nomenclatures.get_cd_nomenclature(occ.id_nomenclature_obs_meth) AS "obsMeth",
    ref_nomenclatures.get_cd_nomenclature(occ.id_nomenclature_bio_condition) AS "ocEtatBio",
    COALESCE(ref_nomenclatures.get_cd_nomenclature(occ.id_nomenclature_naturalness), '0'::text::character varying) AS "ocNat",
    ref_nomenclatures.get_cd_nomenclature(ccc.id_nomenclature_sex) AS "ocSex",
    ref_nomenclatures.get_cd_nomenclature(ccc.id_nomenclature_life_stage) AS "ocStade",
    '0'::text AS "ocBiogeo",
    COALESCE(ref_nomenclatures.get_cd_nomenclature(occ.id_nomenclature_bio_status), '0'::text::character varying) AS "ocStatBio",
    COALESCE(ref_nomenclatures.get_cd_nomenclature(occ.id_nomenclature_exist_proof), '0'::text::character varying) AS "preuveOui",
    ref_nomenclatures.get_nomenclature_label(occ.id_nomenclature_determination_method, 'fr'::character varying) AS "ocMethDet",
    occ.digital_proof AS "preuvNum",
    occ.non_digital_proof AS "preuvNoNum",
    rel.comment AS "obsCtx",
    rel.unique_id_sinp_grp AS "permIdGrp",
    'Relevé'::text AS "methGrp",
    'OBS'::text AS "typGrp",
    ccc.count_max AS "denbrMax",
    ccc.count_min AS "denbrMin",
    ref_nomenclatures.get_cd_nomenclature(ccc.id_nomenclature_obj_count) AS "objDenbr",
    ref_nomenclatures.get_cd_nomenclature(ccc.id_nomenclature_type_count) AS "typDenbr",
    COALESCE(string_agg(DISTINCT (r.nom_role::text || ' '::text || r.prenom_role::text), ','::text), rel.observers_txt::text) AS "obsId",
    COALESCE(string_agg(DISTINCT o.nom_organisme::text, ','::text), 'NSP'::text) AS "obsNomOrg",
    COALESCE(occ.determiner, 'Inconnu'::character varying) AS "detId",
    'NSP'::text AS "detNomOrg",
    'NSP'::text AS "orgGestDat",
    rel.geom_4326,
    st_astext(rel.geom_4326) AS "WKT",
    'In'::text AS "natObjGeo"
   FROM pr_occtax.t_releves_occtax rel
     LEFT JOIN pr_occtax.t_occurrences_occtax occ ON rel.id_releve_occtax = occ.id_releve_occtax
     LEFT JOIN pr_occtax.cor_counting_occtax ccc ON ccc.id_occurrence_occtax = occ.id_occurrence_occtax
     LEFT JOIN taxonomie.taxref tax ON tax.cd_nom = occ.cd_nom
     LEFT JOIN gn_meta.t_datasets d ON d.id_dataset = rel.id_dataset
     LEFT JOIN pr_occtax.cor_role_releves_occtax cr ON cr.id_releve_occtax = rel.id_releve_occtax
     LEFT JOIN utilisateurs.t_roles r ON r.id_role = cr.id_role
     LEFT JOIN utilisateurs.bib_organismes o ON o.id_organisme = r.id_organisme
  GROUP BY 
    ccc.unique_id_sinp_occtax
    ,d.unique_dataset_id
    , occ.id_nomenclature_bio_condition
    , occ.id_nomenclature_naturalness
    , ccc.id_nomenclature_sex
    , ccc.id_nomenclature_life_stage
    , occ.id_nomenclature_bio_status
    , occ.id_nomenclature_exist_proof
    , occ.id_nomenclature_determination_method
    , rel.unique_id_sinp_grp
    , d.id_nomenclature_source_status
    , occ.id_nomenclature_blurring
    , occ.id_nomenclature_diffusion_level
    , occ.nom_cite
    , rel.date_min
    , rel.date_max
    , rel.hour_min
    , rel.hour_max
    , rel.altitude_max
    , rel.altitude_min
    , occ.cd_nom
    , occ.id_nomenclature_observation_status
    , taxonomie.find_cdref(occ.cd_nom)
    , gn_commons.get_default_parameter('taxref_version'::text, NULL::integer)
    , rel.comment
    , rel.id_dataset
    , ref_nomenclatures.get_cd_nomenclature(occ.id_nomenclature_source_status)
    , ccc.id_counting_occtax
    , d.dataset_name
    , occ.determiner
    , occ.comment
    , ref_nomenclatures.get_cd_nomenclature(occ.id_nomenclature_obs_meth)
    , ref_nomenclatures.get_cd_nomenclature(occ.id_nomenclature_bio_condition)
    , ref_nomenclatures.get_cd_nomenclature(occ.id_nomenclature_naturalness)
    , ref_nomenclatures.get_cd_nomenclature(ccc.id_nomenclature_sex)
    , ref_nomenclatures.get_cd_nomenclature(ccc.id_nomenclature_life_stage)
    , ref_nomenclatures.get_cd_nomenclature(occ.id_nomenclature_bio_status)
    , ref_nomenclatures.get_cd_nomenclature(occ.id_nomenclature_exist_proof)
    , ref_nomenclatures.get_nomenclature_label(occ.id_nomenclature_determination_method)
    , occ.digital_proof
    , occ.non_digital_proof
    , ccc.count_max
    , ccc.count_min
    , ref_nomenclatures.get_cd_nomenclature(ccc.id_nomenclature_obj_count)
    , ref_nomenclatures.get_cd_nomenclature(ccc.id_nomenclature_type_count)
    , rel.observers_txt
    , rel.geom_4326;

DROP VIEW pr_occtax.export_occtax_dlb;
CREATE OR REPLACE VIEW pr_occtax.export_occtax_dlb AS 
 SELECT ccc.unique_id_sinp_occtax AS "permId",
    ref_nomenclatures.get_cd_nomenclature(occ.id_nomenclature_observation_status) AS "statObs",
    occ.nom_cite AS "nomCite",
    to_char(rel.date_min, 'DD/MM/YYYY'::text) AS "dateDebut",
    to_char(rel.date_max, 'DD/MM/YYYY'::text) AS "dateFin",
    rel.hour_min AS "heureDebut",
    rel.hour_max AS "heureFin",
    rel.altitude_max AS "altMax",
    rel.altitude_min AS "altMin",
    occ.cd_nom AS "cdNom",
    taxonomie.find_cdref(occ.cd_nom) AS "cdRef",
    to_char(rel.date_min, 'DD/MM/YYYY'::text) AS "dateDet",
    occ.comment,
    'NSP'::text AS "dSPublique",
    ref_nomenclatures.get_cd_nomenclature(occ.id_nomenclature_source_status) AS "statSource",
    ccc.unique_id_sinp_occtax AS "idOrigine",
    d.unique_dataset_id AS "jddId",
    NULL::text AS "refBiblio",
    ref_nomenclatures.get_cd_nomenclature(occ.id_nomenclature_obs_meth) AS "obsMeth",
    ref_nomenclatures.get_cd_nomenclature(occ.id_nomenclature_bio_condition) AS "ocEtatBio",
    COALESCE(ref_nomenclatures.get_cd_nomenclature(occ.id_nomenclature_naturalness), '0'::text::character varying) AS "ocNat",
    ref_nomenclatures.get_cd_nomenclature(ccc.id_nomenclature_sex) AS "ocSex",
    ref_nomenclatures.get_cd_nomenclature(ccc.id_nomenclature_life_stage) AS "ocStade",
    '0'::text AS "ocBiogeo",
    COALESCE(ref_nomenclatures.get_cd_nomenclature(occ.id_nomenclature_bio_status), '0'::text::character varying) AS "ocStatBio",
    COALESCE(ref_nomenclatures.get_cd_nomenclature(occ.id_nomenclature_exist_proof), '0'::text::character varying) AS "preuveOui",
    ref_nomenclatures.get_cd_nomenclature(occ.id_nomenclature_determination_method) AS "ocMethDet",
    occ.digital_proof AS "preuvNum",
    occ.non_digital_proof AS "preuvNoNum",
    rel.comment AS "obsCtx",
    rel.unique_id_sinp_grp AS "permIdGrp",
    'Relevé'::text AS "methGrp",
    'OBS'::text AS "typGrp",
    ccc.count_max AS "denbrMax",
    ccc.count_min AS "denbrMin",
    ref_nomenclatures.get_cd_nomenclature(ccc.id_nomenclature_obj_count) AS "objDenbr",
    ref_nomenclatures.get_cd_nomenclature(ccc.id_nomenclature_type_count) AS "typDenbr",
    COALESCE(string_agg(DISTINCT (r.nom_role::text || ' '::text || r.prenom_role::text), ','::text), rel.observers_txt::text) AS "obsId",
    COALESCE(string_agg(DISTINCT o.nom_organisme::text, ','::text), 'NSP'::text) AS "obsNomOrg",
    COALESCE(occ.determiner, 'Inconnu'::character varying) AS "detId",
    'NSP'::text AS "detNomOrg",
    'NSP'::text AS "orgGestDat",
    st_astext(rel.geom_4326) AS "WKT",
    'In'::text AS "natObjGeo",
    rel.date_min,
    rel.date_max,
    rel.id_dataset,
    rel.id_releve_occtax,
    occ.id_occurrence_occtax,
    rel.id_digitiser,
    rel.geom_4326
   FROM pr_occtax.t_releves_occtax rel
     LEFT JOIN pr_occtax.t_occurrences_occtax occ ON rel.id_releve_occtax = occ.id_releve_occtax
     LEFT JOIN pr_occtax.cor_counting_occtax ccc ON ccc.id_occurrence_occtax = occ.id_occurrence_occtax
     LEFT JOIN taxonomie.taxref tax ON tax.cd_nom = occ.cd_nom
     LEFT JOIN gn_meta.t_datasets d ON d.id_dataset = rel.id_dataset
     LEFT JOIN pr_occtax.cor_role_releves_occtax cr ON cr.id_releve_occtax = rel.id_releve_occtax
     LEFT JOIN utilisateurs.t_roles r ON r.id_role = cr.id_role
     LEFT JOIN utilisateurs.bib_organismes o ON o.id_organisme = r.id_organisme
  GROUP BY 
    rel.date_min
    , rel.date_max
    , rel.id_dataset
    , rel.unique_id_sinp_grp
    , occ.id_occurrence_occtax
    , rel.id_digitiser
    , ccc.unique_id_sinp_occtax
    , d.unique_dataset_id
    , occ.id_nomenclature_bio_condition
    , occ.id_nomenclature_naturalness
    , ccc.id_nomenclature_sex
    , ccc.id_nomenclature_life_stage
    , occ.id_nomenclature_bio_status
    , occ.id_nomenclature_exist_proof
    , occ.id_nomenclature_determination_method
    , rel.id_releve_occtax
    , d.id_nomenclature_source_status
    , occ.id_nomenclature_blurring
    , occ.id_nomenclature_diffusion_level
    , occ.nom_cite
    , rel.hour_min
    , rel.hour_max
    , rel.altitude_max
    , rel.altitude_min
    , occ.cd_nom
    , occ.id_nomenclature_observation_status
    , taxonomie.find_cdref(occ.cd_nom)
    , rel.comment
    , ref_nomenclatures.get_cd_nomenclature(occ.id_nomenclature_source_status)
    , ccc.id_counting_occtax
    , d.dataset_name
    , occ.determiner
    , occ.comment
    , ref_nomenclatures.get_cd_nomenclature(occ.id_nomenclature_obs_meth)
    , ref_nomenclatures.get_cd_nomenclature(occ.id_nomenclature_bio_condition)
    , ref_nomenclatures.get_cd_nomenclature(occ.id_nomenclature_naturalness)
    , ref_nomenclatures.get_cd_nomenclature(ccc.id_nomenclature_sex)
    , ref_nomenclatures.get_cd_nomenclature(ccc.id_nomenclature_life_stage)
    , ref_nomenclatures.get_cd_nomenclature(occ.id_nomenclature_bio_status)
    , ref_nomenclatures.get_cd_nomenclature(occ.id_nomenclature_exist_proof)
    , ref_nomenclatures.get_cd_nomenclature(occ.id_nomenclature_determination_method)
    , occ.digital_proof
    , occ.non_digital_proof
    , ccc.count_max
    , ccc.count_min
    , ref_nomenclatures.get_cd_nomenclature(ccc.id_nomenclature_obj_count)
    , ref_nomenclatures.get_cd_nomenclature(ccc.id_nomenclature_type_count)
    , rel.observers_txt  
    , rel.geom_4326;


----------------------------
----------------------------
-------- MONITORING --------
----------------------------
----------------------------

DROP TRIGGER trg_cor_site_area ON gn_monitoring.t_base_sites;
DROP TRIGGER tri_log_changes ON gn_monitoring.t_base_sites;
ALTER TABLE gn_monitoring.t_base_sites ALTER COLUMN geom SET DATA TYPE public.geometry(geometry,4326);
CREATE TRIGGER trg_cor_site_area
  AFTER INSERT OR UPDATE OF geom
  ON gn_monitoring.t_base_sites
  FOR EACH ROW
  EXECUTE PROCEDURE gn_monitoring.fct_trg_cor_site_area();
CREATE TRIGGER tri_log_changes
  AFTER INSERT OR UPDATE OR DELETE
  ON gn_monitoring.t_base_sites
  FOR EACH ROW
  EXECUTE PROCEDURE gn_commons.fct_trg_log_changes();


----------------------------
----------------------------
--------- COMMONS ----------
----------------------------
----------------------------

ALTER TABLE gn_commons.t_medias ALTER COLUMN uuid_attached_row DROP NOT NULL;
