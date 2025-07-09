
CREATE VIEW gn_profiles.v_consistancy_data AS
 SELECT s.id_synthese,
    s.unique_id_sinp AS id_sinp,
    t.cd_ref,
    t.lb_nom AS valid_name,
    gn_profiles.check_profile_distribution(s.the_geom_local, p.valid_distribution) AS valid_distribution,
    gn_profiles.check_profile_phenology(t.cd_ref, (s.date_min)::date, (s.date_max)::date, s.altitude_min, s.altitude_max, s.id_nomenclature_life_stage, p.active_life_stage) AS valid_phenology,
    gn_profiles.check_profile_altitudes(s.altitude_min, s.altitude_max, p.altitude_min, p.altitude_max) AS valid_altitude,
    n.label_default AS valid_status
   FROM (((gn_synthese.synthese s
     JOIN taxonomie.taxref t ON ((s.cd_nom = t.cd_nom)))
     JOIN gn_profiles.vm_valid_profiles p ON ((p.cd_ref = t.cd_ref)))
     LEFT JOIN ref_nomenclatures.t_nomenclatures n ON ((s.id_nomenclature_valid_status = n.id_nomenclature)));

