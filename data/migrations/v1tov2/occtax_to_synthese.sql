
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
comment_context,
comment_description,
last_action
)
SELECT
  c.unique_id_sinp_occtax,
  r.unique_id_sinp_grp,
  (SELECT id_source FROM gn_synthese.t_sources WHERE name_source = 'Occtax'),
  c.id_counting_occtax,
  r.id_dataset,
  (SELECT id_module FROM gn_commons.t_modules WHERE module_code = 'OCCTAX'),
  pr_occtax.get_default_nomenclature_value('NAT_OBJ_GEO'),
  r.id_nomenclature_grp_typ,
  o.id_nomenclature_obs_meth,
  r.id_nomenclature_obs_technique,
  o.id_nomenclature_bio_status,
  o.id_nomenclature_bio_condition,
  o.id_nomenclature_naturalness,
  o.id_nomenclature_exist_proof,
  o.id_nomenclature_diffusion_level,
  c.id_nomenclature_life_stage,
  c.id_nomenclature_sex,
  c.id_nomenclature_obj_count,
  c.id_nomenclature_type_count,
  o.id_nomenclature_observation_status,
  o.id_nomenclature_blurring,
  id_nomenclature_source_status,
  ref_nomenclatures.get_id_nomenclature('TYP_INF_GEO', '1')	,
  c.count_min,
  c.count_max,
  o.cd_nom,
  o.nom_cite,
  o.meta_v_taxref,
  o.sample_number_proof,
  o.digital_proof,
  o.non_digital_proof,
  r.altitude_min,
  r.altitude_max,
  r.geom_4326,
  public.st_centroid(r.geom_4326),
  r.geom_local,
  concat((to_char(r.date_min, 'DD/MM/YYYY'), ' ', COALESCE(to_char(r.hour_min, 'HH24:MI:SS'),'00:00:00')))::timestamp,
  concat((to_char(r.date_max, 'DD/MM/YYYY'), ' ', COALESCE(to_char(r.hour_max, 'HH24:MI:SS'),'00:00:00')))::timestamp,
  r.observers_txt,
  o.determiner,
  r.id_digitiser,
  o.id_nomenclature_determination_method,
  r.comment,
  o.comment,
  'I'
FROM pr_occtax.t_releves_occtax r
JOIN pr_occtax.t_occurrences_occtax o ON o.id_releve_occtax = r.id_releve_occtax
JOIN pr_occtax.cor_counting_occtax c ON c.id_occurrence_occtax = o.id_occurrence_occtax;

--correspondance observateurs en synthese, jouer l'action à la place du tri_insert_synthese_cor_role_releves_occtax
INSERT INTO gn_synthese.cor_observer_synthese(id_synthese, id_role) 
SELECT s.id_synthese, cro.id_role 
FROM gn_synthese.synthese s
JOIN pr_occtax.cor_counting_occtax cco ON cco.id_counting_occtax::varchar = s.entity_source_pk_value
JOIN pr_occtax.t_occurrences_occtax oo ON oo.id_occurrence_occtax = cco.id_occurrence_occtax
JOIN pr_occtax.t_releves_occtax r ON r.id_releve_occtax = oo.id_releve_occtax
JOIN pr_occtax.cor_role_releves_occtax cro ON cro.id_releve_occtax = r.id_releve_occtax
WHERE s.id_dataset IN(4,14,15,112);
--observers_as_txt en synthese jouer l'action du trigger trg_maj_synthese_observers_txt
WITH synthese_observers AS (
  SELECT c.id_synthese, array_to_string(array_agg(concat(r.nom_role, ' ', r.prenom_role)), ', ') AS theobservers
  FROM utilisateurs.t_roles r
  JOIN gn_synthese.cor_observer_synthese c ON c.id_role = r.id_role
  GROUP BY id_synthese
)
UPDATE gn_synthese.synthese
SET observers = so.theobservers
FROM synthese_observers so
WHERE gn_synthese.synthese.id_synthese = so.id_synthese;


--réactiver les triggers 
ALTER TABLE pr_occtax.t_releves_occtax ENABLE TRIGGER USER;
ALTER TABLE pr_occtax.t_occurrences_occtax ENABLE TRIGGER tri_log_changes_t_occurrences_occtax;
ALTER TABLE pr_occtax.cor_counting_occtax ENABLE TRIGGER tri_log_changes_cor_counting_occtax;
ALTER TABLE pr_occtax.cor_counting_occtax ENABLE TRIGGER tri_insert_synthese_cor_counting_occtax;
ALTER TABLE pr_occtax.cor_counting_occtax ENABLE TRIGGER tri_insert_default_validation_status;
ALTER TABLE pr_occtax.cor_role_releves_occtax ENABLE TRIGGER tri_log_changes_cor_role_releves_occtax;
ALTER TABLE pr_occtax.cor_role_releves_occtax ENABLE TRIGGER tri_insert_synthese_cor_role_releves_occtax;
