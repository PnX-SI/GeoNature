SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
---------
--DATAS--
---------
-- Ajout des utilisateurs de test pour import
DO $$
DECLARE id_organisme_admin INT;
id_organisme_agent INT;
BEGIN
SELECT id_organisme INTO id_organisme_admin
FROM utilisateurs.bib_organismes
WHERE nom_organisme = 'ma structure test';
SELECT id_organisme into id_organisme_agent
FROM utilisateurs.bib_organismes
WHERE nom_organisme = 'Autre';
-- Step 2: Insert data
INSERT INTO utilisateurs.t_roles (
        groupe,
        identifiant,
        nom_role,
        prenom_role,
        desc_role,
        pass,
        email,
        date_insert,
        date_update,
        id_organisme,
        remarques,
        pass_plus
    )
VALUES (
        false,
        'admin-test-import',
        'Administrateur-test-import',
        NULL,
        NULL,
        '21232f297a57a5a743894a0e4a801fc3',
        -- MD5 of 'admin'
        NULL,
        NULL,
        NULL,
        id_organisme_admin,
        'utilisateur test à modifier',
        '$2y$13$TMuRXgvIg6/aAez0lXLLFu0lyPk4m8N55NDhvLoUHh/Ar3rFzjFT.'
    ),
    (
        false,
        'agent-test-import',
        'Agent-test-import',
        NULL,
        NULL,
        'b33aed8f3134996703dc39f9a7c95783',
        -- MD5 of 'agent'
        NULL,
        NULL,
        NULL,
        id_organisme_agent,
        'utilisateur test à modifier ou supprimer',
        '$2b$12$ItumBAShoFbLe.vluoIlZOeVQPoR/rkaW4xRVuqx48npwEt.WMJYe'
    );
END $$;
INSERT INTO utilisateurs.cor_roles (id_role_groupe, id_role_utilisateur)
VALUES (
        (
            SELECT id_role
            FROM utilisateurs.t_roles
            WHERE nom_role = 'Grp_admin'
        ),
        (
            SELECT id_role
            FROM utilisateurs.t_roles
            WHERE identifiant = 'admin-test-import'
        )
    );
-- Insert role agent-test-import into cor_role_app_profil
INSERT INTO utilisateurs.cor_role_app_profil (id_role, id_application, id_profil)
SELECT (
        SELECT id_role
        FROM utilisateurs.t_roles
        WHERE identifiant = 'agent-test-import'
    ) AS id_role,
    app.id_application,
    profils.id_profil
FROM (
        SELECT id_application
        FROM utilisateurs.t_applications
        WHERE code_application = 'GN'
    ) AS app,
    (
        SELECT id_profil
        FROM utilisateurs.t_profils
        WHERE nom_profil LIKE 'Lecteur'
    ) AS profils ON CONFLICT DO NOTHING;
-- Ajout des permissions aux utilisateurs de tests
-- Insert permissions for admin-test-import
INSERT INTO gn_permissions.t_permissions (
        id_role,
        id_action,
        id_module,
        id_object,
        scope_value
    )
SELECT tr.id_role,
    ba.id_action,
    tm.id_module,
    t_o.id_object,
    NULL AS scope_value
FROM (
        SELECT id_role
        FROM utilisateurs.t_roles
        WHERE identifiant = 'admin-test-import'
    ) tr,
    (
        SELECT id_action
        FROM gn_permissions.bib_actions
        WHERE code_action IN ('C', 'R', 'U', 'D')
    ) ba,
    (
        SELECT id_module
        FROM gn_commons.t_modules
        WHERE module_code = 'IMPORT'
    ) tm,
    (
        SELECT id_object
        FROM gn_permissions.t_objects
        WHERE code_object IN ('IMPORT', 'MAPPING')
    ) t_o;
-- Insert permissions for agent-test-import
INSERT INTO gn_permissions.t_permissions (
        id_role,
        id_action,
        id_module,
        id_object,
        scope_value
    )
SELECT tr.id_role,
    ba.id_action,
    tm.id_module,
    t_o.id_object,
    1 AS scope_value
FROM (
        SELECT id_role
        FROM utilisateurs.t_roles
        WHERE identifiant = 'agent-test-import'
    ) tr,
    (
        SELECT id_action
        FROM gn_permissions.bib_actions
        WHERE code_action IN ('C', 'R', 'U', 'D')
    ) ba,
    (
        SELECT id_module
        FROM gn_commons.t_modules
        WHERE module_code = 'IMPORT'
    ) tm,
    (
        SELECT id_object
        FROM gn_permissions.t_objects
        WHERE code_object IN ('IMPORT', 'MAPPING')
    ) t_o;

-- Insert permissions for agent-test-import
INSERT INTO gn_permissions.t_permissions (
        id_role,
        id_action,
        id_module,
        id_object,
        scope_value
    )
SELECT tr.id_role,
    ba.id_action,
    tm.id_module,
    t_o.id_object,
    1 AS scope_value
FROM (
        SELECT id_role
        FROM utilisateurs.t_roles
        WHERE identifiant = 'agent-test-import'
    ) tr,
    (
        SELECT id_action
        FROM gn_permissions.bib_actions
        WHERE code_action IN ('C', 'R', 'U', 'D')
    ) ba,
    (
        SELECT id_module
        FROM gn_commons.t_modules
        WHERE module_code = 'SYNTHESE'
    ) tm,
    (
        SELECT id_object
        FROM gn_permissions.t_objects
        WHERE code_object IN ('ALL')
    ) t_o;

-- Insert permissions for agent-test-import
INSERT INTO gn_permissions.t_permissions (
        id_role,
        id_action,
        id_module,
        id_object,
        scope_value
    )
SELECT tr.id_role,
    ba.id_action,
    tm.id_module,
    t_o.id_object,
    1 AS scope_value
FROM (
        SELECT id_role
        FROM utilisateurs.t_roles
        WHERE identifiant = 'agent-test-import'
    ) tr,
    (
        SELECT id_action
        FROM gn_permissions.bib_actions
        WHERE code_action IN ('R')
    ) ba,
    (
        SELECT id_module
        FROM gn_commons.t_modules
        WHERE module_code = 'METADATA'
    ) tm,
    (
        SELECT id_object
        FROM gn_permissions.t_objects
        WHERE code_object IN ('ALL')
    ) t_o;

-- Ajout du module occhab si non présent
INSERT INTO gn_commons.t_modules (
        module_code,
        module_label,
        module_path,
        active_frontend,
        active_backend,
        ng_module
    )
SELECT 'OCCHAB',
    'Occhab',
    'occhab',
    true,
    false,
    'OCCHAB'
WHERE NOT EXISTS (
        SELECT 1
        FROM gn_commons.t_modules
        WHERE module_code = 'OCCHAB'
    );
-- ajout des tables de destinations
INSERT INTO gn_imports.bib_destinations (id_module, code, "label", table_name)
SELECT (
        SELECT id_module
        FROM gn_commons.t_modules
        WHERE module_code = 'OCCHAB'
    ),
    'occhab',
    'Occhab',
    't_imports_occhab'
WHERE NOT EXISTS (
        SELECT 1
        FROM gn_imports.bib_destinations
        WHERE code = 'occhab'
    )
UNION ALL
SELECT (
        SELECT id_module
        FROM gn_commons.t_modules
        WHERE module_code = 'SYNTHESE'
    ),
    'synthese',
    'Synthese',
    't_imports_synthese'
WHERE NOT EXISTS (
        SELECT 1
        FROM gn_imports.bib_destinations
        WHERE code = 'synthese'
    );
---- Ajouter permissions disponibles pour les nouveau module
INSERT INTO gn_permissions.t_permissions_available (
        id_module,
        id_object,
        id_action,
        label,
        scope_filter
    )
SELECT m.id_module,
    o.id_object,
    a.id_action,
    v.label,
    v.scope_filter
FROM (
        VALUES ('OCCHAB', 'ALL', 'C', True, 'Créer des habitats'),
            ('OCCHAB', 'ALL', 'R', True, 'Voir les habitats'),
            (
                'OCCHAB',
                'ALL',
                'U',
                True,
                'Modifier les habitats'
            ),
            (
                'OCCHAB',
                'ALL',
                'D',
                True,
                'Supprimer des habitats'
            ),
            (
                'OCCHAB',
                'ALL',
                'E',
                True,
                'Exporter des habitats'
            )
    ) AS v (
        module_code,
        object_code,
        action_code,
        scope_filter,
        label
    )
    JOIN gn_commons.t_modules m ON m.module_code = v.module_code
    JOIN gn_permissions.t_objects o ON o.code_object = v.object_code
    JOIN gn_permissions.bib_actions a ON a.code_action = v.action_code ON CONFLICT DO NOTHING;
-- Insérer un cadre d'acquisition d'exemple
INSERT INTO gn_meta.t_acquisition_frameworks (
        unique_acquisition_framework_id,
        acquisition_framework_name,
        acquisition_framework_desc,
        id_nomenclature_territorial_level,
        territory_desc,
        keywords,
        id_nomenclature_financing_type,
        target_description,
        ecologic_or_geologic_target,
        acquisition_framework_parent_id,
        is_parent,
        acquisition_framework_start_date,
        acquisition_framework_end_date,
        meta_create_date,
        meta_update_date
    )
VALUES (
        '5b054340-210c-4350-9034-300543210c43',
        'CA-1-TEST-IMPORT',
        'CA-1-TEST-IMPORT',
        ref_nomenclatures.get_id_nomenclature('NIVEAU_TERRITORIAL', '4'),
        'Territoire du Parc national des Ecrins correspondant au massif alpin des Ecrins',
        'Ecrins, parc national, faune, flore, fonge',
        ref_nomenclatures.get_id_nomenclature('TYPE_FINANCEMENT', '1'),
        'Tous les taxons',
        null,
        null,
        false,
        '1973-03-27',
        null,
        '2018-09-01 10:35:08',
        null
    );
;
INSERT INTO gn_meta.t_acquisition_frameworks (
        unique_acquisition_framework_id,
        acquisition_framework_name,
        acquisition_framework_desc,
        id_nomenclature_territorial_level,
        territory_desc,
        keywords,
        id_nomenclature_financing_type,
        target_description,
        ecologic_or_geologic_target,
        acquisition_framework_parent_id,
        is_parent,
        acquisition_framework_start_date,
        acquisition_framework_end_date,
        meta_create_date,
        meta_update_date
    )
VALUES (
        '7a2b3c4d-5e6f-4a3b-2c1d-e6f5a4b3c2d1',
        'CA-1-TEST-IMPORT-empty',
        'CA-1-TEST-IMPORT-empty',
        ref_nomenclatures.get_id_nomenclature('NIVEAU_TERRITORIAL', '4'),
        'Test',
        'flore, fonge',
        ref_nomenclatures.get_id_nomenclature('TYPE_FINANCEMENT', '1'),
        'Tous les taxons',
        null,
        null,
        false,
        '2002-03-27',
        null,
        '2022-09-01 10:35:08',
        null
    );
-- Insérer 2 jeux de données d'exemple
INSERT INTO gn_meta.t_datasets (
        id_dataset,
        unique_dataset_id,
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
VALUES (
        9999,
        '9f86d081-8292-466e-9e7b-16f3960d255f',
        (
            SELECT id_acquisition_framework
            FROM gn_meta.t_acquisition_frameworks
            WHERE unique_acquisition_framework_id = '5b054340-210c-4350-9034-300543210c43'
        ),
        'JDD-TEST-IMPORT-ADMIN',
        'Jeu de données - test import admin',
        'JDD-TEST-IMPORT-ADMIN',
        ref_nomenclatures.get_id_nomenclature('DATA_TYP', '1'),
        'Aléatoire, hors protocole, faune, flore, fonge',
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
    ),
    (
        9998,
        '2f543d86-ec4e-4f1a-b4d9-123456789abc',
        (
            SELECT id_acquisition_framework
            FROM gn_meta.t_acquisition_frameworks
            WHERE unique_acquisition_framework_id = '5b054340-210c-4350-9034-300543210c43'
        ),
        'JDD-TEST-IMPORT-2',
        'Jeu de données - test import 2',
        'Jeu de données - test import 2',
        ref_nomenclatures.get_id_nomenclature('DATA_TYP', '1'),
        'Aléatoire, ATBI, biodiversité, faune, flore, fonge',
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
        '2018-09-01 16:59:03.25687',
        null
    ),
    (
        9997,
        'a1b2c3d4-e5f6-4a3b-2c1d-e6f5a4b3c2d1',
        (
            SELECT id_acquisition_framework
            FROM gn_meta.t_acquisition_frameworks
            WHERE unique_acquisition_framework_id = '5b054340-210c-4350-9034-300543210c43'
        ),
        'JDD-TEST-IMPORT-3',
        'Jeu de données - test import 3',
        'Jeu de données - test import 3',
        ref_nomenclatures.get_id_nomenclature('DATA_TYP', '1'),
        'Aléatoire, hors protocole, faune, flore, fonge',
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
    ),
    (
        9996,
        '5f45d560-1ce3-420c-b45c-3d589eedaee1',
        (
            SELECT id_acquisition_framework
            FROM gn_meta.t_acquisition_frameworks
            WHERE unique_acquisition_framework_id = '5b054340-210c-4350-9034-300543210c43'
        ),
        'JDD-TEST-IMPORT-INACTIF',
        'Jeu de données - test import inactif',
        'Jeu de données - test import inactif',
        ref_nomenclatures.get_id_nomenclature('DATA_TYP', '1'),
        'Aléatoire, hors protocole, faune, flore, fonge',
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
        false,
        true,
        '2018-09-01 16:57:44.45879',
        null
    );
-- ajout des JDD dans les modules IMPORT et IMPORT dupliqué
INSERT INTO gn_commons.cor_module_dataset (id_module, id_dataset)
VALUES (
        (
            SELECT id_module
            FROM gn_commons.t_modules
            WHERE module_code = 'IMPORT'
        ),
        (
            SELECT id_dataset
            FROM gn_meta.t_datasets
            WHERE unique_dataset_id = '9f86d081-8292-466e-9e7b-16f3960d255f'
        )
    ),
    (
        (
            SELECT id_module
            FROM gn_commons.t_modules
            WHERE module_code = 'IMPORT'
        ),
        (
            SELECT id_dataset
            FROM gn_meta.t_datasets
            WHERE unique_dataset_id = '2f543d86-ec4e-4f1a-b4d9-123456789abc'
        )
    ),
    (
        (
            SELECT id_module
            FROM gn_commons.t_modules
            WHERE module_code = 'IMPORT'
        ),
        (
            SELECT id_dataset
            FROM gn_meta.t_datasets
            WHERE unique_dataset_id = 'a1b2c3d4-e5f6-4a3b-2c1d-e6f5a4b3c2d1'
        )
    ),
    (
        (
            SELECT id_module
            FROM gn_commons.t_modules
            WHERE module_code = 'OCCHAB'
        ),
        (
            SELECT id_dataset
            FROM gn_meta.t_datasets
            WHERE unique_dataset_id = '9f86d081-8292-466e-9e7b-16f3960d255f'
        )
    ),
    (
        (
            SELECT id_module
            FROM gn_commons.t_modules
            WHERE module_code = 'SYNTHESE'
        ),
        (
            SELECT id_dataset
            FROM gn_meta.t_datasets
            WHERE unique_dataset_id = '9f86d081-8292-466e-9e7b-16f3960d255f'
        )
    ),
    (
        (
            SELECT id_module
            FROM gn_commons.t_modules
            WHERE module_code = 'IMPORT'
        ),
        (
            SELECT id_dataset
            FROM gn_meta.t_datasets
            WHERE unique_dataset_id = '5f45d560-1ce3-420c-b45c-3d589eedaee1'
        )
    ),
    (
        (
            SELECT id_module
            FROM gn_commons.t_modules
            WHERE module_code = 'SYNTHESE'
        ),
        (
            SELECT id_dataset
            FROM gn_meta.t_datasets
            WHERE unique_dataset_id = '2f543d86-ec4e-4f1a-b4d9-123456789abc'
        )
    );
-- Renseigner les tables de correspondance
INSERT INTO gn_meta.cor_acquisition_framework_voletsinp (
        id_acquisition_framework,
        id_nomenclature_voletsinp
    )
VALUES (
        (
            SELECT id_acquisition_framework
            FROM gn_meta.t_acquisition_frameworks
            WHERE unique_acquisition_framework_id = '5b054340-210c-4350-9034-300543210c43'
        ),
        ref_nomenclatures.get_id_nomenclature('VOLET_SINP', '1')
    );
INSERT INTO gn_meta.cor_acquisition_framework_objectif (
        id_acquisition_framework,
        id_nomenclature_objectif
    )
VALUES (
        (
            SELECT id_acquisition_framework
            FROM gn_meta.t_acquisition_frameworks
            WHERE unique_acquisition_framework_id = '5b054340-210c-4350-9034-300543210c43'
        ),
        ref_nomenclatures.get_id_nomenclature('CA_OBJECTIFS', '8')
    );
INSERT INTO gn_meta.cor_acquisition_framework_actor (
        id_acquisition_framework,
        id_role,
        id_organism,
        id_nomenclature_actor_role
    )
VALUES (
        (
            SELECT id_acquisition_framework
            FROM gn_meta.t_acquisition_frameworks
            WHERE unique_acquisition_framework_id = '5b054340-210c-4350-9034-300543210c43'
        ),
        NULL,
        (
            SELECT id_organisme
            FROM utilisateurs.bib_organismes
            WHERE nom_organisme = 'ma structure test'
        ),
        ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR', '1')
    ),
    (
        (
            SELECT id_acquisition_framework
            FROM gn_meta.t_acquisition_frameworks
            WHERE unique_acquisition_framework_id = '5b054340-210c-4350-9034-300543210c43'
        ),
        NULL,
        (
            SELECT id_organisme
            FROM utilisateurs.bib_organismes
            WHERE nom_organisme = 'ma structure test'
        ),
        ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR', '6')
    ),
    (
        (
            SELECT id_acquisition_framework
            FROM gn_meta.t_acquisition_frameworks
            WHERE unique_acquisition_framework_id = '5b054340-210c-4350-9034-300543210c43'
        ),
        NULL,
        (
            SELECT id_organisme
            FROM utilisateurs.bib_organismes
            WHERE nom_organisme = 'ma structure test'
        ),
        ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR', '8')
    );
INSERT INTO gn_meta.cor_dataset_actor (
        id_dataset,
        id_role,
        id_organism,
        id_nomenclature_actor_role
    )
VALUES (
        (
            SELECT id_dataset
            FROM gn_meta.t_datasets
            WHERE unique_dataset_id = '9f86d081-8292-466e-9e7b-16f3960d255f'
        ),
        (
            SELECT id_role
            FROM utilisateurs.t_roles
            WHERE identifiant = 'admin-test-import'
        ),
        (
            SELECT id_organisme
            FROM utilisateurs.bib_organismes
            WHERE nom_organisme = 'ma structure test'
        ),
        ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR', '1')
    ),
    (
        (
            SELECT id_dataset
            FROM gn_meta.t_datasets
            WHERE unique_dataset_id = '9f86d081-8292-466e-9e7b-16f3960d255f'
        ),
        NULL,
        (
            SELECT id_organisme
            FROM utilisateurs.bib_organismes
            WHERE nom_organisme = 'ma structure test'
        ),
        ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR', '6')
    ),
    (
        (
            SELECT id_dataset
            FROM gn_meta.t_datasets
            WHERE unique_dataset_id = '2f543d86-ec4e-4f1a-b4d9-123456789abc'
        ),
        NULL,
        (
            SELECT id_organisme
            FROM utilisateurs.bib_organismes
            WHERE nom_organisme = 'ma structure test'
        ),
        ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR', '1')
    ),
    (
        (
            SELECT id_dataset
            FROM gn_meta.t_datasets
            WHERE unique_dataset_id = '2f543d86-ec4e-4f1a-b4d9-123456789abc'
        ),
        NULL,
        (
            SELECT id_organisme
            FROM utilisateurs.bib_organismes
            WHERE nom_organisme = 'ma structure test'
        ),
        ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR', '6')
    ),
    (
        (
            SELECT id_dataset
            FROM gn_meta.t_datasets
            WHERE unique_dataset_id = '2f543d86-ec4e-4f1a-b4d9-123456789abc'
        ),
        (
            SELECT id_role
            FROM utilisateurs.t_roles
            WHERE identifiant = 'admin-test-import'
        ),
        NULL,
        ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR', '8')
    ),
    (
        (
            SELECT id_dataset
            FROM gn_meta.t_datasets
            WHERE unique_dataset_id = '2f543d86-ec4e-4f1a-b4d9-123456789abc'
        ),
        (
            SELECT id_role
            FROM utilisateurs.t_roles
            WHERE identifiant = 'agent-test-import'
        ),
        NULL,
        ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR', '5')
    ),
    (
        (
            SELECT id_dataset
            FROM gn_meta.t_datasets
            WHERE unique_dataset_id = '2f543d86-ec4e-4f1a-b4d9-123456789abc'
        ),
        NULL,
        (
            SELECT id_organisme
            FROM utilisateurs.bib_organismes
            WHERE nom_organisme = 'Autre'
        ),
        ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR', '6')
    ),
    (
        (
            SELECT id_dataset
            FROM gn_meta.t_datasets
            WHERE unique_dataset_id = 'a1b2c3d4-e5f6-4a3b-2c1d-e6f5a4b3c2d1'
        ),
        (
            SELECT id_role
            FROM utilisateurs.t_roles
            WHERE identifiant = 'admin-test-import'
        ),
        (
            SELECT id_organisme
            FROM utilisateurs.bib_organismes
            WHERE nom_organisme = 'ma structure test'
        ),
        ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR', '1')
    ),
    (
        (
            SELECT id_dataset
            FROM gn_meta.t_datasets
            WHERE unique_dataset_id = '5f45d560-1ce3-420c-b45c-3d589eedaee1'
        ),
        (
            SELECT id_role
            FROM utilisateurs.t_roles
            WHERE identifiant = 'admin-test-import'
        ),
        (
            SELECT id_organisme
            FROM utilisateurs.bib_organismes
            WHERE nom_organisme = 'ma structure test'
        ),
        ref_nomenclatures.get_id_nomenclature('ROLE_ACTEUR', '1')
    );
INSERT INTO gn_meta.cor_dataset_territory (
        id_dataset,
        id_nomenclature_territory,
        territory_desc
    )
VALUES (
        (
            SELECT id_dataset
            FROM gn_meta.t_datasets
            WHERE unique_dataset_id = '9f86d081-8292-466e-9e7b-16f3960d255f'
        ),
        ref_nomenclatures.get_id_nomenclature('TERRITOIRE', 'METROP'),
        'Territoire du parc national des Ecrins et de ses environs immédiats'
    ),
    (
        (
            SELECT id_dataset
            FROM gn_meta.t_datasets
            WHERE unique_dataset_id = '2f543d86-ec4e-4f1a-b4d9-123456789abc'
        ),
        ref_nomenclatures.get_id_nomenclature('TERRITOIRE', 'METROP'),
        'Réserve intégrale de lauvitel'
    );
INSERT INTO gn_meta.cor_dataset_protocol (id_dataset, id_protocol)
VALUES (
        (
            SELECT id_dataset
            FROM gn_meta.t_datasets
            WHERE unique_dataset_id = '9f86d081-8292-466e-9e7b-16f3960d255f'
        ),
        (
            SELECT id_protocol
            FROM gn_meta.sinp_datatype_protocols
            WHERE protocol_name = 'hors protocole'
        )
    ),
    (
        (
            SELECT id_dataset
            FROM gn_meta.t_datasets
            WHERE unique_dataset_id = '2f543d86-ec4e-4f1a-b4d9-123456789abc'
        ),
        (
            SELECT id_protocol
            FROM gn_meta.sinp_datatype_protocols
            WHERE protocol_name = 'hors protocole'
        )
    );
-- #On peuple la liste d'import
INSERT INTO gn_imports.t_imports (
        id_import,
        id_dataset,
        id_destination,
        format_source_file,
        srid,
        separator,
        encoding,
        full_file_name,
        source_count,
        uuid_autogenerated,
        altitude_autogenerated,
        date_min_data,
        date_max_data,
        fieldmapping,
        contentmapping,
        detected_separator,
        task_id,
        erroneous_rows
    )
VALUES (
        1000,
        (
            SELECT id_dataset
            FROM gn_meta.t_datasets
            WHERE unique_dataset_id = '2f543d86-ec4e-4f1a-b4d9-123456789abc'
        ),
        (
            SELECT id_destination
            FROM gn_imports.bib_destinations
            WHERE code = 'synthese'
        ),
        'CSV',
        4326,
        ';',
        'UTF-8',
        'valid_file_test_link_list_import_synthese.csv',
        100,
        true,
        true,
        '2022-01-01 00:00:00',
        '2022-12-31 23:59:59',
        '{"entity_source_pk_value": "id_synthese", "unique_id_sinp": "uuid_perm_sinp", "meta_create_date": "date_creation", "meta_update_date": "date_modification", "id_nomenclature_grp_typ": "type_regroupement", "unique_id_sinp_grp": "uuid_perm_grp_sinp", "date_min": "date_debut", "date_max": "date_fin", "hour_min": "heure_debut", "hour_max": "heure_fin", "altitude_min": "alti_min", "altitude_max": "alti_max", "depth_min": "prof_min", "depth_max": "prof_max", "observers": "observateurs", "comment_context": "comment_releve", "WKT": "geometrie_wkt_4326", "id_nomenclature_geo_object_nature": "nature_objet_geo", "place_name": "nom_lieu", "precision": "precision_geographique", "cd_hab": "cd_habref", "grp_method": "methode_regroupement", "nom_cite": "nom_cite", "cd_nom": "cd_nom", "id_nomenclature_obs_technique": "technique_observation", "id_nomenclature_bio_status": "biologique_statut", "id_nomenclature_bio_condition": "etat_biologique", "id_nomenclature_biogeo_status": "biogeographique_statut", "id_nomenclature_naturalness": "naturalite", "comment_description": "comment_occurrence", "id_nomenclature_sensitivity": "niveau_sensibilite", "id_nomenclature_diffusion_level": "niveau_precision_diffusion", "id_nomenclature_observation_status": "statut_observation", "id_nomenclature_blurring": "floutage_dee", "id_nomenclature_source_status": "statut_source", "reference_biblio": "reference_biblio", "id_nomenclature_behaviour": "comportement", "id_nomenclature_life_stage": "stade_vie", "id_nomenclature_sex": "sexe", "id_nomenclature_type_count": "type_denombrement", "id_nomenclature_obj_count": "objet_denombrement", "count_min": "nombre_min", "count_max": "nombre_max", "id_nomenclature_determination_method": "methode_determination", "determiner": "determinateur", "id_nomenclature_exist_proof": "preuve_existante", "digital_proof": "preuve_numerique_url", "non_digital_proof": "preuve_non_numerique", "id_nomenclature_valid_status": "niveau_validation", "validator": "validateur", "meta_validation_date": "date_validation", "validation_comment": "comment_validation"}',
        '{"OCC_COMPORTEMENT": {"Non renseign\u00e9": "1"}, "ETA_BIO": {"Non renseign\u00e9": "1"}, "STATUT_BIO": {"Non renseign\u00e9": "1"}, "STAT_BIOGEO": {"Non renseign\u00e9": "1"}, "DEE_FLOU": {"Non": "NON"}, "METH_DETERMIN": {"Autre m\u00e9thode de d\u00e9termination": "2"}, "NIV_PRECIS": {"Pr\u00e9cise": "5"}, "PREUVE_EXIST": {"Oui": "1"}, "NAT_OBJ_GEO": {"Inventoriel": "In"}, "TYP_GRP": {"OBS": "OBS"}, "STADE_VIE": {"Adulte": "2", "Immature": "4", "Juv\u00e9nile": "3"}, "NATURALITE": {"Sauvage": "1"}, "OBJ_DENBR": {"Individu": "IND"}, "METH_OBS": {"Galerie/terrier": "23"}, "STATUT_OBS": {"Pr\u00e9sent": "Pr"}, "SENSIBILITE": {"Non sensible - Diffusion pr\u00e9cise": "0"}, "SEXE": {"Femelle": "2"}, "STATUT_SOURCE": {"Terrain": "Te"}, "TYP_DENBR": {"Compt\u00e9": "Co"}, "STATUT_VALID": {"En attente de validation": "0"}}',
        ';',
        NULL,
        '{5}'
    ),
    (
        1001,
        (
            SELECT id_dataset
            FROM gn_meta.t_datasets
            WHERE unique_dataset_id = '9f86d081-8292-466e-9e7b-16f3960d255f'
        ),
        (
            SELECT id_destination
            FROM gn_imports.bib_destinations
            WHERE code = 'occhab'
        ),
        'CSV',
        4326,
        ';',
        'UTF-8',
        'valid_file_test_import_occhab.csv',
        100,
        95,
        true,
        true,
        '2022-01-01 00:00:00',
        '2022-12-31 23:59:59',
        '{"date_min": "date_min", "cd_hab": "cd_hab", "nom_cite": "nom_cite"}',
        '{}',
        ';',
        NULL,
        '{}'
    ),
    (
        1002,
        (
            SELECT id_dataset
            FROM gn_meta.t_datasets
            WHERE unique_dataset_id = 'a1b2c3d4-e5f6-4a3b-2c1d-e6f5a4b3c2d1'
        ),
        (
            SELECT id_destination
            FROM gn_imports.bib_destinations
            WHERE code = 'synthese'
        ),
        'CSV',
        4326,
        ';',
        'UTF-8',
        'valid_file_test_import_synthese.csv',
        100,
        95,
        true,
        true,
        '2022-01-01 00:00:00',
        '2022-12-31 23:59:59',
        '{"entity_source_pk_value": "id_synthese", "unique_id_sinp": "uuid_perm_sinp", "meta_create_date": "date_creation", "meta_update_date": "date_modification", "id_nomenclature_grp_typ": "type_regroupement", "unique_id_sinp_grp": "uuid_perm_grp_sinp", "date_min": "date_debut", "date_max": "date_fin", "hour_min": "heure_debut", "hour_max": "heure_fin", "altitude_min": "alti_min", "altitude_max": "alti_max", "depth_min": "prof_min", "depth_max": "prof_max", "observers": "observateurs", "comment_context": "comment_releve", "WKT": "geometrie_wkt_4326", "id_nomenclature_geo_object_nature": "nature_objet_geo", "place_name": "nom_lieu", "precision": "precision_geographique", "cd_hab": "cd_habref", "grp_method": "methode_regroupement", "nom_cite": "nom_cite", "cd_nom": "cd_nom", "id_nomenclature_obs_technique": "technique_observation", "id_nomenclature_bio_status": "biologique_statut", "id_nomenclature_bio_condition": "etat_biologique", "id_nomenclature_biogeo_status": "biogeographique_statut", "id_nomenclature_naturalness": "naturalite", "comment_description": "comment_occurrence", "id_nomenclature_sensitivity": "niveau_sensibilite", "id_nomenclature_diffusion_level": "niveau_precision_diffusion", "id_nomenclature_observation_status": "statut_observation", "id_nomenclature_blurring": "floutage_dee", "id_nomenclature_source_status": "statut_source", "reference_biblio": "reference_biblio", "id_nomenclature_behaviour": "comportement", "id_nomenclature_life_stage": "stade_vie", "id_nomenclature_sex": "sexe", "id_nomenclature_type_count": "type_denombrement", "id_nomenclature_obj_count": "objet_denombrement", "count_min": "nombre_min", "count_max": "nombre_max", "id_nomenclature_determination_method": "methode_determination", "determiner": "determinateur", "id_nomenclature_exist_proof": "preuve_existante", "digital_proof": "preuve_numerique_url", "non_digital_proof": "preuve_non_numerique", "id_nomenclature_valid_status": "niveau_validation", "validator": "validateur", "meta_validation_date": "date_validation", "validation_comment": "comment_validation"}',
        '{"OCC_COMPORTEMENT": {"Non renseign\u00e9": "1"}, "ETA_BIO": {"Non renseign\u00e9": "1"}, "STATUT_BIO": {"Non renseign\u00e9": "1"}, "STAT_BIOGEO": {"Non renseign\u00e9": "1"}, "DEE_FLOU": {"Non": "NON"}, "METH_DETERMIN": {"Autre m\u00e9thode de d\u00e9termination": "2"}, "NIV_PRECIS": {"Pr\u00e9cise": "5"}, "PREUVE_EXIST": {"Oui": "1"}, "NAT_OBJ_GEO": {"Inventoriel": "In"}, "TYP_GRP": {"OBS": "OBS"}, "STADE_VIE": {"Adulte": "2", "Immature": "4", "Juv\u00e9nile": "3"}, "NATURALITE": {"Sauvage": "1"}, "OBJ_DENBR": {"Individu": "IND"}, "METH_OBS": {"Galerie/terrier": "23"}, "STATUT_OBS": {"Pr\u00e9sent": "Pr"}, "SENSIBILITE": {"Non sensible - Diffusion pr\u00e9cise": "0"}, "SEXE": {"Femelle": "2"}, "STATUT_SOURCE": {"Terrain": "Te"}, "TYP_DENBR": {"Compt\u00e9": "Co"}, "STATUT_VALID": {"En attente de validation": "0"}}',
        ';',
        NULL,
        '{5}'
    ),
    (
        1003,
        (
            SELECT id_dataset
            FROM gn_meta.t_datasets
            WHERE unique_dataset_id = '5f45d560-1ce3-420c-b45c-3d589eedaee1'
        ),
        (
            SELECT id_destination
            FROM gn_imports.bib_destinations
            WHERE code = 'synthese'
        ),
        'CSV',
        4326,
        ';',
        'UTF-8',
        'valid_file_test_import_synthese.csv',
        100,
        95,
        true,
        true,
        '2022-01-01 00:00:00',
        '2022-12-31 23:59:59',
        '{"entity_source_pk_value": "id_synthese", "unique_id_sinp": "uuid_perm_sinp", "meta_create_date": "date_creation", "meta_update_date": "date_modification", "id_nomenclature_grp_typ": "type_regroupement", "unique_id_sinp_grp": "uuid_perm_grp_sinp", "date_min": "date_debut", "date_max": "date_fin", "hour_min": "heure_debut", "hour_max": "heure_fin", "altitude_min": "alti_min", "altitude_max": "alti_max", "depth_min": "prof_min", "depth_max": "prof_max", "observers": "observateurs", "comment_context": "comment_releve", "WKT": "geometrie_wkt_4326", "id_nomenclature_geo_object_nature": "nature_objet_geo", "place_name": "nom_lieu", "precision": "precision_geographique", "cd_hab": "cd_habref", "grp_method": "methode_regroupement", "nom_cite": "nom_cite", "cd_nom": "cd_nom", "id_nomenclature_obs_technique": "technique_observation", "id_nomenclature_bio_status": "biologique_statut", "id_nomenclature_bio_condition": "etat_biologique", "id_nomenclature_biogeo_status": "biogeographique_statut", "id_nomenclature_naturalness": "naturalite", "comment_description": "comment_occurrence", "id_nomenclature_sensitivity": "niveau_sensibilite", "id_nomenclature_diffusion_level": "niveau_precision_diffusion", "id_nomenclature_observation_status": "statut_observation", "id_nomenclature_blurring": "floutage_dee", "id_nomenclature_source_status": "statut_source", "reference_biblio": "reference_biblio", "id_nomenclature_behaviour": "comportement", "id_nomenclature_life_stage": "stade_vie", "id_nomenclature_sex": "sexe", "id_nomenclature_type_count": "type_denombrement", "id_nomenclature_obj_count": "objet_denombrement", "count_min": "nombre_min", "count_max": "nombre_max", "id_nomenclature_determination_method": "methode_determination", "determiner": "determinateur", "id_nomenclature_exist_proof": "preuve_existante", "digital_proof": "preuve_numerique_url", "non_digital_proof": "preuve_non_numerique", "id_nomenclature_valid_status": "niveau_validation", "validator": "validateur", "meta_validation_date": "date_validation", "validation_comment": "comment_validation"}',
        '{"OCC_COMPORTEMENT": {"Non renseign\u00e9": "1"}, "ETA_BIO": {"Non renseign\u00e9": "1"}, "STATUT_BIO": {"Non renseign\u00e9": "1"}, "STAT_BIOGEO": {"Non renseign\u00e9": "1"}, "DEE_FLOU": {"Non": "NON"}, "METH_DETERMIN": {"Autre m\u00e9thode de d\u00e9termination": "2"}, "NIV_PRECIS": {"Pr\u00e9cise": "5"}, "PREUVE_EXIST": {"Oui": "1"}, "NAT_OBJ_GEO": {"Inventoriel": "In"}, "TYP_GRP": {"OBS": "OBS"}, "STADE_VIE": {"Adulte": "2", "Immature": "4", "Juv\u00e9nile": "3"}, "NATURALITE": {"Sauvage": "1"}, "OBJ_DENBR": {"Individu": "IND"}, "METH_OBS": {"Galerie/terrier": "23"}, "STATUT_OBS": {"Pr\u00e9sent": "Pr"}, "SENSIBILITE": {"Non sensible - Diffusion pr\u00e9cise": "0"}, "SEXE": {"Femelle": "2"}, "STATUT_SOURCE": {"Terrain": "Te"}, "TYP_DENBR": {"Compt\u00e9": "Co"}, "STATUT_VALID": {"En attente de validation": "0"}}',
        ';',
        NULL,
        '{5}'
    );
--  On peuple les tables de correspondances - Ajout des roles lié aux imports 
CREATE TEMP TABLE temp_filtered_imports AS
SELECT ti.id_import,
    ti.id_dataset
FROM gn_imports.t_imports ti
    JOIN gn_meta.t_datasets td ON ti.id_dataset = td.id_dataset
WHERE td.dataset_name ILIKE '%JDD-TEST-IMPORT%';
INSERT INTO gn_imports.cor_role_import (id_role, id_import)
SELECT cda.id_role,
    tfi.id_import
FROM temp_filtered_imports tfi
    JOIN gn_meta.cor_dataset_actor cda ON tfi.id_dataset = cda.id_dataset
WHERE cda.id_role IS NOT NULL;
DROP TABLE temp_filtered_imports;
