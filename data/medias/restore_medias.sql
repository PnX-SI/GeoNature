-- Requete pour restaurer les medias depuis la table gn_commons.t_history_actions
--
-- pour les medias qui ne sont plus dans gn_commons.t_medias
-- en complement il faut executer la commande du fichier restore_medias.sh depuis le repertoire de GeoNature
-- afin de marquer les fichier supprimer (avec 'deleted_' dans le nom) en non supprimé (on enleve 'deleted')

WITH valid_deleted_media AS (
	SELECT DISTINCT ON (id_media)
		(a.table_content->>'id_media')::int AS id_media,
		a.table_content
	FROM gn_commons.t_history_actions a 
	JOIN gn_commons.bib_tables_location l
		ON (a.table_content->>'id_table_location')::int = l.id_table_location
	LEFT JOIN gn_commons.t_medias m
		ON m.id_media = (table_content->>'id_media')::int 
	WHERE table_content->'id_media' IS NOT NULL 
		AND operation_type = 'D'
		AND table_content->>'uuid_attached_row' IS NOT NULL 
		AND gn_commons.check_entity_uuid_exist(
			CONCAT(schema_name, '.', table_name, '.', uuid_field_name),
			(a.table_content->>'uuid_attached_row')::uuid
			)
		AND m.id_media IS NULL
	ORDER BY id_media, 	id_history_action DESC
)
, media_data AS (
	SELECT d.* 
	FROM valid_deleted_media, json_to_record(valid_deleted_media.table_content) AS d(
		id_media int,
		unique_id_media uuid,
		id_nomenclature_media_type int,
		id_table_location int,	
		uuid_attached_row uuid,
		title_fr character varying(255),
		title_en character varying(255),
		title_it character varying(255),
		title_es character varying(255),
		title_de character varying(255),
		media_url character varying(255),
		media_path character varying(255),
		author character varying(100),
		description_fr text,
		description_en text,
		description_it text,
		description_es text,
		description_de text,
		is_public boolean,
		meta_create_date timestamp without time zone
	)
)
INSERT INTO gn_commons.t_medias (
	id_media,
	unique_id_media,
	id_nomenclature_media_type,
	id_table_location,
	uuid_attached_row,
	title_fr,
	title_en,
	title_it,
	title_es,
	title_de,
	media_url,
	media_path,
	author,
	description_fr,
	description_en,
	description_it,
	description_es,
	description_de,
	is_public,
	meta_create_date
)
SELECT
	id_media,
	unique_id_media,
	id_nomenclature_media_type,
	id_table_location,
	uuid_attached_row,
	title_fr,
	title_en,
	title_it,
	title_es,
	title_de,
	media_url,
	media_path,
	author,
	description_fr,
	description_en,
	description_it,
	description_es,
	description_de,
	is_public,
	meta_create_date
FROM media_data
