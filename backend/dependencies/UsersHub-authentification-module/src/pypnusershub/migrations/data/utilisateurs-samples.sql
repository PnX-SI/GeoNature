---------------
--SAMPLE DATA--
---------------

SET search_path = utilisateurs, pg_catalog, public;

-- Insertion de 2 organismes 
INSERT INTO bib_organismes (nom_organisme, adresse_organisme, cp_organisme, ville_organisme, tel_organisme, fax_organisme, email_organisme, id_organisme) VALUES 
('Autre', '', '', '', '', '', '', -1)
;
INSERT INTO bib_organismes (nom_organisme, adresse_organisme, cp_organisme, ville_organisme, tel_organisme) VALUES 
('ma structure test', 'Rue des bois', '00000', 'VILLE', '00-00-99-00-99');

-- Insertion de roles de type GROUPE de base pour GeoNature
--TODO revoir l'insertion des organisme et des identifiants
INSERT INTO t_roles (groupe, identifiant, nom_role, prenom_role, desc_role, pass, email, date_insert, date_update, id_organisme, remarques) VALUES 
(true, NULL, 'Grp_en_poste', NULL, 'Tous les agents en poste dans la structure', NULL, NULL, NULL, NULL, NULL, 'Groupe des agents de la structure avec droits d''écriture limité')
,(true, NULL, 'Grp_admin', NULL, 'Tous les administrateurs', NULL, NULL, NULL, NULL, NULL, 'Groupe à droit total')
;
-- Insertion de roles de type UTILISATEUR pour GeoNature
INSERT INTO t_roles (groupe, identifiant, nom_role, prenom_role, desc_role, pass, email, date_insert, date_update, id_organisme, remarques, pass_plus) VALUES 
(
    false,
    'admin',
    'Administrateur',
    'test',
    NULL,
    '21232f297a57a5a743894a0e4a801fc3',
    NULL,
    NULL,
    NULL,
    (SELECT id_organisme FROM utilisateurs.bib_organismes WHERE nom_organisme = 'Autre'),
    'utilisateur test à modifier',
    '$2y$13$TMuRXgvIg6/aAez0lXLLFu0lyPk4m8N55NDhvLoUHh/Ar3rFzjFT.'
),(
    false,
    'agent',
    'Agent',
    'test',
    NULL,
    'b33aed8f3134996703dc39f9a7c95783',
    NULL,
    NULL,
    NULL,
    (SELECT id_organisme FROM utilisateurs.bib_organismes WHERE nom_organisme = 'Autre'),
    'utilisateur test à modifier ou supprimer',
    NULL
),(
    false,
    'partenaire',
    'Partenaire',
    'test',
    NULL,
    '5bd40a8524882d75f3083903f2c912fc',
    NULL,
    NULL,
    NULL,
    (SELECT id_organisme FROM utilisateurs.bib_organismes WHERE nom_organisme = 'Autre'),
    'utilisateur test à modifier ou supprimer',
    NULL
),(
    false,
    'pierre.paul',
    'Paul',
    'Pierre',
    NULL,
    '21232f297a57a5a743894a0e4a801fc3',
    NULL,
    NULL,
    NULL,
    (SELECT id_organisme FROM utilisateurs.bib_organismes WHERE nom_organisme = 'Autre'),
    'utilisateur test à modifier ou supprimer',
    NULL
),(
    false,
    'validateur',
    'Validateur',
    'test',
    NULL,
    '21232f297a57a5a743894a0e4a801fc3',
    NULL,
    NULL,
    NULL,
    (SELECT id_organisme FROM utilisateurs.bib_organismes WHERE nom_organisme = 'Autre'),
    'utilisateur test à modifier ou supprimer',
    NULL
);

-- Affectation des utilisateurs exemple dans des groupes
INSERT INTO cor_roles (id_role_groupe, id_role_utilisateur) VALUES 
(
    (SELECT id_role FROM t_roles WHERE nom_role = 'Grp_en_poste'),
    (SELECT id_role FROM t_roles WHERE identifiant = 'admin')
)
,
(
    (SELECT id_role FROM t_roles WHERE nom_role = 'Grp_admin'),
    (SELECT id_role FROM t_roles WHERE identifiant = 'admin')
)
,
(
    (SELECT id_role FROM t_roles WHERE nom_role = 'Grp_en_poste'),
    (SELECT id_role FROM t_roles WHERE identifiant = 'agent')
)
,
(
    (SELECT id_role FROM t_roles WHERE nom_role = 'Grp_en_poste'),
    (SELECT id_role FROM t_roles WHERE identifiant = 'pierre.paul')
)
,
(
    (SELECT id_role FROM t_roles WHERE nom_role = 'Grp_en_poste'),
    (SELECT id_role FROM t_roles WHERE identifiant = 'validateur')
)
;
