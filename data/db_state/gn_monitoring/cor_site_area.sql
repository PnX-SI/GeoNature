
CREATE TABLE gn_monitoring.cor_site_area (
    id_base_site integer NOT NULL,
    id_area integer NOT NULL
);

ALTER TABLE ONLY gn_monitoring.cor_site_area
    ADD CONSTRAINT pk_cor_site_area PRIMARY KEY (id_base_site, id_area);

ALTER TABLE ONLY gn_monitoring.cor_site_area
    ADD CONSTRAINT fk_cor_site_area_id_area FOREIGN KEY (id_area) REFERENCES ref_geo.l_areas(id_area);

ALTER TABLE ONLY gn_monitoring.cor_site_area
    ADD CONSTRAINT fk_cor_site_area_id_base_site FOREIGN KEY (id_base_site) REFERENCES gn_monitoring.t_base_sites(id_base_site) ON UPDATE CASCADE ON DELETE CASCADE;

