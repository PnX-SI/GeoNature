
CREATE VIEW gn_profiles.v_synthese_for_profiles AS
 WITH excluded_live_stage AS (
         SELECT ref_nomenclatures.get_id_nomenclature('STADE_VIE'::character varying, '0'::character varying) AS id_n_excluded
        UNION
         SELECT ref_nomenclatures.get_id_nomenclature('STADE_VIE'::character varying, '1'::character varying) AS id_n_excluded
        )
 SELECT s.id_synthese,
    s.cd_nom,
    s.nom_cite,
    t.cd_ref,
    t.nom_valide,
    t.id_rang,
    s.date_min,
    s.date_max,
    s.the_geom_local,
    s.the_geom_4326,
    s.altitude_min,
    s.altitude_max,
        CASE
            WHEN (s.id_nomenclature_life_stage IN ( SELECT excluded_live_stage.id_n_excluded
               FROM excluded_live_stage)) THEN NULL::integer
            ELSE s.id_nomenclature_life_stage
        END AS id_nomenclature_life_stage,
    s.id_nomenclature_valid_status,
    p.spatial_precision,
    p.temporal_precision_days,
    p.active_life_stage,
    p.distance
   FROM ((gn_synthese.synthese s
     LEFT JOIN taxonomie.taxref t ON ((s.cd_nom = t.cd_nom)))
     CROSS JOIN LATERAL gn_profiles.get_parameters(s.cd_nom) p(cd_ref, spatial_precision, temporal_precision_days, active_life_stage, distance))
  WHERE ((p.spatial_precision IS NOT NULL) AND (public.st_maxdistance(public.st_centroid(s.the_geom_local), s.the_geom_local) < (p.spatial_precision)::double precision) AND (s.altitude_max IS NOT NULL) AND (s.altitude_min IS NOT NULL) AND (s.id_nomenclature_valid_status IN ( SELECT (regexp_split_to_table(t_parameters.value, ','::text))::integer AS regexp_split_to_table
           FROM gn_profiles.t_parameters
          WHERE ((t_parameters.name)::text = 'id_valid_status_for_profiles'::text))) AND ((t.id_rang)::text IN ( SELECT regexp_split_to_table(t_parameters.value, ','::text) AS regexp_split_to_table
           FROM gn_profiles.t_parameters
          WHERE ((t_parameters.name)::text = 'id_rang_for_profiles'::text))));

COMMENT ON VIEW gn_profiles.v_synthese_for_profiles IS 'View containing synthese data feeding profiles calculation.
 cd_ref, date_min, date_max, the_geom_local, altitude_min, altitude_max and
 id_nomenclature_life_stage fields are mandatory.
 WHERE clauses have to apply your t_parameters filters (valid_status)';

