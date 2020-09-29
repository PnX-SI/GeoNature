-- Lister les vues de la BDD à modifier car ils utilisent le champs "id_nomenclature_obs_technique" 
-- qui sera renommé dans la version 2.5.0
SELECT view_schema, view_name 
FROM information_schema.view_column_usage
WHERE table_name = 'synthese' AND table_schema = 'gn_synthese' AND column_name = 'id_nomenclature_obs_technique'
AND NOT view_schema || '.' || view_name IN (
  'gn_synthese.v_synthese_for_export',
  'pr_occtax.v_releve_occtax',
  'gn_synthese.v_synthese_decode_nomenclatures',
  'gn_synthese.v_synthese_for_web_app',
  'gn_commons.v_synthese_validation_forwebapp'
)
