
CREATE TABLE gn_commons.t_additional_fields (
    id_field integer NOT NULL,
    field_name character varying(255) NOT NULL,
    field_label character varying(50) NOT NULL,
    required boolean DEFAULT false NOT NULL,
    description text,
    id_widget integer NOT NULL,
    quantitative boolean DEFAULT false,
    unity character varying(50),
    additional_attributes jsonb,
    code_nomenclature_type character varying(255),
    field_values jsonb,
    multiselect boolean,
    id_list integer,
    api character varying(250),
    exportable boolean DEFAULT true,
    field_order integer,
    default_value text
);

CREATE SEQUENCE gn_commons.t_additional_fields_id_field_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE gn_commons.t_additional_fields_id_field_seq OWNED BY gn_commons.t_additional_fields.id_field;

ALTER TABLE ONLY gn_commons.t_additional_fields
    ADD CONSTRAINT pk_t_additional_fields PRIMARY KEY (id_field);

ALTER TABLE ONLY gn_commons.t_additional_fields
    ADD CONSTRAINT fk_t_additional_fields_id_widget FOREIGN KEY (id_widget) REFERENCES gn_commons.bib_widgets(id_widget) ON UPDATE CASCADE ON DELETE CASCADE;

