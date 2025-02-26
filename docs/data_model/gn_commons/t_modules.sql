
CREATE TABLE gn_commons.t_modules (
    id_module integer NOT NULL,
    module_code character varying(50) NOT NULL,
    module_label character varying(255) NOT NULL,
    module_picto character varying(255),
    module_desc text,
    module_group character varying(50),
    module_path character varying(255),
    module_external_url character varying(255),
    module_target character varying(10),
    module_comment text,
    active_frontend boolean NOT NULL,
    active_backend boolean NOT NULL,
    module_doc_url character varying(255),
    module_order integer,
    type character varying(255) DEFAULT 'base'::character varying NOT NULL,
    meta_create_date timestamp without time zone DEFAULT now(),
    meta_update_date timestamp without time zone DEFAULT now(),
    ng_module character varying(500),
    CONSTRAINT check_urls_not_null CHECK (((module_path IS NOT NULL) OR (module_external_url IS NOT NULL)))
);

COMMENT ON COLUMN gn_commons.t_modules.id_module IS 'PK mais aussi FK vers la table "utilisateurs.t_applications". ATTENTION de ne pas utiliser l''identifiant d''une application existante dans cette table et qui ne serait pas un module de GeoNature';

COMMENT ON COLUMN gn_commons.t_modules.module_path IS 'url relative vers le module - si module interne';

COMMENT ON COLUMN gn_commons.t_modules.module_external_url IS 'url absolue vers le module - si module externe (active_frontend = false)';

COMMENT ON COLUMN gn_commons.t_modules.module_target IS 'Value = NULL ou "blank". On peux ainsi référencer des modules externes et les ouvrir dans un nouvel onglet.';

CREATE SEQUENCE gn_commons.t_modules_id_module_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE gn_commons.t_modules_id_module_seq OWNED BY gn_commons.t_modules.id_module;

ALTER TABLE ONLY gn_commons.t_modules
    ADD CONSTRAINT pk_t_modules PRIMARY KEY (id_module);

ALTER TABLE ONLY gn_commons.t_modules
    ADD CONSTRAINT unique_t_modules_module_code UNIQUE (module_code);

ALTER TABLE ONLY gn_commons.t_modules
    ADD CONSTRAINT unique_t_modules_module_path UNIQUE (module_path);

CREATE TRIGGER tri_meta_dates_change_t_modules BEFORE INSERT OR UPDATE ON gn_commons.t_modules FOR EACH ROW EXECUTE FUNCTION public.fct_trg_meta_dates_change();

