
CREATE TABLE ref_geo.t_linear_groups (
    id_group integer NOT NULL,
    name character varying(250) NOT NULL,
    code character varying(25) NOT NULL
);

CREATE SEQUENCE ref_geo.t_linear_groups_id_group_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE ref_geo.t_linear_groups_id_group_seq OWNED BY ref_geo.t_linear_groups.id_group;

ALTER TABLE ONLY ref_geo.t_linear_groups
    ADD CONSTRAINT pk_ref_geo_linear_group_id_group PRIMARY KEY (id_group);

ALTER TABLE ONLY ref_geo.t_linear_groups
    ADD CONSTRAINT t_linear_groups_code_key UNIQUE (code);

