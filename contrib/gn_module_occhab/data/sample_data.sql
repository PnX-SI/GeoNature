BEGIN;

DELETE FROM ref_habitats.bib_list_habitat WHERE list_name = 'Liste test occhab';
INSERT INTO ref_habitats.bib_list_habitat(list_name) VALUES ('Liste test occhab');
SELECT pg_catalog.setval('ref_habitats.bib_list_habitat_id_list_seq', (SELECT max(id_list)+1 FROM ref_habitats.bib_list_habitat), true);

DELETE FROM ref_habitats.cor_list_habitat 
WHERE id_list IN (
  select id_list FROM ref_habitats.bib_list_habitat WHERE list_name = 'Liste test occhab'
  );

-- ajout de tout habref dans cette liste
INSERT INTO ref_habitats.cor_list_habitat(id_list, cd_hab) 
SELECT b.id_list, cd_hab
FROM ref_habitats.habref h, ref_habitats.bib_list_habitat b
WHERE b.list_name = 'Liste test occhab'
;


INSERT INTO gn_meta.t_acquisition_frameworks (
    acquisition_framework_name, 
    acquisition_framework_desc, 
    id_nomenclature_territorial_level, 
    keywords, 
    id_nomenclature_financing_type, 
    target_description, 
    ecologic_or_geologic_target, 
    acquisition_framework_parent_id, 
    is_parent, 
    acquisition_framework_start_date, 
    acquisition_framework_end_date
    ) VALUES (
    'Données d''habitats',
    'Données d''habitats',
    ref_nomenclatures.get_id_nomenclature('NIVEAU_TERRITORIAL', '4'),
    'Habitat',
    ref_nomenclatures.get_id_nomenclature('TYPE_FINANCEMENT', '1'),
    'Habitat',
    null,
    null,
    false,
    '1973-03-27',
    null
    )
;

-- Insérer 1 jeux de données d'exemple
INSERT INTO gn_meta.t_datasets (
    id_acquisition_framework,
    dataset_name,
    dataset_shortname,
    dataset_desc,
    id_nomenclature_data_type,
    keywords,
    marine_domain,
    terrestrial_domain,
    id_nomenclature_dataset_objectif,
    bbox_west,
    bbox_east,
    bbox_south,
    bbox_north,
    id_nomenclature_collecting_method,
    id_nomenclature_data_origin,
    id_nomenclature_source_status,
    id_nomenclature_resource_type,
    active,
    validable,
    meta_create_date,
    meta_update_date
    )
    VALUES
    (
     (SELECT id_acquisition_framework FROM gn_meta.t_acquisition_frameworks WHERE acquisition_framework_name='Données d''habitats' LIMIT 1),
    'Carto d''habitat X',
    'Carto d''habitat X',
    'Carto d''habitat X',
    ref_nomenclatures.get_id_nomenclature('DATA_TYP', '1'),
    'Habitat',
    false,
    true,
    ref_nomenclatures.get_id_nomenclature('JDD_OBJECTIFS', '1.1'),
    4.85695,
    6.85654,
    44.5020,
    45.25,
    ref_nomenclatures.get_id_nomenclature('METHO_RECUEIL', '1'),
    ref_nomenclatures.get_id_nomenclature('DS_PUBLIQUE', 'Pu'),
    ref_nomenclatures.get_id_nomenclature('STATUT_SOURCE', 'Te'),
    ref_nomenclatures.get_id_nomenclature('RESOURCE_TYP', '1'),
    true,
    true,
    '2018-09-01 16:57:44.45879',
    null
    )
;

COMMIT;

-- Renseignement des tables de correspondance

BEGIN;

INSERT INTO gn_meta.cor_dataset_actor (id_dataset, id_role, id_organism, id_nomenclature_actor_role) VALUES
((SELECT id_dataset FROM gn_meta.t_datasets WHERE dataset_name='Carto d''habitat X' LIMIT 1)
  , NULL, 1, ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR', '1'))
;


INSERT INTO gn_commons.cor_module_dataset (id_module, id_dataset)
SELECT gn_commons.get_id_module_bycode('OCCHAB'), id_dataset
FROM gn_meta.t_datasets
WHERE dataset_name='Carto d''habitat X';

COMMIT;
