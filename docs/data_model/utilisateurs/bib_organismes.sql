
CREATE TABLE utilisateurs.bib_organismes (
    id_organisme integer NOT NULL,
    uuid_organisme uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    nom_organisme character varying(500) NOT NULL,
    adresse_organisme character varying(128),
    cp_organisme character varying(5),
    ville_organisme character varying(100),
    tel_organisme character varying(14),
    fax_organisme character varying(14),
    email_organisme character varying(100),
    url_organisme character varying(255),
    url_logo character varying(255),
    id_parent integer,
    additional_data jsonb DEFAULT '{}'::jsonb,
    meta_create_date timestamp without time zone DEFAULT now(),
    meta_update_date timestamp without time zone DEFAULT now()
);

CREATE SEQUENCE utilisateurs.bib_organismes_id_organisme_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE utilisateurs.bib_organismes_id_organisme_seq OWNED BY utilisateurs.bib_organismes.id_organisme;

ALTER TABLE ONLY utilisateurs.bib_organismes
    ADD CONSTRAINT bib_organismes_un UNIQUE (uuid_organisme);

ALTER TABLE ONLY utilisateurs.bib_organismes
    ADD CONSTRAINT pk_bib_organismes PRIMARY KEY (id_organisme);

CREATE TRIGGER tri_meta_dates_change_organisms BEFORE INSERT OR UPDATE ON utilisateurs.bib_organismes FOR EACH ROW EXECUTE FUNCTION utilisateurs.fct_trg_meta_dates_change();

ALTER TABLE ONLY utilisateurs.bib_organismes
    ADD CONSTRAINT fk_bib_organismes_id_parent FOREIGN KEY (id_parent) REFERENCES utilisateurs.bib_organismes(id_organisme) ON UPDATE CASCADE;

