-- Complément de la migration SQL entre les versions 2.5.5 et 2.6.0
-- Mise à jour du niveau de sensibilité de toutes les observations de la Synthèse, en fonction des règles de sensibilité activées
-- Voir https://github.com/PnX-SI/GeoNature/issues/284
-- Par défaut, seulement les règles nationales sont activées (voir table gn_sensitivity.t_sensitivity_rules)
-- Après le calcul du niveau de sensibilité de chaque observation de la synthèse, leur niveau de diffusion est automatiquement calculé en fonction de leur niveau de sensibilité
-- Seulement les observations dont le niveau de diffusion est nul voient leur niveau de sensibilité calculé automatiquement, pour ne pas écraser des niveaux de diffusion qui auraient été renseignés manuellement
-- Voir https://github.com/PnX-SI/GeoNature/issues/413

-- Désactiver trigger de mise à jour de la date de la synthèse, car sinon cela laisse penser que la donnée a été modifiée
ALTER TABLE gn_synthese.synthese DISABLE TRIGGER tri_meta_dates_change_synthese;

-- Calculer automatiquement le niveau de sensibilité des observations de la synthèse
-- Attention cela va calculer automatiquement la sensibilité à partir des règles de sensibilité nationales du SINP
-- UNIQUEMENT POUR LES DONNÉES N'AYANT PAS DE SENSIBILITÉ DEJA DÉFINIE (c-a-d id_nomenclature_sensitivity IS NULL)

UPDATE gn_synthese.synthese  SET id_nomenclature_sensitivity =  gn_sensitivity.get_id_nomenclature_sensitivity(
    date_min::date,
    taxonomie.find_cdref(cd_nom),
    the_geom_local,
    ('{"STATUT_BIO": ' || id_nomenclature_bio_status::text || '}')::jsonb
) WHERE NOT id_nomenclature_sensitivity IS NULL;

-- Calculer automatiquement le niveau de diffusion des observations de la synthèse
-- Attention cela va calculer automatiquement le niveau de diffusion à partir de la sensibilté
-- UNIQUEMENT POUR LES DONNÉES N'AYANT PAS DE NIVEAU DE DIFFUSION DEJA DÉFINI (c-a-d id_diffusion_level IS NULL)

WITH cor_diff_sens AS (
	SELECT DISTINCT ref_nomenclatures.get_id_nomenclature(
        'NIV_PRECIS',
        gn_sensitivity.calculate_cd_diffusion_level(
          NULL,
          t.cd_nomenclature
        )
     ) AS id_diff, t.id_nomenclature AS id_sens
     FROM ref_nomenclatures.t_nomenclatures t
     JOIN ref_nomenclatures.bib_nomenclatures_types b
     ON t.id_type = b.id_type AND b.mnemonique = 'SENSIBILITE'
)
UPDATE gn_synthese.synthese s
    SET id_nomenclature_diffusion_level = id_diff
FROM cor_diff_sens c
WHERE c.id_sens = s.id_nomenclature_sensitivity
	AND s.id_nomenclature_diffusion_level IS NULL;

-- Réactiver le trigger de mise à jour des dates des observations de la synthèse
ALTER TABLE gn_synthese.synthese ENABLE TRIGGER tri_meta_dates_change_synthese;
