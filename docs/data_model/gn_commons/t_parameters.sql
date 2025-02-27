
CREATE TABLE gn_commons.t_parameters (
    id_parameter integer NOT NULL,
    id_organism integer,
    parameter_name character varying(100) NOT NULL,
    parameter_desc text,
    parameter_value text NOT NULL,
    parameter_extra_value character varying(255)
);

COMMENT ON TABLE gn_commons.t_parameters IS 'Allow to manage content configuration depending on organism or not (CRUD depending on privileges).';

CREATE SEQUENCE gn_commons.t_parameters_id_parameter_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE gn_commons.t_parameters_id_parameter_seq OWNED BY gn_commons.t_parameters.id_parameter;

ALTER TABLE ONLY gn_commons.t_parameters
    ADD CONSTRAINT pk_t_parameters PRIMARY KEY (id_parameter);

ALTER TABLE ONLY gn_commons.t_parameters
    ADD CONSTRAINT unique_t_parameters_id_organism_parameter_name UNIQUE (id_organism, parameter_name);

CREATE UNIQUE INDEX i_unique_t_parameters_parameter_name_with_id_organism_null ON gn_commons.t_parameters USING btree (parameter_name) WHERE (id_organism IS NULL);

ALTER TABLE ONLY gn_commons.t_parameters
    ADD CONSTRAINT fk_t_parameters_bib_organismes FOREIGN KEY (id_organism) REFERENCES utilisateurs.bib_organismes(id_organisme) ON UPDATE CASCADE;

