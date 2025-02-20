
CREATE TABLE gn_commons.cor_field_object (
    id_field integer NOT NULL,
    id_object integer NOT NULL
);

ALTER TABLE ONLY gn_commons.cor_field_object
    ADD CONSTRAINT pk_cor_field_object PRIMARY KEY (id_field, id_object);

ALTER TABLE ONLY gn_commons.cor_field_object
    ADD CONSTRAINT fk_cor_field_obj_field FOREIGN KEY (id_field) REFERENCES gn_commons.t_additional_fields(id_field) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY gn_commons.cor_field_object
    ADD CONSTRAINT fk_cor_field_object FOREIGN KEY (id_object) REFERENCES gn_permissions.t_objects(id_object) ON UPDATE CASCADE ON DELETE CASCADE;

