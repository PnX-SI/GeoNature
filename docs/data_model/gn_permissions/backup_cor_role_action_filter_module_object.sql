
CREATE TABLE gn_permissions.backup_cor_role_action_filter_module_object (
    id_permission integer NOT NULL,
    id_role integer NOT NULL,
    id_action integer NOT NULL,
    id_filter integer NOT NULL,
    id_module integer NOT NULL,
    id_object integer NOT NULL
);

ALTER TABLE ONLY gn_permissions.backup_cor_role_action_filter_module_object
    ADD CONSTRAINT backup_cor_role_action_filter_module_object_pkey PRIMARY KEY (id_permission);

ALTER TABLE ONLY gn_permissions.backup_cor_role_action_filter_module_object
    ADD CONSTRAINT backup_fk_cor_r_a_f_m_o_id_action FOREIGN KEY (id_action) REFERENCES gn_permissions.bib_actions(id_action) ON UPDATE CASCADE;

ALTER TABLE ONLY gn_permissions.backup_cor_role_action_filter_module_object
    ADD CONSTRAINT backup_fk_cor_r_a_f_m_o_id_filter FOREIGN KEY (id_filter) REFERENCES gn_permissions.backup_t_filters(id_filter) ON DELETE CASCADE;

ALTER TABLE ONLY gn_permissions.backup_cor_role_action_filter_module_object
    ADD CONSTRAINT backup_fk_cor_r_a_f_m_o_id_module FOREIGN KEY (id_module) REFERENCES gn_commons.t_modules(id_module) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY gn_permissions.backup_cor_role_action_filter_module_object
    ADD CONSTRAINT backup_fk_cor_r_a_f_m_o_id_object FOREIGN KEY (id_object) REFERENCES gn_permissions.t_objects(id_object) ON UPDATE CASCADE;

ALTER TABLE ONLY gn_permissions.backup_cor_role_action_filter_module_object
    ADD CONSTRAINT backup_fk_cor_r_a_f_m_o_id_role FOREIGN KEY (id_role) REFERENCES utilisateurs.t_roles(id_role) ON UPDATE CASCADE ON DELETE CASCADE;

