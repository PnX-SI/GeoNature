
CREATE TABLE gn_commons.t_mobile_apps (
    id_mobile_app integer NOT NULL,
    app_code character varying(30),
    relative_path_apk character varying(255),
    url_apk character varying(255),
    package character varying(255),
    version_code character varying(10),
    url_settings character varying
);

COMMENT ON COLUMN gn_commons.t_mobile_apps.app_code IS 'Code de l''application mobile. Pas de FK vers t_modules car une application mobile ne correspond pas forcement à un module GN';

CREATE SEQUENCE gn_commons.t_mobile_apps_id_mobile_app_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE gn_commons.t_mobile_apps_id_mobile_app_seq OWNED BY gn_commons.t_mobile_apps.id_mobile_app;

ALTER TABLE ONLY gn_commons.t_mobile_apps
    ADD CONSTRAINT pk_t_moobile_apps PRIMARY KEY (id_mobile_app);

ALTER TABLE ONLY gn_commons.t_mobile_apps
    ADD CONSTRAINT unique_t_mobile_apps_app_code UNIQUE (app_code);

