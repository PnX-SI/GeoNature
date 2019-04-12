CREATE SCHEMA gn_dashboard;

CREATE MATERIALIZED VIEW gn_dashboard.vm_synthese AS 
 SELECT s.id_synthese,
    s.id_source,
    s.id_dataset,
    s.id_nomenclature_obj_count,
    s.count_min,
    s.count_max,
    s.cd_nom,
    t.cd_ref,
    s.nom_cite,
    t.id_statut,
    t.id_rang,
    t.regne,
    t.phylum,
    t.classe,
    t.ordre,
    t.famille,
    t.sous_famille,
    t.lb_nom,
    t.nom_vern,
    t.url,
    s.altitude_min,
    s.altitude_max,
    st_x(s.the_geom_4326) AS lon,
    st_y(s.the_geom_4326) AS lat,
    s.date_min,
    s.date_max
   FROM gn_synthese.synthese s
     JOIN taxonomie.taxref t ON s.cd_nom = t.cd_nom
WITH DATA;


CREATE MATERIALIZED VIEW gn_dashboard.vm_synthese_communes AS 
 SELECT row_number() OVER (ORDER BY a.area_name)::integer AS fid,
    a.area_name,
    st_asgeojson(st_transform(a.geom, 4326)) AS geom_area_4326,
    a.id_type,
    date_part('year'::text, s.date_min) AS year,
    count(*) AS nb_obs,
    count(DISTINCT t.cd_ref) AS nb_taxons
   FROM gn_synthese.synthese s
     JOIN ref_geo.l_areas a ON st_intersects(s.the_geom_local, a.geom)
     JOIN taxonomie.taxref t ON s.cd_nom = t.cd_nom
  GROUP BY a.area_name, (date_part('year'::text, s.date_min)), a.geom, a.id_type
WITH DATA;