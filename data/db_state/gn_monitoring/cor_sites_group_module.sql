
CREATE TABLE gn_monitoring.cor_sites_group_module (
    id_sites_group integer NOT NULL,
    id_module integer NOT NULL
);

ALTER TABLE ONLY gn_monitoring.cor_sites_group_module
    ADD CONSTRAINT pk_cor_sites_group_module PRIMARY KEY (id_sites_group, id_module);

ALTER TABLE ONLY gn_monitoring.cor_sites_group_module
    ADD CONSTRAINT fk_cor_sites_group_module_id_module FOREIGN KEY (id_module) REFERENCES gn_commons.t_modules(id_module) ON UPDATE CASCADE;

ALTER TABLE ONLY gn_monitoring.cor_sites_group_module
    ADD CONSTRAINT fk_cor_sites_group_module_id_sites_group FOREIGN KEY (id_sites_group) REFERENCES gn_monitoring.t_sites_groups(id_sites_group) ON UPDATE CASCADE ON DELETE CASCADE;

