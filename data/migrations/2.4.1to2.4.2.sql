
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
                                   

                                   
-- Mise à jour des nomenclatures "CA_OBJECTIFS" et mise à jour des données en conséquence (standard métadonnées 1.3.10)
-- Faire correspondre les nouveaux objectifs aux Cadres d'acquisition sur la base des anciennes nomenclatures - Annexe 1 du standard 1.3.10 mtd
DO $$
DECLARE 
	id_ca INTEGER;
	my_obj_cd int[];
BEGIN
	FOR id_ca IN (SELECT DISTINCT id_acquisition_framework FROM gn_meta.cor_acquisition_framework_objectif)
	LOOP
		my_obj_cd := (
			SELECT array_agg(n.cd_nomenclature)::int[]
			FROM gn_meta.cor_acquisition_framework_objectif cao
			JOIN ref_nomenclatures.t_nomenclatures n ON cao.id_nomenclature_objectif = n.id_nomenclature 
			WHERE id_acquisition_framework = id_ca);

		IF my_obj_cd && ARRAY[1, 2, 3, 6] THEN
			INSERT INTO gn_meta.cor_acquisition_framework_objectif (id_acquisition_framework,id_nomenclature_objectif) 
			VALUES(id_ca, (SELECT n.id_nomenclature FROM ref_nomenclatures.t_nomenclatures n JOIN ref_nomenclatures.bib_nomenclatures_types t on t.id_type=n.id_type WHERE t.mnemonique='CA_OBJECTIFS' AND n.cd_nomenclature='8'));		
		END IF;
		
		IF my_obj_cd && ARRAY[5] THEN
			INSERT INTO gn_meta.cor_acquisition_framework_objectif (id_acquisition_framework,id_nomenclature_objectif) 
			VALUES(id_ca, (SELECT n.id_nomenclature FROM ref_nomenclatures.t_nomenclatures n JOIN ref_nomenclatures.bib_nomenclatures_types t on t.id_type=n.id_type WHERE t.mnemonique='CA_OBJECTIFS' AND n.cd_nomenclature='9'));
		END IF;
	
		IF my_obj_cd && ARRAY[4,7] THEN
			INSERT INTO gn_meta.cor_acquisition_framework_objectif (id_acquisition_framework,id_nomenclature_objectif) 
			VALUES(id_ca, (SELECT n.id_nomenclature FROM ref_nomenclatures.t_nomenclatures n JOIN ref_nomenclatures.bib_nomenclatures_types t on t.id_type=n.id_type WHERE t.mnemonique='CA_OBJECTIFS' AND n.cd_nomenclature='11'));
		END IF;
	END LOOP;
END $$;

-- Supprimer les correspondances des Cadres d'Acquisition avec les anciennes nomenclatures des objectifs
DELETE FROM gn_meta.cor_acquisition_framework_objectif
WHERE id_nomenclature_objectif IN (SELECT n.id_nomenclature FROM ref_nomenclatures.t_nomenclatures n JOIN ref_nomenclatures.bib_nomenclatures_types t on t.id_type=n.id_type WHERE t.mnemonique='CA_OBJECTIFS' AND n.cd_nomenclature IN ('1','2','3','4','5','6','7'));
