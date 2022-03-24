-- tables pour gérer les référentiels géographiques linéaires (routes, etc..)
-- - ref_geo.bib_linears_types
-- - ref_geo.l_linear


-- table des types de lineaires (routes, voie ferrées, voies fluviales, corridors, etc ....)

CREATE TABLE ref_geo.bib_linears_types (
    id_type SERIAL NOT NULL,
    type_name character varying(200) NOT NULL,
    type_code character varying(25) NOT NULL,
    type_desc text,
    ref_name character varying(200),
    ref_version integer,
    num_version character varying(50),
    meta_create_date timestamp without time zone,
    meta_update_date timestamp without time zone,

    CONSTRAINT pk_ref_geo_bib_linears_types_id_type PRIMARY KEY (id_type),

    UNIQUE(type_code)
);

-- table des linéaires (tronçon de route, etc..)

CREATE TABLE ref_geo.l_linears (
    id_linear SERIAL NOT NULL,
    id_type INTEGER NOT NULL,
    linear_name character varying(250) NOT NULL,
    linear_code character varying(25) NOT NULL,
    enable BOOLEAN NOT NULL DEFAULT (TRUE),
    geom GEOMETRY(GEOMETRY, :local_srid),
    geojson_4326 VARCHAR,
    source character varying(250),
    additional_data jsonb NULL,
    meta_create_date timestamp without time zone,
    meta_update_date timestamp without time zone,

    UNIQUE (id_type, linear_code),

    CONSTRAINT pk_ref_geo_l_linears_id_linear PRIMARY KEY (id_linear),
    CONSTRAINT fk_ref_geo_l_linears_id_type FOREIGN KEY (id_type)
        REFERENCES ref_geo.bib_linears_types(id_type)
        ON UPDATE CASCADE ON DELETE NO ACTION
);

-- index geom

CREATE INDEX ref_geo_l_linears_geom_idx ON ref_geo.l_linears USING GIST(geom);


-- groupe de linéaire, (par ex, une route est un groupe qui contient l'ensemble de ses tronçons)

CREATE TABLE ref_geo.t_linear_groups (
    id_group SERIAL NOT NULL,
    name character varying(250) NOT NULL,
    code character varying(25) NOT NULL,
    UNIQUE (code),
    CONSTRAINT pk_ref_geo_linear_group_id_group PRIMARY KEY (id_group)
);

-- correlation groupes - linear

CREATE TABLE ref_geo.cor_linear_group (
    id_group INTEGER NOT NULL,
    id_linear INTEGER NOT NULL,
    CONSTRAINT pk_ref_geo_cor_linear_group PRIMARY KEY (id_group,id_linear),
    CONSTRAINT fk_ref_geo_cor_linear_group_id_group FOREIGN KEY (id_group)
        REFERENCES ref_geo.t_linear_groups(id_group)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_ref_geo_cor_linear_group_id_linear FOREIGN KEY (id_linear)
        REFERENCES ref_geo.l_linears(id_linear)
        ON UPDATE CASCADE ON DELETE CASCADE
);
