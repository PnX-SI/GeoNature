-- On ne défini pas d'id pour la PK, la séquence s'en charge
INSERT INTO gn_commons.bib_tables_location(table_desc, schema_name, table_name, pk_field, uuid_field_name)
VALUES
('Table centralisant les sites faisant l''objet de protocole de suivis', 'gn_monitoring', 't_base_sites', 'id_base_site', 'uuid_base_site'),
('Table centralisant les visites réalisées sur un site', 'gn_monitoring', 't_base_visits', 'id_base_visit', 'uuid_base_visit');
