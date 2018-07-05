DROP TABLE pr_occtax.defaults_nomenclatures_value;

CREATE TABLE pr_occtax.defaults_nomenclatures_value (
    mnemonique_type character varying(50) NOT NULL,
    id_organism integer NOT NULL DEFAULT 0,
    regne character varying(20) NOT NULL DEFAULT '0',
    group2_inpn character varying(255) NOT NULL DEFAULT '0',
    id_nomenclature integer NOT NULL
);

-- FK ET PK
ALTER TABLE ONLY pr_occtax.defaults_nomenclatures_value
    ADD CONSTRAINT pk_pr_occtax_defaults_nomenclatures_value PRIMARY KEY (mnemonique_type, id_organism, regne, group2_inpn);

ALTER TABLE ONLY pr_occtax.defaults_nomenclatures_value
    ADD CONSTRAINT fk_pr_occtax_defaults_nomenclatures_value_mnemonique_type FOREIGN KEY (mnemonique_type) REFERENCES ref_nomenclatures.bib_nomenclatures_types(mnemonique) ON UPDATE CASCADE;

ALTER TABLE ONLY pr_occtax.defaults_nomenclatures_value
    ADD CONSTRAINT fk_pr_occtax_defaults_nomenclatures_value_id_organism FOREIGN KEY (id_organism) REFERENCES utilisateurs.bib_organismes(id_organisme) ON UPDATE CASCADE;


-- Contraintes

ALTER TABLE pr_occtax.t_releves_occtax DROP CONSTRAINT check_t_releves_occtax_obs_technique;
ALTER TABLE pr_occtax.t_releves_occtax ADD CONSTRAINT check_t_releves_occtax_obs_technique CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_obs_technique, 'TECHNIQUE_OBS')) NOT VALID;
ALTER TABLE pr_occtax.t_releves_occtax DROP CONSTRAINT check_t_releves_occtax_regroupement_typ;
ALTER TABLE pr_occtax.t_releves_occtax ADD CONSTRAINT check_t_releves_occtax_regroupement_typ CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_grp_typ, 'TYP_GRP')) NOT VALID;
ALTER TABLE pr_occtax.t_occurrences_occtax DROP CONSTRAINT check_t_occurrences_occtax_cd_nom_isinbib_noms;
ALTER TABLE pr_occtax.t_occurrences_occtax ADD CONSTRAINT check_t_occurrences_occtax_cd_nom_isinbib_noms CHECK (taxonomie.check_is_inbibnoms(cd_nom)) NOT VALID;
ALTER TABLE pr_occtax.t_occurrences_occtax DROP CONSTRAINT check_t_occurrences_occtax_obs_meth;
ALTER TABLE pr_occtax.t_occurrences_occtax ADD CONSTRAINT check_t_occurrences_occtax_obs_meth CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_obs_meth, 'METH_OBS')) NOT VALID;
ALTER TABLE pr_occtax.t_occurrences_occtax DROP CONSTRAINT check_t_occurrences_occtax_bio_condition;
ALTER TABLE pr_occtax.t_occurrences_occtax ADD CONSTRAINT check_t_occurrences_occtax_bio_condition CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_bio_condition, 'ETA_BIO')) NOT VALID;
ALTER TABLE pr_occtax.t_occurrences_occtax DROP CONSTRAINT check_t_occurrences_occtax_bio_status;
ALTER TABLE pr_occtax.t_occurrences_occtax ADD CONSTRAINT check_t_occurrences_occtax_bio_status CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_bio_status, 'STATUT_BIO')) NOT VALID;
ALTER TABLE pr_occtax.t_occurrences_occtax DROP CONSTRAINT check_t_occurrences_occtax_naturalness;
ALTER TABLE pr_occtax.t_occurrences_occtax ADD CONSTRAINT check_t_occurrences_occtax_naturalness CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_naturalness, 'NATURALITE')) NOT VALID;
ALTER TABLE pr_occtax.t_occurrences_occtax DROP CONSTRAINT check_t_occurrences_occtax_exist_proof;
ALTER TABLE pr_occtax.t_occurrences_occtax ADD CONSTRAINT check_t_occurrences_occtax_exist_proof CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_exist_proof, 'PREUVE_EXIST')) NOT VALID;
ALTER TABLE pr_occtax.t_occurrences_occtax DROP CONSTRAINT check_t_occurrences_occtax_accur_level;
ALTER TABLE pr_occtax.t_occurrences_occtax ADD CONSTRAINT check_t_occurrences_occtax_accur_level CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_diffusion_level, 'NIV_PRECIS')) NOT VALID;
ALTER TABLE pr_occtax.t_occurrences_occtax DROP CONSTRAINT check_t_occurrences_occtax_obs_status;
ALTER TABLE pr_occtax.t_occurrences_occtax ADD CONSTRAINT check_t_occurrences_occtax_obs_status CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_observation_status, 'STATUT_OBS')) NOT VALID;
ALTER TABLE pr_occtax.t_occurrences_occtax DROP CONSTRAINT check_t_occurrences_occtax_blurring;
ALTER TABLE pr_occtax.t_occurrences_occtax ADD CONSTRAINT check_t_occurrences_occtax_blurring CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_blurring, 'DEE_FLOU')) NOT VALID;
ALTER TABLE pr_occtax.t_occurrences_occtax DROP CONSTRAINT check_t_occurrences_occtax_source_status;
ALTER TABLE pr_occtax.t_occurrences_occtax ADD CONSTRAINT check_t_occurrences_occtax_source_status CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_source_status, 'STATUT_SOURCE')) NOT VALID;
ALTER TABLE pr_occtax.t_occurrences_occtax DROP CONSTRAINT check_t_occurrences_occtax_determination_method;
ALTER TABLE pr_occtax.t_occurrences_occtax ADD CONSTRAINT check_t_occurrences_occtax_determination_method CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_determination_method, 'METH_DETERMIN')) NOT VALID;
ALTER TABLE pr_occtax.cor_counting_occtax DROP CONSTRAINT check_cor_counting_occtax_life_stage;
ALTER TABLE pr_occtax.cor_counting_occtax ADD CONSTRAINT check_cor_counting_occtax_life_stage CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_life_stage, 'STADE_VIE')) NOT VALID;
ALTER TABLE pr_occtax.cor_counting_occtax DROP CONSTRAINT check_cor_counting_occtax_sexe;
ALTER TABLE pr_occtax.cor_counting_occtax ADD CONSTRAINT check_cor_counting_occtax_sexe CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_sex, 'SEXE')) NOT VALID;
ALTER TABLE pr_occtax.cor_counting_occtax DROP CONSTRAINT check_cor_counting_occtax_obj_count;
ALTER TABLE pr_occtax.cor_counting_occtax ADD CONSTRAINT check_cor_counting_occtax_obj_count CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_obj_count, 'OBJ_DENBR')) NOT VALID;
ALTER TABLE pr_occtax.cor_counting_occtax DROP CONSTRAINT check_cor_counting_occtax_type_count;
ALTER TABLE pr_occtax.cor_counting_occtax ADD CONSTRAINT check_cor_counting_occtax_type_count CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_type_count, 'TYP_DENBR')) NOT VALID;

ALTER TABLE pr_occtax.defaults_nomenclatures_value ADD CONSTRAINT check_pr_occtax_defaults_nomenclatures_value_is_nomenclature_in CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature, mnemonique_type)) NOT VALID;

ALTER TABLE pr_occtax.defaults_nomenclatures_value ADD CONSTRAINT check_pr_occtax_defaults_nomenclatures_value_isgroup2inpn CHECK ((taxonomie.check_is_group2inpn((group2_inpn)::text) OR ((group2_inpn)::text = '0'::text))) NOT VALID;

ALTER TABLE pr_occtax.defaults_nomenclatures_value ADD CONSTRAINT check_pr_occtax_defaults_nomenclatures_value_isregne CHECK ((taxonomie.check_is_regne((regne)::text) OR ((regne)::text = '0'::text))) NOT VALID;

-- DATA

INSERT INTO pr_occtax.defaults_nomenclatures_value (mnemonique_type, id_organism, regne, group2_inpn, id_nomenclature) VALUES
('METH_OBS',0,0,0, ref_nomenclatures.get_id_nomenclature('METH_OBS', '0'))
,('ETA_BIO',0,0,0, ref_nomenclatures.get_id_nomenclature('ETA_BIO', '2'))
,('STATUT_BIO',0,0,0, ref_nomenclatures.get_id_nomenclature('STATUT_BIO', '1'))
,('NATURALITE',0,0,0, ref_nomenclatures.get_id_nomenclature('NATURALITE', '1'))
,('PREUVE_EXIST',0,0,0, ref_nomenclatures.get_id_nomenclature('PREUVE_EXIST', '0'))
,('STATUT_VALID',0,0,0, ref_nomenclatures.get_id_nomenclature('STATUT_VALID', '0'))
,('NIV_PRECIS',0,0,0, ref_nomenclatures.get_id_nomenclature('NIV_PRECIS', '5'))
,('METH_DETERMIN',0,0,0, ref_nomenclatures.get_id_nomenclature('METH_DETERMIN', '1'))
,('STADE_VIE',0,0,0, ref_nomenclatures.get_id_nomenclature('STADE_VIE', '0'))
,('SEXE',0,0,0, ref_nomenclatures.get_id_nomenclature('SEXE', '6'))
,('OBJ_DENBR',0,0,0, ref_nomenclatures.get_id_nomenclature('OBJ_DENBR', 'IND'))
,('TYP_DENBR',0,0,0, ref_nomenclatures.get_id_nomenclature('TYP_DENBR', 'NSP'))
,('STATUT_OBS',0,0,0, ref_nomenclatures.get_id_nomenclature('STATUT_OBS', 'Pr'))
,('DEE_FLOU',0,0,0, ref_nomenclatures.get_id_nomenclature('DEE_FLOU', 'NON'))
,('TYP_GRP',0,0,0, ref_nomenclatures.get_id_nomenclature('TYP_GRP', 'NSP'))
,('TECHNIQUE_OBS',0,0,0, ref_nomenclatures.get_id_nomenclature('TECHNIQUE_OBS', '133'))
,('STATUT_SOURCE',0, 0, 0,  ref_nomenclatures.get_id_nomenclature('STATUT_SOURCE', 'Te'))
;