
CREATE TABLE utilisateurs.t_providers (
    id_provider integer NOT NULL,
    name character varying NOT NULL,
    url character varying
);

COMMENT ON COLUMN utilisateurs.t_providers.name IS 'Nom de l''instance du provider';

COMMENT ON COLUMN utilisateurs.t_providers.url IS 'L''url du fournisseur d''authentification';

CREATE SEQUENCE utilisateurs.t_providers_id_provider_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE utilisateurs.t_providers_id_provider_seq OWNED BY utilisateurs.t_providers.id_provider;

ALTER TABLE ONLY utilisateurs.t_providers
    ADD CONSTRAINT t_providers_pkey PRIMARY KEY (id_provider);

