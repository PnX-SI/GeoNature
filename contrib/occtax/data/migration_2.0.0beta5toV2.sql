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


CREATE OR REPLACE FUNCTION pr_occtax.get_unique_id_sinp_from_id_releve(my_id_releve integer)
  RETURNS integer[] AS
$BODY$
-- Function which return the unique_id_sinp_occtax in an array (table pr_occtax.cor_counting_occtax) from the id_releve(integer)
DECLARE the_array_uuid_sinp integer[];

BEGIN
SELECT INTO the_array_uuid_sinp array_agg(counting.unique_id_sinp_occtax)
FROM pr_occtax.t_releves_occtax rel
JOIN pr_occtax.t_occurrences_occtax occ ON occ.id_releve_occtax = rel.id_releve_occtax
JOIN pr_occtax.cor_counting_occtax counting ON counting.id_occurrence_occtax = occ.id_occurrence_occtax
WHERE rel.id_releve_occtax = my_id_releve;
RETURN the_array_uuid_sinp;
END;
$BODY$
  LANGUAGE plpgsql IMMUTABLE
  COST 100;


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
observers RECORD;
id_role_loop integer;

BEGIN

--recupération du counting à partir de son ID
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
  --nature de l'objet geo: id_nomenclature_geo_object_nature Le taxon observé est présent quelque part dans l'objet géographique - NSP par défault
  pr_occtax.get_default_nomenclature_value('NAT_OBJ_GEO'),
  releve.id_nomenclature_grp_typ,
  occurrence.id_nomenclature_obs_meth,
  releve.id_nomenclature_obs_technique,
  occurrence.id_nomenclature_bio_status,
  occurrence.id_nomenclature_bio_condition,
  occurrence.id_nomenclature_naturalness,
  occurrence.id_nomenclature_exist_proof,
    -- statut de validation récupérer à partir de gn_commons.t_validations
  validation.id_nomenclature_valid_status,
  occurrence.id_nomenclature_diffusion_level,
  new_count.id_nomenclature_life_stage,
  new_count.id_nomenclature_sex,
  new_count.id_nomenclature_obj_count,
  new_count.id_nomenclature_type_count,
  occurrence.id_nomenclature_observation_status,
  occurrence.id_nomenclature_blurring,
  -- status_source récupéré depuis le JDD
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
  (to_char(releve.date_min, 'DD/MM/YYYY') || ' ' || to_char(releve.date_min, 'hh:mm:ss'))::timestamp,
  (to_char(releve.date_max, 'DD/MM/YYYY') || ' ' || to_char(releve.date_max, 'hh:mm:ss'))::timestamp,
  validation.validator_full_name,
  validation.validation_comment,
  COALESCE (observers.observers_name, releve.observers_txt),
  occurrence.determiner,
  releve.id_digitiser,
  occurrence.id_nomenclature_determination_method,
  CONCAT('Relevé : ', COALESCE(releve.comment, ' - '), 'Occurrence: ', COALESCE(occurrence.comment, ' -')),
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
-- Insert counting
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
      INSERT INTO gn_synthese.cor_observer_synthese (id_synthese, id_role) VALUES (the_id_synthese, id_role_loop);
    END LOOP;
  END IF;

  RETURN NULL;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;


-- DELETE counting
CREATE OR REPLACE FUNCTION pr_occtax.fct_tri_synthese_delete_counting()
RETURNS trigger AS
$BODY$
DECLARE
BEGIN
  -- suppression de l'obs dans le schéma gn_synthese
  DELETE FROM gn_synthese.synthese WHERE unique_id_sinp = OLD.unique_id_sinp_occtax;
  RETURN NULL;
END;
$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;


-- DELETE counting
CREATE OR REPLACE FUNCTION pr_occtax.fct_tri_delete_counting()
RETURNS trigger AS
$BODY$
DECLARE
  nb_counting integer;
BEGIN
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
BEGIN

  -- update dans la synthese
  UPDATE gn_synthese.synthese
  SET
  entity_source_pk_value = NEW.id_counting_occtax,
  id_nomenclature_life_stage = NEW.id_nomenclature_life_stage,
  id_nomenclature_sex = NEW.id_nomenclature_sex,
  id_nomenclature_obj_count = NEW.id_nomenclature_obj_count,
  id_nomenclature_type_count = NEW.id_nomenclature_type_count,
  count_min = NEW.count_min,
  count_max = NEW.count_max,
  last_action = 'U'
  WHERE unique_id_sinp = NEW.unique_id_sinp_occtax;
  IF(NEW.unique_id_sinp_occtax <> OLD.unique_id_sinp_occtax) THEN
      RAISE EXCEPTION 'ATTENTION : %', 'Le champ "unique_id_sinp_occtax" est généré par GeoNature et ne doit pas être changé.'
		       || chr(10) || 'Il est utilisé par le SINP pour identifier de manière unique une observation.'
		       || chr(10) || 'Si vous le changez, le SINP considérera cette observation comme une nouvelle observation.'
		       || chr(10) || 'Si vous souhaitez vraiment le changer, désactivez ce trigger, faite le changement, réactiez ce trigger'
		       || chr(10) || 'ET répercutez manuellement les changements dans "gn_synthese.synthese".';
  END IF;
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
  releve RECORD;
BEGIN
  -- récupération du releve pour le commentaire à concatener
  SELECT INTO releve * FROM pr_occtax.t_releves_occtax WHERE id_releve_occtax = NEW.id_releve_occtax;

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
    comments  = CONCAT('Relevé : ',COALESCE(releve.comment, '-' ), ' Occurrence: ', COALESCE(NEW.comment, '-' )),
    last_action = 'U'
    WHERE unique_id_sinp IN (SELECT unique_id_sinp_occtax FROM pr_occtax.cor_counting_occtax WHERE id_occurrence_occtax = NEW.id_occurrence_occtax);

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
BEGIN
  -- suppression dans la synthese
    DELETE FROM gn_synthese.synthese WHERE unique_id_sinp IN (
      SELECT unique_id_sinp_occtax FROM pr_occtax.cor_counting_occtax WHERE id_occurrence_occtax = OLD.id_occurrence_occtax 
    );
  RETURN OLD;
END;
$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;

CREATE OR REPLACE FUNCTION pr_occtax.fct_tri_delete_occ()
RETURNS trigger AS
$BODY$
DECLARE
nb_occ integer;
BEGIN
  -- suppression du releve s'il n'y a plus d'occurrence
  SELECT INTO nb_occ count(*) FROM pr_occtax.t_occurrences_occtax WHERE id_releve_occtax = OLD.id_releve_occtax;
  IF nb_occ < 1 THEN
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
  theoccurrence RECORD;
  theobservers character varying;
BEGIN
 
  IF NEW.observers_txt IS NULL THEN
    SELECT INTO theobservers array_to_string(array_agg(rol.nom_role || ' ' || rol.prenom_role), ', ')
    FROM pr_occtax.cor_role_releves_occtax cor
    JOIN utilisateurs.t_roles rol ON rol.id_role = cor.id_role
    JOIN pr_occtax.t_releves_occtax rel ON rel.id_releve_occtax = cor.id_releve_occtax
    WHERE cor.id_releve_occtax = NEW.id_releve_occtax;
  ELSE 
    theobservers:= NEW.observers_txt;
  END IF;
  --mise à jour en synthese des informations correspondant au relevé uniquement
  UPDATE gn_synthese.synthese SET
      id_dataset = NEW.id_dataset,
      observers = theobservers,
      id_digitiser = NEW.id_digitiser,
      id_nomenclature_obs_technique = NEW.id_nomenclature_obs_technique,
      id_nomenclature_grp_typ = NEW.id_nomenclature_grp_typ,
      date_min = (to_char(NEW.date_min, 'DD/MM/YYYY') || ' ' || COALESCE(to_char(NEW.hour_min, 'hh:mm:ss'), '00:00:00'))::timestamp,
      date_max = (to_char(NEW.date_max, 'DD/MM/YYYY') || ' ' || COALESCE(to_char(NEW.hour_max, 'hh:mm:ss'), '00:00:00'))::timestamp,
      altitude_min = NEW.altitude_min,
      altitude_max = NEW.altitude_max,
      the_geom_4326 = NEW.geom_4326,
      the_geom_point = ST_CENTROID(NEW.geom_4326),
      last_action = 'U'
  WHERE unique_id_sinp IN (SELECT unnest(pr_occtax.get_unique_id_sinp_from_id_releve(NEW.id_releve_occtax::integer)));
  -- récupération de l'occurrence pour le releve et mise à jour des commentaires avec celui de l'occurence seulement si le commentaire à changé
  IF(NEW.comment <> OLD.comment) THEN
      FOR theoccurrence IN SELECT * FROM pr_occtax.t_occurrences_occtax WHERE id_releve_occtax = NEW.id_releve_occtax
      LOOP
          UPDATE gn_synthese.synthese SET
                comments = CONCAT('Relevé: ',COALESCE(NEW.comment, '-'), 'Occurrence: ', COALESCE(theoccurrence.comment, '-'))
          WHERE unique_id_sinp IN (SELECT unnest(pr_occtax.get_unique_id_sinp_from_id_releve(NEW.id_releve_occtax::integer)));
      END LOOP;
  END IF;
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
BEGIN
    DELETE FROM gn_synthese.synthese WHERE unique_id_sinp IN (
      SELECT unnest(pr_occtax.get_unique_id_sinp_from_id_releve(OLD.id_releve_occtax::integer))
    );
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
  the_uuid_countings  uuid[];
  the_uuid_counting uuid;
  the_id_synthese integer;

BEGIN
  -- récupération des uuid_counting à partir de l'id_releve
  SELECT INTO the_uuid_countings pr_occtax.get_unique_id_sinp_from_id_releve(NEW.id_releve_occtax::integer);

  IF the_uuid_countings IS NOT NULL THEN
    FOREACH the_uuid_counting IN ARRAY the_uuid_countings
    LOOP
      SELECT INTO the_id_synthese id_synthese
      FROM gn_synthese.synthese
      WHERE  unique_id_sinp = the_uuid_counting;
      -- insertion dans cor_role_synthese pour chaque counting
      INSERT INTO gn_synthese.cor_observer_synthese(id_synthese, id_role) VALUES(
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


-- trigger update cor_role_releve_occtax
CREATE OR REPLACE FUNCTION pr_occtax.fct_tri_synthese_update_cor_role_releve()
RETURNS trigger AS
$BODY$
DECLARE
  the_uuid_countings  uuid[];
  the_uuid_counting uuid;
  the_id_synthese integer;
BEGIN
  -- récupération des id_counting à partir de l'id_releve
  SELECT INTO the_uuid_countings pr_occtax.get_unique_id_sinp_from_id_releve(NEW.id_releve_occtax::integer);
  IF the_uuid_countings IS NOT NULL THEN
    FOREACH the_uuid_counting IN ARRAY the_uuid_countings
    LOOP
      SELECT INTO the_id_synthese id_synthese
      FROM gn_synthese.synthese
      WHERE unique_id_sinp = the_uuid_counting;
      -- update dans cor_role_synthese pour chaque counting
      UPDATE gn_synthese.cor_observer_synthese SET
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

-- delete cor_role
CREATE OR REPLACE FUNCTION pr_occtax.fct_tri_synthese_delete_cor_role_releve()
RETURNS trigger AS
$BODY$
DECLARE
  the_uuid_countings  uuid[];
  the_uuid_counting uuid;
  the_id_synthese integer;
BEGIN
  -- récupération des id_counting à partir de l'id_releve
  SELECT INTO the_uuid_countings pr_occtax.get_unique_id_sinp_from_id_releve(OLD.id_releve_occtax::integer);
  IF the_uuid_countings IS NOT NULL THEN
  FOREACH the_uuid_counting IN ARRAY the_uuid_countings
    LOOP
      SELECT INTO the_id_synthese id_synthese
      FROM gn_synthese.synthese
      WHERE unique_id_sinp = the_uuid_counting;
      -- suppression dans cor_role_synthese pour chaque counting
      DELETE FROM gn_synthese.cor_observer_synthese
      WHERE id_synthese = the_id_synthese AND id_role = OLD.id_role;
    END LOOP;
  END IF;
RETURN NULL;
END;

$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;


------------
--TRIGGERS--
------------


CREATE TRIGGER tri_insert_default_validation_status
  AFTER INSERT
  ON cor_counting_occtax
  FOR EACH ROW
  EXECUTE PROCEDURE gn_commons.fct_trg_add_default_validation_status();

CREATE TRIGGER tri_log_changes_cor_counting_occtax
  AFTER INSERT OR UPDATE OR DELETE
  ON cor_counting_occtax
  FOR EACH ROW
  EXECUTE PROCEDURE gn_commons.fct_trg_log_changes();

CREATE TRIGGER tri_log_changes_t_occurrences_occtax
  AFTER INSERT OR UPDATE OR DELETE
  ON t_occurrences_occtax
  FOR EACH ROW
  EXECUTE PROCEDURE gn_commons.fct_trg_log_changes();

CREATE TRIGGER tri_log_changes_t_releves_occtax
  AFTER INSERT OR UPDATE OR DELETE
  ON t_releves_occtax
  FOR EACH ROW
  EXECUTE PROCEDURE gn_commons.fct_trg_log_changes();

CREATE TRIGGER tri_log_changes_cor_role_releves_occtax
  AFTER INSERT OR UPDATE OR DELETE
  ON cor_role_releves_occtax
  FOR EACH ROW
  EXECUTE PROCEDURE gn_commons.fct_trg_log_changes();

CREATE TRIGGER tri_calculate_geom_local
  BEFORE INSERT OR UPDATE
  ON pr_occtax.t_releves_occtax
  FOR EACH ROW
  EXECUTE PROCEDURE ref_geo.fct_trg_calculate_geom_local('geom_4326', 'geom_local');

  -- triggers vers la synthese

DROP TRIGGER IF EXISTS tri_insert_synthese_cor_counting_occtax ON pr_occtax.cor_counting_occtax;
CREATE TRIGGER tri_insert_synthese_cor_counting_occtax
    AFTER INSERT
    ON pr_occtax.cor_counting_occtax
    FOR EACH ROW
    EXECUTE PROCEDURE pr_occtax.fct_tri_synthese_insert_counting();

DROP TRIGGER IF EXISTS tri_update_synthese_cor_counting_occtax ON pr_occtax.cor_counting_occtax;
CREATE TRIGGER tri_update_synthese_cor_counting_occtax
  AFTER UPDATE
  ON pr_occtax.cor_counting_occtax
  FOR EACH ROW
  EXECUTE PROCEDURE pr_occtax.fct_tri_synthese_update_counting();

DROP TRIGGER IF EXISTS tri_delete_synthese_cor_counting_occtax ON pr_occtax.cor_counting_occtax;
CREATE TRIGGER tri_delete_synthese_cor_counting_occtax
  AFTER DELETE
  ON pr_occtax.cor_counting_occtax
  FOR EACH ROW
  EXECUTE PROCEDURE pr_occtax.fct_tri_synthese_delete_counting();

DROP TRIGGER IF EXISTS tri_delete_cor_counting_occtax ON pr_occtax.cor_counting_occtax;
CREATE TRIGGER tri_delete_cor_counting_occtax
  AFTER DELETE
  ON pr_occtax.cor_counting_occtax
  FOR EACH ROW
  EXECUTE PROCEDURE pr_occtax.fct_tri_delete_counting();

DROP TRIGGER IF EXISTS tri_update_synthese_t_occurrence_occtax ON pr_occtax.t_occurrences_occtax;
CREATE TRIGGER tri_update_synthese_t_occurrence_occtax
  AFTER UPDATE
  ON pr_occtax.t_occurrences_occtax
  FOR EACH ROW
  EXECUTE PROCEDURE pr_occtax.fct_tri_synthese_update_occ();

DROP TRIGGER IF EXISTS tri_delete_synthese_t_occurrence_occtax ON pr_occtax.t_occurrences_occtax;
CREATE TRIGGER tri_delete_synthese_t_occurrence_occtax
  AFTER DELETE
  ON pr_occtax.t_occurrences_occtax
  FOR EACH ROW
  EXECUTE PROCEDURE pr_occtax.fct_tri_synthese_delete_occ();

DROP TRIGGER IF EXISTS tri_delete_t_occurrence_occtax ON pr_occtax.t_occurrences_occtax;
CREATE TRIGGER tri_delete_t_occurrence_occtax
  AFTER DELETE
  ON pr_occtax.t_occurrences_occtax
  FOR EACH ROW
  EXECUTE PROCEDURE pr_occtax.fct_tri_delete_occ();

DROP TRIGGER IF EXISTS tri_update_synthese_t_releve_occtax ON pr_occtax.t_releves_occtax;
CREATE TRIGGER tri_update_synthese_t_releve_occtax
  AFTER UPDATE
  ON pr_occtax.t_releves_occtax
  FOR EACH ROW
  EXECUTE PROCEDURE pr_occtax.fct_tri_synthese_update_releve();

DROP TRIGGER IF EXISTS tri_delete_synthese_t_releve_occtax ON pr_occtax.t_releves_occtax;
CREATE TRIGGER tri_delete_synthese_t_releve_occtax
  AFTER DELETE
  ON pr_occtax.t_releves_occtax
  FOR EACH ROW
  EXECUTE PROCEDURE pr_occtax.fct_tri_synthese_delete_releve();

DROP TRIGGER IF EXISTS tri_insert_synthese_cor_role_releves_occtax ON pr_occtax.cor_role_releves_occtax;
CREATE TRIGGER tri_insert_synthese_cor_role_releves_occtax
  AFTER INSERT
  ON pr_occtax.cor_role_releves_occtax
  FOR EACH ROW
  EXECUTE PROCEDURE pr_occtax.fct_tri_synthese_insert_cor_role_releve();

DROP TRIGGER IF EXISTS tri_update_synthese_cor_role_releves_occtax ON pr_occtax.cor_role_releves_occtax;
CREATE TRIGGER tri_update_synthese_cor_role_releves_occtax
  AFTER UPDATE
  ON pr_occtax.cor_role_releves_occtax
  FOR EACH ROW
  EXECUTE PROCEDURE pr_occtax.fct_tri_synthese_update_cor_role_releve();

DROP TRIGGER IF EXISTS tri_delete_synthese_cor_role_releves_occtax ON pr_occtax.cor_role_releves_occtax;
CREATE TRIGGER tri_delete_synthese_cor_role_releves_occtax
  AFTER DELETE
  ON pr_occtax.cor_role_releves_occtax
  FOR EACH ROW
  EXECUTE PROCEDURE pr_occtax.fct_tri_synthese_delete_cor_role_releve();


--------------------
-- ASSOCIATED DATA--
--------------------

INSERT INTO gn_synthese.t_sources ( name_source, desc_source, entity_source_pk_field, url_source)
 VALUES ('Occtax', 'Données issues du module Occtax', 'pr_occtax.cor_counting_occtax.id_counting_occtax', '#/occtax/info/id_counting');
 
INSERT INTO pr_occtax.defaults_nomenclatures_value (mnemonique_type, id_organism, regne, group2_inpn, id_nomenclature) VALUES
('NAT_OBJ_GEO',0, 0, 0,  ref_nomenclatures.get_id_nomenclature('NAT_OBJ_GEO', 'NSP'));
