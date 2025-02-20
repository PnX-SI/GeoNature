
CREATE TABLE gn_permissions.backup_bib_filters_type (
    id_filter_type integer NOT NULL,
    code_filter_type character varying(50) NOT NULL,
    label_filter_type character varying(255) NOT NULL,
    description_filter_type text
);

ALTER TABLE ONLY gn_permissions.backup_bib_filters_type
    ADD CONSTRAINT backup_bib_filters_type_pkey PRIMARY KEY (id_filter_type);

