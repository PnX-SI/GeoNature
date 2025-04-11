
CREATE TABLE gn_meta.t_acquisition_frameworks (
    id_acquisition_framework integer NOT NULL,
    unique_acquisition_framework_id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    acquisition_framework_name character varying(255) NOT NULL,
    acquisition_framework_desc text NOT NULL,
    id_nomenclature_territorial_level integer DEFAULT ref_nomenclatures.get_default_nomenclature_value('NIVEAU_TERRITORIAL'::character varying),
    territory_desc text,
    keywords text,
    id_nomenclature_financing_type integer DEFAULT ref_nomenclatures.get_default_nomenclature_value('TYPE_FINANCEMENT'::character varying),
    target_description text,
    ecologic_or_geologic_target text,
    acquisition_framework_parent_id integer,
    is_parent boolean,
    opened boolean DEFAULT true,
    id_digitizer integer,
    acquisition_framework_start_date date NOT NULL,
    acquisition_framework_end_date date,
    meta_create_date timestamp without time zone NOT NULL,
    meta_update_date timestamp without time zone,
    initial_closing_date timestamp without time zone
);

COMMENT ON TABLE gn_meta.t_acquisition_frameworks IS 'Define a acquisition framework that embed datasets. Implement 1.3.10 SINP metadata standard';

COMMENT ON COLUMN gn_meta.t_acquisition_frameworks.id_acquisition_framework IS 'Internal value for primary and foreign keys';

COMMENT ON COLUMN gn_meta.t_acquisition_frameworks.unique_acquisition_framework_id IS 'Correspondance standard SINP = identifiantCadre';

COMMENT ON COLUMN gn_meta.t_acquisition_frameworks.acquisition_framework_name IS 'Correspondance standard SINP = libelle';

COMMENT ON COLUMN gn_meta.t_acquisition_frameworks.acquisition_framework_desc IS 'Correspondance standard SINP = description';

COMMENT ON COLUMN gn_meta.t_acquisition_frameworks.id_nomenclature_territorial_level IS 'Correspondance standard SINP = niveauTerritorial';

COMMENT ON COLUMN gn_meta.t_acquisition_frameworks.keywords IS 'Correspondance standard SINP = motCle : Mot(s)-clé(s) représentatifs du cadre d''acquisition, séparés par des virgules - FACULTATIF';

COMMENT ON COLUMN gn_meta.t_acquisition_frameworks.id_nomenclature_financing_type IS 'Correspondance standard SINP = typeFinancement : Type de financement pour le cadre d''acquisition, tel que défini dans la nomenclature TypeFinancementValue - RECOMMANDE';

COMMENT ON COLUMN gn_meta.t_acquisition_frameworks.target_description IS 'Correspondance standard SINP = descriptionCible : Description de la cible taxonomique ou géologique pour le cadre d''acquisition. (ex : pteridophyta) - RECOMMANDE';

COMMENT ON COLUMN gn_meta.t_acquisition_frameworks.ecologic_or_geologic_target IS 'Correspondance standard SINP = cibleEcologiqueOuGeologique : Cet attribut sera composé de CD_NOM de TAXREF, séparés par des points virgules, s''il s''agit de taxons, ou de CD_HAB de HABREF, séparés par des points virgules, s''il s''agit d''habitats. - FACULTATIF';

COMMENT ON COLUMN gn_meta.t_acquisition_frameworks.acquisition_framework_parent_id IS 'Correspondance standard SINP = idMetaCadreParent : Indique, par le biais de l''existence d''un identifiant unique de métacadre parent, si le cadre d''acquisition ici présent est contenu dans un autre cadre d''acquisition. S''il y un cadre parent, c''est son identifiant qui doit être renseigné ici. - RECOMMANDE';

COMMENT ON COLUMN gn_meta.t_acquisition_frameworks.is_parent IS 'Correspondance standard SINP = estMetaCadre : Indique si ce dispositif est un métacadre, et donc s''il contient d''autres cadres d''acquisition. Cet attribut est un booléen : 0 pour false (n''est pas un métacadre), 1 pour true (est un métacadre) - OBLIGATOIRE.';

COMMENT ON COLUMN gn_meta.t_acquisition_frameworks.acquisition_framework_start_date IS 'Correspondance standard SINP = ReferenceTemporelle:dateLancement : Date de lancement du cadre d''acquisition - OBLIGATOIRE.';

COMMENT ON COLUMN gn_meta.t_acquisition_frameworks.acquisition_framework_end_date IS 'Correspondance standard SINP = ReferenceTemporelle:dateCloture : Date de clôture du cadre d''acquisition. Si elle n''est pas remplie, on considère que le cadre est toujours en activité. - RECOMMANDE';

COMMENT ON COLUMN gn_meta.t_acquisition_frameworks.meta_create_date IS 'Correspondance standard SINP = dateCreationMtd : Date de création de la fiche de métadonnées du cadre d''acquisition. - OBLIGATOIRE';

COMMENT ON COLUMN gn_meta.t_acquisition_frameworks.meta_update_date IS 'Correspondance standard SINP = dateMiseAJourMtd : Date de mise à jour de la fiche de métadonnées du cadre d''acquisition. - FACULTATIF';

CREATE SEQUENCE gn_meta.t_acquisition_frameworks_id_acquisition_framework_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE gn_meta.t_acquisition_frameworks_id_acquisition_framework_seq OWNED BY gn_meta.t_acquisition_frameworks.id_acquisition_framework;

ALTER TABLE gn_meta.t_acquisition_frameworks
    ADD CONSTRAINT check_t_acquisition_financing_type CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_financing_type, 'TYPE_FINANCEMENT'::character varying)) NOT VALID;

ALTER TABLE gn_meta.t_acquisition_frameworks
    ADD CONSTRAINT check_t_acquisition_frameworks_territorial_level CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_territorial_level, 'NIVEAU_TERRITORIAL'::character varying)) NOT VALID;

ALTER TABLE ONLY gn_meta.t_acquisition_frameworks
    ADD CONSTRAINT pk_t_acquisition_frameworks PRIMARY KEY (id_acquisition_framework);

ALTER TABLE ONLY gn_meta.t_acquisition_frameworks
    ADD CONSTRAINT unique_acquisition_frameworks_uuid UNIQUE (unique_acquisition_framework_id);

CREATE UNIQUE INDEX i_unique_t_acquisition_framework_unique_id ON gn_meta.t_acquisition_frameworks USING btree (unique_acquisition_framework_id);

CREATE TRIGGER tri_meta_dates_change_t_acquisition_frameworks BEFORE INSERT OR UPDATE ON gn_meta.t_acquisition_frameworks FOR EACH ROW EXECUTE FUNCTION public.fct_trg_meta_dates_change();

ALTER TABLE ONLY gn_meta.t_acquisition_frameworks
    ADD CONSTRAINT fk_t_acquisition_frameworks_id_digitizer FOREIGN KEY (id_digitizer) REFERENCES utilisateurs.t_roles(id_role) ON UPDATE CASCADE;

