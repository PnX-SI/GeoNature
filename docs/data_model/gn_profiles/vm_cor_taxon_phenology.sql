

CREATE MATERIALIZED VIEW gn_profiles.vm_cor_taxon_phenology AS
 WITH exlude_live_stage AS (
         SELECT ref_nomenclatures.get_id_nomenclature('STADE_VIE'::character varying, '0'::character varying) AS id_n_excluded
        UNION
         SELECT ref_nomenclatures.get_id_nomenclature('STADE_VIE'::character varying, '1'::character varying) AS id_n_excluded
        ), params AS (
         SELECT ((parameters.value)::double precision / (100)::double precision) AS proportion_kept_data
           FROM gn_profiles.t_parameters parameters
          WHERE ((parameters.name)::text = 'proportion_kept_data'::text)
        ), classified_data AS (
         SELECT DISTINCT vsfp.cd_ref,
            unnest(ARRAY[(floor((date_part('doy'::text, vsfp.date_min) / (vsfp.temporal_precision_days)::double precision)) * (vsfp.temporal_precision_days)::double precision), (floor((date_part('doy'::text, vsfp.date_max) / (vsfp.temporal_precision_days)::double precision)) * (vsfp.temporal_precision_days)::double precision)]) AS doy_min,
            unnest(ARRAY[((floor((date_part('doy'::text, vsfp.date_min) / (vsfp.temporal_precision_days)::double precision)) * (vsfp.temporal_precision_days)::double precision) + (vsfp.temporal_precision_days)::double precision), ((floor((date_part('doy'::text, vsfp.date_max) / (vsfp.temporal_precision_days)::double precision)) * (vsfp.temporal_precision_days)::double precision) + (vsfp.temporal_precision_days)::double precision)]) AS doy_max,
                CASE
                    WHEN ((vsfp.active_life_stage = true) AND (NOT (vsfp.id_nomenclature_life_stage IN ( SELECT exlude_live_stage.id_n_excluded
                       FROM exlude_live_stage)))) THEN vsfp.id_nomenclature_life_stage
                    ELSE NULL::integer
                END AS id_nomenclature_life_stage,
            count(vsfp.*) AS count_valid_data,
            min(vsfp.altitude_min) AS extreme_altitude_min,
            percentile_disc(( SELECT params.proportion_kept_data
                   FROM params)) WITHIN GROUP (ORDER BY vsfp.altitude_min DESC) AS p_min,
            max(vsfp.altitude_max) AS extreme_altitude_max,
            percentile_disc(( SELECT params.proportion_kept_data
                   FROM params)) WITHIN GROUP (ORDER BY vsfp.altitude_max) AS p_max
           FROM gn_profiles.v_synthese_for_profiles vsfp
          WHERE ((vsfp.temporal_precision_days IS NOT NULL) AND (vsfp.spatial_precision IS NOT NULL) AND (vsfp.active_life_stage IS NOT NULL) AND (date_part('day'::text, (vsfp.date_max - vsfp.date_min)) < (vsfp.temporal_precision_days)::double precision) AND (vsfp.altitude_min IS NOT NULL) AND (vsfp.altitude_max IS NOT NULL))
          GROUP BY vsfp.cd_ref, (unnest(ARRAY[(floor((date_part('doy'::text, vsfp.date_min) / (vsfp.temporal_precision_days)::double precision)) * (vsfp.temporal_precision_days)::double precision), (floor((date_part('doy'::text, vsfp.date_max) / (vsfp.temporal_precision_days)::double precision)) * (vsfp.temporal_precision_days)::double precision)])), (unnest(ARRAY[((floor((date_part('doy'::text, vsfp.date_min) / (vsfp.temporal_precision_days)::double precision)) * (vsfp.temporal_precision_days)::double precision) + (vsfp.temporal_precision_days)::double precision), ((floor((date_part('doy'::text, vsfp.date_max) / (vsfp.temporal_precision_days)::double precision)) * (vsfp.temporal_precision_days)::double precision) + (vsfp.temporal_precision_days)::double precision)])),
                CASE
                    WHEN ((vsfp.active_life_stage = true) AND (NOT (vsfp.id_nomenclature_life_stage IN ( SELECT exlude_live_stage.id_n_excluded
                       FROM exlude_live_stage)))) THEN vsfp.id_nomenclature_life_stage
                    ELSE NULL::integer
                END
        )
 SELECT classified_data.cd_ref,
    classified_data.doy_min,
    classified_data.doy_max,
    classified_data.id_nomenclature_life_stage,
    classified_data.count_valid_data,
    classified_data.extreme_altitude_min,
    classified_data.p_min AS calculated_altitude_min,
    classified_data.extreme_altitude_max,
    classified_data.p_max AS calculated_altitude_max
   FROM classified_data
  WITH NO DATA;

COMMENT ON MATERIALIZED VIEW gn_profiles.vm_cor_taxon_phenology IS 'View containing phenological combinations and corresponding valid data for each taxa';

CREATE INDEX index_vm_cor_taxon_phenology_cd_ref ON gn_profiles.vm_cor_taxon_phenology USING btree (cd_ref);

CREATE UNIQUE INDEX vm_cor_taxon_phenology_cd_ref_period_id_nomenclature_life_s_idx ON gn_profiles.vm_cor_taxon_phenology USING btree (cd_ref, doy_min, doy_max, id_nomenclature_life_stage);


