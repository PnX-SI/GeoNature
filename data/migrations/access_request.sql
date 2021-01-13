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
-- Add new utilities functions
CREATE OR REPLACE FUNCTION gn_permissions.get_id_action(actionCode character varying)
    RETURNS integer
    LANGUAGE plpgsql
    IMMUTABLE
AS $function$
    BEGIN
        RETURN (
            SELECT id_action
            FROM gn_permissions.t_actions
            WHERE code_action = actionCode
        );
    END;
$function$ ;

CREATE OR REPLACE FUNCTION gn_permissions.get_id_filter_type(filterTypeCode character varying)
    RETURNS integer
    LANGUAGE plpgsql
    IMMUTABLE
AS $function$
    BEGIN
        RETURN (
            SELECT id_filter_type
            FROM gn_permissions.bib_filters_type
            WHERE code_filter_type = filterTypeCode
        );
    END;
$function$ ;


-- -------------------------------------------------------------------------------------------------
-- Add constraint for "id_module" in table "cor_role_action_filter_module_object"
ALTER TABLE gn_permissions.cor_role_action_filter_module_object
	DROP CONSTRAINT IF EXISTS fk_cor_r_a_f_m_o_id_module CASCADE ;

ALTER TABLE gn_permissions.cor_role_action_filter_module_object
	ADD CONSTRAINT fk_cor_r_a_f_m_o_id_module FOREIGN KEY (id_module)
	REFERENCES gn_commons.t_modules (id_module) MATCH FULL
	ON UPDATE CASCADE ;


-- -------------------------------------------------------------------------------------------------
-- Add sequence for new table "bib_filters_values" primary key
DROP SEQUENCE IF EXISTS gn_permissions.bib_filters_values_id_filter_value_seq CASCADE ;

CREATE SEQUENCE gn_permissions.bib_filters_values_id_filter_value_seq
	INCREMENT BY 1
	MINVALUE 0
	MAXVALUE 2147483647
	START WITH 1
	CACHE 1
	NO CYCLE ;

-- ALTER SEQUENCE gn_permissions.bib_filters_values_id_filter_value_seq OWNER TO geonatadmin;

COMMENT ON SEQUENCE gn_permissions.bib_filters_values_id_filter_value_seq IS 
    E'Auto-incrément de la clé primaire de la table bib_filters_values.' ;

-- -------------------------------------------------------------------------------------------------
-- Create request states enum 
DROP TYPE IF EXISTS filter_value_formats CASCADE ;

CREATE TYPE filter_value_formats AS ENUM ('string', 'integer', 'boolean', 'geometry', 'csvint') ;


-- -------------------------------------------------------------------------------------------------
-- Create filters values types table 
DROP TABLE IF EXISTS gn_permissions.bib_filters_values CASCADE ;

CREATE TABLE gn_permissions.bib_filters_values (
	id_filter_value integer NOT NULL 
        DEFAULT nextval('gn_permissions.bib_filters_values_id_filter_value_seq'::regclass),
	id_filter_type integer,
    value_format filter_value_formats NOT NULL,
    predefined boolean NOT NULL,
    value_or_field varchar(50) NOT NULL,
    label varchar(255) NOT NULL,
    description text,
	CONSTRAINT bib_filters_values_pk PRIMARY KEY (id_filter_value)
) ;
COMMENT ON TABLE gn_permissions.bib_filters_values IS 
    E'Contient les types de valeurs des filtres.';
COMMENT ON COLUMN gn_permissions.bib_filters_values.id_filter_value IS 
    E'Identifiant auto-incrementé d''un type de valeur de filtre.';
COMMENT ON COLUMN gn_permissions.bib_filters_values.id_filter_type IS 
    E'Identifiant du type de filtre auquel la valeur appartient.';
COMMENT ON COLUMN gn_permissions.bib_filters_values.value_format IS 
    E'Format de la valeur : chaine de caractère (="str"), '
     'un nombre entier unique (="int"), '
     'une liste de nombres entiers séparés par des virgules (="csv-int),'
     'une géométrie (="geom").';
COMMENT ON COLUMN gn_permissions.bib_filters_values.predefined IS 
    E'Indique si la valeur est prédinie (=true) en étant limitée par une liste figée de valeurs '
    'ou libre (=false) en dépendant de choix réalisés par l''utilisateur.';
COMMENT ON COLUMN gn_permissions.bib_filters_values.value_or_field IS 
    E'Code alphanumérique représentant une valeur du filtre ou pour le format "csv-int" '
     'le nom du champ correspondant aux nombres entiers séparés par des virgules.'
     'Dans le cas des valeurs prédéfinies, privilégier un mot anglais court.';
COMMENT ON COLUMN gn_permissions.bib_filters_values.label IS 
    E'Nom court représentant la valeur. Surtout utile pour les valeurs prédéfinies.';
COMMENT ON COLUMN gn_permissions.bib_filters_values.description IS 
    E'Description détaillée du type de valeur.';


-- -------------------------------------------------------------------------------------------------
-- Constraints for table "bib_filters_values"
ALTER TABLE gn_permissions.bib_filters_values 
    DROP CONSTRAINT IF EXISTS fk_bib_filters_values_id_filter_type CASCADE ;

ALTER TABLE gn_permissions.bib_filters_values 
    ADD CONSTRAINT fk_bib_filters_values_id_filter_type FOREIGN KEY (id_filter_type)
    REFERENCES gn_permissions.bib_filters_type (id_filter_type) MATCH FULL
    ON UPDATE CASCADE ;


-- -------------------------------------------------------------------------------------------------
-- Add filters values types knowned
INSERT INTO gn_permissions.bib_filters_values (
    id_filter_type, value_format, predefined, value_or_field, label, description
) 
    SELECT
        gn_permissions.get_id_filter_type('SCOPE'),
        'integer',
        true,
        '0',
        'À personne',
        'Aucune appartenance. Cette valeur empèche l''accès aux objets.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.bib_filters_values AS bfv
        WHERE id_filter_type = gn_permissions.get_id_filter_type('SCOPE')
            AND bfv.value_or_field = '0'
    ) ;

INSERT INTO gn_permissions.bib_filters_values (
    id_filter_type, value_format, predefined, value_or_field, label, description
) 
    SELECT
        gn_permissions.get_id_filter_type('SCOPE'),
        'integer',
        true,
        '1',
        'À moi',
        'Appartenant à l''utilisateur. '
        'Indique un accès restreint aux objets créés/associés '
        'à l''utilisateur connecté.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.bib_filters_values AS bfv
        WHERE id_filter_type = gn_permissions.get_id_filter_type('SCOPE')
            AND bfv.value_or_field = '1'
    ) ;

INSERT INTO gn_permissions.bib_filters_values (
    id_filter_type, value_format, predefined, value_or_field, label, description
) 
    SELECT
        gn_permissions.get_id_filter_type('SCOPE'),
        'integer',
        true,
        '2',
        'À mon organisme',
        'Appartenant à l''ogranisme de l''utilisateur. '
        'Indique un accès restreint aux objets créés/associés à des utilisateurs '
        'du même organisme que l''utilisateur actuellement connecté.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.bib_filters_values AS bfv
        WHERE id_filter_type = gn_permissions.get_id_filter_type('SCOPE')
            AND bfv.value_or_field = '2'
    ) ;

INSERT INTO gn_permissions.bib_filters_values (
    id_filter_type, value_format, predefined, value_or_field, label, description
) 
    SELECT
        gn_permissions.get_id_filter_type('SCOPE'),
        'integer',
        true,
        '3',
        'À tout le monde',
        'Appartenant à tout le monde. '
        'Indique un accès à tous non restreint par l''appartenance des objets.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.bib_filters_values AS bfv
        WHERE id_filter_type = gn_permissions.get_id_filter_type('SCOPE')
            AND bfv.value_or_field = '3'
    ) ;

INSERT INTO gn_permissions.bib_filters_values (
    id_filter_type, value_format, predefined, value_or_field, label, description
) 
    SELECT
        gn_permissions.get_id_filter_type('GEOGRAPHIC'),
        'csvint',
        false,
        'ref_geo.l_areas.id_area',
        'id_area',
        'Liste d''identifiant de zones géographiques séparés par des virgules. '
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.bib_filters_values AS bfv
        WHERE id_filter_type = gn_permissions.get_id_filter_type('GEOGRAPHIC')
            AND bfv.value_or_field = 'id_area'
    ) ;

INSERT INTO gn_permissions.bib_filters_values (
    id_filter_type, value_format, predefined, value_or_field, label, description
) 
    SELECT
        gn_permissions.get_id_filter_type('TAXONOMIC'),
        'csvint',
        false,
        'taxonomie.taxref.cd_nom',
        'cd_nom',
        'Liste d''identifiant de noms scientifiques séparés par des virgules. '
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.bib_filters_values AS bfv
        WHERE id_filter_type = gn_permissions.get_id_filter_type('TAXONOMIC')
            AND bfv.value_or_field = 'cd_nom'
    ) ;

INSERT INTO gn_permissions.bib_filters_values (
    id_filter_type, value_format, predefined, value_or_field, label, description
) 
    SELECT
        gn_permissions.get_id_filter_type('PRECISION'),
        'string',
        true,
        'exact',
        'Exacte',
        'Accès aux objets avec les informations géographiques précises.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.bib_filters_values AS bfv
        WHERE id_filter_type = gn_permissions.get_id_filter_type('PRECISION')
            AND bfv.value_or_field = 'exact'
    ) ;

INSERT INTO gn_permissions.bib_filters_values (
    id_filter_type, value_format, predefined, value_or_field, label, description
) 
    SELECT
        gn_permissions.get_id_filter_type('PRECISION'),
        'string',
        true,
        'fuzzy',
        'Floutée',
        'Accès aux objets avec les informations géographiques floutées.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.bib_filters_values AS bfv
        WHERE id_filter_type = gn_permissions.get_id_filter_type('PRECISION')
            AND bfv.value_or_field = 'fuzzy'
    ) ;


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
    -- TODO: maybe using a single field "filters" with jsonb could be simplify the code
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
    label_filter_type = 'Filtre d''appartenance',
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


ALTER TABLE gn_permissions.cor_role_action_filter_module_object
    ADD COLUMN gathering uuid DEFAULT uuid_generate_v4(),
    ADD COLUMN end_date timestamp NULL,
    ADD COLUMN id_filter_type int4 NULL,
    -- TODO: not used today. Remove ? See if really usefull or not !
    -- ADD COLUMN id_filter_value int4 NULL,
    ADD COLUMN value_filter text NULL,
    ADD COLUMN id_request int4 NULL ;


COMMENT ON COLUMN gn_permissions.cor_role_action_filter_module_object.gathering IS 
	E'Groupe les permissions. Toutes les permissions possédant le même UUID sont à rassembler.'
     'Permet ainsi de cummuler plusieurs filtres distincts.' ;
COMMENT ON COLUMN gn_permissions.cor_role_action_filter_module_object.end_date IS 
	E'Indique la date à laquelle la permission prend fin la permission. '
     'Répéter cette date pour toutes les permissions d''un même groupe.' ;
COMMENT ON COLUMN gn_permissions.cor_role_action_filter_module_object.id_filter_type IS 
	E'Identifiant du type de filtre de la permission.' ;
-- TODO: not used today. Remove ?
-- COMMENT ON COLUMN gn_permissions.cor_role_action_filter_module_object.id_filter_value IS 
-- 	E'Identifiant du type de valeur du filtre de la permission.'
--   'Utile pour les filtres non prédéfini pouvant posséder plusieurs types de valeurs.' ;
COMMENT ON COLUMN gn_permissions.cor_role_action_filter_module_object.value_filter IS 
	E'Contient les valeurs du filtre à appliquer. '
     'Voir la description du type de filtre pour les valeurs possibles.' ;
COMMENT ON COLUMN gn_permissions.cor_role_action_filter_module_object.id_request IS 
	E'Identifiant de la requête à l''origine de la création de la permission'
     'Si la permission n''est pas liée à une demande d''accès contient NULL.' ;


ALTER TABLE gn_permissions.cor_role_action_filter_module_object
	DROP CONSTRAINT IF EXISTS fk_cor_r_a_f_m_o_id_filter_type CASCADE ;

ALTER TABLE gn_permissions.cor_role_action_filter_module_object
	ADD CONSTRAINT fk_cor_r_a_f_m_o_id_filter_type FOREIGN KEY (id_filter_type)
	REFERENCES gn_permissions.bib_filters_type (id_filter_type) MATCH FULL
	ON UPDATE CASCADE ;

ALTER TABLE gn_permissions.cor_role_action_filter_module_object
	ADD CONSTRAINT fk_cor_r_a_f_m_o_id_request FOREIGN KEY (id_request)
	REFERENCES gn_permissions.t_requests (id_request) MATCH FULL
	ON UPDATE CASCADE ;


-- -------------------------------------------------------------------------------------------------
-- Rename and update trigger to force only one filter type by permission (gathering)
-- TODO: see if we can rename this trigger
CREATE OR REPLACE FUNCTION gn_permissions.fct_tri_only_one_filter_type_by_permission()
RETURNS trigger AS
$BODY$
    -- Check if a role has not already the same filter type for a permission (= module-action-object).
    -- Use as constraint to force not set multiple same filter type by permission (= module-action-object).
    DECLARE 
        codeFilterType character varying ;
        nbPermission integer ;
    BEGIN
        -- For this filter type, check if there is not already a permission with it for this
        -- role-module-action-object
        SELECT INTO nbPermission COUNT(id_permission)
        FROM gn_permissions.cor_role_action_filter_module_object
        WHERE id_role = NEW.id_role 
            AND id_action = NEW.id_action 
            AND id_module = NEW.id_module 
            AND id_object = NEW.id_object 
            AND gathering = NEW.gathering
            AND id_filter_type = NEW.id_filter_type ;

        -- if its an insert 0 row must be present, if its an update 1 row must be present
        IF (TG_OP = 'INSERT' AND nbPermission = 0) OR (TG_OP = 'UPDATE' AND nbPermission = 1) THEN
            RETURN NEW;
        END IF;
        BEGIN
            -- Get code filter type
            SELECT INTO codeFilterType code_filter_type
            FROM gn_permissions.bib_filters_type 
            WHERE id_filter_type = NEW.id_filter_type ;

            RAISE EXCEPTION 'ATTENTION: il existe déjà un enregistrement avec le type de filtre % '
                'pour le role % sur le module %, son action % et objet % . Il est interdit de '
                'définir plusieurs fois le même type de filtre pour un même ensemble role, module, '
                'action et objet.', 
                codeFilterType, 
                NEW.id_role, 
                NEW.id_module, 
                NEW.id_action, 
                NEW.id_object ;
        END;
    END;
$BODY$
LANGUAGE plpgsql VOLATILE
COST 100 ;

DROP TRIGGER IF EXISTS tri_check_no_multiple_filter_type 
    ON gn_permissions.cor_role_action_filter_module_object ;

CREATE TRIGGER tri_check_no_multiple_filter_type 
    BEFORE INSERT OR UPDATE
    ON gn_permissions.cor_role_action_filter_module_object 
    FOR EACH ROW 
    EXECUTE PROCEDURE gn_permissions.fct_tri_only_one_filter_type_by_permission() ;

DROP TRIGGER IF EXISTS tri_check_no_multiple_scope_perm 
    ON gn_permissions.cor_role_action_filter_module_object ;

DROP FUNCTION IF EXISTS gn_permissions.fct_tri_does_user_have_already_scope_filter ;


-- -------------------------------------------------------------------------------------------------
-- Rebuild view "v_roles_permissions"
DROP VIEW IF EXISTS gn_permissions.v_roles_permissions ;

CREATE VIEW gn_permissions.v_roles_permissions
AS WITH 
    -- Get users permissions
    p_user_permission AS (
        SELECT u.id_role,
            u.nom_role,
            u.prenom_role,
            NULL AS group_name,
            u.id_organisme,
            c_1.id_permission,
            c_1.id_module,
            c_1.id_action,
            c_1.id_object,
            c_1.gathering,
            c_1.end_date,
            c_1.id_filter,-- TODO: remove this line
            c_1.id_filter_type,
            c_1.value_filter
        FROM utilisateurs.t_roles AS u
            JOIN gn_permissions.cor_role_action_filter_module_object AS c_1 
                ON (c_1.id_role = u.id_role)
        WHERE u.groupe = false
    ),
    -- Get permissions of groups AND the user permissions inherited from his group(s)
    -- WARNING : get permissions from groups only if they have users
    p_groupe_permission AS (
        SELECT u.id_role,
            u.nom_role,
            u.prenom_role,
            TRIM(TRAILING FROM CONCAT(grp.nom_role, ' ', grp.prenom_role)) AS group_name,
            u.id_organisme,
            c_1.id_permission,
            c_1.id_module,
            c_1.id_action,
            c_1.id_object,
            c_1.gathering,
            c_1.end_date,
            c_1.id_filter,-- TODO: remove this line
            c_1.id_filter_type,
            c_1.value_filter
        FROM utilisateurs.t_roles AS u
            JOIN utilisateurs.cor_roles AS g 
                ON (g.id_role_utilisateur = u.id_role OR g.id_role_groupe = u.id_role)
            JOIN utilisateurs.t_roles AS grp 
                ON (g.id_role_groupe = grp.id_role)
            JOIN gn_permissions.cor_role_action_filter_module_object AS c_1 
                ON (c_1.id_role = g.id_role_groupe)
        -- TODO: check if below lines are really useful
        -- WHERE g.id_role_groupe IN (
        --     SELECT DISTINCT cor_roles.id_role_groupe 
        --     FROM utilisateurs.cor_roles
        -- )
    ), 
    all_user_permission AS (
        -- UNION operator removes all duplicate rows from the combined data set
        SELECT p_user_permission.id_role,
            p_user_permission.nom_role,
            p_user_permission.prenom_role,
            p_user_permission.group_name,
            p_user_permission.id_organisme,
            p_user_permission.id_permission,
            p_user_permission.id_module,
            p_user_permission.id_action,
            p_user_permission.id_object,
            p_user_permission.gathering,
            p_user_permission.end_date,
            p_user_permission.id_filter,-- TODO: remove this line
            p_user_permission.id_filter_type,
            p_user_permission.value_filter
        FROM p_user_permission
        UNION
        SELECT p_groupe_permission.id_role,
            p_groupe_permission.nom_role,
            p_groupe_permission.prenom_role,
            p_groupe_permission.group_name,
            p_groupe_permission.id_organisme,
            p_groupe_permission.id_permission,
            p_groupe_permission.id_module,
            p_groupe_permission.id_action,
            p_groupe_permission.id_object,
            p_groupe_permission.gathering,
            p_groupe_permission.end_date,
            p_groupe_permission.id_filter,-- TODO: remove this line
            p_groupe_permission.id_filter_type,
            p_groupe_permission.value_filter
        FROM p_groupe_permission
    )
SELECT v.id_role,
    v.nom_role,
    v.prenom_role,
    v.group_name,
    v.id_organisme,
    v.id_module,
    modules.module_code,
    v.id_action,
    actions.code_action,
    actions.description_action,
    obj.code_object,
    v.id_filter,-- TODO: remove this line
    v.id_filter_type,
    v.value_filter,
    --filters.label_filter,-- TODO: remove this line
    filter_type.code_filter_type,
    v.gathering,
    v.end_date,
    v.id_permission
FROM all_user_permission AS v
    JOIN gn_permissions.t_actions AS actions 
        ON (actions.id_action = v.id_action)
    JOIN gn_permissions.t_objects AS obj 
        ON (obj.id_object = v.id_object)
    JOIN gn_permissions.bib_filters_type AS filter_type 
        ON (v.id_filter_type = filter_type.id_filter_type)
    JOIN gn_commons.t_modules AS modules 
        ON (modules.id_module = v.id_module)
-- TODO: check performance issues with order by
ORDER BY nom_role, prenom_role, module_code, gathering, id_action, code_object, code_filter_type, end_date ;


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
    code varchar(200) NOT NULL,
    label varchar(250) NOT NULL,
    description text NULL,
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
COMMENT ON COLUMN gn_permissions.cor_module_action_object_filter.code IS 
	E'Code de la permission correspondant à la concaténation des codes (séparés par des tirets) '
     'du module, action, objet et type de filtre.';
COMMENT ON COLUMN gn_permissions.cor_module_action_object_filter.label IS 
	E'Intitulé de la permission constitué du verbe (CRUVED) et du complément (object).\n'
     'Cette valeur sera identique pour toutes les lignes ayant les mêmes valeurs '
     'd''action et d''objet.\n'
     'Elle sert à nommer une permission quelque soit son filtre et son module.\n'
     'Ex.: Lire les observations privées';
COMMENT ON COLUMN gn_permissions.cor_module_action_object_filter.description IS 
	E'Description de la permission, de son cadre d''utilisation et des valeurs autorisées '
     'pour le filtre.';


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

-- TODO: not used today. Remove ?
-- ALTER TABLE gn_permissions.cor_module_action_object_filter
-- 	DROP CONSTRAINT IF EXISTS fk_cor_module_action_object_filter_id_filter_value CASCADE ;

-- ALTER TABLE gn_permissions.cor_module_action_object_filter
-- 	ADD CONSTRAINT fk_cor_module_action_object_filter_id_filter_value FOREIGN KEY (id_filter_value)
-- 	REFERENCES gn_permissions.bib_filters_values (id_filter_value) MATCH FULL
-- 	ON UPDATE CASCADE ;


-- -------------------------------------------------------------------------------------------------
-- Helper query to see all distinct permissions used
--
-- SELECT DISTINCT crafmo.id_module, crafmo.id_action, tm.module_code, ta.code_action, to2.code_object, bft.code_filter_type 
-- FROM gn_permissions.cor_role_action_filter_module_object AS crafmo
-- 	JOIN gn_commons.t_modules AS tm  ON crafmo.id_module = tm.id_module 
-- 	JOIN gn_permissions.t_actions AS ta ON crafmo.id_action = ta.id_action 
-- 	JOIN gn_permissions.t_objects AS to2 ON crafmo.id_object = to2.id_object 
-- 	JOIN gn_permissions.bib_filters_type AS bft ON crafmo.id_filter_type = bft.id_filter_type 
-- ORDER BY crafmo.id_module, crafmo.id_action ;


-- -------------------------------------------------------------------------------------------------
-- Insert data into permissions available table

INSERT INTO gn_permissions.cor_module_action_object_filter (
    id_module, id_action, id_object, id_filter_type, code, label, description
) 
    SELECT
        gn_commons.get_id_module_bycode('GEONATURE'),
        gn_permissions.get_id_action('C'),
        gn_permissions.get_id_object('ALL'),
        gn_permissions.get_id_filter_type('SCOPE'),
        'GEONATURE-C-ALL-SCOPE',
        'Créer des données',
        'Créer des données dans GeoNature en étant limité par la portée.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.cor_module_action_object_filter AS cmaof
        WHERE cmaof.code = 'GEONATURE-C-ALL-SCOPE'
    ) ;

INSERT INTO gn_permissions.cor_module_action_object_filter (
    id_module, id_action, id_object, id_filter_type, code, label, description
) 
    SELECT
        gn_commons.get_id_module_bycode('GEONATURE'),
        gn_permissions.get_id_action('R'),
        gn_permissions.get_id_object('ALL'),
        gn_permissions.get_id_filter_type('SCOPE'),
        'GEONATURE-R-ALL-SCOPE',
        'Lire les données',
        'Lire les données dans GeoNature limitées en étant limité par la portée.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.cor_module_action_object_filter AS cmaof
        WHERE cmaof.code = 'GEONATURE-R-ALL-SCOPE'
    ) ;

INSERT INTO gn_permissions.cor_module_action_object_filter (
    id_module, id_action, id_object, id_filter_type, code, label, description
) 
    SELECT
        gn_commons.get_id_module_bycode('GEONATURE'),
        gn_permissions.get_id_action('U'),
        gn_permissions.get_id_object('ALL'),
        gn_permissions.get_id_filter_type('SCOPE'),
        'GEONATURE-U-ALL-SCOPE',
        'Mettre à jour des données',
        'Mettre à jour des données dans GeoNature en étant limité par la portée.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.cor_module_action_object_filter AS cmaof
        WHERE cmaof.code = 'GEONATURE-U-ALL-SCOPE'
    ) ;

INSERT INTO gn_permissions.cor_module_action_object_filter (
    id_module, id_action, id_object, id_filter_type, code, label, description
) 
    SELECT
        gn_commons.get_id_module_bycode('GEONATURE'),
        gn_permissions.get_id_action('V'),
        gn_permissions.get_id_object('ALL'),
        gn_permissions.get_id_filter_type('SCOPE'),
        'GEONATURE-V-ALL-SCOPE',
        'Valider des données',
        'Valider des données dans GeoNature en étant limité par la portée.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.cor_module_action_object_filter AS cmaof
        WHERE cmaof.code = 'GEONATURE-V-ALL-SCOPE'
    ) ;

INSERT INTO gn_permissions.cor_module_action_object_filter (
    id_module, id_action, id_object, id_filter_type, code, label, description
) 
    SELECT
        gn_commons.get_id_module_bycode('GEONATURE'),
        gn_permissions.get_id_action('E'),
        gn_permissions.get_id_object('ALL'),
        gn_permissions.get_id_filter_type('SCOPE'),
        'GEONATURE-E-ALL-SCOPE',
        'Exporter des données',
        'Exporter des données dans GeoNature en étant limité par la portée.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.cor_module_action_object_filter AS cmaof
        WHERE cmaof.code = 'GEONATURE-E-ALL-SCOPE'
    ) ;

INSERT INTO gn_permissions.cor_module_action_object_filter (
    id_module, id_action, id_object, id_filter_type, code, label, description
) 
    SELECT
        gn_commons.get_id_module_bycode('GEONATURE'),
        gn_permissions.get_id_action('D'),
        gn_permissions.get_id_object('ALL'),
        gn_permissions.get_id_filter_type('SCOPE'),
        'GEONATURE-D-ALL-SCOPE',
        'Supprimer des données',
        'Supprimer des données dans GeoNature en étant limité par la portée.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.cor_module_action_object_filter AS cmaof
        WHERE cmaof.code = 'GEONATURE-D-ALL-SCOPE'
    ) ;

INSERT INTO gn_permissions.cor_module_action_object_filter (
    id_module, id_action, id_object, id_filter_type, code, label, description
) 
    SELECT
        gn_commons.get_id_module_bycode('ADMIN'),
        gn_permissions.get_id_action('C'),
        gn_permissions.get_id_object('ALL'),
        gn_permissions.get_id_filter_type('SCOPE'),
        'ADMIN-C-ALL-SCOPE',
        'Créer des données',
        'Créer des données dans le module Admin en étant limité par la portée.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.cor_module_action_object_filter AS cmaof
        WHERE cmaof.code = 'ADMIN-C-ALL-SCOPE'
    ) ;

INSERT INTO gn_permissions.cor_module_action_object_filter (
    id_module, id_action, id_object, id_filter_type, code, label, description
) 
    SELECT
        gn_commons.get_id_module_bycode('ADMIN'),
        gn_permissions.get_id_action('C'),
        gn_permissions.get_id_object('NOMENCLATURES'),
        gn_permissions.get_id_filter_type('SCOPE'),
        'ADMIN-C-NOMENCLATURES-SCOPE',
        'Créer des nomenclatures',
        'Créer des nomenclatures dans le module Admin en étant limité par la portée.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.cor_module_action_object_filter AS cmaof
        WHERE cmaof.code = 'ADMIN-C-NOMENCLATURES-SCOPE'
    ) ;

INSERT INTO gn_permissions.cor_module_action_object_filter (
    id_module, id_action, id_object, id_filter_type, code, label, description
) 
    SELECT
        gn_commons.get_id_module_bycode('ADMIN'),
        gn_permissions.get_id_action('C'),
        gn_permissions.get_id_object('PERMISSIONS'),
        gn_permissions.get_id_filter_type('SCOPE'),
        'ADMIN-C-PERMISSIONS-SCOPE',
        'Créer des permissions',
        'Créer des permissions dans le module Admin en étant limité par la portée.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.cor_module_action_object_filter AS cmaof
        WHERE cmaof.code = 'ADMIN-C-PERMISSIONS-SCOPE'
    ) ;

INSERT INTO gn_permissions.cor_module_action_object_filter (
    id_module, id_action, id_object, id_filter_type, code, label, description
) 
    SELECT
        gn_commons.get_id_module_bycode('ADMIN'),
        gn_permissions.get_id_action('R'),
        gn_permissions.get_id_object('ALL'),
        gn_permissions.get_id_filter_type('SCOPE'),
        'ADMIN-R-ALL-SCOPE',
        'Lire des données',
        'Lire des données dans le module Admin en étant limité par la portée.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.cor_module_action_object_filter AS cmaof
        WHERE cmaof.code = 'ADMIN-R-ALL-SCOPE'
    ) ;

INSERT INTO gn_permissions.cor_module_action_object_filter (
    id_module, id_action, id_object, id_filter_type, code, label, description
) 
    SELECT
        gn_commons.get_id_module_bycode('ADMIN'),
        gn_permissions.get_id_action('R'),
        gn_permissions.get_id_object('NOMENCLATURES'),
        gn_permissions.get_id_filter_type('SCOPE'),
        'ADMIN-R-NOMENCLATURES-SCOPE',
        'Lire des nomenclatures',
        'Lire des nomenclatures dans le module Admin en étant limité par la portée.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.cor_module_action_object_filter AS cmaof
        WHERE cmaof.code = 'ADMIN-R-NOMENCLATURES-SCOPE'
    ) ;

INSERT INTO gn_permissions.cor_module_action_object_filter (
    id_module, id_action, id_object, id_filter_type, code, label, description
) 
    SELECT
        gn_commons.get_id_module_bycode('ADMIN'),
        gn_permissions.get_id_action('R'),
        gn_permissions.get_id_object('PERMISSIONS'),
        gn_permissions.get_id_filter_type('SCOPE'),
        'ADMIN-R-PERMISSIONS-SCOPE',
        'Lire des permissions',
        'Lire des permissions dans le module Admin en étant limité par la portée.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.cor_module_action_object_filter AS cmaof
        WHERE cmaof.code = 'ADMIN-R-PERMISSIONS-SCOPE'
    ) ;

INSERT INTO gn_permissions.cor_module_action_object_filter (
    id_module, id_action, id_object, id_filter_type, code, label, description
) 
    SELECT
        gn_commons.get_id_module_bycode('ADMIN'),
        gn_permissions.get_id_action('U'),
        gn_permissions.get_id_object('ALL'),
        gn_permissions.get_id_filter_type('SCOPE'),
        'ADMIN-U-ALL-SCOPE',
        'Mettre à jour des données',
        'Mettre à jour des données dans le module Admin en étant limité par la portée.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.cor_module_action_object_filter AS cmaof
        WHERE cmaof.code = 'ADMIN-U-ALL-SCOPE'
    ) ;

INSERT INTO gn_permissions.cor_module_action_object_filter (
    id_module, id_action, id_object, id_filter_type, code, label, description
) 
    SELECT
        gn_commons.get_id_module_bycode('ADMIN'),
        gn_permissions.get_id_action('U'),
        gn_permissions.get_id_object('NOMENCLATURES'),
        gn_permissions.get_id_filter_type('SCOPE'),
        'ADMIN-U-NOMENCLATURES-SCOPE',
        'Mettre à jour des nomenclatures',
        'Mettre à jour des nomenclatures dans le module Admin en étant limité par la portée.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.cor_module_action_object_filter AS cmaof
        WHERE cmaof.code = 'ADMIN-U-NOMENCLATURES-SCOPE'
    ) ;

INSERT INTO gn_permissions.cor_module_action_object_filter (
    id_module, id_action, id_object, id_filter_type, code, label, description
) 
    SELECT
        gn_commons.get_id_module_bycode('ADMIN'),
        gn_permissions.get_id_action('U'),
        gn_permissions.get_id_object('PERMISSIONS'),
        gn_permissions.get_id_filter_type('SCOPE'),
        'ADMIN-U-PERMISSIONS-SCOPE',
        'Mettre à jour des permissions',
        'Mettre à jour des permissions dans le module Admin en étant limité par la portée.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.cor_module_action_object_filter AS cmaof
        WHERE cmaof.code = 'ADMIN-U-PERMISSIONS-SCOPE'
    ) ;

-- ADMIN-V-ALL-SCOPE : not used !
-- ADMIN-V-NOMENCLATURES-SCOPE : not used !
-- ADMIN-V-PERMISSIONS-SCOPE : not used !

INSERT INTO gn_permissions.cor_module_action_object_filter (
    id_module, id_action, id_object, id_filter_type, code, label, description
) 
    SELECT
        gn_commons.get_id_module_bycode('ADMIN'),
        gn_permissions.get_id_action('E'),
        gn_permissions.get_id_object('ALL'),
        gn_permissions.get_id_filter_type('SCOPE'),
        'ADMIN-E-ALL-SCOPE',
        'Exporter des données',
        'Exporter des données dans le module Admin en étant limité par la portée.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.cor_module_action_object_filter AS cmaof
        WHERE cmaof.code = 'ADMIN-E-ALL-SCOPE'
    ) ;

INSERT INTO gn_permissions.cor_module_action_object_filter (
    id_module, id_action, id_object, id_filter_type, code, label, description
) 
    SELECT
        gn_commons.get_id_module_bycode('ADMIN'),
        gn_permissions.get_id_action('E'),
        gn_permissions.get_id_object('NOMENCLATURES'),
        gn_permissions.get_id_filter_type('SCOPE'),
        'ADMIN-E-NOMENCLATURES-SCOPE',
        'Exporter des nomenclatures',
        'Exporter des nomenclatures dans le module Admin en étant limité par la portée.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.cor_module_action_object_filter AS cmaof
        WHERE cmaof.code = 'ADMIN-E-NOMENCLATURES-SCOPE'
    ) ;

INSERT INTO gn_permissions.cor_module_action_object_filter (
    id_module, id_action, id_object, id_filter_type, code, label, description
) 
    SELECT
        gn_commons.get_id_module_bycode('ADMIN'),
        gn_permissions.get_id_action('E'),
        gn_permissions.get_id_object('PERMISSIONS'),
        gn_permissions.get_id_filter_type('SCOPE'),
        'ADMIN-E-PERMISSIONS-SCOPE',
        'Exporter des permissions',
        'Exporter des permissions dans le module Admin en étant limité par la portée.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.cor_module_action_object_filter AS cmaof
        WHERE cmaof.code = 'ADMIN-E-PERMISSIONS-SCOPE'
    ) ;

INSERT INTO gn_permissions.cor_module_action_object_filter (
    id_module, id_action, id_object, id_filter_type, code, label, description
) 
    SELECT
        gn_commons.get_id_module_bycode('ADMIN'),
        gn_permissions.get_id_action('D'),
        gn_permissions.get_id_object('ALL'),
        gn_permissions.get_id_filter_type('SCOPE'),
        'ADMIN-D-ALL-SCOPE',
        'Supprimer des données',
        'Supprimer des données dans le module Admin en étant limité par la portée.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.cor_module_action_object_filter AS cmaof
        WHERE cmaof.code = 'ADMIN-D-ALL-SCOPE'
    ) ;

INSERT INTO gn_permissions.cor_module_action_object_filter (
    id_module, id_action, id_object, id_filter_type, code, label, description
) 
    SELECT
        gn_commons.get_id_module_bycode('ADMIN'),
        gn_permissions.get_id_action('D'),
        gn_permissions.get_id_object('NOMENCLATURES'),
        gn_permissions.get_id_filter_type('SCOPE'),
        'ADMIN-D-NOMENCLATURES-SCOPE',
        'Supprimer des nomenclatures',
        'Supprimer des nomenclatures dans le module Admin en étant limité par la portée.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.cor_module_action_object_filter AS cmaof
        WHERE cmaof.code = 'ADMIN-D-NOMENCLATURES-SCOPE'
    ) ;

INSERT INTO gn_permissions.cor_module_action_object_filter (
    id_module, id_action, id_object, id_filter_type, code, label, description
) 
    SELECT
        gn_commons.get_id_module_bycode('ADMIN'),
        gn_permissions.get_id_action('D'),
        gn_permissions.get_id_object('PERMISSIONS'),
        gn_permissions.get_id_filter_type('SCOPE'),
        'ADMIN-D-PERMISSIONS-SCOPE',
        'Supprimer des permissions',
        'Supprimer des permissions dans le module Admin en étant limité par la portée.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.cor_module_action_object_filter AS cmaof
        WHERE cmaof.code = 'ADMIN-D-PERMISSIONS-SCOPE'
    ) ;

INSERT INTO gn_permissions.cor_module_action_object_filter (
    id_module, id_action, id_object, id_filter_type, code, label, description
) 
    SELECT
        gn_commons.get_id_module_bycode('METADATA'),
        gn_permissions.get_id_action('C'),
        gn_permissions.get_id_object('ALL'),
        gn_permissions.get_id_filter_type('SCOPE'),
        'METADATA-C-ALL-SCOPE',
        'Créer des données',
        'Créer des données dans le module Métadonnées en étant limité par la portée.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.cor_module_action_object_filter AS cmaof
        WHERE cmaof.code = 'METADATA-C-ALL-SCOPE'
    ) ;

INSERT INTO gn_permissions.cor_module_action_object_filter (
    id_module, id_action, id_object, id_filter_type, code, label, description
) 
    SELECT
        gn_commons.get_id_module_bycode('METADATA'),
        gn_permissions.get_id_action('R'),
        gn_permissions.get_id_object('ALL'),
        gn_permissions.get_id_filter_type('SCOPE'),
        'METADATA-R-ALL-SCOPE',
        'Lire les données',
        'Lire les données dans le module Métadonnées limitées en étant limité par la portée.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.cor_module_action_object_filter AS cmaof
        WHERE cmaof.code = 'METADATA-R-ALL-SCOPE'
    ) ;

INSERT INTO gn_permissions.cor_module_action_object_filter (
    id_module, id_action, id_object, id_filter_type, code, label, description
) 
    SELECT
        gn_commons.get_id_module_bycode('METADATA'),
        gn_permissions.get_id_action('U'),
        gn_permissions.get_id_object('ALL'),
        gn_permissions.get_id_filter_type('SCOPE'),
        'METADATA-U-ALL-SCOPE',
        'Mettre à jour des données',
        'Mettre à jour des données dans le module Métadonnées en étant limité par la portée.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.cor_module_action_object_filter AS cmaof
        WHERE cmaof.code = 'METADATA-U-ALL-SCOPE'
    ) ;

INSERT INTO gn_permissions.cor_module_action_object_filter (
    id_module, id_action, id_object, id_filter_type, code, label, description
) 
    SELECT
        gn_commons.get_id_module_bycode('METADATA'),
        gn_permissions.get_id_action('V'),
        gn_permissions.get_id_object('ALL'),
        gn_permissions.get_id_filter_type('SCOPE'),
        'METADATA-V-ALL-SCOPE',
        'Valider des données',
        'Valider des données dans le module Métadonnées en étant limité par la portée.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.cor_module_action_object_filter AS cmaof
        WHERE cmaof.code = 'METADATA-V-ALL-SCOPE'
    ) ;

INSERT INTO gn_permissions.cor_module_action_object_filter (
    id_module, id_action, id_object, id_filter_type, code, label, description
) 
    SELECT
        gn_commons.get_id_module_bycode('METADATA'),
        gn_permissions.get_id_action('E'),
        gn_permissions.get_id_object('ALL'),
        gn_permissions.get_id_filter_type('SCOPE'),
        'METADATA-E-ALL-SCOPE',
        'Exporter des données',
        'Exporter des données dans le module Métadonnées en étant limité par la portée.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.cor_module_action_object_filter AS cmaof
        WHERE cmaof.code = 'METADATA-E-ALL-SCOPE'
    ) ;

INSERT INTO gn_permissions.cor_module_action_object_filter (
    id_module, id_action, id_object, id_filter_type, code, label, description
) 
    SELECT
        gn_commons.get_id_module_bycode('METADATA'),
        gn_permissions.get_id_action('D'),
        gn_permissions.get_id_object('ALL'),
        gn_permissions.get_id_filter_type('SCOPE'),
        'METADATA-D-ALL-SCOPE',
        'Supprimer des données',
        'Supprimer des données dans le module Métadonnées en étant limité par la portée.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.cor_module_action_object_filter AS cmaof
        WHERE cmaof.code = 'METADATA-D-ALL-SCOPE'
    ) ;

-- TODO: Add all SYNTHESE permission for ALL object

-- ----------------------------------------------------------------------
INSERT INTO gn_permissions.cor_module_action_object_filter (
    id_module, id_action, id_object, id_filter_type, code, label, description
) 
    SELECT
        gn_commons.get_id_module_bycode('SYNTHESE'),
        gn_permissions.get_id_action('R'),
        gn_permissions.get_id_object('ALL'),
        gn_permissions.get_id_filter_type('SCOPE'),
        'SYNTHESE-R-ALL-SCOPE',
        'Lire des données',
        'Lire des données dans le module Synthèse en étant limité par la portée.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.cor_module_action_object_filter AS cmaof
        WHERE cmaof.code = 'SYNTHESE-R-ALL-SCOPE'
    ) ;

INSERT INTO gn_permissions.cor_module_action_object_filter (
    id_module, id_action, id_object, id_filter_type, code, label, description
) 
    SELECT
        gn_commons.get_id_module_bycode('SYNTHESE'),
        gn_permissions.get_id_action('E'),
        gn_permissions.get_id_object('ALL'),
        gn_permissions.get_id_filter_type('SCOPE'),
        'SYNTHESE-E-ALL-SCOPE',
        'Exporter des données',
        'Exporter des données dans le module Synthèse en étant limité par la portée.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.cor_module_action_object_filter AS cmaof
        WHERE cmaof.code = 'SYNTHESE-E-ALL-SCOPE'
    ) ;

INSERT INTO gn_permissions.cor_module_action_object_filter (
    id_module, id_action, id_object, id_filter_type, code, label, description
) 
    SELECT
        gn_commons.get_id_module_bycode('SYNTHESE'),
        gn_permissions.get_id_action('R'),
        gn_permissions.get_id_object('PRIVATE_OBSERVATION'),
        gn_permissions.get_id_filter_type('PRECISION'),
        'SYNTHESE-R-PRIVATE_OBSERVATION-PRECISION',
        'Lire des observations privées',
        'Lire des observations privées dans le module Synthèse en étant limité par la précision.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.cor_module_action_object_filter AS cmaof
        WHERE cmaof.code = 'SYNTHESE-R-PRIVATE_OBSERVATION-PRECISION'
    ) ;

INSERT INTO gn_permissions.cor_module_action_object_filter (
    id_module, id_action, id_object, id_filter_type, code, label, description
) 
    SELECT
        gn_commons.get_id_module_bycode('SYNTHESE'),
        gn_permissions.get_id_action('R'),
        gn_permissions.get_id_object('PRIVATE_OBSERVATION'),
        gn_permissions.get_id_filter_type('SCOPE'),
        'SYNTHESE-R-PRIVATE_OBSERVATION-SCOPE',
        'Lire des observations privées',
        'Lire des observations privées dans le module Synthèse en étant limité par la portée.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.cor_module_action_object_filter AS cmaof
        WHERE cmaof.code = 'SYNTHESE-R-PRIVATE_OBSERVATION-SCOPE'
    ) ;

INSERT INTO gn_permissions.cor_module_action_object_filter (
    id_module, id_action, id_object, id_filter_type, code, label, description
) 
    SELECT
        gn_commons.get_id_module_bycode('SYNTHESE'),
        gn_permissions.get_id_action('R'),
        gn_permissions.get_id_object('PRIVATE_OBSERVATION'),
        gn_permissions.get_id_filter_type('GEOGRAPHIC'),
        'SYNTHESE-R-PRIVATE_OBSERVATION-GEOGRAPHIC',
        'Lire des observations privées',
        'Lire des observations privées dans le module Synthèse en étant limité par zones géographiques.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.cor_module_action_object_filter AS cmaof
        WHERE cmaof.code = 'SYNTHESE-R-PRIVATE_OBSERVATION-GEOGRAPHIC'
    ) ;

INSERT INTO gn_permissions.cor_module_action_object_filter (
    id_module, id_action, id_object, id_filter_type, code, label, description
) 
    SELECT
        gn_commons.get_id_module_bycode('SYNTHESE'),
        gn_permissions.get_id_action('R'),
        gn_permissions.get_id_object('PRIVATE_OBSERVATION'),
        gn_permissions.get_id_filter_type('TAXONOMIC'),
        'SYNTHESE-R-PRIVATE_OBSERVATION-TAXONOMIC',
        'Lire des observations privées',
        'Lire des observations privées dans le module Synthèse en étant limité par des taxons.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.cor_module_action_object_filter AS cmaof
        WHERE cmaof.code = 'SYNTHESE-R-PRIVATE_OBSERVATION-TAXONOMIC'
    ) ;
-- ----------------------------------------------------------------------
INSERT INTO gn_permissions.cor_module_action_object_filter (
    id_module, id_action, id_object, id_filter_type, code, label, description
) 
    SELECT
        gn_commons.get_id_module_bycode('SYNTHESE'),
        gn_permissions.get_id_action('E'),
        gn_permissions.get_id_object('PRIVATE_OBSERVATION'),
        gn_permissions.get_id_filter_type('PRECISION'),
        'SYNTHESE-E-PRIVATE_OBSERVATION-PRECISION',
        'Exporter des observations privées',
        'Exporter des observations privées dans le module Synthèse en étant limité par la précision.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.cor_module_action_object_filter AS cmaof
        WHERE cmaof.code = 'SYNTHESE-E-PRIVATE_OBSERVATION-PRECISION'
    ) ;

INSERT INTO gn_permissions.cor_module_action_object_filter (
    id_module, id_action, id_object, id_filter_type, code, label, description
) 
    SELECT
        gn_commons.get_id_module_bycode('SYNTHESE'),
        gn_permissions.get_id_action('E'),
        gn_permissions.get_id_object('PRIVATE_OBSERVATION'),
        gn_permissions.get_id_filter_type('SCOPE'),
        'SYNTHESE-E-PRIVATE_OBSERVATION-SCOPE',
        'Exporter des observations privées',
        'Exporter des observations privées dans le module Synthèse en étant limité par la portée.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.cor_module_action_object_filter AS cmaof
        WHERE cmaof.code = 'SYNTHESE-E-PRIVATE_OBSERVATION-SCOPE'
    ) ;

INSERT INTO gn_permissions.cor_module_action_object_filter (
    id_module, id_action, id_object, id_filter_type, code, label, description
) 
    SELECT
        gn_commons.get_id_module_bycode('SYNTHESE'),
        gn_permissions.get_id_action('E'),
        gn_permissions.get_id_object('PRIVATE_OBSERVATION'),
        gn_permissions.get_id_filter_type('GEOGRAPHIC'),
        'SYNTHESE-E-PRIVATE_OBSERVATION-GEOGRAPHIC',
        'Exporter des observations privées',
        'Exporter des observations privées dans le module Synthèse en étant limité par zones géographiques.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.cor_module_action_object_filter AS cmaof
        WHERE cmaof.code = 'SYNTHESE-E-PRIVATE_OBSERVATION-GEOGRAPHIC'
    ) ;

INSERT INTO gn_permissions.cor_module_action_object_filter (
    id_module, id_action, id_object, id_filter_type, code, label, description
) 
    SELECT
        gn_commons.get_id_module_bycode('SYNTHESE'),
        gn_permissions.get_id_action('E'),
        gn_permissions.get_id_object('PRIVATE_OBSERVATION'),
        gn_permissions.get_id_filter_type('TAXONOMIC'),
        'SYNTHESE-R-PRIVATE_OBSERVATION-TAXONOMIC',
        'Exporter des observations privées',
        'Exporter des observations privées dans le module Synthèse en étant limité par des taxons.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.cor_module_action_object_filter AS cmaof
        WHERE cmaof.code = 'SYNTHESE-E-PRIVATE_OBSERVATION-TAXONOMIC'
    ) ;
-- ----------------------------------------------------------------------
INSERT INTO gn_permissions.cor_module_action_object_filter (
    id_module, id_action, id_object, id_filter_type, code, label, description
) 
    SELECT
        gn_commons.get_id_module_bycode('SYNTHESE'),
        gn_permissions.get_id_action('R'),
        gn_permissions.get_id_object('SENSITIVE_OBSERVATION'),
        gn_permissions.get_id_filter_type('PRECISION'),
        'SYNTHESE-R-SENSITIVE_OBSERVATION-PRECISION',
        'Lire des observations sensibles',
        'Lire des observations sensibles dans le module Synthèse en étant limité par la précision.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.cor_module_action_object_filter AS cmaof
        WHERE cmaof.code = 'SYNTHESE-R-SENSITIVE_OBSERVATION-PRECISION'
    ) ;

INSERT INTO gn_permissions.cor_module_action_object_filter (
    id_module, id_action, id_object, id_filter_type, code, label, description
) 
    SELECT
        gn_commons.get_id_module_bycode('SYNTHESE'),
        gn_permissions.get_id_action('R'),
        gn_permissions.get_id_object('SENSITIVE_OBSERVATION'),
        gn_permissions.get_id_filter_type('SCOPE'),
        'SYNTHESE-R-SENSITIVE_OBSERVATION-SCOPE',
        'Lire des observations sensibles',
        'Lire des observations sensibles dans le module Synthèse en étant limité par la portée.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.cor_module_action_object_filter AS cmaof
        WHERE cmaof.code = 'SYNTHESE-R-SENSITIVE_OBSERVATION-SCOPE'
    ) ;

INSERT INTO gn_permissions.cor_module_action_object_filter (
    id_module, id_action, id_object, id_filter_type, code, label, description
) 
    SELECT
        gn_commons.get_id_module_bycode('SYNTHESE'),
        gn_permissions.get_id_action('R'),
        gn_permissions.get_id_object('SENSITIVE_OBSERVATION'),
        gn_permissions.get_id_filter_type('GEOGRAPHIC'),
        'SYNTHESE-R-SENSITIVE_OBSERVATION-GEOGRAPHIC',
        'Lire des observations sensibles',
        'Lire des observations sensibles dans le module Synthèse en étant limité par zones géographiques.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.cor_module_action_object_filter AS cmaof
        WHERE cmaof.code = 'SYNTHESE-R-SENSITIVE_OBSERVATION-GEOGRAPHIC'
    ) ;

INSERT INTO gn_permissions.cor_module_action_object_filter (
    id_module, id_action, id_object, id_filter_type, code, label, description
) 
    SELECT
        gn_commons.get_id_module_bycode('SYNTHESE'),
        gn_permissions.get_id_action('R'),
        gn_permissions.get_id_object('SENSITIVE_OBSERVATION'),
        gn_permissions.get_id_filter_type('TAXONOMIC'),
        'SYNTHESE-R-SENSITIVE_OBSERVATION-TAXONOMIC',
        'Lire des observations sensibles',
        'Lire des observations sensibles dans le module Synthèse en étant limité par des taxons.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.cor_module_action_object_filter AS cmaof
        WHERE cmaof.code = 'SYNTHESE-R-SENSITIVE_OBSERVATION-TAXONOMIC'
    ) ;
-- ----------------------------------------------------------------------
INSERT INTO gn_permissions.cor_module_action_object_filter (
    id_module, id_action, id_object, id_filter_type, code, label, description
) 
    SELECT
        gn_commons.get_id_module_bycode('SYNTHESE'),
        gn_permissions.get_id_action('E'),
        gn_permissions.get_id_object('SENSITIVE_OBSERVATION'),
        gn_permissions.get_id_filter_type('PRECISION'),
        'SYNTHESE-E-SENSITIVE_OBSERVATION-PRECISION',
        'Exporter des observations sensibles',
        'Exporter des observations sensibles dans le module Synthèse en étant limité par la précision.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.cor_module_action_object_filter AS cmaof
        WHERE cmaof.code = 'SYNTHESE-E-SENSITIVE_OBSERVATION-PRECISION'
    ) ;

INSERT INTO gn_permissions.cor_module_action_object_filter (
    id_module, id_action, id_object, id_filter_type, code, label, description
) 
    SELECT
        gn_commons.get_id_module_bycode('SYNTHESE'),
        gn_permissions.get_id_action('E'),
        gn_permissions.get_id_object('SENSITIVE_OBSERVATION'),
        gn_permissions.get_id_filter_type('SCOPE'),
        'SYNTHESE-E-SENSITIVE_OBSERVATION-SCOPE',
        'Exporter des observations sensibles',
        'Exporter des observations sensibles dans le module Synthèse en étant limité par la portée.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.cor_module_action_object_filter AS cmaof
        WHERE cmaof.code = 'SYNTHESE-E-SENSITIVE_OBSERVATION-SCOPE'
    ) ;

INSERT INTO gn_permissions.cor_module_action_object_filter (
    id_module, id_action, id_object, id_filter_type, code, label, description
) 
    SELECT
        gn_commons.get_id_module_bycode('SYNTHESE'),
        gn_permissions.get_id_action('E'),
        gn_permissions.get_id_object('SENSITIVE_OBSERVATION'),
        gn_permissions.get_id_filter_type('GEOGRAPHIC'),
        'SYNTHESE-E-SENSITIVE_OBSERVATION-GEOGRAPHIC',
        'Exporter des observations sensibles',
        'Exporter des observations sensibles dans le module Synthèse en étant limité par zones géographiques.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.cor_module_action_object_filter AS cmaof
        WHERE cmaof.code = 'SYNTHESE-E-SENSITIVE_OBSERVATION-GEOGRAPHIC'
    ) ;

INSERT INTO gn_permissions.cor_module_action_object_filter (
    id_module, id_action, id_object, id_filter_type, code, label, description
) 
    SELECT
        gn_commons.get_id_module_bycode('SYNTHESE'),
        gn_permissions.get_id_action('E'),
        gn_permissions.get_id_object('SENSITIVE_OBSERVATION'),
        gn_permissions.get_id_filter_type('TAXONOMIC'),
        'SYNTHESE-R-SENSITIVE_OBSERVATION-TAXONOMIC',
        'Exporter des observations sensibles',
        'Exporter des observations sensibles dans le module Synthèse en étant limité par des taxons.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.cor_module_action_object_filter AS cmaof
        WHERE cmaof.code = 'SYNTHESE-E-SENSITIVE_OBSERVATION-TAXONOMIC'
    ) ;
-- ----------------------------------------------------------------------
INSERT INTO gn_permissions.cor_module_action_object_filter (
    id_module, id_action, id_object, id_filter_type, code, label, description
) 
    SELECT
        gn_commons.get_id_module_bycode('VALIDATION'),
        gn_permissions.get_id_action('R'),
        gn_permissions.get_id_object('PRIVATE_OBSERVATION'),
        gn_permissions.get_id_filter_type('PRECISION'),
        'VALIDATION-R-PRIVATE_OBSERVATION-PRECISION',
        'Lire des observations privées',
        'Lire des observations privées dans le module Validation en étant limité par la précision.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.cor_module_action_object_filter AS cmaof
        WHERE cmaof.code = 'VALIDATION-R-PRIVATE_OBSERVATION-PRECISION'
    ) ;

INSERT INTO gn_permissions.cor_module_action_object_filter (
    id_module, id_action, id_object, id_filter_type, code, label, description
) 
    SELECT
        gn_commons.get_id_module_bycode('VALIDATION'),
        gn_permissions.get_id_action('R'),
        gn_permissions.get_id_object('PRIVATE_OBSERVATION'),
        gn_permissions.get_id_filter_type('SCOPE'),
        'VALIDATION-R-PRIVATE_OBSERVATION-SCOPE',
        'Lire des observations privées',
        'Lire des observations privées dans le module Validation en étant limité par la portée.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.cor_module_action_object_filter AS cmaof
        WHERE cmaof.code = 'VALIDATION-R-PRIVATE_OBSERVATION-SCOPE'
    ) ;

INSERT INTO gn_permissions.cor_module_action_object_filter (
    id_module, id_action, id_object, id_filter_type, code, label, description
) 
    SELECT
        gn_commons.get_id_module_bycode('VALIDATION'),
        gn_permissions.get_id_action('R'),
        gn_permissions.get_id_object('PRIVATE_OBSERVATION'),
        gn_permissions.get_id_filter_type('GEOGRAPHIC'),
        'VALIDATION-R-PRIVATE_OBSERVATION-GEOGRAPHIC',
        'Lire des observations privées',
        'Lire des observations privées dans le module Validation en étant limité par zones géographiques.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.cor_module_action_object_filter AS cmaof
        WHERE cmaof.code = 'VALIDATION-R-PRIVATE_OBSERVATION-GEOGRAPHIC'
    ) ;

INSERT INTO gn_permissions.cor_module_action_object_filter (
    id_module, id_action, id_object, id_filter_type, code, label, description
) 
    SELECT
        gn_commons.get_id_module_bycode('VALIDATION'),
        gn_permissions.get_id_action('R'),
        gn_permissions.get_id_object('PRIVATE_OBSERVATION'),
        gn_permissions.get_id_filter_type('TAXONOMIC'),
        'VALIDATION-R-PRIVATE_OBSERVATION-TAXONOMIC',
        'Lire des observations privées',
        'Lire des observations privées dans le module Validation en étant limité par des taxons.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.cor_module_action_object_filter AS cmaof
        WHERE cmaof.code = 'VALIDATION-R-PRIVATE_OBSERVATION-TAXONOMIC'
    ) ;
-- ----------------------------------------------------------------------
INSERT INTO gn_permissions.cor_module_action_object_filter (
    id_module, id_action, id_object, id_filter_type, code, label, description
) 
    SELECT
        gn_commons.get_id_module_bycode('VALIDATION'),
        gn_permissions.get_id_action('R'),
        gn_permissions.get_id_object('SENSITIVE_OBSERVATION'),
        gn_permissions.get_id_filter_type('PRECISION'),
        'VALIDATION-R-SENSITIVE_OBSERVATION-PRECISION',
        'Lire des observations sensibles',
        'Lire des observations sensibles dans le module Validation en étant limité par la précision.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.cor_module_action_object_filter AS cmaof
        WHERE cmaof.code = 'VALIDATION-R-SENSITIVE_OBSERVATION-PRECISION'
    ) ;

INSERT INTO gn_permissions.cor_module_action_object_filter (
    id_module, id_action, id_object, id_filter_type, code, label, description
) 
    SELECT
        gn_commons.get_id_module_bycode('VALIDATION'),
        gn_permissions.get_id_action('R'),
        gn_permissions.get_id_object('SENSITIVE_OBSERVATION'),
        gn_permissions.get_id_filter_type('SCOPE'),
        'VALIDATION-R-SENSITIVE_OBSERVATION-SCOPE',
        'Lire des observations sensibles',
        'Lire des observations sensibles dans le module Validation en étant limité par la portée.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.cor_module_action_object_filter AS cmaof
        WHERE cmaof.code = 'VALIDATION-R-SENSITIVE_OBSERVATION-SCOPE'
    ) ;

INSERT INTO gn_permissions.cor_module_action_object_filter (
    id_module, id_action, id_object, id_filter_type, code, label, description
) 
    SELECT
        gn_commons.get_id_module_bycode('VALIDATION'),
        gn_permissions.get_id_action('R'),
        gn_permissions.get_id_object('SENSITIVE_OBSERVATION'),
        gn_permissions.get_id_filter_type('GEOGRAPHIC'),
        'VALIDATION-R-SENSITIVE_OBSERVATION-GEOGRAPHIC',
        'Lire des observations sensibles',
        'Lire des observations sensibles dans le module Validation en étant limité par zones géographiques.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.cor_module_action_object_filter AS cmaof
        WHERE cmaof.code = 'VALIDATION-R-SENSITIVE_OBSERVATION-GEOGRAPHIC'
    ) ;

INSERT INTO gn_permissions.cor_module_action_object_filter (
    id_module, id_action, id_object, id_filter_type, code, label, description
) 
    SELECT
        gn_commons.get_id_module_bycode('VALIDATION'),
        gn_permissions.get_id_action('R'),
        gn_permissions.get_id_object('SENSITIVE_OBSERVATION'),
        gn_permissions.get_id_filter_type('TAXONOMIC'),
        'VALIDATION-R-SENSITIVE_OBSERVATION-TAXONOMIC',
        'Lire des observations sensibles',
        'Lire des observations sensibles dans le module Validation en étant limité par des taxons.'
    WHERE NOT EXISTS (
        SELECT 'X'
        FROM gn_permissions.cor_module_action_object_filter AS cmaof
        WHERE cmaof.code = 'VALIDATION-R-SENSITIVE_OBSERVATION-TAXONOMIC'
    ) ;


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
-- Migrate "t_filters" entries
UPDATE gn_permissions.cor_role_action_filter_module_object AS c
SET 
    id_filter_type = f.id_filter_type,
    value_filter = f.value_filter
FROM gn_permissions.t_filters AS f
WHERE c.id_filter = f.id_filter 
    AND c.id_filter_type IS NULL
    AND c.value_filter IS NULL ;

-- TODO: uncomment the database cleaning queries.
-- -------------------------------------------------------------------------------------------------
-- Remove useless column from cor_role_action_filter_module_object
-- ALTER TABLE gn_permissions.cor_role_action_filter_module_object
--     DROP COLUMN id_filter IF EXISTS, 
--     DROP CONSTRAINT IF EXISTS fk_cor_r_a_f_m_o_id_filter CASCADE ;

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
