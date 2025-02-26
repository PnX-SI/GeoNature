
CREATE TABLE gn_permissions.bib_filters_type (
    id_filter_type integer NOT NULL,
    code_filter_type character varying(50) NOT NULL,
    label_filter_type character varying(255) NOT NULL,
    description_filter_type text
);

CREATE SEQUENCE gn_permissions.bib_filters_type_id_filter_type_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE gn_permissions.bib_filters_type_id_filter_type_seq OWNED BY gn_permissions.bib_filters_type.id_filter_type;

ALTER TABLE ONLY gn_permissions.bib_filters_type
    ADD CONSTRAINT pk_bib_filters_type PRIMARY KEY (id_filter_type);

