
CREATE TABLE taxonomie.bdc_statut_text (
    id_text integer NOT NULL,
    cd_st_text character varying(50),
    cd_type_statut character varying(50) NOT NULL,
    cd_sig character varying(50),
    cd_doc integer,
    niveau_admin character varying(250),
    cd_iso3166_1 character varying(50),
    cd_iso3166_2 character varying(50),
    lb_adm_tr character varying(250),
    full_citation text,
    doc_url text,
    enable boolean DEFAULT true
);

COMMENT ON TABLE taxonomie.bdc_statut_text IS 'Table contenant les textes et leur zone d''application';

CREATE SEQUENCE taxonomie.bdc_statut_text_id_text_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE taxonomie.bdc_statut_text_id_text_seq OWNED BY taxonomie.bdc_statut_text.id_text;

ALTER TABLE ONLY taxonomie.bdc_statut_text
    ADD CONSTRAINT bdc_statut_text_pkey PRIMARY KEY (id_text);

CREATE INDEX idx_bstxt_cd_sig ON taxonomie.bdc_statut_text USING btree (cd_sig);

CREATE INDEX idx_bstxt_cd_type_statut ON taxonomie.bdc_statut_text USING btree (cd_type_statut);

ALTER TABLE ONLY taxonomie.bdc_statut_text
    ADD CONSTRAINT bdc_statut_text_fkey FOREIGN KEY (cd_type_statut) REFERENCES taxonomie.bdc_statut_type(cd_type_statut) ON UPDATE CASCADE ON DELETE CASCADE;

