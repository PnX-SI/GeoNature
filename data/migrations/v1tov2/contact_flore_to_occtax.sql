DROP FOREIGN TABLE v1_compat.v_nomade_classes;
IMPORT FOREIGN SCHEMA contactflore FROM SERVER geonature1server INTO v1_compat;

CREATE MATERIALIZED VIEW v1_compat.vm_t_fiches_cflore AS
WITH temp AS (
SELECT  max(id_releve_occtax) AS max_id
 FROM pr_occtax.t_releves_occtax
)
SELECT 
temp.max_id + id_cflore, 
insee, dateobs, 
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
the_geom_local
FROM v1_compat.t_fiches_cflore;


CREATE MATERIALIZED VIEW v1_compat.vm_t_releves_cflore AS
WITH temp AS (
SELECT  max(id_occurrence_occtax) AS max_id
 FROM pr_occtax.t_occurrences_occtax
)
SELECT 
temp.max_id + id_releve_cflore, 
id_cflore, 
id_nom, 
id_abondance_cflore, 
id_phenologie_cflore, 
cd_ref_origine, 
nom_taxon_saisi, 
commentaire, 
determinateur, 
supprime, 
herbier, 
gid, 
validite_cflore, 
diffusable
FROM v1_compat.t_releves_cflore, temp;



CREATE TABLE v1_compat.cor_critere_cflore_v1_to_v2 (
	pk_source integer,
	entity_source character varying(100),
	field_source character varying(50),
	entity_target character varying(100),
	field_target character varying(50),
	id_type_nomenclature_cible integer,
	id_nomenclature_cible integer,
	commentaire text
);


-- stade de vie: Inconnu par defaut
INSERT INTO v1_compat.cor_critere_cflore_v1_to_v2 (pk_source, entity_source, field_source, entity_target, field_target, id_type_nomenclature_cible, id_nomenclature_cible)
SELECT id_phenologie_cflore, 'v1_compat.bib_phenologies_cflore' AS entity_source, 'id_phenologie_cflore' as field_source, 'pr_occtax.cor_counting_occtax' AS entity_target, 'id_nomenclature_life_stage' AS field_target, 10 AS id_type_nomenclature_cible, ref_nomenclatures.get_id_nomenclature('STADE_VIE','0') AS id_nomenclature_cible 
FROM v1_compat.bib_phenologies_cflore;

-- stade de vie - décrepitude  = fané
UPDATE v1_compat.cor_critere_cflore_v1_to_v2
SET id_nomenclature_cible = ref_nomenclatures.get_id_nomenclature('STADE_VIE','19')
WHERE pk_source IN (7)
AND entity_source = 'v1_compat.bib_phenologies_cflore' AND field_source = 'id_phenologie_cflore' AND entity_target = 'pr_occtax.cor_counting_occtax' AND field_target = 'id_nomenclature_life_stage';



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
SELECT 
    id_cflore AS id_releve_occtax,
    uuid_generate_v4() AS unique_id_sinp_grp,
    id_lot AS id_dataset,
    ref_nomenclatures.get_id_nomenclature('TECHNIQUE_OBS','133') AS id_nomenclature_obs_technique,
    ref_nomenclatures.get_id_nomenclature('TYP_GRP','NSP') ,
    dateobs AS date_min,
    dateobs AS date_max,
    altitude_retenue AS altitude_min,
    altitude_retenue AS altitude_max,
    saisie_initiale AS meta_device_entry, 
    the_geom_local AS geom_local,
    ST_TRANSFORM(the_geom_local, 4326) AS geom_4326,
    50 AS precision
FROM v1_compat.vm_t_t_fiches_cflore cf
;

-- occurrence
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
    n7 AS (SELECT * FROM v1_compat.cor_critere_contactinv_v1_to_v2 WHERE id_type_nomenclature_cible = 7),
    SELECT
    id_releve_cflore AS id_occurrence_occtax,
    uuid_generate_v4() AS unique_id_occurence_occtax,
    id_cflore AS id_releve_occtax,
    -- method_obs = vu
    ref_nomenclatures.get_id_nomenclature('METH_OBS','0') AS id_nomenclature_obs_meth,
    -- etat bio : non renseigné 
    ref_nomenclatures.get_id_nomenclature('ETA_BIO','1') AS id_nomenclature_bio_condition,
    -- statut bio: non renseigné
    ref_nomenclatures.get_id_nomenclature('STATUT_BIO','1') AS id_nomenclature_bio_status,
    -- naturalité: sauvage
    ref_nomenclatures.get_id_nomenclature('NATURALITE','1') AS id_nomenclature_naturalness,
    -- preuve existance: non -- TODO: si presence d'herbier à modifier
    ref_nomenclatures.get_id_nomenclature('PREUVE_EXIST','2') AS id_nomenclature_exist_proof,
    -- prevision diffusion = precise
    ref_nomenclatures.get_id_nomenclature('NIV_PRECIS','5') AS id_nomenclature_diffusion_level,
    -- statut obs: present
    ref_nomenclatures.get_id_nomenclature('STATUT_OBS','Pr') AS id_nomenclature_observation_status,
    -- floutage: non
    ref_nomenclatures.get_id_nomenclature('DEE_FLOU','NON') AS id_nomenclature_blurring,
    -- source: terrain
    ref_nomenclatures.get_id_nomenclature('STATUT_SOURCE','Te') AS id_nomenclature_source_status,
    -- determination = Non renseigné
    NULL AS determiner,
    -- méthode determination: non renseigné
    ref_nomenclatures.get_id_nomenclature('METH_DETERMIN','1') AS id_nomenclature_source_status,
    bib_noms.cd_nom AS cd_nom,
    nom_taxon_saisi AS nom_cite,
    'Taxref V11.0' AS meta_v_taxref,
    NULL AS sample_number_proof,
    NULL AS digital_proof, 
    NULL AS non_digital_proof,
    cflore.commentaire AS comment
    FROM v1_compat.vm_t_releves_cflore cflore
    JOIN taxonomie.bib_noms bib_noms ON bib_noms.id_nom = cflore.id_nom
;



-- faire chaque stade de vie de la phénologie et écrire dans counting
WITH 
... stades_vie

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
id_releve_cflore AS id_occurrence_occtax,
ref_nomenclatures.get_id_nomenclature('STADE_VIE', '2'),
ref_nomenclatures.get_id_nomenclature('SEXE', '0'),
-- TODO objet dénombrement: NSP (touffe, tige, hampe florale ?? ou individu)
ref_nomenclatures.get_id_nomenclature('OBJ_DENBR', 'NSP'),
CASE bib_ab.nom_abondance_cflore
WHEN "1 individu" THEN ref_nomenclatures.get_id_nomenclature('TYP_DENBR', 'Co')
ELSE ref_nomenclatures.get_id_nomenclature('TYP_DENBR', 'Es')
END AS id_nomenclature_type_count,
CASE bib_ab.nom_abondance_cflore
WHEN "1 individu" THEN 1 
WHEN "De 1 à 10 individus" THEN 1
WHEN "De 10 à 100 individus" THEN 10
WHEN "Plus de 100 individus" THEN 100
END AS count_min,
-- TODO: plus de 100 individu ?
CASE bib_ab.nom_abondance_cflore
WHEN "1 individu" THEN 1 
WHEN "De 1 à 10 individus" THEN 10
WHEN "De 10 à 100 individus" THEN 100
WHEN "Plus de 100 individus" THEN 100
END AS count_max
FROM v1_compat.vm_t_releves_cflore cflore
JOIN v1_compat.bib_abondances_cflore ON bib_ab.id_abondance_cflore = cflore.id_abondance_cflore
;