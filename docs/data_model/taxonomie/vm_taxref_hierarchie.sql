
CREATE TABLE taxonomie.vm_taxref_hierarchie (
    regne character varying(20),
    phylum character varying(50),
    classe character varying(50),
    ordre character varying(50),
    famille character varying(50),
    cd_nom integer NOT NULL,
    cd_ref integer,
    lb_nom character varying(250),
    id_rang text,
    nb_tx_fm bigint,
    nb_tx_or bigint,
    nb_tx_cl bigint,
    nb_tx_ph bigint,
    nb_tx_kd bigint
);

ALTER TABLE ONLY taxonomie.vm_taxref_hierarchie
    ADD CONSTRAINT vm_taxref_hierarchie_pkey PRIMARY KEY (cd_nom);

