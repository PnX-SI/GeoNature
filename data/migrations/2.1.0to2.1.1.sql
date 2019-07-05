CREATE OR REPLACE FUNCTION gn_sensitivity.fct_tri_maj_id_sensitivity_synthese()
  RETURNS trigger AS
$BODY$
BEGIN
    UPDATE gn_synthese.synthese SET id_nomenclature_sensitivity = NEW.id_nomenclature_sensitivity
    WHERE unique_id_sinp = NEW.uuid_attached_row;
    RETURN NEW;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

CREATE OR REPLACE FUNCTION gn_sensitivity.fct_tri_delete_id_sensitivity_synthese()
  RETURNS trigger AS
$BODY$
BEGIN
    UPDATE gn_synthese.synthese SET id_nomenclature_sensitivity = gn_synthese.get_default_nomenclature_value('SENSIBILITE'::character varying)
    WHERE unique_id_sinp = OLD.uuid_attached_row;
    RETURN OLD;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;


-- ADD validable column in t_datasets

ALTER TABLE gn_meta.t_datasets
ADD COLUMN validable boolean DEFAULT true;

UPDATE gn_meta.t_datasets SET validable = true;

ALTER TABLE gn_meta.t_datasets
DROP COLUMN default_validity;

-- DROP FROM t_sources
ALTER TABLE gn_synthese.t_sources
DROP COLUMN validable;


DROP VIEW IF EXISTS gn_commons.v_latest_validations_for_web_app;
DROP VIEW IF EXISTS gn_commons.v_validations_for_web_app;

-- ajout vue latest validation
CREATE OR REPLACE VIEW gn_commons.v_latest_validation AS 
 SELECT v.id_validation,
    v.uuid_attached_row,
    v.id_nomenclature_valid_status,
    v.validation_auto,
    v.id_validator,
    v.validation_comment,
    v.validation_date
   FROM gn_commons.t_validations v
     JOIN ( SELECT t_validations.uuid_attached_row,
            max(t_validations.validation_date) AS max_date
           FROM gn_commons.t_validations
          GROUP BY t_validations.uuid_attached_row) last_val ON v.uuid_attached_row = last_val.uuid_attached_row AND v.validation_date = last_val.max_date;


CREATE OR REPLACE VIEW gn_commons.v_synthese_validation_forwebapp AS 
 SELECT s.id_synthese,
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
    t.cd_nom,
    t.cd_ref,
    t.nom_valide,
    t.lb_nom,
    t.nom_vern,
    n.mnemonique,
    n.cd_nomenclature AS cd_nomenclature_validation_status,
    n.label_default,
    latest_v.validation_auto,
    latest_v.validation_date
   FROM gn_synthese.synthese s
     JOIN taxonomie.taxref t ON t.cd_nom = s.cd_nom
     JOIN gn_meta.t_datasets d ON d.id_dataset = s.id_dataset
     LEFT JOIN gn_commons.t_validations v ON v.uuid_attached_row = s.unique_id_sinp
     LEFT JOIN ref_nomenclatures.t_nomenclatures n ON n.id_nomenclature = s.id_nomenclature_valid_status
     LEFT JOIN gn_commons.v_latest_validation latest_v ON latest_v.uuid_attached_row = s.unique_id_sinp
     WHERE d.validable = true;
  ;

COMMENT ON VIEW gn_commons.v_synthese_validation_forwebapp  IS 'Vue utilisée pour le module validation. Prend l''id_nomenclature dans la table synthese ainsi que toutes les colonnes de la synthese pour les filtres. On JOIN sur la vue latest_validation pour voir si la validation est auto';


DROP VIEW gn_commons.v_validations_for_web_app CASCADE;
ALTER TABLE gn_commons.t_validations DROP COLUMN id_table_location;




-- update fonction trigger validation
CREATE OR REPLACE FUNCTION gn_commons.fct_trg_add_default_validation_status()
  RETURNS trigger AS
$BODY$
DECLARE
	theschema text := quote_ident(TG_TABLE_SCHEMA);
	thetable text := quote_ident(TG_TABLE_NAME);
	theuuidfieldname character varying(50);
	theuuid uuid;
  thecomment text := 'auto = default value';
BEGIN
  --Retouver le nom du champ stockant l'uuid de l'enregistrement en cours de validation
	SELECT INTO theuuidfieldname gn_commons.get_uuid_field_name(theschema,thetable);
  --Récupérer l'uuid de l'enregistrement en cours de validation
	EXECUTE format('SELECT $1.%I', theuuidfieldname) INTO theuuid USING NEW;
  --Insertion du statut de validation et des informations associées dans t_validations
  INSERT INTO gn_commons.t_validations (uuid_attached_row,id_nomenclature_valid_status,id_validator,validation_comment,validation_date)
  VALUES(
    theuuid,
    ref_nomenclatures.get_default_nomenclature_value('STATUT_VALID'), --comme la fonction est générique, cette valeur par défaut doit exister et est la même pour tous les modules
    null,
    thecomment,
    NOW()
  );
  RETURN NEW;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;



-- update trigger synthese -> cor_area_synthese

CREATE OR REPLACE FUNCTION gn_synthese.fct_trig_insert_in_cor_area_synthese()
  RETURNS trigger AS
$BODY$
  DECLARE
  id_area_loop integer;
  geom_change boolean;
  BEGIN
  geom_change = false;
  IF(TG_OP = 'UPDATE') THEN
	SELECT INTO geom_change NOT ST_EQUALS(OLD.the_geom_local, NEW.the_geom_local);
  END IF;

  IF (geom_change) THEN
	DELETE FROM gn_synthese.cor_area_synthese WHERE id_synthese = NEW.id_synthese;
  END IF;

  -- intersection avec toutes les areas et écriture dans cor_area_synthese
    IF (TG_OP = 'INSERT' OR (TG_OP = 'UPDATE' AND geom_change )) THEN
      INSERT INTO gn_synthese.cor_area_synthese SELECT
	      s.id_synthese AS id_synthese,
        a.id_area AS id_area,
        s.cd_nom AS cd_nom
        FROM ref_geo.l_areas a
        JOIN gn_synthese.synthese s ON ST_INTERSECTS(s.the_geom_local, a.geom)
        WHERE s.id_synthese = NEW.id_synthese AND a.enable IS true;
    END IF;
  RETURN NULL;
  END;
  $BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

-- suppression des aire de cor_area where enabled = false
DELETE FROM gn_synthese.cor_area_synthese WHERE id_area IN (
SELECT s.id_area
FROM gn_synthese.cor_area_synthese s
JOIN ref_geo.l_areas a ON a.id_area = s.id_area
WHERE a.enable IS false
);