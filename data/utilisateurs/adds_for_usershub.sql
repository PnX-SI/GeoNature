
SET search_path = utilisateurs, pg_catalog;

-- Insérer les applications de base liées à GeoNature
INSERT INTO t_applications (code_application, nom_application, desc_application, id_parent) VALUES 
('GN', 'GeoNature', 'Application permettant la consultation et la gestion des relevés faune et flore', NULL)
;
SELECT pg_catalog.setval('t_applications_id_application_seq', (SELECT max(id_application)+1 FROM t_applications), false);	

-- Association du profil Lecteur à GeoNature, necessaire pour donner l'accès à des rôles à GeoNature
INSERT INTO cor_profil_for_app (id_profil, id_application) VALUES
(1, (SELECT id_application FROM utilisateurs.t_applications WHERE code_application = 'GN'))
;

--Accès du GRP_admin et du GRP_en_poste à GeoNature en l'associant au profil Lecteur 
-- Les permissions applicatives (CRUVED) sont gérées dans l'admin GeoNature
INSERT INTO cor_role_app_profil (id_role, id_application, id_profil, is_default_group_for_app) VALUES
(9, (SELECT id_application FROM utilisateurs.t_applications WHERE code_application = 'GN'), 1, false)
,(7, (SELECT id_application FROM utilisateurs.t_applications WHERE code_application = 'GN'), 1, true)
;


--TODO revoir l'insertion des organismes et des identifiants
-- Camille : Est-ce vraiment utile à GN d'avoir ces 2 roles ? 
-- Et l'ID est un serial désormais donc pas besoin de l'incrémenter à la fin...
-- Je commente donc pour le moment
-- INSERT INTO t_roles (groupe, identifiant, nom_role, prenom_role, desc_role, pass, email, pn, session_appli, date_insert, date_update, id_organisme, remarques) VALUES 
-- (true, NULL, 'Grp_socle 2', NULL, 'Socle 2', NULL, NULL, true, NULL, NULL, NULL, NULL, 'Groupe à droit étendu sur les données de son organisme')
-- ,(true, NULL, 'Grp_socle 1', NULL, 'Socle 1', NULL, NULL, true, NULL, NULL, NULL, NULL, 'Groupe à droit limité sur ses données')
-- ;
-- SELECT pg_catalog.setval('t_roles_id_role_seq', (SELECT max(id_role)+1 FROM t_roles), false);	
