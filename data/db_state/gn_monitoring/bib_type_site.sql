
CREATE TABLE gn_monitoring.bib_type_site (
    id_nomenclature_type_site integer NOT NULL,
    config json
);

COMMENT ON TABLE gn_monitoring.bib_type_site IS 'Table de définition des champs associés aux types de sites';

ALTER TABLE ONLY gn_monitoring.bib_type_site
    ADD CONSTRAINT bib_type_site_pkey PRIMARY KEY (id_nomenclature_type_site);

ALTER TABLE gn_monitoring.bib_type_site
    ADD CONSTRAINT ck_bib_type_site_id_nomenclature_type_site CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_type_site, 'TYPE_SITE'::character varying)) NOT VALID;

ALTER TABLE ONLY gn_monitoring.bib_type_site
    ADD CONSTRAINT fk_t_nomenclatures_id_nomenclature_type_site FOREIGN KEY (id_nomenclature_type_site) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature);

