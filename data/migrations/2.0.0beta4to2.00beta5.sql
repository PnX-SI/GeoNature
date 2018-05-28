CREATE TABLE gn_commons.t_parameters (
    id_parameter integer NOT NULL,
    id_organism integer,
    parameter_name character varying(100) NOT NULL,
    parameter_desc text,
    parameter_value text NOT NULL,
    parameter_extra_value character varying(255)
);
COMMENT ON TABLE gn_commons.t_parameters IS 'Allow to manage content configuration depending on organism or not (CRUD depending on privileges).';

ALTER TABLE ONLY gn_commons.t_parameters
    ADD CONSTRAINT pk_t_parameters PRIMARY KEY (id_parameter);

INSERT INTO gn_commons.t_parameters (id_parameter, id_organism, parameter_name, parameter_desc, parameter_value, parameter_extra_value)
SELECT * FROM gn_meta.t_parameters;