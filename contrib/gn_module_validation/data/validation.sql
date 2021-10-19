SET client_encoding = 'UTF8';

-- ----------------------------------------------------------------------
-- Add available Validation permissions

-- ----------------------------------------------------------------------
-- VALIDATION - CR---- - ALL - SCOPE
INSERT INTO gn_permissions.cor_module_action_object_filter (
    id_module, id_action, id_object, id_filter_type, code, label, description
) 
    SELECT
        gn_commons.get_id_module_bycode('VALIDATION'),
        gn_permissions.get_id_action('C'),
        gn_permissions.get_id_object('ALL'),
        gn_permissions.get_id_filter_type('SCOPE'),
        'VALIDATION-C-ALL-SCOPE',
        'Créer des données',
        'Créer des données dans le module Validation en étant limité par l''appartenance.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.cor_module_action_object_filter AS cmaof
        WHERE cmaof.code = 'VALIDATION-C-ALL-SCOPE'
    ) ;

INSERT INTO gn_permissions.cor_module_action_object_filter (
    id_module, id_action, id_object, id_filter_type, code, label, description
) 
    SELECT
        gn_commons.get_id_module_bycode('VALIDATION'),
        gn_permissions.get_id_action('R'),
        gn_permissions.get_id_object('ALL'),
        gn_permissions.get_id_filter_type('SCOPE'),
        'VALIDATION-R-ALL-SCOPE',
        'Lire des données',
        'Lire des données dans le module Validation en étant limité par l''appartenance.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.cor_module_action_object_filter AS cmaof
        WHERE cmaof.code = 'VALIDATION-R-ALL-SCOPE'
    ) ;
