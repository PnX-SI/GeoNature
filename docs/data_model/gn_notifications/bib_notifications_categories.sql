
CREATE TABLE gn_notifications.bib_notifications_categories (
    code character varying NOT NULL,
    label character varying,
    description text,
    id_module integer,
    id_object integer,
    id_action integer
);

ALTER TABLE ONLY gn_notifications.bib_notifications_categories
    ADD CONSTRAINT bib_notifications_categories_pkey PRIMARY KEY (code);

ALTER TABLE ONLY gn_notifications.bib_notifications_categories
    ADD CONSTRAINT bib_notifications_categories_id_action_fkey FOREIGN KEY (id_action) REFERENCES gn_permissions.bib_actions(id_action);

ALTER TABLE ONLY gn_notifications.bib_notifications_categories
    ADD CONSTRAINT bib_notifications_categories_id_module_fkey FOREIGN KEY (id_module) REFERENCES gn_commons.t_modules(id_module);

ALTER TABLE ONLY gn_notifications.bib_notifications_categories
    ADD CONSTRAINT bib_notifications_categories_id_object_fkey FOREIGN KEY (id_object) REFERENCES gn_permissions.t_objects(id_object);

