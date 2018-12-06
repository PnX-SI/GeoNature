
SET search_path = utilisateurs, pg_catalog;

-- Insérer les applications de base liées à GeoNature
INSERT INTO t_applications (code_application, nom_application, desc_application, id_parent) VALUES 
('GN', 'GeoNature', 'Application permettant la consultation et la gestion des relevés faune et flore.', NULL)
;
SELECT pg_catalog.setval('t_applications_id_application_seq', (SELECT max(id_application)+1 FROM t_applications), false);	

INSERT INTO cor_profil_for_app (id_profil, id_application) VALUES
(1, (SELECT id_application FROM utilisateurs.t_applications WHERE code_application = 'GN'))
;

INSERT INTO cor_role_app_profil (id_role, id_application, id_profil) VALUES
(9, (SELECT id_application FROM utilisateurs.t_applications WHERE code_application = 'GN'), 1) --Accès à GeoNature (les permissions spécifiques sont gérées dans l'admin GeoNature)
;


--TODO revoir l'insertion des organismes et des identifiants
INSERT INTO t_roles (groupe, identifiant, nom_role, prenom_role, desc_role, pass, email, pn, session_appli, date_insert, date_update, id_organisme, remarques) VALUES 
(true, NULL, 'Grp_socle 2', NULL, 'Socle 2', NULL, NULL, true, NULL, NULL, NULL, NULL, 'Groupe à droit étendu sur les données de son organisme')
,(true, NULL, 'Grp_socle 1', NULL, 'Socle 1', NULL, NULL, true, NULL, NULL, NULL, NULL, 'Groupe à droit limité sur ses données')
;
SELECT pg_catalog.setval('t_roles_id_role_seq', (SELECT max(id_role)+1 FROM t_roles), false);	
