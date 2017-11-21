SET search_path = gn_users, utilisateurs, pg_catalog;

--------
--DATA--
--------
DO
$$
BEGIN
INSERT INTO bib_gn_data_types (id_gn_data_type, gn_data_type_name, gn_data_type_desc) VALUES
(1,'my data','user data')
,(2,'my organization data', 'data that''s owned by the user''s organization')
,(3,'all data', 'All the data that is contained in this GeoNaute instance')
;
EXCEPTION WHEN unique_violation THEN RAISE NOTICE 'Tentative d''insertion de valeur existante';
END
$$;


DO
$$
BEGIN
INSERT INTO bib_gn_actions (id_gn_action, gn_action_code, gn_action_name, gn_action_desc) VALUES
(1,'C','create','can create/add new data')
,(2,'R','read', 'can read data')
,(3,'U','update', 'can edit data')
,(4,'V','validate', 'can validate data')
,(5,'E','export', 'can export data')
,(6,'D','delete', 'can delete data')
;
EXCEPTION WHEN unique_violation THEN RAISE NOTICE 'Tentative d''insertion de valeur existante';
END
$$;


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
INSERT INTO t_roles (groupe, id_role, identifiant, prenom_role, nom_role, desc_role, pass, pass_sha, email, id_organisme, remarques) VALUES
(true, 20001, NULL, 'grp_bureau_etude', NULL, 'Bureau d''étude', NULL, NULL, NULL, -1, 'groupe test à modifier ou supprimer');
PERFORM pg_catalog.setval('t_roles_id_seq', 20002, true);
EXCEPTION WHEN unique_violation THEN RAISE NOTICE 'Tentative d''insertion de valeur existante';
END
$$;

DO
$$
BEGIN
INSERT INTO t_roles (groupe, id_role, identifiant, prenom_role, nom_role, desc_role, pass, pass_sha, email, id_organisme, remarques) VALUES
(true, 20002, NULL, 'grp_en_poste', NULL, 'Tous les agents en poste', NULL, NULL, NULL, -1, 'groupe test à modifier ou supprimer');
PERFORM pg_catalog.setval('t_roles_id_seq', 20002, true);
EXCEPTION WHEN unique_violation THEN RAISE NOTICE 'Tentative d''insertion de valeur existante';
END
$$;

DO
$$
BEGIN
INSERT INTO t_roles (groupe, id_role, identifiant, prenom_role, nom_role, desc_role, pass, pass_sha, email, id_organisme, remarques) VALUES
(false, 1, 'admin', 'Administrateur', 'test', NULL, '21232f297a57a5a743894a0e4a801fc3', NULL, NULL, -1, 'utilisateur test à modifier');
PERFORM pg_catalog.setval('t_roles_id_seq', 20002, true);
EXCEPTION WHEN unique_violation THEN RAISE NOTICE 'Tentative d''insertion de valeur existante';
END
$$;

DO
$$
BEGIN
INSERT INTO t_roles (groupe, id_role, identifiant, prenom_role, nom_role, desc_role, pass, pass_sha, email, id_organisme, remarques) VALUES
(false,2, 'agent', 'Agent', 'test', NULL, 'b33aed8f3134996703dc39f9a7c95783', NULL, NULL, -1,'utilisateur test à modifier ou supprimer');
PERFORM pg_catalog.setval('t_roles_id_seq', 20002, true);
EXCEPTION WHEN unique_violation THEN RAISE NOTICE 'Tentative d''insertion de valeur existante';
END
$$;

DO
$$
BEGIN
INSERT INTO t_roles (groupe, id_role, identifiant, prenom_role, nom_role, desc_role, pass, pass_sha, email, id_organisme, remarques) VALUES
(false,3, 'partenaire', 'Partenaire', 'test', NULL, '5bd40a8524882d75f3083903f2c912fc', NULL, NULL, -1,'utilisateur test à modifier ou supprimer');
PERFORM pg_catalog.setval('t_roles_id_seq', 20002, true);
EXCEPTION WHEN unique_violation THEN RAISE NOTICE 'Tentative d''insertion de valeur existante';
END
$$;

DO
$$
BEGIN
INSERT INTO t_roles (groupe, id_role, identifiant, prenom_role, nom_role, desc_role, pass, pass_sha, email, id_organisme, remarques) VALUES
(false,4, 'pierre.paul', 'Paul', 'Pierre', NULL, '21232f297a57a5a743894a0e4a801fc3', NULL, NULL, -1,'utilisateur test à modifier ou supprimer');
PERFORM pg_catalog.setval('t_roles_id_seq', 20002, true);
EXCEPTION WHEN unique_violation THEN RAISE NOTICE 'Tentative d''insertion de valeur existante';
END
$$;

DO
$$
BEGIN
INSERT INTO t_roles (groupe, id_role, identifiant, prenom_role, nom_role, desc_role, pass, pass_sha, email, id_organisme, remarques) VALUES
(false,5, 'validateur', 'validateur', 'test', NULL, '21232f297a57a5a743894a0e4a801fc3', NULL, NULL, -1,'utilisateur test à modifier ou supprimer');
PERFORM pg_catalog.setval('t_roles_id_seq', 20002, true);
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


DO
$$
BEGIN
INSERT INTO t_tags (id_tag, tag_name, tag_desc) VALUES
(1, 'utilisateur', 'Ne peut que consulter')
,(2, 'rédacteur', 'Il possède des droit d''écriture pour créer des enregistrements')
,(3, 'référent', 'utilisateur ayant des droits complémentaires au rédacteur (par exemple exporter des données ou autre)')
,(4, 'modérateur', 'Peu utilisé')
,(5, 'validateur', 'Il valide bien sur')
,(6, 'administrateur', 'Il a tous les droits')
,(10,'CREATE new data', 'This user can create/add new data')
,(11,'READ my data', 'This user can read only his own data')
,(12,'READ my organism data', 'This user can read only the data of his organization')
,(13,'READ all data', 'This user can read all data')
,(14,'UPDATE my data', 'This user can edit only his own data')
,(15,'UPDATE my organism data', 'This user can edit only the data of his organization')
,(16,'UPDATE all data', 'This user can edit all data')
,(17,'VALID my data', 'This user can validate only his own data')
,(18,'VALID my organism data', 'This user can validate only the data of his organization')
,(19,'VALID all data', 'This user can validate all data')
,(20,'EXPORT my data', 'This user can export only his own data')
,(21,'EXPORT my organism data', 'This user can export only the data of his organization')
,(22,'EXPORT all data', 'This user can export all data')
,(23,'DELETE my data', 'This user can delete only his own data')
,(24,'DELETE my organism data', 'This user can delete only the data of his organization')
,(25,'DELETE all data', 'This user can delete all data')

,(100,'observateurs flore', 'liste des observateurs pour les protocoles flore')
,(101,'observateurs faune', 'liste des observateurs pour les protocoles faune')
,(102,'observateurs aigle', 'liste des observateurs pour le protocole suivi de la reproduction de l''aigle royal')

,(1000,'Geonature', 'Etiquette définissant l''appartenance au domaine "GeoNature"')
,(1001,'actions', 'Etiquette définissant un type "actions"')
,(1002,'Data types', 'Etiquette définissant un type "data_type". Plus précisément, l''étendue des données GeoNature accessibles (my data, my organism data, all data)')
,(1003,'listes', 'Etiquette définissant un type "listes"')
;
PERFORM pg_catalog.setval('t_tags_id_tag_seq', 1003, true);
EXCEPTION WHEN unique_violation  THEN
        RAISE NOTICE 'Tentative d''insertion de valeur existante';
END
$$;


DO
$$
BEGIN
INSERT INTO cor_role_tag_application (id_role, id_tag, id_application) VALUES
--administrateur sur UsersHub et TaxHub
(1, 6, 1)
,(1, 6, 2)
--administrateur sur GeoNature
,(1, 6, 14)
,(1, 10, 14)
,(1, 13, 14)
,(1, 16, 14)
,(1, 19, 14)
,(1, 22, 14)
,(1, 25, 14)
--validateur sur contact
,(5, 5, 15)
,(5, 19, 15)
--groupe en poste
,(20002, 10, 14)
,(20002, 13, 14)
,(20002, 14, 14)
,(20002, 21, 14)
,(20002, 23, 14)
--groupe bureau d''étude
,(20001, 10, 14)
,(20001, 11, 14)
,(20001, 14, 14)
,(20001, 17, 14)
,(20001, 20, 14)
,(20001, 23, 14)
--liste des observateurs faune
,(20002, 101, 15)
,(3, 101, 15)
--liste des observateurs flore
,(2, 100, 15)
,(5, 100, 15)
;
EXCEPTION WHEN unique_violation  THEN
        RAISE NOTICE 'Tentative d''insertion de valeur existante';
END
$$;


DO
$$
BEGIN
INSERT INTO gn_users.cor_data_type_action_tag (id_gn_data_type, id_gn_action, id_tag, comment) VALUES
(3,6,25,'This user can delete all data')
,(2,6,24,'This user can delete only the data of his organization')
,(1,6,23,'This user can delete only his own data')
,(3,5,22,'This user can export all data')
,(2,5,21,'This user can export only the data of his organization')
,(1,5,20,'This user can export only his own data')
,(3,4,19,'This user can validate all data')
,(2,4,18,'This user can validate only the data of his organization')
,(1,4,17,'This user can validate only his own data')
,(3,3,16,'This user can edit all data')
,(2,3,15,'This user can edit only the data of his organization')
,(1,3,14,'This user can edit only his own data')
,(3,2,13,'This user can read all data')
,(2,2,12,'This user can read only the data of his organization')
,(1,2,11,'This user can read only his own data')
,(3,1,10,'This user can create/add new data')
,(2,1,10,'This user can create/add new data')
,(1,1,10,'This user can create/add new data')
;
EXCEPTION WHEN unique_violation  THEN
        RAISE NOTICE 'Tentative d''insertion de valeur existante';
END
$$;


DO
$$
BEGIN
INSERT INTO cor_tags_relations (id_tag_l, id_tag_r, relation_type) VALUES
(100, 1003, 'est de type')
, (101, 1003, 'est de type')
, (102, 1003, 'est de type')
, (1, 1001, 'est de type')
, (2, 1001, 'est de type')
, (3, 1001, 'est de type')
, (4, 1001, 'est de type')
, (5, 1001, 'est de type')
, (6, 1001, 'est de type')
, (10, 1001, 'est de type')
, (11, 1001, 'est de type')
, (12, 1001, 'est de type')
, (13, 1001, 'est de type')
, (14, 1001, 'est de type')
, (15, 1001, 'est de type')
, (16, 1001, 'est de type')
, (17, 1001, 'est de type')
, (18, 1001, 'est de type')
, (19, 1001, 'est de type')
, (20, 1001, 'est de type')
, (21, 1001, 'est de type')
, (22, 1001, 'est de type')
, (23, 1001, 'est de type')
, (24, 1001, 'est de type')
, (25, 1001, 'est de type')
, (11, 1002, 'est de type')
, (12, 1002, 'est de type')
, (13, 1002, 'est de type')
, (14, 1002, 'est de type')
, (15, 1002, 'est de type')
, (16, 1002, 'est de type')
, (17, 1002, 'est de type')
, (18, 1002, 'est de type')
, (19, 1002, 'est de type')
, (20, 1002, 'est de type')
, (21, 1002, 'est de type')
, (22, 1002, 'est de type')
, (23, 1002, 'est de type')
, (24, 1002, 'est de type')
, (25, 1002, 'est de type')
;
EXCEPTION WHEN unique_violation  THEN
        RAISE NOTICE 'Tentative d''insertion de valeur existante';
END
$$;