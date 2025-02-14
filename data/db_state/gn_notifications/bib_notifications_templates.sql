
CREATE TABLE gn_notifications.bib_notifications_templates (
    code_category character varying NOT NULL,
    code_method character varying NOT NULL,
    content text
);

ALTER TABLE ONLY gn_notifications.bib_notifications_templates
    ADD CONSTRAINT bib_notifications_templates_pkey PRIMARY KEY (code_category, code_method);

ALTER TABLE ONLY gn_notifications.bib_notifications_templates
    ADD CONSTRAINT bib_notifications_templates_code_category_fkey FOREIGN KEY (code_category) REFERENCES gn_notifications.bib_notifications_categories(code);

ALTER TABLE ONLY gn_notifications.bib_notifications_templates
    ADD CONSTRAINT bib_notifications_templates_code_method_fkey FOREIGN KEY (code_method) REFERENCES gn_notifications.bib_notifications_methods(code);

