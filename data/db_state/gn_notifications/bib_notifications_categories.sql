
CREATE TABLE gn_notifications.bib_notifications_categories (
    code character varying NOT NULL,
    label character varying,
    description text
);

ALTER TABLE ONLY gn_notifications.bib_notifications_categories
    ADD CONSTRAINT bib_notifications_categories_pkey PRIMARY KEY (code);

