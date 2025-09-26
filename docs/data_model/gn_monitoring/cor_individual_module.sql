
\restrict cT5NhLehbPMsCPnaJbU4uGIU0W62TwrGIKVjzuFDkZoOpdyfUpsRgkfz338bGwG

CREATE TABLE gn_monitoring.cor_individual_module (
    id_individual integer NOT NULL,
    id_module integer NOT NULL
);

ALTER TABLE ONLY gn_monitoring.cor_individual_module
    ADD CONSTRAINT cor_individual_module_pkey PRIMARY KEY (id_individual, id_module);

ALTER TABLE ONLY gn_monitoring.cor_individual_module
    ADD CONSTRAINT cor_individual_module_id_individual_fkey FOREIGN KEY (id_individual) REFERENCES gn_monitoring.t_individuals(id_individual) ON DELETE CASCADE;

ALTER TABLE ONLY gn_monitoring.cor_individual_module
    ADD CONSTRAINT cor_individual_module_id_module_fkey FOREIGN KEY (id_module) REFERENCES gn_commons.t_modules(id_module) ON DELETE CASCADE;

\unrestrict cT5NhLehbPMsCPnaJbU4uGIU0W62TwrGIKVjzuFDkZoOpdyfUpsRgkfz338bGwG

