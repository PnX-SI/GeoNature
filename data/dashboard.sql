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

CREATE MATERIALIZED VIEW gn_dashboard.vm_synthese_communes_complete AS 
 SELECT a.area_name,
    st_asgeojson(st_transform(a.geom, 4326)) AS geom_area_4326,
    date_part('year'::text, s.date_min) AS year,
    t.regne,
    t.phylum,
    t.group1_inpn,
    t.classe,
    t.group2_inpn,
    t.ordre,
    t.famille,
    t.cd_ref,
    count(*) AS nb_obs,
    count(DISTINCT t.cd_ref) AS nb_taxons
   FROM gn_synthese.synthese s
     JOIN ref_geo.l_areas a ON st_intersects(s.the_geom_local, a.geom)
     JOIN taxonomie.taxref t ON s.cd_nom = t.cd_nom
  WHERE a.id_type = 25
  GROUP BY GROUPING SETS ((a.area_name, a.geom, (date_part('year'::text, s.date_min)), t.regne, t.phylum, t.group1_inpn, t.classe, t.group2_inpn, t.ordre, t.famille, t.cd_ref), (a.area_name, a.geom))
  ORDER BY a.area_name, (date_part('year'::text, s.date_min)), t.regne, t.phylum, t.group1_inpn, t.classe, t.group2_inpn, t.ordre, t.famille, t.cd_ref
WITH DATA;

CREATE MATERIALIZED VIEW gn_dashboard.vm_taxonomie AS 
 SELECT 'Règne'::text AS level,
    COALESCE(vm_synthese.regne, 'Not defined'::character varying) AS name_taxon
   FROM gn_dashboard.vm_synthese
  GROUP BY vm_synthese.regne
UNION ALL
 SELECT 'Phylum'::text AS level,
    COALESCE(vm_synthese.phylum, 'Not defined'::character varying) AS name_taxon
   FROM gn_dashboard.vm_synthese
  GROUP BY vm_synthese.phylum
UNION ALL
 SELECT 'Classe'::text AS level,
    COALESCE(vm_synthese.classe, 'Not defined'::character varying) AS name_taxon
   FROM gn_dashboard.vm_synthese
  GROUP BY vm_synthese.classe
UNION ALL
 SELECT 'Ordre'::text AS level,
    COALESCE(vm_synthese.ordre, 'Not defined'::character varying) AS name_taxon
   FROM gn_dashboard.vm_synthese
  GROUP BY vm_synthese.ordre
UNION ALL
 SELECT 'Famille'::text AS level,
    COALESCE(vm_synthese.famille, 'Not defined'::character varying) AS name_taxon
   FROM gn_dashboard.vm_synthese
  GROUP BY vm_synthese.famille
UNION ALL
 SELECT 'Groupe INPN 1'::text AS level,
    COALESCE(vm_synthese.group1_inpn, 'Not defined'::character varying) AS name_taxon
   FROM gn_dashboard.vm_synthese
  GROUP BY vm_synthese.group1_inpn
UNION ALL
 SELECT 'Groupe INPN 2'::text AS level,
    COALESCE(vm_synthese.group2_inpn, 'Not defined'::character varying) AS name_taxon
   FROM gn_dashboard.vm_synthese
  GROUP BY vm_synthese.group2_inpn
WITH DATA;