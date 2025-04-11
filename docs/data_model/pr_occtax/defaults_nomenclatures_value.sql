
CREATE TABLE pr_occtax.defaults_nomenclatures_value (
    mnemonique_type character varying(255) NOT NULL,
    id_organism integer DEFAULT 0 NOT NULL,
    regne character varying(20) DEFAULT '0'::character varying NOT NULL,
    group2_inpn character varying(255) DEFAULT '0'::character varying NOT NULL,
    id_nomenclature integer NOT NULL
);

ALTER TABLE pr_occtax.defaults_nomenclatures_value
    ADD CONSTRAINT check_pr_occtax_defaults_nomenclatures_value_is_nomenclature_in CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature, mnemonique_type)) NOT VALID;

ALTER TABLE pr_occtax.defaults_nomenclatures_value
    ADD CONSTRAINT check_pr_occtax_defaults_nomenclatures_value_isgroup2inpn CHECK ((taxonomie.check_is_group2inpn((group2_inpn)::text) OR ((group2_inpn)::text = '0'::text))) NOT VALID;

ALTER TABLE pr_occtax.defaults_nomenclatures_value
    ADD CONSTRAINT check_pr_occtax_defaults_nomenclatures_value_isregne CHECK ((taxonomie.check_is_regne((regne)::text) OR ((regne)::text = '0'::text))) NOT VALID;

ALTER TABLE ONLY pr_occtax.defaults_nomenclatures_value
    ADD CONSTRAINT pk_pr_occtax_defaults_nomenclatures_value PRIMARY KEY (mnemonique_type, id_organism, regne, group2_inpn);

ALTER TABLE ONLY pr_occtax.defaults_nomenclatures_value
    ADD CONSTRAINT fk_pr_occtax_defaults_nomenclatures_value_id_nomenclature FOREIGN KEY (id_nomenclature) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

ALTER TABLE ONLY pr_occtax.defaults_nomenclatures_value
    ADD CONSTRAINT fk_pr_occtax_defaults_nomenclatures_value_id_organism FOREIGN KEY (id_organism) REFERENCES utilisateurs.bib_organismes(id_organisme) ON UPDATE CASCADE;

ALTER TABLE ONLY pr_occtax.defaults_nomenclatures_value
    ADD CONSTRAINT fk_pr_occtax_defaults_nomenclatures_value_mnemonique_type FOREIGN KEY (mnemonique_type) REFERENCES ref_nomenclatures.bib_nomenclatures_types(mnemonique) ON UPDATE CASCADE;

