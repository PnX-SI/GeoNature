
CREATE TABLE gn_profiles.t_parameters (
    id_parameter integer NOT NULL,
    name character varying(100) NOT NULL,
    "desc" text,
    value text NOT NULL
);

COMMENT ON TABLE gn_profiles.t_parameters IS 'Define global parameters for profiles calculation';

CREATE SEQUENCE gn_profiles.t_parameters_id_parameter_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE gn_profiles.t_parameters_id_parameter_seq OWNED BY gn_profiles.t_parameters.id_parameter;

ALTER TABLE ONLY gn_profiles.t_parameters
    ADD CONSTRAINT pk_parameters PRIMARY KEY (id_parameter);

