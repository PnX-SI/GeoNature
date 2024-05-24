SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET search_path = gn_imports, pg_catalog, public;
SET default_with_oids = false;


--------------
--INSERTIONS--
--------------

-- Créer les mappings par défaut
INSERT INTO gn_imports.t_mappings (mapping_label, mapping_type, active, is_public)
VALUES
('Format DEE (champs 10 char)', 'FIELD', true, true),
('Synthese GeoNature', 'FIELD', true, true),
('Nomenclatures SINP (labels)', 'CONTENT', true, true),
('Nomenclatures SINP (codes)', 'CONTENT', true, true);



-- Renseigner les correspondances de champs du mapping 'Format DEE'
INSERT INTO gn_imports.t_mappings_fields (id_mapping, source_field, target_field, is_selected, is_added)
VALUES 
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Format DEE (champs 10 char)'), 'permid','unique_id_sinp',true,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Format DEE (champs 10 char)'), 'idorigine','entity_source_pk_value',true,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Format DEE (champs 10 char)'), 'permidgrp','unique_id_sinp_grp',true,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Format DEE (champs 10 char)'), 'true','unique_id_sinp_generate',true,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Format DEE (champs 10 char)'), '','meta_create_date',false,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Format DEE (champs 10 char)'), 'vtaxref','meta_v_taxref',true,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Format DEE (champs 10 char)'), '','meta_update_date',false,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Format DEE (champs 10 char)'), 'datedebut','date_min',true,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Format DEE (champs 10 char)'), 'datefin','date_max',true,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Format DEE (champs 10 char)'), 'heuredebut','hour_min',true,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Format DEE (champs 10 char)'), 'heurefin','hour_max',true,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Format DEE (champs 10 char)'), 'altmin','altitude_min',true,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Format DEE (champs 10 char)'), 'altmax','altitude_max',true,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Format DEE (champs 10 char)'), 'profmin','depth_min',true,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Format DEE (champs 10 char)'), 'profmax','depth_max',true,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Format DEE (champs 10 char)'), '','altitudes_generate',false,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Format DEE (champs 10 char)'), 'x_centroid','longitude',false,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Format DEE (champs 10 char)'), 'y_centroid','latitude',false,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Format DEE (champs 10 char)'), 'observer','observers',true,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Format DEE (champs 10 char)'), 'obsdescr','comment_description',true,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Format DEE (champs 10 char)'), 'typinfgeo','id_nomenclature_info_geo_type',true,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Format DEE (champs 10 char)'), 'typgrp','id_nomenclature_grp_typ',true,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Format DEE (champs 10 char)'), 'methgrp','grp_method',true,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Format DEE (champs 10 char)'), 'nomcite','nom_cite',true,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Format DEE (champs 10 char)'), 'cdnom','cd_nom',true,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Format DEE (champs 10 char)'), 'obstech','id_nomenclature_obs_technique',true,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Format DEE (champs 10 char)'), 'ocstatbio','id_nomenclature_bio_status',true,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Format DEE (champs 10 char)'), 'ocetatbio','id_nomenclature_bio_condition',true,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Format DEE (champs 10 char)'), 'ocbiogeo','id_nomenclature_biogeo_status',true,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Format DEE (champs 10 char)'), 'occcomport','id_nomenclature_behaviour',true,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Format DEE (champs 10 char)'), 'ocnat','id_nomenclature_naturalness',true,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Format DEE (champs 10 char)'), 'obsctx','comment_context',true,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Format DEE (champs 10 char)'), 'sensiniv','id_nomenclature_sensitivity',true,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Format DEE (champs 10 char)'), 'difnivprec','id_nomenclature_diffusion_level',true,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Format DEE (champs 10 char)'), 'deeflou','id_nomenclature_blurring',true,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Format DEE (champs 10 char)'), 'ocstade','id_nomenclature_life_stage',true,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Format DEE (champs 10 char)'), 'ocsex','id_nomenclature_sex',true,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Format DEE (champs 10 char)'), 'denbrtyp','id_nomenclature_type_count',true,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Format DEE (champs 10 char)'), 'objdenbr','id_nomenclature_obj_count',true,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Format DEE (champs 10 char)'), 'denbrmin','count_min',true,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Format DEE (champs 10 char)'), 'denbrmax','count_max',true,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Format DEE (champs 10 char)'), 'ocmethdet','id_nomenclature_determination_method',true,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Format DEE (champs 10 char)'), 'detminer','determiner',true,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Format DEE (champs 10 char)'), 'id_digitiser','id_digitiser',false,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Format DEE (champs 10 char)'), 'preuveoui','id_nomenclature_exist_proof',true,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Format DEE (champs 10 char)'), 'urlpreuv','digital_proof',true,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Format DEE (champs 10 char)'), 'preuvnonum','non_digital_proof',true,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Format DEE (champs 10 char)'), 'nivval','id_nomenclature_valid_status',true,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Format DEE (champs 10 char)'), 'validateur','validator',true,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Format DEE (champs 10 char)'), 'datectrl','meta_validation_date',true,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Format DEE (champs 10 char)'), 'validcom','validation_comment',true,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Format DEE (champs 10 char)'), 'natobjgeo','id_nomenclature_geo_object_nature',true,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Format DEE (champs 10 char)'), 'obstech','id_nomenclature_obs_technique',true,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Format DEE (champs 10 char)'), 'statobs','id_nomenclature_observation_status',true,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Format DEE (champs 10 char)'), 'statsource','id_nomenclature_source_status',true,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Format DEE (champs 10 char)'), 'refbiblio','reference_biblio',true,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Format DEE (champs 10 char)'), 'cdhab','cd_hab',true,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Format DEE (champs 10 char)'), 'geometrie','WKT',true,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Format DEE (champs 10 char)'), 'nomlieu','place_name',true,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Format DEE (champs 10 char)'), 'precisgeo','precision',true,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Format DEE (champs 10 char)'), 'gn_1_the_geom_point_2','the_geom_point',false,true),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Format DEE (champs 10 char)'), 'gn_1_the_geom_local_2','the_geom_local',false,true),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Format DEE (champs 10 char)'), 'gn_1_the_geom_4326_2','the_geom_4326',false,true),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Format DEE (champs 10 char)'), 'cdcommune','codecommune',true,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Format DEE (champs 10 char)'), 'cdmaille10','codemaille',true,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Format DEE (champs 10 char)'), 'cddept','codedepartement',true,false),

-- Renseigner les correspondances de champs du mapping 'Synthese GeoNature'
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Synthese GeoNature'), 'uuid_perm_sinp','unique_id_sinp',true,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Synthese GeoNature'), 'id_synthese','entity_source_pk_value',true,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Synthese GeoNature'), 'uuid_perm_grp_sinp','unique_id_sinp_grp',true,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Synthese GeoNature'), '','unique_id_sinp_generate',false,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Synthese GeoNature'), 'date_creation','meta_create_date',false,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Synthese GeoNature'), '','meta_v_taxref',true,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Synthese GeoNature'), 'date_modification','meta_update_date',false,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Synthese GeoNature'), 'date_debut','date_min',true,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Synthese GeoNature'), 'date_fin','date_max',true,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Synthese GeoNature'), 'heure_debut','hour_min',true,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Synthese GeoNature'), 'heure_fin','hour_max',true,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Synthese GeoNature'), 'alti_min','altitude_min',true,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Synthese GeoNature'), 'alti_max','altitude_max',true,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Synthese GeoNature'), 'prof_min','depth_min',true,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Synthese GeoNature'), 'prof_max','depth_max',true,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Synthese GeoNature'), '','altitudes_generate',false,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Synthese GeoNature'), '','longitude',false,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Synthese GeoNature'), '','latitude',false,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Synthese GeoNature'), 'observateurs','observers',true,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Synthese GeoNature'), 'comment_occurrence','comment_description',true,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Synthese GeoNature'), 'type_info_geo','id_nomenclature_info_geo_type',true,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Synthese GeoNature'), 'type_regroupement','id_nomenclature_grp_typ',true,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Synthese GeoNature'), 'methode_regroupement','grp_method',true,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Synthese GeoNature'), 'nom_cite','nom_cite',true,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Synthese GeoNature'), 'cd_nom','cd_nom',true,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Synthese GeoNature'), 'technique_observation','id_nomenclature_obs_technique',true,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Synthese GeoNature'), 'biologique_statut','id_nomenclature_bio_status',true,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Synthese GeoNature'), 'etat_biologique','id_nomenclature_bio_condition',true,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Synthese GeoNature'), 'biogeographique_statut','id_nomenclature_biogeo_status',true,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Synthese GeoNature'), 'comportement','id_nomenclature_behaviour',true,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Synthese GeoNature'), 'naturalite','id_nomenclature_naturalness',true,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Synthese GeoNature'), 'comment_releve','comment_context',true,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Synthese GeoNature'), 'niveau_sensibilite','id_nomenclature_sensitivity',true,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Synthese GeoNature'), 'niveau_precision_diffusion','id_nomenclature_diffusion_level',true,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Synthese GeoNature'), 'floutage_dee','id_nomenclature_blurring',true,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Synthese GeoNature'), 'stade_vie','id_nomenclature_life_stage',true,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Synthese GeoNature'), 'sexe','id_nomenclature_sex',true,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Synthese GeoNature'), 'type_denombrement','id_nomenclature_type_count',true,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Synthese GeoNature'), 'objet_denombrement','id_nomenclature_obj_count',true,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Synthese GeoNature'), 'nombre_min','count_min',true,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Synthese GeoNature'), 'nombre_max','count_max',true,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Synthese GeoNature'), 'methode_determination','id_nomenclature_determination_method',true,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Synthese GeoNature'), 'determinateur','determiner',true,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Synthese GeoNature'), '','id_digitiser',false,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Synthese GeoNature'), 'preuve_existante','id_nomenclature_exist_proof',true,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Synthese GeoNature'), 'preuve_numerique_url','digital_proof',true,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Synthese GeoNature'), 'preuve_non_numerique','non_digital_proof',true,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Synthese GeoNature'), 'niveau_validation','id_nomenclature_valid_status',true,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Synthese GeoNature'), 'validateur','validator',true,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Synthese GeoNature'), 'date_validation','meta_validation_date',true,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Synthese GeoNature'), 'comment_validation','validation_comment',true,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Synthese GeoNature'), 'nature_objet_geo','id_nomenclature_geo_object_nature',true,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Synthese GeoNature'), 'statut_observation','id_nomenclature_observation_status',true,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Synthese GeoNature'), 'statut_source','id_nomenclature_source_status',true,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Synthese GeoNature'), 'reference_biblio','reference_biblio',true,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Synthese GeoNature'), 'cd_habref','cd_hab',true,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Synthese GeoNature'), 'geometrie_wkt_4326','WKT',true,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Synthese GeoNature'), 'nom_lieu','place_name',true,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Synthese GeoNature'), 'precision_geographique','precision',true,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Synthese GeoNature'), '','the_geom_point',false,true),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Synthese GeoNature'), '','the_geom_local',false,true),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Synthese GeoNature'), '','the_geom_4326',false,true),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Synthese GeoNature'), '','codecommune',true,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Synthese GeoNature'), '','codemaille',true,false),
((SELECT id_mapping FROM gn_imports.t_mappings WHERE mapping_label='Synthese GeoNature'), '','codedepartement',true,false)
;

-- Intégration du mapping de valeurs SINP (labels) par défaut pour les nomenclatures de la synthèse 
INSERT INTO gn_imports.t_mappings_values (id_mapping, source_value, id_target_value)
SELECT
m.id_mapping, 
n.label_default,
n.id_nomenclature
FROM gn_imports.t_mappings m, ref_nomenclatures.t_nomenclatures n
JOIN ref_nomenclatures.bib_nomenclatures_types bnt ON bnt.id_type=n.id_type 
WHERE m.mapping_label='Nomenclatures SINP (labels)' AND bnt.mnemonique IN (SELECT DISTINCT(mnemonique) FROM gn_imports.cor_synthese_nomenclature);

-- Intégration du mapping de valeurs SINP (codes) par défaut pour les nomenclatures de la synthèse
INSERT INTO gn_imports.t_mappings_values (id_mapping, source_value, id_target_value)
SELECT
m.id_mapping,
n.cd_nomenclature,
n.id_nomenclature
FROM gn_imports.t_mappings m, ref_nomenclatures.t_nomenclatures n
JOIN ref_nomenclatures.bib_nomenclatures_types bnt ON bnt.id_type=n.id_type 
WHERE m.mapping_label='Nomenclatures SINP (codes)' AND bnt.mnemonique IN (SELECT DISTINCT(mnemonique) FROM gn_imports.cor_synthese_nomenclature);
