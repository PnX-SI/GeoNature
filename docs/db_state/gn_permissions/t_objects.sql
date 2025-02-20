
CREATE TABLE gn_permissions.t_objects (
    id_object integer NOT NULL,
    code_object character varying(50) NOT NULL,
    description_object text
);

CREATE SEQUENCE gn_permissions.t_objects_id_object_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE gn_permissions.t_objects_id_object_seq OWNED BY gn_permissions.t_objects.id_object;

ALTER TABLE ONLY gn_permissions.t_objects
    ADD CONSTRAINT pk_t_objects PRIMARY KEY (id_object);

ALTER TABLE ONLY gn_permissions.t_objects
    ADD CONSTRAINT unique_t_objects UNIQUE (code_object);

