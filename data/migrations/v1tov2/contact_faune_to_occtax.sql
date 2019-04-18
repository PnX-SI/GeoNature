
DROP FOREIGN TABLE v1_compat.v_nomade_classes;
IMPORT FOREIGN SCHEMA contactfaune FROM SERVER geonature1server INTO v1_compat;

--create de vues métérialisées pour des raisons de performances
CREATE MATERIALIZED VIEW v1_compat.vm_t_fiches_cf AS
SELECT * FROM v1_compat.t_fiches_cf;
CREATE MATERIALIZED VIEW v1_compat.vm_t_releves_cf AS
SELECT * FROM v1_compat.t_releves_cf;
CREATE MATERIALIZED VIEW v1_compat.vm_cor_role_fiche_cf AS
SELECT * FROM v1_compat.cor_role_fiche_cf;


--TODO : réactiver les triggers en prod
ALTER TABLE pr_occtax.t_releves_occtax DISABLE TRIGGER USER;
ALTER TABLE pr_occtax.t_occurrences_occtax DISABLE TRIGGER tri_log_changes_t_occurrences_occtax;
ALTER TABLE pr_occtax.cor_counting_occtax DISABLE TRIGGER tri_log_changes_cor_counting_occtax;
ALTER TABLE pr_occtax.cor_role_releves_occtax DISABLE TRIGGER tri_log_changes_cor_role_releves_occtax;
ALTER TABLE pr_occtax.cor_role_releves_occtax DISABLE TRIGGER tri_insert_synthese_cor_role_releves_occtax;
ALTER TABLE gn_synthese.cor_observer_synthese DISABLE TRIGGER trg_maj_synthese_observers_txt;

CREATE TABLE v1_compat.cor_critere_contactfaune_v1_to_v2 (
	pk_source integer,
	entity_source character varying(100),
	field_source character varying(50),
	entity_target character varying(100),
	field_target character varying(50),
	id_type_nomenclature_cible integer,
	id_nomenclature_cible integer,
	commentaire text
);


INSERT INTO v1_compat.cor_critere_contactfaune_v1_to_v2
SELECT * 
FROM v1_compat.cor_synthese_v1_to_v2
WHERE entity_source = 'v1_compat.bib_criteres_synthese' AND pk_source < 100 ;

UPDATE v1_compat.cor_critere_contactfaune_v1_to_v2 SET entity_target = 'pr_occtax.t_occurrences_occtax';


INSERT INTO pr_occtax.t_releves_occtax(
            id_releve_occtax,
            unique_id_sinp_grp,
            id_dataset, 
            -- technique d'obs non traité en l'état -> NSP
            id_nomenclature_obs_technique, 
            id_nomenclature_grp_typ, 
            date_min, 
            date_max, 
            altitude_min, 
            altitude_max, 
            meta_device_entry, 
            geom_local, 
            geom_4326, 
            "precision"
        )
WITH
n24 AS (SELECT * FROM v1_compat.cor_synthese_v1_to_v2 WHERE id_type_nomenclature_cible = 24)
SELECT 
    id_cf AS id_releve_occtax,
    uuid_generate_v4() AS unique_id_sinp_grp,
    id_lot AS id_dataset,
    ref_nomenclatures.get_id_nomenclature('TECHNIQUE_OBS','133') AS id_nomenclature_obs_technique,
    COALESCE(n24.id_nomenclature_cible, ref_nomenclatures.get_id_nomenclature('TYP_GRP','NSP')) ,
    dateobs AS date_min,
    dateobs AS date_max,
    altitude_retenue AS altitude_min,
    altitude_retenue AS altitude_max,
    saisie_initiale AS meta_device_entry, 
    the_geom_local AS geom_local,
    ST_TRANSFORM(the_geom_local, 4326) AS geom_4326,
    50 AS precision
FROM v1_compat.vm_t_fiches_cf cf
LEFT JOIN n24 ON cf.id_lot = n24.pk_source;

INSERT INTO pr_occtax.t_occurrences_occtax(
            id_occurrence_occtax,
            unique_id_occurence_occtax, 
            id_releve_occtax, 
            id_nomenclature_obs_meth, 
            id_nomenclature_bio_condition, 
            id_nomenclature_bio_status, 
            id_nomenclature_naturalness, 
            id_nomenclature_exist_proof, 
            id_nomenclature_diffusion_level, 
            id_nomenclature_observation_status, 
            id_nomenclature_blurring, 
            id_nomenclature_source_status, 
            determiner, 
            id_nomenclature_determination_method, 
            cd_nom, 
            nom_cite, 
            meta_v_taxref, 
            sample_number_proof, 
            digital_proof, 
            non_digital_proof, 
            comment
        )
    WITH 
    n14 AS (SELECT * FROM v1_compat.cor_critere_contactfaune_v1_to_v2 WHERE id_type_nomenclature_cible = 14) ,
    n7 AS (SELECT * FROM v1_compat.cor_critere_contactfaune_v1_to_v2 WHERE id_type_nomenclature_cible = 7),
    n13 AS (SELECT * FROM v1_compat.cor_critere_contactfaune_v1_to_v2 WHERE id_type_nomenclature_cible = 13)
    SELECT
    id_releve_cf AS id_occurrence_occtax,
    uuid_generate_v4() AS unique_id_occurence_occtax,
    id_cf AS id_releve_occtax,
    COALESCE(n14.id_nomenclature_cible, ref_nomenclatures.get_id_nomenclature('METH_OBS','21')) AS id_nomenclature_obs_meth,
    COALESCE(n7.id_nomenclature_cible, ref_nomenclatures.get_id_nomenclature('ETA_BIO','0')) AS id_nomenclature_bio_condition,
    COALESCE(n13.id_nomenclature_cible, ref_nomenclatures.get_id_nomenclature('STATUT_BIO','1')) AS id_nomenclature_bio_status,
    ref_nomenclatures.get_id_nomenclature('NATURALITE','1') AS id_nomenclature_naturalness,
    ref_nomenclatures.get_id_nomenclature('PREUVE_EXIST','2') AS id_nomenclature_exist_proof,
    ref_nomenclatures.get_id_nomenclature('NIV_PRECIS','5') AS id_nomenclature_diffusion_level,
    ref_nomenclatures.get_id_nomenclature('STATUT_OBS','Pr') AS id_nomenclature_observation_status,
    ref_nomenclatures.get_id_nomenclature('DEE_FLOU','NON') AS id_nomenclature_blurring,
    ref_nomenclatures.get_id_nomenclature('STATUT_SOURCE','Te') AS id_nomenclature_source_status,
    -- determination = Non renseigné
    NULL AS determiner,
    ref_nomenclatures.get_id_nomenclature('METH_DETERMIN','1') AS id_nomenclature_source_status,
    bib_noms.cd_nom AS cd_nom,
    nom_taxon_saisi AS nom_cite,
    'Taxref V11.0' AS meta_v_taxref,
    NULL AS sample_number_proof,
    NULL AS digital_proof, 
    NULL AS non_digital_proof,
    cf.commentaire AS comment
    FROM v1_compat.vm_t_releves_cf cf
    LEFT JOIN n14 ON n14.pk_source =  cf.id_critere_cf
    LEFT JOIN n7 ON n7.pk_source =  cf.id_critere_cf
    LEFT JOIN n13 ON n13.pk_source =  cf.id_critere_cf
    JOIN taxonomie.bib_noms bib_noms ON bib_noms.id_nom = cf.id_nom;


-- insertion denombrement
-- adulte male
INSERT INTO pr_occtax.cor_counting_occtax(
            unique_id_sinp_occtax, 
            id_occurrence_occtax, 
            id_nomenclature_life_stage, 
            id_nomenclature_sex, 
            id_nomenclature_obj_count, 
            id_nomenclature_type_count, 
            count_min, 
            count_max
        )
SELECT 
uuid_generate_v4() AS unique_id_sinp_occtax,
id_releve_cf AS id_occurrence_occtax,
ref_nomenclatures.get_id_nomenclature('STADE_VIE', '2'),
ref_nomenclatures.get_id_nomenclature('SEXE', '3'),
ref_nomenclatures.get_id_nomenclature('OBJ_DENBR', 'IND'),
ref_nomenclatures.get_id_nomenclature('TYP_DENBR', 'NSP'),
am AS count_min,
am AS count_max
FROM v1_compat.vm_t_releves_cf cf
WHERE am > 0;

-- adulte femelle
INSERT INTO pr_occtax.cor_counting_occtax(
            unique_id_sinp_occtax, 
            id_occurrence_occtax, 
            id_nomenclature_life_stage, 
            id_nomenclature_sex, 
            id_nomenclature_obj_count, 
            id_nomenclature_type_count, 
            count_min, 
            count_max
        )
SELECT 
uuid_generate_v4() AS unique_id_sinp_occtax,
id_releve_cf AS id_occurrence_occtax,
ref_nomenclatures.get_id_nomenclature('STADE_VIE', '2'),
ref_nomenclatures.get_id_nomenclature('SEXE', '2'),
ref_nomenclatures.get_id_nomenclature('OBJ_DENBR', 'IND'),
ref_nomenclatures.get_id_nomenclature('TYP_DENBR', 'NSP'),
af AS count_min,
af AS count_max
FROM v1_compat.vm_t_releves_cf cf
WHERE af > 0;

-- adulte indeterminé
INSERT INTO pr_occtax.cor_counting_occtax(
            unique_id_sinp_occtax, 
            id_occurrence_occtax, 
            id_nomenclature_life_stage, 
            id_nomenclature_sex, 
            id_nomenclature_obj_count, 
            id_nomenclature_type_count, 
            count_min, 
            count_max
        )
SELECT 
uuid_generate_v4() AS unique_id_sinp_occtax,
id_releve_cf AS id_occurrence_occtax,
ref_nomenclatures.get_id_nomenclature('STADE_VIE', '2'),
ref_nomenclatures.get_id_nomenclature('SEXE', '0'),
ref_nomenclatures.get_id_nomenclature('OBJ_DENBR', 'IND'),
ref_nomenclatures.get_id_nomenclature('TYP_DENBR', 'NSP'),
ai AS count_min,
ai AS count_max
FROM v1_compat.vm_t_releves_cf cf
WHERE ai > 0;

-- sexe et age indeterminé
INSERT INTO pr_occtax.cor_counting_occtax(
            unique_id_sinp_occtax, 
            id_occurrence_occtax, 
            id_nomenclature_life_stage, 
            id_nomenclature_sex, 
            id_nomenclature_obj_count, 
            id_nomenclature_type_count, 
            count_min, 
            count_max
        )
SELECT 
uuid_generate_v4() AS unique_id_sinp_occtax,
id_releve_cf AS id_occurrence_occtax,
ref_nomenclatures.get_id_nomenclature('STADE_VIE', '0'),
ref_nomenclatures.get_id_nomenclature('SEXE', '0'),
ref_nomenclatures.get_id_nomenclature('OBJ_DENBR', 'IND'),
ref_nomenclatures.get_id_nomenclature('TYP_DENBR', 'NSP'),
sai AS count_min,
sai AS count_max
FROM v1_compat.vm_t_releves_cf cf
WHERE sai > 0;

-- non adulte
INSERT INTO pr_occtax.cor_counting_occtax(
            unique_id_sinp_occtax, 
            id_occurrence_occtax, 
            id_nomenclature_life_stage, 
            id_nomenclature_sex, 
            id_nomenclature_obj_count, 
            id_nomenclature_type_count, 
            count_min, 
            count_max
        )
SELECT 
uuid_generate_v4() AS unique_id_sinp_occtax,
id_releve_cf AS id_occurrence_occtax,
ref_nomenclatures.get_id_nomenclature('STADE_VIE', '3'),
ref_nomenclatures.get_id_nomenclature('SEXE', '0'),
ref_nomenclatures.get_id_nomenclature('OBJ_DENBR', 'IND'),
ref_nomenclatures.get_id_nomenclature('TYP_DENBR', 'NSP'),
na AS count_min,
na AS count_max
FROM v1_compat.vm_t_releves_cf cf
WHERE na > 0;


-- jeune
INSERT INTO pr_occtax.cor_counting_occtax(
            unique_id_sinp_occtax, 
            id_occurrence_occtax, 
            id_nomenclature_life_stage, 
            id_nomenclature_sex, 
            id_nomenclature_obj_count, 
            id_nomenclature_type_count, 
            count_min, 
            count_max
        )
SELECT 
uuid_generate_v4() AS unique_id_sinp_occtax,
id_releve_cf AS id_occurrence_occtax,
ref_nomenclatures.get_id_nomenclature('STADE_VIE', '3'),
ref_nomenclatures.get_id_nomenclature('SEXE', '0'),
ref_nomenclatures.get_id_nomenclature('OBJ_DENBR', 'IND'),
ref_nomenclatures.get_id_nomenclature('TYP_DENBR', 'NSP'),
jeune AS count_min,
jeune AS count_max
FROM v1_compat.vm_t_releves_cf cf
WHERE jeune > 0;

-- yearling
INSERT INTO pr_occtax.cor_counting_occtax(
            unique_id_sinp_occtax, 
            id_occurrence_occtax, 
            id_nomenclature_life_stage, 
            id_nomenclature_sex, 
            id_nomenclature_obj_count, 
            id_nomenclature_type_count, 
            count_min, 
            count_max
        )
SELECT 
uuid_generate_v4() AS unique_id_sinp_occtax,
id_releve_cf AS id_occurrence_occtax,
ref_nomenclatures.get_id_nomenclature('STADE_VIE', '4'),
ref_nomenclatures.get_id_nomenclature('SEXE', '0'),
ref_nomenclatures.get_id_nomenclature('OBJ_DENBR', 'IND'),
ref_nomenclatures.get_id_nomenclature('TYP_DENBR', 'NSP'),
yearling AS count_min,
yearling AS count_max
FROM v1_compat.vm_t_releves_cf cf
WHERE yearling > 0;

-- mettre à jour le serial
SELECT pg_catalog.setval('pr_occtax.t_occurrences_occtax_id_occurrence_occtax_seq', (SELECT max(id_occurrence_occtax)+1 FROM pr_occtax.t_occurrences_occtax), true);
SELECT pg_catalog.setval('pr_occtax.t_releves_occtax_id_releve_occtax_seq', (SELECT max(id_releve_occtax)+1 FROM pr_occtax.t_releves_occtax), true);


-- observateurs 
INSERT INTO pr_occtax.cor_role_releves_occtax
SELECT 
uuid_generate_v4() AS unique_id_cor_role_releve,
id_cf AS id_releve_occtax,
id_role AS id_role
FROM v1_compat.vm_cor_role_fiche_cf;

--TODO Déplacer cette partie pour ne la jouer qu'une fois les 3 schéma cf, inv et cflore importés
--correspondance observateurs en synthese, jouer l'action à la place du tri_insert_synthese_cor_role_releves_occtax
INSERT INTO gn_synthese.cor_observer_synthese(id_synthese, id_role) 
SELECT s.id_synthese, cro.id_role 
FROM gn_synthese.synthese s
JOIN pr_occtax.cor_counting_occtax cco ON cco.id_counting_occtax::varchar = s.entity_source_pk_value
JOIN pr_occtax.t_occurrences_occtax oo ON oo.id_occurrence_occtax = cco.id_occurrence_occtax
JOIN pr_occtax.t_releves_occtax r ON r.id_releve_occtax = oo.id_releve_occtax
JOIN pr_occtax.cor_role_releves_occtax cro ON cro.id_releve_occtax = r.id_releve_occtax
WHERE s.id_dataset IN(4,15);
--observers_as_txt en synthese jouer l'action du trigger trg_maj_synthese_observers_txt
WITH synthese_observers AS (
  SELECT c.id_synthese, array_to_string(array_agg(r.nom_role || ' ' || r.prenom_role), ', ') AS theobservers
  FROM utilisateurs.t_roles r
  JOIN gn_synthese.cor_observer_synthese c ON c.id_role = r.id_role
  GROUP BY id_synthese
)
UPDATE gn_synthese.synthese
SET observers = so.theobservers
FROM synthese_observers so
WHERE gn_synthese.synthese.id_synthese = so.id_synthese;

ALTER TABLE pr_occtax.t_releves_occtax ENABLE TRIGGER USER;
ALTER TABLE pr_occtax.t_occurrences_occtax ENABLE TRIGGER tri_log_changes_t_occurrences_occtax;
ALTER TABLE pr_occtax.cor_counting_occtax ENABLE TRIGGER tri_log_changes_cor_counting_occtax;
ALTER TABLE pr_occtax.cor_role_releves_occtax ENABLE TRIGGER tri_log_changes_cor_role_releves_occtax;
ALTER TABLE pr_occtax.cor_role_releves_occtax ENABLE TRIGGER tri_insert_synthese_cor_role_releves_occtax;
ALTER TABLE gn_synthese.cor_observer_synthese ENABLE TRIGGER trg_maj_synthese_observers_txt;

-- TODO Gérer les id_datasets PNE dans ce script non générique
-- TODO Données sans dénombrement (af, am etc = 0)