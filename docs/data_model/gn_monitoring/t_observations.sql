
CREATE TABLE gn_monitoring.t_observations (
    id_observation integer NOT NULL,
    id_base_visit integer NOT NULL,
    cd_nom integer NOT NULL,
    comments text,
    uuid_observation uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    id_digitiser integer NOT NULL
);

CREATE SEQUENCE gn_monitoring.t_observations_id_observation_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE gn_monitoring.t_observations_id_observation_seq OWNED BY gn_monitoring.t_observations.id_observation;

ALTER TABLE ONLY gn_monitoring.t_observations
    ADD CONSTRAINT pk_t_observations PRIMARY KEY (id_observation);

ALTER TABLE ONLY gn_monitoring.t_observations
    ADD CONSTRAINT fk_t_observations_id_base_visit FOREIGN KEY (id_base_visit) REFERENCES gn_monitoring.t_base_visits(id_base_visit) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY gn_monitoring.t_observations
    ADD CONSTRAINT fk_t_observations_id_digitiser FOREIGN KEY (id_digitiser) REFERENCES utilisateurs.t_roles(id_role) ON UPDATE CASCADE;

