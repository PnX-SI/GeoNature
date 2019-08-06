CREATE SCHEMA pr_aigle;


-------------
--FUNCTIONS--
-------------
CREATE FUNCTION pr_aigle.application_update_statut_territoire() RETURNS boolean
    LANGUAGE plpgsql
    AS $$
  BEGIN
    update pr_aigle.t_territoires set id_statut_repro_calcul = 0;
	update pr_aigle.t_territoires
	set id_statut_repro_calcul = a.id_statut_repro
	FROM
	(select a.annee, a.id_territoire, a.num_territoire, a.nom_territoire, b.id_statut_repro, a.statut_repro, max(a.date_visite)
	FROM (select s.id_statut_repro, s.statut_repro, t.annee, t.id_territoire, t.num_territoire, t.nom_territoire, v.date_visite, v.id_visite, b.activite, a.num_aire, a.nom_aire
	from pr_aigle.bib_statut_reproduction s
	JOIN pr_aigle.bib_activites b ON b.id_statut_repro = s.id_statut_repro
	JOIN pr_aigle.cor_visite_activite c ON c.id_activite = b.id_activite
	join pr_aigle.t_visites v ON v.id_visite = c.id_visite
	JOIN pr_aigle.t_aires a ON a.id_aire = v.id_aire
	JOIN pr_aigle.cor_aire_territoire at ON at.id_aire = a.id_aire
	JOIN pr_aigle.t_territoires t ON t.id_territoire = at.id_territoire
	WHERE cast(to_char(v.date_visite,'YYYY')as int) = t.annee
	group by s.id_statut_repro, s.statut_repro, t.annee, t.id_territoire, t.num_territoire, t.nom_territoire, v.date_visite, v.id_visite, b.activite, a.num_aire, a.nom_aire
	order by t.nom_territoire) a
	JOIN
	(select max(s.id_statut_repro) as id_statut_repro, t.annee, t.id_territoire  
	from pr_aigle.bib_statut_reproduction s
	JOIN pr_aigle.bib_activites b ON b.id_statut_repro = s.id_statut_repro
	JOIN pr_aigle.cor_visite_activite c ON c.id_activite = b.id_activite
	join pr_aigle.t_visites v ON v.id_visite = c.id_visite
	JOIN pr_aigle.t_aires a ON a.id_aire = v.id_aire
	JOIN pr_aigle.cor_aire_territoire at ON at.id_aire = a.id_aire
	JOIN pr_aigle.t_territoires t ON t.id_territoire = at.id_territoire
	WHERE t.annee = cast(to_char(v.date_visite,'YYYY')as int)
	group by t.annee, t.id_territoire
	order by t.id_territoire) b
	ON a.id_statut_repro = b.id_statut_repro and a.id_territoire = b.id_territoire
	GROUP BY a.annee, a.id_territoire, a.num_territoire, a.nom_territoire, b.id_statut_repro, a.statut_repro
	ORDER BY a.annee, a.nom_territoire) a
	WHERE a.id_territoire = t_territoires.id_territoire;
	update pr_aigle.t_territoires
	set id_statut_repro_expert = id_statut_repro_calcul
	WHERE id_statut_repro_expert < id_statut_repro_calcul;
    RETURN TRUE;
  END;
$$;

CREATE FUNCTION pr_aigle.application_update_statut_territoire(id integer) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE id_terr integer;
  BEGIN
	select into id_terr c.id_territoire FROM pr_aigle.t_visites v
	JOIN pr_aigle.cor_aire_territoire c ON c.id_aire = v.id_aire
	JOIN pr_aigle.t_territoires t ON t.id_territoire = c.id_territoire
	WHERE v.id_visite = id 
	AND cast(to_char(v.date_visite,'YYYY')as int) = t.annee;
	-- on supprime le trigger update pour éviter qu'il soit lancer sur l'update territoire
	DROP TRIGGER check_territoire_aire_intersection_trigger ON pr_aigle.t_territoires;

	-- on commence les update de la t_territoires
	update pr_aigle.t_territoires set id_statut_repro_calcul = 0
	WHERE id_territoire = id_terr;
	
	update pr_aigle.t_territoires
	set id_statut_repro_calcul = a.id_statut_repro
	FROM
	(
		select a.annee, a.id_territoire, a.num_territoire, a.nom_territoire, b.id_statut_repro, a.statut_repro, max(a.date_visite)
		FROM 
		(
			select s.id_statut_repro, s.statut_repro, t.annee, t.id_territoire, t.num_territoire, t.nom_territoire, v.date_visite, v.id_visite, b.activite, a.num_aire, a.nom_aire
			from pr_aigle.bib_statut_reproduction s
			JOIN pr_aigle.bib_activites b ON b.id_statut_repro = s.id_statut_repro
			JOIN pr_aigle.cor_visite_activite c ON c.id_activite = b.id_activite
			join pr_aigle.t_visites v ON v.id_visite = c.id_visite
			JOIN pr_aigle.t_aires a ON a.id_aire = v.id_aire
			JOIN pr_aigle.cor_aire_territoire at ON at.id_aire = a.id_aire
			JOIN pr_aigle.t_territoires t ON t.id_territoire = at.id_territoire
			WHERE cast(to_char(v.date_visite,'YYYY')as int) = t.annee
			AND t.id_territoire = id_terr
			group by s.id_statut_repro, s.statut_repro, t.annee, t.id_territoire, t.num_territoire, t.nom_territoire, v.date_visite, v.id_visite, b.activite, a.num_aire, a.nom_aire
			order by t.nom_territoire
		) a
		JOIN
		(
			select max(s.id_statut_repro) as id_statut_repro, t.annee, t.id_territoire  
			from pr_aigle.bib_statut_reproduction s
			JOIN pr_aigle.bib_activites b ON b.id_statut_repro = s.id_statut_repro
			JOIN pr_aigle.cor_visite_activite c ON c.id_activite = b.id_activite
			join pr_aigle.t_visites v ON v.id_visite = c.id_visite
			JOIN pr_aigle.t_aires a ON a.id_aire = v.id_aire
			JOIN pr_aigle.cor_aire_territoire at ON at.id_aire = a.id_aire
			JOIN pr_aigle.t_territoires t ON t.id_territoire = at.id_territoire
			WHERE t.annee = cast(to_char(v.date_visite,'YYYY')as int)
			AND t.id_territoire = id_terr
			group by t.annee, t.id_territoire
			order by t.id_territoire
		) b ON a.id_statut_repro = b.id_statut_repro and a.id_territoire = b.id_territoire
		WHERE a.id_territoire = id_terr
		GROUP BY a.annee, a.id_territoire, a.num_territoire, a.nom_territoire, b.id_statut_repro, a.statut_repro
		ORDER BY a.annee, a.nom_territoire
	) a
	WHERE pr_aigle.t_territoires.id_territoire = id_terr;
	update pr_aigle.t_territoires
	set id_statut_repro_expert = id_statut_repro_calcul
	WHERE id_statut_repro_expert < id_statut_repro_calcul;
	-- on recréer le trigger update 
	CREATE TRIGGER check_territoire_aire_intersection_trigger
	AFTER INSERT OR UPDATE
	ON pr_aigle.t_territoires
	FOR EACH ROW
	EXECUTE PROCEDURE pr_aigle.check_territoire_aire_intersection();
	RETURN TRUE;
  END;
$$;

CREATE FUNCTION pr_aigle.application_update_statut_territoire2() RETURNS boolean
    LANGUAGE plpgsql
    AS $$
  BEGIN
	update pr_aigle.t_territoires set id_statut_repro_calcul = 0;
	update pr_aigle.t_territoires
	set id_statut_repro_calcul = a.id_statut_repro
	FROM
	(select a.annee, a.id_territoire, a.num_territoire, a.nom_territoire, b.id_statut_repro, a.statut_repro, max(a.date_rencontre)
	FROM (select s.id_statut_repro, s.statut_repro, t.annee, t.id_territoire, t.num_territoire, t.nom_territoire, v.date_rencontre, v.id_rencontre, b.comportement
	from pr_aigle.bib_statut_reproduction s
	JOIN pr_aigle.bib_comportements b ON b.id_statut_repro = s.id_statut_repro
	JOIN pr_aigle.cor_rencontre_comportement c ON c.id_comportement = b.id_comportement
	join pr_aigle.t_rencontres v ON v.id_rencontre = c.id_rencontre
	JOIN pr_aigle.t_territoires t ON t.id_territoire = v.id_territoire
	WHERE cast(to_char(v.date_rencontre,'YYYY')as int) = t.annee
	group by s.id_statut_repro, s.statut_repro, t.annee, t.id_territoire, t.num_territoire, t.nom_territoire, v.date_rencontre, v.id_rencontre, b.comportement
	order by t.nom_territoire) a
	JOIN
	(select max(s.id_statut_repro) as id_statut_repro, t.annee, t.id_territoire  
	from pr_aigle.bib_statut_reproduction s
	JOIN pr_aigle.bib_comportements b ON b.id_statut_repro = s.id_statut_repro
	JOIN pr_aigle.cor_rencontre_comportement c ON c.id_comportement = b.id_comportement
	join pr_aigle.t_rencontres v ON v.id_rencontre = c.id_rencontre
	JOIN pr_aigle.t_territoires t ON t.id_territoire = v.id_territoire
	WHERE t.annee = cast(to_char(v.date_rencontre,'YYYY')as int)
	group by t.annee, t.id_territoire
	order by t.id_territoire) b
	ON a.id_statut_repro = b.id_statut_repro and a.id_territoire = b.id_territoire
	GROUP BY a.annee, a.id_territoire, a.num_territoire, a.nom_territoire, b.id_statut_repro, a.statut_repro
	ORDER BY a.annee, a.nom_territoire) a
	WHERE a.id_territoire = t_territoires.id_territoire;
	update pr_aigle.t_territoires
	set id_statut_repro_expert = id_statut_repro_calcul
	WHERE id_statut_repro_expert < id_statut_repro_calcul;
    RETURN TRUE;
  END;
$$;

CREATE FUNCTION pr_aigle.check_aire_territoire_intersection() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  DECLARE
    id INTEGER;
  BEGIN
    SELECT INTO id id_aire
    FROM pr_aigle.t_aires WHERE id_aire = NEW.id_aire;
    DELETE FROM pr_aigle.cor_aire_territoire
    WHERE id_aire = id;
    INSERT INTO pr_aigle.cor_aire_territoire (id_aire, id_territoire)
    SELECT a.id_aire, b.id_territoire
    FROM pr_aigle.t_aires AS a, pr_aigle.t_territoires AS b
    WHERE st_intersects(b.the_geom, a.the_geom)
    AND a.id_aire = id;
    RETURN NEW;
  END;
$$;

CREATE FUNCTION pr_aigle.check_territoire_aire_intersection() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  DECLARE
    y INTEGER;
  BEGIN
   IF (TG_OP = 'UPDATE') THEN 
     IF NOT ST_Equals(new.the_geom,old.the_geom) OR (old.the_geom is null AND new.the_geom is not null) THEN	
      SELECT into y cast(extract (year from current_date) as integer);
      DELETE FROM pr_aigle.cor_aire_territoire
      WHERE id_territoire in (SELECT id_territoire from pr_aigle.t_territoires t where t.annee = y);
      INSERT INTO pr_aigle.cor_aire_territoire (id_aire, id_territoire)
        SELECT a.id_aire, b.id_territoire
        FROM pr_aigle.t_aires AS a, (SELECT * from pr_aigle.t_territoires t 
        WHERE t.annee = y) as b
      WHERE st_intersects(b.the_geom, a.the_geom);
     END IF;
   END IF;
   IF (TG_OP = 'INSERT') THEN 	
      SELECT into y cast(extract (year from current_date) as integer);
      DELETE FROM pr_aigle.cor_aire_territoire
      WHERE id_territoire in (SELECT id_territoire from pr_aigle.t_territoires t where t.annee = y);
      INSERT INTO pr_aigle.cor_aire_territoire (id_aire, id_territoire)
        SELECT a.id_aire, b.id_territoire
        FROM pr_aigle.t_aires AS a, (SELECT * from pr_aigle.t_territoires t 
        WHERE t.annee = y) as b
      WHERE st_intersects(b.the_geom, a.the_geom);
   END IF;
    
    RETURN NEW;
  END;
$$;

----------
--TABLES--
----------
SET default_with_oids = false;

CREATE TABLE pr_aigle.bib_activites (
    id_activite integer NOT NULL,
    id_statut_repro integer NOT NULL,
    activite character varying(100)
);

CREATE TABLE pr_aigle.bib_comportements (
    id_comportement integer NOT NULL,
    comportement character varying(100),
    id_statut_repro integer
);

-- CREATE TABLE pr_aigle.bib_droits (
--     id_droits integer NOT NULL,
--     droits character varying(50),
--     description text
-- );

CREATE TABLE pr_aigle.bib_orientations (
    id_orientation integer NOT NULL,
    orientation character varying(20)
);

CREATE TABLE pr_aigle.bib_positions (
    id_position integer NOT NULL,
    positionnement character varying(50)
);

CREATE TABLE pr_aigle.bib_secteurs (
    id_secteur integer NOT NULL,
    secteur character varying(50)
);

CREATE TABLE pr_aigle.bib_statut_reproduction (
    id_statut_repro integer NOT NULL,
    statut_repro character varying(100),
    code_couleur character(7)
);

CREATE TABLE pr_aigle.bib_substrats (
    id_substrat integer NOT NULL,
    substrat character varying(50),
    type_substrat character varying(20)
);

CREATE TABLE pr_aigle.bib_topologies (
    id_topologie integer NOT NULL,
    topologie character varying(50)
);

CREATE TABLE pr_aigle.cor_aire_territoire (
    id_territoire integer NOT NULL,
    id_aire integer NOT NULL
);

CREATE TABLE pr_aigle.cor_rencontre_comportement (
    id_rencontre integer NOT NULL,
    id_comportement integer NOT NULL
);

CREATE TABLE pr_aigle.cor_visite_activite (
    id_activite integer NOT NULL,
    id_visite integer NOT NULL
);

CREATE TABLE pr_aigle.t_aires (
    id_aire integer NOT NULL,
    id_observateur integer,
    id_topologie integer,
    id_orientation integer,
    id_substrat integer,
    id_position integer,
    num_aire character varying(10),
    nom_aire character varying(100),
    annee_decouverte integer,
    altitude integer,
    hauteur_falaise integer,
    date_decouverte timestamp without time zone,
    validation boolean DEFAULT false,
    the_geom public.geometry,
    CONSTRAINT enforce_dims_the_geom CHECK ((public.st_ndims(the_geom) = 2)),
    CONSTRAINT enforce_geotype_the_geom CHECK (((public.st_geometrytype(the_geom) = 'ST_Point'::text) OR (the_geom IS NULL))),
    CONSTRAINT enforce_srid_the_geom CHECK ((public.st_srid(the_geom) = 27572))
);
CREATE SEQUENCE pr_aigle.t_aires_id_aire_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE pr_aigle.t_aires_id_aire_seq OWNED BY pr_aigle.t_aires.id_aire;
ALTER TABLE ONLY pr_aigle.t_aires ALTER COLUMN id_aire SET DEFAULT nextval('pr_aigle.t_aires_id_aire_seq'::regclass);

CREATE TABLE pr_aigle.t_photos_aires (
    id_photo integer NOT NULL,
    id_aire integer NOT NULL,
    chemin character varying(255),
    legend character varying(255),
    nom_photo character varying(50)
);
CREATE SEQUENCE pr_aigle.t_photos_aires_id_photo_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE pr_aigle.t_photos_aires_id_photo_seq OWNED BY pr_aigle.t_photos_aires.id_photo;
ALTER TABLE ONLY pr_aigle.t_photos_aires ALTER COLUMN id_photo SET DEFAULT nextval('pr_aigle.t_photos_aires_id_photo_seq'::regclass);


CREATE TABLE pr_aigle.t_rencontres (
    id_rencontre integer NOT NULL,
    id_observateur integer NOT NULL,
    id_territoire integer NOT NULL,
    date_rencontre date NOT NULL,
    remarques text,
    id_redacteur integer,
    duree double precision
);
CREATE SEQUENCE pr_aigle.t_rencontres_id_rencontre_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE pr_aigle.t_rencontres_id_rencontre_seq OWNED BY pr_aigle.t_rencontres.id_rencontre;
ALTER TABLE ONLY pr_aigle.t_rencontres ALTER COLUMN id_rencontre SET DEFAULT nextval('pr_aigle.t_rencontres_id_rencontre_seq'::regclass);

CREATE TABLE pr_aigle.t_territoires (
    id_territoire integer NOT NULL,
    id_statut_repro_expert integer DEFAULT 0,
    id_statut_repro_calcul integer DEFAULT 0,
    num_territoire integer,
    nom_territoire character varying(100),
    annee integer NOT NULL,
    id_secteur integer,
    the_geom public.geometry,
    CONSTRAINT enforce_dims_the_geom CHECK ((public.st_ndims(the_geom) = 2)),
    CONSTRAINT enforce_srid_the_geom CHECK ((public.st_srid(the_geom) = 27572))
);
CREATE SEQUENCE pr_aigle.t_territoires_id_territoire_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE pr_aigle.t_territoires_id_territoire_seq OWNED BY pr_aigle.t_territoires.id_territoire;
ALTER TABLE ONLY pr_aigle.t_territoires ALTER COLUMN id_territoire SET DEFAULT nextval('pr_aigle.t_territoires_id_territoire_seq'::regclass);

CREATE TABLE pr_aigle.t_visites (
    id_visite integer NOT NULL,
    id_observateur integer NOT NULL,
    id_aire integer NOT NULL,
    date_visite date NOT NULL,
    remarques text,
    id_redacteur integer,
    duree double precision
);
CREATE SEQUENCE pr_aigle.t_visites_id_visite_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE pr_aigle.t_visites_id_visite_seq OWNED BY pr_aigle.t_visites.id_visite;
ALTER TABLE ONLY pr_aigle.t_visites ALTER COLUMN id_visite SET DEFAULT nextval('pr_aigle.t_visites_id_visite_seq'::regclass);


---------
--VIEWS--
---------
CREATE VIEW pr_aigle.yoccoz AS
 SELECT public.st_transform(public.st_convexhull(public.st_union(a.the_geom)), 2154) AS the_geom,
    t.id_territoire,
    t.nom_territoire
   FROM ((pr_aigle.t_aires a
     JOIN pr_aigle.cor_aire_territoire cor ON ((a.id_aire = cor.id_aire)))
     JOIN pr_aigle.t_territoires t ON ((cor.id_territoire = t.id_territoire)))
  WHERE (t.annee = 2011)
  GROUP BY t.id_territoire, t.nom_territoire;


----------------
--PRIMARY KEYS--
----------------
ALTER TABLE ONLY pr_aigle.bib_activites ADD CONSTRAINT pk_bib_activites PRIMARY KEY (id_activite);
ALTER TABLE ONLY pr_aigle.bib_comportements ADD CONSTRAINT pk_bib_comportements PRIMARY KEY (id_comportement);
--ALTER TABLE ONLY pr_aigle.bib_droits ADD CONSTRAINT pk_bib_droits PRIMARY KEY (id_droits);
ALTER TABLE ONLY pr_aigle.bib_orientations ADD CONSTRAINT pk_bib_orientations PRIMARY KEY (id_orientation);
ALTER TABLE ONLY pr_aigle.bib_positions ADD CONSTRAINT pk_bib_positions PRIMARY KEY (id_position);
ALTER TABLE ONLY pr_aigle.bib_secteurs ADD CONSTRAINT pk_bib_secteurs PRIMARY KEY (id_secteur);
ALTER TABLE ONLY pr_aigle.bib_statut_reproduction ADD CONSTRAINT pk_bib_statut_reproduction PRIMARY KEY (id_statut_repro);
ALTER TABLE ONLY pr_aigle.bib_substrats ADD CONSTRAINT pk_bib_substrat PRIMARY KEY (id_substrat);
ALTER TABLE ONLY pr_aigle.bib_topologies ADD CONSTRAINT pk_bib_topologie PRIMARY KEY (id_topologie);
ALTER TABLE ONLY pr_aigle.cor_aire_territoire ADD CONSTRAINT pk_cor_aire_territoire PRIMARY KEY (id_territoire, id_aire);
ALTER TABLE ONLY pr_aigle.cor_rencontre_comportement ADD CONSTRAINT pk_cor_rencontre_comportement PRIMARY KEY (id_rencontre, id_comportement);
ALTER TABLE ONLY pr_aigle.cor_visite_activite ADD CONSTRAINT pk_cor_visite_activite PRIMARY KEY (id_activite, id_visite);
ALTER TABLE ONLY pr_aigle.t_aires ADD CONSTRAINT pk_t_aires PRIMARY KEY (id_aire);
ALTER TABLE ONLY pr_aigle.t_photos_aires ADD CONSTRAINT pk_t_photos_aires PRIMARY KEY (id_photo);
ALTER TABLE ONLY pr_aigle.t_rencontres ADD CONSTRAINT pk_t_rencontres PRIMARY KEY (id_rencontre);
ALTER TABLE ONLY pr_aigle.t_territoires ADD CONSTRAINT pk_t_territoires PRIMARY KEY (id_territoire);
ALTER TABLE ONLY pr_aigle.t_visites ADD CONSTRAINT pk_t_visites PRIMARY KEY (id_visite);


---------------
--IMPORT DATA--
---------------
IMPORT FOREIGN SCHEMA aigle EXCEPT (bib_droits) FROM SERVER geonature1server INTO v1_compat;
INSERT INTO pr_aigle.bib_activites SELECT * FROM v1_compat.bib_activites;
INSERT INTO pr_aigle.bib_comportements SELECT * FROM v1_compat.bib_comportements;
INSERT INTO pr_aigle.bib_orientations SELECT * FROM v1_compat.bib_orientations;
INSERT INTO pr_aigle.bib_positions SELECT * FROM v1_compat.bib_positions;
INSERT INTO pr_aigle.bib_secteurs SELECT * FROM v1_compat.bib_secteurs;
INSERT INTO pr_aigle.bib_statut_reproduction SELECT * FROM v1_compat.bib_statut_reproduction;
INSERT INTO pr_aigle.bib_substrats SELECT * FROM v1_compat.bib_substrats;
INSERT INTO pr_aigle.bib_topologies SELECT * FROM v1_compat.bib_topologies;
INSERT INTO pr_aigle.t_aires SELECT * FROM v1_compat.t_aires;
INSERT INTO pr_aigle.t_photos_aires SELECT * FROM v1_compat.t_photos_aires;
INSERT INTO pr_aigle.t_territoires SELECT * FROM v1_compat.t_territoires;
INSERT INTO pr_aigle.t_rencontres SELECT * FROM v1_compat.t_rencontres;
INSERT INTO pr_aigle.t_visites SELECT * FROM v1_compat.t_visites;
INSERT INTO pr_aigle.cor_aire_territoire SELECT * FROM v1_compat.cor_aire_territoire;
INSERT INTO pr_aigle.cor_rencontre_comportement SELECT * FROM v1_compat.cor_rencontre_comportement;
INSERT INTO pr_aigle.cor_visite_activite SELECT * FROM v1_compat.cor_visite_activite;

---------
--INDEX--
---------
CREATE INDEX fki_ ON pr_aigle.t_photos_aires USING btree (id_aire);
CREATE INDEX i_fk_bib_activites_bib_statut_ ON pr_aigle.bib_activites USING btree (id_statut_repro);
CREATE INDEX i_fk_cor_aire_territoire_t_air ON pr_aigle.cor_aire_territoire USING btree (id_aire);
CREATE INDEX i_fk_cor_aire_territoire_t_ter ON pr_aigle.cor_aire_territoire USING btree (id_territoire);
CREATE INDEX i_fk_cor_visite_activite_bib_a ON pr_aigle.cor_visite_activite USING btree (id_activite);
CREATE INDEX i_fk_cor_visite_activite_t_vis ON pr_aigle.cor_visite_activite USING btree (id_visite);
CREATE INDEX i_fk_cor_visite_comportement_b ON pr_aigle.cor_rencontre_comportement USING btree (id_comportement);
CREATE INDEX i_fk_cor_visite_comportement_t ON pr_aigle.cor_rencontre_comportement USING btree (id_rencontre);
CREATE INDEX i_fk_t_aires_bib_observateurs ON pr_aigle.t_aires USING btree (id_observateur);
CREATE INDEX i_fk_t_aires_bib_orientations ON pr_aigle.t_aires USING btree (id_orientation);
CREATE INDEX i_fk_t_aires_bib_positions ON pr_aigle.t_aires USING btree (id_position);
CREATE INDEX i_fk_t_aires_bib_substrat ON pr_aigle.t_aires USING btree (id_substrat);
CREATE INDEX i_fk_t_aires_bib_topologie ON pr_aigle.t_aires USING btree (id_topologie);
CREATE INDEX i_fk_t_rencontres_bib_observateur ON pr_aigle.t_rencontres USING btree (id_observateur);
CREATE INDEX i_fk_t_rencontres_t_territoires ON pr_aigle.t_rencontres USING btree (id_territoire);
CREATE INDEX i_fk_t_territoires_bib_statut1 ON pr_aigle.t_territoires USING btree (id_statut_repro_calcul);
CREATE INDEX i_fk_t_territoires_bib_statut_ ON pr_aigle.t_territoires USING btree (id_statut_repro_expert);
CREATE INDEX i_fk_t_visites_bib_observateur ON pr_aigle.t_visites USING btree (id_observateur);
CREATE INDEX i_fk_t_visites_t_aires ON pr_aigle.t_visites USING btree (id_aire);


------------
--TRIGGERS--
------------
CREATE TRIGGER check_aire_territoire_intersection_trigger AFTER INSERT ON pr_aigle.t_aires FOR EACH ROW EXECUTE PROCEDURE pr_aigle.check_aire_territoire_intersection();
CREATE TRIGGER check_territoire_aire_intersection_trigger AFTER INSERT OR UPDATE ON pr_aigle.t_territoires FOR EACH ROW EXECUTE PROCEDURE pr_aigle.check_territoire_aire_intersection();


----------------
--FOREIGN KEYS--
----------------
ALTER TABLE ONLY pr_aigle.bib_activites
    ADD CONSTRAINT fk_bib_activites_bib_statut_repr FOREIGN KEY (id_statut_repro) REFERENCES pr_aigle.bib_statut_reproduction(id_statut_repro);
ALTER TABLE ONLY pr_aigle.cor_aire_territoire
    ADD CONSTRAINT fk_cor_aire_territoire_t_aires FOREIGN KEY (id_aire) REFERENCES pr_aigle.t_aires(id_aire) ON UPDATE CASCADE;
ALTER TABLE ONLY pr_aigle.cor_aire_territoire
    ADD CONSTRAINT fk_cor_aire_territoire_t_territo FOREIGN KEY (id_territoire) REFERENCES pr_aigle.t_territoires(id_territoire) ON UPDATE CASCADE;
ALTER TABLE ONLY pr_aigle.cor_rencontre_comportement
    ADD CONSTRAINT fk_cor_rencontre_comportement_bib_c FOREIGN KEY (id_comportement) REFERENCES pr_aigle.bib_comportements(id_comportement) ON UPDATE CASCADE;
ALTER TABLE ONLY pr_aigle.cor_rencontre_comportement
    ADD CONSTRAINT fk_cor_rencontre_comportement_t_ren FOREIGN KEY (id_rencontre) REFERENCES pr_aigle.t_rencontres(id_rencontre) ON UPDATE CASCADE;
ALTER TABLE ONLY pr_aigle.cor_visite_activite
    ADD CONSTRAINT fk_cor_visite_activite_bib_activ FOREIGN KEY (id_activite) REFERENCES pr_aigle.bib_activites(id_activite);
ALTER TABLE ONLY pr_aigle.cor_visite_activite
    ADD CONSTRAINT fk_cor_visite_activite_t_visites FOREIGN KEY (id_visite) REFERENCES pr_aigle.t_visites(id_visite);
ALTER TABLE ONLY pr_aigle.t_aires
    ADD CONSTRAINT fk_t_aires_bib_orientations FOREIGN KEY (id_orientation) REFERENCES pr_aigle.bib_orientations(id_orientation) ON UPDATE CASCADE;
ALTER TABLE ONLY pr_aigle.t_aires
    ADD CONSTRAINT fk_t_aires_bib_positions FOREIGN KEY (id_position) REFERENCES pr_aigle.bib_positions(id_position) ON UPDATE CASCADE;
ALTER TABLE ONLY pr_aigle.t_aires
    ADD CONSTRAINT fk_t_aires_bib_substrat FOREIGN KEY (id_substrat) REFERENCES pr_aigle.bib_substrats(id_substrat) ON UPDATE CASCADE;
ALTER TABLE ONLY pr_aigle.t_aires
    ADD CONSTRAINT fk_t_aires_bib_topologie FOREIGN KEY (id_topologie) REFERENCES pr_aigle.bib_topologies(id_topologie) ON UPDATE CASCADE;
ALTER TABLE ONLY pr_aigle.t_rencontres
    ADD CONSTRAINT fk_t_rencontres_bib_observateurs FOREIGN KEY (id_observateur) REFERENCES utilisateurs.t_roles(id_role) ON UPDATE CASCADE;
ALTER TABLE ONLY pr_aigle.t_rencontres
    ADD CONSTRAINT fk_t_rencontres_t_territoires FOREIGN KEY (id_territoire) REFERENCES pr_aigle.t_territoires(id_territoire) ON UPDATE CASCADE;
ALTER TABLE ONLY pr_aigle.t_territoires
    ADD CONSTRAINT fk_t_territoires_bib_statut_re_2 FOREIGN KEY (id_statut_repro_calcul) REFERENCES pr_aigle.bib_statut_reproduction(id_statut_repro);
ALTER TABLE ONLY pr_aigle.t_territoires
    ADD CONSTRAINT fk_t_territoires_bib_statut_repr FOREIGN KEY (id_statut_repro_expert) REFERENCES pr_aigle.bib_statut_reproduction(id_statut_repro);
ALTER TABLE ONLY pr_aigle.t_visites
    ADD CONSTRAINT fk_t_visites_bib_observateurs FOREIGN KEY (id_observateur) REFERENCES utilisateurs.t_roles(id_role);
ALTER TABLE ONLY pr_aigle.t_visites
    ADD CONSTRAINT fk_t_visites_t_aires FOREIGN KEY (id_aire) REFERENCES pr_aigle.t_aires(id_aire);
ALTER TABLE ONLY pr_aigle.t_photos_aires
    ADD CONSTRAINT t_photos_aires_id_aire_fkey FOREIGN KEY (id_aire) REFERENCES pr_aigle.t_aires(id_aire);



