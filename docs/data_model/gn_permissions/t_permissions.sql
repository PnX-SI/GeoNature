
CREATE TABLE gn_permissions.t_permissions (
    id_permission integer NOT NULL,
    id_role integer NOT NULL,
    id_action integer NOT NULL,
    id_module integer NOT NULL,
    id_object integer DEFAULT gn_permissions.get_id_object('ALL'::character varying) NOT NULL,
    scope_value integer,
    sensitivity_filter boolean DEFAULT false
);

CREATE SEQUENCE gn_permissions.cor_role_action_filter_module_object_id_permission_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE gn_permissions.cor_role_action_filter_module_object_id_permission_seq OWNED BY gn_permissions.t_permissions.id_permission;

ALTER TABLE ONLY gn_permissions.t_permissions
    ADD CONSTRAINT pk_cor_r_a_f_m_o PRIMARY KEY (id_permission);

ALTER TABLE ONLY gn_permissions.t_permissions
    ADD CONSTRAINT fk_cor_r_a_f_m_o_id_action FOREIGN KEY (id_action) REFERENCES gn_permissions.bib_actions(id_action) ON UPDATE CASCADE;

ALTER TABLE ONLY gn_permissions.t_permissions
    ADD CONSTRAINT fk_cor_r_a_f_m_o_id_module FOREIGN KEY (id_module) REFERENCES gn_commons.t_modules(id_module) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY gn_permissions.t_permissions
    ADD CONSTRAINT fk_cor_r_a_f_m_o_id_object FOREIGN KEY (id_object) REFERENCES gn_permissions.t_objects(id_object) ON UPDATE CASCADE;

ALTER TABLE ONLY gn_permissions.t_permissions
    ADD CONSTRAINT fk_cor_r_a_f_m_o_id_role FOREIGN KEY (id_role) REFERENCES utilisateurs.t_roles(id_role) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY gn_permissions.t_permissions
    ADD CONSTRAINT t_permissions_scope_value_fkey FOREIGN KEY (scope_value) REFERENCES gn_permissions.bib_filters_scope(value);

