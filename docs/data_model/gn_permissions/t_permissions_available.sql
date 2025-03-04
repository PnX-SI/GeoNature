
CREATE TABLE gn_permissions.t_permissions_available (
    id_module integer NOT NULL,
    id_object integer NOT NULL,
    id_action integer NOT NULL,
    label character varying,
    scope_filter boolean DEFAULT false,
    sensitivity_filter boolean DEFAULT false
);

ALTER TABLE ONLY gn_permissions.t_permissions_available
    ADD CONSTRAINT t_permissions_available_pkey PRIMARY KEY (id_module, id_object, id_action);

ALTER TABLE ONLY gn_permissions.t_permissions_available
    ADD CONSTRAINT t_permissions_available_id_action_fkey FOREIGN KEY (id_action) REFERENCES gn_permissions.bib_actions(id_action);

ALTER TABLE ONLY gn_permissions.t_permissions_available
    ADD CONSTRAINT t_permissions_available_id_module_fkey FOREIGN KEY (id_module) REFERENCES gn_commons.t_modules(id_module);

ALTER TABLE ONLY gn_permissions.t_permissions_available
    ADD CONSTRAINT t_permissions_available_id_object_fkey FOREIGN KEY (id_object) REFERENCES gn_permissions.t_objects(id_object);

