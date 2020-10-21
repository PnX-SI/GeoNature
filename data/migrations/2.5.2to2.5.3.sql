DROP VIEW gn_synthese.v_synthese_for_export;

CREATE OR REPLACE VIEW gn_synthese.v_synthese_for_export AS
 SELECT s.id_synthese AS "idSynthese",
    s.entity_source_pk_value AS "idOrigine",
    s.unique_id_sinp AS "permId",
    s.unique_id_sinp_grp AS "permIdGrp",
    s.grp_method,
    s.count_min AS "denbrMin",
    s.count_max AS "denbrMax",
    s.sample_number_proof AS "sampleNumb",
    s.digital_proof AS "uRLPreuv",
    s.non_digital_proof AS "preuvNoNum",
    s.altitude_min AS "altMin",
    s.altitude_max AS "altMax",
    s.depth_min AS "profMin",
    s.depth_max AS "profMax",
    s.precision,
    public.ST_astext(s.the_geom_4326) AS "geometrie",
    to_char(s.date_min, 'YYYY-MM-DD') AS "dateDebut",
    to_char(s.date_max, 'YYYY-MM-DD') AS "dateFin",
    s.date_min::time AS "heureFin",
    s.date_max::time AS "heureDebut",
    s.validator AS validateur,
    n21.label_default AS "nivVal",
    s.meta_validation_date as "dateCtrl",
    s.observers AS observer,
    s.id_digitiser AS id_digitiser,
    s.determiner AS detminer,
    s.comment_context AS "obsCtx",
    s.comment_description AS "obsDescr",
    s.meta_create_date,
    s.meta_update_date,
    d.dataset_name AS "jddName", -- champs non standard (pas le nom du JDD dans le standard)
    d.unique_dataset_id AS "idSINPJdd",
    d.id_acquisition_framework,
    t.cd_nom AS "cdNom",
    t.cd_ref AS "cdRef",
    s.cd_hab AS "codeHabRef",
    t.nom_valide AS "nomValide",
    s.nom_cite AS "nomCite",
    hab.lb_code AS "codeHab",
    hab.lb_hab_fr AS "nomHab",
    s.cd_hab AS "cdHab",
    public.ST_x(public.ST_transform(s.the_geom_point, 2154)) AS x_centroid,
    public.ST_y(public.ST_transform(s.the_geom_point, 2154)) AS y_centroid,
    COALESCE(s.meta_update_date, s.meta_create_date) AS lastact,
    public.ST_asgeojson(s.the_geom_4326) AS geojson_4326,
    public.ST_asgeojson(s.the_geom_local) AS geojson_local,
    s.place_name AS "nomLieu",
    n1.label_default AS "natObjGeo",
    n2.label_default AS "typGrp",
    s.grp_method AS "methGrp",
    n3.label_default AS "obsTech",
    n5.label_default AS "ocStatBio",
    n6.label_default AS "ocEtatBio",
    n7.label_default AS "ocNat",
    n8.label_default AS "preuveOui",
    n9.label_default AS "difNivPrec",
    n10.label_default AS "ocStade",
    n11.label_default AS "ocSex",
    n12.label_default AS "objDenbr",
    n13.label_default AS "denbrTyp",
    n14.label_default AS"sensiNiv",
    n15.label_default AS "statObs",
    n16.label_default AS "dEEFlou",
    n17.label_default AS "statSource",
    n18.label_default AS "typInfGeo",
    n19.label_default AS "ocMethDet",
    n20.label_default AS "occComport",
    s.reference_biblio AS "refBiblio"
   FROM gn_synthese.synthese s
     JOIN taxonomie.taxref t ON t.cd_nom = s.cd_nom
     JOIN gn_meta.t_datasets d ON d.id_dataset = s.id_dataset
     JOIN gn_synthese.t_sources sources ON sources.id_source = s.id_source
     LEFT JOIN ref_nomenclatures.t_nomenclatures n1 ON s.id_nomenclature_geo_object_nature = n1.id_nomenclature
     LEFT JOIN ref_nomenclatures.t_nomenclatures n2 ON s.id_nomenclature_grp_typ = n2.id_nomenclature
     LEFT JOIN ref_nomenclatures.t_nomenclatures n3 ON s.id_nomenclature_obs_technique = n3.id_nomenclature
     LEFT JOIN ref_nomenclatures.t_nomenclatures n5 ON s.id_nomenclature_bio_status = n5.id_nomenclature
     LEFT JOIN ref_nomenclatures.t_nomenclatures n6 ON s.id_nomenclature_bio_condition = n6.id_nomenclature
     LEFT JOIN ref_nomenclatures.t_nomenclatures n7 ON s.id_nomenclature_naturalness = n7.id_nomenclature
     LEFT JOIN ref_nomenclatures.t_nomenclatures n8 ON s.id_nomenclature_exist_proof = n8.id_nomenclature
     LEFT JOIN ref_nomenclatures.t_nomenclatures n9 ON s.id_nomenclature_diffusion_level = n9.id_nomenclature
     LEFT JOIN ref_nomenclatures.t_nomenclatures n10 ON s.id_nomenclature_life_stage = n10.id_nomenclature
     LEFT JOIN ref_nomenclatures.t_nomenclatures n11 ON s.id_nomenclature_sex = n11.id_nomenclature
     LEFT JOIN ref_nomenclatures.t_nomenclatures n12 ON s.id_nomenclature_obj_count = n12.id_nomenclature
     LEFT JOIN ref_nomenclatures.t_nomenclatures n13 ON s.id_nomenclature_type_count = n13.id_nomenclature
     LEFT JOIN ref_nomenclatures.t_nomenclatures n14 ON s.id_nomenclature_sensitivity = n14.id_nomenclature
     LEFT JOIN ref_nomenclatures.t_nomenclatures n15 ON s.id_nomenclature_observation_status = n15.id_nomenclature
     LEFT JOIN ref_nomenclatures.t_nomenclatures n16 ON s.id_nomenclature_blurring = n16.id_nomenclature
     LEFT JOIN ref_nomenclatures.t_nomenclatures n17 ON s.id_nomenclature_source_status = n17.id_nomenclature
     LEFT JOIN ref_nomenclatures.t_nomenclatures n18 ON s.id_nomenclature_info_geo_type = n18.id_nomenclature
     LEFT JOIN ref_nomenclatures.t_nomenclatures n19 ON s.id_nomenclature_determination_method = n19.id_nomenclature
     LEFT JOIN ref_nomenclatures.t_nomenclatures n20 ON s.id_nomenclature_behaviour = n20.id_nomenclature
     LEFT JOIN ref_nomenclatures.t_nomenclatures n21 ON s.id_nomenclature_valid_status = n21.id_nomenclature
     LEFT JOIN ref_habitats.habref hab ON hab.cd_hab = s.cd_hab;

