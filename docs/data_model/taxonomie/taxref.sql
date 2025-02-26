
CREATE TABLE taxonomie.taxref (
    cd_nom integer NOT NULL,
    id_statut character(1),
    id_habitat integer,
    id_rang character varying(10),
    regne character varying(20),
    phylum character varying(50),
    classe character varying(50),
    ordre character varying(50),
    famille character varying(50),
    sous_famille character varying(50),
    tribu character varying(50),
    cd_taxsup integer,
    cd_sup integer,
    cd_ref integer,
    lb_nom character varying(250),
    lb_auteur character varying(500),
    nom_complet character varying(500),
    nom_complet_html character varying(500),
    nom_valide character varying(500),
    nom_vern character varying(1000),
    nom_vern_eng character varying(500),
    group1_inpn character varying(50),
    group2_inpn character varying(50),
    url text,
    group3_inpn character varying(250)
);

ALTER TABLE ONLY taxonomie.taxref
    ADD CONSTRAINT pk_taxref PRIMARY KEY (cd_nom);

CREATE INDEX i_fk_taxref_bib_taxref_habitat ON taxonomie.taxref USING btree (id_habitat);

CREATE INDEX i_fk_taxref_bib_taxref_rangs ON taxonomie.taxref USING btree (id_rang);

CREATE INDEX i_fk_taxref_bib_taxref_statuts ON taxonomie.taxref USING btree (id_statut);

CREATE INDEX i_fk_taxref_group1_inpn ON taxonomie.taxref USING btree (group1_inpn);

CREATE INDEX i_fk_taxref_group2_inpn ON taxonomie.taxref USING btree (group2_inpn);

CREATE INDEX i_fk_taxref_nom_vern ON taxonomie.taxref USING btree (nom_vern);

CREATE INDEX i_taxref_cd_ref ON taxonomie.taxref USING btree (cd_ref);

CREATE INDEX i_taxref_cd_sup ON taxonomie.taxref USING btree (cd_sup);

CREATE INDEX i_taxref_group3_inpn ON taxonomie.taxref USING btree (group3_inpn);

CREATE INDEX i_taxref_hierarchy ON taxonomie.taxref USING btree (regne, phylum, classe, ordre, famille);

ALTER TABLE ONLY taxonomie.taxref
    ADD CONSTRAINT fk_taxref_bib_taxref_habitats FOREIGN KEY (id_habitat) REFERENCES taxonomie.bib_taxref_habitats(id_habitat) ON UPDATE CASCADE;

ALTER TABLE ONLY taxonomie.taxref
    ADD CONSTRAINT fk_taxref_bib_taxref_rangs FOREIGN KEY (id_rang) REFERENCES taxonomie.bib_taxref_rangs(id_rang) ON UPDATE CASCADE;

ALTER TABLE ONLY taxonomie.taxref
    ADD CONSTRAINT taxref_id_statut_fkey FOREIGN KEY (id_statut) REFERENCES taxonomie.bib_taxref_statuts(id_statut) ON UPDATE CASCADE;

