SET statement_timeout
= 0;
SET lock_timeout
= 0;
SET client_encoding
= 'UTF8';
SET standard_conforming_strings
= on;
SET check_function_bodies
= false;
SET client_min_messages
= warning;

SET search_path
= gn_permissions, pg_catalog;
SET default_with_oids
= false;


INSERT INTO t_actions
    (code_action, description_action)
VALUES
    ('C', 'Action de créer (C)'),
    ('R', 'Action de lire (R)'),
    ('U', 'Action de mettre à jour (U)'),
    ('V', 'Action de valider (V)'),
    ('E', 'Action d''exporter (E)'),
    ('D', 'Action de supprimer (D)')
;

INSERT INTO bib_filters_type
    (code_filter_type, label_filter_type, description_filter_type)
VALUES
    ('SCOPE', 'Permissions de type portée', 'Filtre de type portée'),
    ('SENSITIVITY', 'Permissions de type sensibilité', 'Permission de type sensibilité'),
    ('GEOGRAPHIC', 'Permissions de type géographique', 'Ajouter des id_area séparés par des virgules'),
    ('TAXONOMIC', 'Permissions de type taxonomique', 'Ajouter des cd_nom séparés par des virgules')
;

INSERT INTO t_filters
    (value_filter, label_filter, description_filter, id_filter_type)
SELECT '0', 'Aucune donnée', 'Aucune donnée', id_filter_type
FROM gn_permissions.bib_filters_type
WHERE code_filter_type = 'SCOPE';

INSERT INTO t_filters
    (value_filter, label_filter, description_filter, id_filter_type)
SELECT '1', 'Mes données', 'Mes données', id_filter_type
FROM gn_permissions.bib_filters_type
WHERE code_filter_type = 'SCOPE';

INSERT INTO t_filters
    (value_filter, label_filter, description_filter, id_filter_type)
SELECT '2', 'Les données de mon organisme', 'Les données de mon organisme', id_filter_type
FROM gn_permissions.bib_filters_type
WHERE code_filter_type = 'SCOPE';

INSERT INTO t_filters
    (value_filter, label_filter, description_filter, id_filter_type)
SELECT '3', 'Toutes les données', 'Toutes les données', id_filter_type
FROM gn_permissions.bib_filters_type
WHERE code_filter_type = 'SCOPE';

INSERT INTO t_filters
    (value_filter, label_filter, description_filter, id_filter_type)
VALUES
    ('61098', 'Les bouquetins', 'Filtre taxonomique sur les bouquetins', 4),
    ('DONNEES_DEGRADEES', 'Données dégradées', 'Filtre pour afficher les données sensibles dégradées/floutées à l''utilisateur', 2),
    ('DONNEES_PRECISES', 'Données précises', 'Filtre qui affiche les données sensibles  précises à l''utilisateur', 3)
;

INSERT INTO t_objects
    (code_object, description_object)
VALUES
    ('ALL', 'Représente tous les objets d''un module'),
    ('METADATA', 'Gestion du backoffice des métadonnées'),
    ('PERMISSIONS', 'Gestion du backoffice des permissions')
;

INSERT INTO cor_object_module
    (id_object, id_module)
VALUES
    (2, 4),
    (3, 4)
;

INSERT INTO cor_object_module
    (id_object, id_module)
SELECT o.id_object, t.id_module
FROM gn_permissions.t_objects o, gn_commons.t_modules t
WHERE o.code_object = 'TDatasets' AND t.module_code = 'ADMIN';


INSERT INTO cor_role_action_filter_module_object
    (
    id_role,
    id_action,
    id_filter,
    id_module,
    id_object
    )
VALUES
    -- Groupe Admin
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
    (8, 6, 2, 3, 1),
    -- ADMIN peut gérer les permissions du backoffice
    (9, 1, 4, 4, 3),
    (9, 2, 4, 4, 3),
    (9, 3, 4, 4, 3),
    (9, 4, 4, 4, 3),
    (9, 5, 4, 4, 3),
    (9, 6, 4, 4, 3),
    -- ADMIN peut gérer les métadonnées du backoffice
    (9, 1, 4, 4, 2),
    (9, 2, 4, 4, 2),
    (9, 3, 4, 4, 2),
    (9, 4, 4, 4, 2),
    (9, 5, 4, 4, 2),
    (9, 6, 4, 4, 2)
;
