
\restrict 6gwSy7VDHLwgk2Rj8qJndIiUXYgNOTNw8OrcGGeiEuHzVg79BH96GWqdPpH9Z0r

CREATE TABLE taxonomie.t_meta_taxref (
    referencial_name character varying NOT NULL,
    version integer NOT NULL,
    update_date timestamp without time zone DEFAULT now()
);

ALTER TABLE ONLY taxonomie.t_meta_taxref
    ADD CONSTRAINT t_meta_taxref_pkey PRIMARY KEY (referencial_name, version);

\unrestrict 6gwSy7VDHLwgk2Rj8qJndIiUXYgNOTNw8OrcGGeiEuHzVg79BH96GWqdPpH9Z0r

