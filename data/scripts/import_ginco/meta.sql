-- creation d'un cadre d'acquisition provisoire pour pouvoir inserer les JDD. On fera le rattachement plus tard grâce au web service MTD

TRUNCATE TABLE gn_meta.t_acquisition_frameworks CASCADE;

INSERT INTO gn_meta.t_acquisition_frameworks (
    acquisition_framework_name,
    acquisition_framework_desc, 
    id_nomenclature_territorial_level, 
    id_nomenclature_financing_type, 
    acquisition_framework_start_date

    ) VALUES (
    'CA provisoire - import Ginco -> GeoNature',
    ' - ',
    ref_nomenclatures.get_id_nomenclature('NIVEAU_TERRITORIAL', '4'),
    ref_nomenclatures.get_id_nomenclature('TYPE_FINANCEMENT', '1'),
    '2019-11-17'
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
    id_dataset,
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
    jdd.id,
    (SELECT id_acquisition_framework FROM gn_meta.t_acquisition_frameworks WHERE acquisition_framework_name = 'CA provisoire - import Ginco -> GeoNature'),
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