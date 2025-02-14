
CREATE TABLE gn_monitoring.t_observation_details (
    id_observation_detail integer NOT NULL,
    id_observation integer NOT NULL,
    data jsonb,
    uuid_observation_detail uuid DEFAULT public.uuid_generate_v4() NOT NULL
);

CREATE SEQUENCE gn_monitoring.t_observation_details_id_observation_detail_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE gn_monitoring.t_observation_details_id_observation_detail_seq OWNED BY gn_monitoring.t_observation_details.id_observation_detail;

ALTER TABLE ONLY gn_monitoring.t_observation_details
    ADD CONSTRAINT pk_t_observation_details PRIMARY KEY (id_observation_detail);

ALTER TABLE ONLY gn_monitoring.t_observation_details
    ADD CONSTRAINT fk_t_observation_details_id_observation FOREIGN KEY (id_observation) REFERENCES gn_monitoring.t_observations(id_observation) ON UPDATE CASCADE ON DELETE CASCADE;

