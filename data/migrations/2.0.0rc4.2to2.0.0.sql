-- Migration du metadata comme un module à part

INSERT INTO gn_commons.t_modules(module_code, module_label, module_picto, module_desc, module_path, module_target, active_frontend, active_backend) VALUES
('METADATA', 'Metadonnées', 'fa-book', 'Module de gestion des métadonnées', 'metadata', '_self', TRUE, TRUE)
;

-- migration des permission dans le nouveau module
INSERT INTO gn_permissions.cor_role_action_filter_module_object(
  id_role,
  id_action,
  id_filter,
  id_module
)
WITH mod_admin AS (
    SELECT id_module
    FROM gn_commons.t_modules
    WHERE module_code ILIKE 'ADMIN'
),
obj AS (
    SELECT id_object
    FROM gn_permissions.t_objects
    WHERE code_object ILIKE 'METADATA'
),
mod_metadata AS (
    SELECT id_module
    FROM gn_commons.t_modules
    WHERE module_code ILIKE 'METADATA' 
)
SELECT id_role, id_action, id_filter, mod_metadata.id_module
FROM gn_permissions.cor_role_action_filter_module_object cor, mod_admin, obj, mod_metadata
WHERE cor.id_module = mod_admin.id_module AND cor.id_object = obj.id_object;

-- suppression des permissions de l'objet metadata inutiles
DELETE 
FROM gn_permissions.cor_role_action_filter_module_object
WHERE id_object = (
    SELECT id_object FROM gn_permissions.t_objects WHERE code_object = 'METADATA'
) AND id_module = (
    SELECT id_module FROM gn_commons.t_modules WHERE module_code = 'ADMIN'
);


-- suppression relation cor_object_module 
DELETE FROM gn_permissions.cor_object_module WHERE id_object = (
    SELECT id_object FROM gn_permissions.t_objects WHERE code_object = 'METADATA'
);

-- supression de l'objet metadata
DELETE FROM gn_permissions.t_objects where code_object = 'METADATA'

-- Droit limité pour le groupe en poste pour le module METADATA
INSERT INTO gn_permissions.cor_role_action_filter_module_object(id_role, id_action,id_filter,id_module)
SELECT 7, 1, 1, id_module
FROM gn_commons.t_modules
WHERE module_code = 'METADATA';

INSERT INTO gn_permissions.cor_role_action_filter_module_object(id_role, id_action,id_filter,id_module)
SELECT 7, 2, 3, id_module
FROM gn_commons.t_modules
WHERE module_code = 'METADATA';

INSERT INTO gn_permissions.cor_role_action_filter_module_object(id_role, id_action,id_filter,id_module)
SELECT 7, 3, 1, id_module
FROM gn_commons.t_modules
WHERE module_code = 'METADATA';

INSERT INTO gn_permissions.cor_role_action_filter_module_object(id_role, id_action,id_filter,id_module)
SELECT 7, 4, 1, id_module
FROM gn_commons.t_modules
WHERE module_code = 'METADATA';

INSERT INTO gn_permissions.cor_role_action_filter_module_object(id_role, id_action,id_filter,id_module)
SELECT 7, 5, 3, id_module
FROM gn_commons.t_modules
WHERE module_code = 'METADATA';

INSERT INTO gn_permissions.cor_role_action_filter_module_object(id_role, id_action,id_filter,id_module)
SELECT 7, 6, 1, id_module
FROM gn_commons.t_modules
WHERE module_code = 'METADATA';


-- Update taxons_synthese_autocomplete

SELECT concat(aut.search_name,  ' - [', t.id_rang, ' - ', t.cd_nom , ']' )
FROM gn_synthese.taxons_synthese_autocomplete aut
JOIN taxonomie.taxref t ON aut.cd_nom = t.cd_nom;

CREATE OR REPLACE FUNCTION gn_synthese.fct_trg_refresh_taxons_forautocomplete()
  RETURNS trigger AS
$BODY$
 DECLARE
  BEGIN

    IF TG_OP in ('DELETE', 'TRUNCATE', 'UPDATE') AND OLD.cd_nom NOT IN (SELECT DISTINCT cd_nom FROM gn_synthese.synthese) THEN
        DELETE FROM gn_synthese.taxons_synthese_autocomplete auto
        WHERE auto.cd_nom = OLD.cd_nom;
    END IF;

    IF TG_OP in ('INSERT', 'UPDATE') AND NEW.cd_nom NOT IN (SELECT DISTINCT cd_nom FROM gn_synthese.taxons_synthese_autocomplete) THEN
      INSERT INTO gn_synthese.taxons_synthese_autocomplete
      SELECT t.cd_nom,
              t.cd_ref,
          concat(t.lb_nom, ' = <i>', t.nom_valide, '</i>', ' - [', t.id_rang, ' - ', t.cd_nom , ']') AS search_name,
          t.nom_valide,
          t.lb_nom,
          t.regne,
          t.group2_inpn
      FROM taxonomie.taxref t  WHERE cd_nom = NEW.cd_nom;
      INSERT INTO gn_synthese.taxons_synthese_autocomplete
      SELECT t.cd_nom,
        t.cd_ref,
        concat(t.nom_vern, ' =  <i> ', t.nom_valide, '</i>', ' - [', t.id_rang, ' - ', t.cd_nom , ']' ) AS search_name,
        t.nom_valide,
        t.lb_nom,
        t.regne,
        t.group2_inpn
      FROM taxonomie.taxref t  WHERE t.nom_vern IS NOT NULL AND cd_nom = NEW.cd_nom;
    END IF;
  RETURN NULL;
  END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;


CREATE OR REPLACE FUNCTION taxonomie.trg_fct_refresh_nomfrancais_mv_taxref_list_forautocomplete()
  RETURNS trigger AS
$BODY$
DECLARE
BEGIN
    UPDATE taxonomie.vm_taxref_list_forautocomplete v
    SET search_name = concat(NEW.nom_francais, ' =  <i> ', t.nom_valide, '</i>', ' - [', t.id_rang, ' - ', t.cd_nom , ']')
    FROM taxonomie.taxref t
		WHERE v.cd_nom = NEW.cd_nom AND t.cd_nom = NEW.cd_nom;
    RETURN NEW;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;



-- DELETE cascade sur ref_geo
ALTER TABLE ref_geo.li_municipalities DROP CONSTRAINT fk_li_municipalities_id_area;

ALTER TABLE ref_geo.li_municipalities
  ADD CONSTRAINT fk_li_municipalities_id_area FOREIGN KEY (id_area)
      REFERENCES ref_geo.l_areas (id_area) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ref_geo.li_grids DROP CONSTRAINT fk_li_grids_id_area;

ALTER TABLE ref_geo.li_grids
  ADD CONSTRAINT fk_li_grids_id_area FOREIGN KEY (id_area)
      REFERENCES ref_geo.l_areas (id_area) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE CASCADE;


-- Contrainte unique sur UUID en synthese et occtax

ALTER TABLE ONLY gn_synthese.synthese
    ADD CONSTRAINT unique_id_sinp_unique UNIQUE (unique_id_sinp);

ALTER TABLE ONLY pr_occtax.cor_counting_occtax
    ADD CONSTRAINT unique_id_sinp_occtax_unique UNIQUE (unique_id_sinp_occtax);


-- suppression de la récupération de la validation lors du trigger occtax -> synthese
-- redondant car déjà effectué par occtax via l'ecriture dans t_validation puis par le trigger validation -> synthese 
-- ecrivant le dernier statut de valiation

CREATE OR REPLACE FUNCTION pr_occtax.insert_in_synthese(my_id_counting integer)
  RETURNS integer[] AS
$BODY$
DECLARE
new_count RECORD;
occurrence RECORD;
releve RECORD;
id_source integer;
id_module integer;
id_nomenclature_source_status integer;
myobservers RECORD;
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

-- Récupération de l'id_module
SELECT INTO id_module gn_commons.get_id_module_bycode('OCCTAX');


-- Récupération du status_source depuis le JDD
SELECT INTO id_nomenclature_source_status d.id_nomenclature_source_status FROM gn_meta.t_datasets d WHERE id_dataset = releve.id_dataset;

--Récupération et formatage des observateurs
SELECT INTO myobservers array_to_string(array_agg(rol.nom_role || ' ' || rol.prenom_role), ', ') AS observers_name,
array_agg(rol.id_role) AS observers_id
FROM pr_occtax.cor_role_releves_occtax cor
JOIN utilisateurs.t_roles rol ON rol.id_role = cor.id_role
WHERE cor.id_releve_occtax = releve.id_releve_occtax;

-- insertion dans la synthese
INSERT INTO gn_synthese.synthese (
unique_id_sinp,
unique_id_sinp_grp,
id_source,
entity_source_pk_value,
id_dataset,
id_module,
id_nomenclature_geo_object_nature,
id_nomenclature_grp_typ,
id_nomenclature_obs_meth,
id_nomenclature_obs_technique,
id_nomenclature_bio_status,
id_nomenclature_bio_condition,
id_nomenclature_naturalness,
id_nomenclature_exist_proof,
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
  id_module,
  --nature de l'objet geo: id_nomenclature_geo_object_nature Le taxon observé est présent quelque part dans l'objet géographique - NSP par défault
  pr_occtax.get_default_nomenclature_value('NAT_OBJ_GEO'),
  releve.id_nomenclature_grp_typ,
  occurrence.id_nomenclature_obs_meth,
  releve.id_nomenclature_obs_technique,
  occurrence.id_nomenclature_bio_status,
  occurrence.id_nomenclature_bio_condition,
  occurrence.id_nomenclature_naturalness,
  occurrence.id_nomenclature_exist_proof,
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
  (to_char(releve.date_min, 'DD/MM/YYYY') || ' ' || COALESCE(to_char(releve.hour_min, 'HH24:MI:SS'),'00:00:00'))::timestamp,
  (to_char(releve.date_max, 'DD/MM/YYYY') || ' ' || COALESCE(to_char(releve.hour_max, 'HH24:MI:SS'),'00:00:00'))::timestamp,
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