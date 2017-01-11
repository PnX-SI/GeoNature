SET search_path = public, pg_catalog;

CREATE OR REPLACE VIEW v_mobile_recherche AS 
( SELECT ap.indexap AS gid,
    zp.dateobs,
    t.latin AS taxon,
    o.observateurs,
    public.st_asgeojson(public.st_transform(ap.the_geom_2154, 4326)) AS geom_4326,
    public.st_x(public.st_transform(public.st_centroid(ap.the_geom_2154), 4326)) AS centroid_x,
    public.st_y(public.st_transform(public.st_centroid(ap.the_geom_2154), 4326)) AS centroid_y
   FROM florepatri.t_apresence ap
     JOIN florepatri.t_zprospection zp ON ap.indexzp = zp.indexzp
     JOIN florepatri.bib_taxons_fp t ON t.cd_nom = zp.cd_nom
     JOIN ( SELECT c.indexzp,
            array_to_string(array_agg((r.prenom_role::text || ' '::text) || r.nom_role::text), ', '::text) AS observateurs
           FROM florepatri.cor_zp_obs c
             JOIN utilisateurs.t_roles r ON r.id_role = c.codeobs
          GROUP BY c.indexzp) o ON o.indexzp = ap.indexzp
  WHERE ap.supprime = false AND st_isvalid(ap.the_geom_2154) AND ap.topo_valid = true
  ORDER BY zp.dateobs DESC)
UNION
( SELECT cft.id_station AS gid,
    s.dateobs,
    t.latin AS taxon,
    o.observateurs,
    public.st_asgeojson(public.st_transform(s.the_geom_3857, 4326)) AS geom_4326,
    public.st_x(public.st_transform(public.st_centroid(s.the_geom_3857), 4326)) AS centroid_x,
    public.st_y(public.st_transform(public.st_centroid(s.the_geom_3857), 4326)) AS centroid_y
   FROM florestation.cor_fs_taxon cft
     JOIN florestation.t_stations_fs s ON s.id_station = cft.id_station
     JOIN florepatri.bib_taxons_fp t ON t.cd_nom = cft.cd_nom
     JOIN ( SELECT c.id_station,
            array_to_string(array_agg((r.prenom_role::text || ' '::text) || r.nom_role::text), ', '::text) AS observateurs
           FROM florestation.cor_fs_observateur c
             JOIN utilisateurs.t_roles r ON r.id_role = c.id_role
          GROUP BY c.id_station) o ON o.id_station = cft.id_station
  WHERE cft.supprime = false AND st_isvalid(s.the_geom_3857)
  ORDER BY s.dateobs DESC);