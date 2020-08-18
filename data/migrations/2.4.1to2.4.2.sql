
CREATE OR REPLACE FUNCTION gn_sensitivity.get_id_nomenclature_sensitivity(my_date_obs date, my_cd_ref integer, my_geom geometry, my_criterias jsonb)
 RETURNS integer
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
DECLARE
    niv_precis integer;
    niv_precis_null integer;
BEGIN

    niv_precis_null := (SELECT ref_nomenclatures.get_id_nomenclature('SENSIBILITE'::text, '0'::text));

    -- ##########################################
    -- TESTS unicritère
    --    => Permet de voir si un critère est remplis ou non de façon à limiter au maximum
    --      la requete globale qui croise l'ensemble des critères
    -- ##########################################

    -- Paramètres cd_ref
     IF NOT EXISTS (
        SELECT 1
        FROM gn_sensitivity.t_sensitivity_rules_cd_ref s
        WHERE s.cd_ref = my_cd_ref
    ) THEN
        return niv_precis_null;
    END IF;

    -- Paramètres durée de validité de la règle
    IF NOT EXISTS (
        SELECT 1
        FROM gn_sensitivity.t_sensitivity_rules_cd_ref s
        WHERE s.cd_ref = my_cd_ref
        AND (date_part('year', CURRENT_TIMESTAMP) - sensitivity_duration) <= date_part('year', my_date_obs)
    ) THEN
        return niv_precis_null;
    END IF;

    -- Paramètres période d'observation
    IF NOT EXISTS (
        SELECT 1
        FROM gn_sensitivity.t_sensitivity_rules_cd_ref s
        WHERE s.cd_ref = my_cd_ref
        AND (to_char(my_date_obs, 'MMDD') between to_char(s.date_min, 'MMDD') and to_char(s.date_max, 'MMDD') )
    ) THEN
        return niv_precis_null;
    END IF;

    -- Paramètres critères biologiques
    -- S'il existe un critère pour ce taxon
    IF EXISTS (
        SELECT 1
        FROM gn_sensitivity.t_sensitivity_rules_cd_ref s
        JOIN gn_sensitivity.cor_sensitivity_criteria c USING(id_sensitivity)
        WHERE s.cd_ref = my_cd_ref
    ) THEN
        -- Si le critère est remplis
        niv_precis := (

			WITH RECURSIVE h_val(KEY, value, id_broader) AS  (
				SELECT KEY, value::int, id_broader
				FROM (SELECT * FROM jsonb_each_text(my_criterias)) d
				JOIN ref_nomenclatures.t_nomenclatures tn
				ON tn.id_nomenclature = d.value::int
				UNION
				SELECT KEY, id_nomenclature , tn.id_broader
				FROM ref_nomenclatures.t_nomenclatures tn
				JOIN h_val
				ON tn.id_nomenclature = h_val.id_broader
				WHERE NOT id_nomenclature = 0
			)
			SELECT DISTINCT id_nomenclature_sensitivity
			FROM gn_sensitivity.t_sensitivity_rules_cd_ref s
			JOIN gn_sensitivity.cor_sensitivity_criteria c USING(id_sensitivity)
			JOIN h_val a
			ON c.id_criteria = a.value
			WHERE s.cd_ref = my_cd_ref
			LIMIT 1
        );
        IF niv_precis IS NULL THEN
            niv_precis := (SELECT ref_nomenclatures.get_id_nomenclature('SENSIBILITE'::text, '0'::text));
            return niv_precis;
        END IF;
    END IF;



    -- ##########################################
    -- TESTS multicritères
    --    => Permet de voir si l'ensemble des critères sont remplis
    -- ##########################################

    -- Paramètres durée, zone géographique, période de l'observation et critères biologique
	SELECT INTO niv_precis s.id_nomenclature_sensitivity
	FROM (
		SELECT s.*, l.geom, c.id_criteria, c.id_type_nomenclature
		FROM gn_sensitivity.t_sensitivity_rules_cd_ref s
		LEFT OUTER JOIN gn_sensitivity.cor_sensitivity_area  USING(id_sensitivity)
        LEFT OUTER JOIN gn_sensitivity.cor_sensitivity_criteria c USING(id_sensitivity)
		LEFT OUTER JOIN ref_geo.l_areas l USING(id_area)
	) s
	WHERE my_cd_ref = s.cd_ref
		AND (st_intersects(my_geom, s.geom) OR s.geom IS NULL) -- paramètre géographique
		AND (-- paramètre période
			(to_char(my_date_obs, 'MMDD') between to_char(s.date_min, 'MMDD') and to_char(s.date_max, 'MMDD') )
		)
		AND ( -- paramètre duré de validité de la règle
			(date_part('year', CURRENT_TIMESTAMP) - sensitivity_duration) <= date_part('year', my_date_obs)
		)
		AND ( -- paramètre critères
            s.id_criteria IN (SELECT  value::int FROM jsonb_each_text(my_criterias)) OR s.id_criteria IS NULL
		);

	IF niv_precis IS NULL THEN
		niv_precis := niv_precis_null;
	END IF;


	return niv_precis;

END;
$function$
;



-- vue validation de gn_commons necessitant le schéma synthese
CREATE OR REPLACE VIEW gn_commons.v_synthese_validation_forwebapp AS
SELECT  s.id_synthese,
    s.unique_id_sinp,
    s.unique_id_sinp_grp,
    s.id_source,
    s.entity_source_pk_value,
    s.count_min,
    s.count_max,
    s.nom_cite,
    s.meta_v_taxref,
    s.sample_number_proof,
    s.digital_proof,
    s.non_digital_proof,
    s.altitude_min,
    s.altitude_max,
    s.the_geom_4326,
    s.date_min,
    s.date_max,
    s.validator,
    s.observers,
    s.id_digitiser,
    s.determiner,
    s.comment_context,
    s.comment_description,
    s.meta_validation_date,
    s.meta_create_date,
    s.meta_update_date,
    s.last_action,
    d.id_dataset,
    d.dataset_name,
    d.id_acquisition_framework,
    s.id_nomenclature_geo_object_nature,
    s.id_nomenclature_info_geo_type,
    s.id_nomenclature_grp_typ,
    s.id_nomenclature_obs_meth,
    s.id_nomenclature_obs_technique,
    s.id_nomenclature_bio_status,
    s.id_nomenclature_bio_condition,
    s.id_nomenclature_naturalness,
    s.id_nomenclature_exist_proof,
    s.id_nomenclature_diffusion_level,
    s.id_nomenclature_life_stage,
    s.id_nomenclature_sex,
    s.id_nomenclature_obj_count,
    s.id_nomenclature_type_count,
    s.id_nomenclature_sensitivity,
    s.id_nomenclature_observation_status,
    s.id_nomenclature_blurring,
    s.id_nomenclature_source_status,
    s.id_nomenclature_valid_status,
    s.reference_biblio,
    t.cd_nom,
    t.cd_ref,
    t.nom_valide,
    t.lb_nom,
    t.nom_vern,
    n.mnemonique,
    n.cd_nomenclature AS cd_nomenclature_validation_status,
    n.label_default,
    v.validation_auto,
    v.validation_date,
    ST_asgeojson(s.the_geom_4326) as geojson
   FROM gn_synthese.synthese s
    JOIN taxonomie.taxref t ON t.cd_nom = s.cd_nom
    JOIN gn_meta.t_datasets d ON d.id_dataset = s.id_dataset
    LEFT JOIN ref_nomenclatures.t_nomenclatures n ON n.id_nomenclature = s.id_nomenclature_valid_status
    LEFT JOIN LATERAL (
        SELECT v.validation_auto, v.validation_date
        FROM gn_commons.t_validations v
        WHERE v.uuid_attached_row = s.unique_id_sinp
        ORDER BY v.validation_date DESC
        LIMIT 1
    ) v ON true
  WHERE d.validable = true AND NOT s.unique_id_sinp IS NULL;

COMMENT ON VIEW gn_commons.v_synthese_validation_forwebapp  IS 'Vue utilisée pour le module validation. Prend l''id_nomenclature dans la table synthese ainsi que toutes les colonnes de la synthese pour les filtres. On JOIN sur la vue latest_validation pour voir si la validation est auto';

-- correction de fonctions permissions (nom de la vue a changé)

CREATE OR REPLACE FUNCTION does_user_have_scope_permission
(
 myuser integer,
 mycodemodule character varying,
 myactioncode character varying,
 myscope integer
)
 RETURNS boolean AS
$BODY$
-- the function say if the given user can do the requested action in the requested module with its scope level
-- warning: NO heritage between parent and child module
-- USAGE : SELECT gn_persmissions.does_user_have_scope_permission(requested_userid,requested_actionid,requested_module_code,requested_scope);
-- SAMPLE : SELECT gn_permissions.does_user_have_scope_permission(2,'OCCTAX','R',3);
BEGIN
    IF myactioncode IN (
  SELECT code_action
    FROM gn_permissions.v_roles_permissions
    WHERE id_role = myuser AND module_code = mycodemodule AND code_action = myactioncode AND value_filter::int >= myscope AND code_filter_type = 'SCOPE') THEN
    RETURN true;
END
IF;
 RETURN false;
END;
$BODY$
 LANGUAGE plpgsql IMMUTABLE
 COST 100;


CREATE OR REPLACE FUNCTION user_max_accessible_data_level_in_module
(
 myuser integer,
 myactioncode character varying,
 mymodulecode character varying)
 RETURNS integer AS
$BODY$
DECLARE
 themaxscopelevel integer;
-- the function return the max accessible extend of data the given user can access in the requested module
-- warning: NO heritage between parent and child module
-- USAGE : SELECT gn_permissions.user_max_accessible_data_level_in_module(requested_userid,requested_actionid,requested_moduleid);
-- SAMPLE :SELECT gn_permissions.user_max_accessible_data_level_in_module(2,'U','GEONATURE');
BEGIN
    SELECT max(value_filter::int)
    INTO themaxscopelevel
    FROM gn_permissions.v_roles_permissions
    WHERE id_role = myuser AND module_code = mymodulecode AND code_action = myactioncode;
    RETURN themaxscopelevel;
END;
$BODY$
 LANGUAGE plpgsql IMMUTABLE
 COST 100;

CREATE OR REPLACE FUNCTION cruved_for_user_in_module
(
 myuser integer,
 mymodulecode character varying
)
 RETURNS json AS
$BODY$
-- the function return user's CRUVED in the requested module
-- warning: the function not return the parent CRUVED but only the module cruved - no heritage
-- USAGE : SELECT utilisateurs.cruved_for_user_in_module(requested_userid,requested_moduleid);
-- SAMPLE : SELECT utilisateurs.cruved_for_user_in_module(2,3);
DECLARE
 thecruved json;
BEGIN
    SELECT array_to_json(array_agg(row))
    INTO thecruved
    FROM (
  SELECT code_action AS action, max(value_filter::int) AS level
        FROM gn_permissions.v_roles_permissions
        WHERE id_role = myuser AND module_code = mymodulecode AND code_filter_type = 'SCOPE'
        GROUP BY code_action) row;
    RETURN thecruved;
END;
$BODY$
 LANGUAGE plpgsql IMMUTABLE
 COST 100;



 -- OCCTAX V2

ALTER TABLE pr_occtax.t_releves_occtax
ADD COLUMN id_nomenclature_geo_object_nature integer NOT NULL,
ADD CONSTRAINT check_t_releves_occtax_geo_object_nature CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_geo_object_nature,'NAT_OBJ_GEO')) NOT VALID;
ADD CONSTRAINT fk_t_releves_occtax_id_nomenclature_geo_object_nature FOREIGN KEY (id_nomenclature_geo_object_nature) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE,
ADD COLUMN cd_hab integer,
ADD CONSTRAINT fk_t_releves_occtax_cd_hab FOREIGN KEY (cd_hab) REFERENCES ref_habitats.habref(cd_hab) ON UPDATE CASCADE,
ADD COLUMN grp_method varchar(255)
;

ALTER TABLE pr_occtax.t_occurrences_occtax
    --delete sensi
    DROP COLUMN id_nomenclature_diffusion_level;
    -- comportement
    ADD COLUMN id_nomenclature_behavior integer,
    ADD CONSTRAINT fk_t_occurrences_occtax_behavior FOREIGN KEY (id_nomenclature_behavior) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;
    ADD CONSTRAINT check_t_occurrences_occtax_behavior CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_determination_method,'OCC_COMPORTEMENT')) NOT VALID;

INSERT INTO pr_occtax.defaults_nomenclatures_value(mnemonique_type, id_nomenclature)
VALUES ('OCC_COMPORTEMENT', '0');

INSERT INTO gn_synthese.defaults_nomenclatures_value(mnemonique_type, id_nomenclature)
VALUES ('OCC_COMPORTEMENT', '0');


ALTER TABLE gn_synthese.syntese 
    ADD COLUM cd_hab integer,
    ADD CONSTRAINT fk_synthese_cd_hab FOREIGN KEY (cd_hab) REFERENCES ref_habitats.habref(cd_hab) ON UPDATE CASCADE,
    ADD COLUMN grp_method vachar(255),
    ADD COLUMN id_nomenclature_behavior integer DEFAULT VALUE get_default_nomenclature_value('OCC_COMPORTEMENT'),
    ADD CONSTRAINT fk_synthese_id_nomenclature_behavior FOREIGN KEY (id_nomenclature_behavior) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;
    ADD CONSTRAINT check_synthese_behavior CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_determination_method,'OCC_COMPORTEMENT')) NOT VALID;




CREATE OR REPLACE FUNCTION insert_in_synthese(my_id_counting integer)
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
cd_hab,
id_nomenclature_grp_typ,
id_nomenclature_obs_meth,
id_nomenclature_obs_technique,
id_nomenclature_bio_status,
id_nomenclature_bio_condition,
id_nomenclature_naturalness,
id_nomenclature_exist_proof,
id_nomenclature_life_stage,
id_nomenclature_sex,
id_nomenclature_obj_count,
id_nomenclature_type_count,
id_nomenclature_observation_status,
id_nomenclature_blurring,
id_nomenclature_source_status,
id_nomenclature_info_geo_type,
id_nomenclature_behavior,
count_min,
count_max,
cd_nom,
cd_hab,
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
comment_context,
comment_description,
last_action
)
VALUES(
  new_count.unique_id_sinp_occtax,
  releve.unique_id_sinp_grp,
  id_source,
  new_count.id_counting_occtax,
  releve.id_dataset,
  id_module,
  releve.id_nomenclature_geo_object_nature,
  releve.cd_hab,
  releve.id_nomenclature_geo_object_nature,
  releve.id_nomenclature_grp_typ,
  occurrence.id_nomenclature_obs_meth,
  releve.id_nomenclature_obs_technique,
  occurrence.id_nomenclature_bio_status,
  occurrence.id_nomenclature_bio_condition,
  occurrence.id_nomenclature_naturalness,
  occurrence.id_nomenclature_exist_proof,
  new_count.id_nomenclature_life_stage,
  new_count.id_nomenclature_sex,
  new_count.id_nomenclature_obj_count,
  new_count.id_nomenclature_type_count,
  occurrence.id_nomenclature_observation_status,
  occurrence.id_nomenclature_blurring,
  -- status_source récupéré depuis le JDD
  id_nomenclature_source_status,
  -- id_nomenclature_info_geo_type: type de rattachement = géoréferencement
  ref_nomenclatures.get_id_nomenclature('TYP_INF_GEO', '1'),
  occurrence.id_nomenclature_behavior
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
  date_trunc('day',releve.date_min)+COALESCE(releve.hour_min,'00:00:00'::time),
  date_trunc('day',releve.date_max)+COALESCE(releve.hour_max,'00:00:00'::time),
  COALESCE (myobservers.observers_name, releve.observers_txt),
  occurrence.determiner,
  releve.id_digitiser,
  occurrence.id_nomenclature_determination_method,
  releve.comment,
  occurrence.comment,
  'I'
);

  RETURN myobservers.observers_id ;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;


CREATE OR REPLACE FUNCTION fct_tri_synthese_update_occ()
  RETURNS trigger AS
$BODY$
DECLARE
BEGIN
  UPDATE gn_synthese.synthese SET
    id_nomenclature_obs_meth = NEW.id_nomenclature_obs_meth,
    id_nomenclature_bio_condition = NEW.id_nomenclature_bio_condition,
    id_nomenclature_bio_status = NEW.id_nomenclature_bio_status,
    id_nomenclature_naturalness = NEW.id_nomenclature_naturalness,
    id_nomenclature_exist_proof = NEW.id_nomenclature_exist_proof,
    id_nomenclature_observation_status = NEW.id_nomenclature_observation_status,
    id_nomenclature_blurring = NEW.id_nomenclature_blurring,
    id_nomenclature_source_status = NEW.id_nomenclature_source_status,
    determiner = NEW.determiner,
    id_nomenclature_determination_method = NEW.id_nomenclature_determination_method,
    id_nomenclature_behavior = id_nomenclature_behavior,
    cd_nom = NEW.cd_nom,
    nom_cite = NEW.nom_cite,
    meta_v_taxref = NEW.meta_v_taxref,
    sample_number_proof = NEW.sample_number_proof,
    digital_proof = NEW.digital_proof,
    non_digital_proof = NEW.non_digital_proof,
    comment_description = NEW.comment,
    last_action = 'U'
  WHERE unique_id_sinp IN (SELECT unique_id_sinp_occtax FROM pr_occtax.cor_counting_occtax WHERE id_occurrence_occtax = NEW.id_occurrence_occtax);
  RETURN NULL;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;



  RETURN myobservers.observers_id ;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;



CREATE OR REPLACE FUNCTION fct_tri_synthese_update_releve()
  RETURNS trigger AS
$BODY$
DECLARE
  myobservers text;
BEGIN
  --calcul de l'observateur. On privilégie le ou les observateur(s) de cor_role_releves_occtax
  --Récupération et formatage des observateurs
  SELECT INTO myobservers array_to_string(array_agg(rol.nom_role || ' ' || rol.prenom_role), ', ')
  FROM pr_occtax.cor_role_releves_occtax cor
  JOIN utilisateurs.t_roles rol ON rol.id_role = cor.id_role
  WHERE cor.id_releve_occtax = NEW.id_releve_occtax;
  IF myobservers IS NULL THEN
    myobservers = NEW.observers_txt;
  END IF;
  --mise à jour en synthese des informations correspondant au relevé uniquement
  UPDATE gn_synthese.synthese SET
      id_dataset = NEW.id_dataset,
      observers = myobservers,
      id_digitiser = NEW.id_digitiser,
      id_nomenclature_obs_technique = NEW.id_nomenclature_obs_technique,
      grp_method = NEW.grp_method,
      id_nomenclature_grp_typ = NEW.id_nomenclature_grp_typ,
      date_min = date_trunc('day',NEW.date_min)+COALESCE(NEW.hour_min,'00:00:00'::time),
      date_max = date_trunc('day',NEW.date_max)+COALESCE(NEW.hour_max,'00:00:00'::time), 
      altitude_min = NEW.altitude_min,
      altitude_max = NEW.altitude_max,
      the_geom_4326 = NEW.geom_4326,
      the_geom_point = ST_CENTROID(NEW.geom_4326),
      id_nomenclature_geo_object_nature = NEW.id_nomenclature_geo_object_nature,
      last_action = 'U',
      comment_context = NEW.comment
  WHERE unique_id_sinp IN (SELECT unnest(pr_occtax.get_unique_id_sinp_from_id_releve(NEW.id_releve_occtax::integer)));
  RETURN NULL;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

