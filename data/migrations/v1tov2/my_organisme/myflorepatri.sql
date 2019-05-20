---------------------------------------------------------------------------------------------------------------------
--début de travail pour un cron maintenant à jour la synthese PNE à jour depuis les données issues de la base du rezo
---------------------------------------------------------------------------------------------------------------------

--données nouvelles (à ajouter dans la synthese)
WITH updated_rows_in_synthese AS(
    SELECT ap.indexap, ap.indexzp
    FROM gn_synthese.synthese s
    JOIN v1_florepatri.vm_t_apresence_rezo ap ON ap.indexap = s.entity_source_pk_value::integer
    JOIN v1_florepatri.vm_t_zprospection_rezo zp ON zp.indexzp = ap.indexzp AND zp.id_organisme = 2
    WHERE s.id_source = 104
    AND (
            ap.date_insert > (SELECT last_update FROM v1_florepatri.synchro_rezo)
            OR
            zp.date_insert > (SELECT last_update FROM v1_florepatri.synchro_rezo)
    )
),
fp_rezo AS (
    SELECT
      uuid_generate_v4() AS unique_id_sinp,
      104 AS id_source,
      ap.indexap::character varying AS entity_source_pk_value,
      104 AS id_dataset,
        --nomenclatures TODO
      1 AS count_min,
      null AS count_max,
      zp.cd_nom

      FROM v1_florepatri.vm_t_apresence_rezo ap 
      JOIN v1_florepatri.vm_t_zprospection_rezo zp ON zp.indexzp = ap.indexzp AND zp.id_organisme = 2
      JOIN updated_rows_in_synthese u ON u.indexap = ap.indexap
)
SELECT indexap
FROM v1_florepatri.vm_t_apresence_rezo ap 
JOIN fp_rezo f ON f.entity_source_pk_value = ap.indexap::character varying
JOIN v1_florepatri.vm_t_zprospection_rezo zp ON zp.indexzp = ap.indexzp
WHERE indexap NOT IN()
;
--données existantes en synthese mais mises à jour coté rézo
WITH updated_rows_in_synthese AS(
    SELECT ap.indexap, ap.indexzp
    FROM gn_synthese.synthese s
    JOIN v1_florepatri.vm_t_apresence_rezo ap ON ap.indexap = s.entity_source_pk_value::integer
    JOIN v1_florepatri.vm_t_zprospection_rezo zp ON zp.indexzp = ap.indexzp AND zp.id_organisme = 2
    WHERE s.id_source = 104
    AND (
            ap.date_update > (SELECT last_update FROM v1_florepatri.synchro_rezo)
            OR
            zp.date_update > (SELECT last_update FROM v1_florepatri.synchro_rezo)
    )
),
fp_rezo AS (
    SELECT
      uuid_generate_v4() AS unique_id_sinp,
      104 AS id_source,
      ap.indexap::character varying AS entity_source_pk_value,
      104 AS id_dataset,
        --nomenclatures TODO
      1 AS count_min,
      null AS count_max,
      zp.cd_nom

      FROM v1_florepatri.vm_t_apresence_rezo ap 
      JOIN v1_florepatri.vm_t_zprospection_rezo zp ON zp.indexzp = ap.indexzp AND zp.id_organisme = 2
      JOIN updated_rows_in_synthese u ON u.indexap = ap.indexap
)
SELECT indexap
FROM v1_florepatri.vm_t_apresence_rezo ap 
JOIN fp_rezo f ON f.entity_source_pk_value = ap.indexap::character varying
JOIN v1_florepatri.vm_t_zprospection_rezo zp ON zp.indexzp = ap.indexzp
WHERE indexap NOT IN()
;
UPDATE v1_florepatri.synchro_rezo SET last_update = now();

