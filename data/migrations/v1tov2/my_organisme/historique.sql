-------------
--FUNCTIONS--
-------------
CREATE OR REPLACE FUNCTION insert_maj_date()
  RETURNS trigger AS
$BODY$
BEGIN
	new.date_insert= 'now';
	new.date_update= 'now';
	RETURN NEW; 			
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

CREATE OR REPLACE FUNCTION update_maj_date()
  RETURNS trigger AS
$BODY$
BEGIN
	new.date_update= 'now';
	RETURN NEW; 			
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;


----------------
--CONTACTFAUNE--
----------------
CREATE SCHEMA hist_contactfaune;
CREATE TABLE hist_contactfaune.bib_criteres_cf AS
SELECT * FROM v1_compat.bib_criteres_cf;
CREATE TABLE hist_contactfaune.bib_messages_cf AS
SELECT * FROM v1_compat.bib_messages_cf;
CREATE TABLE hist_contactfaune.cor_critere_liste AS
SELECT * FROM v1_compat.cor_critere_liste;
CREATE TABLE hist_contactfaune.cor_message_taxon AS
SELECT * FROM v1_compat.cor_message_taxon_contactfaune;
CREATE TABLE hist_contactfaune.cor_role_fiche_cf AS
SELECT * FROM v1_compat.cor_role_fiche_cf;
CREATE TABLE hist_contactfaune.cor_unite_taxon AS
SELECT * FROM v1_compat.cor_unite_taxon;
CREATE TABLE hist_contactfaune.t_fiches_cf AS
SELECT * FROM v1_compat.t_fiches_cf;
CREATE TABLE hist_contactfaune.t_releves_cf AS
SELECT * FROM v1_compat.t_releves_cf;
ALTER TABLE ONLY hist_contactfaune.bib_criteres_cf ADD CONSTRAINT pk_bib_criteres_cf PRIMARY KEY (id_critere_cf);
ALTER TABLE ONLY hist_contactfaune.bib_messages_cf ADD CONSTRAINT pk_bib_messages_cf PRIMARY KEY (id_message_cf);
ALTER TABLE ONLY hist_contactfaune.cor_critere_liste ADD CONSTRAINT pk_cor_critere_liste PRIMARY KEY (id_critere_cf, id_liste);
ALTER TABLE ONLY hist_contactfaune.cor_message_taxon ADD CONSTRAINT pk_cor_message_taxon_cf PRIMARY KEY (id_message_cf, id_nom);
ALTER TABLE ONLY hist_contactfaune.cor_role_fiche_cf ADD CONSTRAINT pk_cor_role_fiche_cf PRIMARY KEY (id_cf, id_role);
ALTER TABLE ONLY hist_contactfaune.cor_unite_taxon ADD CONSTRAINT pk_cor_unite_taxon_cf PRIMARY KEY (id_unite_geo, id_nom);
ALTER TABLE ONLY hist_contactfaune.t_fiches_cf ADD CONSTRAINT pk_t_fiches_cf PRIMARY KEY (id_cf);
ALTER TABLE ONLY hist_contactfaune.t_releves_cf ADD CONSTRAINT pk_t_releves_cf PRIMARY KEY (id_releve_cf);


--------------
--CONTACTINV--
--------------
CREATE SCHEMA hist_contactinv;
CREATE TABLE hist_contactinv.bib_criteres_inv AS
SELECT * FROM v1_compat.bib_criteres_inv;
CREATE TABLE hist_contactinv.bib_messages_inv AS
SELECT * FROM v1_compat.bib_messages_inv;
CREATE TABLE hist_contactinv.bib_milieux_inv AS
SELECT * FROM v1_compat.bib_milieux_inv;
CREATE TABLE hist_contactinv.cor_message_taxon AS
SELECT * FROM v1_compat.cor_message_taxon_contactinv;
CREATE TABLE hist_contactinv.cor_role_fiche_inv AS
SELECT * FROM v1_compat.cor_role_fiche_inv;
CREATE TABLE hist_contactinv.cor_unite_taxon AS
SELECT * FROM v1_compat.cor_unite_taxon;
CREATE TABLE hist_contactinv.t_fiches_inv AS
SELECT * FROM v1_compat.t_fiches_inv;
CREATE TABLE hist_contactinv.t_releves_inv AS
SELECT * FROM v1_compat.t_releves_inv;
ALTER TABLE ONLY hist_contactinv.bib_criteres_inv ADD CONSTRAINT pk_bib_criteres_inv PRIMARY KEY (id_critere_inv);
ALTER TABLE ONLY hist_contactinv.bib_messages_inv ADD CONSTRAINT pk_bib_messages_inv PRIMARY KEY (id_message_inv);
ALTER TABLE ONLY hist_contactinv.bib_milieux_inv ADD CONSTRAINT pk_bib_milieux_inv PRIMARY KEY (id_milieu_inv);
ALTER TABLE ONLY hist_contactinv.cor_message_taxon ADD CONSTRAINT pk_cor_message_taxon_inv PRIMARY KEY (id_message_inv, id_nom);
ALTER TABLE ONLY hist_contactinv.cor_role_fiche_inv ADD CONSTRAINT pk_cor_role_fiche_inv PRIMARY KEY (id_inv, id_role);
ALTER TABLE ONLY hist_contactinv.cor_unite_taxon ADD CONSTRAINT pk_cor_unite_taxon_inv PRIMARY KEY (id_unite_geo, id_nom);
ALTER TABLE ONLY hist_contactinv.t_fiches_inv ADD CONSTRAINT pk_t_fiches_inv PRIMARY KEY (id_inv);
ALTER TABLE ONLY hist_contactinv.t_releves_inv ADD CONSTRAINT pk_t_releves_inv PRIMARY KEY (id_releve_inv);


----------------
--CONTACTFLORE--
----------------
CREATE SCHEMA hist_contactflore;
CREATE TABLE hist_contactflore.bib_abondances_cflore AS
SELECT * FROM v1_compat.bib_abondances_cflore;
CREATE TABLE hist_contactflore.bib_messages_cflore AS
SELECT * FROM v1_compat.bib_messages_cflore;
CREATE TABLE hist_contactflore.bib_phenologies_cflore AS
SELECT * FROM v1_compat.bib_phenologies_cflore;
CREATE TABLE hist_contactflore.cor_message_taxon_cflore AS
SELECT * FROM v1_compat.cor_message_taxon_cflore;
CREATE TABLE hist_contactflore.cor_role_fiche_cflore AS
SELECT * FROM v1_compat.cor_role_fiche_cflore;
CREATE TABLE hist_contactflore.cor_unite_taxon_cflore AS
SELECT * FROM v1_compat.cor_unite_taxon_cflore;
CREATE TABLE hist_contactflore.t_fiches_cflore AS
SELECT * FROM v1_compat.t_fiches_cflore;
CREATE TABLE hist_contactflore.t_releves_cflore AS
SELECT * FROM v1_compat.t_releves_cflore;
ALTER TABLE ONLY hist_contactflore.bib_abondances_cflore ADD CONSTRAINT pk_bib_abondances_cflore PRIMARY KEY (id_abondance_cflore);
ALTER TABLE ONLY hist_contactflore.bib_messages_cflore ADD CONSTRAINT pk_bib_messages_cflore PRIMARY KEY (id_message_cflore);
ALTER TABLE ONLY hist_contactflore.bib_phenologies_cflore ADD CONSTRAINT pk_bib_phenologies_cflore PRIMARY KEY (id_phenologie_cflore);
ALTER TABLE ONLY hist_contactflore.cor_message_taxon_cflore ADD CONSTRAINT pk_cor_message_taxon_cflore PRIMARY KEY (id_message_cflore, id_nom);
ALTER TABLE ONLY hist_contactflore.cor_role_fiche_cflore ADD CONSTRAINT pk_cor_role_fiche_cflore PRIMARY KEY (id_cflore, id_role);
ALTER TABLE ONLY hist_contactflore.cor_unite_taxon_cflore ADD CONSTRAINT pk_cor_unite_taxon_cflore PRIMARY KEY (id_unite_geo, id_nom);
ALTER TABLE ONLY hist_contactflore.t_fiches_cflore ADD CONSTRAINT pk_t_fiches_cflore PRIMARY KEY (id_cflore);
ALTER TABLE ONLY hist_contactflore.t_releves_cflore ADD CONSTRAINT pk_t_releves_cflore PRIMARY KEY (id_releve_cflore);


---------
--BDF05--
---------
IMPORT FOREIGN SCHEMA associations FROM SERVER geonature1server INTO v1_compat;
CREATE SCHEMA partenaires_bdf05;
CREATE TABLE partenaires_bdf05.bdf05_bib_observateurs AS
SELECT * FROM v1_compat.bdf05_bib_observateurs;
CREATE TABLE partenaires_bdf05.bdf05_t_releves AS
SELECT * FROM v1_compat.bdf05_t_releves;
CREATE TABLE partenaires_bdf05.bdf05_t_stations AS
SELECT * FROM v1_compat.bdf05_t_stations;
ALTER TABLE partenaires_bdf05.bdf05_bib_observateurs ADD CONSTRAINT pk_bdf05_bib_observateurs PRIMARY KEY(codeobs);
ALTER TABLE partenaires_bdf05.bdf05_t_releves ADD CONSTRAINT pk_bdf05_t_releves PRIMARY KEY(id_releve);
ALTER TABLE partenaires_bdf05.bdf05_t_stations ADD CONSTRAINT pk_bdf05_t_stations PRIMARY KEY(id_station);
ALTER TABLE partenaires_bdf05.bdf05_t_releves ADD CONSTRAINT fk_bdf05_t_releves_cd_nom FOREIGN KEY (cd_nom)
    REFERENCES taxonomie.taxref (cd_nom) MATCH SIMPLE ON UPDATE CASCADE ON DELETE NO ACTION;
ALTER TABLE partenaires_bdf05.bdf05_t_releves ADD CONSTRAINT fk_bdf05_t_releves_id_station FOREIGN KEY (id_station)
    REFERENCES partenaires_bdf05.bdf05_t_stations (id_station) MATCH SIMPLE ON UPDATE CASCADE ON DELETE NO ACTION;
ALTER TABLE partenaires_bdf05.bdf05_t_stations ADD CONSTRAINT fk_bdf05_t_stations_codeobs1 FOREIGN KEY (codeobs1)
    REFERENCES partenaires_bdf05.bdf05_bib_observateurs (codeobs) MATCH SIMPLE ON UPDATE CASCADE ON DELETE NO ACTION;
ALTER TABLE partenaires_bdf05.bdf05_t_stations ADD CONSTRAINT fk_bdf05_t_stations_codeobs2 FOREIGN KEY (codeobs2)
    REFERENCES partenaires_bdf05.bdf05_bib_observateurs (codeobs) MATCH SIMPLE ON UPDATE CASCADE ON DELETE NO ACTION;
ALTER TABLE partenaires_bdf05.bdf05_t_stations ADD CONSTRAINT fk_bdf05_t_stations_codeobs3 FOREIGN KEY (codeobs3)
    REFERENCES partenaires_bdf05.bdf05_bib_observateurs (codeobs) MATCH SIMPLE ON UPDATE CASCADE ON DELETE NO ACTION;


-----------------
--BIBLIOGRAPHIE--
-----------------
IMPORT FOREIGN SCHEMA bibliographie FROM SERVER geonature1server INTO v1_compat;
CREATE SCHEMA hist_bibliographie;
CREATE TABLE hist_bibliographie.bibliographie AS
SELECT * FROM v1_compat.bibliographie;
ALTER TABLE hist_bibliographie.bibliographie ADD CONSTRAINT pk_biblio PRIMARY KEY(id_biblio);
ALTER TABLE hist_bibliographie.bibliographie ADD CONSTRAINT biblio_id_datasets_fkey FOREIGN KEY (id_lot)
    REFERENCES gn_meta.t_datasets (id_dataset) MATCH SIMPLE ON UPDATE CASCADE ON DELETE NO ACTION;
ALTER TABLE hist_bibliographie.bibliographie ADD CONSTRAINT biblio_id_source_fkey FOREIGN KEY (id_source)
    REFERENCES gn_synthese.t_sources (id_source) MATCH SIMPLE ON UPDATE CASCADE ON DELETE NO ACTION;
ALTER TABLE hist_bibliographie.bibliographie ADD CONSTRAINT fk_biblio_bib_organismes FOREIGN KEY (id_organisme)
    REFERENCES utilisateurs.bib_organismes (id_organisme) MATCH SIMPLE ON UPDATE CASCADE ON DELETE NO ACTION;


--------
--CBNA--
--------
CREATE SCHEMA partenaires_cbna;
--On importe rien; C'est à refaire. Les anciennes données sont au format GN1


---------------
--CHIROPTERES--
---------------
IMPORT FOREIGN SCHEMA chiropteres EXCEPT(t_visites) FROM SERVER geonature1server INTO v1_compat;
--Renommer les tables
ALTER FOREIGN TABLE v1_compat.t_sites RENAME TO t_sites_chiro;
ALTER FOREIGN TABLE v1_compat.bib_taxons RENAME TO bib_taxons_chiro;
ALTER FOREIGN TABLE v1_compat.bib_observateurs RENAME TO bib_observateurs_chiro;
ALTER FOREIGN TABLE v1_compat.meta RENAME TO meta_chiro;
CREATE FOREIGN TABLE v1_compat.t_visites_chiro
(
  numfiche character varying(7) NOT NULL,
  id_site integer,
  dateobs date NOT NULL,
  id_observateur integer,
  menaces character varying(15),
  description_menace text,
  preconisations text
)
SERVER geonature1server
OPTIONS (schema_name 'chiropteres', table_name 't_visites');
CREATE SCHEMA hist_chiropteres;
CREATE TABLE hist_chiropteres.bib_indices AS
SELECT * FROM v1_compat.bib_indices;
CREATE TABLE hist_chiropteres.bib_observateurs AS
SELECT * FROM v1_compat.bib_observateurs_chiro;
CREATE TABLE hist_chiropteres.bib_proprietaires AS
SELECT * FROM v1_compat.bib_proprietaires;
CREATE TABLE hist_chiropteres.bib_taxons AS
SELECT * FROM v1_compat.bib_taxons_chiro;
CREATE TABLE hist_chiropteres.bib_types_site AS
SELECT * FROM v1_compat.bib_types_site;
CREATE TABLE hist_chiropteres.cor_incides_gites AS
SELECT * FROM v1_compat.cor_incides_gites;
CREATE TABLE hist_chiropteres.meta AS
SELECT * FROM v1_compat.meta_chiro;
CREATE TABLE hist_chiropteres.t_gites AS
SELECT * FROM v1_compat.t_gites;
CREATE TABLE hist_chiropteres.t_lieux AS
SELECT * FROM v1_compat.t_lieux;
CREATE TABLE hist_chiropteres.t_mesures AS
SELECT * FROM v1_compat.t_mesures;
CREATE TABLE hist_chiropteres.t_sites AS
SELECT * FROM v1_compat.t_sites_chiro;
CREATE TABLE hist_chiropteres.t_visites AS
SELECT * FROM v1_compat.t_visites_chiro;
ALTER TABLE hist_chiropteres.bib_indices ADD CONSTRAINT pk_bib_indices PRIMARY KEY(id_indice);
ALTER TABLE hist_chiropteres.bib_observateurs ADD CONSTRAINT pk_bib_observateurs PRIMARY KEY(id_observateur);
ALTER TABLE hist_chiropteres.bib_proprietaires ADD CONSTRAINT pk_bib_proprietaires PRIMARY KEY(id_proprio);
ALTER TABLE hist_chiropteres.bib_taxons ADD CONSTRAINT pk_bib_taxons PRIMARY KEY(id_taxon);
ALTER TABLE hist_chiropteres.bib_types_site ADD CONSTRAINT pk_bib_types_site PRIMARY KEY(id_typesite);
ALTER TABLE hist_chiropteres.cor_incides_gites ADD CONSTRAINT pk_cor_incides_gites PRIMARY KEY(id_gite, id_indice);
ALTER TABLE hist_chiropteres.meta ADD CONSTRAINT pk_meta PRIMARY KEY(id);
ALTER TABLE hist_chiropteres.t_gites ADD CONSTRAINT pk_t_gites PRIMARY KEY(id_gite);
ALTER TABLE hist_chiropteres.t_lieux ADD CONSTRAINT pk_t_lieux PRIMARY KEY(id_lieu);
ALTER TABLE hist_chiropteres.t_mesures ADD CONSTRAINT pk_bib_mesures PRIMARY KEY(id_mesure);
ALTER TABLE hist_chiropteres.t_sites ADD CONSTRAINT pk_t_sites PRIMARY KEY(id_site);
ALTER TABLE hist_chiropteres.t_visites ADD CONSTRAINT pk_t_visites PRIMARY KEY(numfiche);

ALTER TABLE hist_chiropteres.cor_incides_gites ADD CONSTRAINT fk_cor_incides_gites_gites FOREIGN KEY (id_gite)
    REFERENCES hist_chiropteres.t_gites (id_gite) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION;
ALTER TABLE hist_chiropteres.cor_incides_gites ADD CONSTRAINT fk_cor_incides_gites_indices FOREIGN KEY (id_indice)
    REFERENCES hist_chiropteres.bib_indices (id_indice) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION;
ALTER TABLE hist_chiropteres.t_gites ADD CONSTRAINT fk_t_gites_bib_taxons FOREIGN KEY (id_taxon)
    REFERENCES taxonomie.bib_noms (id_nom) MATCH SIMPLE ON UPDATE CASCADE ON DELETE NO ACTION;
ALTER TABLE hist_chiropteres.t_gites ADD CONSTRAINT fk_t_gites_t_visites FOREIGN KEY (numfiche)
    REFERENCES hist_chiropteres.t_visites (numfiche) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION;
ALTER TABLE hist_chiropteres.t_lieux ADD CONSTRAINT fk_t_lieux_bib_proprietaires FOREIGN KEY (id_proprio)
    REFERENCES hist_chiropteres.bib_proprietaires (id_proprio) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION;
ALTER TABLE hist_chiropteres.t_lieux ADD CONSTRAINT enforce_dims_the_geom_27572 CHECK (public.st_ndims(the_geom_27572) = 2);
ALTER TABLE hist_chiropteres.t_lieux ADD CONSTRAINT enforce_geotype_the_geom_27572 CHECK (public.st_geometrytype(the_geom_27572) = 'ST_Point'::text OR the_geom_27572 IS NULL);
ALTER TABLE hist_chiropteres.t_lieux ADD CONSTRAINT enforce_srid_the_geom_27572 CHECK (public.st_srid(the_geom_27572) = 27572);
ALTER TABLE hist_chiropteres.t_mesures ADD CONSTRAINT fk_bib_mesures_t_lieux FOREIGN KEY (id_lieu)
    REFERENCES hist_chiropteres.t_lieux (id_lieu) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION;
ALTER TABLE hist_chiropteres.t_sites ADD CONSTRAINT fk_t_sites_bib_types_site FOREIGN KEY (id_typesite)
    REFERENCES hist_chiropteres.bib_types_site (id_typesite) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION;
ALTER TABLE hist_chiropteres.t_sites ADD CONSTRAINT fk_t_sites_t_lieux FOREIGN KEY (id_lieu)
    REFERENCES hist_chiropteres.t_lieux (id_lieu) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION;
ALTER TABLE hist_chiropteres.t_visites ADD CONSTRAINT fk_t_visites_bib_observateurs FOREIGN KEY (id_observateur)
      REFERENCES hist_chiropteres.bib_observateurs (id_observateur) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION;
ALTER TABLE hist_chiropteres.t_visites ADD CONSTRAINT fk_t_visites_t_sites FOREIGN KEY (id_site)
      REFERENCES hist_chiropteres.t_sites (id_site) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION;


-----------
--CIGALES--
-----------
IMPORT FOREIGN SCHEMA cigales EXCEPT(t_transects) FROM SERVER geonature1server INTO v1_compat;
CREATE FOREIGN TABLE v1_compat.t_transects_cigales
(
  nom_transect character varying(200) NOT NULL,
  altitude_transect integer,
  the_geom_27572 geometry,
  id_transect serial NOT NULL,
  id_utilisateur_verrou integer,
  supprime boolean DEFAULT false,
  date_verrou timestamp without time zone,
  verrou boolean DEFAULT false,
  date_update timestamp without time zone,
  date_insert timestamp without time zone,
  the_geom_2154 geometry,
  srid_dessin integer,
  the_geom_3857 geometry
)
SERVER geonature1server
OPTIONS (schema_name 'cigales', table_name 't_transects');
CREATE SCHEMA hist_cigales;
CREATE TABLE hist_cigales.bib_couvertures_nuageuses AS
SELECT * FROM v1_compat.bib_couvertures_nuageuses;
CREATE TABLE hist_cigales.bib_ensoleillements AS
SELECT * FROM v1_compat.bib_ensoleillements;
CREATE TABLE hist_cigales.bib_temperatures AS
SELECT * FROM v1_compat.bib_temperatures;
CREATE TABLE hist_cigales.cor_releve_taxon AS
SELECT * FROM v1_compat.cor_releve_taxon;
CREATE TABLE hist_cigales.cor_troncon_taxon AS
SELECT * FROM v1_compat.cor_troncon_taxon;
CREATE TABLE hist_cigales.t_releves_cigales AS
SELECT * FROM v1_compat.t_releves_cigales;
CREATE TABLE hist_cigales.t_transects AS
SELECT * FROM v1_compat.t_transects_cigales;
CREATE TABLE hist_cigales.t_troncons_cigales AS
SELECT * FROM v1_compat.t_troncons_cigales;
ALTER TABLE hist_cigales.bib_couvertures_nuageuses ADD CONSTRAINT pk_bib_couvertures_nuageuses PRIMARY KEY(id_couverture_nuageuse);
ALTER TABLE hist_cigales.bib_ensoleillements ADD CONSTRAINT pk_bib_ensoleillement PRIMARY KEY(id_ensoleillement);
ALTER TABLE hist_cigales.bib_temperatures ADD CONSTRAINT pk_bib_temperatures PRIMARY KEY(id_temperature);
ALTER TABLE hist_cigales.cor_releve_taxon ADD CONSTRAINT pk_cor_releve_taxon PRIMARY KEY(id_taxon, id_releve);
ALTER TABLE hist_cigales.cor_troncon_taxon ADD CONSTRAINT pk_cor_troncon_taxon PRIMARY KEY(id_taxon, id_troncon);
ALTER TABLE hist_cigales.t_releves_cigales ADD CONSTRAINT pk_t_releves_cigales PRIMARY KEY(id_releve);
ALTER TABLE hist_cigales.t_transects ADD CONSTRAINT pk_t_transects PRIMARY KEY(id_transect);
ALTER TABLE hist_cigales.t_troncons_cigales ADD CONSTRAINT pk_t_troncons_cigales PRIMARY KEY(id_troncon);
ALTER TABLE hist_cigales.cor_releve_taxon ADD CONSTRAINT cor_releve_taxon_id_releve_fkey FOREIGN KEY (id_releve)
    REFERENCES hist_cigales.t_releves_cigales (id_releve) MATCH SIMPLE ON UPDATE CASCADE ON DELETE NO ACTION;
ALTER TABLE hist_cigales.cor_releve_taxon ADD CONSTRAINT cor_releve_taxon_id_taxon_fkey FOREIGN KEY (id_taxon)
    REFERENCES taxonomie.bib_noms (id_nom) MATCH SIMPLE ON UPDATE CASCADE ON DELETE NO ACTION;
ALTER TABLE hist_cigales.cor_troncon_taxon ADD CONSTRAINT cor_troncon_taxon_id_taxon_fkey FOREIGN KEY (id_taxon)
    REFERENCES taxonomie.bib_noms (id_nom) MATCH SIMPLE ON UPDATE CASCADE ON DELETE NO ACTION;
ALTER TABLE hist_cigales.cor_troncon_taxon ADD CONSTRAINT cor_troncon_taxon_id_troncon_fkey FOREIGN KEY (id_troncon)
    REFERENCES hist_cigales.t_troncons_cigales (id_troncon) MATCH SIMPLE ON UPDATE CASCADE ON DELETE NO ACTION;
ALTER TABLE hist_cigales.t_releves_cigales ADD CONSTRAINT t_releves_cigales_id_couverture_nuageuse_fkey FOREIGN KEY (id_couverture_nuageuse)
    REFERENCES hist_cigales.bib_couvertures_nuageuses (id_couverture_nuageuse) MATCH SIMPLE ON UPDATE CASCADE ON DELETE NO ACTION;  
ALTER TABLE hist_cigales.t_releves_cigales ADD CONSTRAINT t_releves_cigales_id_role_fkey FOREIGN KEY (id_role)
      REFERENCES utilisateurs.t_roles (id_role) MATCH SIMPLE ON UPDATE CASCADE ON DELETE NO ACTION;
ALTER TABLE hist_cigales.t_releves_cigales ADD CONSTRAINT t_releves_cigales_id_temperature_fkey FOREIGN KEY (id_temperature)
      REFERENCES hist_cigales.bib_temperatures (id_temperature) MATCH SIMPLE ON UPDATE CASCADE ON DELETE NO ACTION;
ALTER TABLE hist_cigales.t_releves_cigales ADD CONSTRAINT t_releves_cigales_id_transect_fkey FOREIGN KEY (id_transect)
      REFERENCES hist_cigales.t_transects (id_transect) MATCH SIMPLE ON UPDATE CASCADE ON DELETE NO ACTION;
ALTER TABLE hist_cigales.t_transects ADD CONSTRAINT enforce_dims_the_geom_2154 CHECK (public.st_ndims(the_geom_2154) = 2);
ALTER TABLE hist_cigales.t_transects ADD CONSTRAINT enforce_dims_the_geom_27572 CHECK (public.ST_ndims(the_geom_27572) = 2);
ALTER TABLE hist_cigales.t_transects ADD CONSTRAINT enforce_dims_the_geom_3857 CHECK (public.ST_ndims(the_geom_3857) = 2);
ALTER TABLE hist_cigales.t_transects ADD CONSTRAINT enforce_geotype_the_geom_2154 CHECK (public.ST_geometrytype(the_geom_2154) = 'ST_MultiLineString'::text OR the_geom_2154 IS NULL);
ALTER TABLE hist_cigales.t_transects ADD CONSTRAINT enforce_geotype_the_geom_27572 CHECK (public.ST_geometrytype(the_geom_27572) = 'ST_MultiLineString'::text OR the_geom_27572 IS NULL);
ALTER TABLE hist_cigales.t_transects ADD CONSTRAINT enforce_geotype_the_geom_3857 CHECK (public.ST_geometrytype(the_geom_3857) = 'ST_MultiLineString'::text OR the_geom_3857 IS NULL);
ALTER TABLE hist_cigales.t_transects ADD CONSTRAINT enforce_srid_the_geom_2154 CHECK (public.ST_srid(the_geom_2154) = 2154);
ALTER TABLE hist_cigales.t_transects ADD CONSTRAINT enforce_srid_the_geom_27572 CHECK (public.ST_srid(the_geom_27572) = 27572);
ALTER TABLE hist_cigales.t_transects ADD CONSTRAINT enforce_srid_the_geom_3857 CHECK (public.ST_srid(the_geom_3857) = 3857);
ALTER TABLE hist_cigales.t_troncons_cigales ADD CONSTRAINT t_troncons_cigales_id_ensoleillement_fkey FOREIGN KEY (id_ensoleillement)
    REFERENCES hist_cigales.bib_ensoleillements (id_ensoleillement) MATCH SIMPLE ON UPDATE CASCADE ON DELETE NO ACTION;

CREATE OR REPLACE FUNCTION hist_cigales.update_transect()
  RETURNS trigger AS
$BODY$
BEGIN
------------------------- gestion des infos relatives aux géométries
-------------------------- attention la saisie sur le web réalise un insert sur qq données mais the_geom_3857 est "faussement inséré" par un update !!!
	IF 
	    (NOT ST_Equals(new.the_geom_27572,old.the_geom_27572) OR (old.the_geom_27572 IS null AND new.the_geom_27572 IS not null))
	    OR (NOT ST_Equals(new.the_geom_2154,old.the_geom_2154) OR (old.the_geom_2154 IS null AND new.the_geom_2154 IS not null))
	    OR (NOT ST_Equals(new.the_geom_3857,old.the_geom_3857)OR (old.the_geom_3857 IS null AND new.the_geom_3857 IS not null)) 
	THEN
	    IF NOT ST_Equals(new.the_geom_3857,old.the_geom_3857) OR (old.the_geom_3857 IS null AND new.the_geom_3857 IS not null) THEN
			new.the_geom_27572 = st_transform(new.the_geom_3857,27572);
			new.the_geom_2154 = st_transform(new.the_geom_3857,2154);
		ELSIF NOT ST_Equals(new.the_geom_2154,old.the_geom_2154) OR (old.the_geom_2154 IS null AND new.the_geom_2154 IS not null) THEN
			new.the_geom_27572 = st_transform(new.the_geom_2154,27572);
			new.the_geom_3857 = st_transform(new.the_geom_2154,3857);
		ELSIF NOT ST_Equals(new.the_geom_27572,old.the_geom_27572) OR (old.the_geom_27572 IS null AND new.the_geom_27572 IS not null) THEN
			new.the_geom_3857 = st_transform(new.the_geom_27572,3857);
			new.the_geom_2154 = st_transform(new.the_geom_27572,2154);
		END IF;
	END IF;

	new.date_update= 'now';	 -- mise a jour de date insert

	RETURN new;	
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

CREATE OR REPLACE FUNCTION hist_cigales.insert_transect()
  RETURNS trigger AS
$BODY$
BEGIN
   new.date_insert= 'now';	 -- mise a jour de date insert
   return new;	
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

CREATE OR REPLACE FUNCTION hist_cigales.insert_releve()
  RETURNS trigger AS
$BODY$
BEGIN
   new.date_insert= 'now';	 -- mise a jour de date insert
   return new;	
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

CREATE OR REPLACE FUNCTION hist_cigales.update_releve()
  RETURNS trigger AS
$BODY$
BEGIN
   new.date_update= 'now';	 -- mise a jour de date insert
   return new;	
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

CREATE TRIGGER trigger_insert_transect
  BEFORE INSERT
  ON hist_cigales.t_transects
  FOR EACH ROW
  EXECUTE PROCEDURE hist_cigales.insert_transect();
CREATE TRIGGER trigger_update_transect
  BEFORE UPDATE
  ON hist_cigales.t_transects
  FOR EACH ROW
  EXECUTE PROCEDURE hist_cigales.update_transect();
CREATE TRIGGER trigger_insert_releve
  BEFORE INSERT
  ON hist_cigales.t_releves_cigales
  FOR EACH ROW
  EXECUTE PROCEDURE hist_cigales.insert_releve();
CREATE TRIGGER trigger_update_releve
  BEFORE UPDATE
  ON hist_cigales.t_releves_cigales
  FOR EACH ROW
  EXECUTE PROCEDURE hist_cigales.update_releve();

CREATE SEQUENCE hist_cigales.t_releves_cigales_id_releve_seq
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 54
  CACHE 1;
CREATE SEQUENCE hist_cigales.t_transects_id_transect_seq
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 32
  CACHE 1;
CREATE SEQUENCE hist_cigales.t_troncons_cigales_id_troncon_seq
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 250
  CACHE 1;


---------------------
--GRANDS PREDATEURS--
---------------------
IMPORT FOREIGN SCHEMA grandspredateurs EXCEPT(t_releves_gp_2014) FROM SERVER geonature1server INTO v1_compat;
CREATE SCHEMA pr_grandspredateurs;
CREATE TABLE pr_grandspredateurs.t_releves_gp AS
SELECT * FROM v1_compat.t_releves_gp;
ALTER TABLE pr_grandspredateurs.t_releves_gp ADD CONSTRAINT pk_t_releves_gp PRIMARY KEY(id_releve_gp);
ALTER TABLE pr_grandspredateurs.t_releves_gp ADD CONSTRAINT enforce_dims_the_geom_2154 CHECK (public.st_ndims(the_geom_2154) = 2);
ALTER TABLE pr_grandspredateurs.t_releves_gp ADD CONSTRAINT enforce_geotype_the_geom_2154 CHECK (public.st_geometrytype(the_geom_2154) = 'ST_Point'::text OR the_geom_2154 IS NULL);
ALTER TABLE pr_grandspredateurs.t_releves_gp ADD CONSTRAINT enforce_srid_the_geom_2154 CHECK (public.st_srid(the_geom_2154) = 2154);
CREATE SEQUENCE pr_grandspredateurs.t_releves_gp_id_releve_gp_seq
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 140
  CACHE 1;
CREATE SEQUENCE pr_grandspredateurs.t_releves_gp_id_releve_gp_seq1
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 1
  CACHE 1;


------------
--HABITATS--
------------
IMPORT FOREIGN SCHEMA habitats FROM SERVER geonature1server INTO v1_compat;
INSERT INTO ref_geo.bib_areas_types (type_name, type_code, type_desc) VALUES
('Polygones SOPHIE', 'SOPHIE', 'Les 124 polygones du protocole SOPHIE de suivi des habitats ');
INSERT INTO ref_geo.l_areas(id_type, area_name, area_code, geom, centroid, source, enable)
SELECT ref_geo.get_id_area_type('SOPHIE'), concat('SOPHIE-',ssp::varchar), ssp::varchar, ST_Multi(st_transform(the_geom, 2154)), public.ST_Pointonsurface(st_transform(the_geom, 2154)), 'gn1', false 
FROM v1_compat.sophie;


-----------------------
--HISTORIQUE ARCHIVES--
-----------------------
IMPORT FOREIGN SCHEMA historique LIMIT TO(archives, bib_critere_arch, bib_protocoles, bib_observateurs, cor_protocoles) FROM SERVER geonature1server INTO v1_compat;
CREATE SCHEMA hist_archives;
CREATE TABLE hist_archives.archives AS
SELECT * FROM v1_compat.archives;
CREATE TABLE hist_archives.bib_critere_arch AS
SELECT * FROM v1_compat.bib_critere_arch;
CREATE TABLE hist_archives.bib_observateurs AS
SELECT * FROM v1_compat.bib_observateurs;
CREATE TABLE hist_archives.bib_protocoles AS
SELECT * FROM v1_compat.bib_protocoles;
CREATE TABLE hist_archives.cor_protocoles AS
SELECT * FROM v1_compat.cor_protocoles;
CREATE TABLE hist_archives.bib_criteres_synthese_gn1 AS
SELECT * FROM v1_compat.bib_criteres_synthese;
ALTER TABLE hist_archives.bib_critere_arch ADD CONSTRAINT pk_bib_crites_archives PRIMARY KEY(codecritarch);
ALTER TABLE hist_archives.bib_observateurs ADD CONSTRAINT pk_bib_observateurs PRIMARY KEY(codeobs);
ALTER TABLE hist_archives.bib_protocoles ADD CONSTRAINT pk_bib_protocoles PRIMARY KEY(codeprotocole);
ALTER TABLE hist_archives.archives ADD CONSTRAINT pk_archives PRIMARY KEY(num_auto);
ALTER TABLE hist_archives.cor_protocoles ADD CONSTRAINT pk_cor_protocoles PRIMARY KEY(codeprotocole, id_protocole);
ALTER TABLE hist_archives.bib_criteres_synthese_gn1 ADD CONSTRAINT pk_bib_criteres_synthese_gn1 PRIMARY KEY(id_critere_synthese);
ALTER TABLE hist_archives.archives ADD CONSTRAINT fk_archives_bib_critere_arch FOREIGN KEY (codecritarch)
    REFERENCES hist_archives.bib_critere_arch (codecritarch) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION;
ALTER TABLE hist_archives.archives ADD CONSTRAINT fk_archives_bib_lots FOREIGN KEY (id_lot)
    REFERENCES gn_meta.t_datasets (id_dataset) MATCH SIMPLE ON UPDATE CASCADE ON DELETE NO ACTION;
ALTER TABLE hist_archives.archives ADD CONSTRAINT fk_archives_bib_observateurs FOREIGN KEY (codeobs)
    REFERENCES hist_archives.bib_observateurs (codeobs) MATCH SIMPLE ON UPDATE CASCADE ON DELETE NO ACTION;
ALTER TABLE hist_archives.archives ADD CONSTRAINT fk_archives_bib_protocoles FOREIGN KEY (codeprotocole)
    REFERENCES hist_archives.bib_protocoles (codeprotocole) MATCH SIMPLE ON UPDATE CASCADE ON DELETE NO ACTION;
ALTER TABLE hist_archives.archives ADD CONSTRAINT fk_archives_bib_taxons FOREIGN KEY (codeespece)
    REFERENCES taxonomie.bib_noms (id_nom) MATCH SIMPLE ON UPDATE CASCADE ON DELETE NO ACTION;
ALTER TABLE hist_archives.cor_protocoles ADD CONSTRAINT fk_cor_protocoles_code FOREIGN KEY (codeprotocole)
    REFERENCES hist_archives.bib_protocoles (codeprotocole) MATCH SIMPLE ON UPDATE CASCADE ON DELETE NO ACTION;
ALTER TABLE hist_archives.cor_protocoles ADD CONSTRAINT fk_cor_protocoles_id FOREIGN KEY (id_protocole)
    REFERENCES gn_meta.sinp_datatype_protocols (id_protocol) MATCH SIMPLE ON UPDATE CASCADE ON DELETE NO ACTION;
ALTER TABLE hist_archives.archives ADD CONSTRAINT enforce_dims_the_geom_27572 CHECK (public.st_ndims(the_geom_27572) = 2);
ALTER TABLE hist_archives.archives ADD CONSTRAINT enforce_geotype_the_geom_27572 CHECK (public.st_geometrytype(the_geom_27572) = 'ST_Polygon'::text OR the_geom_27572 IS NULL);
ALTER TABLE hist_archives.archives ADD CONSTRAINT enforce_srid_the_geom_27572 CHECK (public.st_srid(the_geom_27572) = 27572);


-------------------------
--HISTORIQUE BOUQUETINS--
-------------------------
IMPORT FOREIGN SCHEMA historique LIMIT TO(bib_bou_m, bib_bou_ni, bou_m, bou_ni, boufiche) FROM SERVER geonature1server INTO v1_compat;
CREATE SCHEMA hist_bouquetins;
CREATE TABLE hist_bouquetins.bib_bou_m AS
SELECT * FROM v1_compat.bib_bou_m;
CREATE TABLE hist_bouquetins.bib_bou_ni AS
SELECT * FROM v1_compat.bib_bou_ni;
CREATE TABLE hist_bouquetins.bou_m AS
SELECT * FROM v1_compat.bou_m;
CREATE TABLE hist_bouquetins.bou_ni AS
SELECT * FROM v1_compat.bou_ni;
CREATE TABLE hist_bouquetins.boufiche AS
SELECT * FROM v1_compat.boufiche;
ALTER TABLE hist_bouquetins.bib_bou_m ADD CONSTRAINT pk_bib_bou_m PRIMARY KEY(codebm);
ALTER TABLE hist_bouquetins.bib_bou_ni ADD CONSTRAINT pk_bib_bou_ni PRIMARY KEY(codebni);
ALTER TABLE hist_bouquetins.bou_m ADD CONSTRAINT pk_bou_m PRIMARY KEY(nfiche, codebm);
ALTER TABLE hist_bouquetins.bou_ni ADD CONSTRAINT pk_bou_ni PRIMARY KEY(nfiche, codebni);
ALTER TABLE hist_bouquetins.boufiche ADD CONSTRAINT pk_boufiche PRIMARY KEY(nfiche);
ALTER TABLE hist_bouquetins.bou_m ADD CONSTRAINT fk_bou_m_bib_bou_m FOREIGN KEY (codebm)
    REFERENCES hist_bouquetins.bib_bou_m (codebm) MATCH SIMPLE ON UPDATE CASCADE ON DELETE NO ACTION;
ALTER TABLE hist_bouquetins.bou_m ADD CONSTRAINT fk_bou_m_boufiche FOREIGN KEY (nfiche)
    REFERENCES hist_bouquetins.boufiche (nfiche) MATCH SIMPLE ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE hist_bouquetins.bou_ni ADD CONSTRAINT fk_bou_ni_bib_bou_ni FOREIGN KEY (codebni)
    REFERENCES hist_bouquetins.bib_bou_ni (codebni) MATCH SIMPLE ON UPDATE CASCADE ON DELETE NO ACTION;
ALTER TABLE hist_bouquetins.bou_ni ADD CONSTRAINT fk_bou_ni_boufiche FOREIGN KEY (nfiche)
    REFERENCES hist_bouquetins.boufiche (nfiche) MATCH SIMPLE ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE hist_bouquetins.boufiche ADD CONSTRAINT fk_boufiche_bib_lots FOREIGN KEY (id_lot)
    REFERENCES gn_meta.t_datasets (id_dataset) MATCH SIMPLE ON UPDATE CASCADE ON DELETE NO ACTION;
ALTER TABLE hist_bouquetins.boufiche ADD CONSTRAINT fk_boufiche_bib_observateurs FOREIGN KEY (codeobs)
    REFERENCES hist_archives.bib_observateurs (codeobs) MATCH SIMPLE ON UPDATE CASCADE ON DELETE NO ACTION;
ALTER TABLE hist_bouquetins.boufiche ADD CONSTRAINT enforce_dims_the_geom_27572 CHECK (public.st_ndims(the_geom_27572) = 2);
ALTER TABLE hist_bouquetins.boufiche ADD CONSTRAINT enforce_srid_the_geom_27572 CHECK (public.st_srid(the_geom_27572) = 27572);


------------------
--HISTORIQUE SOC--
------------------
IMPORT FOREIGN SCHEMA historique LIMIT TO(socfiche, soctaxons, bib_stationsoc) FROM SERVER geonature1server INTO v1_compat;
CREATE SCHEMA hist_soc;
CREATE TABLE hist_soc.socfiche AS
SELECT * FROM v1_compat.socfiche;
CREATE TABLE hist_soc.soctaxons AS
SELECT * FROM v1_compat.soctaxons;
CREATE TABLE hist_soc.bib_stationsoc AS
SELECT * FROM v1_compat.bib_stationsoc;
ALTER TABLE hist_soc.bib_stationsoc ADD CONSTRAINT pk_bib_stations_soc PRIMARY KEY(codestation);
ALTER TABLE hist_soc.socfiche ADD CONSTRAINT pk_socfiche PRIMARY KEY(nfiche);
ALTER TABLE hist_soc.soctaxons ADD CONSTRAINT soctaxons_pkey PRIMARY KEY(num_auto);
ALTER TABLE hist_soc.bib_stationsoc ADD CONSTRAINT enforce_dims_the_geom_27572 CHECK (public.st_ndims(the_geom_27572) = 2);
ALTER TABLE hist_soc.bib_stationsoc ADD CONSTRAINT enforce_geotype_the_geom_27572 CHECK (public.st_geometrytype(the_geom_27572) = 'ST_Point'::text OR the_geom_27572 IS NULL);
ALTER TABLE hist_soc.bib_stationsoc ADD CONSTRAINT enforce_srid_the_geom_27572 CHECK (public.st_srid(the_geom_27572) = 27572);
ALTER TABLE hist_soc.socfiche ADD CONSTRAINT fk_socfiche_bib_lots FOREIGN KEY (id_lot)
    REFERENCES gn_meta.t_datasets (id_dataset) MATCH SIMPLE ON UPDATE CASCADE ON DELETE NO ACTION;
ALTER TABLE hist_soc.socfiche ADD CONSTRAINT fk_socfiche_bib_observateurs FOREIGN KEY (codeobs)
    REFERENCES hist_archives.bib_observateurs (codeobs) MATCH SIMPLE ON UPDATE CASCADE ON DELETE NO ACTION;
ALTER TABLE hist_soc.socfiche ADD CONSTRAINT fk_socfiche_bib_stationsoc FOREIGN KEY (codestation)
    REFERENCES hist_soc.bib_stationsoc (codestation) MATCH SIMPLE ON UPDATE CASCADE ON DELETE NO ACTION;
ALTER TABLE hist_soc.soctaxons ADD CONSTRAINT fk_soctaxons_bib_especes FOREIGN KEY (codeespece)
    REFERENCES taxonomie.bib_noms (id_nom) MATCH SIMPLE ON UPDATE CASCADE ON DELETE NO ACTION;
ALTER TABLE hist_soc.soctaxons ADD CONSTRAINT fk_soctaxons_socfiche FOREIGN KEY (nfiche)
    REFERENCES hist_soc.socfiche (nfiche) MATCH SIMPLE ON UPDATE CASCADE ON DELETE CASCADE;


-----------------------------
--HISTORIQUE FAUNE VERTEBRE--
-----------------------------
IMPORT FOREIGN SCHEMA historique LIMIT TO(bib_criterefv, fvfiche, fvreleves, rel_classe_critfv) FROM SERVER geonature1server INTO v1_compat;
CREATE SCHEMA hist_fv;
CREATE TABLE hist_fv.bib_criterefv AS
SELECT * FROM v1_compat.bib_criterefv;
CREATE TABLE hist_fv.fvfiche AS
SELECT * FROM v1_compat.fvfiche;
CREATE TABLE hist_fv.fvreleves AS
SELECT * FROM v1_compat.fvreleves;
CREATE TABLE hist_fv.rel_classe_critfv AS
SELECT * FROM v1_compat.rel_classe_critfv;
ALTER TABLE hist_fv.bib_criterefv ADD CONSTRAINT pk_bib_criterefv PRIMARY KEY(codecritfv);
ALTER TABLE hist_fv.fvfiche ADD CONSTRAINT pk_fvfiche PRIMARY KEY(nfiche);
ALTER TABLE hist_fv.fvreleves ADD CONSTRAINT pk_fvreleves PRIMARY KEY(num_auto);
ALTER TABLE hist_fv.rel_classe_critfv ADD CONSTRAINT pk_rel_classe_critfv PRIMARY KEY(codeclasse, codecritfv);
ALTER TABLE hist_fv.rel_classe_critfv ADD CONSTRAINT fk_rel_critfv_classe_bib_crite FOREIGN KEY (codecritfv)
    REFERENCES hist_fv.bib_criterefv (codecritfv) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION;
ALTER TABLE hist_fv.fvreleves ADD CONSTRAINT fk_fvreleves_bib_criterefv FOREIGN KEY (codecritfv)
    REFERENCES hist_fv.bib_criterefv (codecritfv) MATCH SIMPLE ON UPDATE CASCADE ON DELETE NO ACTION;
ALTER TABLE hist_fv.fvreleves ADD CONSTRAINT fk_fvreleves_bib_especes FOREIGN KEY (codeespece)
    REFERENCES taxonomie.bib_noms (id_nom) MATCH SIMPLE ON UPDATE CASCADE ON DELETE NO ACTION;
ALTER TABLE hist_fv.fvreleves ADD CONSTRAINT fk_fvreleves_fvfiche FOREIGN KEY (nfiche)
    REFERENCES hist_fv.fvfiche (nfiche) MATCH SIMPLE ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE hist_fv.fvreleves ADD CONSTRAINT enforce_dims_the_geom_27572 CHECK (public.st_ndims(the_geom_27572) = 2);
ALTER TABLE hist_fv.fvreleves ADD CONSTRAINT enforce_srid_the_geom_27572 CHECK (public.st_srid(the_geom_27572) = 27572);
ALTER TABLE hist_fv.fvfiche ADD CONSTRAINT fk_fvfiche_bib_lots FOREIGN KEY (id_lot)
    REFERENCES gn_meta.t_datasets (id_dataset) MATCH SIMPLE ON UPDATE CASCADE ON DELETE NO ACTION;
ALTER TABLE hist_fv.fvfiche ADD CONSTRAINT fk_fvfiche_bib_observateurs FOREIGN KEY (codeobs)
    REFERENCES hist_archives.bib_observateurs (codeobs) MATCH SIMPLE ON UPDATE CASCADE ON DELETE NO ACTION;
ALTER TABLE hist_fv.fvfiche ADD CONSTRAINT fk_fvfiche_bib_protocoles FOREIGN KEY (codeprotocole)
    REFERENCES hist_archives.bib_protocoles (codeprotocole) MATCH SIMPLE ON UPDATE CASCADE ON DELETE NO ACTION;


-------------------------------
--HISTORIQUE FAUNE INVERTEBRE--
-------------------------------
IMPORT FOREIGN SCHEMA historique LIMIT TO(bib_critereinv, invfiche, invreleves) FROM SERVER geonature1server INTO v1_compat;
CREATE SCHEMA hist_inv;
CREATE TABLE hist_inv.bib_critereinv AS
SELECT * FROM v1_compat.bib_critereinv;
CREATE TABLE hist_inv.invfiche AS
SELECT * FROM v1_compat.invfiche;
CREATE TABLE hist_inv.invreleves AS
SELECT * FROM v1_compat.invreleves;
ALTER TABLE hist_inv.bib_critereinv ADD CONSTRAINT criteres_invertebres_pkey PRIMARY KEY(codecritinv);
ALTER TABLE hist_inv.invfiche ADD CONSTRAINT invfiche_pkey PRIMARY KEY(nfiche);
ALTER TABLE hist_inv.invreleves ADD CONSTRAINT invreleves_pkey PRIMARY KEY(num_auto);
ALTER TABLE hist_inv.invfiche ADD CONSTRAINT fk_invfiche_bib_lots FOREIGN KEY (id_lot)
    REFERENCES gn_meta.t_datasets (id_dataset) MATCH SIMPLE ON UPDATE CASCADE ON DELETE NO ACTION;
ALTER TABLE hist_inv.invfiche ADD CONSTRAINT fk_invfiche_bib_observateurs FOREIGN KEY (codeobs)
    REFERENCES hist_archives.bib_observateurs (codeobs) MATCH SIMPLE ON UPDATE CASCADE ON DELETE NO ACTION;
ALTER TABLE hist_inv.invreleves ADD CONSTRAINT fk_invreleves_bib_especes FOREIGN KEY (codeespece)
    REFERENCES taxonomie.bib_noms (id_nom) MATCH SIMPLE ON UPDATE CASCADE ON DELETE NO ACTION;
ALTER TABLE hist_inv.invreleves ADD CONSTRAINT fk_invreleves_critinv FOREIGN KEY (codecritinv)
    REFERENCES hist_inv.bib_critereinv (codecritinv) MATCH SIMPLE ON UPDATE CASCADE ON DELETE NO ACTION;
ALTER TABLE hist_inv.invreleves ADD CONSTRAINT fk_invreleves_invfiche FOREIGN KEY (nfiche)
    REFERENCES hist_inv.invfiche (nfiche) MATCH SIMPLE ON UPDATE CASCADE ON DELETE CASCADE;


----------
--IMPORT--
----------
IMPORT FOREIGN SCHEMA imports FROM SERVER geonature1server INTO v1_compat;
CREATE SCHEMA v1_imports;
CREATE TABLE v1_imports.importedobs AS
SELECT * FROM v1_compat.importedobs;
TRUNCATE TABLE v1_imports.importedobs CASCADE;
CREATE TABLE v1_imports.tmp4csv AS
SELECT * FROM v1_compat.tmp4csv;
TRUNCATE TABLE v1_imports.tmp4csv CASCADE;
CREATE TABLE v1_imports.tmpnewnoms AS
SELECT * FROM v1_compat.tmpnewnoms;
TRUNCATE TABLE v1_imports.tmpnewnoms CASCADE;
ALTER TABLE v1_imports.importedobs ADD CONSTRAINT pk_importedobs PRIMARY KEY(id);
ALTER TABLE v1_imports.tmp4csv ADD CONSTRAINT pk_csv PRIMARY KEY(id_csv);
ALTER TABLE v1_imports.tmpnewnoms ADD CONSTRAINT pk_tmpnewnoms PRIMARY KEY(cd_nom);
ALTER TABLE v1_imports.importedobs ADD CONSTRAINT fk_importedobs_bib_organismes FOREIGN KEY (id_organisme)
    REFERENCES utilisateurs.bib_organismes (id_organisme) MATCH SIMPLE ON UPDATE CASCADE ON DELETE NO ACTION;
ALTER TABLE v1_imports.importedobs ADD CONSTRAINT importedobs_id_lot_fkey FOREIGN KEY (id_lot)
    REFERENCES gn_meta.t_datasets (id_dataset) MATCH SIMPLE ON UPDATE CASCADE ON DELETE NO ACTION;
ALTER TABLE v1_imports.importedobs ADD CONSTRAINT importedobs_id_protocole_fkey FOREIGN KEY (id_protocole)
    REFERENCES hist_archives.bib_protocoles (codeprotocole) MATCH SIMPLE ON UPDATE CASCADE ON DELETE NO ACTION;
ALTER TABLE v1_imports.importedobs ADD CONSTRAINT importedobs_id_source_fkey FOREIGN KEY (id_source)
    REFERENCES gn_synthese.t_sources (id_source) MATCH SIMPLE ON UPDATE CASCADE ON DELETE NO ACTION;
ALTER TABLE v1_imports.importedobs ADD CONSTRAINT importedobs_id_critere_synthese_gn1_fkey FOREIGN KEY (id_critere_synthese)
    REFERENCES hist_archives.bib_criteres_synthese_gn1 (id_critere_synthese) MATCH SIMPLE ON UPDATE CASCADE ON DELETE NO ACTION;
ALTER TABLE v1_imports.importedobs ADD CONSTRAINT enforce_dims_the_geom_2154 CHECK (public.st_ndims(the_geom_2154) = 2);
ALTER TABLE v1_imports.importedobs ADD CONSTRAINT enforce_dims_the_geom_3857 CHECK (public.st_ndims(the_geom_3857) = 2);
ALTER TABLE v1_imports.importedobs ADD CONSTRAINT enforce_dims_the_geom_point CHECK (public.st_ndims(the_geom_point) = 2);
ALTER TABLE v1_imports.importedobs ADD CONSTRAINT enforce_geotype_the_geom_point CHECK (public.st_geometrytype(the_geom_point) = 'ST_Point'::text OR the_geom_point IS NULL);
ALTER TABLE v1_imports.importedobs ADD CONSTRAINT enforce_srid_the_geom_2154 CHECK (public.st_srid(the_geom_2154) = 2154);
ALTER TABLE v1_imports.importedobs ADD CONSTRAINT enforce_srid_the_geom_3857 CHECK (public.st_srid(the_geom_3857) = 3857);
ALTER TABLE v1_imports.importedobs ADD CONSTRAINT enforce_srid_the_geom_point CHECK (public.st_srid(the_geom_point) = 3857);
ALTER TABLE v1_imports.importedobs ADD CONSTRAINT importedobs_cle_check CHECK (cle < 5);
CREATE SEQUENCE v1_imports.tmp4csv_id_csv_seq
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 1
  CACHE 1;


----------------
--NATURALISTES--
----------------
INSERT INTO gn_meta.sinp_datatype_protocols (id_protocol, protocol_name, protocol_desc, id_nomenclature_protocol_type)
VALUES(0, 'pas de correspondance dans cette table', 'le protocole n''est pas connu ou n''est pas décrit dans cette table', 394);
IMPORT FOREIGN SCHEMA naturalistes EXCEPT(fauneisere) FROM SERVER geonature1server INTO v1_compat;
CREATE SCHEMA partenaires_naturalistes;
CREATE TABLE partenaires_naturalistes.bernard_frin AS
SELECT * FROM v1_compat.bernard_frin;
CREATE TABLE partenaires_naturalistes.christophe_perrier AS
SELECT * FROM v1_compat.christophe_perrier;
CREATE TABLE partenaires_naturalistes.eric_drouet AS
SELECT * FROM v1_compat.eric_drouet;
CREATE TABLE partenaires_naturalistes.jacques_nel AS
SELECT * FROM v1_compat.jacques_nel;
CREATE TABLE partenaires_naturalistes.pierre_frapa AS
SELECT * FROM v1_compat.pierre_frapa;
CREATE TABLE partenaires_naturalistes.stephane_bence AS
SELECT * FROM v1_compat.stephane_bence;

ALTER TABLE partenaires_naturalistes.bernard_frin ADD CONSTRAINT pk_bernard_frin PRIMARY KEY(gid);
ALTER TABLE partenaires_naturalistes.christophe_perrier ADD CONSTRAINT pk_christophe_perrier PRIMARY KEY(gid);
ALTER TABLE partenaires_naturalistes.eric_drouet ADD CONSTRAINT pk_eric_drouet PRIMARY KEY(gid);
ALTER TABLE partenaires_naturalistes.jacques_nel ADD CONSTRAINT pk_jacques_nel PRIMARY KEY(gid);
ALTER TABLE partenaires_naturalistes.pierre_frapa ADD CONSTRAINT pk_pierre_frapa PRIMARY KEY(gid);
ALTER TABLE partenaires_naturalistes.stephane_bence ADD CONSTRAINT pk_stephane_bence PRIMARY KEY(gid);
ALTER TABLE partenaires_naturalistes.bernard_frin ADD CONSTRAINT fk_bernard_frin_bib_organismes FOREIGN KEY (id_organisme)
    REFERENCES utilisateurs.bib_organismes (id_organisme) MATCH SIMPLE ON UPDATE CASCADE ON DELETE NO ACTION;
ALTER TABLE partenaires_naturalistes.bernard_frin ADD CONSTRAINT bernard_frin_id_lot_fkey FOREIGN KEY (id_lot)
    REFERENCES gn_meta.t_datasets (id_dataset) MATCH SIMPLE ON UPDATE CASCADE ON DELETE NO ACTION;
ALTER TABLE partenaires_naturalistes.bernard_frin ADD CONSTRAINT bernard_frin_id_protocole_fkey FOREIGN KEY (id_protocole)
    REFERENCES gn_meta.sinp_datatype_protocols (id_protocol) MATCH SIMPLE ON UPDATE CASCADE ON DELETE NO ACTION;
ALTER TABLE partenaires_naturalistes.bernard_frin ADD CONSTRAINT bernard_frin_id_source_fkey FOREIGN KEY (id_source)
      REFERENCES gn_synthese.t_sources (id_source) MATCH SIMPLE ON UPDATE CASCADE ON DELETE NO ACTION;
ALTER TABLE partenaires_naturalistes.bernard_frin ADD CONSTRAINT bernard_frin_id_critere_synthese_gn1_fkey FOREIGN KEY (id_critere_synthese)
      REFERENCES hist_archives.bib_criteres_synthese_gn1 (id_critere_synthese) MATCH SIMPLE ON UPDATE CASCADE ON DELETE NO ACTION;
ALTER TABLE partenaires_naturalistes.bernard_frin ADD CONSTRAINT enforce_dims_the_geom_2154 CHECK (public.st_ndims(the_geom_2154) = 2);
ALTER TABLE partenaires_naturalistes.bernard_frin ADD CONSTRAINT enforce_dims_the_geom_3857 CHECK (public.st_ndims(the_geom_3857) = 2);
ALTER TABLE partenaires_naturalistes.bernard_frin ADD CONSTRAINT enforce_dims_the_geom_point CHECK (public.st_ndims(the_geom_point) = 2);
ALTER TABLE partenaires_naturalistes.bernard_frin ADD CONSTRAINT enforce_geotype_the_geom_point CHECK (public.st_geometrytype(the_geom_point) = 'ST_Point'::text OR the_geom_point IS NULL);
ALTER TABLE partenaires_naturalistes.bernard_frin ADD CONSTRAINT enforce_srid_the_geom_2154 CHECK (public.st_srid(the_geom_2154) = 2154);
ALTER TABLE partenaires_naturalistes.bernard_frin ADD CONSTRAINT enforce_srid_the_geom_3857 CHECK (public.st_srid(the_geom_3857) = 3857);
ALTER TABLE partenaires_naturalistes.bernard_frin ADD CONSTRAINT enforce_srid_the_geom_point CHECK (public.st_srid(the_geom_point) = 3857);
ALTER TABLE partenaires_naturalistes.bernard_frin ADD CONSTRAINT bernard_frin_cle_check CHECK (cle < 5);

ALTER TABLE partenaires_naturalistes.christophe_perrier ADD CONSTRAINT fk_christophe_perrier_bib_organismes FOREIGN KEY (id_organisme)
    REFERENCES utilisateurs.bib_organismes (id_organisme) MATCH SIMPLE ON UPDATE CASCADE ON DELETE NO ACTION;
ALTER TABLE partenaires_naturalistes.christophe_perrier ADD CONSTRAINT christophe_perrier_id_lot_fkey FOREIGN KEY (id_lot)
    REFERENCES gn_meta.t_datasets (id_dataset) MATCH SIMPLE ON UPDATE CASCADE ON DELETE NO ACTION;
ALTER TABLE partenaires_naturalistes.christophe_perrier ADD CONSTRAINT christophe_perrier_id_protocole_fkey FOREIGN KEY (id_protocole)
    REFERENCES gn_meta.sinp_datatype_protocols (id_protocol) MATCH SIMPLE ON UPDATE CASCADE ON DELETE NO ACTION;
ALTER TABLE partenaires_naturalistes.christophe_perrier ADD CONSTRAINT christophe_perrier_id_source_fkey FOREIGN KEY (id_source)
    REFERENCES gn_synthese.t_sources (id_source) MATCH SIMPLE ON UPDATE CASCADE ON DELETE NO ACTION;
ALTER TABLE partenaires_naturalistes.christophe_perrier ADD CONSTRAINT christophe_perrier_id_critere_synthese_gn1_fkey FOREIGN KEY (id_critere_synthese)
    REFERENCES hist_archives.bib_criteres_synthese_gn1 (id_critere_synthese) MATCH SIMPLE ON UPDATE CASCADE ON DELETE NO ACTION;
ALTER TABLE partenaires_naturalistes.christophe_perrier ADD CONSTRAINT enforce_dims_the_geom_2154 CHECK (public.st_ndims(the_geom_2154) = 2);
ALTER TABLE partenaires_naturalistes.christophe_perrier ADD CONSTRAINT enforce_dims_the_geom_3857 CHECK (public.st_ndims(the_geom_3857) = 2);
ALTER TABLE partenaires_naturalistes.christophe_perrier ADD CONSTRAINT enforce_dims_the_geom_point CHECK (public.st_ndims(the_geom_point) = 2);
ALTER TABLE partenaires_naturalistes.christophe_perrier ADD CONSTRAINT enforce_geotype_the_geom_point CHECK (public.st_geometrytype(the_geom_point) = 'ST_Point'::text OR the_geom_point IS NULL);
ALTER TABLE partenaires_naturalistes.christophe_perrier ADD CONSTRAINT enforce_srid_the_geom_2154 CHECK (public.st_srid(the_geom_2154) = 2154);
ALTER TABLE partenaires_naturalistes.christophe_perrier ADD CONSTRAINT enforce_srid_the_geom_3857 CHECK (public.st_srid(the_geom_3857) = 3857);
ALTER TABLE partenaires_naturalistes.christophe_perrier ADD CONSTRAINT enforce_srid_the_geom_point CHECK (public.st_srid(the_geom_point) = 3857);
ALTER TABLE partenaires_naturalistes.christophe_perrier ADD CONSTRAINT christophe_perrier_cle_check CHECK (cle < 5);

ALTER TABLE partenaires_naturalistes.eric_drouet ADD CONSTRAINT fk_eric_drouet_bib_organismes FOREIGN KEY (id_organisme)
    REFERENCES utilisateurs.bib_organismes (id_organisme) MATCH SIMPLE ON UPDATE CASCADE ON DELETE NO ACTION;
ALTER TABLE partenaires_naturalistes.eric_drouet ADD CONSTRAINT eric_drouet_id_lot_fkey FOREIGN KEY (id_lot)
    REFERENCES gn_meta.t_datasets (id_dataset) MATCH SIMPLE ON UPDATE CASCADE ON DELETE NO ACTION;
ALTER TABLE partenaires_naturalistes.eric_drouet ADD CONSTRAINT eric_drouet_id_protocole_fkey FOREIGN KEY (id_protocole)
    REFERENCES gn_meta.sinp_datatype_protocols (id_protocol) MATCH SIMPLE ON UPDATE CASCADE ON DELETE NO ACTION;
ALTER TABLE partenaires_naturalistes.eric_drouet ADD CONSTRAINT eric_drouet_id_source_fkey FOREIGN KEY (id_source)
    REFERENCES gn_synthese.t_sources (id_source) MATCH SIMPLE ON UPDATE CASCADE ON DELETE NO ACTION;
ALTER TABLE partenaires_naturalistes.eric_drouet ADD CONSTRAINT eric_drouet_id_critere_synthese_gn1_fkey FOREIGN KEY (id_critere_synthese)
    REFERENCES hist_archives.bib_criteres_synthese_gn1 (id_critere_synthese) MATCH SIMPLE ON UPDATE CASCADE ON DELETE NO ACTION;
ALTER TABLE partenaires_naturalistes.eric_drouet ADD CONSTRAINT enforce_dims_the_geom_2154 CHECK (public.st_ndims(the_geom_2154) = 2);
ALTER TABLE partenaires_naturalistes.eric_drouet ADD CONSTRAINT enforce_dims_the_geom_3857 CHECK (public.st_ndims(the_geom_3857) = 2);
ALTER TABLE partenaires_naturalistes.eric_drouet ADD CONSTRAINT enforce_dims_the_geom_point CHECK (public.st_ndims(the_geom_point) = 2);
ALTER TABLE partenaires_naturalistes.eric_drouet ADD CONSTRAINT enforce_geotype_the_geom_point CHECK (public.st_geometrytype(the_geom_point) = 'ST_Point'::text OR the_geom_point IS NULL);
ALTER TABLE partenaires_naturalistes.eric_drouet ADD CONSTRAINT enforce_srid_the_geom_2154 CHECK (public.st_srid(the_geom_2154) = 2154);
ALTER TABLE partenaires_naturalistes.eric_drouet ADD CONSTRAINT enforce_srid_the_geom_3857 CHECK (public.st_srid(the_geom_3857) = 3857);
ALTER TABLE partenaires_naturalistes.eric_drouet ADD CONSTRAINT enforce_srid_the_geom_point CHECK (public.st_srid(the_geom_point) = 3857);
ALTER TABLE partenaires_naturalistes.eric_drouet ADD CONSTRAINT eric_drouet_cle_check CHECK (cle < 5);

ALTER TABLE partenaires_naturalistes.jacques_nel ADD CONSTRAINT fk_jacques_nel_bib_organismes FOREIGN KEY (id_organisme)
    REFERENCES utilisateurs.bib_organismes (id_organisme) MATCH SIMPLE ON UPDATE CASCADE ON DELETE NO ACTION;
ALTER TABLE partenaires_naturalistes.jacques_nel ADD CONSTRAINT jacques_nel_id_lot_fkey FOREIGN KEY (id_lot)
    REFERENCES gn_meta.t_datasets (id_dataset) MATCH SIMPLE ON UPDATE CASCADE ON DELETE NO ACTION;
ALTER TABLE partenaires_naturalistes.jacques_nel ADD CONSTRAINT jacques_nel_id_protocole_fkey FOREIGN KEY (id_protocole)
    REFERENCES gn_meta.sinp_datatype_protocols (id_protocol) MATCH SIMPLE ON UPDATE CASCADE ON DELETE NO ACTION;
ALTER TABLE partenaires_naturalistes.jacques_nel ADD CONSTRAINT jacques_nel_id_source_fkey FOREIGN KEY (id_source)
    REFERENCES gn_synthese.t_sources (id_source) MATCH SIMPLE ON UPDATE CASCADE ON DELETE NO ACTION;
ALTER TABLE partenaires_naturalistes.jacques_nel ADD CONSTRAINT jacques_nel_id_critere_synthese_gn1_fkey FOREIGN KEY (id_critere_synthese)
    REFERENCES hist_archives.bib_criteres_synthese_gn1 (id_critere_synthese) MATCH SIMPLE ON UPDATE CASCADE ON DELETE NO ACTION;
ALTER TABLE partenaires_naturalistes.jacques_nel ADD CONSTRAINT enforce_dims_the_geom_2154 CHECK (public.st_ndims(the_geom_2154) = 2);
ALTER TABLE partenaires_naturalistes.jacques_nel ADD CONSTRAINT enforce_dims_the_geom_3857 CHECK (public.st_ndims(the_geom_3857) = 2);
ALTER TABLE partenaires_naturalistes.jacques_nel ADD CONSTRAINT enforce_dims_the_geom_point CHECK (public.st_ndims(the_geom_point) = 2);
ALTER TABLE partenaires_naturalistes.jacques_nel ADD CONSTRAINT enforce_geotype_the_geom_point CHECK (public.st_geometrytype(the_geom_point) = 'ST_Point'::text OR the_geom_point IS NULL);
ALTER TABLE partenaires_naturalistes.jacques_nel ADD CONSTRAINT enforce_srid_the_geom_2154 CHECK (public.st_srid(the_geom_2154) = 2154);
ALTER TABLE partenaires_naturalistes.jacques_nel ADD CONSTRAINT enforce_srid_the_geom_3857 CHECK (public.st_srid(the_geom_3857) = 3857);
ALTER TABLE partenaires_naturalistes.jacques_nel ADD CONSTRAINT enforce_srid_the_geom_point CHECK (public.st_srid(the_geom_point) = 3857);
ALTER TABLE partenaires_naturalistes.jacques_nel ADD CONSTRAINT jacques_nel_cle_check CHECK (cle < 5);

ALTER TABLE partenaires_naturalistes.pierre_frapa ADD CONSTRAINT fk_pierre_frapa_bib_organismes FOREIGN KEY (id_organisme)
    REFERENCES utilisateurs.bib_organismes (id_organisme) MATCH SIMPLE ON UPDATE CASCADE ON DELETE NO ACTION;
ALTER TABLE partenaires_naturalistes.pierre_frapa ADD CONSTRAINT pierre_frapa_id_lot_fkey FOREIGN KEY (id_lot)
    REFERENCES gn_meta.t_datasets (id_dataset) MATCH SIMPLE ON UPDATE CASCADE ON DELETE NO ACTION;
ALTER TABLE partenaires_naturalistes.pierre_frapa ADD CONSTRAINT pierre_frapa_id_protocole_fkey FOREIGN KEY (id_protocole)
    REFERENCES gn_meta.sinp_datatype_protocols (id_protocol) MATCH SIMPLE ON UPDATE CASCADE ON DELETE NO ACTION;
ALTER TABLE partenaires_naturalistes.pierre_frapa ADD CONSTRAINT pierre_frapa_id_source_fkey FOREIGN KEY (id_source)
    REFERENCES gn_synthese.t_sources (id_source) MATCH SIMPLE ON UPDATE CASCADE ON DELETE NO ACTION;
ALTER TABLE partenaires_naturalistes.pierre_frapa ADD CONSTRAINT pierre_frapa_id_critere_synthese_gn1_fkey FOREIGN KEY (id_critere_synthese)
    REFERENCES hist_archives.bib_criteres_synthese_gn1 (id_critere_synthese) MATCH SIMPLE ON UPDATE CASCADE ON DELETE NO ACTION;
ALTER TABLE partenaires_naturalistes.pierre_frapa ADD CONSTRAINT enforce_dims_the_geom_2154 CHECK (public.st_ndims(the_geom_2154) = 2);
ALTER TABLE partenaires_naturalistes.pierre_frapa ADD CONSTRAINT enforce_dims_the_geom_3857 CHECK (public.st_ndims(the_geom_3857) = 2);
ALTER TABLE partenaires_naturalistes.pierre_frapa ADD CONSTRAINT enforce_dims_the_geom_point CHECK (public.st_ndims(the_geom_point) = 2);
ALTER TABLE partenaires_naturalistes.pierre_frapa ADD CONSTRAINT enforce_geotype_the_geom_point CHECK (public.st_geometrytype(the_geom_point) = 'ST_Point'::text OR the_geom_point IS NULL);
ALTER TABLE partenaires_naturalistes.pierre_frapa ADD CONSTRAINT enforce_srid_the_geom_2154 CHECK (public.st_srid(the_geom_2154) = 2154);
ALTER TABLE partenaires_naturalistes.pierre_frapa ADD CONSTRAINT enforce_srid_the_geom_3857 CHECK (public.st_srid(the_geom_3857) = 3857);
ALTER TABLE partenaires_naturalistes.pierre_frapa ADD CONSTRAINT enforce_srid_the_geom_point CHECK (public.st_srid(the_geom_point) = 3857);
ALTER TABLE partenaires_naturalistes.pierre_frapa ADD CONSTRAINT pierre_frapa_cle_check CHECK (cle < 5);

ALTER TABLE partenaires_naturalistes.stephane_bence ADD CONSTRAINT fk_stephane_bence_bib_organismes FOREIGN KEY (id_organisme)
    REFERENCES utilisateurs.bib_organismes (id_organisme) MATCH SIMPLE ON UPDATE CASCADE ON DELETE NO ACTION;
ALTER TABLE partenaires_naturalistes.stephane_bence ADD CONSTRAINT stephane_bence_id_lot_fkey FOREIGN KEY (id_lot)
    REFERENCES gn_meta.t_datasets (id_dataset) MATCH SIMPLE ON UPDATE CASCADE ON DELETE NO ACTION;
ALTER TABLE partenaires_naturalistes.stephane_bence ADD CONSTRAINT stephane_bence_id_protocole_fkey FOREIGN KEY (id_protocole)
    REFERENCES gn_meta.sinp_datatype_protocols (id_protocol) MATCH SIMPLE ON UPDATE CASCADE ON DELETE NO ACTION;
ALTER TABLE partenaires_naturalistes.stephane_bence ADD CONSTRAINT stephane_bence_id_source_fkey FOREIGN KEY (id_source)
      REFERENCES gn_synthese.t_sources (id_source) MATCH SIMPLE ON UPDATE CASCADE ON DELETE NO ACTION;
ALTER TABLE partenaires_naturalistes.stephane_bence ADD CONSTRAINT stephane_bence_id_critere_synthese_gn1_fkey FOREIGN KEY (id_critere_synthese)
    REFERENCES hist_archives.bib_criteres_synthese_gn1 (id_critere_synthese) MATCH SIMPLE ON UPDATE CASCADE ON DELETE NO ACTION;
ALTER TABLE partenaires_naturalistes.stephane_bence ADD CONSTRAINT enforce_dims_the_geom_2154 CHECK (public.st_ndims(the_geom_2154) = 2);
ALTER TABLE partenaires_naturalistes.stephane_bence ADD CONSTRAINT enforce_dims_the_geom_3857 CHECK (public.st_ndims(the_geom_3857) = 2);
ALTER TABLE partenaires_naturalistes.stephane_bence ADD CONSTRAINT enforce_dims_the_geom_point CHECK (public.st_ndims(the_geom_point) = 2);
ALTER TABLE partenaires_naturalistes.stephane_bence ADD CONSTRAINT enforce_geotype_the_geom_point CHECK (public.st_geometrytype(the_geom_point) = 'ST_Point'::text OR the_geom_point IS NULL);
ALTER TABLE partenaires_naturalistes.stephane_bence ADD CONSTRAINT enforce_srid_the_geom_2154 CHECK (public.st_srid(the_geom_2154) = 2154);
ALTER TABLE partenaires_naturalistes.stephane_bence ADD CONSTRAINT enforce_srid_the_geom_3857 CHECK (public.st_srid(the_geom_3857) = 3857);
ALTER TABLE partenaires_naturalistes.stephane_bence ADD CONSTRAINT enforce_srid_the_geom_point CHECK (public.st_srid(the_geom_point) = 3857);
ALTER TABLE partenaires_naturalistes.stephane_bence ADD CONSTRAINT stephane_bence_cle_check CHECK (cle < 5);


-------
--LPO--
-------
IMPORT FOREIGN SCHEMA partenaires LIMIT TO(lpo_paca, cor_critere_lpo_synthese) FROM SERVER geonature1server INTO v1_compat;
CREATE SCHEMA partenaires_lpo;
CREATE TABLE partenaires_lpo.cor_critere_lpo_synthese_gn1 AS
SELECT * FROM v1_compat.cor_critere_lpo_synthese;
CREATE TABLE partenaires_lpo.lpo_paca AS
SELECT * FROM v1_compat.lpo_paca;
ALTER TABLE partenaires_lpo.cor_critere_lpo_synthese_gn1 ADD CONSTRAINT pk_cor_critere_lpo_synthese_gn1 PRIMARY KEY(code_atlas, id_critere_synthese);
ALTER TABLE partenaires_lpo.lpo_paca ADD CONSTRAINT pk_lpo_paca PRIMARY KEY(id_sighting);
ALTER TABLE partenaires_lpo.lpo_paca ADD CONSTRAINT enforce_dims_the_geom_4326 CHECK (st_ndims(the_geom_4326) = 2);
ALTER TABLE partenaires_lpo.lpo_paca ADD CONSTRAINT enforce_geotype_the_geom_4326 CHECK (st_geometrytype(the_geom_4326) = 'ST_Point'::text OR the_geom_4326 IS NULL);
ALTER TABLE partenaires_lpo.lpo_paca ADD CONSTRAINT enforce_srid_the_geom_4326 CHECK (st_srid(the_geom_4326) = 4326);

IMPORT FOREIGN SCHEMA naturalistes LIMIT TO(fauneisere) FROM SERVER geonature1server INTO v1_compat;
CREATE TABLE partenaires_lpo.lpo_isere AS
SELECT * FROM v1_compat.fauneisere;
ALTER TABLE partenaires_lpo.lpo_isere ADD CONSTRAINT pk_lpo_isere PRIMARY KEY(id);
ALTER TABLE partenaires_lpo.lpo_isere ADD CONSTRAINT enforce_dims_the_geom_2154 CHECK (public.st_ndims(the_geom_2154) = 2);
ALTER TABLE partenaires_lpo.lpo_isere ADD CONSTRAINT enforce_geotype_the_geom_2154 CHECK (public.st_geometrytype(the_geom_2154) = 'ST_Point'::text OR the_geom_2154 IS NULL);
ALTER TABLE partenaires_lpo.lpo_isere ADD CONSTRAINT enforce_srid_the_geom_2154 CHECK (public.st_srid(the_geom_2154) = 2154);

-----------
--EXPERTS--
-----------
IMPORT FOREIGN SCHEMA partenaires LIMIT TO(rencontres, experts, atbi, abc) FROM SERVER geonature1server INTO v1_compat;
CREATE SCHEMA partenaires_experts;
CREATE TABLE partenaires_experts.experts AS
SELECT * FROM v1_compat.experts;
CREATE TABLE partenaires_experts.rencontres AS
SELECT * FROM v1_compat.rencontres;
CREATE TABLE partenaires_experts.atbi AS
SELECT * FROM v1_compat.atbi;
CREATE TABLE partenaires_experts.abc AS
SELECT * FROM v1_compat.abc;
ALTER TABLE partenaires_experts.rencontres ADD CONSTRAINT pk_rencontres PRIMARY KEY(gid);
ALTER TABLE partenaires_experts.experts ADD CONSTRAINT pk_experts PRIMARY KEY(id_expert);
ALTER TABLE partenaires_experts.atbi ADD CONSTRAINT atbi_pkey PRIMARY KEY(id_atbi);
ALTER TABLE partenaires_experts.abc ADD CONSTRAINT abc_pkey PRIMARY KEY(id_abc);

ALTER TABLE partenaires_experts.experts ADD CONSTRAINT experts_id_lot_fkey FOREIGN KEY (id_lot)
    REFERENCES gn_meta.t_datasets (id_dataset) MATCH SIMPLE ON UPDATE CASCADE ON DELETE NO ACTION;
ALTER TABLE partenaires_experts.experts ADD CONSTRAINT experts_id_protocole_fkey FOREIGN KEY (id_protocole)
    REFERENCES gn_meta.sinp_datatype_protocols (id_protocol) MATCH SIMPLE ON UPDATE CASCADE ON DELETE NO ACTION;
ALTER TABLE partenaires_experts.experts ADD CONSTRAINT experts_id_source_fkey FOREIGN KEY (id_source)
    REFERENCES gn_synthese.t_sources (id_source) MATCH SIMPLE ON UPDATE CASCADE ON DELETE NO ACTION;
ALTER TABLE partenaires_experts.experts ADD CONSTRAINT fk_experts_bib_organismes FOREIGN KEY (id_organisme)
    REFERENCES utilisateurs.bib_organismes (id_organisme) MATCH SIMPLE ON UPDATE CASCADE ON DELETE NO ACTION;
ALTER TABLE partenaires_experts.experts ADD CONSTRAINT experts_id_critere_synthese_fkey FOREIGN KEY (id_critere_synthese)
    REFERENCES hist_archives.bib_criteres_synthese_gn1 (id_critere_synthese) MATCH SIMPLE ON UPDATE CASCADE ON DELETE NO ACTION;
ALTER TABLE partenaires_experts.experts ADD CONSTRAINT enforce_dims_the_geom_2154 CHECK (public.st_ndims(the_geom_2154) = 2);
ALTER TABLE partenaires_experts.experts ADD CONSTRAINT enforce_dims_the_geom_3857 CHECK (public.st_ndims(the_geom_3857) = 2);
ALTER TABLE partenaires_experts.experts ADD CONSTRAINT enforce_dims_the_geom_point CHECK (public.st_ndims(the_geom_point) = 2);
ALTER TABLE partenaires_experts.experts ADD CONSTRAINT enforce_geotype_the_geom_point CHECK (public.st_geometrytype(the_geom_point) = 'ST_Point'::text OR the_geom_point IS NULL);
ALTER TABLE partenaires_experts.experts ADD CONSTRAINT enforce_srid_the_geom_2154 CHECK (public.st_srid(the_geom_2154) = 2154);
ALTER TABLE partenaires_experts.experts ADD CONSTRAINT enforce_srid_the_geom_3857 CHECK (public.st_srid(the_geom_3857) = 3857);
ALTER TABLE partenaires_experts.experts ADD CONSTRAINT enforce_srid_the_geom_point CHECK (public.st_srid(the_geom_point) = 3857);
ALTER TABLE partenaires_experts.experts ADD CONSTRAINT experts_cle_check CHECK (cle < 5);
CREATE TRIGGER tri_insert_experts
  BEFORE INSERT
  ON partenaires_experts.experts
  FOR EACH ROW
  EXECUTE PROCEDURE insert_maj_date();
CREATE TRIGGER tri_update_experts
  BEFORE UPDATE
  ON partenaires_experts.experts
  FOR EACH ROW
  EXECUTE PROCEDURE update_maj_date();

ALTER TABLE partenaires_experts.rencontres ADD CONSTRAINT rencontres_id_lot_fkey FOREIGN KEY (id_lot)
    REFERENCES gn_meta.t_datasets (id_dataset) MATCH SIMPLE ON UPDATE CASCADE ON DELETE NO ACTION;
ALTER TABLE partenaires_experts.rencontres ADD CONSTRAINT rencontres_id_protocole_fkey FOREIGN KEY (id_protocole)
    REFERENCES gn_meta.sinp_datatype_protocols (id_protocol) MATCH SIMPLE ON UPDATE CASCADE ON DELETE NO ACTION;
ALTER TABLE partenaires_experts.rencontres ADD CONSTRAINT rencontres_id_source_fkey FOREIGN KEY (id_source)
    REFERENCES gn_synthese.t_sources (id_source) MATCH SIMPLE ON UPDATE CASCADE ON DELETE NO ACTION;
ALTER TABLE partenaires_experts.rencontres ADD CONSTRAINT fk_rencontres_bib_organismes FOREIGN KEY (id_organisme)
    REFERENCES utilisateurs.bib_organismes (id_organisme) MATCH SIMPLE ON UPDATE CASCADE ON DELETE NO ACTION;
ALTER TABLE partenaires_experts.rencontres ADD CONSTRAINT rencontres_id_critere_synthese_fkey FOREIGN KEY (id_critere_synthese)
    REFERENCES hist_archives.bib_criteres_synthese_gn1 (id_critere_synthese) MATCH SIMPLE ON UPDATE CASCADE ON DELETE NO ACTION;
ALTER TABLE partenaires_experts.rencontres ADD CONSTRAINT enforce_dims_the_geom_2154 CHECK (public.st_ndims(the_geom_2154) = 2);
ALTER TABLE partenaires_experts.rencontres ADD CONSTRAINT enforce_dims_the_geom_3857 CHECK (public.st_ndims(the_geom_3857) = 2);
ALTER TABLE partenaires_experts.rencontres ADD CONSTRAINT enforce_dims_the_geom_point CHECK (public.st_ndims(the_geom_point) = 2);
ALTER TABLE partenaires_experts.rencontres ADD CONSTRAINT enforce_geotype_the_geom_point CHECK (public.st_geometrytype(the_geom_point) = 'ST_Point'::text OR the_geom_point IS NULL);
ALTER TABLE partenaires_experts.rencontres ADD CONSTRAINT enforce_srid_the_geom_2154 CHECK (public.st_srid(the_geom_2154) = 2154);
ALTER TABLE partenaires_experts.rencontres ADD CONSTRAINT enforce_srid_the_geom_3857 CHECK (public.st_srid(the_geom_3857) = 3857);
ALTER TABLE partenaires_experts.rencontres ADD CONSTRAINT enforce_srid_the_geom_point CHECK (public.st_srid(the_geom_point) = 3857);
ALTER TABLE partenaires_experts.rencontres ADD CONSTRAINT rencontres_cle_check CHECK (cle < 5);
CREATE TRIGGER tri_insert_rencontres
  BEFORE INSERT
  ON partenaires_experts.rencontres
  FOR EACH ROW
  EXECUTE PROCEDURE insert_maj_date();
CREATE TRIGGER tri_update_rencontres
  BEFORE UPDATE
  ON partenaires_experts.rencontres
  FOR EACH ROW
  EXECUTE PROCEDURE update_maj_date();

ALTER TABLE partenaires_experts.atbi ADD CONSTRAINT atbi_id_lot_fkey FOREIGN KEY (id_lot)
    REFERENCES gn_meta.t_datasets (id_dataset) MATCH SIMPLE ON UPDATE CASCADE ON DELETE NO ACTION;
ALTER TABLE partenaires_experts.atbi ADD CONSTRAINT atbi_id_protocole_fkey FOREIGN KEY (id_protocole)
    REFERENCES gn_meta.sinp_datatype_protocols (id_protocol) MATCH SIMPLE ON UPDATE CASCADE ON DELETE NO ACTION;
ALTER TABLE partenaires_experts.atbi ADD CONSTRAINT atbi_id_source_fkey FOREIGN KEY (id_source)
    REFERENCES gn_synthese.t_sources (id_source) MATCH SIMPLE ON UPDATE CASCADE ON DELETE NO ACTION;
ALTER TABLE partenaires_experts.atbi ADD CONSTRAINT fk_atbi_bib_organismes FOREIGN KEY (id_organisme)
    REFERENCES utilisateurs.bib_organismes (id_organisme) MATCH SIMPLE ON UPDATE CASCADE ON DELETE NO ACTION;
ALTER TABLE partenaires_experts.atbi ADD CONSTRAINT atbi_id_critere_synthese_fkey FOREIGN KEY (id_critere_synthese)
    REFERENCES hist_archives.bib_criteres_synthese_gn1 (id_critere_synthese) MATCH SIMPLE ON UPDATE CASCADE ON DELETE NO ACTION;
ALTER TABLE partenaires_experts.atbi ADD CONSTRAINT enforce_dims_the_geom_2154 CHECK (public.st_ndims(the_geom_2154) = 2);
ALTER TABLE partenaires_experts.atbi ADD CONSTRAINT enforce_dims_the_geom_3857 CHECK (public.st_ndims(the_geom_3857) = 2);
ALTER TABLE partenaires_experts.atbi ADD CONSTRAINT enforce_dims_the_geom_point CHECK (public.st_ndims(the_geom_point) = 2);
ALTER TABLE partenaires_experts.atbi ADD CONSTRAINT enforce_geotype_the_geom_point CHECK (public.st_geometrytype(the_geom_point) = 'ST_Point'::text OR the_geom_point IS NULL);
ALTER TABLE partenaires_experts.atbi ADD CONSTRAINT enforce_srid_the_geom_2154 CHECK (public.st_srid(the_geom_2154) = 2154);
ALTER TABLE partenaires_experts.atbi ADD CONSTRAINT enforce_srid_the_geom_3857 CHECK (public.st_srid(the_geom_3857) = 3857);
ALTER TABLE partenaires_experts.atbi ADD CONSTRAINT enforce_srid_the_geom_point CHECK (public.st_srid(the_geom_point) = 3857);
ALTER TABLE partenaires_experts.atbi ADD CONSTRAINT atbi_cle_check CHECK (cle < 5);
CREATE TRIGGER tri_insert_atbi
  BEFORE INSERT
  ON partenaires_experts.atbi
  FOR EACH ROW
  EXECUTE PROCEDURE insert_maj_date();
CREATE TRIGGER tri_update_atbi
  BEFORE UPDATE
  ON partenaires_experts.atbi
  FOR EACH ROW
  EXECUTE PROCEDURE update_maj_date();

ALTER TABLE partenaires_experts.abc ADD CONSTRAINT abc_id_lot_fkey FOREIGN KEY (id_lot)
    REFERENCES gn_meta.t_datasets (id_dataset) MATCH SIMPLE ON UPDATE CASCADE ON DELETE NO ACTION;
ALTER TABLE partenaires_experts.abc ADD CONSTRAINT abc_id_protocole_fkey FOREIGN KEY (id_protocole)
    REFERENCES gn_meta.sinp_datatype_protocols (id_protocol) MATCH SIMPLE ON UPDATE CASCADE ON DELETE NO ACTION;
ALTER TABLE partenaires_experts.abc ADD CONSTRAINT abc_id_source_fkey FOREIGN KEY (id_source)
    REFERENCES gn_synthese.t_sources (id_source) MATCH SIMPLE ON UPDATE CASCADE ON DELETE NO ACTION;
ALTER TABLE partenaires_experts.abc ADD CONSTRAINT fk_abc_bib_organismes FOREIGN KEY (id_organisme)
    REFERENCES utilisateurs.bib_organismes (id_organisme) MATCH SIMPLE ON UPDATE CASCADE ON DELETE NO ACTION;
ALTER TABLE partenaires_experts.abc ADD CONSTRAINT abc_id_critere_synthese_fkey FOREIGN KEY (id_critere_synthese)
    REFERENCES hist_archives.bib_criteres_synthese_gn1 (id_critere_synthese) MATCH SIMPLE ON UPDATE CASCADE ON DELETE NO ACTION;
ALTER TABLE partenaires_experts.abc ADD CONSTRAINT enforce_dims_the_geom_2154 CHECK (public.st_ndims(the_geom_2154) = 2);
ALTER TABLE partenaires_experts.abc ADD CONSTRAINT enforce_dims_the_geom_3857 CHECK (public.st_ndims(the_geom_3857) = 2);
ALTER TABLE partenaires_experts.abc ADD CONSTRAINT enforce_dims_the_geom_point CHECK (public.st_ndims(the_geom_point) = 2);
ALTER TABLE partenaires_experts.abc ADD CONSTRAINT enforce_geotype_the_geom_point CHECK (public.st_geometrytype(the_geom_point) = 'ST_Point'::text OR the_geom_point IS NULL);
ALTER TABLE partenaires_experts.abc ADD CONSTRAINT enforce_srid_the_geom_2154 CHECK (public.st_srid(the_geom_2154) = 2154);
ALTER TABLE partenaires_experts.abc ADD CONSTRAINT enforce_srid_the_geom_3857 CHECK (public.st_srid(the_geom_3857) = 3857);
ALTER TABLE partenaires_experts.abc ADD CONSTRAINT enforce_srid_the_geom_point CHECK (public.st_srid(the_geom_point) = 3857);
ALTER TABLE partenaires_experts.abc ADD CONSTRAINT abc_cle_check CHECK (cle < 5);
CREATE TRIGGER tri_insert_abc
  BEFORE INSERT
  ON partenaires_experts.abc
  FOR EACH ROW
  EXECUTE PROCEDURE insert_maj_date();
CREATE TRIGGER tri_update_abc
  BEFORE UPDATE
  ON partenaires_experts.abc
  FOR EACH ROW
  EXECUTE PROCEDURE update_maj_date();

---------------
--EMBRUN 2016--
---------------
IMPORT FOREIGN SCHEMA partenaires LIMIT TO(embrun_2016) FROM SERVER geonature1server INTO v1_compat;
CREATE SCHEMA hist_embrun2016;
CREATE TABLE hist_embrun2016.embrun_2016 AS
SELECT * FROM v1_compat.embrun_2016;
ALTER TABLE hist_embrun2016.embrun_2016 ADD CONSTRAINT pk_embrun_2016 PRIMARY KEY(gid);

------------
--STOC-EPS--
------------
IMPORT FOREIGN SCHEMA stoceps FROM SERVER geonature1server INTO v1_compat;
CREATE SCHEMA hist_stoceps;
CREATE TABLE hist_stoceps.t_points_ecoute AS
SELECT * FROM v1_compat.t_points_ecoute;
CREATE TABLE hist_stoceps.t_releves_stoc AS
SELECT * FROM v1_compat.t_releves_stoc;
ALTER TABLE hist_stoceps.t_points_ecoute ADD CONSTRAINT pk_t_points_ecoute PRIMARY KEY(id_point_ecoute);
ALTER TABLE hist_stoceps.t_releves_stoc ADD CONSTRAINT pk_t_releves_stoc PRIMARY KEY(id_releve_stoc);
ALTER TABLE hist_stoceps.t_releves_stoc ADD CONSTRAINT fk_t_releves_t_points_ecoute FOREIGN KEY (id_point_ecoute)
    REFERENCES hist_stoceps.t_points_ecoute (id_point_ecoute) MATCH SIMPLE ON UPDATE CASCADE ON DELETE NO ACTION;
ALTER TABLE hist_stoceps.t_points_ecoute ADD CONSTRAINT enforce_dims_the_geom_27572 CHECK (st_ndims(the_geom_27572) = 2);
ALTER TABLE hist_stoceps.t_points_ecoute ADD CONSTRAINT enforce_geotype_the_geom_27572 CHECK (st_geometrytype(the_geom_27572) = 'ST_Point'::text OR the_geom_27572 IS NULL);
ALTER TABLE hist_stoceps.t_points_ecoute ADD CONSTRAINT enforce_srid_the_geom_27572 CHECK (st_srid(the_geom_27572) = 27572);
CREATE SEQUENCE hist_stoceps.t_releves_stoc_id_releve_stoc_seq
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 128336
  CACHE 1;


