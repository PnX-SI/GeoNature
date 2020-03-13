


-- update champs nom_organisme trop petit
SELECT gn_commons.deps_save_and_drop_dependencies('utilisateurs', 'bib_organismes');
ALTER TABLE utilisateurs.bib_organismes ALTER COLUMN nom_organisme TYPE character varying(255);
SELECT gn_commons.deps_restore_dependencies('utilisateurs', 'bib_organismes');

TRUNCATE utilisateurs.t_roles CASCADE;
TRUNCATE utilisateurs.bib_organismes CASCADE;

INSERT INTO utilisateurs.bib_organismes(
            id_organisme, uuid_organisme, nom_organisme)
SELECT 
id::integer,
COALESCE(uuid::uuid, uuid_generate_v4()),
label
FROM ginco_migration.providers;

SELECT setval('utilisateurs.bib_organismes_id_organisme_seq', (SELECT max(id_organisme)+1 FROM utilisateurs.bib_organismes), true);

INSERT INTO utilisateurs.t_roles (
    groupe,
    identifiant,
    nom_role,
    pass,
    email,
    id_organisme,
    date_insert
)
SELECT 
    false,
    user_login,
    user_name,
    user_password,
    email,
    provider_id::integer,
    created_at
 FROM ginco_migration.users;
SELECT setval('utilisateurs.t_roles_id_role_seq', (SELECT max(id_role)+1 FROM utilisateurs.t_roles), true);

-- insertion des groupes
INSERT INTO utilisateurs.t_roles (groupe, nom_role, desc_role)
SELECT true, role_label, role_definition
FROM ginco_migration.role;

-- insertion des utilisateur dans les groupes
WITH role_group AS 
(
    SELECT 
    r1.id_role as id_role_grp,
    r2.role_code
    FROM utilisateurs.t_roles r1 
    JOIN ginco_migration.role r2 ON r2.role_label = r1.nom_role
    WHERE groupe IS true
)
INSERT INTO utilisateurs.cor_roles
SELECT g.id_role_grp, t.id_role
FROM ginco_migration.role_to_user ru
JOIN utilisateurs.t_roles t ON t.identifiant = ru.user_login
JOIN role_group g ON g.role_code = ru.role_code;

-- Insertion de données pour pouvoir se connecter sans CAS

-- Insertion d'un organisme factice
INSERT INTO utilisateurs.bib_organismes (nom_organisme, adresse_organisme, cp_organisme, ville_organisme, tel_organisme, fax_organisme, email_organisme, id_organisme) VALUES 
('Autre', '', '', '', '', '', '', -1)
;
-- Insertion d'un user admin/admin pour pouvoir continuer à se connecter
INSERT INTO utilisateurs.t_roles (groupe, identifiant, nom_role, prenom_role, desc_role, pass, email, date_insert, date_update, id_organisme, remarques, pass_plus) VALUES 
(false,
'admin', 'Administrateur', 'test', NULL, '21232f297a57a5a743894a0e4a801fc3',
 NULL, NULL, NULL, -1, 'utilisateur test à modifier', '$2y$13$TMuRXgvIg6/aAez0lXLLFu0lyPk4m8N55NDhvLoUHh/Ar3rFzjFT.')
;

-- ajout dans le groupe ginco 'administrateur'
INSERT INTO utilisateurs.cor_roles
VALUES (
(SELECT id_role FROM utilisateurs.t_roles WHERE nom_role = 'Administrateur' AND groupe IS true),
(SELECT id_role FROM utilisateurs.t_roles WHERE identifiant = 'admin')
);

-- droit de connection à GeoNature
INSERT INTO utilisateurs.cor_role_app_profil
VALUES (
    (SELECT id_role FROM utilisateurs.t_roles WHERE nom_role = 'Administrateur' AND groupe IS true),
    (SELECT id_application FROM utilisateurs.t_applications WHERE code_application = 'GN'),
    1
);



