
CREATE TABLE taxonomie.t_medias (
    id_media integer NOT NULL,
    cd_ref integer,
    titre character varying(255) NOT NULL,
    url character varying(255),
    chemin character varying(255),
    auteur character varying(1000),
    desc_media text,
    date_media date,
    is_public boolean DEFAULT true NOT NULL,
    id_type integer NOT NULL,
    source character varying,
    licence character varying(100),
    CONSTRAINT check_cd_ref_is_ref CHECK ((cd_ref = taxonomie.find_cdref(cd_ref)))
);

CREATE SEQUENCE taxonomie.t_medias_id_media_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE taxonomie.t_medias_id_media_seq OWNED BY taxonomie.t_medias.id_media;

ALTER TABLE ONLY taxonomie.t_medias
    ADD CONSTRAINT id_media PRIMARY KEY (id_media);

CREATE TRIGGER tri_insert_t_medias BEFORE INSERT ON taxonomie.t_medias FOR EACH ROW EXECUTE FUNCTION taxonomie.insert_t_medias();

CREATE TRIGGER tri_unique_type1 AFTER INSERT OR UPDATE ON taxonomie.t_medias FOR EACH ROW EXECUTE FUNCTION taxonomie.unique_type1();

ALTER TABLE ONLY taxonomie.t_medias
    ADD CONSTRAINT fk_t_media_bib_noms FOREIGN KEY (cd_ref) REFERENCES taxonomie.taxref(cd_nom) ON UPDATE CASCADE;

ALTER TABLE ONLY taxonomie.t_medias
    ADD CONSTRAINT fk_t_media_bib_types_media FOREIGN KEY (id_type) REFERENCES taxonomie.bib_types_media(id_type) MATCH FULL ON UPDATE CASCADE;

