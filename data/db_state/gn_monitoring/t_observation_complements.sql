
CREATE TABLE gn_monitoring.t_observation_complements (
    id_observation integer NOT NULL,
    data jsonb
);

ALTER TABLE ONLY gn_monitoring.t_observation_complements
    ADD CONSTRAINT pk_t_observation_complements PRIMARY KEY (id_observation);

ALTER TABLE ONLY gn_monitoring.t_observation_complements
    ADD CONSTRAINT fk_t_observation_complements_id_observation FOREIGN KEY (id_observation) REFERENCES gn_monitoring.t_observations(id_observation) ON UPDATE CASCADE ON DELETE CASCADE;

