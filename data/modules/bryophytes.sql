--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- TOC entry 11 (class 2615 OID 2747598)
-- Name: bryophytes; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA bryophytes;


SET search_path = bryophytes, pg_catalog;

--
-- TOC entry 1460 (class 1255 OID 2747629)
-- Name: bryophytes_insert(); Type: FUNCTION; Schema: bryophytes; Owner: -
--

CREATE FUNCTION bryophytes_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$

BEGIN

new.date_insert= 'now';	 -- mise a jour de date insert
new.the_geom_local = public.st_transform(new.the_geom_3857,MYLOCALSRID);
new.insee = layers.f_insee(new.the_geom_local);-- mise a jour du code insee
new.altitude_sig = layers.f_isolines20(new.the_geom_local); -- mise à jour de l'altitude sig


IF new.altitude_saisie is null or new.altitude_saisie = 0 then -- mis à jour de l'altitude retenue
  new.altitude_retenue = new.altitude_sig;
ELSE
  new.altitude_retenue = new.altitude_saisie;
END IF;

RETURN new; -- return new procède à l'insertion de la donnée dans PG avec les nouvelles valeures.			

END;
$$;


--
-- TOC entry 1472 (class 1255 OID 2747630)
-- Name: bryophytes_update(); Type: FUNCTION; Schema: bryophytes; Owner: -
--

CREATE FUNCTION bryophytes_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
IF (NOT public.st_equals(new.the_geom_local,old.the_geom_local) OR (old.the_geom_local is null AND new.the_geom_local is NOT NULL))
  OR (NOT public.st_equals(new.the_geom_3857,old.the_geom_3857) OR (old.the_geom_3857 is null AND new.the_geom_3857 is NOT NULL)) 
   THEN

	IF NOT public.st_equals(new.the_geom_3857,old.the_geom_3857) OR (old.the_geom_3857 is null AND new.the_geom_3857 is NOT NULL) THEN
		new.the_geom_local = public.st_transform(new.the_geom_3857,MYLOCALSRID);
		new.srid_dessin = 3857;
	ELSIF NOT public.st_equals(new.the_geom_local,old.the_geom_local) OR (old.the_geom_local is null AND new.the_geom_local is NOT NULL) THEN
		new.the_geom_3857 = public.st_transform(new.the_geom_local,3857);
		new.srid_dessin = MYLOCALSRID;
	END IF;

        new.insee = layers.f_insee(new.the_geom_local);-- mise à jour du code insee
        new.altitude_sig = layers.f_isolines20(new.the_geom_local); --mise à jour de l'altitude_sig

END IF;

IF (new.altitude_saisie <> old.altitude_saisie OR old.altitude_saisie is null OR new.altitude_saisie is null OR old.altitude_saisie=0 OR new.altitude_saisie=0) then  -- mis à jour de l'altitude retenue
	BEGIN
		if new.altitude_saisie is null or new.altitude_saisie = 0 then
			new.altitude_retenue = layers.f_isolines20(new.the_geom_local);
		else
			new.altitude_retenue = new.altitude_saisie;
		end if;
	END;	
END IF;

new.date_update= 'now';	 -- mise a jour de date insert

RETURN new; -- return new procède à l'insertion de la donnée dans PG avec les nouvelles valeures.			
END;
$$;


--
-- TOC entry 1500 (class 1255 OID 2747631)
-- Name: delete_synthese_cor_bryo_taxon(); Type: FUNCTION; Schema: bryophytes; Owner: -
--

CREATE FUNCTION delete_synthese_cor_bryo_taxon() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
--il n'y a pas de trigger delete sur la table t_stations_fs parce qu'il un delete cascade dans la fk id_station de cor_fs_taxon
--donc si on supprime la station, on supprime sa ou ces taxons relevés et donc ce trigger sera déclanché et fera le ménage dans la table syntheseff

BEGIN
        --on fait le delete dans syntheseff
        DELETE FROM synthese.syntheseff WHERE id_source = 6 AND id_fiche_source = CAST(old.gid AS VARCHAR(25));
	RETURN old; 			
END;
$$;


--
-- TOC entry 1505 (class 1255 OID 2747632)
-- Name: insert_synthese_cor_bryo_taxon(); Type: FUNCTION; Schema: bryophytes; Owner: -
--

CREATE FUNCTION insert_synthese_cor_bryo_taxon() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    fiche RECORD;
    mesobservateurs character varying(255);
BEGIN
    SELECT INTO fiche * FROM bryophytes.t_stations_bryo WHERE id_station = new.id_station;
    --Récupération des données dans la table t_zprospection et de la liste des observateurs	
    SELECT INTO mesobservateurs array_to_string(array_agg(r.nom_role || ' ' || r.prenom_role), ', ') AS observateurs 
    FROM bryophytes.cor_bryo_observateur c
    JOIN utilisateurs.t_roles r ON r.id_role = c.id_role
    JOIN bryophytes.t_stations_bryo s ON s.id_station = c.id_station
    WHERE c.id_station = new.id_station;
    
    -- MAJ de la table cor_unite_taxon, on commence par récupérer les zonnes à statuts à partir du pointage (table t_fiches_cf)
    INSERT INTO synthese.syntheseff
    (
      id_source,
      id_fiche_source,
      code_fiche_source,
      id_organisme,
      id_protocole,
      id_precision,
      cd_nom,
      insee,
      dateobs,
      observateurs,
      altitude_retenue,
      remarques,
      derniere_action,
      supprime,
      id_lot,
      the_geom_3857,
      the_geom_local,
      the_geom_point
    )
    VALUES
    ( 
      6, 
      new.gid,
      'st' || new.id_station || '-' || 'cdnom' || new.cd_nom,
      fiche.id_organisme,
	  fiche.id_protocole,
      1,
      new.cd_nom,
      fiche.insee,
      fiche.dateobs,
      mesobservateurs,
      fiche.altitude_retenue,
      fiche.remarques,
      'c',
      new.supprime,
      fiche.id_lot,
      fiche.the_geom_3857,
      fiche.the_geom_local,
      fiche.the_geom_3857
    );
	
RETURN NEW; 			
END;
$$;


--
-- TOC entry 1473 (class 1255 OID 2747633)
-- Name: update_synthese_cor_bryo_observateur(); Type: FUNCTION; Schema: bryophytes; Owner: -
--

CREATE FUNCTION update_synthese_cor_bryo_observateur() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE 
    monreleve RECORD;
    mesobservateurs character varying(255);
BEGIN
    --Récupération de la liste des observateurs	
    --ici on va mettre à jour l'enregistrement dans syntheseff autant de fois qu'on insert dans cette table
	SELECT INTO mesobservateurs array_to_string(array_agg(r.nom_role || ' ' || r.prenom_role), ', ') AS observateurs 
    FROM bryophytes.cor_bryo_observateur c
    JOIN utilisateurs.t_roles r ON r.id_role = c.id_role
    JOIN bryophytes.t_stations_bryo s ON s.id_station = c.id_station
    WHERE c.id_station = new.id_station;
    --on boucle sur tous les enregistrements de la station
    FOR monreleve IN SELECT gid FROM bryophytes.cor_bryo_taxon WHERE id_station = new.id_station  LOOP
        --on fait le update du champ observateurs dans syntheseff
        UPDATE synthese.syntheseff 
        SET 
            observateurs = mesobservateurs,
            derniere_action = 'u'
        WHERE id_source = 6 AND id_fiche_source = CAST(monreleve.gid AS VARCHAR(25));
    END LOOP;
	RETURN NEW; 			
END;
$$;


--
-- TOC entry 1474 (class 1255 OID 2747634)
-- Name: update_synthese_cor_bryo_taxon(); Type: FUNCTION; Schema: bryophytes; Owner: -
--

CREATE FUNCTION update_synthese_cor_bryo_taxon() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
--On ne fait qq chose que si l'un des champs de la table cor_bryo_taxon concerné dans syntheseff a changé
IF (
        new.id_station <> old.id_station 
        OR new.gid <> old.gid 
        OR new.cd_nom <> old.cd_nom 
        OR new.supprime <> old.supprime 
    ) THEN
    --on fait le update dans syntheseff
    UPDATE synthese.syntheseff 
    SET 
	id_fiche_source = new.gid,
	code_fiche_source = 'st' || new.id_station || '-' || 'cdnom' || new.cd_nom,
	cd_nom = new.cd_nom,
	derniere_action = 'u',
	supprime = new.supprime
    WHERE id_source = 6 AND id_fiche_source = CAST(old.gid AS VARCHAR(25));
END IF;

RETURN NEW; 			
END;
$$;


--
-- TOC entry 1507 (class 1255 OID 2747635)
-- Name: update_synthese_stations_bryo(); Type: FUNCTION; Schema: bryophytes; Owner: -
--

CREATE FUNCTION update_synthese_stations_bryo() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE 
    monreleve RECORD;
BEGIN
FOR monreleve IN SELECT gid, cd_nom FROM bryophytes.cor_bryo_taxon WHERE id_station = new.id_station  LOOP
    --On ne fait qq chose que si l'un des champs de la table t_station_bryo concerné dans syntheseff a changé
    IF (
            new.id_station <> old.id_station 
            OR ((new.remarques <> old.remarques) OR (new.remarques is null and old.remarques is NOT NULL) OR (new.remarques is NOT NULL and old.remarques is null))
            OR ((new.insee <> old.insee) OR (new.insee is null and old.insee is NOT NULL) OR (new.insee is NOT NULL and old.insee is null))
            OR ((new.dateobs <> old.dateobs) OR (new.dateobs is null and old.dateobs is NOT NULL) OR (new.dateobs is NOT NULL and old.dateobs is null))
            OR ((new.altitude_retenue <> old.altitude_retenue) OR (new.altitude_retenue is null and old.altitude_retenue is NOT NULL) OR (new.altitude_retenue is NOT NULL and old.altitude_retenue is null))
        ) THEN
        --on fait le update dans syntheseff
        UPDATE synthese.syntheseff 
        SET 
            code_fiche_source = 'st' || new.id_station || '-' || 'cdnom' || monreleve.cd_nom,
            insee = new.insee,
            dateobs = new.dateobs,
            altitude_retenue = new.altitude_retenue,
            remarques = new.remarques,
            derniere_action = 'u',
            the_geom_3857 = new.the_geom_3857,
            the_geom_local = new.the_geom_local,
            the_geom_point = new.the_geom_3857
        WHERE id_source = 6 AND id_fiche_source = CAST(monreleve.gid AS VARCHAR(25));
    END IF;
END LOOP;
	RETURN NEW; 
END;
$$;


SET default_with_oids = false;

--
-- TOC entry 257 (class 1259 OID 2747723)
-- Name: bib_abondances; Type: TABLE; Schema: bryophytes; Owner: -
--

CREATE TABLE bib_abondances (
    id_abondance character(1) NOT NULL,
    nom_abondance character varying(128) NOT NULL
);


--
-- TOC entry 258 (class 1259 OID 2747726)
-- Name: bib_expositions; Type: TABLE; Schema: bryophytes; Owner: -
--

CREATE TABLE bib_expositions (
    id_exposition character(2) NOT NULL,
    nom_exposition character varying(10) NOT NULL,
    tri_exposition integer
);


--
-- TOC entry 259 (class 1259 OID 2747729)
-- Name: cor_bryo_observateur; Type: TABLE; Schema: bryophytes; Owner: -
--

CREATE TABLE cor_bryo_observateur (
    id_role integer NOT NULL,
    id_station bigint NOT NULL
);


--
-- TOC entry 260 (class 1259 OID 2747732)
-- Name: cor_bryo_taxon_gid_seq; Type: SEQUENCE; Schema: bryophytes; Owner: -
--

CREATE SEQUENCE cor_bryo_taxon_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 261 (class 1259 OID 2747734)
-- Name: cor_bryo_taxon; Type: TABLE; Schema: bryophytes; Owner: -
--

CREATE TABLE cor_bryo_taxon (
    id_station bigint NOT NULL,
    cd_nom integer NOT NULL,
    id_abondance character(1),
    taxon_saisi character varying(255),
    supprime boolean DEFAULT false,
    diffusable boolean DEFAULT true,
    id_station_cd_nom integer NOT NULL,
    gid integer DEFAULT nextval('cor_bryo_taxon_gid_seq'::regclass) NOT NULL
);


--
-- TOC entry 262 (class 1259 OID 2747739)
-- Name: cor_bryo_taxon_id_station_cd_nom_seq; Type: SEQUENCE; Schema: bryophytes; Owner: -
--

CREATE SEQUENCE cor_bryo_taxon_id_station_cd_nom_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 3931 (class 0 OID 0)
-- Dependencies: 262
-- Name: cor_bryo_taxon_id_station_cd_nom_seq; Type: SEQUENCE OWNED BY; Schema: bryophytes; Owner: -
--

ALTER SEQUENCE cor_bryo_taxon_id_station_cd_nom_seq OWNED BY cor_bryo_taxon.id_station_cd_nom;


--
-- TOC entry 263 (class 1259 OID 2747741)
-- Name: t_stations_bryo; Type: TABLE; Schema: bryophytes; Owner: -
--

CREATE TABLE t_stations_bryo (
    id_station bigint NOT NULL,
    id_exposition character(2) NOT NULL,
    id_support integer NOT NULL,
    id_protocole integer NOT NULL,
    id_lot integer NOT NULL,
    id_organisme integer NOT NULL,
    dateobs date,
    info_acces character varying(1000),
    surface integer DEFAULT 1,
    complet_partiel character(1),
    altitude_saisie integer DEFAULT 0,
    altitude_sig integer DEFAULT 0,
    altitude_retenue integer DEFAULT 0,
    remarques text,
    pdop real DEFAULT 0,
    supprime boolean DEFAULT false,
    date_insert timestamp without time zone,
    date_update timestamp without time zone,
    insee character(5),
    gid integer NOT NULL,
    the_geom_local public.geometry(Point,MYLOCALSRID),
    srid_dessin integer,
    the_geom_3857 public.geometry(Point,3857),
    CONSTRAINT enforce_dims_the_geom_local CHECK ((public.st_ndims(the_geom_local) = 2)),
    CONSTRAINT enforce_dims_the_geom_3857 CHECK ((public.st_ndims(the_geom_3857) = 2)),
    CONSTRAINT enforce_geotype_the_geom_local CHECK (((public.geometrytype(the_geom_local) = 'POINT'::text) OR (the_geom_local IS NULL))),
    CONSTRAINT enforce_geotype_the_geom_3857 CHECK (((public.geometrytype(the_geom_3857) = 'POINT'::text) OR (the_geom_3857 IS NULL))),
    CONSTRAINT enforce_srid_the_geom_local CHECK ((public.st_srid(the_geom_local) = MYLOCALSRID)),
    CONSTRAINT enforce_srid_the_geom_3857 CHECK ((public.st_srid(the_geom_3857) = 3857))
);


--
-- TOC entry 264 (class 1259 OID 2747759)
-- Name: t_stations_bryo_gid_seq; Type: SEQUENCE; Schema: bryophytes; Owner: -
--

CREATE SEQUENCE t_stations_bryo_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 3932 (class 0 OID 0)
-- Dependencies: 264
-- Name: t_stations_bryo_gid_seq; Type: SEQUENCE OWNED BY; Schema: bryophytes; Owner: -
--

ALTER SEQUENCE t_stations_bryo_gid_seq OWNED BY t_stations_bryo.gid;


--
-- TOC entry 3717 (class 2604 OID 2748294)
-- Name: id_station_cd_nom; Type: DEFAULT; Schema: bryophytes; Owner: -
--

ALTER TABLE ONLY cor_bryo_taxon ALTER COLUMN id_station_cd_nom SET DEFAULT nextval('cor_bryo_taxon_id_station_cd_nom_seq'::regclass);


--
-- TOC entry 3724 (class 2604 OID 2748295)
-- Name: gid; Type: DEFAULT; Schema: bryophytes; Owner: -
--

ALTER TABLE ONLY t_stations_bryo ALTER COLUMN gid SET DEFAULT nextval('t_stations_bryo_gid_seq'::regclass);


--
-- TOC entry 3732 (class 2606 OID 2748341)
-- Name: pk_bib_abondances; Type: CONSTRAINT; Schema: bryophytes; Owner: -
--

ALTER TABLE ONLY bib_abondances
    ADD CONSTRAINT pk_bib_abondances PRIMARY KEY (id_abondance);


--
-- TOC entry 3734 (class 2606 OID 2748343)
-- Name: pk_bib_expositions; Type: CONSTRAINT; Schema: bryophytes; Owner: -
--

ALTER TABLE ONLY bib_expositions
    ADD CONSTRAINT pk_bib_expositions PRIMARY KEY (id_exposition);


--
-- TOC entry 3736 (class 2606 OID 2748345)
-- Name: pk_cor_bryo_observateur; Type: CONSTRAINT; Schema: bryophytes; Owner: -
--

ALTER TABLE ONLY cor_bryo_observateur
    ADD CONSTRAINT pk_cor_bryo_observateur PRIMARY KEY (id_role, id_station);


--
-- TOC entry 3739 (class 2606 OID 2748347)
-- Name: pk_cor_bryo_taxons; Type: CONSTRAINT; Schema: bryophytes; Owner: -
--

ALTER TABLE ONLY cor_bryo_taxon
    ADD CONSTRAINT pk_cor_bryo_taxons PRIMARY KEY (id_station, cd_nom);


--
-- TOC entry 3744 (class 2606 OID 2748349)
-- Name: pk_t_stations_bryo; Type: CONSTRAINT; Schema: bryophytes; Owner: -
--

ALTER TABLE ONLY t_stations_bryo
    ADD CONSTRAINT pk_t_stations_bryo PRIMARY KEY (id_station);


--
-- TOC entry 3746 (class 2606 OID 2748351)
-- Name: t_stations_bryo_gid_key; Type: CONSTRAINT; Schema: bryophytes; Owner: -
--

ALTER TABLE ONLY t_stations_bryo
    ADD CONSTRAINT t_stations_bryo_gid_key UNIQUE (gid);


--
-- TOC entry 3740 (class 1259 OID 2748473)
-- Name: fki_t_stations_bryo_gid; Type: INDEX; Schema: bryophytes; Owner: -
--

CREATE INDEX fki_t_stations_bryo_gid ON t_stations_bryo USING btree (gid);


--
-- TOC entry 3933 (class 0 OID 0)
-- Dependencies: 3740
-- Name: INDEX fki_t_stations_bryo_gid; Type: COMMENT; Schema: bryophytes; Owner: -
--

COMMENT ON INDEX fki_t_stations_bryo_gid IS 'pour le fonctionnement de qgis';


--
-- TOC entry 3741 (class 1259 OID 2748474)
-- Name: i_fk_t_stations_bryo_bib_exposit; Type: INDEX; Schema: bryophytes; Owner: -
--

CREATE INDEX i_fk_t_stations_bryo_bib_exposit ON t_stations_bryo USING btree (id_exposition);


--
-- TOC entry 3742 (class 1259 OID 2748475)
-- Name: i_fk_t_stations_bryo_bib_support; Type: INDEX; Schema: bryophytes; Owner: -
--

CREATE INDEX i_fk_t_stations_bryo_bib_support ON t_stations_bryo USING btree (id_support);


--
-- TOC entry 3737 (class 1259 OID 2748476)
-- Name: index_cd_nom; Type: INDEX; Schema: bryophytes; Owner: -
--

CREATE INDEX index_cd_nom ON cor_bryo_taxon USING btree (cd_nom);


--
-- Name: index_gist_t_stations_bryo_the_geom_local; Type: INDEX; Schema: bryophytes; Owner: -; Tablespace: 
--

CREATE INDEX index_gist_t_stations_bryo_the_geom_local ON t_stations_bryo USING gist (the_geom_local);


--
-- Name: index_gist_t_stations_bryo_the_geom_3857; Type: INDEX; Schema: bryophytes; Owner: -; Tablespace: 
--

CREATE INDEX index_gist_t_stations_bryo_the_geom_3857 ON t_stations_bryo USING gist (the_geom_3857);


--
-- TOC entry 3758 (class 2620 OID 2748518)
-- Name: tri_delete_synthese_cor_bryo_taxon; Type: TRIGGER; Schema: bryophytes; Owner: -
--

CREATE TRIGGER tri_delete_synthese_cor_bryo_taxon AFTER DELETE ON cor_bryo_taxon FOR EACH ROW EXECUTE PROCEDURE delete_synthese_cor_bryo_taxon();


--
-- TOC entry 3761 (class 2620 OID 2748519)
-- Name: tri_insert; Type: TRIGGER; Schema: bryophytes; Owner: -
--

CREATE TRIGGER tri_insert BEFORE INSERT ON t_stations_bryo FOR EACH ROW EXECUTE PROCEDURE bryophytes_insert();


--
-- TOC entry 3757 (class 2620 OID 2748520)
-- Name: tri_insert_synthese_cor_bryo_observateur; Type: TRIGGER; Schema: bryophytes; Owner: -
--

CREATE TRIGGER tri_insert_synthese_cor_bryo_observateur AFTER INSERT ON cor_bryo_observateur FOR EACH ROW EXECUTE PROCEDURE update_synthese_cor_bryo_observateur();


--
-- TOC entry 3759 (class 2620 OID 2748521)
-- Name: tri_insert_synthese_cor_bryo_taxon; Type: TRIGGER; Schema: bryophytes; Owner: -
--

CREATE TRIGGER tri_insert_synthese_cor_bryo_taxon AFTER INSERT ON cor_bryo_taxon FOR EACH ROW EXECUTE PROCEDURE insert_synthese_cor_bryo_taxon();


--
-- TOC entry 3762 (class 2620 OID 2748522)
-- Name: tri_update; Type: TRIGGER; Schema: bryophytes; Owner: -
--

CREATE TRIGGER tri_update BEFORE UPDATE ON t_stations_bryo FOR EACH ROW EXECUTE PROCEDURE bryophytes_update();


--
-- TOC entry 3760 (class 2620 OID 2748523)
-- Name: tri_update_synthese_cor_bryo_taxon; Type: TRIGGER; Schema: bryophytes; Owner: -
--

CREATE TRIGGER tri_update_synthese_cor_bryo_taxon AFTER UPDATE ON cor_bryo_taxon FOR EACH ROW EXECUTE PROCEDURE update_synthese_cor_bryo_taxon();


--
-- TOC entry 3763 (class 2620 OID 2748524)
-- Name: tri_update_synthese_stations_bryo; Type: TRIGGER; Schema: bryophytes; Owner: -
--

CREATE TRIGGER tri_update_synthese_stations_bryo AFTER UPDATE ON t_stations_bryo FOR EACH ROW EXECUTE PROCEDURE update_synthese_stations_bryo();


--
-- TOC entry 3747 (class 2606 OID 2748681)
-- Name: cor_bryo_observateur_id_station_fkey; Type: FK CONSTRAINT; Schema: bryophytes; Owner: -
--

ALTER TABLE ONLY cor_bryo_observateur
    ADD CONSTRAINT cor_bryo_observateur_id_station_fkey FOREIGN KEY (id_station) REFERENCES t_stations_bryo(id_station) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 3749 (class 2606 OID 2748686)
-- Name: cor_bryo_taxons_cd_nom_fkey; Type: FK CONSTRAINT; Schema: bryophytes; Owner: -
--

ALTER TABLE ONLY cor_bryo_taxon
    ADD CONSTRAINT cor_bryo_taxons_cd_nom_fkey FOREIGN KEY (cd_nom) REFERENCES taxonomie.taxref(cd_nom) ON UPDATE CASCADE;


--
-- TOC entry 3750 (class 2606 OID 2748691)
-- Name: cor_bryo_taxons_id_abondance_fkey; Type: FK CONSTRAINT; Schema: bryophytes; Owner: -
--

ALTER TABLE ONLY cor_bryo_taxon
    ADD CONSTRAINT cor_bryo_taxons_id_abondance_fkey FOREIGN KEY (id_abondance) REFERENCES bib_abondances(id_abondance) ON UPDATE CASCADE;


--
-- TOC entry 3751 (class 2606 OID 2748696)
-- Name: cor_bryo_taxons_id_station_fkey; Type: FK CONSTRAINT; Schema: bryophytes; Owner: -
--

ALTER TABLE ONLY cor_bryo_taxon
    ADD CONSTRAINT cor_bryo_taxons_id_station_fkey FOREIGN KEY (id_station) REFERENCES t_stations_bryo(id_station) ON UPDATE CASCADE;


--
-- TOC entry 3748 (class 2606 OID 2748701)
-- Name: fk_cor_bryo_observateur_t_roles; Type: FK CONSTRAINT; Schema: bryophytes; Owner: -
--

ALTER TABLE ONLY cor_bryo_observateur
    ADD CONSTRAINT fk_cor_bryo_observateur_t_roles FOREIGN KEY (id_role) REFERENCES utilisateurs.t_roles(id_role) ON UPDATE CASCADE;


--
-- TOC entry 3752 (class 2606 OID 2748706)
-- Name: fk_t_stations_bryo_bib_expositions; Type: FK CONSTRAINT; Schema: bryophytes; Owner: -
--

ALTER TABLE ONLY t_stations_bryo
    ADD CONSTRAINT fk_t_stations_bryo_bib_expositions FOREIGN KEY (id_exposition) REFERENCES bib_expositions(id_exposition) ON UPDATE CASCADE;


--
-- TOC entry 3754 (class 2606 OID 2748716)
-- Name: fk_t_stations_bryo_bib_lots; Type: FK CONSTRAINT; Schema: bryophytes; Owner: -
--

ALTER TABLE ONLY t_stations_bryo
    ADD CONSTRAINT fk_t_stations_bryo_bib_lots FOREIGN KEY (id_lot) REFERENCES meta.bib_lots(id_lot) ON UPDATE CASCADE;


--
-- TOC entry 3755 (class 2606 OID 2748721)
-- Name: fk_t_stations_bryo_bib_organismes; Type: FK CONSTRAINT; Schema: bryophytes; Owner: -
--

ALTER TABLE ONLY t_stations_bryo
    ADD CONSTRAINT fk_t_stations_bryo_bib_organismes FOREIGN KEY (id_organisme) REFERENCES utilisateurs.bib_organismes(id_organisme) ON UPDATE CASCADE;


--
-- TOC entry 3756 (class 2606 OID 2748726)
-- Name: fk_t_stations_bryo_bib_supports; Type: FK CONSTRAINT; Schema: bryophytes; Owner: -
--

ALTER TABLE ONLY t_stations_bryo
    ADD CONSTRAINT fk_t_stations_bryo_bib_supports FOREIGN KEY (id_support) REFERENCES meta.bib_supports(id_support) ON UPDATE CASCADE;


--
-- TOC entry 3753 (class 2606 OID 2748711)
-- Name: fk_t_stations_bryo_t_protocoles; Type: FK CONSTRAINT; Schema: bryophytes; Owner: -
--

ALTER TABLE ONLY t_stations_bryo
    ADD CONSTRAINT fk_t_stations_bryo_t_protocoles FOREIGN KEY (id_protocole) REFERENCES meta.t_protocoles(id_protocole) ON UPDATE CASCADE;


--------------------------------------------------------------------------------------
--------------------INSERTION DES DONNEES DES TABLES DICTIONNAIRES--------------------
--------------------------------------------------------------------------------------

SET search_path = bryophytes, pg_catalog;

INSERT INTO bib_abondances (id_abondance, nom_abondance) VALUES ('+', 'Moins de 1 %');
INSERT INTO bib_abondances (id_abondance, nom_abondance) VALUES ('1', 'Moins de 5 %');
INSERT INTO bib_abondances (id_abondance, nom_abondance) VALUES ('2', 'De 5 à 25 %');
INSERT INTO bib_abondances (id_abondance, nom_abondance) VALUES ('3', 'De 25 à 50 %');
INSERT INTO bib_abondances (id_abondance, nom_abondance) VALUES ('4', 'De 50 à 75 %');
INSERT INTO bib_abondances (id_abondance, nom_abondance) VALUES ('5', 'Plus de 75 %');
INSERT INTO bib_abondances (id_abondance, nom_abondance) VALUES ('9', 'Aucune');

INSERT INTO bib_expositions (id_exposition, nom_exposition, tri_exposition) VALUES ('N ', 'Nord', 1);
INSERT INTO bib_expositions (id_exposition, nom_exposition, tri_exposition) VALUES ('NE', 'Nord Est', 2);
INSERT INTO bib_expositions (id_exposition, nom_exposition, tri_exposition) VALUES ('E ', 'Est', 3);
INSERT INTO bib_expositions (id_exposition, nom_exposition, tri_exposition) VALUES ('SE', 'Sud Est', 4);
INSERT INTO bib_expositions (id_exposition, nom_exposition, tri_exposition) VALUES ('S ', 'Sud', 5);
INSERT INTO bib_expositions (id_exposition, nom_exposition, tri_exposition) VALUES ('SO', 'Sud Ouest', 6);
INSERT INTO bib_expositions (id_exposition, nom_exposition, tri_exposition) VALUES ('O ', 'Ouest', 7);
INSERT INTO bib_expositions (id_exposition, nom_exposition, tri_exposition) VALUES ('NO', 'Nord Ouest', 8);
INSERT INTO bib_expositions (id_exposition, nom_exposition, tri_exposition) VALUES ('I ', 'Indéfinie', 9);


--------------------------------------------------------------------------------------
--------------------AJOUT DU MODULE DANS LES TABLES DE DESCRIPTION--------------------
--------------------------------------------------------------------------------------

SET search_path = meta, pg_catalog;
INSERT INTO bib_programmes (id_programme, nom_programme, desc_programme, actif, programme_public, desc_programme_public) VALUES (6, 'Bryophytes', 'Relevés stationnels et non stratifiés de la flore bryophyte.', true, true, 'Relevés stationnels et non stratifiés de la flore bryophyte.');
INSERT INTO bib_lots (id_lot, nom_lot, desc_lot, menu_cf, pn, menu_inv, id_programme) VALUES (6, 'bryophytes', 'Relevés stationnels et non stratifiés de la flore bryophyte', false, true, false, 6);
INSERT INTO t_protocoles VALUES (6, 'Bryophytes', 'à compléter', 'à compléter', 'à compléter', 'non', NULL, NULL);
SET search_path = synthese, pg_catalog;
INSERT INTO bib_sources (id_source, nom_source, desc_source, host, port, username, pass, db_name, db_schema, db_table, db_field, url, target, picto, groupe, actif) VALUES (6, 'Bryophytes', 'Données de contact bryologique', 'localhost', 22, NULL, NULL, 'geonaturedb', 'bryophytes', 'cor_bryo_taxon', 'gid', 'bryo', NULL, 'images/pictos/mousse.gif', 'FLORE', true);