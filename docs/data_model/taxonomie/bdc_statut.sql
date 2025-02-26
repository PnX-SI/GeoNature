
CREATE TABLE taxonomie.bdc_statut (
    id integer NOT NULL,
    cd_nom integer NOT NULL,
    cd_ref integer NOT NULL,
    cd_sup integer,
    cd_type_statut character varying(50) NOT NULL,
    lb_type_statut character varying(250),
    regroupement_type character varying(250),
    code_statut character varying(250),
    label_statut character varying(1000),
    rq_statut text,
    cd_sig character varying(100),
    cd_doc integer,
    lb_nom character varying(1000),
    lb_auteur character varying(1000),
    nom_complet_html character varying(1000),
    nom_valide_html character varying(1000),
    regne character varying(250),
    phylum character varying(250),
    classe character varying(250),
    ordre character varying(250),
    famille character varying(250),
    group1_inpn character varying(255),
    group2_inpn character varying(255),
    lb_adm_tr character varying(100),
    niveau_admin character varying(250),
    cd_iso3166_1 character varying(50),
    cd_iso3166_2 character varying(50),
    full_citation text,
    doc_url text,
    thematique character varying(100),
    type_value character varying(100)
);

COMMENT ON TABLE taxonomie.bdc_statut IS 'Table initialement fournie par l''INPN. Contient tout les statuts sous leur forme brute';

CREATE SEQUENCE taxonomie.bdc_statut_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE taxonomie.bdc_statut_id_seq OWNED BY taxonomie.bdc_statut.id;

CREATE INDEX bdc_statut_code_statut_idx ON taxonomie.bdc_statut USING btree (code_statut);

CREATE INDEX bdc_statut_id_idx ON taxonomie.bdc_statut USING btree (id);

CREATE INDEX bdc_statut_label_statut_idx ON taxonomie.bdc_statut USING btree (label_statut);

