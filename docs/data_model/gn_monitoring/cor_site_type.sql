
CREATE TABLE gn_monitoring.cor_site_type (
    id_type_site integer NOT NULL,
    id_base_site integer NOT NULL
);

COMMENT ON TABLE gn_monitoring.cor_site_type IS 'Table d''association entre les sites et les types de sites';

ALTER TABLE ONLY gn_monitoring.cor_site_type
    ADD CONSTRAINT pk_cor_site_type PRIMARY KEY (id_type_site, id_base_site);

ALTER TABLE ONLY gn_monitoring.cor_site_type
    ADD CONSTRAINT fk_cor_site_type_id_base_site FOREIGN KEY (id_base_site) REFERENCES gn_monitoring.t_base_sites(id_base_site) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY gn_monitoring.cor_site_type
    ADD CONSTRAINT fk_cor_site_type_id_nomenclature_type_site FOREIGN KEY (id_type_site) REFERENCES gn_monitoring.bib_type_site(id_nomenclature_type_site) ON UPDATE CASCADE ON DELETE CASCADE;

