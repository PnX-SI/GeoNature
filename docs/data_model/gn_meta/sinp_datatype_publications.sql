
CREATE TABLE gn_meta.sinp_datatype_publications (
    id_publication integer NOT NULL,
    unique_publication_id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    publication_reference text NOT NULL,
    publication_url text
);

COMMENT ON TABLE gn_meta.sinp_datatype_publications IS 'Define a SINP datatype Concepts::Publication.';

COMMENT ON COLUMN gn_meta.sinp_datatype_publications.id_publication IS 'Internal value for primary and foreign keys';

COMMENT ON COLUMN gn_meta.sinp_datatype_publications.unique_publication_id IS 'Internal value to reference external publication id value';

COMMENT ON COLUMN gn_meta.sinp_datatype_publications.publication_reference IS 'Correspondance standard SINP = referencePublication : Référence complète de la publication suivant la nomenclature ISO 690 - OBLIGATOIRE';

COMMENT ON COLUMN gn_meta.sinp_datatype_publications.publication_url IS 'Correspondance standard SINP = URLPublication : Adresse à laquelle trouver la publication - RECOMMANDE.';

CREATE SEQUENCE gn_meta.sinp_datatype_publications_id_publication_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE gn_meta.sinp_datatype_publications_id_publication_seq OWNED BY gn_meta.sinp_datatype_publications.id_publication;

ALTER TABLE ONLY gn_meta.sinp_datatype_publications
    ADD CONSTRAINT pk_sinp_datatype_publications PRIMARY KEY (id_publication);

ALTER TABLE ONLY gn_meta.sinp_datatype_publications
    ADD CONSTRAINT unique_sinp_datatype_publications_uuid UNIQUE (unique_publication_id);

