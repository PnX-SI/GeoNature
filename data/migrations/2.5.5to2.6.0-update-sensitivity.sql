-- Complément de la migration SQL entre les versions 2.5.5 et 2.6.0
-- Mise à jour du niveau de sensibilité de toutes les observations de la Synthèse, en fonction des règles de sensibilité activées
-- Voir https://github.com/PnX-SI/GeoNature/issues/284
-- Par défaut, seulement les règles nationales sont activées (voir table gn_sensitivity.t_sensitivity_rules)
-- Après le calcul du niveau de sensibilité de chaque observation de la synthèse, leur niveau de diffusion est automatiquement calculé en fonction de leur niveau de sensibilité
-- Seulement les observations dont le niveau de diffusion est nul voient leur niveau de sensibilité calculé automatiquement, pour ne pas écraser des niveaux de diffusion qui auraient été renseignés manuellement

-- Désactiver trigger de mise à jour de la date de la synthèse, car sinon cela laisse penser que la donnée a été modifiée
ALTER TABLE gn_synthese.synthese DISABLE TRIGGER tri_meta_dates_change_synthese;

-- Calculer automatiquement le niveau de sensibilité des observations de la synthèse
-- Attention cela va calculer automatiquement la sensibilité et le niveau de diffusion de TOUTES les données présentes dans la synthèse, à partir des règles de sensibilité nationales du SINP
-- Cela écrasera les valeurs de ces champs si certaines avaient été renseignées manuellement
UPDATE gn_synthese.synthese  SET id_nomenclature_sensitivity =  gn_sensitivity.get_id_nomenclature_sensitivity(
    date_min::date,
    taxonomie.find_cdref(cd_nom),
    the_geom_local,
    ('{"STATUT_BIO": ' || id_nomenclature_bio_status::text || '}')::jsonb
);

-- Réactiver le trigger de mise à jour des dates des observations de la synthèse
ALTER TABLE gn_synthese.synthese ENABLE TRIGGER tri_meta_dates_change_synthese;
