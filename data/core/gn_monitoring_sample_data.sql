--- Insertion de la notion d'application

INSERT INTO utilisateurs.t_applications(id_application, nom_application, desc_application, id_parent)
VALUES (100, 'suivi', 'Ensemble des applications relatives à un protocole de suivis', NULL);
INSERT INTO utilisateurs.t_applications(id_application, nom_application, desc_application, id_parent)
VALUES (101, 'suivi chiro', 'Suivis des gites à chiroptère', 100);

INSERT INTO utilisateurs.cor_app_privileges(id_tag_action, id_tag_object, id_application, id_role)
VALUES
    (11,23,100,1),
    (12,23,100,1),
    (13,23,100,1),
    (14,23,100,1),
    (15,23,100,1),
    (16,23,100,1);


-- Insertion d'un site et d'une visite
INSERT INTO  gn_monitoring.t_base_sites (
    id_base_site, id_inventor, id_digitiser, id_nomenclature_type_site, base_site_name,
    base_site_description, base_site_code, first_use_date, geom
)
VALUES (
    1, 1, 1, 475, 'test site',
    'Site description', 'TEST_000', '2018-01-01', '0101000020E610000062A67E7001980D40C24CD3511D2B4640'
);
SELECT pg_catalog.setval('gn_monitoring.t_base_sites_id_base_site_seq', 1, true);

INSERT INTO gn_monitoring.cor_site_application(id_base_site, id_application)
VALUES (1, 101);


INSERT INTO gn_monitoring.t_base_visits(
    id_base_visit, id_base_site, id_digitiser, visit_date, geom, comments
)
VALUES (
    1, 1, 1, '2018-01-01', NULL, 'Visite test pour l''exemple'
);
SELECT pg_catalog.setval('gn_monitoring.t_base_visits_id_base_visit_seq', 1, true);


INSERT INTO gn_monitoring.cor_visit_observer(id_base_visit, id_role)
VALUES (1,1);
