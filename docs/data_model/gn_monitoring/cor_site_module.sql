
CREATE TABLE gn_monitoring.cor_site_module (
    id_base_site integer NOT NULL,
    id_module integer NOT NULL
);

ALTER TABLE ONLY gn_monitoring.cor_site_module
    ADD CONSTRAINT pk_cor_site_module PRIMARY KEY (id_base_site, id_module);

ALTER TABLE ONLY gn_monitoring.cor_site_module
    ADD CONSTRAINT fk_cor_site_module_id_base_site FOREIGN KEY (id_base_site) REFERENCES gn_monitoring.t_base_sites(id_base_site) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY gn_monitoring.cor_site_module
    ADD CONSTRAINT fk_cor_site_module_id_module FOREIGN KEY (id_module) REFERENCES gn_commons.t_modules(id_module) ON UPDATE CASCADE ON DELETE CASCADE;

