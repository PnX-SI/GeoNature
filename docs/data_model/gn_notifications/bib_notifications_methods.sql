

CREATE TABLE gn_notifications.bib_notifications_methods (
    code character varying NOT NULL,
    label character varying,
    description text
);

ALTER TABLE ONLY gn_notifications.bib_notifications_methods
    ADD CONSTRAINT bib_notifications_methods_pkey PRIMARY KEY (code);


