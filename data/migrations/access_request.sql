BEGIN ;

-- Add tables to store permissions requests
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

DROP SEQUENCE IF EXISTS gn_permissions.cor_requests_permissions_id_request_permission_seq CASCADE ;

CREATE SEQUENCE gn_permissions.cor_requests_permissions_id_request_permission_seq
	INCREMENT BY 1
	MINVALUE 0
	MAXVALUE 2147483647
	START WITH 1
	CACHE 1
	NO CYCLE ;

-- ALTER SEQUENCE gn_permissions.cor_requests_permissions_id_request_permission_seq OWNER TO geonatadmin;

COMMENT ON SEQUENCE gn_permissions.cor_requests_permissions_id_request_permission_seq IS 
    E'Séquence de la clé primaire de la table cor_requests_permissions.' ;


DROP TABLE IF EXISTS gn_permissions.t_requests CASCADE ;

CREATE TABLE gn_permissions.t_requests (
	id_request integer NOT NULL DEFAULT nextval('gn_permissions.t_requests_id_request_seq'::regclass),
	id_role integer,
    token uuid NOT NULL DEFAULT uuid_generate_v4(),
    end_date date,
	accepted boolean,
    accepted_date timestamp,
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
COMMENT ON COLUMN gn_permissions.t_requests.accepted IS 
	E'Demande acceptée (=true), demande refusée (=false), demande en attente (=null).';
COMMENT ON COLUMN gn_permissions.t_requests.end_date IS 
	E'Date et heure d''acceptation ou refus de la demande. Null indique une demande en attente.';
COMMENT ON COLUMN gn_permissions.t_requests.additional_data IS 
	E'Contient des données complémentaires liées à la demande de permissions d''accès. Données du formulaire dynamique. Utiliser un objet JSON.';
COMMENT ON COLUMN gn_permissions.t_requests.meta_create_date IS 
	E'Date et heure de création de l''enregistrement.';
COMMENT ON COLUMN gn_permissions.t_requests.meta_update_date IS 
	E'Date de mise à jour de l''enregistrement. À la création de l''enregistrement, correspond à la date et heure de création.';

-- ALTER TABLE gn_permissions.t_requests OWNER TO geonatadmin ;


DROP TABLE IF EXISTS gn_permissions.cor_requests_permissions CASCADE ;

CREATE TABLE gn_permissions.cor_requests_permissions (
	id_request_permission integer NOT NULL DEFAULT nextval('gn_permissions.cor_requests_permissions_id_request_permission_seq'::regclass),
	id_request integer NOT NULL,
	id_module integer,
	id_action integer,
	id_object integer,
	id_filter_type integer,
	value_filter varchar(500),
    CONSTRAINT cor_requests_permissions_pk PRIMARY KEY (id_request_permission)
);

COMMENT ON TABLE gn_permissions.cor_requests_permissions IS 
	E'Contient les permissions associées à une demande.';
COMMENT ON COLUMN gn_permissions.cor_requests_permissions.id_request_permission IS 
	E'Identifiant auto-incrémenté d''une permission d''une demande.';
COMMENT ON COLUMN gn_permissions.cor_requests_permissions.id_request IS 
	E'Identifiant de la demande incluant cette permission.';
COMMENT ON COLUMN gn_permissions.cor_requests_permissions.id_module IS 
	E'Identifiant du module concerné par cette permission.';
COMMENT ON COLUMN gn_permissions.cor_requests_permissions.id_action IS 
	E'Identifiant de l''action de cette permission.';
COMMENT ON COLUMN gn_permissions.cor_requests_permissions.id_object IS 
	E'Identifiant de l''objet sur lequel s''applique l''action de cette permission.';
COMMENT ON COLUMN gn_permissions.cor_requests_permissions.id_filter_type IS 
	E'Identifiant du filtre à appliquer à la permission.';
COMMENT ON COLUMN gn_permissions.cor_requests_permissions.value_filter IS 
	E'Peut contenir un id, une liste d''id séparé par des virgules ou une chaîne en fonction du type de filtre.';

-- ALTER TABLE gn_permissions.cor_requests_permissions OWNER TO geonatadmin;

ALTER TABLE gn_permissions.t_requests 
    DROP CONSTRAINT IF EXISTS fk_t_requests_id_role CASCADE ;

ALTER TABLE gn_permissions.t_requests 
    ADD CONSTRAINT fk_t_requests_id_role FOREIGN KEY (id_role)
    REFERENCES utilisateurs.t_roles (id_role) MATCH FULL
    ON DELETE SET NULL ON UPDATE CASCADE ;


ALTER TABLE gn_permissions.cor_requests_permissions
	DROP CONSTRAINT IF EXISTS fk_cor_requests_permissions_id_action CASCADE ;

ALTER TABLE gn_permissions.cor_requests_permissions
	ADD CONSTRAINT fk_cor_requests_permissions_id_action FOREIGN KEY (id_action)
	REFERENCES gn_permissions.t_actions (id_action) MATCH FULL
	ON DELETE SET NULL ON UPDATE CASCADE ;


ALTER TABLE gn_permissions.cor_requests_permissions
	DROP CONSTRAINT IF EXISTS fk_cor_requests_permissions_id_object CASCADE ;

ALTER TABLE gn_permissions.cor_requests_permissions
	ADD CONSTRAINT fk_cor_requests_permissions_id_object FOREIGN KEY (id_object)
	REFERENCES gn_permissions.t_objects (id_object) MATCH FULL
	ON DELETE SET NULL ON UPDATE CASCADE ;


ALTER TABLE gn_permissions.cor_requests_permissions
	DROP CONSTRAINT IF EXISTS fk_cor_requests_permissions_id_module CASCADE ;

ALTER TABLE gn_permissions.cor_requests_permissions
	ADD CONSTRAINT fk_cor_requests_permissions_id_module FOREIGN KEY (id_module)
	REFERENCES gn_commons.t_modules (id_module) MATCH FULL
	ON DELETE SET NULL ON UPDATE CASCADE ;


ALTER TABLE gn_permissions.cor_requests_permissions
	DROP CONSTRAINT IF EXISTS fk_cor_requests_permissions_id_request CASCADE ;

ALTER TABLE gn_permissions.cor_requests_permissions
	ADD CONSTRAINT fk_cor_requests_permissions_id_request FOREIGN KEY (id_request)
	REFERENCES gn_permissions.t_requests (id_request) MATCH FULL
	ON DELETE RESTRICT ON UPDATE CASCADE ;


ALTER TABLE gn_permissions.cor_requests_permissions
	DROP CONSTRAINT IF EXISTS fk_cor_requests_permissions_id_filter_type CASCADE ;

ALTER TABLE gn_permissions.cor_requests_permissions
	ADD CONSTRAINT fk_cor_requests_permissions_id_filter_type FOREIGN KEY (id_filter_type)
	REFERENCES gn_permissions.bib_filters_type (id_filter_type) MATCH FULL
	ON DELETE SET NULL ON UPDATE CASCADE ;


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


-- Add new Object for Synthese module
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


-- Update table 'cor_role_action_filter_module_object' to group permissions,
-- manage permissions timing, store value of filters.


-- Remove table 't_filters'

COMMIT ;
