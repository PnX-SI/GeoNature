
CREATE TABLE gn_permissions.cor_object_module (
    id_cor_object_module integer NOT NULL,
    id_object integer NOT NULL,
    id_module integer NOT NULL
);

CREATE SEQUENCE gn_permissions.cor_object_module_id_cor_object_module_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE gn_permissions.cor_object_module_id_cor_object_module_seq OWNED BY gn_permissions.cor_object_module.id_cor_object_module;

ALTER TABLE ONLY gn_permissions.cor_object_module
    ADD CONSTRAINT pk_cor_object_module PRIMARY KEY (id_cor_object_module);

ALTER TABLE ONLY gn_permissions.cor_object_module
    ADD CONSTRAINT unique_cor_object_module UNIQUE (id_object, id_module);

ALTER TABLE ONLY gn_permissions.cor_object_module
    ADD CONSTRAINT fk_cor_object_module_id_module FOREIGN KEY (id_module) REFERENCES gn_commons.t_modules(id_module) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY gn_permissions.cor_object_module
    ADD CONSTRAINT fk_cor_object_module_id_object FOREIGN KEY (id_object) REFERENCES gn_permissions.t_objects(id_object) ON UPDATE CASCADE ON DELETE CASCADE;

