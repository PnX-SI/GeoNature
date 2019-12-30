--Created here because gn_meta uses gn_commons (see above) and must be created after gn_commons
CREATE TABLE gn_commons.cor_module_dataset (
    id_module integer NOT NULL,
    id_dataset integer NOT NULL,
  CONSTRAINT pk_cor_module_dataset PRIMARY KEY (id_module, id_dataset),
  CONSTRAINT fk_cor_module_dataset_id_module FOREIGN KEY (id_module)
      REFERENCES gn_commons.t_modules (id_module) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE NO ACTION,
  CONSTRAINT fk_cor_module_dataset_id_dataset FOREIGN KEY (id_dataset)
      REFERENCES gn_meta.t_datasets (id_dataset) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE NO ACTION
);
COMMENT ON TABLE gn_commons.cor_module_dataset IS 'Define wich datasets can be used in modules';

-- on met tous les JDD comme appartenant Occtax par défaut pour assurer la rétrocompatibilité

INSERT into gn_commons.cor_module_dataset(id_module, id_dataset)
SELECT
gn_commons.get_id_module_bycode('OCCTAX'), t.id_dataset
FROM gn_meta.t_datasets t
WHERE t.active = true
;

DROP view gn_commons.v_synthese_validation_forwebapp;
CREATE OR REPLACE VIEW gn_commons.v_synthese_validation_forwebapp AS
 SELECT DISTINCT ON (s.id_synthese) s.id_synthese,
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
    v.validation_auto,
    v.validation_date
   FROM gn_synthese.synthese s
     JOIN taxonomie.taxref t ON t.cd_nom = s.cd_nom
     JOIN gn_meta.t_datasets d ON d.id_dataset = s.id_dataset
     LEFT JOIN ref_nomenclatures.t_nomenclatures n ON n.id_nomenclature = s.id_nomenclature_valid_status
     LEFT JOIN gn_commons.t_validations v ON v.uuid_attached_row = s.unique_id_sinp
  WHERE d.validable = true
  ORDER BY s.id_synthese, v.validation_date DESC;

COMMENT ON VIEW gn_commons.v_synthese_validation_forwebapp  IS 'Vue utilisée pour le module validation. Prend l''id_nomenclature dans la table synthese ainsi que toutes les colonnes de la synthese pour les filtres. On JOIN sur la vue latest_validation pour voir si la validation est auto';

DROP VIEW gn_synthese.v_synthese_for_export;
CREATE OR REPLACE VIEW gn_synthese.v_synthese_for_export AS
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
    t.nom_valide AS "nomValide",
    s.nom_cite AS "nomCite",
    public.ST_x(public.ST_transform(s.the_geom_point, 2154)) AS x_centroid,
    public.ST_y(public.ST_transform(s.the_geom_point, 2154)) AS y_centroid,
    COALESCE(s.meta_update_date, s.meta_create_date) AS lastact,
    public.ST_asgeojson(s.the_geom_4326) AS geojson_4326,
    public.ST_asgeojson(s.the_geom_local) AS geojson_local,
    n1.label_default AS "ObjGeoTyp",
    n2.label_default AS "methGrp",
    n3.label_default AS "obsMeth",
    n4.label_default AS "obsTech",
    n5.label_default AS "ocStatutBio",
    n6.label_default AS "ocEtatBio",
    n7.label_default AS "ocNat",
    n8.label_default AS "preuveOui",
    n9.label_default AS "difNivPrec",
    n10.label_default AS "ocStade",
    n11.label_default AS "ocSex",
    n12.label_default AS "objDenbr",
    n13.label_default AS "denbrTyp",
    n14.label_default AS"sensiNiv",
    n15.label_default AS "statObs",
    n16.label_default AS "dEEFlou",
    n17.label_default AS "statSource",
    n18.label_default AS "typInfGeo",
    n19.label_default AS "ocMethDet"
   FROM gn_synthese.synthese s
     JOIN taxonomie.taxref t ON t.cd_nom = s.cd_nom
     JOIN gn_meta.t_datasets d ON d.id_dataset = s.id_dataset
     JOIN gn_synthese.t_sources sources ON sources.id_source = s.id_source
     LEFT JOIN ref_nomenclatures.t_nomenclatures n1 ON s.id_nomenclature_geo_object_nature = n1.id_nomenclature
     LEFT JOIN ref_nomenclatures.t_nomenclatures n2 ON s.id_nomenclature_grp_typ = n2.id_nomenclature
     LEFT JOIN ref_nomenclatures.t_nomenclatures n3 ON s.id_nomenclature_obs_meth = n3.id_nomenclature
     LEFT JOIN ref_nomenclatures.t_nomenclatures n4 ON s.id_nomenclature_obs_technique = n4.id_nomenclature
     LEFT JOIN ref_nomenclatures.t_nomenclatures n5 ON s.id_nomenclature_bio_status = n5.id_nomenclature
     LEFT JOIN ref_nomenclatures.t_nomenclatures n6 ON s.id_nomenclature_bio_condition = n6.id_nomenclature
     LEFT JOIN ref_nomenclatures.t_nomenclatures n7 ON s.id_nomenclature_naturalness = n7.id_nomenclature
     LEFT JOIN ref_nomenclatures.t_nomenclatures n8 ON s.id_nomenclature_exist_proof = n8.id_nomenclature
     LEFT JOIN ref_nomenclatures.t_nomenclatures n9 ON s.id_nomenclature_diffusion_level = n9.id_nomenclature
     LEFT JOIN ref_nomenclatures.t_nomenclatures n10 ON s.id_nomenclature_life_stage = n10.id_nomenclature
     LEFT JOIN ref_nomenclatures.t_nomenclatures n11 ON s.id_nomenclature_sex = n11.id_nomenclature
     LEFT JOIN ref_nomenclatures.t_nomenclatures n12 ON s.id_nomenclature_obj_count = n12.id_nomenclature
     LEFT JOIN ref_nomenclatures.t_nomenclatures n13 ON s.id_nomenclature_type_count = n13.id_nomenclature
     LEFT JOIN ref_nomenclatures.t_nomenclatures n14 ON s.id_nomenclature_sensitivity = n14.id_nomenclature
     LEFT JOIN ref_nomenclatures.t_nomenclatures n15 ON s.id_nomenclature_observation_status = n15.id_nomenclature
     LEFT JOIN ref_nomenclatures.t_nomenclatures n16 ON s.id_nomenclature_blurring = n16.id_nomenclature
     LEFT JOIN ref_nomenclatures.t_nomenclatures n17 ON s.id_nomenclature_source_status = n17.id_nomenclature
     LEFT JOIN ref_nomenclatures.t_nomenclatures n18 ON s.id_nomenclature_info_geo_type = n18.id_nomenclature
     LEFT JOIN ref_nomenclatures.t_nomenclatures n19 ON s.id_nomenclature_determination_method = n19.id_nomenclature
;

CREATE OR REPLACE VIEW pr_occtax.export_occtax_sinp AS
 SELECT
    ccc.unique_id_sinp_occtax AS "permId",
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
    gn_commons.get_default_parameter('taxref_version'::text, NULL::integer) AS "vTAXREF",
    'NSP'::text AS "dSPublique",
    d.unique_dataset_id AS "jddMetaId",
    ref_nomenclatures.get_cd_nomenclature(occ.id_nomenclature_source_status) AS "statSource",
    '0'::text AS "difNivPrec",
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
    occ.comment AS "obsDescr",
    rel.unique_id_sinp_grp AS "permIdGrp",
    'Relevé'::text AS "methGrp",
    'OBS'::text AS "typGrp",
    ccc.count_max AS "denbrMax",
    ccc.count_min AS "denbrMin",
    ref_nomenclatures.get_cd_nomenclature(ccc.id_nomenclature_obj_count) AS "objDenbr",
    ref_nomenclatures.get_cd_nomenclature(ccc.id_nomenclature_type_count) AS "typDenbr",
    COALESCE(string_agg(DISTINCT (r.nom_role::text || ' '::text) || r.prenom_role::text, ','::text), rel.observers_txt::text) AS "obsId",
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
   GROUP BY ccc.id_counting_occtax,occ.id_occurrence_occtax,rel.id_releve_occtax,d.id_dataset;

--INDEX--
CREATE INDEX i_cor_role_releves_occtax_id_releve_occtax ON pr_occtax.cor_role_releves_occtax USING btree (id_releve_occtax);
CREATE INDEX i_cor_role_releves_occtax_id_role ON pr_occtax.cor_role_releves_occtax USING btree (id_role);
CREATE unique INDEX i_cor_role_releves_occtax_id_role_id_releve_occtax ON pr_occtax.cor_role_releves_occtax USING btree (id_role, id_releve_occtax);

CREATE INDEX i_cor_counting_occtax_id_nomenclature_life_stage ON pr_occtax.cor_counting_occtax USING btree (id_nomenclature_life_stage);
CREATE INDEX i_cor_counting_occtax_id_nomenclature_sex ON pr_occtax.cor_counting_occtax USING btree (id_nomenclature_sex);
CREATE INDEX i_cor_counting_occtax_id_nomenclature_obj_count ON pr_occtax.cor_counting_occtax USING btree (id_nomenclature_obj_count);
CREATE INDEX i_cor_counting_occtax_id_nomenclature_type_count ON pr_occtax.cor_counting_occtax USING btree (id_nomenclature_type_count);

CREATE INDEX i_t_occurrences_occtax_id_nomenclature_obs_meth ON pr_occtax.t_occurrences_occtax USING btree (id_nomenclature_obs_meth);
CREATE INDEX i_t_occurrences_occtax_id_nomenclature_bio_condition ON pr_occtax.t_occurrences_occtax USING btree (id_nomenclature_bio_condition);
CREATE INDEX i_t_occurrences_occtax_id_nomenclature_bio_status ON pr_occtax.t_occurrences_occtax USING btree (id_nomenclature_bio_status);
CREATE INDEX i_t_occurrences_occtax_id_nomenclature_naturalness ON pr_occtax.t_occurrences_occtax USING btree (id_nomenclature_naturalness);
CREATE INDEX i_t_occurrences_occtax_id_nomenclature_exist_proof ON pr_occtax.t_occurrences_occtax USING btree (id_nomenclature_exist_proof);
CREATE INDEX i_t_occurrences_occtax_id_nomenclature_observation_status ON pr_occtax.t_occurrences_occtax USING btree (id_nomenclature_observation_status);
CREATE INDEX i_t_occurrences_occtax_id_nomenclature_blurring ON pr_occtax.t_occurrences_occtax USING btree (id_nomenclature_blurring);
CREATE INDEX i_t_occurrences_occtax_id_nomenclature_source_status ON pr_occtax.t_occurrences_occtax USING btree (id_nomenclature_source_status);
CREATE INDEX i_t_occurrences_occtax_id_nomenclature_determination_method ON pr_occtax.t_occurrences_occtax USING btree (id_nomenclature_determination_method);


CREATE INDEX i_t_releves_occtax_id_nomenclature_obs_technique ON pr_occtax.t_releves_occtax USING btree (id_nomenclature_obs_technique);
CREATE INDEX i_t_releves_occtax_id_nomenclature_grp_typ ON pr_occtax.t_releves_occtax USING btree (id_nomenclature_grp_typ);
CREATE INDEX i_t_releves_occtax_geom_local ON pr_occtax.t_releves_occtax USING gist (geom_local);
CREATE INDEX i_t_releves_occtax_date_max ON pr_occtax.t_releves_occtax USING btree (date_max);

-- ###############################################
-- MONITORING
-- ###############################################
-- Nettoyage monitoring
DROP TABLE IF EXISTS gn_monitoring.cor_site_application;

-- gn_commons.t_modules Changement des CHARACTER(n) en CHARACTER VARYING(n)
ALTER TABLE gn_commons.t_modules ALTER COLUMN module_path TYPE CHARACTER VARYING(255);
ALTER TABLE gn_commons.t_modules ALTER COLUMN module_external_url TYPE CHARACTER VARYING(255);
ALTER TABLE gn_commons.t_modules ALTER COLUMN module_target TYPE CHARACTER VARYING(10);

-- gn_commons.t_modules  : module_code, module_path UNIQUE
ALTER TABLE gn_commons.t_modules ADD CONSTRAINT unique_t_modules_module_path UNIQUE (module_path);
ALTER TABLE gn_commons.t_modules ADD CONSTRAINT unique_t_modules_module_code UNIQUE (module_code);

-- Ajout date création modificiation sur les tables de base de monitoring
-- viens en complément du stockage vertical
ALTER TABLE gn_monitoring.t_base_sites ADD meta_create_date timestamp without time zone DEFAULT now();
ALTER TABLE gn_monitoring.t_base_sites ADD meta_update_date timestamp without time zone DEFAULT now();

ALTER TABLE gn_monitoring.t_base_sites ADD altitude_min int;
ALTER TABLE gn_monitoring.t_base_sites ADD altitude_max int;

DO $$
DECLARE local_srid integer;
BEGIN
    local_srid := (SELECT parameter_value FROM gn_commons.t_parameters WHERE parameter_name = 'local_srid');

    EXECUTE 'ALTER TABLE gn_monitoring.t_base_sites ADD geom_local geometry(Geometry,' || local_srid || ')';

    --Mise à jour des données existantes: champ geom_local
    UPDATE  gn_monitoring.t_base_sites SET geom_local = st_transform(geom, local_srid);
END $$;

--Mise à jour des données existantes : champ alt_min/max
WITH alt AS (
    SELECT (ref_geo.fct_get_altitude_intersection(geom_local)).*, id_base_site
    FROM gn_monitoring.t_base_sites
)
UPDATE gn_monitoring.t_base_sites  s SET altitude_min = alt.altitude_min, altitude_max = alt.altitude_max
FROM alt
WHERE s.id_base_site = alt.id_base_site;


CREATE TRIGGER tri_calculate_geom_local
  BEFORE INSERT OR UPDATE
  ON gn_monitoring.t_base_sites
  FOR EACH ROW
  EXECUTE PROCEDURE ref_geo.fct_trg_calculate_geom_local('geom', 'geom_local');


CREATE TRIGGER tri_meta_dates_change_t_base_sites
  BEFORE INSERT OR UPDATE
  ON gn_monitoring.t_base_sites
  FOR EACH ROW
  EXECUTE PROCEDURE public.fct_trg_meta_dates_change();


CREATE OR REPLACE FUNCTION ref_geo.fct_trg_calculate_alt_minmax()
  RETURNS trigger AS
$BODY$
DECLARE
	the4326geomcol text := quote_ident(TG_ARGV[0]);
  thelocalsrid int;
BEGIN
	-- si c'est un insert ou que c'est un UPDATE ET que le geom_4326 a été modifié
	IF (TG_OP = 'INSERT' OR (TG_OP = 'UPDATE' AND NOT public.ST_EQUALS(hstore(OLD)-> the4326geomcol, hstore(NEW)-> the4326geomcol))) THEN
		--récupérer le srid local
		SELECT INTO thelocalsrid parameter_value::int FROM gn_commons.t_parameters WHERE parameter_name = 'local_srid';
		--Calcul de l'altitude
        SELECT (ref_geo.fct_get_altitude_intersection(st_transform(hstore(NEW)-> the4326geomcol,thelocalsrid))).*  INTO NEW.altitude_min, NEW.altitude_max ;

	END IF;
  RETURN NEW;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;


CREATE TRIGGER tri_t_base_sites_calculate_alt
  BEFORE INSERT OR UPDATE
  ON gn_monitoring.t_base_sites
  FOR EACH ROW
  EXECUTE PROCEDURE ref_geo.fct_trg_calculate_alt_minmax('geom');


ALTER TABLE gn_monitoring.t_base_visits ADD meta_create_date timestamp without time zone DEFAULT now();
ALTER TABLE gn_monitoring.t_base_visits ADD meta_update_date timestamp without time zone DEFAULT now();

ALTER TABLE gn_monitoring.t_base_visits ADD id_dataset integer NOT NULL;

ALTER TABLE gn_monitoring.t_base_visits ADD CONSTRAINT fk_t_base_visits_t_datasets FOREIGN KEY (id_dataset)
      REFERENCES gn_meta.t_datasets (id_dataset) MATCH SIMPLE
      ON UPDATE CASCADE ON DELETE NO ACTION;


ALTER TABLE gn_monitoring.t_base_visits ADD id_nomenclature_obs_technique integer DEFAULT ref_nomenclatures.get_id_nomenclature('TECHNIQUE_OBS', '133');
ALTER TABLE gn_monitoring.t_base_visits ADD id_nomenclature_grp_typ integer DEFAULT ref_nomenclatures.get_id_nomenclature('TYP_GRP', 'PASS');

ALTER TABLE gn_monitoring.t_base_visits ADD COLUMN IF NOT EXISTS id_module INTEGER NOT NULL;

ALTER TABLE gn_monitoring.t_base_visits ADD CONSTRAINT fk_t_base_visits_id_module FOREIGN KEY (id_module)
            REFERENCES gn_commons.t_modules (id_module) MATCH SIMPLE
            ON UPDATE CASCADE ON DELETE CASCADE;


ALTER TABLE ONLY gn_monitoring.t_base_visits
    ADD CONSTRAINT fk_t_base_visits_id_nomenclature_obs_technique FOREIGN KEY (id_nomenclature_obs_technique) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY gn_monitoring.t_base_visits
    ADD CONSTRAINT fk_t_base_visits_id_nomenclature_grp_typ FOREIGN KEY (id_nomenclature_grp_typ) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE gn_monitoring.t_base_visits
  ADD CONSTRAINT check_t_base_visits_id_nomenclature_obs_technique CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_obs_technique,'TECHNIQUE_OBS')) NOT VALID;

ALTER TABLE gn_monitoring.t_base_visits
  ADD CONSTRAINT check_t_base_visits_id_nomenclature_grp_typ CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_grp_typ,'TYP_GRP')) NOT VALID;


CREATE TRIGGER tri_meta_dates_change_synthese
  BEFORE INSERT OR UPDATE
  ON gn_monitoring.t_base_visits
  FOR EACH ROW
  EXECUTE PROCEDURE public.fct_trg_meta_dates_change();



-- ###############################################
-- EXPORT TAXON LIST
-- ###############################################

-- Vue export des taxons de la synthèse
-- Première version qui reste à affiner/étoffer
CREATE OR REPLACE VIEW gn_synthese.v_synthese_taxon_for_export_view AS
 SELECT DISTINCT
    ref.nom_valide,
    ref.cd_ref,
    ref.nom_vern,
    ref.group1_inpn,
    ref.group2_inpn,
    ref.regne,
    ref.phylum,
    ref.classe,
    ref.ordre,
    ref.famille,
    ref.id_rang
FROM gn_synthese.synthese  s
JOIN taxonomie.taxref t ON s.cd_nom = t.cd_nom
JOIN taxonomie.taxref ref ON t.cd_ref = ref.cd_nom;

