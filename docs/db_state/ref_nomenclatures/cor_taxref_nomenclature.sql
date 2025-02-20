
CREATE TABLE ref_nomenclatures.cor_taxref_nomenclature (
    id_nomenclature integer NOT NULL,
    regne character varying(255) NOT NULL,
    group2_inpn character varying(255) NOT NULL,
    meta_create_date timestamp without time zone DEFAULT now(),
    meta_update_date timestamp without time zone,
    group3_inpn character varying(255) DEFAULT 'all'::character varying NOT NULL
);

ALTER TABLE ref_nomenclatures.cor_taxref_nomenclature
    ADD CONSTRAINT check_cor_taxref_nomenclature_isgroup2inpn CHECK ((taxonomie.check_is_group2inpn((group2_inpn)::text) OR ((group2_inpn)::text = 'all'::text))) NOT VALID;

ALTER TABLE ref_nomenclatures.cor_taxref_nomenclature
    ADD CONSTRAINT check_cor_taxref_nomenclature_isgroup3inpn CHECK ((taxonomie.check_is_group3inpn((group3_inpn)::text) OR ((group3_inpn)::text = 'all'::text))) NOT VALID;

ALTER TABLE ref_nomenclatures.cor_taxref_nomenclature
    ADD CONSTRAINT check_cor_taxref_nomenclature_isregne CHECK ((taxonomie.check_is_regne((regne)::text) OR ((regne)::text = 'all'::text))) NOT VALID;

ALTER TABLE ONLY ref_nomenclatures.cor_taxref_nomenclature
    ADD CONSTRAINT pk_cor_taxref_nomenclature PRIMARY KEY (id_nomenclature, regne, group2_inpn, group3_inpn);

CREATE TRIGGER tri_meta_dates_change_cor_taxref_nomenclature BEFORE INSERT OR UPDATE ON ref_nomenclatures.cor_taxref_nomenclature FOR EACH ROW EXECUTE FUNCTION public.fct_trg_meta_dates_change();

ALTER TABLE ONLY ref_nomenclatures.cor_taxref_nomenclature
    ADD CONSTRAINT fk_cor_taxref_nomenclature_id_nomenclature FOREIGN KEY (id_nomenclature) REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;

