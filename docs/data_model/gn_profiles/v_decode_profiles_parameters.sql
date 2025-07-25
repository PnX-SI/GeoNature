
CREATE VIEW gn_profiles.v_decode_profiles_parameters AS
 SELECT t.cd_ref,
    t.lb_nom,
    t.id_rang,
    p.spatial_precision,
    p.temporal_precision_days,
    p.active_life_stage
   FROM (gn_profiles.cor_taxons_parameters p
     LEFT JOIN taxonomie.taxref t ON ((p.cd_nom = t.cd_nom)));

