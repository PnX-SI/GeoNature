-- Ajout champs "Statut biogéographique" dans la Synthèse
INSERT INTO gn_synthese.defaults_nomenclatures_value (mnemonique_type, id_organism, regne, group2_inpn, id_nomenclature) VALUES
('STAT_BIOGEO',0,0,0, ref_nomenclatures.get_id_nomenclature('STAT_BIOGEO', '1'))
;

ALTER TABLE gn_synthese.synthese 
ADD COLUMN id_nomenclature_biogeo_status integer DEFAULT gn_synthese.get_default_nomenclature_value('STAT_BIOGEO');

ALTER TABLE ONLY gn_synthese.synthese
    ADD CONSTRAINT fk_synthese_id_nomenclature_biogeo_status 
    FOREIGN KEY (id_nomenclature_biogeo_status) 
    REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE gn_synthese.synthese
  ADD CONSTRAINT check_synthese_biogeo_status CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_biogeo_status,'STAT_BIOGEO')) NOT VALID;

-- Ajout de la nomenclature "Statut biogéographique" dans la vue décodant les nomenclatures
DROP VIEW gn_synthese.v_synthese_decode_nomenclatures;
CREATE OR REPLACE VIEW gn_synthese.v_synthese_decode_nomenclatures AS
SELECT
s.id_synthese,
ref_nomenclatures.get_nomenclature_label(s.id_nomenclature_geo_object_nature) AS nat_obj_geo,
ref_nomenclatures.get_nomenclature_label(s.id_nomenclature_grp_typ) AS grp_typ,
ref_nomenclatures.get_nomenclature_label(s.id_nomenclature_obs_technique) AS obs_technique,
ref_nomenclatures.get_nomenclature_label(s.id_nomenclature_bio_status) AS bio_status,
ref_nomenclatures.get_nomenclature_label(s.id_nomenclature_bio_condition) AS bio_condition,
ref_nomenclatures.get_nomenclature_label(s.id_nomenclature_naturalness) AS naturalness,
ref_nomenclatures.get_nomenclature_label(s.id_nomenclature_exist_proof) AS exist_proof ,
ref_nomenclatures.get_nomenclature_label(s.id_nomenclature_valid_status) AS valid_status,
ref_nomenclatures.get_nomenclature_label(s.id_nomenclature_diffusion_level) AS diffusion_level,
ref_nomenclatures.get_nomenclature_label(s.id_nomenclature_life_stage) AS life_stage,
ref_nomenclatures.get_nomenclature_label(s.id_nomenclature_sex) AS sex,
ref_nomenclatures.get_nomenclature_label(s.id_nomenclature_obj_count) AS obj_count,
ref_nomenclatures.get_nomenclature_label(s.id_nomenclature_type_count) AS type_count,
ref_nomenclatures.get_nomenclature_label(s.id_nomenclature_sensitivity) AS sensitivity,
ref_nomenclatures.get_nomenclature_label(s.id_nomenclature_observation_status) AS observation_status,
ref_nomenclatures.get_nomenclature_label(s.id_nomenclature_blurring) AS blurring,
ref_nomenclatures.get_nomenclature_label(s.id_nomenclature_source_status) AS source_status,
ref_nomenclatures.get_nomenclature_label(s.id_nomenclature_info_geo_type) AS info_geo_type,
ref_nomenclatures.get_nomenclature_label(s.id_nomenclature_determination_method) AS determination_method,
ref_nomenclatures.get_nomenclature_label(s.id_nomenclature_behaviour) AS occ_behaviour,
ref_nomenclatures.get_nomenclature_label(s.id_nomenclature_biogeo_status) AS occ_stat_biogeo
FROM gn_synthese.synthese s;

-- Refonte de la vue listant les observations pour l'export de la Synthèse
DROP VIEW gn_synthese.v_synthese_for_export;
CREATE OR REPLACE VIEW gn_synthese.v_synthese_for_export AS
 SELECT 
    s.date_min::date AS date_debut,
    s.date_max::date AS date_fin,
    s.date_min::time AS heure_debut,
    s.date_max::time AS heure_fin,
    t.cd_nom AS cd_nom,
    t.cd_ref AS cd_ref,
    t.nom_valide AS nom_valide,
    t.nom_vern as nom_vernaculaire,
    s.nom_cite AS nom_cite,
    t.regne AS regne,
    t.group1_inpn AS group1_inpn,
    t.group2_inpn AS group2_inpn,
    t.classe AS classe,
    t.ordre AS ordre,
    t.famille AS famille,
    t.id_rang AS rang_taxo,
    s.count_min AS nombre_min,
    s.count_max AS nombre_max,
    s.altitude_min AS alti_min,
    s.altitude_max AS alti_max,
    s.depth_min AS prof_min,
    s.depth_max AS prof_max,
    s.observers AS observateurs,
    s.id_digitiser AS id_digitiser, -- Utile pour le CRUVED
    s.determiner AS determinateur,
    communes AS communes,
    public.ST_astext(s.the_geom_4326) AS geometrie_wkt_4326,
    public.ST_x(s.the_geom_point) AS x_centroid_4326,
    public.ST_y(s.the_geom_point) AS y_centroid_4326,
    public.ST_asgeojson(s.the_geom_4326) AS geojson_4326,-- Utile pour la génération de l'export en SHP
    public.ST_asgeojson(s.the_geom_local) AS geojson_local,-- Utile pour la génération de l'export en SHP
    s.place_name AS nom_lieu,
    s.comment_context AS comment_releve,
    s.comment_description AS comment_occurrence,
    s.validator AS validateur,
    n21.label_default AS niveau_validation,
    s.meta_validation_date as date_validation,
    s.validation_comment AS comment_validation,
    s.digital_proof AS preuve_numerique_url,
    s.non_digital_proof AS preuve_non_numerique,
    d.dataset_name AS jdd_nom,
    d.unique_dataset_id AS jdd_uuid,
    d.id_dataset AS jdd_id, -- Utile pour le CRUVED
    af.acquisition_framework_name AS ca_nom,
    af.unique_acquisition_framework_id AS ca_uuid,
    d.id_acquisition_framework AS ca_id,
    s.cd_hab AS cd_habref,
    hab.lb_code AS cd_habitat,
    hab.lb_hab_fr AS nom_habitat,
    s.precision as precision_geographique,
    n1.label_default AS nature_objet_geo,
    n2.label_default AS type_regroupement,
    s.grp_method AS methode_regroupement,
    n3.label_default AS technique_observation,
    n5.label_default AS biologique_statut,
    n6.label_default AS etat_biologique,
    n22.label_default AS biogeographique_statut,
    n7.label_default AS naturalite,
    n8.label_default AS preuve_existante,
    n9.label_default AS niveau_precision_diffusion,
    n10.label_default AS stade_vie,
    n11.label_default AS sexe,
    n12.label_default AS objet_denombrement,
    n13.label_default AS type_denombrement,
    n14.label_default AS niveau_sensibilite,
    n15.label_default AS statut_observation,
    n16.label_default AS floutage_dee,
    n17.label_default AS statut_source,
    n18.label_default AS type_info_geo,
    n19.label_default AS methode_determination,
    n20.label_default AS comportement,
    s.reference_biblio AS reference_biblio,
    s.id_synthese AS id_synthese,
    s.entity_source_pk_value AS id_origine,
    s.unique_id_sinp AS uuid_perm_sinp,
    s.unique_id_sinp_grp AS uuid_perm_grp_sinp,
    s.meta_create_date AS date_creation,
    s.meta_update_date AS date_modification,
    COALESCE(s.meta_update_date, s.meta_create_date) AS derniere_action
   FROM gn_synthese.synthese s
     JOIN taxonomie.taxref t ON t.cd_nom = s.cd_nom
     JOIN gn_meta.t_datasets d ON d.id_dataset = s.id_dataset
     JOIN gn_meta.t_acquisition_frameworks af ON d.id_acquisition_framework = af.id_acquisition_framework
     LEFT OUTER JOIN (
        SELECT id_synthese, string_agg(DISTINCT area_name, ', ') AS communes
        FROM gn_synthese.cor_area_synthese cas
        LEFT OUTER JOIN ref_geo.l_areas a_1 ON cas.id_area = a_1.id_area
        JOIN ref_geo.bib_areas_types ta ON ta.id_type = a_1.id_type AND ta.type_code ='COM'
        GROUP BY id_synthese 
     ) sa ON sa.id_synthese = s.id_synthese
     LEFT JOIN ref_nomenclatures.t_nomenclatures n1 ON s.id_nomenclature_geo_object_nature = n1.id_nomenclature
     LEFT JOIN ref_nomenclatures.t_nomenclatures n2 ON s.id_nomenclature_grp_typ = n2.id_nomenclature
     LEFT JOIN ref_nomenclatures.t_nomenclatures n3 ON s.id_nomenclature_obs_technique = n3.id_nomenclature
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
     LEFT JOIN ref_nomenclatures.t_nomenclatures n20 ON s.id_nomenclature_behaviour = n20.id_nomenclature
     LEFT JOIN ref_nomenclatures.t_nomenclatures n21 ON s.id_nomenclature_valid_status = n21.id_nomenclature
     LEFT JOIN ref_nomenclatures.t_nomenclatures n22 ON s.id_nomenclature_biogeo_status = n22.id_nomenclature
     LEFT JOIN ref_habitats.habref hab ON hab.cd_hab = s.cd_hab;

-- Amélioration vue d'export des métadonnées
DROP VIEW gn_synthese.v_metadata_for_export;
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
     JOIN gn_meta.cor_dataset_actor act ON act.id_dataset = d.id_dataset
     JOIN ref_nomenclatures.t_nomenclatures nomencl ON nomencl.id_nomenclature = act.id_nomenclature_actor_role
     LEFT JOIN utilisateurs.bib_organismes orga ON orga.id_organisme = act.id_organism
     LEFT JOIN utilisateurs.t_roles roles ON roles.id_role = act.id_role
     JOIN count_nb_obs ON count_nb_obs.id_dataset = d.id_dataset
  GROUP BY d.id_dataset, d.unique_dataset_id, d.dataset_name, af.acquisition_framework_name, af.unique_acquisition_framework_id, count_nb_obs.nb_obs;

-- Correction du trigger de mise à jour de Occtax vers Synthèse (#1117)
CREATE OR REPLACE FUNCTION pr_occtax.fct_tri_synthese_update_releve()
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
      grp_method = NEW.grp_method,
      id_nomenclature_grp_typ = NEW.id_nomenclature_grp_typ,
      date_min = date_trunc('day',NEW.date_min)+COALESCE(NEW.hour_min,'00:00:00'::time),
      date_max = date_trunc('day',NEW.date_max)+COALESCE(NEW.hour_max,'00:00:00'::time), 
      altitude_min = NEW.altitude_min,
      altitude_max = NEW.altitude_max,
      depth_min = NEW.depth_min,
      depth_max = NEW.depth_max,
      place_name = NEW.place_name,
      precision = NEW.precision,
      the_geom_local = NEW.geom_local,
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

-- Mise à jour du champs the_geom_local de la Synthèse pour les observations venant d'Occtax 
-- Par sécurité si ils ont été modifiés (#1117)
UPDATE gn_synthese.synthese 
SET the_geom_local = ST_transform(the_geom_4326, gn_commons.get_default_parameter('local_srid')::integer)
WHERE id_source = (SELECT id_source FROM gn_synthese.t_sources WHERE name_source ilike 'Occtax');
