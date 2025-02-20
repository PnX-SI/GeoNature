
CREATE TABLE gn_synthese.bib_reports_types (
    id_type integer NOT NULL,
    type character varying NOT NULL
);

CREATE SEQUENCE gn_synthese.bib_reports_types_id_type_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE gn_synthese.bib_reports_types_id_type_seq OWNED BY gn_synthese.bib_reports_types.id_type;

ALTER TABLE ONLY gn_synthese.bib_reports_types
    ADD CONSTRAINT bib_reports_types_pkey PRIMARY KEY (id_type);

