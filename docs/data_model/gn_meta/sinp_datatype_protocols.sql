
CREATE TABLE gn_meta.sinp_datatype_protocols (
    id_protocol integer NOT NULL,
    unique_protocol_id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    protocol_name character varying(255) NOT NULL,
    protocol_desc text,
    id_nomenclature_protocol_type integer NOT NULL,
    protocol_url character varying(255)
);

COMMENT ON TABLE gn_meta.sinp_datatype_protocols IS 'Define a SINP datatype Types::ProtocoleType.';

COMMENT ON COLUMN gn_meta.sinp_datatype_protocols.id_protocol IS 'Internal value for primary and foreign keys';

COMMENT ON COLUMN gn_meta.sinp_datatype_protocols.unique_protocol_id IS 'Internal value to reference external protocol id value';

COMMENT ON COLUMN gn_meta.sinp_datatype_protocols.protocol_name IS 'Correspondance standard SINP = libelle : Libellé du protocole : donne le nom du protocole en quelques mots - OBLIGATOIRE';

COMMENT ON COLUMN gn_meta.sinp_datatype_protocols.protocol_desc IS 'Correspondance standard SINP = description : Description du protocole : décrit le contenu du protocole - FACULTATIF.';

COMMENT ON COLUMN gn_meta.sinp_datatype_protocols.id_nomenclature_protocol_type IS 'Correspondance standard SINP = typeProtocole : Type du protocole, tel que défini dans la nomenclature TypeProtocoleValue - OBLIGATOIRE';

COMMENT ON COLUMN gn_meta.sinp_datatype_protocols.protocol_url IS 'Correspondance standard SINP = uRL : URL d''accès à un document permettant de décrire le protocole - RECOMMANDE.';

CREATE SEQUENCE gn_meta.sinp_datatype_protocols_id_protocol_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE gn_meta.sinp_datatype_protocols_id_protocol_seq OWNED BY gn_meta.sinp_datatype_protocols.id_protocol;

ALTER TABLE gn_meta.sinp_datatype_protocols
    ADD CONSTRAINT check_sinp_datatype_protocol_type CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_protocol_type, 'TYPE_PROTOCOLE'::character varying)) NOT VALID;

ALTER TABLE ONLY gn_meta.sinp_datatype_protocols
    ADD CONSTRAINT pk_sinp_datatype_protocols PRIMARY KEY (id_protocol);

ALTER TABLE ONLY gn_meta.sinp_datatype_protocols
    ADD CONSTRAINT unique_sinp_datatype_protocols_uuid UNIQUE (unique_protocol_id);

