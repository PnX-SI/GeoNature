-- Add tables to store permissions requests and alter permissions tables
BEGIN ;

-- -------------------------------------------------------------------------------------------------
-- Add comments on existing tables, columns and primary key sequences

-- Table "bib_filters_type"
COMMENT ON TABLE gn_permissions.bib_filters_type IS 
    E'Contient les types de filtres de permissions disponibles.';
COMMENT ON COLUMN gn_permissions.bib_filters_type.id_filter_type IS 
    E'Identifiant auto-incrementé d''un type de filtre.';
COMMENT ON COLUMN gn_permissions.bib_filters_type.code_filter_type IS 
    E'Code du type de filtre. Si possible un mot en anglais et en majuscule.';
COMMENT ON COLUMN gn_permissions.bib_filters_type.label_filter_type IS 
    E'Libellé court du type de filtre en français. Se baser sur les existants pour l''uniformité.';
COMMENT ON COLUMN gn_permissions.bib_filters_type.description_filter_type IS 
    E'Description du type de filtre en français. '
     'Décrire l''objet de la limitation, les valeurs possibles.';
COMMENT ON SEQUENCE gn_permissions.bib_filters_type_id_filter_type_seq IS 
    E'Séquence de la clé primaire de la table "bib_filters_type".' ;

-- Table "cor_role_action_filter_module_object"
COMMENT ON TABLE gn_permissions.cor_role_action_filter_module_object IS 
    E'Contient les permissions attribuées aux utilisateurs ou groupes.';
COMMENT ON COLUMN gn_permissions.cor_role_action_filter_module_object.id_permission IS 
	E'Identifiant auto-incrementé d''une permission attribuée' ;
COMMENT ON COLUMN gn_permissions.cor_role_action_filter_module_object.id_role IS 
	E'Identifiant du rôle/groupe de l''utitilisateur concerné par la permission.' ;
COMMENT ON COLUMN gn_permissions.cor_role_action_filter_module_object.id_action IS 
	E'Identifiant de l''action (CRUVED) de la permission.' ;
COMMENT ON COLUMN gn_permissions.cor_role_action_filter_module_object.id_module IS 
	E'Identifiant du module de la permission.' ;
COMMENT ON COLUMN gn_permissions.cor_role_action_filter_module_object.id_object IS 
	E'Identifiant de l''objet de la permission.' ;
COMMENT ON SEQUENCE gn_permissions.cor_role_action_filter_module_object_id_permission_seq IS
    E'Séquence de la clé primaire de la table "cor_role_action_filter_module_object".' ;

-- Table "t_actions"
COMMENT ON TABLE gn_permissions.t_actions IS 
    E'Contient les actions (CRUVED) disponibles.';
COMMENT ON COLUMN gn_permissions.t_actions.id_action IS 
	E'Identifiant auto-incrementé d''une action' ;
COMMENT ON COLUMN gn_permissions.t_actions.code_action IS 
    E'Code de l''action. Si possible une lettre en anglais et en majuscule.';
COMMENT ON COLUMN gn_permissions.t_actions.description_action IS 
    E'Description de l''action en français.';
COMMENT ON SEQUENCE gn_permissions.t_actions_id_action_seq IS
    E'Séquence de la clé primaire de la table "t_actions".' ;

-- Table "t_objects"
COMMENT ON TABLE gn_permissions.t_objects IS 
    E'Contient les objets ou ressources disponibles dans GeoNature. '
     'Les objets sont plus ou moins spécifiques à un module.';
COMMENT ON COLUMN gn_permissions.t_objects.id_object IS 
	E'Identifiant auto-incrementé d''un objet' ;
COMMENT ON COLUMN gn_permissions.t_objects.code_object IS 
    E'Code de l''objet. Si possible un mot ou deux en anglais en majuscule, '
     'avec le tiret bas ("_") comme séparateur de mots.';
COMMENT ON COLUMN gn_permissions.t_objects.description_object IS 
    E'Description détaillée de l''objet en français.';
COMMENT ON SEQUENCE gn_permissions.t_objects_id_object_seq IS
    E'Séquence de la clé primaire de la table "t_objects".' ;


-- -------------------------------------------------------------------------------------------------
-- Add sequence for new table "t_requests" primary key
DROP SEQUENCE IF EXISTS gn_permissions.t_requests_id_request_seq CASCADE ;

CREATE SEQUENCE gn_permissions.t_requests_id_request_seq
	INCREMENT BY 1
	MINVALUE 0
	MAXVALUE 2147483647
	START WITH 1
	CACHE 1
	NO CYCLE ;

-- ALTER SEQUENCE gn_permissions.t_requests_id_request_seq OWNER TO geonatadmin;

COMMENT ON SEQUENCE gn_permissions.t_requests_id_request_seq IS 
    E'Auto-incrément de la clé primaire de la table t_requests.' ;


-- -------------------------------------------------------------------------------------------------
-- Create request states enum 
DROP TYPE IF EXISTS request_states CASCADE ;

CREATE TYPE request_states AS ENUM ('pending', 'refused', 'accepted') ;


-- -------------------------------------------------------------------------------------------------
-- Create requests table 
DROP TABLE IF EXISTS gn_permissions.t_requests CASCADE ;

CREATE TABLE gn_permissions.t_requests (
	id_request integer NOT NULL DEFAULT nextval('gn_permissions.t_requests_id_request_seq'::regclass),
	id_role integer,
    token uuid NOT NULL DEFAULT uuid_generate_v4(),
    end_date date,
	processed_state request_states NOT NULL DEFAULT 'pending',
    processed_date timestamp,
    processed_by integer,
    refusal_reason varchar(1000),
    geographic_filter text,
    taxonomic_filter text,
    sensitive_access boolean DEFAULT false,
	additional_data jsonb,  
	meta_create_date timestamp NOT NULL DEFAULT now(),
	meta_update_date timestamp NOT NULL DEFAULT now(),
	CONSTRAINT t_requests_pk PRIMARY KEY (id_request)
) ;
COMMENT ON TABLE gn_permissions.t_requests IS 
    E'Contient les demandes de permissions.';
COMMENT ON COLUMN gn_permissions.t_requests.id_request IS 
    E'Identifiant auto-incrementé d''une demande de permissions.';
COMMENT ON COLUMN gn_permissions.t_requests.id_role IS 
	E'Identifiant de l''utilisateur (=rôle) réalisant la demande de permissions.';
COMMENT ON COLUMN gn_permissions.t_requests.token IS 
	E'Jeton de la demande de permissions. Identifie cette demande lors des appels par web service.';
COMMENT ON COLUMN gn_permissions.t_requests.end_date IS 
	E'Date de fin des permissions demandées. Null indique une demande de permissions permanente.';
COMMENT ON COLUMN gn_permissions.t_requests.processed_state IS 
	E'État de la demande correspondant à un ENUM.\n'
     'Valeurs possibles : acceptée (=accepted), demande refusée (=refused), demande en attente (=pending).';
COMMENT ON COLUMN gn_permissions.t_requests.processed_date IS 
	E'Date et heure de la dernière acceptation ou refus de la demande. Null pour les demandes en attente.';
COMMENT ON COLUMN gn_permissions.t_requests.processed_by IS 
	E'Identifiant du dernier utilisateur (=rôle) ayant accepté/refusé la demande. '
     'Null pour les demandes en attente et les actions via email.';
COMMENT ON COLUMN gn_permissions.t_requests.refusal_reason IS 
	E'Si accepted = false, peut contenir la raison du refus. '
     'Null pour les demandes en attente ou pour les refus sans raison.';
COMMENT ON COLUMN gn_permissions.t_requests.geographic_filter IS 
	E'Contient la liste des id_area du filtre géographique. '
     'Séparer les valeurs par des virgules.';
COMMENT ON COLUMN gn_permissions.t_requests.taxonomic_filter IS 
	E'Contient la liste des cd_nom du filtre taxonomique. '
     'Séparer les valeurs par des virgules.';
COMMENT ON COLUMN gn_permissions.t_requests.sensitive_access IS 
	E'Indique si oui (=true) ou non (=false) l''accès aux données sensibles est demandé.';
COMMENT ON COLUMN gn_permissions.t_requests.additional_data IS 
	E'Contient des données complémentaires liées à la demande de permissions d''accès. '
     'Données du formulaire dynamique. Utiliser un objet JSON.';
COMMENT ON COLUMN gn_permissions.t_requests.meta_create_date IS 
	E'Date et heure de création de l''enregistrement.';
COMMENT ON COLUMN gn_permissions.t_requests.meta_update_date IS 
	E'Date de mise à jour de l''enregistrement. '
     'À la création de l''enregistrement, correspond à la date et heure de création.';

-- ALTER TABLE gn_permissions.t_requests OWNER TO geonatadmin ;


-- -------------------------------------------------------------------------------------------------
-- Constraints for table "t_requests"
ALTER TABLE gn_permissions.t_requests 
    DROP CONSTRAINT IF EXISTS fk_t_requests_id_role CASCADE ;

ALTER TABLE gn_permissions.t_requests 
    ADD CONSTRAINT fk_t_requests_id_role FOREIGN KEY (id_role)
    REFERENCES utilisateurs.t_roles (id_role) MATCH FULL
    ON UPDATE CASCADE ;


ALTER TABLE gn_permissions.t_requests 
    DROP CONSTRAINT IF EXISTS fk_t_requests_processed_by CASCADE ;

ALTER TABLE gn_permissions.t_requests 
    ADD CONSTRAINT fk_t_requests_processed_by FOREIGN KEY (processed_by)
    REFERENCES utilisateurs.t_roles (id_role) MATCH FULL
    ON UPDATE CASCADE ;


-- -------------------------------------------------------------------------------------------------
-- Triggers
CREATE OR REPLACE FUNCTION gn_permissions.tri_func_modify_meta_update_date()
    RETURNS trigger
    LANGUAGE plpgsql
AS $function$
BEGIN
    NEW.meta_update_date := now();
    RETURN NEW;
END;
$function$ ;


DROP TRIGGER IF EXISTS tri_modify_meta_update_date_t_requests 
    ON gn_permissions.t_requests;

CREATE TRIGGER tri_modify_meta_update_date_t_requests
    AFTER UPDATE
    ON gn_permissions.t_requests
    FOR EACH ROW
        EXECUTE PROCEDURE gn_permissions.tri_func_modify_meta_update_date();


-- -------------------------------------------------------------------------------------------------
-- Add new Objects for Synthese module
INSERT INTO gn_permissions.t_objects (code_object, description_object) 
    SELECT
        'PRIVATE_OBSERVATION',
        'Observation privée.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.t_objects AS o
        WHERE o.code_object = 'PRIVATE_OBSERVATION'
    ) ;
INSERT INTO gn_permissions.t_objects (code_object, description_object) 
    SELECT
        'SENSITIVE_OBSERVATION',
        'Observation senssible.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.t_objects AS o
        WHERE o.code_object = 'SENSITIVE_OBSERVATION'
    ) ;


-- -------------------------------------------------------------------------------------------------
-- Rename filter "SENSITIVITY" to "PRECISION" and update others. See #1062.
UPDATE gn_permissions.bib_filters_type 
SET 
    label_filter_type = 'Filtre de portée',
    description_filter_type = E'Permissions limitées par le type d''appartenances des données.\n'
        'Accès à : aucune (=0), les miennes (=1), celles de mon organisme (=2), toutes (=3).'
WHERE code_filter_type = 'SCOPE' ;

UPDATE gn_permissions.bib_filters_type 
SET 
    label_filter_type = 'Filtre géographique',
    description_filter_type = E'Permissions limitées par zones géographiques.\n'
        'Utiliser des id_area séparés par des virgules.'
WHERE code_filter_type = 'GEOGRAPHIC' ;

UPDATE gn_permissions.bib_filters_type 
SET 
    label_filter_type = 'Filtre taxonomique',
    description_filter_type = E'Permissions limitées par des taxons.\n'
        'Utiliser des cd_nom séparés par des virgules.'
WHERE code_filter_type = 'TAXONOMIC' ;

UPDATE gn_permissions.bib_filters_type 
SET 
    code_filter_type = 'PRECISION',
    label_filter_type = 'Filtre de précision',
    description_filter_type = 'Active (=fuzzy) ou désactive (=exact) le floutage des données (sensibles ou privées).'
WHERE code_filter_type = 'SENSITIVITY' ;


-- -------------------------------------------------------------------------------------------------
-- Alter table "cor_role_action_filter_module_object" to group permissions,
-- manage permissions timing, store value of filters.
ALTER TABLE gn_permissions.cor_role_action_filter_module_object
    DROP COLUMN IF EXISTS gathering,
    DROP COLUMN IF EXISTS end_date,
    DROP COLUMN IF EXISTS id_filter_type,
    DROP COLUMN IF EXISTS value_filter ;


-- TODO: remove field "id_filter" from "cor_role_action_filter_module_object"
ALTER TABLE gn_permissions.cor_role_action_filter_module_object
    -- DROP COLUMN id_filter IF EXISTS, 
    ADD COLUMN gathering uuid DEFAULT uuid_generate_v4(),
    ADD COLUMN end_date timestamp NULL,
    ADD COLUMN id_filter_type int4 NULL,
    ADD COLUMN value_filter text NULL ;


COMMENT ON COLUMN gn_permissions.cor_role_action_filter_module_object.gathering IS 
	E'Groupe les permissions. Toutes les permissions possédant le même UUID sont à rassembler.'
     'Permet ainsi de cummuler plusieurs filtres distincts.' ;
COMMENT ON COLUMN gn_permissions.cor_role_action_filter_module_object.end_date IS 
	E'Indique la date à laquelle la permission prend fin la permission. '
     'Répéter cette date pour toutes les permissions d''un même groupe.' ;
COMMENT ON COLUMN gn_permissions.cor_role_action_filter_module_object.id_filter_type IS 
	E'Identifiant du type de filtre de la permission.' ;
COMMENT ON COLUMN gn_permissions.cor_role_action_filter_module_object.value_filter IS 
	E'Contient les valeurs du filtre à appliquer. '
     'Voir la description du type de filtre pour les valeurs possibles.' ;


ALTER TABLE gn_permissions.cor_role_action_filter_module_object
	DROP CONSTRAINT IF EXISTS fk_cor_role_action_filter_module_object_id_filter_type CASCADE ;

ALTER TABLE gn_permissions.cor_role_action_filter_module_object
	ADD CONSTRAINT fk_cor_role_action_filter_module_object_id_filter_type FOREIGN KEY (id_filter_type)
	REFERENCES gn_permissions.bib_filters_type (id_filter_type) MATCH FULL
	ON UPDATE CASCADE ;

-- -------------------------------------------------------------------------------------------------
-- Add sequence for new table "cor_module_action_object_filter" primary key
DROP SEQUENCE IF EXISTS gn_permissions.cor_module_action_object_filter_id_permission_available_seq CASCADE ;

CREATE SEQUENCE gn_permissions.cor_module_action_object_filter_id_permission_available_seq
	INCREMENT BY 1
	MINVALUE 0
	MAXVALUE 2147483647
	START WITH 1
	CACHE 1
	NO CYCLE ;

COMMENT ON SEQUENCE gn_permissions.cor_module_action_object_filter_id_permission_available_seq IS 
    E'Auto-incrément de la clé primaire de la table cor_module_action_object_filter.' ;


-- -------------------------------------------------------------------------------------------------
-- Add new table "cor_module_action_object_filter" (AKA "t_permissions_available")
DROP TABLE IF EXISTS gn_permissions.cor_module_action_object_filter CASCADE ;

CREATE TABLE gn_permissions.cor_module_action_object_filter (
	id_permission_available integer NOT NULL DEFAULT nextval('gn_permissions.cor_module_action_object_filter_id_permission_available_seq'::regclass),
	id_module integer NOT NULL,
	id_action integer NOT NULL,
	id_object integer NOT NULL,
	id_filter_type integer NOT NULL,
    permission_code varchar(200) NOT NULL,
    permission_description text NULL,
    CONSTRAINT cor_module_action_object_filter_pk PRIMARY KEY (id_permission_available)
);

COMMENT ON TABLE gn_permissions.cor_module_action_object_filter IS 
	E'Contient les permissions implémentées au niveau du code des modules.';
COMMENT ON COLUMN gn_permissions.cor_module_action_object_filter.id_permission_available IS 
	E'Identifiant auto-incrémenté d''une permission implémentée.';
COMMENT ON COLUMN gn_permissions.cor_module_action_object_filter.id_module IS 
	E'Identifiant du module concerné par cette permission.';
COMMENT ON COLUMN gn_permissions.cor_module_action_object_filter.id_action IS 
	E'Identifiant de l''action de cette permission.';
COMMENT ON COLUMN gn_permissions.cor_module_action_object_filter.id_object IS 
	E'Identifiant de l''objet sur lequel s''applique l''action de cette permission.';
COMMENT ON COLUMN gn_permissions.cor_module_action_object_filter.id_filter_type IS 
	E'Identifiant du filtre à appliquer à la permission.';
COMMENT ON COLUMN gn_permissions.cor_module_action_object_filter.permission_code IS 
	E'Code de la permission correspondant à la concaténation des codes (séparés par des tirets) du module, action, objet et type de filtre.';
COMMENT ON COLUMN gn_permissions.cor_module_action_object_filter.permission_description IS 
	E'Description de la permission, de son cadre d''utilisation et des valeurs autorisées pour le filtre.';


-- -------------------------------------------------------------------------------------------------
-- Constraints for table "cor_module_action_object_filter"
ALTER TABLE gn_permissions.cor_module_action_object_filter
	DROP CONSTRAINT IF EXISTS fk_cor_module_action_object_filter_id_module CASCADE ;

ALTER TABLE gn_permissions.cor_module_action_object_filter
	ADD CONSTRAINT fk_cor_module_action_object_filter_id_module FOREIGN KEY (id_module)
	REFERENCES gn_commons.t_modules (id_module) MATCH FULL
	ON UPDATE CASCADE ;


ALTER TABLE gn_permissions.cor_module_action_object_filter
	DROP CONSTRAINT IF EXISTS fk_cor_module_action_object_filter_id_action CASCADE ;

ALTER TABLE gn_permissions.cor_module_action_object_filter
	ADD CONSTRAINT fk_cor_module_action_object_filter_id_action FOREIGN KEY (id_action)
	REFERENCES gn_permissions.t_actions (id_action) MATCH FULL
	ON UPDATE CASCADE ;


ALTER TABLE gn_permissions.cor_module_action_object_filter
	DROP CONSTRAINT IF EXISTS fk_cor_module_action_object_filter_id_object CASCADE ;

ALTER TABLE gn_permissions.cor_module_action_object_filter
	ADD CONSTRAINT fk_cor_module_action_object_filter_id_object FOREIGN KEY (id_object)
	REFERENCES gn_permissions.t_objects (id_object) MATCH FULL
	ON UPDATE CASCADE ;


ALTER TABLE gn_permissions.cor_module_action_object_filter
	DROP CONSTRAINT IF EXISTS fk_cor_module_action_object_filter_id_filter_type CASCADE ;

ALTER TABLE gn_permissions.cor_module_action_object_filter
	ADD CONSTRAINT fk_cor_module_action_object_filter_id_filter_type FOREIGN KEY (id_filter_type)
	REFERENCES gn_permissions.bib_filters_type (id_filter_type) MATCH FULL
	ON UPDATE CASCADE ;


-- -------------------------------------------------------------------------------------------------
-- Rename "SENSITIVITY" filter values. See #1062
-- TODO: to remove when new permissions management implemented.
UPDATE gn_permissions.t_filters 
SET 
    value_filter = 'fuzzy',
    description_filter = 'Filtre pour flouter les données sensibles et privées.'
WHERE value_filter = 'DONNEES_DEGRADEES' ;

-- TODO: to remove when new permissions management implemented.
UPDATE gn_permissions.t_filters 
SET 
    value_filter = 'exact',
    description_filter = 'Filtre pour afficher précisément les données sensibles et privées.'
WHERE value_filter = 'DONNEES_PRECISES' ;


-- -------------------------------------------------------------------------------------------------
-- TODO: try to migrate "t_filters" entries


-- -------------------------------------------------------------------------------------------------
-- Remove table "t_filters"
-- DROP TABLE IF EXISTS gn_permissions.t_filters ;


-- -------------------------------------------------------------------------------------------------
-- Remove table "cor_object_module"
-- DROP TABLE IF EXISTS gn_permissions.cor_object_module ;


-- -------------------------------------------------------------------------------------------------
-- Remove table "cor_filter_type_module"
-- DROP TABLE IF EXISTS gn_permissions.cor_filter_type_module ;

COMMIT ;
