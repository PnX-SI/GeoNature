

-- Ajout de contraintes d'unicité sur les permissions
ALTER TABLE gn_permissions.cor_object_module ADD CONSTRAINT unique_cor_object_module UNIQUE (id_object,id_module);

ALTER TABLE gn_permissions.t_objects ADD CONSTRAINT unique_t_objects UNIQUE (code_object);

-- Ajout de champs à la table t_modules
ALTER TABLE gn_commons.t_modules ADD type CHARACTER VARYING(255);  -- polymorphisme
ALTER TABLE gn_commons.t_modules ADD meta_create_date timestamp without time zone DEFAULT now();
ALTER TABLE gn_commons.t_modules ADD meta_update_date timestamp without time zone DEFAULT now();
CREATE TRIGGER tri_meta_dates_change_t_modules
      BEFORE INSERT OR UPDATE
      ON gn_commons.t_modules
      FOR EACH ROW
      EXECUTE PROCEDURE public.fct_trg_meta_dates_change();
