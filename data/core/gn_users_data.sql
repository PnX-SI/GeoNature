SET search_path = gn_users, utilisateurs, pg_catalog;

--------
--DATA--
--------
DO
$$
BEGIN
INSERT INTO bib_organismes (id_organisme, nom_organisme, adresse_organisme, cp_organisme, ville_organisme, tel_organisme, fax_organisme, email_organisme, id_parent) VALUES
(1,'PNF', NULL, NULL, 'Montpellier', NULL, NULL, NULL,NULL)
,(2,'Parc National des Ecrins', 'Domaine de Charance', '05000', 'GAP', '04 92 40 20 10', NULL, NULL, NULL)
,(99,'Autres', NULL, NULL, NULL, NULL, NULL, NULL, NULL)
;
PERFORM pg_catalog.setval('t_organisms_id_organism_seq', 3, true);
EXCEPTION WHEN unique_violation THEN RAISE NOTICE 'Tentative d''insertion de valeur existante';
END
$$;

DO
$$
BEGIN
UPDATE bib_organismes SET id_organisme = -1 WHERE id_organisme = 99 AND nom_organisme = 'Autre';
EXCEPTION WHEN unique_violation THEN RAISE NOTICE 'Tentative d''insertion de valeur existante';
END
$$;

DO
$$
BEGIN
INSERT INTO t_roles (groupe, id_role, identifiant, prenom_role, nom_role, desc_role, pass, pass_plus, email, id_organisme, remarques) VALUES
(true, 20001, NULL,  NULL, 'grp_socle 2',  'Bureau d''étude socle 2', NULL, NULL, NULL, NULL, 'Groupe à droit étendu');
PERFORM pg_catalog.setval('t_roles_id_seq', 20002, true);
EXCEPTION WHEN unique_violation THEN RAISE NOTICE 'Tentative d''insertion de valeur existante';
END
$$;

DO
$$
BEGIN
INSERT INTO t_roles (groupe, id_role, identifiant, prenom_role, nom_role, desc_role, pass, pass_plus, email, id_organisme, remarques) VALUES
(true, 20002, NULL, NULL,'grp_en_poste', 'Tous les agents en poste', NULL, NULL, NULL, NULL, 'groupe test à modifier ou supprimer');
PERFORM pg_catalog.setval('t_roles_id_seq', 20003, true);
EXCEPTION WHEN unique_violation THEN RAISE NOTICE 'Tentative d''insertion de valeur existante';
END
$$;

DO
$$
BEGIN
INSERT INTO t_roles (groupe, id_role, identifiant, prenom_role, nom_role, desc_role, pass, pass_plus, email, id_organisme, remarques) VALUES
(true, 20003, NULL,  NULL, 'grp_socle 1',  'Bureau d''étude socle 1', NULL, NULL, NULL, NULL, 'Groupe à droit limité');
PERFORM pg_catalog.setval('t_roles_id_seq', 20004, true);
EXCEPTION WHEN unique_violation THEN RAISE NOTICE 'Tentative d''insertion de valeur existante';
END
$$;

DO
$$
BEGIN
INSERT INTO t_roles (groupe, id_role, identifiant, prenom_role, nom_role, desc_role, pass, pass_plus, email, id_organisme, remarques) VALUES
(false, 1, 'admin', 'Administrateur', 'test', NULL, '21232f297a57a5a743894a0e4a801fc3', NULL, NULL, -1, 'utilisateur test à modifier');
PERFORM pg_catalog.setval('t_roles_id_seq', 20004, true);
EXCEPTION WHEN unique_violation THEN RAISE NOTICE 'Tentative d''insertion de valeur existante';
END
$$;

DO
$$
BEGIN
INSERT INTO t_roles (groupe, id_role, identifiant, prenom_role, nom_role, desc_role, pass, pass_plus, email, id_organisme, remarques) VALUES
(false,2, 'agent', 'Agent', 'test', NULL, 'b33aed8f3134996703dc39f9a7c95783', NULL, NULL, -1,'utilisateur test à modifier ou supprimer');
PERFORM pg_catalog.setval('t_roles_id_seq', 20004, true);
EXCEPTION WHEN unique_violation THEN RAISE NOTICE 'Tentative d''insertion de valeur existante';
END
$$;

DO
$$
BEGIN
INSERT INTO t_roles (groupe, id_role, identifiant, prenom_role, nom_role, desc_role, pass, pass_plus, email, id_organisme, remarques) VALUES
(false,3, 'partenaire', 'Partenaire', 'test', NULL, '5bd40a8524882d75f3083903f2c912fc', NULL, NULL, -1,'utilisateur test à modifier ou supprimer');
PERFORM pg_catalog.setval('t_roles_id_seq', 20004, true);
EXCEPTION WHEN unique_violation THEN RAISE NOTICE 'Tentative d''insertion de valeur existante';
END
$$;

DO
$$
BEGIN
INSERT INTO t_roles (groupe, id_role, identifiant, prenom_role, nom_role, desc_role, pass, pass_plus, email, id_organisme, remarques) VALUES
(false,4, 'pierre.paul', 'Paul', 'Pierre', NULL, '21232f297a57a5a743894a0e4a801fc3', NULL, NULL, -1,'utilisateur test à modifier ou supprimer');
PERFORM pg_catalog.setval('t_roles_id_seq', 20004, true);
EXCEPTION WHEN unique_violation THEN RAISE NOTICE 'Tentative d''insertion de valeur existante';
END
$$;

DO
$$
BEGIN
INSERT INTO t_roles (groupe, id_role, identifiant, prenom_role, nom_role, desc_role, pass, pass_plus, email, id_organisme, remarques) VALUES
(false,5, 'validateur', 'validateur', 'test', NULL, '21232f297a57a5a743894a0e4a801fc3', NULL, NULL, -1,'utilisateur test à modifier ou supprimer');
PERFORM pg_catalog.setval('t_roles_id_seq', 20004, true);
EXCEPTION WHEN unique_violation THEN RAISE NOTICE 'Tentative d''insertion de valeur existante';
END
$$;


DO
$$
BEGIN
INSERT INTO cor_roles (id_role_groupe, id_role_utilisateur) VALUES
(20002, 1);
EXCEPTION WHEN unique_violation THEN RAISE NOTICE 'Tentative d''insertion de valeur existante';
END
$$;

DO
$$
BEGIN
INSERT INTO cor_roles (id_role_groupe, id_role_utilisateur) VALUES
(20002, 2);
EXCEPTION WHEN unique_violation THEN RAISE NOTICE 'Tentative d''insertion de valeur existante';
END
$$;

DO
$$
BEGIN
INSERT INTO cor_roles (id_role_groupe, id_role_utilisateur) VALUES
(20002, 4);
EXCEPTION WHEN unique_violation THEN RAISE NOTICE 'Tentative d''insertion de valeur existante';
END
$$;

DO
$$
BEGIN
INSERT INTO cor_roles (id_role_groupe, id_role_utilisateur) VALUES
(20002, 5);
EXCEPTION WHEN unique_violation THEN RAISE NOTICE 'Tentative d''insertion de valeur existante';
END
$$;


DO
$$
BEGIN
INSERT INTO t_applications (id_application, nom_application, desc_application, id_parent) VALUES
(1, 'UsersHub', 'application permettant d''administrer le contenu du schéma utilisateurs de usershub.', NULL);
PERFORM pg_catalog.setval('t_applications_id_application_seq', 100, true);
EXCEPTION WHEN unique_violation THEN RAISE NOTICE 'Tentative d''insertion de valeur existante';
END
$$;


DO
$$
BEGIN
INSERT INTO t_applications (id_application, nom_application, desc_application, id_parent) VALUES
(2, 'TaxHub', 'application permettant d''administrer la liste des taxons.', NULL);
PERFORM pg_catalog.setval('t_applications_id_application_seq', 100, true);
EXCEPTION WHEN unique_violation THEN RAISE NOTICE 'Tentative d''insertion de valeur existante';
END
$$;

DO
$$
BEGIN
INSERT INTO t_applications (id_application, nom_application, desc_application, id_parent) VALUES
(14, 'application geonature', 'Application permettant la consultation et la gestion des relevés faune et flore.', NULL);
PERFORM pg_catalog.setval('t_applications_id_application_seq', 100, true);
EXCEPTION WHEN unique_violation THEN RAISE NOTICE 'Tentative d''insertion de valeur existante';
END
$$;

DO
$$
BEGIN
INSERT INTO t_applications (id_application, nom_application, desc_application, id_parent) VALUES
(15, 'contact (GeoNature)', 'Module contact faune-flore-fonge de GeoNature', 14);
PERFORM pg_catalog.setval('t_applications_id_application_seq', 100, true);
EXCEPTION WHEN unique_violation THEN RAISE NOTICE 'Tentative d''insertion de valeur existante';
END
$$;

INSERT INTO bib_tag_types(id_tag_type, tag_type_name, tag_type_desc) VALUES
(1, 'object', 'Define a type object. Usualy to defini priviliges on it.')
,(2, 'action', 'Define a type action. Usualy to defini priviliges with it.')
,(3, 'privilege', 'Define a privilege level.')
,(4, 'liste', 'Define a type liste for grouping anythink.')
;


DO
$$
BEGIN
INSERT INTO t_tags (id_tag, id_tag_type, tag_code, tag_name, tag_label, tag_desc) VALUES
(1, 3,'1','utilisateur', 'utilisateur','Ne peut que consulter')
,(2, 3, '2', 'rédacteur', 'rédacteur','Il possède des droit d''écriture pour créer des enregistrements')
,(3, 3, '3', 'référent', 'référent','utilisateur ayant des droits complémentaires au rédacteur (par exemple exporter des données ou autre)')
,(4, 3, '4', 'modérateur', 'modérateur', 'Peu utilisé')
,(5, 3, '5', 'validateur', 'validateur', 'Il valide bien sur')
,(6, 3, '6', 'administrateur', 'administrateur', 'Il a tous les droits')
,(11, 2, 'C', 'create', 'Create', 'can create/add new data')
,(12, 2, 'R', 'read', 'Read', 'can read data')
,(13, 2, 'U', 'update', 'Update', 'can update data')
,(14, 2, 'V', 'validate', 'Validate', 'can validate data')
,(15, 2, 'E', 'export', 'Export', 'can export data')
,(16, 2, 'D', 'delete', 'Delete', 'can delete data')
,(21, 3, '1', 'my data', 'My data', 'can do action only on my data')
,(22, 3, '2', 'my organism data', 'My organism data', 'can do action only on my data and on my organism data')
,(23, 3, '3', 'all data', 'All data', 'can do action on all data')

,(100, 4, NULL, 'observateurs flore', 'Observateurs flore','liste des observateurs pour les protocoles flore')
,(101, 4, NULL, 'observateurs faune', 'Observateurs faune','liste des observateurs pour les protocoles faune')
,(102, 4, NULL, 'observateurs aigle', 'Observateurs aigle', 'liste des observateurs pour le protocole suivi de la reproduction de l''aigle royal')
;
PERFORM pg_catalog.setval('t_tags_id_tag_seq', 104, true);
EXCEPTION WHEN unique_violation  THEN
        RAISE NOTICE 'Tentative d''insertion de valeur existante';
END
$$;

DO
$$
BEGIN
INSERT INTO cor_role_tag (id_role, id_tag) VALUES
--liste des observateurs faune
(1,101)
,(20002,101)
,(5,101)
-- --liste des observateurs flore
,(2,100)
,(5,100)
;
EXCEPTION WHEN unique_violation  THEN
        RAISE NOTICE 'Tentative d''insertion de valeur existante';
END
$$;


DO
$$
BEGIN
INSERT INTO cor_app_privileges (id_tag_action, id_tag_object, id_application, id_role) VALUES
--administrateur sur UsersHub et TaxHub
(6,23,1,1)
,(6,23,2,1)
--administrateur sur GeoNature
,(11, 23, 14, 1)
,(12, 23, 14, 1)
,(13, 23, 14, 1)
,(14, 23, 14, 1)
,(15, 23, 14, 1)
,(16, 23, 14, 1)
--validateur général sur tout GeoNature
,(14, 23, 14, 5)
--validateur pour son organisme sur contact
,(14, 22, 15, 4)
--CRUVED du groupe en poste sur tout GeoNature
,(11, 23, 14, 20002)
,(12, 22, 14, 20002)
,(13, 21, 14, 20002)
,(15, 22, 14, 20002)
,(16, 21, 14, 20002)
--groupe bureau d''étude socle 2 sur tout GeoNature
,(11, 23, 14, 20001)
,(12, 22, 14, 20001)
,(13, 21, 14, 20001)
,(15, 22, 14, 20001)
,(16, 21, 14, 20001)
--groupe bureau d''étude socle 1 sur tout GeoNature
,(11, 23, 14, 20003)
,(12, 21, 14, 20003)
,(13, 21, 14, 20003)
,(15, 21, 14, 20003)
,(16, 21, 14, 20003)
;
EXCEPTION WHEN unique_violation  THEN
        RAISE NOTICE 'Tentative d''insertion de valeur existante';
END
$$;