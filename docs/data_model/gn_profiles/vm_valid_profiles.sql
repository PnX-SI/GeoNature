

CREATE MATERIALIZED VIEW gn_profiles.vm_valid_profiles AS
 SELECT DISTINCT vsfp.cd_ref,
    public.st_union(public.st_buffer(vsfp.the_geom_local, (COALESCE(vsfp.spatial_precision, 1))::double precision)) AS valid_distribution,
    min(vsfp.altitude_min) AS altitude_min,
    max(vsfp.altitude_max) AS altitude_max,
    min(vsfp.date_min) AS first_valid_data,
    max(vsfp.date_max) AS last_valid_data,
    count(vsfp.*) AS count_valid_data,
    vsfp.active_life_stage
   FROM gn_profiles.v_synthese_for_profiles vsfp
  GROUP BY vsfp.cd_ref, vsfp.active_life_stage
  WITH NO DATA;

CREATE UNIQUE INDEX index_vm_valid_profiles_cd_ref ON gn_profiles.vm_valid_profiles USING btree (cd_ref);


