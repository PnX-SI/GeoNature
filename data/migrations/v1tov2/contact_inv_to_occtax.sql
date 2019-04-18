DROP FOREIGN TABLE v1_compat.v_nomade_classes;
DROP FOREIGN TABLE v1_compat.cor_message_taxon;
DROP FOREIGN TABLE v1_compat.log_colors;
DROP FOREIGN TABLE v1_compat.log_colors_day;

IMPORT FOREIGN SCHEMA contactinv FROM SERVER geonature1server INTO v1_compat;

ALTER TABLE pr_occtax.t_releves_occtax DISABLE TRIGGER USER;
ALTER TABLE pr_occtax.t_occurrences_occtax DISABLE TRIGGER tri_log_changes_t_occurrences_occtax;
ALTER TABLE pr_occtax.cor_counting_occtax DISABLE TRIGGER tri_log_changes_cor_counting_occtax;
ALTER TABLE pr_occtax.cor_role_releves_occtax DISABLE TRIGGER tri_log_changes_cor_role_releves_occtax;
ALTER TABLE pr_occtax.cor_role_releves_occtax DISABLE TRIGGER tri_insert_synthese_cor_role_releves_occtax;
ALTER TABLE gn_synthese.cor_observer_synthese DISABLE TRIGGER trg_maj_synthese_observers_txt;


--create de vues métérialisées pour des raisons de performances
-- TODO: faire un update sur id_inv en prenant le max de la table t_releve_occtax
CREATE MATERIALIZED VIEW v1_compat.vm_t_fiches_inv AS
WITH temp AS (
SELECT  max(id_releve_occtax) AS max_id
 FROM pr_occtax.t_releves_occtax
)
SELECT
 temp.max_id + id_inv AS id_inv, 
 insee, 
 dateobs, 
 heure, 
 altitude_saisie, 
 altitude_sig, 
 altitude_retenue, 
 date_insert, 
 date_update, 
 supprime, 
 pdop, 
 saisie_initiale, 
 id_organisme, 
 srid_dessin, 
 id_protocole, 
 id_lot, 
 the_geom_3857, 
 id_milieu_inv, 
 the_geom_local
 FROM v1_compat.t_fiches_inv, temp;

CREATE MATERIALIZED VIEW v1_compat.vm_t_releves_inv AS
WITH temp AS (
SELECT  max(id_occurrence_occtax) AS max_id
 FROM pr_occtax.t_occurrences_occtax 
),
temp2 AS (
SELECT  max(id_releve_occtax) AS max_id
 FROM pr_occtax.t_releves_occtax        
)
SELECT
 temp.max_id + id_releve_inv AS id_releve_inv, 
 temp2.max_id + id_inv AS id_inv, 
 id_nom, 
 id_critere_inv, 
 am, 
 af, 
 ai, 
 na, 
cd_ref_origine, 
nom_taxon_saisi, 
commentaire, 
determinateur, 
supprime, 
prelevement,
gid, 
diffusable
FROM v1_compat.t_releves_inv, temp, temp2;

-- vm cor_role
CREATE MATERIALIZED VIEW v1_compat.vm_cor_role_fiche_inv AS
WITH temp AS (
SELECT  max(id_releve_occtax) AS max_id
 FROM pr_occtax.t_releves_occtax
)
SELECT 
temp.max_id + id_inv AS id_inv,
id_role
FROM v1_compat.cor_role_fiche_inv, temp;

CREATE TABLE v1_compat.cor_critere_contactinv_v1_to_v2 (
	pk_source integer,
	entity_source character varying(100),
	field_source character varying(50),
	entity_target character varying(100),
	field_target character varying(50),
	id_type_nomenclature_cible integer,
	id_nomenclature_cible integer,
	commentaire text
);

-- methode d'observation - defaut inconnu
INSERT INTO v1_compat.cor_critere_contactinv_v1_to_v2 (pk_source, entity_source, field_source, entity_target, field_target, id_type_nomenclature_cible, id_nomenclature_cible)
SELECT id_critere_inv, 'v1_compat.bib_criteres_inv' AS entity_source, 'id_critere_inv' as field_source, 'pr_occtax.t_occurrence_occtax' AS entity_target, 'id_nomenclature_obs_meth' AS field_target, 14 AS id_type_nomenclature_cible, ref_nomenclatures.get_id_nomenclature('METH_OBS','21') AS id_nomenclature_cible 
FROM v1_compat.bib_criteres_inv;

-- methode d'observation - vu
UPDATE v1_compat.cor_critere_contactinv_v1_to_v2
SET id_nomenclature_cible = ref_nomenclatures.get_id_nomenclature('METH_OBS','0')
WHERE pk_source IN (1,2,3,8)
AND entity_source = 'v1_compat.bib_criteres_inv' AND field_source = 'id_critere_inv' AND entity_target = 'pr_occtax.t_occurrence_occtax' AND field_target = 'id_nomenclature_obs_meth';

-- statut bio: toujours inconnu

-- etat bio - default: NSP
INSERT INTO v1_compat.cor_critere_contactinv_v1_to_v2 (pk_source, entity_source, field_source, entity_target, field_target, id_type_nomenclature_cible, id_nomenclature_cible)
SELECT id_critere_inv, 'v1_compat.bib_criteres_inv' AS entity_source, 'id_critere_inv' as field_source, 'pr_occtax.t_occurrence_occtax' AS entity_target, 'id_nomenclature_bio_condition' AS field_target, 7 AS id_type_nomenclature_cible, ref_nomenclatures.get_id_nomenclature('ETA_BIO','0') AS id_nomenclature_cible 
FROM v1_compat.bib_criteres_inv;

-- vivant
UPDATE v1_compat.cor_critere_contactinv_v1_to_v2
SET id_nomenclature_cible = ref_nomenclatures.get_id_nomenclature('ETA_BIO','2')
WHERE pk_source IN(1,2,3)
AND entity_source = 'v1_compat.bib_criteres_inv' AND field_source = 'id_critere_inv' AND entity_target = 'pr_occtax.t_occurrence_occtax' AND field_target = 'id_nomenclature_bio_condition';

-- mort
UPDATE v1_compat.cor_critere_contactinv_v1_to_v2
SET id_nomenclature_cible = ref_nomenclatures.get_id_nomenclature('ETA_BIO','3')
WHERE pk_source IN(8)
AND entity_source = 'v1_compat.bib_criteres_inv' AND field_source = 'id_critere_inv' AND entity_target = 'pr_occtax.t_occurrence_occtax' AND field_target = 'id_nomenclature_bio_condition';


INSERT INTO pr_occtax.t_releves_occtax(
            id_releve_occtax, 
            unique_id_sinp_grp, 
            id_dataset, 
            id_nomenclature_obs_technique, 
            id_nomenclature_grp_typ, 
            date_min, 
            date_max, 
            hour_min, 
            hour_max, 
            altitude_min, 
            altitude_max, 
            meta_device_entry, 
            geom_local, 
            geom_4326, 
            "precision"
        )
    SELECT 
    id_inv AS id_releve_occtax,
    uuid_generate_v4() AS unique_id_sinp_grp,
    id_lot AS id_dataset,
    ref_nomenclatures.get_id_nomenclature('TECHNIQUE_OBS','133') AS id_nomenclature_obs_technique,
    ref_nomenclatures.get_id_nomenclature('TYP_GRP','NSP') AS id_nomenclature_grp_typ,
    dateobs AS date_min,
    dateobs AS date_max,
    make_interval(hours:= heure, mins := 00)::time AS hour_min,
    make_interval(hours:= heure, mins := 00)::time AS hour_max,
    altitude_retenue AS altitude_min,
    altitude_retenue AS altitude_max,
    saisie_initiale AS meta_device_entry,
    the_geom_local AS geom_local,
    ST_TRANSFORM(the_geom_local, 4326) AS geom_4326,
    50 AS precision
    FROM v1_compat.vm_t_fiches_inv
;

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
    n14 AS (SELECT * FROM v1_compat.cor_critere_contactinv_v1_to_v2 WHERE id_type_nomenclature_cible = 14) ,
    n7 AS (SELECT * FROM v1_compat.cor_critere_contactinv_v1_to_v2 WHERE id_type_nomenclature_cible = 7)
    SELECT
    id_releve_inv AS id_occurrence_occtax,
    uuid_generate_v4() AS unique_id_occurence_occtax,
    id_inv AS id_releve_occtax,
    COALESCE(n14.id_nomenclature_cible, ref_nomenclatures.get_id_nomenclature('METH_OBS','21')) AS id_nomenclature_obs_meth,
    COALESCE(n7.id_nomenclature_cible, ref_nomenclatures.get_id_nomenclature('ETA_BIO','0')) AS id_nomenclature_bio_condition,
    ref_nomenclatures.get_id_nomenclature('STATUT_BIO','1') AS id_nomenclature_bio_status,
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
    inv.commentaire AS comment
    FROM v1_compat.vm_t_releves_inv inv
    LEFT JOIN n14 ON n14.pk_source =  inv.id_critere_inv
    LEFT JOIN n7 ON n7.pk_source =  inv.id_critere_inv
    JOIN taxonomie.bib_noms bib_noms ON bib_noms.id_nom = inv.id_nom
;


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
id_releve_inv AS id_occurrence_occtax,
ref_nomenclatures.get_id_nomenclature('STADE_VIE', '2'),
ref_nomenclatures.get_id_nomenclature('SEXE', '3'),
ref_nomenclatures.get_id_nomenclature('OBJ_DENBR', 'IND'),
ref_nomenclatures.get_id_nomenclature('TYP_DENBR', 'NSP'),
am AS count_min,
am AS count_max
FROM v1_compat.vm_t_releves_inv inv
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
id_releve_inv AS id_occurrence_occtax,
ref_nomenclatures.get_id_nomenclature('STADE_VIE', '2'),
ref_nomenclatures.get_id_nomenclature('SEXE', '2'),
ref_nomenclatures.get_id_nomenclature('OBJ_DENBR', 'IND'),
ref_nomenclatures.get_id_nomenclature('TYP_DENBR', 'NSP'),
af AS count_min,
af AS count_max
FROM v1_compat.vm_t_releves_inv inv
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
id_releve_inv AS id_occurrence_occtax,
ref_nomenclatures.get_id_nomenclature('STADE_VIE', '2'),
ref_nomenclatures.get_id_nomenclature('SEXE', '0'),
ref_nomenclatures.get_id_nomenclature('OBJ_DENBR', 'IND'),
ref_nomenclatures.get_id_nomenclature('TYP_DENBR', 'NSP'),
ai AS count_min,
ai AS count_max
FROM v1_compat.vm_t_releves_inv inv
WHERE ai > 0;

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
id_releve_inv AS id_occurrence_occtax,
ref_nomenclatures.get_id_nomenclature('STADE_VIE', '3'),
ref_nomenclatures.get_id_nomenclature('SEXE', '0'),
ref_nomenclatures.get_id_nomenclature('OBJ_DENBR', 'IND'),
ref_nomenclatures.get_id_nomenclature('TYP_DENBR', 'NSP'),
na AS count_min,
na AS count_max
FROM v1_compat.vm_t_releves_inv inv
WHERE na > 0;


-- observateurs
INSERT INTO pr_occtax.cor_role_releves_occtax
SELECT 
uuid_generate_v4() AS unique_id_cor_role_releve,
id_inv AS id_releve_occtax,
id_role AS id_role
FROM v1_compat.vm_cor_role_fiche_inv;

--correspondance observateurs en synthese, jouer l'action à la place du tri_insert_synthese_cor_role_releves_occtax
INSERT INTO gn_synthese.cor_observer_synthese(id_synthese, id_role) 
SELECT s.id_synthese, cro.id_role 
FROM gn_synthese.synthese s
JOIN pr_occtax.cor_counting_occtax cco ON cco.id_counting_occtax::varchar = s.entity_source_pk_value
JOIN pr_occtax.t_occurrences_occtax oo ON oo.id_occurrence_occtax = cco.id_occurrence_occtax
JOIN pr_occtax.t_releves_occtax r ON r.id_releve_occtax = oo.id_releve_occtax
JOIN pr_occtax.cor_role_releves_occtax cro ON cro.id_releve_occtax = r.id_releve_occtax
WHERE s.id_dataset  = 14;
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

-- Suppression des VM
DROP MATERIALIZED VIEW v1_compat.vm_t_fiches_inv;
DROP MATERIALIZED VIEW v1_compat.vm_t_releves_inv;
