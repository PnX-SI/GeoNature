
CREATE TABLE gn_meta.cor_acquisition_framework_actor (
    id_cafa integer NOT NULL,
    id_acquisition_framework integer NOT NULL,
    id_role integer,
    id_organism integer,
    id_nomenclature_actor_role integer NOT NULL,
    CONSTRAINT check_id_role_not_group CHECK ((NOT gn_commons.role_is_group(id_role))),
    CONSTRAINT check_is_actor_in_cor_acquisition_framework_actor CHECK (((id_role IS NOT NULL) OR (id_organism IS NOT NULL)))
);

COMMENT ON TABLE gn_meta.cor_acquisition_framework_actor IS 'A acquisition framework must have a principal actor "acteurPrincipal" and can have 0 or n other actor "acteurAutre". Implement 1.3.10 SINP metadata standard : Contact principal pour le cadre d''acquisition (Règle : RoleActeur prendra la valeur 1) - OBLIGATOIRE. Autres contacts pour le cadre d''acquisition (exemples : maître d''oeuvre, d''ouvrage...).- RECOMMANDE';

COMMENT ON COLUMN gn_meta.cor_acquisition_framework_actor.id_nomenclature_actor_role IS 'Correspondance standard SINP = roleActeur : Rôle de l''acteur tel que défini dans la nomenclature RoleActeurValue - OBLIGATOIRE';

CREATE SEQUENCE gn_meta.cor_acquisition_framework_actor_id_cafa_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE gn_meta.cor_acquisition_framework_actor_id_cafa_seq OWNED BY gn_meta.cor_acquisition_framework_actor.id_cafa;

ALTER TABLE gn_meta.cor_acquisition_framework_actor
    ADD CONSTRAINT check_cor_acquisition_framework_actor CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_actor_role, 'ROLE_ACTEUR'::character varying)) NOT VALID;

ALTER TABLE ONLY gn_meta.cor_acquisition_framework_actor
    ADD CONSTRAINT check_is_unique_cor_acquisition_framework_actor_organism UNIQUE (id_acquisition_framework, id_organism, id_nomenclature_actor_role);

ALTER TABLE ONLY gn_meta.cor_acquisition_framework_actor
    ADD CONSTRAINT check_is_unique_cor_acquisition_framework_actor_role UNIQUE (id_acquisition_framework, id_role, id_nomenclature_actor_role);

ALTER TABLE ONLY gn_meta.cor_acquisition_framework_actor
    ADD CONSTRAINT pk_cor_acquisition_framework_actor PRIMARY KEY (id_cafa);

ALTER TABLE ONLY gn_meta.cor_acquisition_framework_actor
    ADD CONSTRAINT fk_cor_acquisition_framework_actor_id_acquisition_framework FOREIGN KEY (id_acquisition_framework) REFERENCES gn_meta.t_acquisition_frameworks(id_acquisition_framework) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY gn_meta.cor_acquisition_framework_actor
    ADD CONSTRAINT fk_cor_acquisition_framework_actor_id_nomenclature_actor_role FOREIGN KEY (id_nomenclature_actor_role) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY gn_meta.cor_acquisition_framework_actor
    ADD CONSTRAINT fk_cor_acquisition_framework_actor_id_organism FOREIGN KEY (id_organism) REFERENCES utilisateurs.bib_organismes(id_organisme) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY gn_meta.cor_acquisition_framework_actor
    ADD CONSTRAINT fk_cor_acquisition_framework_actor_id_role FOREIGN KEY (id_role) REFERENCES utilisateurs.t_roles(id_role) ON UPDATE CASCADE ON DELETE CASCADE;

