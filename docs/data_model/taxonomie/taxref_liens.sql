
CREATE TABLE taxonomie.taxref_liens (
    ct_name character varying(250) NOT NULL,
    ct_type character varying(250) NOT NULL,
    ct_authors text,
    ct_title character varying,
    ct_url character varying(250),
    cd_nom integer NOT NULL,
    ct_sp_id character varying NOT NULL,
    url_sp text
);

ALTER TABLE ONLY taxonomie.taxref_liens
    ADD CONSTRAINT taxref_liens_pkey PRIMARY KEY (ct_name, cd_nom, ct_sp_id);

ALTER TABLE ONLY taxonomie.taxref_liens
    ADD CONSTRAINT taxref_liens_cd_nom_fkey FOREIGN KEY (cd_nom) REFERENCES taxonomie.taxref(cd_nom);

