
CREATE TABLE gn_notifications.t_notifications_rules (
    id integer NOT NULL,
    id_role integer,
    code_method character varying NOT NULL,
    code_category character varying NOT NULL,
    subscribed boolean DEFAULT true NOT NULL
);

CREATE SEQUENCE gn_notifications.t_notifications_rules_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE gn_notifications.t_notifications_rules_id_seq OWNED BY gn_notifications.t_notifications_rules.id;

ALTER TABLE ONLY gn_notifications.t_notifications_rules
    ADD CONSTRAINT t_notifications_rules_pkey PRIMARY KEY (id);

ALTER TABLE ONLY gn_notifications.t_notifications_rules
    ADD CONSTRAINT un_role_method_category UNIQUE (id_role, code_method, code_category);

CREATE INDEX un_method_category ON gn_notifications.t_notifications_rules USING btree (code_method, code_category) WHERE (id_role IS NULL);

ALTER TABLE ONLY gn_notifications.t_notifications_rules
    ADD CONSTRAINT t_notifications_rules_code_category_fkey FOREIGN KEY (code_category) REFERENCES gn_notifications.bib_notifications_categories(code);

ALTER TABLE ONLY gn_notifications.t_notifications_rules
    ADD CONSTRAINT t_notifications_rules_code_method_fkey FOREIGN KEY (code_method) REFERENCES gn_notifications.bib_notifications_methods(code);

ALTER TABLE ONLY gn_notifications.t_notifications_rules
    ADD CONSTRAINT t_notifications_rules_id_role_fkey FOREIGN KEY (id_role) REFERENCES utilisateurs.t_roles(id_role);

