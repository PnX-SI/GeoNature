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
    ('C', 'Créer (C)'),
    ('R', 'Lire (R)'),
    ('U', 'Mettre à jour (U)'),
    ('V', 'Valider (V)'),
    ('E', 'Exporter (E)'),
    ('D', 'Supprimer (D)')
;

INSERT INTO bib_filters_type
    (code_filter_type, label_filter_type, description_filter_type)
VALUES
    ('SCOPE', 'Permissions de type Portée', 'Filtre de type Portée'),
    ('SENSITIVITY', 'Permissions de type Sensibilité', 'Permission de type Sensibilité'),
    ('GEOGRAPHIC', 'Permissions de type Géographique', 'Ajouter des id_area séparés par des virgules'),
    ('TAXONOMIC', 'Permissions de type Taxonomique', 'Ajouter des cd_nom séparés par des virgules')
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
    ('185961', 'Les oiseaux', 'Filtre taxonomique sur les oiseaux - classe Aves', 4),
    ('DONNEES_DEGRADEES', 'Données dégradées', 'Filtre pour afficher les données sensibles dégradées/floutées à l''utilisateur', 2),
    ('DONNEES_PRECISES', 'Données précises', 'Filtre qui affiche les données sensibles  précises à l''utilisateur', 2)
;

INSERT INTO t_objects
    (code_object, description_object)
VALUES
    ('ALL', 'Représente tous les objets d''un module'),
    ('PERMISSIONS', 'Gestion du backoffice des permissions'),
    ('NOMENCLATURES', 'Gestion du backoffice des nomenclatures')
;

INSERT INTO cor_object_module
    (id_object, id_module)
VALUES
    (2, 1),
    (3, 1)
;

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
    (9, 1, 4, 0, 1),
    (9, 2, 4, 0, 1),
    (9, 3, 4, 0, 1),
    (9, 4, 4, 0, 1),
    (9, 5, 4, 0, 1),
    (9, 6, 4, 0, 1),
    --Validateur général sur tout GeoNature
    (5, 4, 4, 0, 1 ),
    --CRUVED du groupe en poste (id=7) sur tout GeoNature 
    (7, 1, 4, 0, 1),
    (7, 2, 3, 0, 1),
    (7, 3, 2, 0, 1),
    (7, 4, 1, 0, 1),
    (7, 5, 3, 0, 1),
    (7, 6, 2, 0, 1),
    -- Groupe admin a tous les droit dans METADATA
    (9, 1, 4, 2, 1),
    (9, 2, 4, 2, 1),
    (9, 3, 4, 2, 1),
    (9, 4, 4, 2, 1),
    (9, 5, 4, 2, 1),
    (9, 6, 4, 2, 1),
    -- Groupe en poste acces limité a dans METADATA
    (7, 1, 1, 2, 1),
    (7, 2, 3, 2, 1),
    (7, 3, 1, 2, 1),
    (7, 4, 1, 2, 1),
    (7, 5, 3, 2, 1),
    (7, 6, 1, 2, 1),
    -- Groupe en poste, n'a pas accès à l'admin
    (7, 1, 1, 1, 1),
    (7, 2, 1, 1, 1),
    (7, 3, 1, 1, 1),
    (7, 4, 1, 1, 1),
    (7, 5, 1, 1, 1),
    (7, 6, 1, 1, 1),
    -- Groupe en admin a tous les droits sur l'admin
    (9, 1, 4, 1, 1),
    (9, 2, 4, 1, 1),
    (9, 3, 4, 1, 1),
    (9, 4, 4, 1, 1),
    (9, 5, 4, 1, 1),
    (9, 6, 4, 1, 1),
    -- Groupe ADMIN peut gérer les permissions depuis le backoffice
    (9, 1, 4, 1, 2),
    (9, 2, 4, 1, 2),
    (9, 3, 4, 1, 2),
    (9, 4, 4, 1, 2),
    (9, 5, 4, 1, 2),
    (9, 6, 4, 1, 2),
    -- Groupe ADMIN peut gérer les nomenclatures depuis le backoffice
    (9, 1, 4, 1, 3),
    (9, 2, 4, 1, 3),
    (9, 3, 4, 1, 3),
    (9, 4, 4, 1, 3),
    (9, 5, 4, 1, 3),
    (9, 6, 4, 1, 3)
;

