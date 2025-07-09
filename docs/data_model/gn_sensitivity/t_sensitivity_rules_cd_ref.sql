
CREATE MATERIALIZED VIEW gn_sensitivity.t_sensitivity_rules_cd_ref AS
 WITH RECURSIVE r(cd_ref) AS (
         SELECT t.cd_ref,
            r_1.id_sensitivity,
            r_1.cd_nom,
            r_1.nom_cite,
            r_1.id_nomenclature_sensitivity,
            r_1.sensitivity_duration,
            r_1.sensitivity_territory,
            r_1.id_territory,
            COALESCE(r_1.date_min, '1900-01-01'::date) AS date_min,
            COALESCE(r_1.date_max, '1900-12-31'::date) AS date_max,
            r_1.active,
            r_1.comments,
            r_1.meta_create_date,
            r_1.meta_update_date
           FROM (gn_sensitivity.t_sensitivity_rules r_1
             JOIN taxonomie.taxref t ON ((t.cd_nom = r_1.cd_nom)))
          WHERE (r_1.active = true)
        UNION ALL
         SELECT t.cd_ref,
            r_1.id_sensitivity,
            t.cd_nom,
            r_1.nom_cite,
            r_1.id_nomenclature_sensitivity,
            r_1.sensitivity_duration,
            r_1.sensitivity_territory,
            r_1.id_territory,
            r_1.date_min,
            r_1.date_max,
            r_1.active,
            r_1.comments,
            r_1.meta_create_date,
            r_1.meta_update_date
           FROM taxonomie.taxref t,
            r r_1
          WHERE (t.cd_taxsup = r_1.cd_ref)
        )
 SELECT r.cd_ref,
    r.id_sensitivity,
    r.cd_nom,
    r.nom_cite,
    r.id_nomenclature_sensitivity,
    r.sensitivity_duration,
    r.sensitivity_territory,
    r.id_territory,
    r.date_min,
    r.date_max,
    r.active,
    r.comments,
    r.meta_create_date,
    r.meta_update_date
   FROM r
  WITH NO DATA;

