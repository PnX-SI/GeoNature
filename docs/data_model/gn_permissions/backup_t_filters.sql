
\restrict xmYvyS4E7plLygPdhIXj3FiKLZdcPbKmBovWRZy2eCb8goRNK06VcV9A65kk0Zi

CREATE TABLE gn_permissions.backup_t_filters (
    id_filter integer NOT NULL,
    label_filter character varying(255) NOT NULL,
    value_filter text NOT NULL,
    description_filter text,
    id_filter_type integer NOT NULL
);

ALTER TABLE ONLY gn_permissions.backup_t_filters
    ADD CONSTRAINT backup_t_filters_pkey PRIMARY KEY (id_filter);

ALTER TABLE ONLY gn_permissions.backup_t_filters
    ADD CONSTRAINT backup_fk_t_filters_id_filter_type FOREIGN KEY (id_filter_type) REFERENCES gn_permissions.backup_bib_filters_type(id_filter_type) ON DELETE CASCADE;

\unrestrict xmYvyS4E7plLygPdhIXj3FiKLZdcPbKmBovWRZy2eCb8goRNK06VcV9A65kk0Zi

