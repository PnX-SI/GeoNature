-- Complément de la migration SQL entre les versions 2.5.5 et 2.6.0
-- Mise à jour du niveau de sensibilité de toutes les observations de la Synthèse, en fonction des règles de sensibilité activées
-- Voir https://github.com/PnX-SI/GeoNature/issues/284
-- Par défaut, seulement les règles nationales sont activées (voir table gn_sensitivity.t_sensitivity_rules)
-- Après le calcul du niveau de sensibilité de chaque observation de la synthèse, leur niveau de diffusion est automatiquement calculé en fonction de leur niveau de sensibilité
-- Seulement les observations dont le niveau de diffusion est nul voient leur niveau de sensibilité calculé automatiquement, pour ne pas écraser des niveaux de diffusion qui auraient été renseignés manuellement

-- Désactiver trigger de mise à jour de la date de la synthèse, car sinon cela laisse penser que la donnée a été modifiée
ALTER TABLE gn_synthese.synthese DISABLE TRIGGER tri_meta_dates_change_synthese;

-- Calculer automatiquement le niveau de sensibilité des observations de la synthèse
-- !!!!!! Attention on ne le calcule ici que si le niveau de sensibilité est nul. Or je pense qu'il est renseigné 
-- !!!!!! Je pense qu'il faudrait le faire pour toutes les données de la synthèse. C'est le niveau de diffusion qui peut être manuel, pas le niveau de sensibilité
-- !!!!!! Mais si il est fourni par le partenaire, on l'écrase ????
UPDATE gn_synthese.synthese  SET id_nomenclature_sensitivity =  gn_sensitivity.get_id_nomenclature_sensitivity(
    date_min::date,
    taxonomie.find_cdref(cd_nom),
    the_geom_local,
    ('{"STATUT_BIO": ' || id_nomenclature_bio_status::text || '}')::jsonb
)
WHERE id_nomenclature_sensitivity IS NULL;

-- Calculer les niveaux de diffusion en fonction de la sensibilité des observations de la synthèse, seulement si ils n'ont pas été renseignés par ailleurs
-- Attention, passer des ID aux CD, voir https://github.com/PnX-SI/GeoNature/blob/develop/data/migrations/2.5.5to2.6.0.sql#L47
UPDATE gn_synthese.synthese SET id_nomenclature_diffusion_level = 140 WHERE id_nomenclature_sensitivity = 67 AND id_nomenclature_diffusion_level IS NULL;
UPDATE gn_synthese.synthese SET id_nomenclature_diffusion_level = 141 WHERE id_nomenclature_sensitivity = 68 AND id_nomenclature_diffusion_level IS NULL;
UPDATE gn_synthese.synthese SET id_nomenclature_diffusion_level = 142 WHERE id_nomenclature_sensitivity = 69 AND id_nomenclature_diffusion_level IS NULL;
UPDATE gn_synthese.synthese SET id_nomenclature_diffusion_level = 143 WHERE id_nomenclature_sensitivity = 70 AND id_nomenclature_diffusion_level IS NULL;
UPDATE gn_synthese.synthese SET id_nomenclature_diffusion_level = 144 WHERE id_nomenclature_sensitivity = 71 AND id_nomenclature_diffusion_level IS NULL;

-- Réactiver le trigger de mise à jour des dates des observations de la synthèse
ALTER TABLE gn_synthese.synthese ENABLE TRIGGER tri_meta_dates_change_synthese;
