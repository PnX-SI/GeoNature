-------------------
--SCHEMA SYNTHESE--
-------------------
-- Creation d'une vue materialisée avec seulement les données avec geom 
-- et qui n'appartiennent pas à un JDD suppriméé
CREATE OR REPLACE FUNCTION convert_to_integer(v_input text)
RETURNS INTEGER AS $$
DECLARE v_int_value INTEGER DEFAULT NULL;
BEGIN
    BEGIN
        v_int_value := v_input::INTEGER;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'Invalid integer value: "%".  Returning NULL.', v_input;
        RETURN NULL;
    END;
RETURN v_int_value;
END;
$$ LANGUAGE plpgsql;


DROP MATERIALIZED VIEW IF exists ginco_migration.vm_data_model_source CASCADE;
DROP SEQUENCE IF EXISTS vm_data_model_source;
CREATE SEQUENCE vm_data_model_source CYCLE;
CREATE MATERIALIZED VIEW ginco_migration.vm_data_model_source AS 
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
   FROM ginco_migration.model_592e825dab701_observation m
   -- on ne prend que les JDD non supprimé car la table gn_meta.t_datasets ne comprend que les JDD non supprimé
   join gn_meta.t_datasets d on d.unique_dataset_id = m.jddmetadonneedeeid::uuid
    where m.geometrie is not null
    and 
    m.jddmetadonneedeeid not IN ( 
      select f.value_string
      from ginco_migration.jdd j
      join ginco_migration.jdd_field f on f.jdd_id = j.id
      where j.status = 'deleted' 
      and f."key" = 'metadataId'
     )
   ;


-- Insertion des données
DELETE FROM gn_synthese.synthese;
DELETE FROM gn_synthese.t_sources 
WHERE name_source = 'Ginco';

-- creation d'une source
INSERT INTO gn_synthese.t_sources
(
  name_source, 
  desc_source, 
  entity_source_pk_field
  )
VALUES(
  'Ginco', 
  'Données source Ginco', 
  concat('ginco_migration.', :GINCO_TABLE_QUOTED)
);


UPDATE gn_synthese.defaults_nomenclatures_value 
SET id_nomenclature = ref_nomenclatures.get_id_nomenclature('STATUT_VALID', '6')
WHERE mnemonique_type = 'STATUT_VALID';


-- suppresion des contraintes, on tentera de les remettre plus tard...
ALTER TABLE gn_synthese.synthese DROP CONSTRAINT check_synthese_date_max;
ALTER TABLE gn_synthese.synthese DROP CONSTRAINT check_synthese_count_max;

INSERT INTO gn_synthese.synthese (
unique_id_sinp,
id_source,
entity_source_pk_value,
id_dataset,
id_nomenclature_geo_object_nature,
id_nomenclature_obs_meth,
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
  (SELECT id_dataset FROM gn_meta.t_datasets ds where ds.unique_dataset_id = COALESCE(m.jddmetadonneedeeid::uuid, NULL)),
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
  t13.id_nomenclature,
  m.denombrementmin,
  m.denombrementmax,
  tax.cd_nom,
  m.nomcite,
  substring(m.versiontaxref from 1 for 50),
  m.geometrie,
  public.st_centroid(m.geometrie),
  public.st_transform(m.geometrie, 2154),
  concat((to_char(m.jourdatedebut, 'DD/MM/YYYY'), ' ', COALESCE(to_char(m.heuredatedebut, 'HH24:MI:SS'),'00:00:00')))::timestamp,
  concat((to_char(m.jourdatefin, 'DD/MM/YYYY'), ' ', COALESCE(to_char(m.heuredatedebut, 'HH24:MI:SS'),'00:00:00')))::timestamp,
  m.observateuridentite,
  (select id_role from utilisateurs.t_roles tr where tr.nom_role = m.user_login LIMIT 1),
  m.commentaire,
  'I'
FROM ginco_migration.vm_data_model_source as m 
left JOIN ref_nomenclatures.t_nomenclatures t1 ON t1.cd_nomenclature = m.natureobjetgeo AND t1.id_type = 3
left JOIN ref_nomenclatures.t_nomenclatures t2 ON t2.cd_nomenclature = m.obsmethode AND t2.id_type = 14
left JOIN ref_nomenclatures.t_nomenclatures t3 ON t3.cd_nomenclature = m.occstatutbiologique AND t3.id_type = 13
left JOIN ref_nomenclatures.t_nomenclatures t4 ON t4.cd_nomenclature = m.occetatbiologique AND t4.id_type = 7
left JOIN ref_nomenclatures.t_nomenclatures t5 ON t5.cd_nomenclature = m.occnaturalite AND t5.id_type = 8
left JOIN ref_nomenclatures.t_nomenclatures t6 ON t6.cd_nomenclature = m.diffusionniveauprecision AND t6.id_type = 5
left JOIN ref_nomenclatures.t_nomenclatures t7 ON t7.cd_nomenclature = m.occstadedevie AND t7.id_type = 10
left JOIN ref_nomenclatures.t_nomenclatures t8 ON t8.cd_nomenclature = m.occsexe AND t8.id_type = 9
left JOIN ref_nomenclatures.t_nomenclatures t9 ON t9.cd_nomenclature = m.objetdenombrement AND t9.id_type = 6
left JOIN ref_nomenclatures.t_nomenclatures t10 ON t10.cd_nomenclature = m.statutobservation AND t10.id_type = 18
left JOIN ref_nomenclatures.t_nomenclatures t11 ON t11.cd_nomenclature = m.deefloutage AND t11.id_type = 4
left JOIN ref_nomenclatures.t_nomenclatures t12 ON t12.cd_nomenclature = m.statutobservation AND t12.id_type = 19
left JOIN ref_nomenclatures.t_nomenclatures t13 ON t13.cd_nomenclature = m.typeinfogeoen AND t13.id_type = 23
JOIN taxonomie.taxref tax ON tax.cd_nom = m.cdnom::integer
WHERE m.identifiantpermanent NOT IN (
  select identifiantpermanent
from ginco_migration.vm_data_model_source
group by identifiantpermanent
having count(*) > 1)
;
