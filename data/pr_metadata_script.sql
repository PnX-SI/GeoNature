COMMENT ON TABLE gn_meta.cor_dataset_territory
    IS 'A dataset must have 1 or n "territoire". Implement 1.3.10 SINP metadata standard : Cible géographique du jeu de données, ou zone géographique visée par le jeu. Défini par une valeur dans la nomenclature TerritoireValue. - OBLIGATOIRE';
 
COMMENT ON TABLE gn_meta.cor_acquisition_framework_publication
    IS 'A acquisition framework can have 0 or n "publication". Implement 1.3.10 SINP metadata standard : Référence(s) bibliographique(s) éventuelle(s) concernant le cadre d''acquisition - RECOMMANDE';
 
COMMENT ON TABLE gn_meta.cor_acquisition_framework_objectif
    IS 'A acquisition framework can have 1 or n "objectif". Implement 1.3.10 SINP metadata standard : Objectif du cadre d''acquisition, tel que défini par la nomenclature TypeDispositifValue - OBLIGATOIRE';
 
COMMENT ON TABLE gn_meta.cor_acquisition_framework_actor
    IS 'A acquisition framework must have a principal actor "acteurPrincipal" and can have 0 or n other actor "acteurAutre". Implement 1.3.10 SINP metadata standard : Contact principal pour le cadre d''acquisition (Règle : RoleActeur prendra la valeur 1) - OBLIGATOIRE. Autres contacts pour le cadre d''acquisition (exemples : maître d''oeuvre, d''ouvrage...).- RECOMMANDE';
 
COMMENT ON TABLE gn_meta.cor_acquisition_framework_voletsinp
    IS 'A acquisition framework can have 0 or n "voletSINP". Implement 1.3.10 SINP metadata standard : Volet du SINP concerné par le dispositif de collecte, tel que défini dans la nomenclature voletSINPValue - FACULTATIF';
 
COMMENT ON TABLE gn_meta.cor_dataset_actor
    IS 'A dataset must have 1 or n actor ""pointContactJdd"". Implement 1.3.10 SINP metadata standard : Point de contact principal pour les données du jeu de données, et autres éventuels contacts (fournisseur ou producteur). (Règle : Un contact au moins devra avoir roleActeur à 1 - Les autres types possibles pour roleActeur sont 5 et 6 (fournisseur et producteur)) - OBLIGATOIRE';
 
COMMENT ON TABLE gn_meta.cor_dataset_protocol
    IS 'A dataset can have 0 or n "protocole". Implement 1.3.10 SINP metadata standard : Protocole(s) rattaché(s) au jeu de données (protocole de synthèse et/ou de collecte). On se rapportera au type "Protocole Type". - RECOMMANDE';
 
COMMENT ON TABLE gn_meta.t_acquisition_frameworks
    IS 'Define a acquisition framework that embed datasets. Implement 1.3.10 SINP metadata standard';
 
 
CREATE TABLE gn_meta.cor_acquisition_framework_territory
(
    id_acquisition_framework integer NOT NULL,
    id_nomenclature_territory integer NOT NULL,
    CONSTRAINT pk_cor_acquisition_framework_territory PRIMARY KEY (id_acquisition_framework, id_nomenclature_territory),
    CONSTRAINT fk_cor_af_territory_id_af FOREIGN KEY (id_acquisition_framework)
        REFERENCES gn_meta.t_acquisition_frameworks (id_acquisition_framework) MATCH SIMPLE
        ON UPDATE CASCADE
        ON DELETE NO ACTION,
    CONSTRAINT fk_cor_af_territory_id_nomenclature_territory FOREIGN KEY (id_nomenclature_territory)
        REFERENCES ref_nomenclatures.t_nomenclatures (id_nomenclature) MATCH SIMPLE
        ON UPDATE CASCADE
        ON DELETE NO ACTION,
    CONSTRAINT check_cor_af_territory CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_territory, 'TERRITOIRE'::character varying)) NOT VALID
);
 
COMMENT ON TABLE gn_meta.cor_acquisition_framework_territory
    IS 'A acquisition_framework must have 1 or n "territoire". Implement 1.3.10 SINP metadata standard : Cible géographique du jeu de données, ou zone géographique visée par le jeu. Défini par une valeur dans la nomenclature TerritoireValue. - OBLIGATOIRE';
 
 
 
CREATE TABLE gn_meta.t_bibliographical_references
(
    id_bibliographic_reference serial NOT NULL,
    id_acquisition_framework integer NOT NULL,
    publication_url character varying COLLATE pg_catalog."default",
    publication_reference character varying COLLATE pg_catalog."default" NOT NULL,
    CONSTRAINT t_bibliographical_references_pkey PRIMARY KEY (id_bibliographic_reference),
    CONSTRAINT t_bibliographical_references_id_acquisition_framework_fkey FOREIGN KEY (id_acquisition_framework)
        REFERENCES gn_meta.t_acquisition_frameworks (id_acquisition_framework) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
);
 
COMMENT ON TABLE gn_meta.t_bibliographical_references
    IS 'A acquisition_framework must have 0 or n "publical references". Implement 1.3.10 SINP metadata standard : Référence(s) bibliographique(s) éventuelle(s) concernant le cadre d''acquisition. - RECOMMANDE';