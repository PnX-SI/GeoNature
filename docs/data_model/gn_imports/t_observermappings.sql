

CREATE TABLE gn_imports.t_observermappings (
    id integer NOT NULL,
    "values" json DEFAULT '{}'::jsonb NOT NULL
);

CREATE SEQUENCE gn_imports.t_observermappings_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE gn_imports.t_observermappings_id_seq OWNED BY gn_imports.t_observermappings.id;

ALTER TABLE ONLY gn_imports.t_observermappings
    ADD CONSTRAINT t_observermappings_pkey PRIMARY KEY (id);


