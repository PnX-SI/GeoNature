SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

SET search_path = gn_permissions, pg_catalog;
SET default_with_oids = false;


INSERT INTO t_actions(code_action, description_action) VALUES
    ('C', 'Action de créer'),
    ('R', 'Action de lire'),
    ('U', 'Action de mettre à jour'),
    ('V', 'Action de valider'),
    ('E', 'Action d''exporter'),
    ('D', 'Action de supprimer')
;

INSERT INTO bib_filters_type(code_filter_type, description_filter_type) VALUES
    ('SCOPE', 'Filtre de type portée'),
    ('SENSITIVITY', 'Filtre de type sensibilité'),
    ('GEOGRAPHIC', 'Filtre de type géographique')
;

INSERT INTO t_filters (code_filter, description_filter, id_filter_type)
SELECT '0', 'Aucune donnée', id_filter_type
FROM bib_filters_type
WHERE code_filter_type = 'SCOPE';

INSERT INTO t_filters (code_filter, description_filter, id_filter_type)
SELECT '1', 'Mes données', id_filter_type
FROM bib_filters_type
WHERE code_filter_type = 'SCOPE';

INSERT INTO t_filters (code_filter, description_filter, id_filter_type)
SELECT '2', 'Les données de mon organisme', id_filter_type
FROM bib_filters_type
WHERE code_filter_type = 'SCOPE';

INSERT INTO t_filters (code_filter, description_filter, id_filter_type)
SELECT '3', 'Toutes les données', id_filter_type
FROM bib_filters_type
WHERE code_filter_type = 'SCOPE';

INSERT INTO t_objects(code_object, description_object) VALUES 
    ('ALL', 'Représente tous les objets d''un module'),
    ('TDatasets', 'Objet dataset')
;

INSERT INTO cor_object_module (id_object, id_module)
SELECT id_object, t.id_module
FROM t_objects, gn_commons.t_modules t
WHERE code_object = 'TDatasets' AND t.module_code = 'OCCTAX';

INSERT INTO cor_object_module (id_object, id_module)
SELECT id_object, t.id_module
FROM t_objects, gn_commons.t_modules t
WHERE code_object = 'TDatasets' AND t.module_code = 'ADMIN';


INSERT INTO cor_role_action_filter_module_object 
    -- Admin: C:3, R:3, U:3, V:3, E:3, D:3 sur GeoNature
    (1, 1, 4, 3, 1),
    (1, 2, 4, 3, 1),
    (1, 3, 4, 3, 1),
    (1, 4, 4, 3, 1),
    (1, 5, 4, 3, 1),
    (1, 6, 4, 3, 1),
    -- groupe Admin
    (9, 1, 4, 3, 1),
    (9, 2, 4, 3, 1),
    (9, 3, 4, 3, 1),
    (9, 4, 4, 3, 1),
    (9, 5, 4, 3, 1),
    (9, 6, 4, 3, 1),
    --Validateur général sur tout GeoNature
    (5, 4, 4, 3, 1 ),
    --CRUVED du groupe en poste (id=7) sur tout GeoNature 
    (7, 1, 4, 3, 1),
    (7, 2, 3, 3, 1),
    (7, 3, 2, 3, 1),
    (7, 4, 1, 3, 1),
    (7, 5, 3, 3, 1),
    (7, 6, 2, 3, 1),
    --Groupe bureau d''étude socle 2 sur tout GeoNature
    (6, 1, 4, 3, 1),
    (6, 2, 3, 3, 1),
    (6, 3, 2, 3, 1),
    (6, 4, 1, 3, 1),
    (6, 5, 3, 3, 1),
    (6, 6, 2, 3, 1),
    --Groupe bureau d''étude socle 1 sur tout GeoNature
    (8, 1, 4, 3, 1),
    (8, 2, 2, 3, 1),
    (8, 3, 2, 3, 1),
    (8, 4, 2, 3, 1),
    (8, 5, 2, 3, 1),
    (8, 6, 2, 3, 1)
;