-----------------------
-----FUNCTIONS----------
-----------------------
CREATE OR REPLACE FUNCTION pr_occtax.get_id_counting_from_id_releve(my_id_releve integer)
  RETURNS integer[] AS
$BODY$
-- Function which return the id_countings in an array (table pr_occtax.cor_counting_occtax) from the id_releve(integer)
DECLARE the_array_id_counting integer[];

BEGIN
SELECT INTO the_array_id_counting array_agg(counting.id_counting_occtax)
FROM pr_occtax.t_releves_occtax rel
JOIN pr_occtax.t_occurrences_occtax occ ON occ.id_releve_occtax = rel.id_releve_occtax
JOIN pr_occtax.cor_counting_occtax counting ON counting.id_occurrence_occtax = occ.id_occurrence_occtax
WHERE rel.id_releve_occtax = my_id_releve;
RETURN the_array_id_counting;
END;
$BODY$
  LANGUAGE plpgsql IMMUTABLE
  COST 100;

CREATE OR REPLACE FUNCTION pr_occtax.id_releve_from_id_counting(my_id_counting integer)
  RETURNS integer AS
$BODY$
-- Function which return the id_countings in an array (table pr_occtax.cor_counting_occtax) from the id_releve(integer)
DECLARE the_id_releve integer;

BEGIN
  SELECT INTO the_id_releve rel.id_releve_occtax
  FROM pr_occtax.t_releves_occtax rel
  JOIN pr_occtax.t_occurrences_occtax occ ON occ.id_releve_occtax = rel.id_releve_occtax
  JOIN pr_occtax.cor_counting_occtax counting ON counting.id_occurrence_occtax = occ.id_occurrence_occtax
  WHERE counting.id_counting_occtax = my_id_counting;

  RETURN the_id_releve;
END;
$BODY$
  LANGUAGE plpgsql IMMUTABLE
  COST 100;


CREATE OR REPLACE FUNCTION pr_occtax.insert_in_synthese(my_id_counting integer)
  RETURNS integer[] AS
  $BODY$
DECLARE

new_count RECORD;
occurrence RECORD;
releve RECORD;
id_source integer;
validation RECORD;
cd_nomenclature_source_status character varying;
observers RECORD;
id_municipality character varying;
id_role_loop integer;

BEGIN

--recupération du counting à partir de son ID
SELECT INTO new_count * FROM pr_occtax.cor_counting_occtax WHERE id_counting_occtax = my_id_counting;
-- Récupération de l'occurrence
SELECT INTO occurrence * FROM pr_occtax.t_occurrences_occtax occ WHERE occ.id_occurrence_occtax = new_count.id_occurrence_occtax;

-- Récupération du relevé

SELECT INTO releve * FROM pr_occtax.t_releves_occtax rel WHERE occurrence.id_releve_occtax = rel.id_releve_occtax;

-- Récupération de la source
SELECT INTO id_source s.id_source FROM gn_synthese.t_sources s WHERE lower(name_source) = 'occtax';

-- Récupération du status de validation du counting dans la table t_validation
SELECT INTO validation * FROM gn_commons.t_validations v WHERE uuid_attached_row = new_count.unique_id_sinp_occtax;

-- Récupération du status_source depuis le JDD
SELECT INTO cd_nomenclature_source_status ref_nomenclatures.get_cd_nomenclature(d.id_nomenclature_source_status) FROM gn_meta.t_datasets d WHERE id_dataset = releve.id_dataset;

-- Récupération de l'id_municipality par intersection avec ref_geo: pour les polygones on prend le centroid
SELECT INTO id_municipality m.insee_com
FROM ref_geo.li_municipalities m
JOIN ref_geo.l_areas a ON a.id_area = m.id_area
WHERE ST_INTERSECTS(ST_CENTROID(releve.geom_local), a.geom) AND a.id_type = 101;

--Récupération et formatage des observateurs
SELECT INTO observers array_to_string(array_agg(rol.nom_role || ' ' || rol.prenom_role), ', ') AS observers_name,
array_agg(rol.id_role) AS observers_id
FROM pr_occtax.cor_role_releves_occtax cor
JOIN utilisateurs.t_roles rol ON rol.id_role = cor.id_role
JOIN pr_occtax.t_releves_occtax rel ON rel.id_releve_occtax = cor.id_releve_occtax
WHERE cor.id_releve_occtax = releve.id_releve_occtax;


-- insertion dans la synthese
INSERT INTO gn_synthese.synthese (
unique_id_sinp,
unique_id_sinp_grp,
id_source,
entity_source_pk_value,
id_dataset,
cd_nomenclature_geo_object_nature,
cd_nomenclature_grp_typ,
cd_nomenclature_obs_meth,
cd_nomenclature_obs_technique,
cd_nomenclature_bio_status,
cd_nomenclature_bio_condition,
cd_nomenclature_naturalness,
cd_nomenclature_exist_proof,
cd_nomenclature_valid_status,
cd_nomenclature_diffusion_level,
cd_nomenclature_life_stage,
cd_nomenclature_sex,
cd_nomenclature_obj_count,
cd_nomenclature_type_count,
cd_nomenclature_sensitivity,
cd_nomenclature_observation_status,
cd_nomenclature_blurring,
cd_nomenclature_source_status,
cd_nomenclature_info_geo_type,
id_municipality,
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
-- id_area, TODO
date_min,
date_max,
id_validator,
validation_comment,
observers,
determiner,
cd_nomenclature_determination_method,
comments,
last_action
)

VALUES(
  new_count.unique_id_sinp_occtax,
  releve.unique_id_sinp_grp,
  id_source,
  new_count.id_counting_occtax,
  releve.id_dataset,
  --nature de l'objet geo: cd_nomenclature_geo_object_nature Le taxon observé est présent quelque part dans l'objet géographique - a ajouter dans default_nomenclature du schema occtax
  'In',
  ref_nomenclatures.get_cd_nomenclature(releve.id_nomenclature_grp_typ),
  ref_nomenclatures.get_cd_nomenclature(occurrence.id_nomenclature_obs_meth),
  ref_nomenclatures.get_cd_nomenclature(releve.id_nomenclature_obs_technique),
  ref_nomenclatures.get_cd_nomenclature(occurrence.id_nomenclature_bio_status),
  ref_nomenclatures.get_cd_nomenclature(occurrence.id_nomenclature_bio_condition),
  ref_nomenclatures.get_cd_nomenclature(occurrence.id_nomenclature_naturalness),
  ref_nomenclatures.get_cd_nomenclature(occurrence.id_nomenclature_exist_proof),
  -- statut de validation récupérer à partir de gn_commons.t_validations
  ref_nomenclatures.get_cd_nomenclature(validation.id_nomenclature_valid_status),
  ref_nomenclatures.get_cd_nomenclature(occurrence.id_nomenclature_diffusion_level),
  ref_nomenclatures.get_cd_nomenclature(new_count.id_nomenclature_life_stage),
  ref_nomenclatures.get_cd_nomenclature(new_count.id_nomenclature_sex),
  ref_nomenclatures.get_cd_nomenclature(new_count.id_nomenclature_obj_count),
  ref_nomenclatures.get_cd_nomenclature(new_count.id_nomenclature_type_count),
  -- cd_nomenclature_sensitivity le trigger qui calcule la sensibilité doit remplir le champs niveau de sensibilité, qui n'est pas présent dans occtax ??
  '0',
  ref_nomenclatures.get_cd_nomenclature(occurrence.id_nomenclature_observation_status),
  ref_nomenclatures.get_cd_nomenclature(occurrence.id_nomenclature_blurring),
  -- status_source récupéré depuis le JDD
  cd_nomenclature_source_status,
  -- cd_nomenclature_info_geo_type: type de rattachement = géoréferencement
  '1'	,
  id_municipality,
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
  (to_char(releve.date_min, 'DD/MM/YYYY') || ' ' || to_char(releve.date_min, 'hh:mm:ss'))::timestamp,
  (to_char(releve.date_max, 'DD/MM/YYYY') || ' ' || to_char(releve.date_max, 'hh:mm:ss'))::timestamp,
  validation.id_validator,
  validation.validation_comment,
  COALESCE (observers.observers_name, releve.observers_txt),
  occurrence.determiner,
  ref_nomenclatures.get_cd_nomenclature(occurrence.id_nomenclature_determination_method),
  CONCAT('Relevé : ',releve.comment, ' Occurrence: ', occurrence.comment),
  'I'
  );

  RETURN observers.observers_id ;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;




----------------------
--FUNCTIONS TRIGGERS--
----------------------
CREATE OR REPLACE FUNCTION pr_occtax.fct_tri_synthese_insert_counting()
  RETURNS trigger AS
  $BODY$
DECLARE
  observers integer[];
  the_id_synthese integer;
  the_id_releve integer;
  id_role_loop integer;

BEGIN

  -- recupération de l'id_releve_occtax
  SELECT INTO the_id_releve pr_occtax.id_releve_from_id_counting(NEW.id_counting_occtax::integer);
  -- recupération des observateurs
  SELECT INTO observers array_agg(id_role)
  FROM pr_occtax.cor_role_releves_occtax
  WHERE id_releve_occtax = the_id_releve;

  -- insertion en synthese du counting + occ + releve
  PERFORM pr_occtax.insert_in_synthese(NEW.id_counting_occtax::integer);

  -- recupération de l'id_synthese nouvelement créé
  SELECT INTO the_id_synthese id_synthese FROM gn_synthese.synthese WHERE unique_id_sinp = NEW.unique_id_sinp_occtax;

-- INSERTION DANS COR_ROLE_SYNTHESE
IF observers IS NOT NULL THEN
  FOREACH id_role_loop IN ARRAY observers
    LOOP
      INSERT INTO gn_synthese.cor_role_synthese (id_synthese, id_role) VALUES (the_id_synthese, id_role_loop);
    END LOOP;
  END IF;

  RETURN NULL;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;



CREATE OR REPLACE FUNCTION pr_occtax.fct_tri_synthese_delete_counting()
RETURNS trigger AS
$BODY$
DECLARE
  the_id_source integer;
  the_id_synthese integer;
  nb_counting integer;
BEGIN
  -- recupération de l'id_source
  SELECT INTO the_id_source id_source FROM gn_synthese.t_sources WHERE name_source = 'occtax';
  SELECT INTO the_id_synthese id_synthese
  FROM gn_synthese.synthese
  WHERE id_source = the_id_source AND entity_source_pk_value = to_char(OLD.id_counting_occtax, 'FM9999');
  -- suppression de l'obs dans le schéma gn_synthese
  DELETE FROM gn_synthese.cor_role_synthese WHERE id_synthese = the_id_synthese;
  DELETE FROM gn_synthese.cor_area_synthese WHERE id_synthese = the_id_synthese;
  DELETE FROM gn_synthese.synthese WHERE id_synthese = the_id_synthese;
  -- suppression de l'occurrence s'il n'y a plus de dénomenbrement
  SELECT INTO nb_counting count(*) FROM pr_occtax.cor_counting_occtax WHERE id_occurrence_occtax = OLD.id_occurrence_occtax;
  IF nb_counting < 1 THEN
    DELETE FROM pr_occtax.t_occurrences_occtax WHERE id_occurrence_occtax = OLD.id_occurrence_occtax;
  END IF;

  RETURN NULL;
END;
$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;


  -- UPDATE counting
CREATE OR REPLACE FUNCTION pr_occtax.fct_tri_synthese_update_counting()
RETURNS trigger AS
$BODY$
DECLARE
  the_id_source integer;
BEGIN

  -- recupération de l'id_source
  SELECT INTO the_id_source id_source FROM gn_synthese.t_sources WHERE name_source = 'occtax';
  -- update dans la synthese
  UPDATE gn_synthese.synthese
  SET
  cd_nomenclature_life_stage = ref_nomenclatures.get_cd_nomenclature(NEW.id_nomenclature_life_stage),
  cd_nomenclature_sex = ref_nomenclatures.get_cd_nomenclature(NEW.id_nomenclature_sex),
  cd_nomenclature_obj_count = ref_nomenclatures.get_cd_nomenclature(NEW.id_nomenclature_obj_count),
  cd_nomenclature_type_count = ref_nomenclatures.get_cd_nomenclature(NEW.id_nomenclature_type_count),
  count_min = NEW.count_min,
  count_max = NEW.count_max
  WHERE id_source = the_id_source AND entity_source_pk_value = NEW.id_counting_occtax::text;
  RETURN NULL;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

-- UPDATE Occurrence
-- TODO: SENSIBILITE NON GEREE
CREATE OR REPLACE FUNCTION pr_occtax.fct_tri_synthese_update_occ()
RETURNS trigger AS
$BODY$
DECLARE
  the_id_source integer;
  nb_counting integer;
  releve RECORD;
  counting RECORD;
BEGIN
  -- recupération de l'id_source
  SELECT INTO the_id_source id_source FROM gn_synthese.t_sources WHERE name_source = 'occtax';
  -- récupération du releve pour le commentaire à concatener
  SELECT INTO releve * FROM pr_occtax.t_releves_occtax WHERE id_releve_occtax = NEW.id_releve_occtax;

  FOR counting IN SELECT * FROM pr_occtax.cor_counting_occtax WHERE id_occurrence_occtax = NEW.id_occurrence_occtax LOOP
    UPDATE gn_synthese.synthese SET
    cd_nomenclature_obs_meth = ref_nomenclatures.get_cd_nomenclature(NEW.id_nomenclature_obs_meth),
    cd_nomenclature_bio_condition = ref_nomenclatures.get_cd_nomenclature(NEW.id_nomenclature_bio_condition),
    cd_nomenclature_bio_status = ref_nomenclatures.get_cd_nomenclature(NEW.id_nomenclature_bio_status),
    cd_nomenclature_naturalness = ref_nomenclatures.get_cd_nomenclature(NEW.id_nomenclature_naturalness),
    cd_nomenclature_exist_proof = ref_nomenclatures.get_cd_nomenclature(NEW.id_nomenclature_exist_proof),
    cd_nomenclature_diffusion_level = ref_nomenclatures.get_cd_nomenclature(NEW.id_nomenclature_diffusion_level),
    cd_nomenclature_observation_status = ref_nomenclatures.get_cd_nomenclature(NEW.id_nomenclature_observation_status),
    cd_nomenclature_blurring = ref_nomenclatures.get_cd_nomenclature(NEW.id_nomenclature_blurring),
    cd_nomenclature_source_status = ref_nomenclatures.get_cd_nomenclature(NEW.id_nomenclature_source_status),
    determiner = determiner,
    cd_nomenclature_determination_method = ref_nomenclatures.get_cd_nomenclature(NEW.id_nomenclature_determination_method),
    cd_nom = NEW.cd_nom,
    nom_cite = NEW.nom_cite,
    meta_v_taxref = NEW.meta_v_taxref,
    sample_number_proof = NEW.sample_number_proof,
    digital_proof = NEW.digital_proof,
    non_digital_proof = NEW.non_digital_proof,
    comments  = CONCAT('Relevé : ',releve.comment, 'Occurrence: ', NEW.comment)
    WHERE id_source = the_id_source AND entity_source_pk_value = counting.id_counting_occtax::text;
  END LOOP;

  RETURN NULL;
END;
$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;

-- DELETE OCCURRENCE
CREATE OR REPLACE FUNCTION pr_occtax.fct_tri_synthese_delete_occ()
RETURNS trigger AS
$BODY$
DECLARE
  the_id_source integer;
  the_id_synthese integer;
  nb_occ integer;
  nb_counting integer;
  counting RECORD;
BEGIN
  -- recupération de l'id_source
  SELECT INTO the_id_source id_source FROM gn_synthese.t_sources WHERE name_source = 'occtax';
  -- suppression dans la synthese
  FOR counting IN SELECT * FROM pr_occtax.cor_counting_occtax WHERE id_occurrence_occtax = OLD.id_occurrence_occtax LOOP
    SELECT INTO the_id_synthese id_synthese
    FROM gn_synthese.id_synthese
    WHERE id_source = the_id_source AND entity_source_pk_value = to_char(counting.id_counting_occtax, 'FM9999');
     -- suppression de l'obs dans le schéma gn_synthese
    DELETE FROM gn_synthese.cor_role_synthese WHERE id_synthese = the_id_synthese;
    DELETE FROM gn_synthese.cor_area_synthese WHERE id_synthese = the_id_synthese;
    DELETE FROM gn_synthese.synthese WHERE id_synthese = the_id_synthese;  END LOOP;
  -- suppression de l'occurrence s'il n'y a plus de dénomenbrement
  SELECT INTO nb_counting count(*) FROM pr_occtax.t_occurrences_occtax WHERE id_occurrence_occtax = OLD.id_releve_occtax;
  IF nb_counting < 1 THEN
    DELETE FROM pr_occtax.t_releves_occtax WHERE id_releve_occtax = OLD.id_releve_occtax;
  END IF;

  RETURN OLD;
END;
$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;

-- UPDATE Releve
CREATE OR REPLACE FUNCTION pr_occtax.fct_tri_synthese_update_releve()
RETURNS trigger AS
$BODY$
DECLARE
  the_id_source integer;
  occurrence RECORD;
  counting RECORD;
  role RECORD;
BEGIN
  -- recupération de l'id_source
  SELECT INTO the_id_source id_source FROM gn_synthese.t_sources WHERE name_source = 'occtax';
  FOR occurrence IN SELECT * FROM pr_occtax.t_occurrences_occtax WHERE id_releve_occtax = NEW.id_releve_occtax LOOP
    FOR counting IN SELECT * FROM pr_occtax.cor_counting_occtax WHERE id_occurrence_occtax = occurrence.id_occurrence_occtax LOOP
      UPDATE gn_synthese.synthese SET
      id_dataset = NEW.id_dataset,
      observers = NEW.observers_txt,
      cd_nomenclature_obs_technique = ref_nomenclatures.get_cd_nomenclature(NEW.id_nomenclature_obs_technique),
      cd_nomenclature_grp_typ = ref_nomenclatures.get_cd_nomenclature(NEW.id_nomenclature_grp_typ),
      date_min = (to_char(NEW.date_min, 'DD/MM/YYYY') || ' ' || COALESCE(to_char(NEW.hour_min, 'hh:mm:ss'), '00:00:00'))::timestamp,
      date_max = (to_char(NEW.date_max, 'DD/MM/YYYY') || ' ' || COALESCE(to_char(NEW.hour_max, 'hh:mm:ss'), '00:00:00'))::timestamp,
      altitude_min = NEW.altitude_min,
      altitude_max = NEW.altitude_max,
      comments = CONCAT('Relevé : ',NEW.comment, 'Occurrence: ', occurrence.comment),
      the_geom_local = NEW.geom_local,
      the_geom_4326 = NEW.geom_4326,
      the_geom_point = ST_CENTROID(NEW.geom_4326)
      WHERE id_source = the_id_source AND entity_source_pk_value = counting.id_counting_occtax::text;
    END LOOP;
  END LOOP;
  RETURN NULL;
END;
$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;

-- suppression d'un relevé
CREATE OR REPLACE FUNCTION pr_occtax.fct_tri_synthese_delete_releve()
RETURNS trigger AS
$BODY$
DECLARE
  the_id_source integer;
  the_id_synthese integer;
  occurrence RECORD;
  counting RECORD;
BEGIN
  SELECT INTO the_id_source id_source FROM gn_synthese.t_sources WHERE name_source = 'occtax';
    FOR occurrence IN SELECT * FROM pr_occtax.t_occurrences_occtax WHERE id_releve_occtax = OLD.id_releve_occtax LOOP
      FOR counting IN SELECT * FROM pr_occtax.cor_counting_occtax WHERE id_occurrence_occtax = occurrence.id_occurrence_occtax LOOP
        SELECT INTO the_id_synthese id_synthese
        FROM gn_synthese.id_synthese
        WHERE id_source = the_id_source AND entity_source_pk_value = to_char(counting.id_counting_occtax, 'FM9999');
     -- suppression de l'obs dans le schéma gn_synthese
        DELETE FROM gn_synthese.cor_role_synthese WHERE id_synthese = the_id_synthese;
        DELETE FROM gn_synthese.cor_area_synthese WHERE id_synthese = the_id_synthese;
        DELETE FROM gn_synthese.synthese WHERE id_synthese = the_id_synthese;
      END LOOP;
    END LOOP;
  RETURN OLD;
END;
$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;

-- trigger insertion cor_role_releve_occtax

CREATE OR REPLACE FUNCTION pr_occtax.fct_tri_synthese_insert_cor_role_releve()
RETURNS trigger AS
$BODY$
DECLARE
  the_id_countings  integer[];
  the_id_counting integer;
  the_id_synthese integer;
  the_id_source integer;

BEGIN
-- recupération de l'id_source
  SELECT INTO the_id_source s.id_source FROM gn_synthese.t_sources s WHERE name_source = 'occtax';
  -- récupération des id_counting à partir de l'id_releve
  SELECT INTO the_id_countings pr_occtax.get_id_counting_from_id_releve(NEW.id_releve_occtax::integer);

  IF the_id_countings IS NOT NULL THEN
    FOREACH the_id_counting IN ARRAY the_id_countings
    LOOP
      SELECT INTO the_id_synthese id_synthese
      FROM gn_synthese.synthese
      WHERE id_source = the_id_source AND entity_source_pk_value = the_id_counting::text;
      -- insertion dans cor_role_synthese pour chaque counting
      INSERT INTO gn_synthese.cor_role_synthese(id_synthese, id_role) VALUES(
        the_id_synthese,
        NEW.id_role
      );
    END LOOP;
  END IF;
RETURN NULL;
END;
$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;

CREATE OR REPLACE FUNCTION pr_occtax.fct_tri_synthese_update_cor_role_releve()
RETURNS trigger AS
$BODY$
DECLARE
  the_id_countings  integer[];
  the_id_counting integer;
  the_id_synthese integer;
  the_id_source integer;

BEGIN

-- recupération de l'id_source
  SELECT INTO the_id_source s.id_source FROM gn_synthese.t_sources s WHERE name_source = 'occtax';
  -- récupération des id_counting à partir de l'id_releve
  SELECT INTO the_id_countings pr_occtax.get_id_counting_from_id_releve(NEW.id_releve_occtax::integer);
  IF the_id_countings IS NOT NULL THEN
    FOREACH the_id_counting IN ARRAY the_id_countings
    LOOP
      SELECT INTO the_id_synthese id_synthese
      FROM gn_synthese.synthese
      WHERE id_source = the_id_source AND entity_source_pk_value = the_id_counting::text;
      -- update dans cor_role_synthese pour chaque counting
      UPDATE gn_synthese.cor_role_synthese SET
        id_synthese = the_id_synthese,
        id_role = NEW.id_role
        WHERE id_synthese = the_id_synthese AND id_role = OLD.id_role;
    END LOOP;
  END IF;
RETURN NULL;
END;
$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;


CREATE OR REPLACE FUNCTION pr_occtax.fct_tri_synthese_delete_cor_role_releve()
RETURNS trigger AS
$BODY$
DECLARE
  the_id_countings  integer[];
  the_id_counting integer;
  the_id_synthese integer;
  the_id_source integer;

BEGIN
-- recupération de l'id_source
  SELECT INTO the_id_source s.id_source FROM gn_synthese.t_sources s WHERE name_source = 'occtax';
  -- récupération des id_counting à partir de l'id_releve
  SELECT INTO the_id_countings pr_occtax.get_id_counting_from_id_releve(OLD.id_releve_occtax::integer);
  IF the_id_countings IS NOT NULL THEN
  FOREACH the_id_counting IN ARRAY the_id_countings
    LOOP
      SELECT INTO the_id_synthese id_synthese
      FROM gn_synthese.synthese
      WHERE id_source = the_id_source AND entity_source_pk_value = the_id_counting::text;
      -- suppression dans cor_role_synthese pour chaque counting
      DELETE FROM gn_synthese.cor_role_synthese
      WHERE id_synthese = the_id_synthese AND id_role = OLD.id_role;
    END LOOP;
  END IF;
RETURN NULL;
END;

$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;

$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;

------------
--TRIGGERS--
------------

CREATE TRIGGER tri_insert_synthese_cor_counting_occtax
    AFTER INSERT
    ON pr_occtax.cor_counting_occtax
    FOR EACH ROW
    EXECUTE PROCEDURE pr_occtax.fct_tri_synthese_insert_counting();

CREATE TRIGGER tri_delete_synthese_cor_counting_occtax
  AFTER DELETE
  ON pr_occtax.cor_counting_occtax
  FOR EACH ROW
  EXECUTE PROCEDURE pr_occtax.fct_tri_synthese_delete_counting();

CREATE TRIGGER tri_update_synthese_cor_counting_occtax
  AFTER UPDATE
  ON pr_occtax.cor_counting_occtax
  FOR EACH ROW
  EXECUTE PROCEDURE pr_occtax.fct_tri_synthese_update_counting();

CREATE TRIGGER tri_update_synthese_t_occurrence_occtax
  AFTER UPDATE
  ON pr_occtax.t_occurrences_occtax
  FOR EACH ROW
  EXECUTE PROCEDURE pr_occtax.fct_tri_synthese_update_occ();

CREATE TRIGGER tri_delete_synthese_t_occurrence_occtax
  AFTER DELETE
  ON pr_occtax.t_occurrences_occtax
  FOR EACH ROW
  EXECUTE PROCEDURE pr_occtax.fct_tri_synthese_delete_occ();

CREATE TRIGGER tri_update_synthese_t_releve_occtax
  AFTER UPDATE
  ON pr_occtax.t_releves_occtax
  FOR EACH ROW
  EXECUTE PROCEDURE pr_occtax.fct_tri_synthese_update_releve();

CREATE TRIGGER tri_delete_synthese_t_releve_occtax
  AFTER DELETE
  ON pr_occtax.t_releves_occtax
  FOR EACH ROW
  EXECUTE PROCEDURE pr_occtax.fct_tri_synthese_delete_releve();

CREATE TRIGGER tri_insert_synthese_cor_role_releves_occtax
  AFTER INSERT
  ON pr_occtax.cor_role_releves_occtax
  FOR EACH ROW
  EXECUTE PROCEDURE pr_occtax.fct_tri_synthese_insert_cor_role_releve();

CREATE TRIGGER tri_update_synthese_cor_role_releves_occtax
  AFTER UPDATE
  ON pr_occtax.cor_role_releves_occtax
  FOR EACH ROW
  EXECUTE PROCEDURE pr_occtax.fct_tri_synthese_update_cor_role_releve();

CREATE TRIGGER tri_delete_synthese_cor_role_releves_occtax
  AFTER DELETE
  ON pr_occtax.cor_role_releves_occtax
  FOR EACH ROW
  EXECUTE PROCEDURE pr_occtax.fct_tri_synthese_delete_cor_role_releve();
