DROP MATERIALIZED VIEW IF exists ginco_migration.vm_data_model_source_ratt CASCADE;
CREATE MATERIALIZED VIEW ginco_migration.vm_data_model_source_ratt AS
SELECT nextval('vm_data_model_source'::regclass) AS id,
    m.anneerefcommune,
    m.typeinfogeomaille,
    convert_to_integer(m.cdnom) AS cdnom,
    m.jourdatedebut,
    m.statutobservation,
    m.occnaturalite,
    m.typeinfogeocommune,
    m.cdref,
    m.heuredatefin,
    m.dspublique,
    m.codemaille,
    m.validateurnomorganisme,
    m.identifiantpermanent::uuid AS identifiantpermanent,
    m.versionrefmaille,
    m.observateurnomorganisme,
    m.versiontaxref,
    m.referencebiblio,
    m.typeinfogeodepartement,
    m.diffusionniveauprecision,
    m.codecommune,
    m.denombrementmax::integer,
    m.codedepartement,
    m.anneerefdepartement,
    m.observateuridentite,
    m.deefloutage,
    m.natureobjetgeo,
    m.codeme,
    m.orgtransformation,
    m.versionme,
    m.occetatbiologique,
    m.occstatutbiologique,
    m.identifiantorigine,
    m.dateme,
    m.heuredatedebut,
    m.denombrementmin::integer,
    m.versionen,
    m.nomrefmaille,
    m.statutsource,
    m.occsexe,
    m.nomcommune,
    m.typeinfogeome,
    m.codeen,
    m.organismegestionnairedonnee,
    m.objetdenombrement,
    m.commentaire,
    m.obsmethode,
    m.typeen,
    m.nomcite,
    m.typeinfogeoen,
    m.jourdatefin,
    m.occstadedevie,
    m.jddmetadonneedeeid,
    m.sensimanuelle,
    m.codecommunecalcule,
    m.submission_id,
    m.sensiversionreferentiel,
    m.sensiniveau,
    m.codedepartementcalcule,
    m.deedatedernieremodification,
    m.sensialerte,
    m.sensidateattribution,
    m.nomcommunecalcule,
    m.nomvalide,
    m.sensireferentiel,
    m.sensible,
    m.codemaillecalcule,
    m.provider_id,
    m.geometrie,
    m.cdnomcalcule,
    m.cdrefcalcule,
    m.taxostatut,
    m.taxomodif,
    m.taxoalerte,
    m.user_login
   FROM ginco_migration.model_1_observation m
   -- on ne prend que les JDD non supprimé car la table gn_meta.t_datasets ne comprend que les JDD non supprimé
   join gn_meta.t_datasets d on d.unique_dataset_id = m.jddmetadonneedeeid::uuid
    where m.geometrie is null

;

INSERT INTO gn_synthese.synthese (
unique_id_sinp,
id_source,
entity_source_pk_value,
id_dataset,
id_nomenclature_geo_object_nature,
id_nomenclature_obs_technique,
id_nomenclature_bio_status,
id_nomenclature_bio_condition,
id_nomenclature_naturalness,
id_nomenclature_diffusion_level,
id_nomenclature_life_stage,
id_nomenclature_sex,
id_nomenclature_obj_count,
id_nomenclature_observation_status,
id_nomenclature_blurring,
id_nomenclature_source_status,
id_nomenclature_info_geo_type,
count_min,
count_max,
cd_nom,
nom_cite,
meta_v_taxref,
id_area_attachment,
the_geom_4326,
the_geom_point,
the_geom_local,
date_min,
date_max,
observers,
id_digitiser,
comment_context,
last_action
)
SELECT
  m.identifiantpermanent::uuid,
  (SELECT id_source FROM gn_synthese.t_sources WHERE name_source = 'Ginco'),
  m.identifiantpermanent,
  (SELECT id_dataset FROM gn_meta.t_datasets ds where ds.unique_dataset_id = COALESCE(m.jddmetadonneedeeid::uuid, NULL) LIMIT 1),
  t1.id_nomenclature,
  t2.id_nomenclature,
  t3.id_nomenclature,
  t4.id_nomenclature,
  t5.id_nomenclature,
  t6.id_nomenclature,
  t7.id_nomenclature,
  t8.id_nomenclature,
  t9.id_nomenclature,
  t10.id_nomenclature,
  t11.id_nomenclature,
  t12.id_nomenclature,
  ref_nomenclatures.get_id_nomenclature('TYP_INF_GEO', '2'),
  m.denombrementmin,
  m.denombrementmax,
  tax.cd_nom,
  m.nomcite,
  substring(m.versiontaxref from 1 for 50),
  areas.id_area as id_area_attachment,
  public.st_transform(areas.geom, 4326),
  public.st_centroid(public.st_transform(areas.geom, 4326)),
  areas.geom,
  concat((to_char(m.jourdatedebut, 'DD/MM/YYYY'), ' ', COALESCE(to_char(m.heuredatedebut, 'HH24:MI:SS'),'00:00:00')))::timestamp,
  concat((to_char(m.jourdatefin, 'DD/MM/YYYY'), ' ', COALESCE(to_char(m.heuredatedebut, 'HH24:MI:SS'),'00:00:00')))::timestamp,
  m.observateuridentite,
  (select id_role from utilisateurs.t_roles tr where tr.nom_role = m.user_login LIMIT 1),
  m.commentaire,
  'I'
FROM ginco_migration.vm_data_model_source_ratt as m
left JOIN ref_nomenclatures.t_nomenclatures t1 ON t1.cd_nomenclature = m.natureobjetgeo AND t1.id_type = ref_nomenclatures.get_id_nomenclature_type('NAT_OBJ_GEO')
left JOIN ref_nomenclatures.t_nomenclatures t2 ON t2.cd_nomenclature = m.obsmethode AND t2.id_type = ref_nomenclatures.get_id_nomenclature_type('METH_OBS')
left JOIN ref_nomenclatures.t_nomenclatures t3 ON t3.cd_nomenclature = m.occstatutbiologique AND t3.id_type = ref_nomenclatures.get_id_nomenclature_type('STATUT_BIO')
left JOIN ref_nomenclatures.t_nomenclatures t4 ON t4.cd_nomenclature = m.occetatbiologique AND t4.id_type = ref_nomenclatures.get_id_nomenclature_type('ETA_BIO')
left JOIN ref_nomenclatures.t_nomenclatures t5 ON t5.cd_nomenclature = m.occnaturalite AND t5.id_type = ref_nomenclatures.get_id_nomenclature_type('NATURALITE')
left JOIN ref_nomenclatures.t_nomenclatures t6 ON t6.cd_nomenclature = m.diffusionniveauprecision AND t6.id_type = ref_nomenclatures.get_id_nomenclature_type('NIV_PRECIS')
left JOIN ref_nomenclatures.t_nomenclatures t7 ON t7.cd_nomenclature = m.occstadedevie AND t7.id_type = ref_nomenclatures.get_id_nomenclature_type('STADE_VIE')
left JOIN ref_nomenclatures.t_nomenclatures t8 ON t8.cd_nomenclature = m.occsexe AND t8.id_type = ref_nomenclatures.get_id_nomenclature_type('SEXE')
left JOIN ref_nomenclatures.t_nomenclatures t9 ON t9.cd_nomenclature = m.objetdenombrement AND t9.id_type = ref_nomenclatures.get_id_nomenclature_type('OBJ_DENBR')
left JOIN ref_nomenclatures.t_nomenclatures t10 ON t10.cd_nomenclature = m.statutobservation AND t10.id_type = ref_nomenclatures.get_id_nomenclature_type('STATUT_OBS')
left JOIN ref_nomenclatures.t_nomenclatures t11 ON t11.cd_nomenclature = m.deefloutage AND t11.id_type = ref_nomenclatures.get_id_nomenclature_type('DEE_FLOU')
left JOIN ref_nomenclatures.t_nomenclatures t12 ON t12.cd_nomenclature = m.statutsource AND t12.id_type = ref_nomenclatures.get_id_nomenclature_type('STATUT_SOURCE') 
left JOIN ref_nomenclatures.t_nomenclatures t13 ON t13.cd_nomenclature = m.typeinfogeoen AND t13.id_type = ref_nomenclatures.get_id_nomenclature_type('TYP_INF_GEO') 
JOIN taxonomie.taxref tax ON tax.cd_nom = m.cdnom::integer
JOIN ref_geo.l_areas areas ON areas.area_code = CASE WHEN (codecommune[1]  is not null and codecommune[2]  is  null) THEN codecommune[1]
                                       WHEN (codemaille[1]  is not null and codemaille[2]  is  null) THEN codemaille[1]
                                       WHEN (codedepartement[1]  is not null and codedepartement[2]  is  null) THEN codedepartement[1]
END
WHERE ((codecommune[1]  is not null and codecommune[2]  is null)
OR ((codemaille[1]  is not null and codemaille[2]  is null) and (codecommune[1]  is null or codecommune is null))
OR ((codemaille[1]  is null or codemaille is null) and (codecommune[1]  is null or codecommune is null) and (codedepartement[1]  is not null and codedepartement[2]  is null)))
;

