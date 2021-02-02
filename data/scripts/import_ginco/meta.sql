-- creation d'un cadre d'acquisition provisoire pour pouvoir inserer les JDD. On fera le rattachement plus tard grâce au web service MTD

TRUNCATE TABLE gn_meta.t_acquisition_frameworks CASCADE;

INSERT INTO gn_meta.t_acquisition_frameworks (
    acquisition_framework_name,
    acquisition_framework_desc, 
    id_nomenclature_territorial_level, 
    id_nomenclature_financing_type, 
    acquisition_framework_start_date,
    meta_create_date,
    meta_update_date

    ) VALUES (
    'CA provisoire - import Ginco -> GeoNature',
    ' - ',
    ref_nomenclatures.get_id_nomenclature('NIVEAU_TERRITORIAL', '4'),
    ref_nomenclatures.get_id_nomenclature('TYPE_FINANCEMENT', '1'),
    '2019-11-17',
    NOW(),
    NOW()
    )
;

WITH jdd_uuid AS (
    SELECT 
    value_string as uuid,
    jdd_id
    FROM ginco_migration.jdd_field field
    WHERE field.key = 'metadataId'
),
jdd_name AS (
    SELECT 
    value_string as jdd_name,
    jdd_id
    FROM ginco_migration.jdd_field field
    WHERE field.key = 'title'
)
INSERT INTO gn_meta.t_datasets (
    unique_dataset_id,
    id_acquisition_framework,
    dataset_name,
    dataset_shortname,
    dataset_desc,
    marine_domain,
    terrestrial_domain,
    active,
    validable,
    meta_create_date,
    id_nomenclature_data_type,
    id_nomenclature_dataset_objectif,
    id_nomenclature_collecting_method,
    id_nomenclature_data_origin,
    id_nomenclature_source_status,
    id_nomenclature_resource_type
    )
    SELECT
    jdd_uuid.uuid::uuid,
    (SELECT id_acquisition_framework FROM gn_meta.t_acquisition_frameworks WHERE acquisition_framework_name = 'CA provisoire - import Ginco -> GeoNature' LIMIT 1),
    jdd_name.jdd_name,
    'A compléter',
    'A compléter',
    false,
    true,
    true,
    true,
    '2019-11-17',
    ref_nomenclatures.get_id_nomenclature('DATA_TYP', '2'),
    ref_nomenclatures.get_id_nomenclature('JDD_OBJECTIFS', '7.2'),
    ref_nomenclatures.get_id_nomenclature('METHO_RECUEIL', '12'),
    ref_nomenclatures.get_id_nomenclature('DS_PUBLIQUE', 'NSP'),
    ref_nomenclatures.get_id_nomenclature('STATUT_SOURCE', 'NSP'),
    ref_nomenclatures.get_id_nomenclature('RESOURCE_TYP', '1')
    FROM ginco_migration.jdd jdd
    JOIN jdd_uuid ON jdd_uuid.jdd_id = jdd.id
    JOIN jdd_name ON jdd_name.jdd_id = jdd.id
    where status != 'deleted'
;

-- set submission date
update gn_meta.t_acquisition_frameworks as af
set initial_closing_date = subquery.date_max
from (
with jdd_uuid as (
select j.id, jf.value_string as _uuid
from ginco_migration.jdd j 
join ginco_migration.jdd_field jf on jf.jdd_id = j.id
where jf.key = 'metadataId'
)
select max(TO_TIMESTAMP(value_string, 'YYYY-MM-DD_HH24-MI-SS')) as date_max, taf.id_acquisition_framework 
from ginco_migration.jdd j 
join ginco_migration.jdd_field jf on jf.jdd_id = j.id
join jdd_uuid u on u.id = j.id
join gn_meta.t_datasets td on u._uuid::uuid = td.unique_dataset_id 
join gn_meta.t_acquisition_frameworks taf on taf.id_acquisition_framework = td.id_acquisition_framework 
where jf."key" = 'publishedAt'
group by  taf.id_acquisition_framework 
) as subquery 
where af.id_acquisition_framework = subquery.id_acquisition_framework and af.initial_closing_date is NULL





SELECT pg_catalog.setval('gn_meta.t_datasets_id_dataset_seq', (SELECT max(id_dataset)+1 FROM gn_meta.t_datasets), true);
