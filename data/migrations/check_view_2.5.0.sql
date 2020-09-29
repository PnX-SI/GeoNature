 DO $$
   BEGIN
    IF (
        SELECT count(*)
        FROM information_schema.view_column_usage
        WHERE table_name = 'synthese' AND table_schema = 'gn_synthese' AND column_name = 'id_nomenclature_obs_technique'
        AND NOT view_schema || '.' || view_name IN (
            'gn_synthese.v_synthese_for_export',
            'pr_occtax.v_releve_occtax',
            'gn_synthese.v_synthese_decode_nomenclatures',
            'gn_synthese.v_synthese_for_web_app',
            'gn_commons.v_synthese_validation_forwebapp'
          )
        ) > 0
    THEN
        RAISE EXCEPTION 'Des vues doivent être supprimées puis recréées avant de relancer le script car elles dépendent de la colonne id_nomenclature_obs_technique';
    ELSE
        RAISE NOTICE 'Aucune vue ne dépende du champs id_nomenclature_obs_technique. Vous pouvez lancer le script de migration 2.4.1to2.5.0/sql';

        END IF;
   END
 $$ language plpgsql;
