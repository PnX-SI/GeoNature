
CREATE VIEW pr_occhab.v_export_sinp AS
 SELECT s.id_station,
    s.id_dataset,
    s.id_digitiser,
    s.unique_id_sinp_station AS uuid_station,
    ds.unique_dataset_id AS uuid_jdd,
    to_char(s.date_min, 'DD/MM/YYYY'::text) AS date_debut,
    to_char(s.date_max, 'DD/MM/YYYY'::text) AS date_fin,
    COALESCE(string_agg(DISTINCT (((r.nom_role)::text || ' '::text) || (r.prenom_role)::text), ','::text), (s.observers_txt)::text) AS observateurs,
    nom2.cd_nomenclature AS methode_calcul_surface,
    s.area AS surface,
    public.st_astext(s.geom_4326) AS geometry,
    public.st_asgeojson(s.geom_4326) AS geojson,
    s.geom_local,
    nom3.cd_nomenclature AS nature_objet_geo,
    h.unique_id_sinp_hab AS uuid_habitat,
    s.altitude_min,
    s.altitude_max,
    nom5.cd_nomenclature AS exposition,
    h.nom_cite,
    h.cd_hab,
    h.technical_precision AS precision_technique,
    nom6.cd_nomenclature AS type_sol
   FROM ((((((((((pr_occhab.t_stations s
     JOIN pr_occhab.t_habitats h ON ((h.id_station = s.id_station)))
     JOIN gn_meta.t_datasets ds ON ((ds.id_dataset = s.id_dataset)))
     LEFT JOIN pr_occhab.cor_station_observer cso ON ((cso.id_station = s.id_station)))
     LEFT JOIN utilisateurs.t_roles r ON ((r.id_role = cso.id_role)))
     LEFT JOIN ref_nomenclatures.t_nomenclatures nom1 ON ((nom1.id_nomenclature = ds.id_nomenclature_data_origin)))
     LEFT JOIN ref_nomenclatures.t_nomenclatures nom2 ON ((nom2.id_nomenclature = s.id_nomenclature_area_surface_calculation)))
     LEFT JOIN ref_nomenclatures.t_nomenclatures nom3 ON ((nom3.id_nomenclature = s.id_nomenclature_geographic_object)))
     LEFT JOIN ref_nomenclatures.t_nomenclatures nom4 ON ((nom4.id_nomenclature = h.id_nomenclature_collection_technique)))
     LEFT JOIN ref_nomenclatures.t_nomenclatures nom5 ON ((nom5.id_nomenclature = s.id_nomenclature_exposure)))
     LEFT JOIN ref_nomenclatures.t_nomenclatures nom6 ON ((nom5.id_nomenclature = s.id_nomenclature_type_sol)))
  GROUP BY s.id_station, s.id_dataset, ds.unique_dataset_id, nom2.cd_nomenclature, h.technical_precision, h.cd_hab, h.nom_cite, nom3.cd_nomenclature, h.unique_id_sinp_hab, nom5.cd_nomenclature, nom6.cd_nomenclature;

