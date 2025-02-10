
CREATE TABLE gn_monitoring.t_site_complements (
    id_base_site integer NOT NULL,
    id_sites_group integer,
    data jsonb
);

ALTER TABLE ONLY gn_monitoring.t_site_complements
    ADD CONSTRAINT pk_t_site_complements PRIMARY KEY (id_base_site);

ALTER TABLE ONLY gn_monitoring.t_site_complements
    ADD CONSTRAINT fk_t_site_complement_id_base_site FOREIGN KEY (id_base_site) REFERENCES gn_monitoring.t_base_sites(id_base_site) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY gn_monitoring.t_site_complements

