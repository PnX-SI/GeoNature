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

COMMENT ON VIEW gn_commons.v_synthese_validation_forwebapp  IS 'Vue utilisée pour le module validation. Prend l''id_nomenclature dans la table synthese ainsi que toutes les colonnes de la synthese pour les filtres. On JOIN sur la vue latest_validation pour voir si la validation est auto';


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

ALTER TABLE gn_synthese.cor_area_synthese DROP COLUMN IF EXISTS cd_nom;

-- suppression des aires de cor_area where enabled = false
DELETE FROM gn_synthese.cor_area_synthese WHERE id_area IN (
SELECT s.id_area
FROM gn_synthese.cor_area_synthese s
JOIN ref_geo.l_areas a ON a.id_area = s.id_area
WHERE a.enable IS false
);

-- Correction de la fonction trigger gn_synthese.fct_trg_refresh_taxons_forautocomplete
-- susceptible de créer des doublons sur le nom vernaculaire

CREATE OR REPLACE FUNCTION gn_synthese.fct_trg_refresh_taxons_forautocomplete()
  RETURNS trigger AS
$BODY$
 DECLARE
  thenomvern VARCHAR;
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
      FROM taxonomie.taxref t WHERE cd_nom = NEW.cd_nom;
      --On insère une seule fois le nom_vern car il est le même pour tous les synonymes
      SELECT INTO thenomvern t.cd_nom 
      FROM gn_synthese.taxons_synthese_autocomplete a
      JOIN taxonomie.taxref t ON t.cd_nom = a.cd_nom
      WHERE a.cd_ref = taxonomie.find_cdref(NEW.cd_nom)
      AND a.search_name ILIKE t.nom_vern||'%';
      IF thenomvern IS NULL THEN
        INSERT INTO gn_synthese.taxons_synthese_autocomplete
        SELECT t.cd_nom,
          t.cd_ref,
          concat(t.nom_vern, ' =  <i> ', t.nom_valide, '</i>', ' - [', t.id_rang, ' - ', t.cd_nom , ']' ) AS search_name,
          t.nom_valide,
          t.lb_nom,
          t.regne,
          t.group2_inpn
        FROM taxonomie.taxref t WHERE t.nom_vern IS NOT NULL AND cd_nom = NEW.cd_nom;
      END IF;
    END IF;
  RETURN NULL;
  END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

CREATE OR REPLACE FUNCTION ref_geo.fct_trg_calculate_geom_local()
  RETURNS trigger AS
-- trigger qui reprojete une geom a partir d'une geom source fournie et l'insert dans le NEW
-- en prenant le parametre local_srid de la table t_parameters
-- 1er param: nom de la colonne source
-- 2eme param: nom de la colonne a reprojeter
-- utiliser pour calculer les geom_local à partir des geom_4326
$BODY$
DECLARE
	the4326geomcol text := quote_ident(TG_ARGV[0]);
	thelocalgeomcol text := quote_ident(TG_ARGV[1]);
        thelocalsrid int;
        thegeomlocalvalue public.geometry;
        thegeomchange boolean;
BEGIN
	-- si c'est un insert ou que c'est un UPDATE ET que le geom_4326 a été modifié
	IF (TG_OP = 'INSERT' OR (TG_OP = 'UPDATE' AND NOT public.ST_EQUALS(hstore(OLD)-> the4326geomcol, hstore(NEW)-> the4326geomcol)  )) THEN
		--récupérer le srid local
		SELECT INTO thelocalsrid parameter_value::int FROM gn_commons.t_parameters WHERE parameter_name = 'local_srid';
		EXECUTE FORMAT ('SELECT public.ST_TRANSFORM($1.%I, $2)',the4326geomcol) INTO thegeomlocalvalue USING NEW, thelocalsrid;
                -- insertion dans le NEW de la geom transformée
		NEW := NEW#= hstore(thelocalgeomcol, thegeomlocalvalue);
	END IF;
  RETURN NEW;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

CREATE OR REPLACE FUNCTION ref_geo.fct_get_area_intersection(
    IN mygeom public.geometry,
    IN myidtype integer DEFAULT NULL::integer)
  RETURNS TABLE(id_area integer, id_type integer, area_code character varying, area_name character varying) AS
$BODY$
DECLARE
  isrid int;
BEGIN
  SELECT gn_commons.get_default_parameter('local_srid', NULL) INTO isrid;
  RETURN QUERY
  WITH d  as (
      SELECT public.st_transform(myGeom,isrid) geom_trans
  )
  SELECT a.id_area, a.id_type, a.area_code, a.area_name
  FROM ref_geo.l_areas a, d
  WHERE public.st_intersects(geom_trans, a.geom)
    AND (myIdType IS NULL OR a.id_type = myIdType)
    AND enable=true;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;



CREATE MATERIALIZED VIEW vm_min_max_for_taxons AS
WITH
s as (
  SELECT synt.cd_nom, t.cd_ref, the_geom_local, date_min, date_max, altitude_min, altitude_max
  FROM gn_synthese.synthese synt
  LEFT JOIN taxonomie.taxref t ON t.cd_nom = synt.cd_nom
  WHERE id_nomenclature_valid_status IN('1','2')
)
,loc AS (
  SELECT cd_ref,
	count(*) AS nbobs,
	public.ST_Transform(public.ST_SetSRID(public.box2d(public.ST_extent(s.the_geom_local))::geometry,2154), 4326) AS bbox4326
  FROM  s
  GROUP BY cd_ref
)
,dat AS (
  SELECT cd_ref,
	min(TO_CHAR(date_min, 'DDD')::int) AS daymin,
	max(TO_CHAR(date_max, 'DDD')::int) AS daymax
  FROM s
  GROUP BY cd_ref
)
,alt AS (
  SELECT cd_ref,
	min(altitude_min) AS altitudemin,
	max(altitude_max) AS altitudemax
  FROM s
  GROUP BY cd_ref
)
SELECT loc.cd_ref, nbobs,  daymin, daymax, altitudemin, altitudemax, bbox4326
FROM loc
LEFT JOIN alt ON alt.cd_ref = loc.cd_ref
LEFT JOIN dat ON dat.cd_ref = loc.cd_ref
ORDER BY loc.cd_ref;

CREATE OR REPLACE FUNCTION gn_synthese.fct_trig_insert_in_cor_area_synthese()
  RETURNS trigger AS
$BODY$
  DECLARE
  id_area_loop integer;
  geom_change boolean;
  BEGIN
  geom_change = false;
  IF(TG_OP = 'UPDATE') THEN
	SELECT INTO geom_change NOT public.ST_EQUALS(OLD.the_geom_local, NEW.the_geom_local);
  END IF;

  IF (geom_change) THEN
	DELETE FROM gn_synthese.cor_area_synthese WHERE id_synthese = NEW.id_synthese;
  END IF;

  -- intersection avec toutes les areas et écriture dans cor_area_synthese
    IF (TG_OP = 'INSERT' OR (TG_OP = 'UPDATE' AND geom_change )) THEN
      INSERT INTO gn_synthese.cor_area_synthese SELECT
	      s.id_synthese AS id_synthese,
        a.id_area AS id_area
        FROM ref_geo.l_areas a
        JOIN gn_synthese.synthese s ON public.ST_INTERSECTS(s.the_geom_local, a.geom)
        WHERE s.id_synthese = NEW.id_synthese AND a.enable IS true;
    END IF;
  RETURN NULL;
  END;
  $BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

CREATE OR REPLACE VIEW gn_synthese.v_synthese_for_web_app AS 
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
    public.ST_asgeojson(the_geom_4326),
    s.date_min,
    s.date_max,
    s.validator,
    s.validation_comment,
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
    s.id_nomenclature_valid_status,
    s.id_nomenclature_diffusion_level,
    s.id_nomenclature_life_stage,
    s.id_nomenclature_sex,
    s.id_nomenclature_obj_count,
    s.id_nomenclature_type_count,
    s.id_nomenclature_sensitivity,
    s.id_nomenclature_observation_status,
    s.id_nomenclature_blurring,
    s.id_nomenclature_source_status,
    s.id_nomenclature_determination_method,
    sources.name_source,
    sources.url_source,
    t.cd_nom,
    t.cd_ref,
    t.nom_valide,
    t.lb_nom,
    t.nom_vern
   FROM gn_synthese.synthese s
     JOIN taxonomie.taxref t ON t.cd_nom = s.cd_nom
     JOIN gn_meta.t_datasets d ON d.id_dataset = s.id_dataset
     JOIN gn_synthese.t_sources sources ON sources.id_source = s.id_source;


CREATE OR REPLACE VIEW gn_synthese.v_synthese_for_export AS 
 WITH deco AS (
         SELECT s_1.id_synthese,
            n1.label_default AS "ObjGeoTyp",
            n2.label_default AS "methGrp",
            n3.label_default AS "obsMeth",
            n4.label_default AS "obsTech",
            n5.label_default AS "ocEtatBio",
            n6.label_default AS "ocStatBio",
            n7.label_default AS "ocNat",
            n8.label_default AS "preuveOui",
            n9.label_default AS "difNivPrec",
            n10.label_default AS "ocStade",
            n11.label_default AS "ocSex",
            n12.label_default AS "objDenbr",
            n13.label_default AS "denbrTyp",
            n14.label_default AS "sensiNiv",
            n15.label_default AS "statObs",
            n16.label_default AS "dEEFlou",
            n17.label_default AS "statSource",
            n18.label_default AS "typInfGeo",
            n19.label_default AS "ocMethDet"
           FROM gn_synthese.synthese s_1
            LEFT JOIN ref_nomenclatures.t_nomenclatures n1 ON s_1.id_nomenclature_geo_object_nature = n1.id_nomenclature
            LEFT JOIN ref_nomenclatures.t_nomenclatures n2 ON s_1.id_nomenclature_grp_typ = n2.id_nomenclature
            LEFT JOIN ref_nomenclatures.t_nomenclatures n3 ON s_1.id_nomenclature_obs_meth = n3.id_nomenclature
            LEFT JOIN ref_nomenclatures.t_nomenclatures n4 ON s_1.id_nomenclature_obs_technique = n4.id_nomenclature
            LEFT JOIN ref_nomenclatures.t_nomenclatures n5 ON s_1.id_nomenclature_bio_status = n5.id_nomenclature
            LEFT JOIN ref_nomenclatures.t_nomenclatures n6 ON s_1.id_nomenclature_bio_condition = n6.id_nomenclature
            LEFT JOIN ref_nomenclatures.t_nomenclatures n7 ON s_1.id_nomenclature_naturalness = n7.id_nomenclature
            LEFT JOIN ref_nomenclatures.t_nomenclatures n8 ON s_1.id_nomenclature_exist_proof = n8.id_nomenclature
            LEFT JOIN ref_nomenclatures.t_nomenclatures n9 ON s_1.id_nomenclature_diffusion_level = n9.id_nomenclature
            LEFT JOIN ref_nomenclatures.t_nomenclatures n10 ON s_1.id_nomenclature_life_stage = n10.id_nomenclature
            LEFT JOIN ref_nomenclatures.t_nomenclatures n11 ON s_1.id_nomenclature_sex = n11.id_nomenclature
            LEFT JOIN ref_nomenclatures.t_nomenclatures n12 ON s_1.id_nomenclature_obj_count = n12.id_nomenclature
            LEFT JOIN ref_nomenclatures.t_nomenclatures n13 ON s_1.id_nomenclature_type_count = n13.id_nomenclature
            LEFT JOIN ref_nomenclatures.t_nomenclatures n14 ON s_1.id_nomenclature_sensitivity = n14.id_nomenclature
            LEFT JOIN ref_nomenclatures.t_nomenclatures n15 ON s_1.id_nomenclature_observation_status = n15.id_nomenclature
            LEFT JOIN ref_nomenclatures.t_nomenclatures n16 ON s_1.id_nomenclature_blurring = n16.id_nomenclature
            LEFT JOIN ref_nomenclatures.t_nomenclatures n17 ON s_1.id_nomenclature_source_status = n17.id_nomenclature
            LEFT JOIN ref_nomenclatures.t_nomenclatures n18 ON s_1.id_nomenclature_info_geo_type = n18.id_nomenclature
            LEFT JOIN ref_nomenclatures.t_nomenclatures n19 ON s_1.id_nomenclature_determination_method = n19.id_nomenclature
        )
 SELECT s.id_synthese AS "idSynthese",
    s.unique_id_sinp AS "permId",
    s.unique_id_sinp_grp AS "permIdGrp",
    s.count_min AS "denbrMin",
    s.count_max AS "denbrMax",
    s.meta_v_taxref AS "vTAXREF",
    s.sample_number_proof AS "sampleNumb",
    s.digital_proof AS "preuvNum",
    s.non_digital_proof AS "preuvNoNum",
    s.altitude_min AS "altMin",
    s.altitude_max AS "altMax",
    public.ST_astext(s.the_geom_4326) AS wkt,
    s.date_min AS "dateDebut",
    s.date_max AS "dateFin",
    s.validator AS validateur,
    s.observers AS observer,
    s.id_digitiser AS id_digitiser,
    s.determiner AS detminer,
    s.comment_context AS "obsCtx",
    s.comment_description AS "obsDescr",
    s.meta_create_date,
    s.meta_update_date,
    d.id_dataset AS "jddId",
    d.dataset_name AS "jddCode",
    d.id_acquisition_framework,
    t.cd_nom AS "cdNom",
    t.cd_ref AS "cdRef",
    s.nom_cite AS "nomCite",
    public.ST_x(public.ST_transform(s.the_geom_point, 2154)) AS x_centroid,
    public.ST_y(public.ST_transform(s.the_geom_point, 2154)) AS y_centroid,
    COALESCE(s.meta_update_date, s.meta_create_date) AS lastact,
    public.ST_asgeojson(s.the_geom_4326) AS geojson_4326,
    public.ST_asgeojson(s.the_geom_local) AS geojson_local,
    deco."ObjGeoTyp",
    deco."methGrp",
    deco."obsMeth",
    deco."obsTech",
    deco."ocEtatBio",
    deco."ocNat",
    deco."preuveOui",
    deco."difNivPrec",
    deco."ocStade",
    deco."ocSex",
    deco."objDenbr",
    deco."denbrTyp",
    deco."sensiNiv",
    deco."statObs",
    deco."dEEFlou",
    deco."statSource",
    deco."typInfGeo"
   FROM gn_synthese.synthese s
     JOIN taxonomie.taxref t ON t.cd_nom = s.cd_nom
     JOIN gn_meta.t_datasets d ON d.id_dataset = s.id_dataset
     JOIN gn_synthese.t_sources sources ON sources.id_source = s.id_source
     JOIN deco ON deco.id_synthese = s.id_synthese;


-- ajout d'index 

CREATE INDEX i_t_releves_occtax_id_dataset
  ON pr_occtax.t_releves_occtax
  USING btree
  (id_dataset);

CREATE INDEX i_t_releves_occtax_geom_4326
  ON pr_occtax.t_releves_occtax
  USING gist
  (geom_4326);


CREATE INDEX i_t_occurrences_occtax_id_releve_occtax
  ON pr_occtax.t_occurrences_occtax
  USING btree
  (id_releve_occtax);

CREATE INDEX i_t_occurrences_occtax_cd_nom
  ON pr_occtax.t_occurrences_occtax
  USING btree
  (cd_nom);


CREATE INDEX i_cor_counting_occtax_id_occurrence_occtax
  ON pr_occtax.cor_counting_occtax
  USING btree
  (id_occurrence_occtax);


CREATE INDEX i_t_datasets_id_acquisition_framework
  ON gn_meta.t_datasets
  USING btree
  (id_acquisition_framework);


-- suppression de l'uuid sur cor_role_releve - replacement par un serial
ALTER TABLE pr_occtax.cor_role_releves_occtax DROP CONSTRAINT pk_cor_role_releves_occtax;
ALTER TABLE pr_occtax.cor_role_releves_occtax ADD PRIMARY KEY (id_releve_occtax, id_role);


-- update vue v_releve_list

DROP VIEW pr_occtax.v_releve_list;
CREATE OR REPLACE VIEW pr_occtax.v_releve_list AS 
WITH 
    occurrences (id_releve_occtax, taxons, nb_occ) as (
    SELECT id_releve_occtax, 
    string_agg(DISTINCT t.nom_valide::text, ', '::text) AS taxons,
    count(DISTINCT occ.id_occurrence_occtax) AS nb_occ
    FROM pr_occtax.t_occurrences_occtax occ
    INNER JOIN taxonomie.taxref t ON occ.cd_nom = t.cd_nom
    GROUP BY id_releve_occtax
),
observateurs (id_releve_occtax, nb_observer, observers_txt) as (
    SELECT id_releve_occtax, 
    count(DISTINCT obs.id_role) AS nb_observer,
    string_agg(DISTINCT CONCAT_WS(' ', NULLIF(obs.nom_role, ''), NULLIF(obs.prenom_role, '')), ', '::text) as observers
    FROM pr_occtax.cor_role_releves_occtax cor_role
    INNER JOIN utilisateurs.t_roles obs ON cor_role.id_role = obs.id_role
    GROUP BY id_releve_occtax
)
SELECT rel.id_releve_occtax,
    rel.id_dataset,
    rel.id_digitiser,
    rel.date_min,
    rel.date_max,
    rel.altitude_min,
    rel.altitude_max,
    rel.meta_device_entry,
    rel.comment,
    rel.geom_4326,
    rel."precision",
    rel.observers_txt,
    dataset.dataset_name,
    taxons,
    CONCAT_WS('<br/>', 
    	taxons, 
    	CASE WHEN rel.date_min::date = rel.date_max::date THEN to_char(rel.date_min, 'DD/MM/YYYY') ELSE CONCAT(to_char(rel.date_min, 'DD/MM/YYYY'), ' - ', to_char(rel.date_max::date, 'DD/MM/YYYY')) END, 
    	COALESCE(cor_role.observers_txt, rel.observers_txt)
    ) AS leaflet_popup,
    COALESCE(cor_role.observers_txt, rel.observers_txt) AS observateurs,
    nb_occ,
    nb_observer
FROM pr_occtax.t_releves_occtax rel
INNER JOIN gn_meta.t_datasets dataset ON dataset.id_dataset = rel.id_dataset
LEFT JOIN observateurs cor_role ON cor_role.id_releve_occtax = rel.id_releve_occtax
LEFT JOIN occurrences occ ON occ.id_releve_occtax = rel.id_releve_occtax;


-- update fonction calcul des altitudes (bug)

CREATE OR REPLACE FUNCTION ref_geo.fct_get_altitude_intersection(mygeom geometry)
 RETURNS TABLE(altitude_min integer, altitude_max integer)
 LANGUAGE plpgsql
AS $function$
DECLARE
    thesrid int;
    is_vectorized int;
BEGIN
  SELECT gn_commons.get_default_parameter('local_srid', NULL) INTO thesrid;
  SELECT COALESCE(gid, NULL) FROM ref_geo.dem_vector LIMIT 1 INTO is_vectorized;
	
  IF is_vectorized IS NULL THEN
    -- Use dem
    RETURN QUERY
    SELECT min((altitude).val)::integer AS altitude_min, max((altitude).val)::integer AS altitude_max
    FROM (
	SELECT public.ST_DumpAsPolygons(public.ST_clip(
    rast, 
    1,
	  public.st_transform(myGeom,thesrid), 
    true)
  ) AS altitude
	FROM ref_geo.dem AS altitude 
	WHERE public.st_intersects(rast,public.st_transform(myGeom,thesrid))
    ) AS a;		
  -- Use dem_vector
  ELSE
    RETURN QUERY
    WITH d  as (
        SELECT public.st_transform(myGeom,thesrid) a
     )
    SELECT min(val)::int as altitude_min, max(val)::int as altitude_max
    FROM ref_geo.dem_vector, d
    WHERE public.st_intersects(a,geom);
  END IF;
END;
$function$
;

CREATE OR REPLACE FUNCTION ref_geo.fct_get_area_intersection(
    IN mygeom public.geometry,
    IN myidtype integer DEFAULT NULL::integer)
  RETURNS TABLE(id_area integer, id_type integer, area_code character varying, area_name character varying) AS
$BODY$
DECLARE
  isrid int;
BEGIN
  SELECT gn_commons.get_default_parameter('local_srid', NULL) INTO isrid;
  RETURN QUERY
  WITH d  as (
      SELECT public.st_transform(myGeom,isrid) geom_trans
  )
  SELECT a.id_area, a.id_type, a.area_code, a.area_name
  FROM ref_geo.l_areas a, d
  WHERE public.st_intersects(geom_trans, a.geom)
    AND (myIdType IS NULL OR a.id_type = myIdType)
    AND enable=true;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100
  ROWS 1000;


DROP VIEW gn_synthese.v_tree_taxons_synthese;

-- update v_taxon_tree (limite )
CREATE OR REPLACE VIEW gn_synthese.v_tree_taxons_synthese AS 
 WITH cd_famille AS (
         SELECT t_1.cd_ref,
            t_1.lb_nom AS nom_latin,
            t_1.nom_vern AS nom_francais,
            t_1.cd_nom,
            t_1.id_rang,
            t_1.regne,
            t_1.phylum,
            t_1.classe,
            t_1.ordre,
            t_1.famille,
            t_1.lb_nom
           FROM taxonomie.taxref t_1
          WHERE (t_1.lb_nom::text IN ( SELECT DISTINCT t_2.famille
                   FROM gn_synthese.synthese s
                     JOIN taxonomie.taxref t_2 ON t_2.cd_nom = s.cd_nom))
        ), cd_regne AS (
         SELECT DISTINCT taxref.cd_nom,
            taxref.regne
           FROM taxonomie.taxref
          WHERE taxref.id_rang::text = 'KD'::text AND taxref.cd_nom = taxref.cd_ref
        )
 SELECT t.cd_ref,
    t.nom_latin,
    t.nom_francais,
    t.id_regne,
    t.nom_regne,
    COALESCE(t.id_embranchement, t.id_regne) AS id_embranchement,
    COALESCE(t.nom_embranchement, ' Sans embranchement dans taxref'::character varying) AS nom_embranchement,
    COALESCE(t.id_classe, t.id_embranchement) AS id_classe,
    COALESCE(t.nom_classe, ' Sans classe dans taxref'::character varying) AS nom_classe,
    COALESCE(t.desc_classe, ' Sans classe dans taxref'::character varying) AS desc_classe,
    COALESCE(t.id_ordre, t.id_classe) AS id_ordre,
    COALESCE(t.nom_ordre, ' Sans ordre dans taxref'::character varying) AS nom_ordre
   FROM ( SELECT DISTINCT t_1.cd_ref,
            t_1.nom_latin,
            t_1.nom_francais,
            ( SELECT DISTINCT r.cd_nom
                   FROM cd_regne r
                  WHERE r.regne::text = t_1.regne::text) AS id_regne,
            t_1.regne AS nom_regne,
            ph.cd_nom AS id_embranchement,
            t_1.phylum AS nom_embranchement,
            t_1.phylum AS desc_embranchement,
            cl.cd_nom AS id_classe,
            t_1.classe AS nom_classe,
            t_1.classe AS desc_classe,
            ord.cd_nom AS id_ordre,
            t_1.ordre AS nom_ordre
           FROM cd_famille t_1
             LEFT JOIN taxonomie.taxref ph ON ph.id_rang::text = 'PH'::text AND ph.cd_nom = ph.cd_ref AND ph.lb_nom::text = t_1.phylum::text AND NOT t_1.phylum IS NULL
             LEFT JOIN taxonomie.taxref cl ON cl.id_rang::text = 'CL'::text AND cl.cd_nom = cl.cd_ref AND cl.lb_nom::text = t_1.classe::text AND NOT t_1.classe IS NULL
             LEFT JOIN taxonomie.taxref ord ON ord.id_rang::text = 'OR'::text AND ord.cd_nom = ord.cd_ref AND ord.lb_nom::text = t_1.ordre::text AND NOT t_1.ordre IS NULL) t
  ORDER BY t.id_regne, (COALESCE(t.id_embranchement, t.id_regne)), (COALESCE(t.id_classe, t.id_embranchement)), (COALESCE(t.id_ordre, t.id_classe));


  COMMENT ON VIEW gn_synthese.v_tree_taxons_synthese IS 'Vue destinée à l''arbre taxonomique de la synthese. S''arrête  à la famille pour des questions de performances';
