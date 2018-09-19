-- INSERT INTO gn_meta.sinp_datatype_actors (id_actor, actor_organism, actor_fullname, actor_mail) VALUES
-- (1,'Parc nationaux de France',null,null)
-- ,(2,'Parc national des Ecrins',null,null)
-- ,(3,null,'Gerard Lambert',null)
-- ,(4,null,'Pierre Paul-Jacques',null)
-- ;
-- SELECT pg_catalog.setval('sinp_datatype_actors_id_actor_seq', (SELECT max(id_actor)+1 FROM gn_meta.sinp_datatype_actors), false);

INSERT INTO sinp_datatype_protocols (id_protocol, unique_protocol_id, protocol_name, protocol_desc, id_nomenclature_protocol_type, protocol_url) VALUES
(0, '9ed37cb1-803b-4eec-9ecd-31880475bbe9', 'hors protocole','observation réalisées hors protocole',ref_nomenclatures.get_id_nomenclature('TYPE_PROTOCOLE','1'),null)
;
SELECT pg_catalog.setval('sinp_datatype_protocols_id_protocol_seq', (SELECT max(id_protocol)+1 FROM gn_meta.sinp_datatype_protocols), true);
