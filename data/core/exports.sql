SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;


CREATE SCHEMA IF NOT EXISTS gn_exports;


SET search_path = gn_exports, pg_catalog;


CREATE TABLE t_config_exports (
    id_export integer NOT NULL,
    export_schema_name character varying(255),
    export_view_name character varying(255),
    export_button_name character varying(255),
    export_desc character varying(255)
);
COMMENT ON TABLE t_config_exports IS 'this table is used to declare views intended for export.';
COMMENT ON COLUMN t_config_exports.id_export IS 'Internal value for primary keys';
COMMENT ON COLUMN t_config_exports.export_schema_name IS 'Schema name where the view is stored';
COMMENT ON COLUMN t_config_exports.export_view_name IS 'the view name';
COMMENT ON COLUMN t_config_exports.export_button_name IS 'Export name to display in the button label';
COMMENT ON COLUMN t_config_exports.export_desc IS 'Short or long text to explain the export and/or is content';
CREATE SEQUENCE t_config_exports_id_export_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE t_config_exports_id_export_seq OWNED BY t_config_exports.id_export;
ALTER TABLE ONLY t_config_exports ALTER COLUMN id_export SET DEFAULT nextval('t_config_exports_id_export_seq'::regclass);