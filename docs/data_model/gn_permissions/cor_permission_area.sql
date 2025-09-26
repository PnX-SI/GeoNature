
\restrict tdoxK0QSD5TEDJiKkPoxusrDFG4e9S3uPjd0VIPjUC4kWkHwxVOVHNgLmbULFmC

CREATE TABLE gn_permissions.cor_permission_area (
    id_permission integer NOT NULL,
    id_area integer NOT NULL
);

ALTER TABLE ONLY gn_permissions.cor_permission_area
    ADD CONSTRAINT cor_permission_area_pkey PRIMARY KEY (id_permission, id_area);

ALTER TABLE ONLY gn_permissions.cor_permission_area
    ADD CONSTRAINT cor_permission_area_id_area_fkey FOREIGN KEY (id_area) REFERENCES ref_geo.l_areas(id_area);

ALTER TABLE ONLY gn_permissions.cor_permission_area
    ADD CONSTRAINT cor_permission_area_id_permission_fkey FOREIGN KEY (id_permission) REFERENCES gn_permissions.t_permissions(id_permission);

\unrestrict tdoxK0QSD5TEDJiKkPoxusrDFG4e9S3uPjd0VIPjUC4kWkHwxVOVHNgLmbULFmC

