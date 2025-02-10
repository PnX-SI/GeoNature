
CREATE TABLE gn_monitoring.t_visit_complements (
    id_base_visit integer NOT NULL,
    data jsonb
);

ALTER TABLE ONLY gn_monitoring.t_visit_complements
    ADD CONSTRAINT pk_t_visit_complements PRIMARY KEY (id_base_visit);

ALTER TABLE ONLY gn_monitoring.t_visit_complements
    ADD CONSTRAINT fk_t_visit_complements_id_base_visit FOREIGN KEY (id_base_visit) REFERENCES gn_monitoring.t_base_visits(id_base_visit) ON UPDATE CASCADE ON DELETE CASCADE;

