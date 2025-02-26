
CREATE TABLE gn_meta.t_bibliographical_references (
    id_bibliographic_reference bigint DEFAULT nextval('gn_meta.t_bibliographical_references_id_bibliographic_reference_seq'::regclass) NOT NULL,
    id_acquisition_framework integer NOT NULL,
    publication_url character varying,
    publication_reference character varying NOT NULL
);

COMMENT ON TABLE gn_meta.t_bibliographical_references IS 'A acquisition_framework must have 0 or n "publical references". Implement 1.3.10 SINP metadata standard : Référence(s) bibliographique(s) éventuelle(s) concernant le cadre d''acquisition. - RECOMMANDE';

ALTER TABLE ONLY gn_meta.t_bibliographical_references
    ADD CONSTRAINT t_bibliographical_references_pkey PRIMARY KEY (id_bibliographic_reference);

ALTER TABLE ONLY gn_meta.t_bibliographical_references
    ADD CONSTRAINT t_bibliographical_references_id_acquisition_framework_fkey FOREIGN KEY (id_acquisition_framework) REFERENCES gn_meta.t_acquisition_frameworks(id_acquisition_framework) ON DELETE CASCADE;

