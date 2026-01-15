

CREATE VIEW gn_meta.v_acquisition_frameworks_territories AS
 SELECT d.id_acquisition_framework,
    cdt.id_nomenclature_territory,
    cdt.territory_desc
   FROM ((gn_meta.t_acquisition_frameworks taf
     JOIN gn_meta.t_datasets d ON ((d.id_acquisition_framework = taf.id_acquisition_framework)))
     JOIN gn_meta.cor_dataset_territory cdt ON ((cdt.id_dataset = d.id_dataset)));


