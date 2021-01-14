-- Update script from GeoNature 2.5.5 to 2.6.0

----------------------------
-- SENSITIVITY schema update
----------------------------

-- Update trigger function
 CREATE OR REPLACE FUNCTION gn_sensitivity.fct_tri_maj_id_sensitivity_synthese()
  RETURNS trigger AS
$BODY$
BEGIN
    UPDATE gn_synthese.synthese 
    SET id_nomenclature_sensitivity = updated_rows.id_nomenclature_sensitivity
    FROM NEW AS updated_rows
    JOIN gn_synthese.synthese s ON s.unique_id_sinp = updated_rows.uuid_attached_row;
    RETURN NULL;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

-- Trigger function executed by a ON EACH STATEMENT trigger
CREATE OR REPLACE FUNCTION gn_sensitivity.fct_tri_delete_id_sensitivity_synthese()
  RETURNS trigger AS
$BODY$
BEGIN
    UPDATE gn_synthese.synthese 
    SET id_nomenclature_sensitivity = gn_synthese.get_default_nomenclature_value('SENSIBILITE'::character varying)
    FROM OLD AS deleted_rows
    JOIN gn_synthese.synthese s ON s.unique_id_sinp = deleted_rows.uuid_attached_row;
    RETURN NULL;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

CREATE OR REPLACE FUNCTION gn_sensitivity.calculate_cd_diffusion_level(
  cd_nomenclature_diffusion_level character varying, cd_nomenclature_sensitivity character varying
)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$
BEGIN
  IF cd_nomenclature_diffusion_level IS NULL 
    THEN RETURN
    CASE 
      WHEN cd_nomenclature_sensitivity = '0' THEN '5'
      WHEN cd_nomenclature_sensitivity = '1' THEN '3'
      WHEN cd_nomenclature_sensitivity = '2' THEN '2'
      WHEN cd_nomenclature_sensitivity = '3' THEN '3'
      WHEN cd_nomenclature_sensitivity = '4' THEN '4'
    END;
  ELSE 
    RETURN cd_nomenclature_diffusion_level;
  END IF;
END;
$function$;
 

 CREATE TRIGGER tri_insert_id_sensitivity_synthese
  AFTER INSERT ON gn_sensitivity.cor_sensitivity_synthese
  REFERENCING NEW TABLE AS NEW
  FOR EACH STATEMENT
  EXECUTE PROCEDURE gn_sensitivity.fct_tri_maj_id_sensitivity_synthese();

DROP TRIGGER tri_maj_id_sensitivity_synthese ON gn_sensitivity.cor_sensitivity_synthese;
CREATE TRIGGER tri_maj_id_sensitivity_synthese
  AFTER UPDATE ON gn_sensitivity.cor_sensitivity_synthese
  REFERENCING NEW TABLE AS NEW
  FOR EACH STATEMENT
  EXECUTE PROCEDURE gn_sensitivity.fct_tri_maj_id_sensitivity_synthese();

-- Synthese - Ajout contrainte sur nomenclature STAT_BIOGEO
ALTER TABLE gn_synthese.synthese
DROP CONSTRAINT IF EXISTS check_synthese_biogeo_status;
ALTER TABLE gn_synthese.synthese
  ADD CONSTRAINT check_synthese_biogeo_status CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_biogeo_status,'STAT_BIOGEO')) NOT VALID;
ALTER TABLE ONLY gn_synthese.synthese
DROP CONSTRAINT IF EXISTS fk_synthese_id_nomenclature_biogeo_status;

ALTER TABLE ONLY gn_synthese.synthese
    ADD CONSTRAINT fk_synthese_id_nomenclature_biogeo_status FOREIGN KEY (id_nomenclature_biogeo_status) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;


CREATE OR REPLACE FUNCTION gn_synthese.fct_tri_cal_sensi_diff_level_on_each_statement() RETURNS TRIGGER
  LANGUAGE plpgsql
  AS $$ 
  -- Calculate sensitivity and diffusion level on insert in synthese
    BEGIN
    WITH cte AS (
        SELECT 
        gn_sensitivity.get_id_nomenclature_sensitivity(
          updated_rows.date_min::date, 
          taxonomie.find_cdref(updated_rows.cd_nom), 
          updated_rows.the_geom_local,
          ('{"STATUT_BIO": ' || updated_rows.id_nomenclature_bio_status::text || '}')::jsonb
        ) AS id_nomenclature_sensitivity,
        id_synthese,
        t_diff.cd_nomenclature as cd_nomenclature_diffusion_level
      FROM NEW AS updated_rows
      LEFT JOIN ref_nomenclatures.t_nomenclatures t_diff ON t_diff.id_nomenclature = updated_rows.id_nomenclature_diffusion_level
    )
    UPDATE gn_synthese.synthese AS s
    SET 
      id_nomenclature_sensitivity = c.id_nomenclature_sensitivity,
      id_nomenclature_diffusion_level = ref_nomenclatures.get_id_nomenclature(
        'NIV_PRECIS',
        gn_sensitivity.calculate_cd_diffusion_level(
          c.cd_nomenclature_diffusion_level, 
          t_sensi.cd_nomenclature
        )
        
      )
    FROM cte AS c
    LEFT JOIN ref_nomenclatures.t_nomenclatures t_sensi ON t_sensi.id_nomenclature = c.id_nomenclature_sensitivity
    WHERE c.id_synthese = s.id_synthese
  ;
    RETURN NULL;
    END;
  $$;

 CREATE OR REPLACE FUNCTION gn_synthese.fct_tri_cal_sensi_diff_level_on_each_row() RETURNS TRIGGER
  LANGUAGE plpgsql
  AS $$ 
  -- Calculate sensitivity and diffusion level on update in synthese
  DECLARE calculated_id_sensi integer;
    BEGIN
        SELECT 
        gn_sensitivity.get_id_nomenclature_sensitivity(
          NEW.date_min::date, 
          taxonomie.find_cdref(NEW.cd_nom), 
          NEW.the_geom_local,
          ('{"STATUT_BIO": ' || NEW.id_nomenclature_bio_status::text || '}')::jsonb
        ) INTO calculated_id_sensi;
      UPDATE gn_synthese.synthese 
      SET 
      id_nomenclature_sensitivity = calculated_id_sensi,
      -- TODO: est-ce qu'on remet à jour le niveau de diffusion lors d'une MAJ de la sensi ?
      id_nomenclature_diffusion_level = (
        SELECT ref_nomenclatures.get_id_nomenclature(
            'NIV_PRECIS',
            gn_sensitivity.calculate_cd_diffusion_level(
              ref_nomenclatures.get_cd_nomenclature(OLD.id_nomenclature_diffusion_level),
              ref_nomenclatures.get_cd_nomenclature(calculated_id_sensi)
          )
      	)
      )
      WHERE id_synthese = OLD.id_synthese
      ;
      RETURN NULL;
    END;
  $$;
  
CREATE TRIGGER tri_insert_calculate_sensitivity
 AFTER INSERT ON gn_synthese.synthese
  REFERENCING NEW TABLE AS NEW
  FOR EACH STATEMENT
  EXECUTE PROCEDURE gn_synthese.fct_tri_cal_sensi_diff_level_on_each_statement();
  
CREATE TRIGGER tri_update_calculate_sensitivity
 AFTER UPDATE OF date_min, date_max, cd_nom, the_geom_local, id_nomenclature_bio_status ON gn_synthese.synthese
  FOR EACH ROW
  EXECUTE PROCEDURE gn_synthese.fct_tri_cal_sensi_diff_level_on_each_row();
 
-- Fin schema sensitivity 
 
-- Refactor cor_area triggers
CREATE OR REPLACE FUNCTION gn_synthese.fct_trig_insert_in_cor_area_synthese_on_each_statement()
  RETURNS trigger AS
$BODY$
  DECLARE
  BEGIN
  -- Intersection avec toutes les areas et écriture dans cor_area_synthese
      INSERT INTO gn_synthese.cor_area_synthese 
        SELECT
          updated_rows.id_synthese AS id_synthese,
          a.id_area AS id_area
        FROM NEW as updated_rows
        JOIN ref_geo.l_areas a
          ON public.ST_INTERSECTS(updated_rows.the_geom_local, a.geom)  
        WHERE a.enable IS TRUE AND (ST_GeometryType(updated_rows.the_geom_local) = 'ST_Point' OR NOT public.ST_TOUCHES(updated_rows.the_geom_local,a.geom));
  RETURN NULL;
  END;
  $BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

CREATE OR REPLACE FUNCTION gn_synthese.fct_trig_update_in_cor_area_synthese()
  RETURNS trigger AS
$BODY$
  DECLARE
  geom_change boolean;
  BEGIN
	DELETE FROM gn_synthese.cor_area_synthese WHERE id_synthese = NEW.id_synthese;

  -- Intersection avec toutes les areas et écriture dans cor_area_synthese
    INSERT INTO gn_synthese.cor_area_synthese SELECT
      s.id_synthese AS id_synthese,
      a.id_area AS id_area
      FROM ref_geo.l_areas a
      JOIN gn_synthese.synthese s
        ON public.ST_INTERSECTS(s.the_geom_local, a.geom)
      WHERE a.enable IS TRUE AND s.id_synthese = NEW.id_synthese AND (ST_GeometryType(updated_rows.the_geom_local) = 'ST_Point' OR NOT public.ST_TOUCHES(updated_rows.the_geom_local,a.geom));
  RETURN NULL;
  END;
  $BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

DROP TRIGGER tri_insert_cor_area_synthese ON gn_synthese.synthese;
CREATE TRIGGER tri_insert_cor_area_synthese
AFTER insert ON gn_synthese.synthese
REFERENCING NEW TABLE AS NEW
FOR EACH STATEMENT
EXECUTE PROCEDURE gn_synthese.fct_trig_insert_in_cor_area_synthese_on_each_statement();


CREATE TRIGGER tri_update_cor_area_synthese
AFTER UPDATE OF the_geom_local, the_geom_4326 ON gn_synthese.synthese
FOR EACH ROW
EXECUTE PROCEDURE gn_synthese.fct_trig_update_in_cor_area_synthese();


-- Update import in synthese function
CREATE OR REPLACE FUNCTION gn_synthese.import_row_from_table(
        select_col_name character varying,
        select_col_val character varying,
        tbl_name character varying,
        limit_ integer,
        offset_ integer)
    RETURNS boolean
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE
AS $BODY$
    DECLARE
      select_sql text;
      import_rec record;
    BEGIN

      --test que la table/vue existe bien
      --42P01         undefined_table
      IF EXISTS (
          SELECT 1 FROM information_schema.tables t  WHERE t.table_schema ||'.'|| t.table_name = LOWER(tbl_name)
      ) IS FALSE THEN
          RAISE 'Undefined table: %', tbl_name USING ERRCODE = '42P01';
      END IF ;

      --test que la colonne existe bien
      --42703         undefined_column
      IF EXISTS (
          SELECT * FROM information_schema.columns  t  WHERE  t.table_schema ||'.'|| t.table_name = LOWER(tbl_name) AND column_name = select_col_name
      ) IS FALSE THEN
          RAISE 'Undefined column: %', select_col_name USING ERRCODE = '42703';
      END IF ;

        -- TODO transtypage en text pour des questions de généricité. A réflechir
        select_sql := 'SELECT row_to_json(c)::jsonb d
            FROM ' || LOWER(tbl_name) || ' c
            WHERE ' ||  select_col_name|| '::text = ''' || select_col_val || '''
            LIMIT ' || limit_ || '
            OFFSET ' || offset_ ;

        FOR import_rec IN EXECUTE select_sql LOOP
            PERFORM gn_synthese.import_json_row(import_rec.d);
        END LOOP;

      RETURN TRUE;
      END;
    $BODY$;


-- Add a field to define if the AF is opened or not --
ALTER TABLE gn_meta.t_acquisition_frameworks ADD opened bool NULL DEFAULT true;
ALTER TABLE gn_meta.t_acquisition_frameworks ADD initial_closing_date timestamp NULL;

-- Add a json field in l_areas for additional data
ALTER TABLE ref_geo.l_areas ADD additional_data jsonb NULL;


-- Update VIEW export OCCHAB
DROP VIEW IF EXISTS pr_occhab.v_export_sinp;
CREATE VIEW pr_occhab.v_export_sinp AS
SELECT 
s.id_station,
s.id_dataset,
s.id_digitiser,
s.unique_id_sinp_station as "identifiantStaSINP",
ds.unique_dataset_id as "metadonneeId",
nom1.cd_nomenclature as "dSPublique",
to_char(s.date_min, 'DD/MM/YYYY'::text)as "dateDebut",
to_char(s.date_max, 'DD/MM/YYYY'::text)as "dateFin",
s.observers_txt as "observateur",
nom2.cd_nomenclature as "methodeCalculSurface",
public.st_astext(s.geom_4326) as "geometry", -- Pourquoi rajouter st_astext?
public.st_asgeojson(s.geom_4326) as geojson,
s.geom_local,
nom3.cd_nomenclature as "natureObjetGeo",
h.unique_id_sinp_hab as "identifiantHabSINP",
h.nom_cite as "nomCite",
h.cd_hab as "cdHab",
h.technical_precision as "precisionTechnique"
FROM pr_occhab.t_stations as s
JOIN pr_occhab.t_habitats h on h.id_station = s.id_station
JOIN gn_meta.t_datasets ds on ds.id_dataset = s.id_dataset
LEFT join ref_nomenclatures.t_nomenclatures nom1 on nom1.id_nomenclature = ds.id_nomenclature_data_origin
LEFT join ref_nomenclatures.t_nomenclatures nom2 on nom2.id_nomenclature = s.id_nomenclature_area_surface_calculation
LEFT join ref_nomenclatures.t_nomenclatures nom3 on nom3.id_nomenclature = s.id_nomenclature_geographic_object
LEFT join ref_nomenclatures.t_nomenclatures nom4 on nom4.id_nomenclature = h.id_nomenclature_collection_technique;


-- Révision de la vue validation de gn_commons pour disposer du nom français et latin
DROP VIEW gn_commons.v_synthese_validation_forwebapp; 
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
    s.depth_min,
    s.depth_max,
    s.place_name,
    s.precision,
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
    s.id_nomenclature_behaviour,
    s.reference_biblio,
    t.cd_nom,
    t.cd_ref,
    COALESCE(nom_vern, lb_nom) as nom_vern_or_lb_nom,
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


CREATE OR REPLACE VIEW gn_synthese.v_metadata_for_export AS
 WITH count_nb_obs AS (
         SELECT count(*) AS nb_obs,
            synthese.id_dataset
           FROM gn_synthese.synthese
          GROUP BY synthese.id_dataset
        )
 SELECT d.dataset_name AS jeu_donnees,
    d.id_dataset AS jdd_id,
    d.unique_dataset_id AS jdd_uuid,
    af.acquisition_framework_name AS cadre_acquisition,
    af.unique_acquisition_framework_id AS ca_uuid,
    string_agg(DISTINCT concat(COALESCE(orga.nom_organisme, ((roles.nom_role::text || ' '::text) || roles.prenom_role::text)::character varying), ' (', nomencl.label_default,')'), ', '::text) AS acteurs,
    count_nb_obs.nb_obs AS nombre_obs
   FROM gn_meta.t_datasets d
     JOIN gn_meta.t_acquisition_frameworks af ON af.id_acquisition_framework = d.id_acquisition_framework
     LEFT JOIN gn_meta.cor_dataset_actor act ON act.id_dataset = d.id_dataset
     LEFT JOIN ref_nomenclatures.t_nomenclatures nomencl ON nomencl.id_nomenclature = act.id_nomenclature_actor_role
     LEFT JOIN utilisateurs.bib_organismes orga ON orga.id_organisme = act.id_organism
     LEFT JOIN utilisateurs.t_roles roles ON roles.id_role = act.id_role
     JOIN count_nb_obs ON count_nb_obs.id_dataset = d.id_dataset
  GROUP BY d.id_dataset, d.unique_dataset_id, d.dataset_name, af.acquisition_framework_name, af.unique_acquisition_framework_id, count_nb_obs.nb_obs;

INSERT INTO gn_commons.t_parameters
(id_organism, parameter_name, parameter_desc, parameter_value, parameter_extra_value)
VALUES(0, 'ref_sensi_version', 'Version du referenciel de sensibilité', 'Referentiel de sensibilite taxref v13 2020', '');


---- AFTER 2.6.0.rc.1

ALTER TABLE gn_synthese.synthese
  DROP CONSTRAINT check_synthese_info_geo_type_id_area_attachment;

DROP FUNCTION gn_synthese.calcul_cor_area_taxon;

DROP TRIGGER tri_maj_cor_area_taxon ON gn_synthese.cor_area_synthese;
DROP FUNCTION gn_synthese.fct_tri_maj_cor_unite_taxon;

DROP TRIGGER tri_del_area_synt_maj_corarea_tax ON gn_synthese.synthese;
DROP FUNCTION gn_synthese.fct_tri_manage_area_synth_and_taxon;
DROP FUNCTION gn_synthese.delete_and_insert_area_taxon;

DROP TRIGGER tri_update_cor_area_taxon_update_cd_nom on gn_synthese.synthese;
DROP FUNCTION gn_synthese.fct_tri_update_cd_nom;

DROP VIEW gn_synthese.v_color_taxon_area;

DROP TABLE gn_synthese.cor_area_taxon;

INSERT INTO gn_commons.t_parameters (id_organism, parameter_name, parameter_desc, parameter_value)
VALUES (0, 'occtaxmobile_area_type', 'Type de maille pour laquelle la couleur des taxons est calculée', 'M5');

CREATE VIEW gn_synthese.v_area_taxon AS
SELECT s.cd_nom, c.id_area, count(DISTINCT s.id_synthese) as nb_obs, max(s.date_min) as last_date
FROM gn_synthese.synthese s
JOIN gn_synthese.cor_area_synthese c ON s.id_synthese = c.id_synthese
JOIN ref_geo.l_areas la ON la.id_area = c.id_area
JOIN ref_geo.bib_areas_types bat ON bat.id_type = la.id_type
JOIN gn_commons.t_parameters tp ON tp.parameter_name = 'occtaxmobile_area_type' AND tp.parameter_value = bat.type_code
GROUP BY c.id_area, s.cd_nom;

CREATE VIEW gn_synthese.v_color_taxon_area AS
SELECT cd_nom, id_area, nb_obs, last_date,
 CASE
  WHEN date_part('day', (now() - last_date)) < 365 THEN 'grey'
  ELSE 'red'
 END as color
FROM gn_synthese.v_area_taxon;
