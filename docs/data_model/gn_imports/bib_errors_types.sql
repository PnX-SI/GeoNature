
CREATE TABLE gn_imports.bib_errors_types (
    id_error integer NOT NULL,
    error_type character varying(100) NOT NULL,
    name character varying(255) NOT NULL,
    description text,
    error_level character varying(25)
);

CREATE SEQUENCE gn_imports.t_user_errors_id_error_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE gn_imports.t_user_errors_id_error_seq OWNED BY gn_imports.bib_errors_types.id_error;

ALTER TABLE ONLY gn_imports.bib_errors_types
    ADD CONSTRAINT pk_user_errors PRIMARY KEY (id_error);

ALTER TABLE ONLY gn_imports.bib_errors_types
    ADD CONSTRAINT t_user_errors_name_key UNIQUE (name);

