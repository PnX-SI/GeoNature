

-- Ajout de contraintes d'unicité sur les permissions
ALTER TABLE gn_permissions.cor_object_module ADD CONSTRAINT unique_cor_object_module UNIQUE (id_object,id_module);

ALTER TABLE gn_permissions.t_objects ADD CONSTRAINT unique_t_objects UNIQUE (code_object);

ALTER TABLE gn_commons.t_modules ADD type CHARACTER VARYING(255);
ALTER TABLE gn_commons.t_modules ADD meta_create_date timestamp without time zone DEFAULT now();
ALTER TABLE gn_commons.t_modules ADD meta_update_date timestamp without time zone DEFAULT now();
