DROP SCHEMA if exists gn_dashboard cascade;

CREATE SCHEMA gn_dashboard;

-- Vue matérialisée remettant à plat la taxonomie de toutes les observations présentes dans la synthèse
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
    t.group1_inpn,
    t.group2_inpn,
    t.lb_nom,
    t.nom_vern,
    t.url,
    s.altitude_min,
    s.altitude_max,
    s.date_min,
    s.date_max
   FROM gn_synthese.synthese s
     JOIN taxonomie.taxref t ON s.cd_nom = t.cd_nom
WITH DATA;
COMMENT ON MATERIALIZED VIEW gn_dashboard.vm_synthese
    IS 'Vue matérialisée remettant à plat la taxonomie de toutes les observations présentes dans la synthèse';

CREATE unique index on gn_dashboard.vm_synthese (id_synthese);
CREATE index on gn_dashboard.vm_synthese (cd_ref);


-- Vue matérialisée calculant le nombre d'observations par cadre d'acquisition par année
CREATE MATERIALIZED VIEW gn_dashboard.vm_synthese_frameworks AS 
 SELECT DISTINCT af.acquisition_framework_name,
    date_part('year'::text, s.date_min) AS year,
    count(*) AS nb_obs
   FROM gn_synthese.synthese s
     JOIN gn_meta.t_datasets d ON d.id_dataset = s.id_dataset
     JOIN gn_meta.t_acquisition_frameworks af ON af.id_acquisition_framework = d.id_acquisition_framework
  GROUP BY af.acquisition_framework_name, (date_part('year'::text, s.date_min))
  ORDER BY af.acquisition_framework_name, (date_part('year'::text, s.date_min))
WITH DATA;
COMMENT ON MATERIALIZED VIEW gn_dashboard.vm_synthese_frameworks
    IS 'Vue matérialisée calculant le nombre d''observations par cadre d''acquisition par année';

CREATE unique index on gn_dashboard.vm_synthese_frameworks (acquisition_framework_name,year);


-- Vue matérialisée listant tous les taxons pour lesquels des données ont été observées, ainsi que leur rang taxonomique
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
COMMENT ON MATERIALIZED VIEW gn_dashboard.vm_synthese
    IS 'Vue matérialisée listant tous les taxons pour lesquels des données ont été observées, ainsi que leur rang taxonomique';

CREATE unique index on gn_dashboard.vm_taxonomie (name_taxon,level);


-- Fonction rafraichissant en parallèle toutes les vues matérialisées utilisées par le module Dashboard
-- USAGE : SELECT gn_dashboard.refresh_materialized_view_data()
CREATE OR REPLACE FUNCTION gn_dashboard.refresh_materialized_view_data()
RETURNS VOID AS $$
BEGIN
  REFRESH MATERIALIZED VIEW CONCURRENTLY gn_dashboard.vm_synthese;
  REFRESH MATERIALIZED VIEW CONCURRENTLY gn_dashboard.vm_synthese_frameworks;
  REFRESH MATERIALIZED VIEW CONCURRENTLY gn_dashboard.vm_taxonomie;
END
$$ LANGUAGE plpgsql;
