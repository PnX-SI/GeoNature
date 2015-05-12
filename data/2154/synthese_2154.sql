--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- Name: contactfaune; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA contactfaune;


--
-- Name: SCHEMA contactfaune; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA contactfaune IS 'schéma contenant les données et les bibliothèques du protocole contact faune';


--
-- Name: contactinv; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA contactinv;


--
-- Name: SCHEMA contactinv; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA contactinv IS 'schéma contenant les données et les bibliothèques du protocole contact invertébrés sur le modèle de contactfaune';


--
-- TOC entry 6 (class 2615 OID 55162)
-- Name: bryophytes; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA bryophytes;


--
-- TOC entry 16 (class 2615 OID 55164)
-- Name: florepatri; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA florepatri;


--
-- TOC entry 19 (class 2615 OID 55165)
-- Name: florestation; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA florestation;


--
-- Name: layers; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA layers;


--
-- Name: SCHEMA layers; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA layers IS 'schéma contenant les couches SIG nécéssaires au fonctionnement de la base ou des applications qui s''y connectent. (exemple, communes, secteurs, zone à statut...)';


--
-- Name: meta; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA meta;


--
-- Name: synchronomade; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA synchronomade;


--
-- Name: synthese; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA synthese;


--
-- Name: taxonomie; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA taxonomie;


--
-- Name: utilisateurs; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA utilisateurs;


SET search_path = public, pg_catalog;

--function visant à restaurer le fonctionnement du wms dans l'application fonctionnant avec un mapserver non compatible avec st_geomfromtext
CREATE OR REPLACE FUNCTION geomfromtext(text, integer)
  RETURNS geometry AS
'SELECT st_geometryfromtext($1, $2)'
  LANGUAGE sql IMMUTABLE STRICT
  COST 100;

-- Function: public.periode(date, date, date)

-- DROP FUNCTION public.periode(date, date, date);

CREATE OR REPLACE FUNCTION public.periode(dateobs date, datedebut date, datefin date)
  RETURNS boolean AS
$BODY$
declare
 
jo int; jd int; jf int; test int; 
 
 
BEGIN
jo = extract(doy FROM dateobs);--jour de la date passée
jd = extract(doy FROM datedebut);--jour début
jf = extract(doy FROM datefin); --jour fin
test = jf - jd; --test si la période est sur 2 année ou pas
 
--si on est sur 2 années
IF test < 0 then
	IF jo BETWEEN jd AND 366 OR jo BETWEEN 1 AND jf THEN RETURN true;
	END IF;
-- si on est dans la même année
else 
	IF jo BETWEEN jd AND jf THEN RETURN true;
	END IF;
END IF;
	RETURN false;	
END;
 
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION public.periode(date, date, date)
  OWNER TO geonatuser;
  

SET search_path = contactfaune, pg_catalog;

--
-- Name: couleur_taxon(integer, date); Type: FUNCTION; Schema: contactfaune; Owner: -
--

CREATE FUNCTION couleur_taxon(id integer, maxdateobs date) RETURNS text
    LANGUAGE plpgsql
    AS $$
--fonction permettant de renvoyer la couleur d'un taxon à partir de la dernière date d'observation 
--
--Gil DELUERMOZ mars 2012

  DECLARE
  couleur text;
  patri character(3);
  BEGIN
	SELECT patrimonial INTO patri 
    FROM taxonomie.bib_taxons t
    LEFT JOIN taxonomie.cor_taxon_attribut cta ON cta.id_taxon = t.id_taxon
    LEFT JOIN taxonomie.bib_attributs a ON a.id_attribut = cta.id_attribut
    WHERE a.nom_attribut = 'patrimonial' AND t.id_taxon = id;
	IF patri = 'oui' THEN
		IF date_part('year',maxdateobs)=date_part('year',now()) THEN couleur = 'gray';
		ELSE couleur = 'red';
		END IF;
	ELSIF patri = 'non' THEN
		IF date_part('year',maxdateobs)>=date_part('year',now())-3 THEN couleur = 'gray';
		ELSE couleur = 'red';
		END IF;
	ELSE
	return false;	
	END IF;
	return couleur;
  END;
$$;


--
-- Name: insert_fiche_cf(); Type: FUNCTION; Schema: contactfaune; Owner: -
--

CREATE FUNCTION insert_fiche_cf() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
macommune character(5);
BEGIN
------- si le pointage est deja dans la BDD alors le trigger retourne null (l'insertion de la ligne est annulée).
IF new.id_cf in (SELECT id_cf FROM contactfaune.t_fiches_cf) THEN	
	return null;
ELSE
	new.date_insert= 'now';
	new.date_update= 'now';
-------gestion des infos relatives a la numerisation (srid utilisé et support utilisé : nomade ou web ou autre)
	IF new.saisie_initiale = 'pda' OR new.saisie_initiale = 'nomade' THEN
		new.srid_dessin = 2154;
		new.the_geom_3857 = st_transform(new.the_geom_2154,3857);
	ELSIF new.saisie_initiale = 'web' THEN
		new.srid_dessin = 3857;
		-- attention : pas de creation des geom 2154 car c'est fait par l'application web
	ELSIF new.saisie_initiale ISNULL THEN
		new.srid_dessin = 0;
		-- pas d'info sur le srid utilisé, cas des importations à gérer manuellement. Ne devrait pas exister.
	END IF;
-------gestion des divers control avec attributions des secteurs + communes : dans le cas d'un insert depuis le nomade uniquement via the_geom !!!!
	IF st_isvalid(new.the_geom_2154) = true THEN	-- si la topologie est bonne alors...
		-- on calcul la commune
		SELECT INTO macommune c.insee FROM layers.l_communes c WHERE st_intersects(c.the_geom, new.the_geom_2154);
		new.insee = macommune;
		-- on calcul l'altitude
		new.altitude_sig = layers.f_isolines20(new.the_geom_2154); -- mise à jour de l'altitude sig
		IF new.altitude_saisie IS null OR new.altitude_saisie = -1 THEN-- mis à jour de l'altitude retenue
		    new.altitude_retenue = new.altitude_sig;
		ELSE
		    new.altitude_retenue = new.altitude_saisie;
		END IF;
	ELSE					
		SELECT INTO macommune c.insee FROM layers.l_communes c WHERE st_intersects(c.the_geom, ST_PointFromWKB(st_centroid(Box2D(new.the_geom_2154)),2154));
		new.insee = macommune;
		-- on calcul l'altitude
		new.altitude_sig = layers.f_isolines20(ST_PointFromWKB(st_centroid(Box2D(new.the_geom_2154)),2154)); -- mise à jour de l'altitude sig
		IF new.altitude_saisie IS null OR new.altitude_saisie = -1 THEN-- mis à jour de l'altitude retenue
			new.altitude_retenue = new.altitude_sig;
		ELSE
			new.altitude_retenue = new.altitude_saisie;
		END IF;
	END IF;
	RETURN NEW; 			
END IF;
END;
$$;


--
-- Name: insert_releve_cf(); Type: FUNCTION; Schema: contactfaune; Owner: -
--

CREATE FUNCTION insert_releve_cf() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
re integer;
unite integer;
nbobs integer;
line record;
fiche record;
BEGIN
    --récup du cd_ref du taxon pour le stocker en base au moment de l'enregistrement (= conseil inpn)
	SELECT INTO re taxonomie.find_cdref(cd_nom) FROM taxonomie.bib_taxons WHERE id_taxon = new.id_taxon;
	new.cd_ref_origine = re;
    -- MAJ de la table cor_unite_taxon, on commence par récupérer l'unité à partir du pointage (table t_fiches_cf)
	SELECT INTO fiche * FROM contactfaune.t_fiches_cf WHERE id_cf = new.id_cf;
	SELECT INTO unite u.id_unite_geo FROM layers.l_unites_geo u WHERE ST_INTERSECTS(fiche.the_geom_2154,u.the_geom);
	--si on est dans une des unités on peut mettre à jour la table cor_unite_taxon, sinon on fait rien
	IF unite>0 THEN
		SELECT INTO line * FROM contactfaune.cor_unite_taxon WHERE id_unite_geo = unite AND id_taxon = new.id_taxon;
		--si la ligne existe dans cor_unite_taxon on la supprime
		IF line IS NOT NULL THEN
			DELETE FROM contactfaune.cor_unite_taxon WHERE id_unite_geo = unite AND id_taxon = new.id_taxon;
		END IF;
		--on compte le nombre d'enregistrement pour ce taxon dans l'unité
		SELECT INTO nbobs count(*) from synthese.syntheseff s
		JOIN layers.l_unites_geo u ON ST_Intersects(u.the_geom, s.the_geom_2154) AND u.id_unite_geo = unite
		WHERE s.id_taxon = new.id_taxon;
		--on créé ou recréé la ligne
		INSERT INTO contactfaune.cor_unite_taxon VALUES(unite,new.id_taxon,fiche.dateobs,contactfaune.couleur_taxon(new.id_taxon,fiche.dateobs), nbobs+1);
	END IF;
	RETURN NEW; 			
END;
$$;


--
-- Name: synthese_delete_releve_cf(); Type: FUNCTION; Schema: contactfaune; Owner: -
--

CREATE FUNCTION synthese_delete_releve_cf() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    idsource integer;
BEGIN
    --SUPRESSION EN SYNTHESE
    
    SELECT INTO idsource id_source FROM synthese.bib_sources  WHERE db_schema='contactfaune' AND db_field = 'id_releve_cf' ;
    
	DELETE FROM synthese.syntheseff WHERE id_source = idsource AND id_fiche_source = old.id_releve_cf::text; 
    RETURN OLD; 
END;
$$;

-- Function: contactfaune.synthese_insert_releve_cf()

-- DROP FUNCTION contactfaune.synthese_insert_releve_cf();

CREATE OR REPLACE FUNCTION contactfaune.synthese_insert_releve_cf()
  RETURNS trigger AS
$$
DECLARE
	fiche RECORD;
	test integer;
	mesobservateurs character varying(255);
	criteresynthese integer;
	unite integer;
	idsource integer;
BEGIN

	--Récupération des données id_source dans la table synthese.bib_sources
	SELECT INTO idsource id_source FROM synthese.bib_sources  WHERE db_schema='contactfaune' AND db_field = 'id_releve_cf';
	
	--Récupération des données dans la table t_fiches_cf et de la liste des observateurs
	SELECT INTO fiche * FROM contactfaune.t_fiches_cf WHERE id_cf = new.id_cf;
	SELECT INTO criteresynthese id_critere_synthese FROM contactfaune.bib_criteres_cf WHERE id_critere_cf = new.id_critere_cf;
	SELECT INTO mesobservateurs o.observateurs FROM contactfaune.t_releves_cf r
	JOIN contactfaune.t_fiches_cf f ON f.id_cf = r.id_cf
	LEFT JOIN (
                SELECT id_cf, array_to_string(array_agg(r.nom_role || ' ' || r.prenom_role), ', ') AS observateurs 
                FROM contactfaune.cor_role_fiche_cf c
                JOIN utilisateurs.t_roles r ON r.id_role = c.id_role
                GROUP BY id_cf
            ) o ON o.id_cf = f.id_cf
	WHERE r.id_releve_cf = new.id_releve_cf;

	INSERT INTO synthese.syntheseff (
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
		determinateur,
		altitude_retenue,
		remarques,
		derniere_action,
		supprime,
		the_geom_3857,
		the_geom_2154,
		the_geom_point,
		id_lot,
		id_critere_synthese,
		effectif_total
	)
	VALUES(
	idsource,
	new.id_releve_cf,
	'f'||new.id_cf||'-r'||new.id_releve_cf,
	fiche.id_organisme,
	fiche.id_protocole,
	1,
	new.cd_ref_origine,
	fiche.insee,
	fiche.dateobs,
	mesobservateurs,
    new.determinateur,
	fiche.altitude_retenue,
	new.commentaire,
	'c',
	false,
	fiche.the_geom_3857,
	fiche.the_geom_2154,
	fiche.the_geom_3857,
	fiche.id_lot,
	criteresynthese,
	new.am+new.af+new.ai+new.na+new.jeune+new.yearling+new.sai
	);
	RETURN NEW; 			
END;
$$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION contactfaune.synthese_insert_releve_cf()
  OWNER TO geonatuser;
GRANT EXECUTE ON FUNCTION contactfaune.synthese_insert_releve_cf() TO geonatuser;
GRANT EXECUTE ON FUNCTION contactfaune.synthese_insert_releve_cf() TO public;



--
-- Name: synthese_update_cor_role_fiche_cf(); Type: FUNCTION; Schema: contactfaune; Owner: -
--

CREATE FUNCTION synthese_update_cor_role_fiche_cf() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
	releves RECORD;
	test integer;
	mesobservateurs character varying(255);
    idsource integer;
BEGIN
	--
	--CE TRIGGER NE DEVRAIT SERVIR QU'EN CAS DE MISE A JOUR MANUELLE SUR CETTE TABLE cor_role_fiche_cf
	--L'APPLI WEB ET LE PDA NE FONT QUE DES INSERTS QUI SONT GERER PAR LE TRIGGER INSERT DE t_releves_cf
	--
    SELECT INTO idsource id_source FROM synthese.bib_sources  WHERE db_schema='contactfaune' AND db_field = 'id_releve_cf' ;
    
	--Récupération des enregistrements de la table t_releves_cf avec l'id_cf de la table cor_role_fiche_cf
	FOR releves IN SELECT * FROM contactfaune.t_releves_cf WHERE id_cf = new.id_cf LOOP
		--test si on a bien l'enregistrement dans la table syntheseff avant de le mettre à jour
		SELECT INTO test id_fiche_source FROM synthese.syntheseff 
            WHERE id_source = idsource AND id_fiche_source = releves.id_releve_cf::text;
		IF test ISNULL THEN
		RETURN null;
		ELSE
			SELECT INTO mesobservateurs o.observateurs FROM contactfaune.t_releves_cf r
			JOIN contactfaune.t_fiches_cf f ON f.id_cf = r.id_cf
			LEFT JOIN (
				SELECT id_cf, array_to_string(array_agg(r.nom_role || ' ' || r.prenom_role), ', ') AS observateurs 
				FROM contactfaune.cor_role_fiche_cf c
				JOIN utilisateurs.t_roles r ON r.id_role = c.id_role
				GROUP BY id_cf
			) o ON o.id_cf = f.id_cf
			WHERE r.id_releve_cf = releves.id_releve_cf;
			--mise à jour de l'enregistrement correspondant dans syntheseff ; uniquement le champ observateurs ici
			UPDATE synthese.syntheseff SET
				observateurs = mesobservateurs
			WHERE id_source = idsource AND id_fiche_source = releves.id_releve_cf::text; 
		END IF;
	END LOOP;
	RETURN NEW; 			
END;
$$;


--
-- Name: synthese_update_fiche_cf(); Type: FUNCTION; Schema: contactfaune; Owner: -
--

CREATE FUNCTION synthese_update_fiche_cf() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
	releves RECORD;
	test integer;
	mesobservateurs character varying(255);
    idsource integer;
BEGIN

    
    SELECT INTO idsource id_source FROM synthese.bib_sources  WHERE db_schema='contactfaune' AND db_field = 'id_releve_cf' ;

	--Récupération des données de la table t_releves_cf avec l'id_cf de la fiche modifié
	-- Ici on utilise le OLD id_cf pour être sur qu'il existe dans la table synthese (cas improbable où on changerait la pk de la table t_fiches_cf
	--le trigger met à jour avec le NEW --> SET code_fiche_source =  ....
	FOR releves IN SELECT * FROM contactfaune.t_releves_cf WHERE id_cf = old.id_cf LOOP
		--test si on a bien l'enregistrement dans la table syntheseff avant de le mettre à jour
		SELECT INTO test id_fiche_source FROM synthese.syntheseff WHERE id_source = idsource AND id_fiche_source = releves.id_releve_cf::text;
		IF test IS NOT NULL THEN
			SELECT INTO mesobservateurs o.observateurs FROM contactfaune.t_releves_cf r
			JOIN contactfaune.t_fiches_cf f ON f.id_cf = r.id_cf
			LEFT JOIN (
				SELECT id_cf, array_to_string(array_agg(r.nom_role || ' ' || r.prenom_role), ', ') AS observateurs 
				FROM contactfaune.cor_role_fiche_cf c
				JOIN utilisateurs.t_roles r ON r.id_role = c.id_role
				GROUP BY id_cf
			) o ON o.id_cf = f.id_cf
			WHERE r.id_releve_cf = releves.id_releve_cf;
			IF NOT St_Equals(new.the_geom_3857,old.the_geom_3857) OR NOT St_Equals(new.the_geom_2154,old.the_geom_2154) THEN
				
				--mise à jour de l'enregistrement correspondant dans syntheseff
				UPDATE synthese.syntheseff SET
				code_fiche_source = 'f'||new.id_cf||'-r'||releves.id_releve_cf,
				id_organisme = new.id_organisme,
				id_protocole = new.id_protocole,
				insee = new.insee,
				dateobs = new.dateobs,
				observateurs = mesobservateurs,
				altitude_retenue = new.altitude_retenue,
				derniere_action = 'u',
				supprime = new.supprime,
				the_geom_3857 = new.the_geom_3857,
				the_geom_2154 = new.the_geom_2154,
				the_geom_point = new.the_geom_3857,
				id_lot = new.id_lot
				WHERE id_source = idsource AND id_fiche_source = releves.id_releve_cf::text;
			ELSE
				--mise à jour de l'enregistrement correspondant dans syntheseff
				UPDATE synthese.syntheseff SET
				code_fiche_source = 'f'||new.id_cf||'-r'||releves.id_releve_cf,
				id_organisme = new.id_organisme,
				id_protocole = new.id_protocole,
				insee = new.insee,
				dateobs = new.dateobs,
				observateurs = mesobservateurs,
				altitude_retenue = new.altitude_retenue,
				derniere_action = 'u',
				supprime = new.supprime,
				the_geom_3857 = new.the_geom_3857,
				the_geom_2154 = new.the_geom_2154,
				the_geom_point = new.the_geom_3857,
				id_lot = new.id_lot
			    WHERE id_source = idsource AND id_fiche_source = releves.id_releve_cf::text;
			END IF;
		END IF;
	END LOOP;
	RETURN NEW; 			
END;
$$;


--
-- Name: synthese_update_releve_cf(); Type: FUNCTION; Schema: contactfaune; Owner: -
--

CREATE FUNCTION synthese_update_releve_cf() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
	test integer;
	criteresynthese integer;
    idsource integer;
BEGIN
    
    SELECT INTO idsource id_source FROM synthese.bib_sources  WHERE db_schema='contactfaune' AND db_field = 'id_releve_cf' ;

	--test si on a bien l'enregistrement dans la table syntheseff avant de le mettre à jour
	SELECT INTO test id_fiche_source FROM synthese.syntheseff WHERE id_source = idsource AND id_fiche_source = old.id_releve_cf::text;
	IF test IS NOT NULL THEN
		SELECT INTO criteresynthese id_critere_synthese FROM contactfaune.bib_criteres_cf WHERE id_critere_cf = new.id_critere_cf;

		--mise à jour de l'enregistrement correspondant dans syntheseff
		UPDATE synthese.syntheseff SET
			id_fiche_source = new.id_releve_cf,
			code_fiche_source = 'f'||new.id_cf||'-r'||new.id_releve_cf,
			cd_nom = new.cd_ref_origine,
			remarques = new.commentaire,
			derniere_action = 'u',
			supprime = new.supprime,
			id_critere_synthese = criteresynthese,
			effectif_total = new.am+new.af+new.ai+new.na+new.jeune+new.yearling+new.sai
		WHERE id_source = idsource AND id_fiche_source = old.id_releve_cf::text; -- Ici on utilise le OLD id_releve_cf pour être sur 
		--qu'il existe dans la table synthese (cas improbable où on changerait la pk de la table t_releves_cf
		--le trigger met à jour avec le NEW --> SET id_fiche_source = new.id_releve_cf
	END IF;
	RETURN NEW; 			
END;
$$;


--
-- Name: update_fiche_cf(); Type: FUNCTION; Schema: contactfaune; Owner: -
--

CREATE FUNCTION update_fiche_cf() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
macommune character(5);
BEGIN
-------------------------- gestion des infos relatives a la numerisation (srid utilisé et support utilisé : pda ou web ou sig)
-------------------------- attention la saisie sur le web réalise un insert sur qq données mais the_geom_3857 est "faussement inséré" par un update !!!
IF (NOT ST_Equals(new.the_geom_2154,old.the_geom_2154) OR (old.the_geom_2154 is null AND new.the_geom_2154 is NOT NULL))
  OR (NOT ST_Equals(new.the_geom_3857,old.the_geom_3857) OR (old.the_geom_3857 is null AND new.the_geom_3857 is NOT NULL)) 
   THEN
	IF NOT ST_Equals(new.the_geom_3857,old.the_geom_3857) OR (old.the_geom_3857 is null AND new.the_geom_3857 is NOT NULL) THEN
		new.the_geom_2154 = st_transform(new.the_geom_3857,2154);
		new.srid_dessin = 3857;
	ELSIF NOT ST_Equals(new.the_geom_2154,old.the_geom_2154) OR (old.the_geom_2154 is null AND new.the_geom_2154 is NOT NULL) THEN
		new.the_geom_3857 = st_transform(new.the_geom_2154,3857);
		new.srid_dessin = 2154;
	END IF;
-------gestion des divers control avec attributions de la commune : dans le cas d'un insert depuis le nomade uniquement via the_geom_2154 !!!!
	IF st_isvalid(new.the_geom_2154) = true THEN	-- si la topologie est bonne alors...
		-- on calcul la commune (celle qui contient le plus de zp en surface)...
		SELECT INTO macommune c.insee FROM layers.l_communes c WHERE st_intersects(c.the_geom, new.the_geom_2154);
		new.insee = macommune;
		-- on calcul l'altitude
		new.altitude_sig = layers.f_isolines20(new.the_geom_2154); -- mise à jour de l'altitude sig
		IF new.altitude_saisie IS null OR new.altitude_saisie = -1 THEN-- mis à jour de l'altitude retenue
		    new.altitude_retenue = new.altitude_sig;
		ELSE
		    new.altitude_retenue = new.altitude_saisie;
		END IF;
	ELSE					
		SELECT INTO macommune c.insee FROM layers.l_communes c WHERE st_intersects(c.the_geom, ST_PointFromWKB(st_centroid(Box2D(new.the_geom_2154)),2154));
		new.insee = macommune;
		-- on calcul l'altitude
		new.altitude_sig = layers.f_isolines20(ST_PointFromWKB(st_centroid(Box2D(new.the_geom_2154)),2154)); -- mise à jour de l'altitude sig
		IF new.altitude_saisie IS null OR new.altitude_saisie = -1 THEN-- mis à jour de l'altitude retenue
			new.altitude_retenue = new.altitude_sig;
		ELSE
			new.altitude_retenue = new.altitude_saisie;
		END IF;
	END IF;				
END IF;
--- divers update
IF new.altitude_saisie <> old.altitude_saisie THEN
   new.altitude_retenue = new.altitude_saisie;
END IF;
new.date_update = 'now';
IF new.supprime <> old.supprime THEN	 
  IF new.supprime = 't' THEN
     update contactfaune.t_releves_cf set supprime = 't' WHERE id_cf = old.id_cf; 
  END IF;
  IF new.supprime = 'f' THEN
     update contactfaune.t_releves_cf set supprime = 'f' WHERE id_cf = old.id_cf; 
  END IF;
END IF;
RETURN NEW; 
END;
$$;


--
-- Name: update_releve_cf(); Type: FUNCTION; Schema: contactfaune; Owner: -
--

CREATE FUNCTION update_releve_cf() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
	re integer;
BEGIN
   -- Si changement de taxon, 
	IF new.id_taxon<>old.id_taxon THEN
	   -- Correction du cd_ref_origine
		SELECT INTO re taxonomie.find_cdref(cd_nom) FROM taxonomie.bib_taxons WHERE id_taxon = new.id_taxon;
		new.cd_ref_origine = re;
	END IF;
RETURN NEW;			
END;
$$;


SET search_path = contactinv, pg_catalog;

--
-- Name: couleur_taxon(integer, date); Type: FUNCTION; Schema: contactinv; Owner: -
--

CREATE FUNCTION couleur_taxon(id integer, maxdateobs date) RETURNS text
    LANGUAGE plpgsql
    AS $$
--fonction permettant de renvoyer la couleur d'un taxon à partir de la dernière date d'observation 
--
--Gil DELUERMOZ mars 2012

  DECLARE
  couleur text;
  patri boolean;
  BEGIN
	SELECT patrimonial INTO patri 
    FROM taxonomie.bib_taxons t 
    LEFT JOIN taxonomie.cor_taxon_attribut cta ON cta.id_taxon = t.id_taxon
    LEFT JOIN taxonomie.bib_attributs a ON a.id_attribut = cta.id_attribut
    WHERE a.nom_attribut = 'patrimonial' AND t.id_taxon = id;
	IF patri = 't' THEN
		IF date_part('year',maxdateobs)=date_part('year',now()) THEN couleur = 'gray';
		ELSE couleur = 'red';
		END IF;
	ELSIF patri = 'f' THEN
		IF date_part('year',maxdateobs)>=date_part('year',now())-3 THEN couleur = 'gray';
		ELSE couleur = 'red';
		END IF;
	ELSE
	return false;	
	END IF;
	return couleur;
  END;
$$;


--
-- Name: insert_fiche_inv(); Type: FUNCTION; Schema: contactinv; Owner: -
--

CREATE FUNCTION insert_fiche_inv() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
macommune character(5);
BEGIN
------- si le pointage est deja dans la BDD alors le trigger retourne null (l'insertion de la ligne est annulée).
IF new.id_inv in (SELECT id_inv FROM contactinv.t_fiches_inv) THEN	
	return null;
ELSE
	new.date_insert= 'now';
	new.date_update= 'now';
-------gestion des infos relatives a la numerisation (srid utilisé et support utilisé : nomade ou web ou autre)
	IF new.saisie_initiale = 'pda' OR new.saisie_initiale = 'nomade' THEN
		new.srid_dessin = 2154;
		new.the_geom_3857 = st_transform(new.the_geom_2154,3857);
	ELSIF new.saisie_initiale = 'web' THEN
		new.srid_dessin = 3857;
		-- attention : pas de creation du geom 2154 car c'est fait par l'application web
	ELSIF new.saisie_initiale ISNULL THEN
		new.srid_dessin = 0;
		-- pas d'info sur le srid utilisé, cas des importations à gérer manuellement. Ne devrait pas exister.
	END IF;
-------gestion des divers control avec attributions des secteurs + communes : dans le cas d'un insert depuis le nomade uniquement via the_geom !!!!
	IF st_isvalid(new.the_geom_2154) = true THEN	-- si la topologie est bonne alors...
		-- on calcul la commune (celle qui contient le plus de zp en surface)...
		SELECT INTO macommune c.insee FROM layers.l_communes c WHERE st_intersects(c.the_geom, new.the_geom_2154);
		new.insee = macommune;
		-- on calcul l'altitude
		new.altitude_sig = layers.f_isolines20(new.the_geom_2154); -- mise à jour de l'altitude sig
		IF new.altitude_saisie IS null OR new.altitude_saisie = -1 THEN-- mis à jour de l'altitude retenue
		    new.altitude_retenue = new.altitude_sig;
		ELSE
		    new.altitude_retenue = new.altitude_saisie;
		END IF;
	ELSE					
		SELECT INTO macommune c.insee FROM layers.l_communes c WHERE st_intersects(c.the_geom, ST_PointFromWKB(st_centroid(Box2D(new.the_geom_2154)),2154));
		new.insee = macommune;
		-- on calcul l'altitude
		new.altitude_sig = layers.f_isolines20(ST_PointFromWKB(st_centroid(Box2D(new.the_geom_2154)),2154)); -- mise à jour de l'altitude sig
		IF new.altitude_saisie IS null OR new.altitude_saisie = -1 THEN-- mis à jour de l'altitude retenue
			new.altitude_retenue = new.altitude_sig;
		ELSE
			new.altitude_retenue = new.altitude_saisie;
		END IF;
	END IF;
	RETURN NEW; 			
END IF;
END;
$$;


--
-- Name: insert_releve_inv(); Type: FUNCTION; Schema: contactinv; Owner: -
--

CREATE FUNCTION insert_releve_inv() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
re integer;
unite integer;
nbobs integer;
line record;
fiche record;
BEGIN
    --récup du cd_ref du taxon pour le stocker en base au moment de l'enregistrement (= conseil inpn)
	SELECT INTO re taxonomie.find_cdref(cd_nom) FROM taxonomie.bib_taxons WHERE id_taxon = new.id_taxon;
	new.cd_ref_origine = re;
    -- MAJ de la table cor_unite_taxon_inv, on commence par récupérer l'unité à partir du pointage (table t_fiches_inv)
	SELECT INTO fiche * FROM contactinv.t_fiches_inv WHERE id_inv = new.id_inv;
	SELECT INTO unite u.id_unite_geo FROM layers.l_unites_geo u WHERE ST_INTERSECTS(fiche.the_geom_2154,u.the_geom);
	--si on est dans une des unités on peut mettre à jour la table cor_unite_taxon_inv, sinon on fait rien
	IF unite>0 THEN
		SELECT INTO line * FROM contactinv.cor_unite_taxon_inv WHERE id_unite_geo = unite AND id_taxon = new.id_taxon;
		--si la ligne existe dans cor_unite_taxon_inv on la supprime
		IF line IS NOT NULL THEN
			DELETE FROM contactinv.cor_unite_taxon_inv WHERE id_unite_geo = unite AND id_taxon = new.id_taxon;
		END IF;
		--on compte le nombre d'enregistrement pour ce taxon dans l'unité
		SELECT INTO nbobs count(*) from synthese.syntheseff s
		JOIN layers.l_unites_geo u ON ST_Intersects(u.the_geom, s.the_geom_2154) AND u.id_unite_geo = unite
		WHERE s.id_taxon = new.id_taxon;
		--on créé ou recréé la ligne
		INSERT INTO contactinv.cor_unite_taxon_inv VALUES(unite,new.id_taxon,fiche.dateobs,contactinv.couleur_taxon(new.id_taxon,fiche.dateobs), nbobs+1);
	END IF;
	RETURN NEW; 			
END;
$$;


--
-- Name: synthese_delete_releve_inv(); Type: FUNCTION; Schema: contactinv; Owner: -
--

CREATE FUNCTION synthese_delete_releve_inv() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    idsource integer;
BEGIN
    
    SELECT INTO idsource id_source FROM synthese.bib_sources  WHERE db_schema='contactinv' AND db_field = 'id_releve_inv' ;
    
    --SUPRESSION EN SYNTHESE
	DELETE FROM synthese.syntheseff WHERE id_source = idsource AND id_fiche_source = old.id_releve_inv::text; 
    RETURN OLD; 
END;
$$;

-- Function: contactinv.synthese_insert_releve_inv()

-- DROP FUNCTION contactinv.synthese_insert_releve_inv();

CREATE OR REPLACE FUNCTION contactinv.synthese_insert_releve_inv()
  RETURNS trigger AS
$$
DECLARE
	fiche RECORD;
	test integer;
	criteresynthese integer;
	mesobservateurs character varying(255);
	unite integer;
	idsource integer;
BEGIN

	--Récupération des données id_source dans la table synthese.bib_sources
	SELECT INTO idsource id_source FROM synthese.bib_sources  WHERE db_schema='contactinv' AND db_field = 'id_releve_inv';
	
	--Récupération des données dans la table t_fiches_inv et de la liste des observateurs
	SELECT INTO fiche * FROM contactinv.t_fiches_inv WHERE id_inv = new.id_inv;
	SELECT INTO criteresynthese id_critere_synthese FROM contactinv.bib_criteres_inv WHERE id_critere_inv = new.id_critere_inv;
	SELECT INTO mesobservateurs o.observateurs FROM contactinv.t_releves_inv r
	JOIN contactinv.t_fiches_inv f ON f.id_inv = r.id_inv
	LEFT JOIN (
                SELECT id_inv, array_to_string(array_agg(r.nom_role || ' ' || r.prenom_role), ', ') AS observateurs 
                FROM contactinv.cor_role_fiche_inv c
                JOIN utilisateurs.t_roles r ON r.id_role = c.id_role
                GROUP BY id_inv
            ) o ON o.id_inv = f.id_inv
	WHERE r.id_releve_inv = new.id_releve_inv;
    
	--On fait le INSERT dans syntheseff
	INSERT INTO synthese.syntheseff (
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
        determinateur,
		altitude_retenue,
		remarques,
		derniere_action,
		supprime,
		the_geom_3857,
		the_geom_2154,
		the_geom_point,
		id_lot,
		id_critere_synthese,
		effectif_total
	)
	VALUES(
	idsource,
	new.id_releve_inv,
	'f'||new.id_inv||'-r'||new.id_releve_inv,
	fiche.id_organisme,
	fiche.id_protocole,
	1,
	new.cd_ref_origine,
	fiche.insee,
	fiche.dateobs,
	mesobservateurs,
    new.determinateur,
	fiche.altitude_retenue,
	new.commentaire,
	'c',
	false,
	fiche.the_geom_3857,
	fiche.the_geom_2154,
	fiche.the_geom_3857,
	fiche.id_lot,
	criteresynthese,
	new.am+new.af+new.ai+new.na
	);
	RETURN NEW; 			
END;
$$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION contactinv.synthese_insert_releve_inv()
  OWNER TO geonatuser;
GRANT EXECUTE ON FUNCTION contactinv.synthese_insert_releve_inv() TO geonatuser;
GRANT EXECUTE ON FUNCTION contactinv.synthese_insert_releve_inv() TO public;



--
-- Name: synthese_update_cor_role_fiche_inv(); Type: FUNCTION; Schema: contactinv; Owner: -
--

CREATE FUNCTION synthese_update_cor_role_fiche_inv() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
	releves RECORD;
	test integer;
	mesobservateurs character varying(255);
    idsource integer;
BEGIN
	--
	--CE TRIGGER NE DEVRAIT SERVIR QU'EN CAS DE MISE A JOUR MANUELLE SUR CETTE TABLE cor_role_fiche_inv
	--L'APPLI WEB ET LE PDA NE FONT QUE DES INSERTS QUI SONT GERER PAR LE TRIGGER INSERT DE t_releves_inv
	--
    
	--Récupération des données id_source dans la table synthese.bib_sources
	SELECT INTO idsource id_source FROM synthese.bib_sources  WHERE db_schema='contactinv' AND db_field = 'id_releve_inv';
    
	--Récupération des enregistrements de la table t_releves_inv avec l'id_inv de la table cor_role_fiche_inv
	FOR releves IN SELECT * FROM contactinv.t_releves_inv WHERE id_inv = new.id_inv LOOP
		--test si on a bien l'enregistrement dans la table syntheseff avant de le mettre à jour
		SELECT INTO test id_fiche_source FROM synthese.syntheseff WHERE id_source = idsource AND id_fiche_source = releves.id_releve_inv::text;
		IF test ISNULL THEN
		RETURN null;
		ELSE
			SELECT INTO mesobservateurs o.observateurs FROM contactinv.t_releves_inv r
			JOIN contactinv.t_fiches_inv f ON f.id_inv = r.id_inv
			LEFT JOIN (
				SELECT id_inv, array_to_string(array_agg(r.nom_role || ' ' || r.prenom_role), ', ') AS observateurs 
				FROM contactinv.cor_role_fiche_inv c
				JOIN utilisateurs.t_roles r ON r.id_role = c.id_role
				GROUP BY id_inv
			) o ON o.id_inv = f.id_inv
			WHERE r.id_releve_inv = releves.id_releve_inv;
			--mise à jour de l'enregistrement correspondant dans syntheseff ; uniquement le champ observateurs ici
			UPDATE synthese.syntheseff SET
				observateurs = mesobservateurs
			WHERE id_source = idsource AND id_fiche_source = releves.id_releve_inv::text; 
		END IF;
	END LOOP;
	RETURN NEW; 			
END;
$$;


--
-- Name: synthese_update_fiche_inv(); Type: FUNCTION; Schema: contactinv; Owner: -
--

CREATE FUNCTION synthese_update_fiche_inv() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
	releves RECORD;
	test integer;
	mesobservateurs character varying(255);
    idsource integer;
BEGIN

    
	--Récupération des données id_source dans la table synthese.bib_sources
	SELECT INTO idsource id_source FROM synthese.bib_sources  WHERE db_schema='contactinv' AND db_field = 'id_releve_inv';
    
	--Récupération des données de la table t_releves_inv avec l'id_inv de la fiche modifié
	-- Ici on utilise le OLD id_inv pour être sur qu'il existe dans la table synthese (cas improbable où on changerait la pk de la table t_fiches_inv
	--le trigger met à jour avec le NEW --> SET code_fiche_source =  ....
	FOR releves IN SELECT * FROM contactinv.t_releves_inv WHERE id_inv = old.id_inv LOOP
		--test si on a bien l'enregistrement dans la table syntheseff avant de le mettre à jour
		SELECT INTO test id_fiche_source FROM synthese.syntheseff WHERE id_source = idsource AND id_fiche_source = releves.id_releve_inv::text;
		IF test IS NOT NULL THEN
			SELECT INTO mesobservateurs o.observateurs FROM contactinv.t_releves_inv r
			JOIN contactinv.t_fiches_inv f ON f.id_inv = r.id_inv
			LEFT JOIN (
				SELECT id_inv, array_to_string(array_agg(r.nom_role || ' ' || r.prenom_role), ', ') AS observateurs 
				FROM contactinv.cor_role_fiche_inv c
				JOIN utilisateurs.t_roles r ON r.id_role = c.id_role
				GROUP BY id_inv
			) o ON o.id_inv = f.id_inv
			WHERE r.id_releve_inv = releves.id_releve_inv;
            
			IF NOT St_Equals(new.the_geom_3857,old.the_geom_3857) OR NOT St_Equals(new.the_geom_2154,old.the_geom_2154) THEN
			--mise à jour de l'enregistrement correspondant dans syntheseff
				UPDATE synthese.syntheseff SET
					code_fiche_source = 'f'||new.id_inv||'-r'||releves.id_releve_inv,
					id_organisme = new.id_organisme,
					id_protocole = new.id_protocole,
					insee = new.insee,
					dateobs = new.dateobs,
					observateurs = mesobservateurs,
					altitude_retenue = new.altitude_retenue,
					derniere_action = 'u',
					supprime = new.supprime,
					the_geom_3857 = new.the_geom_3857,
					the_geom_2154 = new.the_geom_2154,
					the_geom_point = new.the_geom_3857,
					id_lot = new.id_lot
				WHERE id_source = idsource AND id_fiche_source = releves.id_releve_inv::text;
			ELSE
				UPDATE synthese.syntheseff SET
					code_fiche_source = 'f'||new.id_inv||'-r'||releves.id_releve_inv,
					id_organisme = new.id_organisme,
					id_protocole = new.id_protocole,
					insee = new.insee,
					dateobs = new.dateobs,
					observateurs = mesobservateurs,
					altitude_retenue = new.altitude_retenue,
					derniere_action = 'u',
					supprime = new.supprime,
					the_geom_3857 = new.the_geom_3857,
					the_geom_2154 = new.the_geom_2154,
					the_geom_point = new.the_geom_3857,
					id_lot = new.id_lot
				WHERE id_source = idsource AND id_fiche_source = releves.id_releve_inv::text;
			END IF;
		END IF;
	END LOOP;
	RETURN NEW;
END;
$$;


--
-- Name: synthese_update_releve_inv(); Type: FUNCTION; Schema: contactinv; Owner: -
--

CREATE FUNCTION synthese_update_releve_inv() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
	test integer;
	criteresynthese integer;
	mesobservateurs character varying(255);
    idsource integer;
BEGIN

	--Récupération des données id_source dans la table synthese.bib_sources
	SELECT INTO idsource id_source FROM synthese.bib_sources  WHERE db_schema='contactinv' AND db_field = 'id_releve_inv';
    
	--test si on a bien l'enregistrement dans la table syntheseff avant de le mettre à jour
	SELECT INTO test id_fiche_source FROM synthese.syntheseff WHERE id_source = idsource AND id_fiche_source = old.id_releve_inv::text;
	IF test IS NOT NULL THEN
		--Récupération des données dans la table t_fiches_inv et de la liste des observateurs
		SELECT INTO criteresynthese id_critere_synthese FROM contactinv.bib_criteres_inv WHERE id_critere_inv = new.id_critere_inv;

		--mise à jour de l'enregistrement correspondant dans syntheseff
		UPDATE synthese.syntheseff SET
			id_fiche_source = new.id_releve_inv,
			code_fiche_source = 'f'||new.id_inv||'-r'||new.id_releve_inv,
			cd_nom = new.cd_ref_origine,
			remarques = new.commentaire,
			derniere_action = 'u',
			supprime = new.supprime,
			id_critere_synthese = criteresynthese,
			effectif_total = new.am+new.af+new.ai+new.na
		WHERE id_source = idsource AND id_fiche_source = old.id_releve_inv::text; -- Ici on utilise le OLD id_releve_inv pour être sur 
		--qu'il existe dans la table synthese (cas improbable où on changerait la pk de la table t_releves_inv
		--le trigger met à jour avec le NEW --> SET id_fiche_source = new.id_releve_inv
	END IF;
	RETURN NEW;
END;
$$;


--
-- Name: update_fiche_inv(); Type: FUNCTION; Schema: contactinv; Owner: -
--

CREATE FUNCTION update_fiche_inv() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
macommune character(5);
BEGIN
-------------------------- gestion des infos relatives a la numerisation (srid utilisé et support utilisé : pda ou web ou sig)
-------------------------- attention la saisie sur le web réalise un insert sur qq données mais the_geom_3857 est "faussement inséré" par un update !!!
IF (NOT ST_Equals(new.the_geom_2154,old.the_geom_2154) OR (old.the_geom_2154 is null AND new.the_geom_2154 is NOT NULL))
  OR (NOT ST_Equals(new.the_geom_3857,old.the_geom_3857) OR (old.the_geom_3857 is null AND new.the_geom_3857 is NOT NULL)) 
   THEN
	IF NOT ST_Equals(new.the_geom_3857,old.the_geom_3857) OR (old.the_geom_3857 is null AND new.the_geom_3857 is NOT NULL) THEN
		new.the_geom_2154 = st_transform(new.the_geom_3857,2154);
		new.srid_dessin = 3857;
	ELSIF NOT ST_Equals(new.the_geom_2154,old.the_geom_2154) OR (old.the_geom_2154 is null AND new.the_geom_2154 is NOT NULL) THEN
		new.the_geom_3857 = st_transform(new.the_geom_2154,3857);
		new.srid_dessin = 2154;
	END IF;

-------gestion des divers control avec attributions de la commune : dans le cas d'un insert depuis le nomade uniquement via the_geom_2154 !!!!
	IF st_isvalid(new.the_geom_2154) = true THEN	-- si la topologie est bonne alors...
		-- on calcul la commune (celle qui contient le plus de zp en surface)...
		SELECT INTO macommune c.insee FROM layers.l_communes c WHERE st_intersects(c.the_geom, new.the_geom_2154);
		new.insee = macommune;
		-- on calcul l'altitude
		new.altitude_sig = layers.f_isolines20(new.the_geom_2154); -- mise à jour de l'altitude sig
		IF new.altitude_saisie IS null OR new.altitude_saisie = -1 THEN-- mis à jour de l'altitude retenue
		    new.altitude_retenue = new.altitude_sig;
		ELSE
		    new.altitude_retenue = new.altitude_saisie;
		END IF;
	ELSE					
		SELECT INTO macommune c.insee FROM layers.l_communes c WHERE st_intersects(c.the_geom, ST_PointFromWKB(st_centroid(Box2D(new.the_geom_2154)),2154));
		new.insee = macommune;
		-- on calcul l'altitude
		new.altitude_sig = layers.f_isolines20(ST_PointFromWKB(st_centroid(Box2D(new.the_geom_2154)),2154)); -- mise à jour de l'altitude sig
		IF new.altitude_saisie IS null OR new.altitude_saisie = -1 THEN-- mis à jour de l'altitude retenue
			new.altitude_retenue = new.altitude_sig;
		ELSE
			new.altitude_retenue = new.altitude_saisie;
		END IF;
	END IF;	
END IF;
-- divers update
IF new.altitude_saisie <> old.altitude_saisie THEN
   new.altitude_retenue = new.altitude_saisie;
END IF;
new.date_update = 'now';
IF new.supprime <> old.supprime THEN	 
  IF new.supprime = 't' THEN
     update contactinv.t_releves_inv set supprime = 't' WHERE id_inv = old.id_inv; 
  END IF;
  IF new.supprime = 'f' THEN
     update contactfaune.t_releves_inv set supprime = 'f' WHERE id_inv = old.id_inv; 
  END IF;
END IF;
RETURN NEW; 
END;
$$;


--
-- Name: update_releve_inv(); Type: FUNCTION; Schema: contactinv; Owner: -
--

CREATE FUNCTION update_releve_inv() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
	re integer;
BEGIN
   -- Si changement de taxon, 
	IF new.id_taxon<>old.id_taxon THEN
	   -- Correction du cd_ref_origine
		SELECT INTO re taxonomie.find_cdref(cd_nom) FROM taxonomie.bib_taxons WHERE id_taxon = new.id_taxon;
		new.cd_ref_origine = re;
	END IF;
RETURN NEW;			
END;
$$;

--:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
-- Début fonctions flore à revoir
--:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
SET search_path = bryophytes, pg_catalog;

--
-- TOC entry 1139 (class 1255 OID 55180)
-- Name: bryophytes_insert(); Type: FUNCTION; Schema: bryophytes; Owner: -
--

CREATE FUNCTION bryophytes_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$

BEGIN

new.date_insert= 'now';	 -- mise a jour de date insert
new.the_geom_2154 = st_transform(new.the_geom_3857,2154);
new.insee = layers.f_insee(new.the_geom_2154);-- mise a jour du code insee
new.altitude_sig = layers.f_isolines20(new.the_geom_2154); -- mise à jour de l'altitude sig


IF new.altitude_saisie is null or new.altitude_saisie = 0 then -- mis à jour de l'altitude retenue
  new.altitude_retenue = new.altitude_sig;
ELSE
  new.altitude_retenue = new.altitude_saisie;
END IF;

RETURN new; -- return new procède à l'insertion de la donnée dans PG avec les nouvelles valeures.			

END;
$$;

--
-- TOC entry 1140 (class 1255 OID 55181)
-- Name: bryophytes_update(); Type: FUNCTION; Schema: bryophytes; Owner: -
--

CREATE FUNCTION bryophytes_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
IF (NOT ST_Equals(new.the_geom_2154,old.the_geom_2154) OR (old.the_geom_2154 is null AND new.the_geom_2154 is NOT NULL))
  OR (NOT ST_Equals(new.the_geom_3857,old.the_geom_3857) OR (old.the_geom_3857 is null AND new.the_geom_3857 is NOT NULL)) 
   THEN

	IF NOT ST_Equals(new.the_geom_3857,old.the_geom_3857) OR (old.the_geom_3857 is null AND new.the_geom_3857 is NOT NULL) THEN
		new.the_geom_2154 = st_transform(new.the_geom_3857,2154);
		new.srid_dessin = 3857;
	ELSIF NOT ST_Equals(new.the_geom_2154,old.the_geom_2154) OR (old.the_geom_2154 is null AND new.the_geom_2154 is NOT NULL) THEN
		new.the_geom_3857 = st_transform(new.the_geom_2154,3857);
		new.srid_dessin = 2154;
	END IF;

        new.insee = layers.f_insee(new.the_geom_2154);-- mise à jour du code insee
        new.altitude_sig = layers.f_isolines20(new.the_geom_2154); --mise à jour de l'altitude_sig

END IF;

IF (new.altitude_saisie <> old.altitude_saisie OR old.altitude_saisie is null OR new.altitude_saisie is null OR old.altitude_saisie=0 OR new.altitude_saisie=0) then  -- mis à jour de l'altitude retenue
	BEGIN
		if new.altitude_saisie is null or new.altitude_saisie = 0 then
			new.altitude_retenue = layers.f_isolines20(new.the_geom_2154);
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
-- TOC entry 1192 (class 1255 OID 55182)
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
-- TOC entry 1196 (class 1255 OID 55183)
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
    SELECT INTO mesobservateurs array_to_string(array_agg(r.prenom_role || ' ' || r.nom_role), ', ') AS observateurs 
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
      the_geom_2154,
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
      fiche.the_geom_2154,
      fiche.the_geom_3857
    );
	
RETURN NEW; 			
END;
$$;

--
-- TOC entry 1197 (class 1255 OID 55184)
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
	SELECT INTO mesobservateurs array_to_string(array_agg(r.prenom_role || ' ' || r.nom_role), ', ') AS observateurs 
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
-- TOC entry 1142 (class 1255 OID 55185)
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
-- TOC entry 1198 (class 1255 OID 55186)
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
            the_geom_2154 = new.the_geom_2154,
            the_geom_point = new.the_geom_3857
        WHERE id_source = 6 AND id_fiche_source = CAST(monreleve.gid AS VARCHAR(25));
    END IF;
END LOOP;
	RETURN NEW; 
END;
$$;

SET search_path = florepatri, pg_catalog;

--
-- TOC entry 1143 (class 1255 OID 55187)
-- Name: delete_synthese_ap(); Type: FUNCTION; Schema: florepatri; Owner: -
--

CREATE FUNCTION delete_synthese_ap() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
--il n'y a pas de trigger delete sur la table t_zprospection parce qu'il un delete cascade dans la fk indexzp de t_apresence
--donc si on supprime la zp, on supprime sa ou ces ap et donc ce trigger sera déclanché et fera le ménage dans la table syntheseff
DECLARE 
    mazp RECORD;
BEGIN
        --on fait le delete dans syntheseff
        DELETE FROM synthese.syntheseff WHERE id_source = 4 AND id_fiche_source = CAST(old.indexap AS VARCHAR(25));
	RETURN old; 			
END;
$$;

--
-- TOC entry 1141 (class 1255 OID 55188)
-- Name: insert_ap(); Type: FUNCTION; Schema: florepatri; Owner: -
--

CREATE FUNCTION insert_ap() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
moncentroide geometry;
BEGIN
------ si l'aire de présence est deja dans la BDD alors le trigger retourne null (l'insertion de la ligne est annulée)
IF new.indexap in (SELECT indexap FROM florepatri.t_apresence) THEN   
	RETURN NULL;    
ELSE
------ gestion de la date insert, la date update prend aussi comme valeur cette premiere date insert
	IF new.date_insert ISNULL THEN 
	new.date_insert='now';
	END IF;
	IF new.date_update ISNULL THEN 
	new.date_update='now';
	END IF;

------ gestion des géometries selon l'outil de saisie :
------ Attention !!! La saisie sur le web réalise un insert sur qq données mais the_geom_3857 est "faussement inséré" par un update !!!
	IF new.the_geom_3857 IS NOT NULL THEN -- saisie web avec the_geom_3857
		new.the_geom_2154 = ST_transform(new.the_geom_3857,2154);
	ELSIF new.the_geom_2154 IS NOT NULL THEN	-- saisie avec outil nomade android avec the_geom_2154
		new.the_geom_3857 = ST_transform(new.the_geom_2154,3857);
	END IF;

------ calcul de validité sur la base d'un double control (sur les deux polygones même si on a un seul champ topo_valid)
------ puis gestion des croisements SIG avec les layers altitude et communes en projection Lambert93

	IF ST_isvalid(new.the_geom_2154) AND ST_isvalid(new.the_geom_3857) THEN
		new.topo_valid = 'true';
		new.insee = layers.f_insee(new.the_geom_2154);-- mise a jour du code insee avec la fonction f_insee
		new.altitude_sig = layers.f_isolines20(new.the_geom_2154); -- mise à jour de l'altitude sig avec la fonction f_isolines20
		IF new.altitude_saisie IS NULL OR new.altitude_saisie = 0 THEN-- mis à jour de l'altitude retenue
			new.altitude_retenue = new.altitude_sig;
		ELSE
			new.altitude_retenue = new.altitude_saisie;
		END IF;
	ELSE
		new.topo_valid = 'false';
		moncentroide = ST_setsrid(ST_centroid(Box2D(new.the_geom_2154)),2154); -- calcul le centroid de la bbox pour les croisements SIG
		new.insee = layers.f_insee(moncentroide);-- mise a jour du code insee
		new.altitude_sig = layers.f_isolines20(moncentroide); -- mise à jour de l'altitude sig
		IF new.altitude_saisie IS NULL OR new.altitude_saisie = 0 THEN-- mis à jour de l'altitude retenue
			new.altitude_retenue = new.altitude_sig;
		ELSE
			new.altitude_retenue = new.altitude_saisie;
		END IF;
	END IF;
----- fin des opérations et return
RETURN NEW;
END IF;
END;
$$;


--
-- TOC entry 1199 (class 1255 OID 55189)
-- Name: insert_synthese_ap(); Type: FUNCTION; Schema: florepatri; Owner: -
--

CREATE FUNCTION insert_synthese_ap() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    fiche RECORD;
    mesobservateurs character varying(255);
    monidprecision integer;
    mongeompoint geometry;
BEGIN
	SELECT INTO fiche * FROM florepatri.t_zprospection WHERE indexzp = new.indexzp;
    --Récupération des données dans la table t_zprospection et de la liste des observateurs	
	SELECT INTO mesobservateurs array_to_string(array_agg(r.prenom_role || ' ' || r.nom_role), ', ') AS observateurs 
    FROM florepatri.cor_zp_obs c
    JOIN utilisateurs.t_roles r ON r.id_role = c.codeobs
    JOIN florepatri.t_zprospection zp ON zp.indexzp = c.indexzp
    WHERE c.indexzp = new.indexzp;
    -- création du geom_point
    IF st_isvalid(new.the_geom_3857) THEN mongeompoint = st_pointonsurface(new.the_geom_3857);
    ELSE mongeompoint = ST_PointFromWKB(st_centroid(Box2D(new.the_geom_3857)),3857);
    END IF;
    -- récupération de la valeur de précision de la géométrie
    IF st_geometrytype(new.the_geom_3857) = 'ST_Point' OR st_geometrytype(new.the_geom_3857) = 'ST_MultiPoint' THEN monidprecision = 1;
    ELSIF st_geometrytype(new.the_geom_3857) = 'ST_LineString' OR st_geometrytype(new.the_geom_3857) = 'ST_MultiLineString' THEN monidprecision = 2;
    ELSIF st_geometrytype(new.the_geom_3857) = 'ST_Polygone' OR st_geometrytype(new.the_geom_3857) = 'ST_MultiPolygon' THEN monidprecision = 3;
    ELSE monidprecision = 12;
    END IF;
    
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
        the_geom_2154,
        the_geom_point
    )
    VALUES( 
        4, 
        new.indexap,
        'zp' || new.indexzp || '-' || 'ap' || new.indexap,
        fiche.id_organisme,
        fiche.id_protocole,
        monidprecision,
        fiche.cd_nom,
        new.insee,
        fiche.dateobs,
        mesobservateurs,
        new.altitude_retenue,
        new.remarques,
        'c',
        new.supprime,
        fiche.id_lot,
        new.the_geom_3857,
        new.the_geom_2154,
        mongeompoint);
	
	RETURN NEW; 			
END;
$$;

--
-- TOC entry 1144 (class 1255 OID 55190)
-- Name: insert_zp(); Type: FUNCTION; Schema: florepatri; Owner: -
--

CREATE FUNCTION insert_zp() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
monsectfp integer;
macommune character(5);
moncentroide geometry;
BEGIN
------ si la zone de prospection est deja dans la BDD alors le trigger retourne null
------ (l'insertion de la ligne est annulée et on passe a la donnée suivante).
IF new.indexzp in (SELECT indexzp FROM florepatri.t_zprospection) THEN
	RETURN NULL;
ELSE
------ gestion de la date insert, la date update prend aussi comme valeur cette premiere date insert
	IF new.date_insert IS NULL THEN 
		new.date_insert='now';
	END IF;
	IF new.date_update IS NULL THEN
		new.date_update='now';
	END IF;

------ gestion de la source des géometries selon l'outil de saisie :
    IF new.saisie_initiale = 'nomade' THEN
		new.srid_dessin = 2154;
		new.the_geom_3857 = st_transform(new.the_geom_2154,3857);
	ELSIF new.saisie_initiale = 'web' THEN
		new.srid_dessin = 3857;
		-- attention : pas de calcul sur les geoemtry car "the_geom_3857" est inseré par le trigger update !!
	ELSIF new.saisie_initiale IS NULL THEN
		new.srid_dessin = 0;
		-- pas d'info sur le srid utilisé, cas possible des importations de couches SIG, il faudra gérer manuellement !
	END IF;

	------ début de calcul de validité sur la base d'un double control (sur les deux polygones même si on a un seul champ topo_valid)
	------ puis calcul du geom_point_3857 (selon validité de the_geom_3857)
	------ puis gestion des croisements SIG avec les layers secteur et communes en projection Lambert93
		IF ST_isvalid(new.the_geom_2154) AND ST_isvalid(new.the_geom_3857) THEN
			new.topo_valid = 'true';
			-- calcul du geom_point_3857 
			new.geom_point_3857 = ST_pointonsurface(new.the_geom_3857);  -- calcul du point pour le premier niveau de zoom appli web
			-- croisement secteur (celui qui contient le plus de zp en surface)
			SELECT INTO monsectfp ls.id_secteur FROM layers.l_secteurs ls WHERE ST_intersects(ls.the_geom, new.the_geom_2154)
			ORDER BY ST_area(ST_intersection(ls.the_geom, new.the_geom_2154)) DESC LIMIT 1;
			-- croisement commune (celle qui contient le plus de zp en surface)
			SELECT INTO macommune lc.insee FROM layers.l_communes lc WHERE ST_intersects(lc.the_geom, new.the_geom_2154)
			ORDER BY ST_area(ST_intersection(lc.the_geom, new.the_geom_2154)) DESC LIMIT 1;
		ELSE
			new.topo_valid = 'false';
			-- calcul du geom_point_3857
			new.geom_point_3857 = ST_setsrid(ST_centroid(Box2D(new.the_geom_3857)),3857);  -- calcul le centroid de la bbox pour premier niveau de zoom appli web
			moncentroide = ST_setsrid(ST_centroid(Box2D(new.the_geom_2154)),2154); -- calcul le centroid de la bbox pour les croisements SIG
			-- croisement secteur (celui qui contient moncentroide)
			SELECT INTO monsectfp ls.id_secteur FROM layers.l_secteurs ls WHERE ST_intersects(ls.the_geom, moncentroide);
			-- croisement commune (celle qui contient moncentroid)
			SELECT INTO macommune lc.insee FROM layers.l_communes lc WHERE ST_intersects(lc.the_geom, moncentroide);
		END IF;
		new.insee = macommune;
		IF monsectfp IS NULL THEN 		-- suite calcul secteur : si la requete sql renvoit null (cad pas d'intersection donc dessin hors zone)
			new.id_secteur = 999;	-- alors on met 999 (hors zone) en code secteur fp
		ELSE
			new.id_secteur = monsectfp; --sinon on met le code du secteur.
		END IF;

		------ calcul du geom_mixte_3857
		IF ST_area(new.the_geom_3857) <10000 THEN	   -- calcul du point (ou de la surface si > 1 hectare) pour le second niveau de zoom appli web
			new.geom_mixte_3857 = new.geom_point_3857;
		ELSE
			new.geom_mixte_3857 = new.the_geom_3857;
		END IF;
		
	------ fin de calcul

------  fin du ELSE et return des valeurs :
	RETURN NEW;
END IF;
END;
$$;

--
-- TOC entry 1201 (class 1255 OID 55191)
-- Name: letypedegeom(public.geometry); Type: FUNCTION; Schema: florepatri; Owner: -
--

CREATE FUNCTION letypedegeom(mongeom public.geometry) RETURNS character varying
    LANGUAGE plpgsql
    AS $$

declare
thetype varchar(18);
montype varchar(15);

BEGIN
select st_geometrytype(mongeom) into thetype;
select
	case 	when thetype= 'ST_Polygon'  then 'Polygon'
		when thetype= 'ST_MultiPolygon' then 'Polygon'
		when thetype= 'ST_LineString' then 'LineString'
		when thetype= 'ST_MultiLineString' then 'LineString'
		when thetype= 'ST_Point' then 'Point'
		when thetype= 'ST_MultiPoint' then 'Point'
		into montype
	end;
return montype;

END;
$$;

--
-- TOC entry 1202 (class 1255 OID 55193)
-- Name: update_ap(); Type: FUNCTION; Schema: florepatri; Owner: -
--

CREATE FUNCTION update_ap() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
moncentroide geometry;
BEGIN
------ gestion de la date update en cas de manip sql directement en base ou via l'appli web 
	--IF new.date_update IS NULL THEN
		new.date_update='now';
	--END IF;

-----------------------------------------------------------------------------------------------------------------
/*  section en attente : 
on pourrait verifier le changement des 3 geom pour lancer les commandes de geometries
car pour le moment on ne gere pas les 2 cas de changement sur le geom 2154 ou the geom
code ci dessous a revoir car ST_equals ne marche pas avec les objets invalid

IF 
    (NOT ST_Equals(new.the_geom_2154,old.the_geom_2154) OR (old.the_geom_2154 IS null AND new.the_geom_2154 IS NOT NULL))
    OR (NOT ST_Equals(new.the_geom_3857,old.the_geom_3857)OR (old.the_geom_3857 IS null AND new.the_geom_3857 IS NOT NULL)) 
THEN
    IF NOT ST_Equals(new.the_geom_3857,old.the_geom_3857) OR (old.the_geom_3857 IS null AND new.the_geom_3857 IS NOT NULL) THEN
		new.the_geom_2154 = st_transform(new.the_geom_3857,2154);
	ELSIF NOT ST_Equals(new.the_geom_2154,old.the_geom_2154) OR (old.the_geom_2154 IS null AND new.the_geom_2154 IS NOT NULL) THEN
		new.the_geom_3857 = st_transform(new.the_geom_2154,3857);
	END IF;
puis suite du THEN
fin de section en attente */ 
------------------------------------------------------------------------------------------------------

------ gestion des infos relatives aux géométries
------ ATTENTION : la saisie en web insert quelques données MAIS the_geom_3857 est "inséré" par une commande update !
------ POUR LE MOMENT gestion des update dans l'appli web uniquement à partir du geom 3857
IF ST_NumGeometries(new.the_geom_3857)=1 THEN	-- si le Multi objet renvoyé par le oueb ne contient qu'un objet
	new.the_geom_3857 = ST_GeometryN(new.the_geom_3857, 1); -- alors on passe en objet simple ( multi vers single)
END IF;

new.the_geom_2154 = ST_transform(new.the_geom_3857,2154);

------ calcul de validité sur la base d'un double control (sur les deux polygones même si on a un seul champ topo_valid)
------ puis gestion des croisements SIG avec les layers altitude et communes en projection Lambert93
IF ST_isvalid(new.the_geom_2154) AND ST_isvalid(new.the_geom_3857) THEN
	new.topo_valid = 'true';
	new.insee = layers.f_insee(new.the_geom_2154);				-- mise a jour du code insee avec la fonction f_insee
	new.altitude_sig = layers.f_isolines20(new.the_geom_2154);		-- mise à jour de l'altitude sig avec la fonction f_isolines20
	IF new.altitude_saisie IS NULL OR new.altitude_saisie = 0 THEN	-- mise à jour de l'altitude retenue
		new.altitude_retenue = new.altitude_sig;
	ELSE
		new.altitude_retenue = new.altitude_saisie;
	END IF;
ELSE
	new.topo_valid = 'false';
	moncentroide = ST_setsrid(ST_centroid(Box2D(new.the_geom_2154)),2154); -- calcul le centroid de la bbox pour les croisements SIG
	new.insee = layers.f_insee(moncentroide);
	new.altitude_sig = layers.f_isolines20(moncentroide);
	IF new.altitude_saisie IS NULL OR new.altitude_saisie = 0 THEN
		new.altitude_retenue = new.altitude_sig;
	ELSE
		new.altitude_retenue = new.altitude_saisie;
	END IF;
END IF;
----- fin des opérations et return
RETURN NEW;
END;
$$;

--
-- TOC entry 1206 (class 1255 OID 55194)
-- Name: update_synthese_ap(); Type: FUNCTION; Schema: florepatri; Owner: -
--

CREATE FUNCTION update_synthese_ap() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    monidprecision integer;
    mongeompoint geometry;
BEGIN
--On ne fait qq chose que si l'un des champs de la table t_apresence concerné dans syntheseff a changé
IF (
        new.indexap <> old.indexap 
        OR new.indexzp <> old.indexzp 
        OR ((new.insee <> old.insee) OR (new.insee is null and old.insee is NOT NULL) OR (new.insee is NOT NULL and old.insee is null))
        OR ((new.altitude_retenue <> old.altitude_retenue) OR (new.altitude_retenue is null and old.altitude_retenue is NOT NULL) OR (new.altitude_retenue is NOT NULL and old.altitude_retenue is null))
        OR ((new.remarques <> old.remarques) OR (new.remarques is null and old.remarques is NOT NULL) OR (new.remarques is NOT NULL and old.remarques is null))
        OR new.supprime <> old.supprime 
        OR (NOT ST_EQUALS(new.the_geom_3857,old.the_geom_3857) OR NOT ST_EQUALS(new.the_geom_2154,old.the_geom_2154))
    ) THEN
    -- création du geom_point
    IF st_isvalid(new.the_geom_3857) THEN mongeompoint = st_pointonsurface(new.the_geom_3857);
    ELSE mongeompoint = ST_PointFromWKB(st_centroid(Box2D(new.the_geom_3857)),3857);
    END IF;
    -- récupération de la valeur de précision de la géométrie
    IF st_geometrytype(new.the_geom_3857) = 'ST_Point' OR st_geometrytype(new.the_geom_3857) = 'ST_MultiPoint' THEN monidprecision = 1;
    ELSIF st_geometrytype(new.the_geom_3857) = 'ST_LineString' OR st_geometrytype(new.the_geom_3857) = 'ST_MultiLineString' THEN monidprecision = 2;
    ELSIF st_geometrytype(new.the_geom_3857) = 'ST_Polygone' OR st_geometrytype(new.the_geom_3857) = 'ST_MultiPolygon' THEN monidprecision = 3;
    ELSE monidprecision = 12;
    END IF;
    --on fait le update dans syntheseff
    UPDATE synthese.syntheseff 
	SET 
		id_fiche_source = new.indexap,
		code_fiche_source = 'zp' || new.indexzp || '-' || 'ap' || new.indexap,
		id_precision = monidprecision,
		insee = new.insee,
		altitude_retenue = new.altitude_retenue,
		remarques = new.remarques,
		derniere_action = 'u',
		supprime = new.supprime,
		the_geom_3857 = new.the_geom_3857,
		the_geom_2154 = new.the_geom_2154,
		the_geom_point = mongeompoint
	WHERE id_source = 4 AND id_fiche_source = CAST(old.indexap AS VARCHAR(25));
END IF;

RETURN NEW; 			
END;
$$;

--
-- TOC entry 1146 (class 1255 OID 55195)
-- Name: update_synthese_cor_zp_obs(); Type: FUNCTION; Schema: florepatri; Owner: -
--

CREATE FUNCTION update_synthese_cor_zp_obs() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE 
    mazp RECORD;
    mesobservateurs character varying(255);
BEGIN
    --Récupération de la liste des observateurs	
    --ici on va mettre à jour l'enregistrement dans syntheseff autant de fois qu'on insert dans cette table
	SELECT INTO mesobservateurs array_to_string(array_agg(r.prenom_role || ' ' || r.nom_role), ', ') AS observateurs 
    FROM florepatri.cor_zp_obs c
    JOIN utilisateurs.t_roles r ON r.id_role = c.codeobs
    JOIN florepatri.t_zprospection zp ON zp.indexzp = c.indexzp
    WHERE c.indexzp = new.indexzp;
    --on boucle sur tous les enregistrements de la zp
    --si la zp est sans ap, la boucle ne se fait pas
    FOR mazp IN SELECT ap.indexap FROM florepatri.t_zprospection zp JOIN florepatri.t_apresence ap ON ap.indexzp = zp.indexzp WHERE ap.indexzp = new.indexzp  LOOP
        --on fait le update du champ observateurs dans syntheseff
        UPDATE synthese.syntheseff 
        SET 
            observateurs = mesobservateurs,
            derniere_action = 'u'
        WHERE id_source = 4 AND id_fiche_source = CAST(mazp.indexap AS VARCHAR(25));
    END LOOP;
	RETURN NEW; 			
END;
$$;

--
-- TOC entry 1195 (class 1255 OID 55196)
-- Name: update_synthese_zp(); Type: FUNCTION; Schema: florepatri; Owner: -
--

CREATE FUNCTION update_synthese_zp() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE 
    mazp RECORD;
BEGIN
FOR mazp IN SELECT ap.indexap FROM florepatri.t_zprospection zp JOIN florepatri.t_apresence ap ON ap.indexzp = zp.indexzp WHERE ap.indexzp = new.indexzp  LOOP
    --On ne fait qq chose que si l'un des champs de la table t_zprospection concerné dans syntheseff a changé
    IF (
            new.indexzp <> old.indexzp 
            OR ((new.cd_nom <> old.cd_nom) OR (new.cd_nom is null and old.cd_nom is NOT NULL) OR (new.cd_nom is NOT NULL and old.cd_nom is null))
            OR ((new.id_organisme <> old.id_organisme) OR (new.id_organisme is null and old.id_organisme is NOT NULL) OR (new.id_organisme is NOT NULL and old.id_organisme is null))
            OR ((new.dateobs <> old.dateobs) OR (new.dateobs is null and old.dateobs is NOT NULL) OR (new.dateobs is NOT NULL and old.dateobs is null))
            OR new.supprime <> old.supprime 
        ) THEN
        --on fait le update dans syntheseff
        UPDATE synthese.syntheseff 
        SET 
            code_fiche_source = 'zp' || new.indexzp || '-' || 'ap' || mazp.indexap,
            cd_nom = new.cd_nom,
            id_organisme = new.id_organisme,
            dateobs = new.dateobs,
            derniere_action = 'u',
            supprime = new.supprime
        WHERE id_source = 4 AND id_fiche_source = CAST(mazp.indexap AS VARCHAR(25));
    END IF;
END LOOP;
	RETURN NEW; 			
END;
$$;

--
-- TOC entry 1157 (class 1255 OID 55197)
-- Name: update_zp(); Type: FUNCTION; Schema: florepatri; Owner: -
--

CREATE FUNCTION update_zp() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
monsectfp integer;
macommune character(5);
moncentroide geometry;
BEGIN
------ gestion de la date update en cas de manip sql directement en base
	--IF new.date_update IS NULL THEN
		new.date_update='now';
	--END IF;
------ update en cas de passage du champ supprime = TRUE, alors on passe les aires de présence en supprime = TRUE
IF new.supprime = 't' THEN
	UPDATE florepatri.t_apresence SET supprime = 't' WHERE indexzp = old.indexzp; 
END IF;

-----------------------------------------------------------------------------------------------------------------
/*  section en attente : 
on pourrait verifier le changement des 3 geom pour lancer les commandes de geometries
car pour le moment on ne gere pas les 2 cas de changement sur le geom 2154 ou the geom
code ci dessous a revoir car ST_equals ne marche pas avec les objets invalid
 -- on verfie si 1 des 3 geom a changé
IF((old.the_geom_3857 is null AND new.the_geom_3857 is NOT NULL) OR NOT ST_Equals(new.the_geom_3857,old.the_geom_3857))
OR ((old.the_geom_2154 is null AND new.the_geom_2154 is NOT NULL) OR NOT ST_Equals(new.the_geom_2154,old.the_geom_2154)) THEN

-- si oui on regarde lequel et on repercute les modif :
	IF (old.the_geom_3857 is null AND new.the_geom_3857 is NOT NULL) OR NOT ST_Equals(new.the_geom_3857,old.the_geom_3857) THEN
		-- verif si on est en multipolygon ou pas : A FAIRE !!!!!!!!!!!!!!!!!!!!!!!!!!!!!
		new.the_geom_2154 = ST_transform(new.the_geom_3857,2154);
		new.srid_dessin = 3857;	
	ELSIF (old.the_geom_2154 is null AND new.the_geom_2154 is NOT NULL) OR NOT ST_Equals(new.the_geom_2154,old.the_geom_2154) THEN
		new.the_geom_3857 = ST_transform(new.the_geom_2154,3857);
		new.srid_dessin = 2154;
	END IF;
puis suite du THEN...
fin de section en attente */ 
------------------------------------------------------------------------------------------------------

------ gestion des infos relatives aux géométries
------ ATTENTION : la saisie en web insert quelques données MAIS the_geom_3857 est "faussement inséré" par une commande update !
------ POUR LE MOMENT gestion des update dans l'appli web uniquement à partir du geom 3857

IF ST_NumGeometries(new.the_geom_3857)=1 THEN	-- si le Multi objet renvoyé par le oueb ne contient qu'un objet
	new.the_geom_3857 = ST_GeometryN(new.the_geom_3857, 1); -- alors on passe en objet simple ( multi vers single)
END IF;

new.the_geom_2154 = ST_transform(new.the_geom_3857,2154);
new.srid_dessin = 3857;

------ 2) puis on calcul la validité des geom + on refait les calcul du geom_point_3857 + on refait les croisements SIG secteurs + communes
------    c'est la même chose que lors d'un INSERT ( cf trigger insert_zp)
IF ST_isvalid(new.the_geom_2154) AND ST_isvalid(new.the_geom_3857) THEN
	new.topo_valid = 'true';
	-- calcul du geom_point_3857 
	new.geom_point_3857 = ST_pointonsurface(new.the_geom_3857);  -- calcul du point pour le premier niveau de zoom appli web
	-- croisement secteur (celui qui contient le plus de zp en surface)
	SELECT INTO monsectfp ls.id_secteur FROM layers.l_secteurs ls WHERE ST_intersects(ls.the_geom, new.the_geom_2154)
	ORDER BY ST_area(ST_intersection(ls.the_geom, new.the_geom_2154)) DESC LIMIT 1;
	-- croisement commune (celle qui contient le plus de zp en surface)
	SELECT INTO macommune lc.insee FROM layers.l_communes lc WHERE ST_intersects(lc.the_geom, new.the_geom_2154)
	ORDER BY ST_area(ST_intersection(lc.the_geom, new.the_geom_2154)) DESC LIMIT 1;
ELSE
	new.topo_valid = 'false';
	-- calcul du geom_point_3857
	new.geom_point_3857 = ST_setsrid(ST_centroid(Box2D(new.the_geom_3857)),3857);  -- calcul le centroid de la bbox pour premier niveau de zoom appli web
	moncentroide = ST_setsrid(ST_centroid(Box2D(new.the_geom_2154)),2154); -- calcul le centroid de la bbox pour les croisements SIG
	-- croisement secteur (celui qui contient moncentroide)
	SELECT INTO monsectfp ls.id_secteur FROM layers.l_secteurs ls WHERE ST_intersects(ls.the_geom, moncentroide);
	-- croisement commune (celle qui contient moncentroid)
	SELECT INTO macommune lc.insee FROM layers.l_communes lc WHERE ST_intersects(lc.the_geom, moncentroide);
	END IF;
	new.insee = macommune;
	IF monsectfp IS NULL THEN 		-- suite calcul secteur : si la requete sql renvoit null (cad pas d'intersection donc dessin hors zone)
		new.id_secteur = 999;	-- alors on met 999 (hors zone) en code secteur fp
	ELSE
		new.id_secteur = monsectfp; --sinon on met le code du secteur.
END IF;

------ 3) puis calcul du geom_mixte_3857
------    c'est la même chose que lors d'un INSERT ( cf trigger insert_zp)
IF ST_area(new.the_geom_3857) <10000 THEN	   -- calcul du point (ou de la surface si > 1 hectare) pour le second niveau de zoom appli web
	new.geom_mixte_3857 = new.geom_point_3857;
ELSE
	new.geom_mixte_3857 = new.the_geom_3857;
END IF;
------  fin du IF pour les traitemenst sur les geometries

------  fin du trigger et return des valeurs :
	RETURN NEW;
END;
$$;

SET search_path = florestation, pg_catalog;

--
-- TOC entry 1149 (class 1255 OID 55199)
-- Name: application_rang_sp(integer); Type: FUNCTION; Schema: florestation; Owner: -
--

CREATE FUNCTION application_rang_sp(id integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
--fonction permettant de renvoyer le cd_ref au rang espèce d'une sous-espèce, une variété ou une convariété à partir de son cd_nom
--si le cd_nom passé est d'un rang espèce ou supérieur (genre, famille...), la fonction renvoie le cd_ref du même rang que le cd_nom passé en entré
--
--Gil DELUERMOZ septembre 2011

  DECLARE
  rang character(4);
  rangsup character(4);
  ref integer;
  sup integer;
  BEGIN
	SELECT INTO rang id_rang FROM taxonomie.taxref WHERE cd_nom = id;
	IF(rang='SSES' OR rang = 'VAR' OR rang = 'CVAR') THEN
	    IF(rang = 'SSES') THEN
		SELECT INTO ref cd_taxsup FROM taxonomie.taxref WHERE cd_nom = id;
	    END IF;
	    
	    IF(rang = 'VAR' OR rang = 'CVAR') THEN
		SELECT INTO sup cd_taxsup FROM taxonomie.taxref WHERE cd_nom = id;
		SELECT INTO rangsup id_rang FROM taxonomie.taxref WHERE cd_nom = sup;
		IF(rangsup = 'ES') THEN
			SELECT INTO ref cd_ref FROM taxonomie.taxref WHERE cd_nom = sup;
		END IF;
		IF(rangsup = 'SSES') THEN
			SELECT INTO ref cd_taxsup FROM taxonomie.taxref WHERE cd_nom = sup;
		END IF;
	    END IF;
	ELSE
	   SELECT INTO ref cd_ref FROM taxonomie.taxref WHERE cd_nom = id;
	END IF;
	return ref;
  END;
$$;

--
-- TOC entry 1154 (class 1255 OID 55200)
-- Name: delete_synthese_cor_fs_taxon(); Type: FUNCTION; Schema: florestation; Owner: -
--

CREATE FUNCTION delete_synthese_cor_fs_taxon() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
--il n'y a pas de trigger delete sur la table t_stations_fs parce qu'il un delete cascade dans la fk id_station de cor_fs_taxon
--donc si on supprime la station, on supprime sa ou ces taxons relevés et donc ce trigger sera déclanché et fera le ménage dans la table syntheseff

BEGIN
        --on fait le delete dans syntheseff
        DELETE FROM synthese.syntheseff WHERE id_source = 5 AND id_fiche_source = CAST(old.gid AS VARCHAR(25));
	RETURN old; 			
END;
$$;

--
-- TOC entry 1203 (class 1255 OID 55201)
-- Name: etiquette_utm(public.geometry); Type: FUNCTION; Schema: florestation; Owner: -
--

CREATE FUNCTION etiquette_utm(mongeom public.geometry) RETURNS character
    LANGUAGE plpgsql
    AS $$
DECLARE
monx char(6);
mony char(7);
monetiquette char(24);
BEGIN
-- on prend le centroid du géom comme ça la fonction marchera avec tous les objets point ligne ou polygon
-- si la longitude en WGS84 degré decimal est < à 6 degrés on est en zone UTM 31
IF ST_x(ST_transform(ST_centroid(mongeom),4326))< 6 then
	monx = CAST(ST_x(ST_transform(ST_centroid(mongeom),32631)) AS integer)as string;
	mony = CAST(ST_y(ST_transform(ST_centroid(mongeom),32631)) AS integer)as string;
	monetiquette = 'UTM31 x:'|| monx || ' y:' || mony;
ELSE
	-- sinon on est en zone UTM 32
	monx = CAST(ST_x(ST_transform(ST_centroid(mongeom),32632)) AS integer)as string;
	mony = CAST(ST_y(ST_transform(ST_centroid(mongeom),32632)) AS integer)as string;
	monetiquette = 'UTM32 x:'|| monx || ' y:' || mony;
END IF;
RETURN monetiquette;
END;
$$;

--
-- TOC entry 1150 (class 1255 OID 55202)
-- Name: florestation_insert(); Type: FUNCTION; Schema: florestation; Owner: -
--

CREATE FUNCTION florestation_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$

BEGIN	
new.date_insert= 'now';	 -- mise a jour de date insert
new.date_update= 'now';	 -- mise a jour de date update
--new.the_geom_2154 = st_transform(new.the_geom_3857,2154);
--new.insee = layers.f_insee(new.the_geom_2154);-- mise a jour du code insee
--new.altitude_sig = layers.f_isolines20(new.the_geom_2154); -- mise à jour de l'altitude sig

--if new.altitude_saisie is null or new.altitude_saisie = 0 then -- mis à jour de l'altitude retenue
  --new.altitude_retenue = new.altitude_sig;
--else
  --new.altitude_retenue = new.altitude_saisie;
--end if;

return new; -- return new procède à l'insertion de la donnée dans PG avec les nouvelles valeures.			

END;
$$;

--
-- TOC entry 1155 (class 1255 OID 55203)
-- Name: florestation_update(); Type: FUNCTION; Schema: florestation; Owner: -
--















CREATE FUNCTION florestation_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
--si aucun geom n'existait et qu'au moins un geom est ajouté, on créé les 2 geom
IF (old.the_geom_2154 is null AND old.the_geom_3857 is null) THEN
    IF (new.the_geom_2154 is NOT NULL) THEN
        new.the_geom_3857 = st_transform(new.the_geom_2154,3857);
		new.srid_dessin = 2154;
    END IF;
    IF (new.the_geom_3857 is NOT NULL) THEN
        new.the_geom_2154 = st_transform(new.the_geom_3857,2154);
		new.srid_dessin = 3857;
    END IF;
    -- on calcul la commune...
    new.insee = layers.f_insee(new.the_geom_2154);-- mise à jour du code insee
    -- on calcul l'altitude
    new.altitude_sig = layers.f_isolines20(new.the_geom_2154); -- mise à jour de l'altitude sig
    IF new.altitude_saisie IS null OR new.altitude_saisie = -1 THEN-- mis à jour de l'altitude retenue
        new.altitude_retenue = new.altitude_sig;
    ELSE
        new.altitude_retenue = new.altitude_saisie;
    END IF;
END IF;
--si au moins un geom existait et qu'il a changé on fait une mise à jour
IF (old.the_geom_2154 is NOT NULL OR old.the_geom_3857 is NOT NULL) THEN
    --si c'est le 2154 qui existait on teste s'il a changé
    IF (old.the_geom_2154 is NOT NULL AND new.the_geom_2154 is NOT NULL) THEN
        IF NOT ST_Equals(new.the_geom_2154,old.the_geom_2154) THEN
            new.the_geom_3857 = st_transform(new.the_geom_2154,3857);
            new.srid_dessin = 2154;
        END IF;
    END IF;
    --si c'est le 3857 qui existait on teste s'il a changé
    IF (old.the_geom_3857 is NOT NULL AND new.the_geom_3857 is NOT NULL) THEN
        IF NOT ST_Equals(new.the_geom_3857,old.the_geom_3857) THEN
            new.the_geom_2154 = st_transform(new.the_geom_3857,2154);
            new.srid_dessin = 3857;
        END IF;
    END IF;
    -- on calcul la commune...
    new.insee = layers.f_insee(new.the_geom_2154);-- mise à jour du code insee
    -- on calcul l'altitude
    new.altitude_sig = layers.f_isolines20(new.the_geom_2154); -- mise à jour de l'altitude sig
    IF new.altitude_saisie IS null OR new.altitude_saisie = -1 THEN-- mis à jour de l'altitude retenue
        new.altitude_retenue = new.altitude_sig;
    ELSE
        new.altitude_retenue = new.altitude_saisie;
    END IF;
END IF;

IF (new.altitude_saisie <> old.altitude_saisie OR old.altitude_saisie is null OR new.altitude_saisie is null OR old.altitude_saisie=0 OR new.altitude_saisie=0) then  -- mis à jour de l'altitude retenue
	BEGIN
		if new.altitude_saisie is null or new.altitude_saisie = 0 then
			new.altitude_retenue = layers.f_isolines20(new.the_geom_2154);
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
-- TOC entry 1204 (class 1255 OID 55204)
-- Name: insert_synthese_cor_fs_taxon(); Type: FUNCTION; Schema: florestation; Owner: -
--

CREATE FUNCTION insert_synthese_cor_fs_taxon() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    fiche RECORD;
    mesobservateurs character varying(255);
BEGIN
    SELECT INTO fiche * FROM florestation.t_stations_fs WHERE id_station = new.id_station;
    --Récupération des données dans la table t_zprospection et de la liste des observateurs	
    SELECT INTO mesobservateurs array_to_string(array_agg(r.prenom_role || ' ' || r.nom_role), ', ') AS observateurs 
    FROM florestation.cor_fs_observateur c
    JOIN utilisateurs.t_roles r ON r.id_role = c.id_role
    JOIN florestation.t_stations_fs s ON s.id_station = c.id_station
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
      the_geom_2154,
      the_geom_point
    )
    VALUES
    ( 
      5, 
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
      fiche.the_geom_2154,
      fiche.the_geom_3857
    );
	
RETURN NEW; 			
END;
$$;

--
-- TOC entry 1163 (class 1255 OID 55205)
-- Name: update_synthese_cor_fs_observateur(); Type: FUNCTION; Schema: florestation; Owner: -
--

CREATE FUNCTION update_synthese_cor_fs_observateur() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE 
    monreleve RECORD;
    mesobservateurs character varying(255);
BEGIN
    --Récupération de la liste des observateurs	
    --ici on va mettre à jour l'enregistrement dans syntheseff autant de fois qu'on insert dans cette table
	SELECT INTO mesobservateurs array_to_string(array_agg(r.prenom_role || ' ' || r.nom_role), ', ') AS observateurs 
    FROM florestation.cor_fs_observateur c
    JOIN utilisateurs.t_roles r ON r.id_role = c.id_role
    JOIN florestation.t_stations_fs s ON s.id_station = c.id_station
    WHERE c.id_station = new.id_station;
    --on boucle sur tous les enregistrements de la station
    FOR monreleve IN SELECT gid FROM florestation.cor_fs_taxon WHERE id_station = new.id_station  LOOP
        --on fait le update du champ observateurs dans syntheseff
        UPDATE synthese.syntheseff 
        SET 
            observateurs = mesobservateurs,
            derniere_action = 'u'
        WHERE id_source = 5 AND id_fiche_source = CAST(monreleve.gid AS VARCHAR(25));
    END LOOP;
	RETURN NEW; 			
END;
$$;

--
-- TOC entry 1164 (class 1255 OID 55206)
-- Name: update_synthese_cor_fs_taxon(); Type: FUNCTION; Schema: florestation; Owner: -
--

CREATE FUNCTION update_synthese_cor_fs_taxon() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
--On ne fait qq chose que si l'un des champs de la table cor_fs_taxon concerné dans syntheseff a changé
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
    WHERE id_source = 5 AND id_fiche_source = CAST(old.gid AS VARCHAR(25));
END IF;

RETURN NEW; 			
END;
$$;

--
-- TOC entry 1205 (class 1255 OID 55207)
-- Name: update_synthese_stations_fs(); Type: FUNCTION; Schema: florestation; Owner: -
--

CREATE FUNCTION update_synthese_stations_fs() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE 
    monreleve RECORD;
BEGIN
FOR monreleve IN SELECT gid, cd_nom FROM florestation.cor_fs_taxon WHERE id_station = new.id_station  LOOP
    --On ne fait qq chose que si l'un des champs de la table t_stations_fs concerné dans syntheseff a changé
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
            the_geom_2154 = new.the_geom_2154,
            the_geom_point = new.the_geom_3857
        WHERE id_source = 5 AND id_fiche_source = CAST(monreleve.gid AS VARCHAR(25));
    END IF;
END LOOP;
	RETURN NEW; 
END;
$$;

--:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
-- FIN fonctions flore à revoir
--:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::


SET search_path = layers, pg_catalog;

--
-- Name: f_dist_maille_commune(public.geometry, character); Type: FUNCTION; Schema: layers; Owner: -
--

CREATE FUNCTION f_dist_maille_commune(mon_geom public.geometry, mon_insee character) RETURNS real
    LANGUAGE plpgsql
    AS $$
DECLARE
ma_distance real;
ma_commune geometry;
BEGIN
-- vérif si le code insee saisi est bien dans la couche commune
IF mon_insee IN (SELECT insee FROM layers.l_communes) THEN
	-- calcul la distance entre la maille et la commune (vérifie d'abord si la maille intersect la commune)
	SELECT INTO ma_commune lc.the_geom FROM layers.l_communes lc WHERE lc.insee = mon_insee;
	IF ST_Intersects(mon_geom, ma_commune) THEN
		  RETURN  0;		-- on est bon la maille est dans la commune saisie a la main
	ELSE
		 SELECT INTO ma_distance ST_Distance(mon_geom, ma_commune);
		 RETURN ma_distance;
	END IF;
ELSE
	RETURN  -1; -- le code insee saisi est mauvais
END IF;

END
$$;


--
-- Name: f_insee(public.geometry); Type: FUNCTION; Schema: layers; Owner: -
--

CREATE FUNCTION f_insee(mongeom public.geometry) RETURNS character
    LANGUAGE plpgsql
    AS $$
DECLARE
mavariableinsee char(5);
BEGIN

select insee into mavariableinsee from 
layers.l_communes c where st_intersects(c.the_geom, mongeom)= true;

if mavariableinsee ISNULL then
	return null;
else
	return mavariableinsee; 
end if;

END
$$;


--
-- Name: f_isolines20(public.geometry); Type: FUNCTION; Schema: layers; Owner: -
--

CREATE FUNCTION f_isolines20(mongeom public.geometry) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
mavariableiso integer;
BEGIN
select iso into mavariableiso from 
(
select i.iso, st_distance(mongeom, i.the_geom) 
from layers.l_isolines20 i
where mongeom&&i.the_geom  -- && renvoit true quand la bouding box de mon geom intersect la bounding box d'isolines20
order by st_distance asc limit 1
) SR;

if mavariableiso ISNULL then 	
	return  0;
else
	return mavariableiso; 
end if;

END
$$;


--
-- Name: f_nomcommune(public.geometry); Type: FUNCTION; Schema: layers; Owner: -
--

CREATE FUNCTION f_nomcommune(mongeom public.geometry) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
DECLARE
macommmune character varying(40);
BEGIN

select commune_min into macommmune from 
layers.l_communes c where st_intersects(c.the_geom, mongeom)= true;

if macommmune ISNULL then
	return null;
else
	return macommmune; 
end if;

END
$$;


SET search_path = synthese, pg_catalog;

--
-- Name: calcul_cor_unite_taxon_cf(integer, integer); Type: FUNCTION; Schema: synthese; Owner: -
--

CREATE FUNCTION calcul_cor_unite_taxon_cf(monidtaxon integer, monunite integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
  BEGIN
	DELETE FROM contactfaune.cor_unite_taxon WHERE id_unite_geo = monunite AND id_taxon = monidtaxon;
	INSERT INTO contactfaune.cor_unite_taxon (id_unite_geo,id_taxon,derniere_date,couleur,nb_obs)
	SELECT monunite, monidtaxon,  max(dateobs) AS derniere_date, contactfaune.couleur_taxon(monidtaxon,max(dateobs)) AS couleur, count(id_synthese) AS nb_obs
	FROM synthese.cor_unite_synthese
	WHERE id_taxon = monidtaxon
	AND id_unite_geo = monunite;
  END;
$$;


--
-- Name: calcul_cor_unite_taxon_inv(integer, integer); Type: FUNCTION; Schema: synthese; Owner: -
--

CREATE FUNCTION calcul_cor_unite_taxon_inv(monidtaxon integer, monunite integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
	DELETE FROM contactinv.cor_unite_taxon_inv WHERE id_unite_geo = monunite AND id_taxon = monidtaxon;
	INSERT INTO contactinv.cor_unite_taxon_inv (id_unite_geo,id_taxon,derniere_date,couleur,nb_obs)
	SELECT monunite, monidtaxon,  max(dateobs) AS derniere_date, contactinv.couleur_taxon(monidtaxon,max(dateobs)) AS couleur, count(id_synthese) AS nb_obs
	FROM synthese.cor_unite_synthese
	WHERE id_taxon = monidtaxon
	AND id_unite_geo = monunite;
END;
$$;


--
-- Name: insert_syntheseff(); Type: FUNCTION; Schema: synthese; Owner: -
--

CREATE FUNCTION insert_syntheseff() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	new.date_insert= 'now';
	new.date_update= 'now';
	RETURN NEW; 			
END;
$$;


--
-- Name: maj_cor_unite_synthese(); Type: FUNCTION; Schema: synthese; Owner: -
--

CREATE FUNCTION maj_cor_unite_synthese() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
-- apres travail dans la table synthèsefaune on supprime la donnée correspondante dans la table cor_unite_synthese
IF (TG_OP = 'DELETE') or (TG_OP = 'UPDATE') THEN
	DELETE FROM synthese.cor_unite_synthese WHERE id_synthese = old.id_synthese;
END IF;
-- insert la donnée depuis la table synthèsefaune dans la table cor_unite_synthese :
-- La donnée dans la table synthèsefaune doit etre en supprime = FALSE sinon on ne l'insert pas,
-- S'il n'y a pas d'intersection avec une ou des unité geographique on ne l'insert pas.
IF (TG_OP = 'INSERT') OR (TG_OP = 'UPDATE') THEN
	IF new.supprime = FALSE THEN
		INSERT INTO synthese.cor_unite_synthese (id_synthese, cd_nom, dateobs, id_unite_geo)
		SELECT s.id_synthese, s.cd_nom, s.dateobs,u.id_unite_geo 
        FROM synthese.syntheseff s, layers.l_unites_geo u
		WHERE st_intersects(u.the_geom, s.the_geom_2154) 
		AND s.id_synthese = new.id_synthese;
	END IF;
END IF;	
RETURN NULL;	
END;
$$;


--
-- Name: maj_cor_unite_taxon(); Type: FUNCTION; Schema: synthese; Owner: -
--

CREATE FUNCTION maj_cor_unite_taxon() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
monembranchement integer;
BEGIN
IF (TG_OP = 'DELETE') THEN
	--calcul de l'embranchement du taxon supprimé
		SELECT tx.phylum FROM taxonomie.taxref tx 
		WHERE tx.cd_nom = old.cd_nom;
		-- puis recalul des couleurs avec old.id_unite_geo et old.taxon selon que le taxon est vertébrés (embranchemet 1) ou invertébres
		IF monembranchement = 'Chordata' THEN
			IF (SELECT count(*) FROM synthese.cor_unite_synthese WHERE cd_nom = old.cd_nom AND id_unite_geo = old.id_unite_geo)= 0 THEN
				DELETE FROM contactfaune.cor_unite_taxon WHERE cd_nom = old.cd_nom AND id_unite_geo = old.id_unite_geo;
			ELSE
				PERFORM synthese.calcul_cor_unite_taxon_cf(old.cd_nom, old.id_unite_geo);
			END IF;
		ELSE
			IF (SELECT count(*) FROM synthese.cor_unite_synthese WHERE cd_nom = old.cd_nom AND id_unite_geo = old.id_unite_geo)= 0 THEN
				DELETE FROM contactinv.cor_unite_taxon_inv WHERE cd_nom = old.cd_nom AND id_unite_geo = old.id_unite_geo;
			ELSE
				PERFORM synthese.calcul_cor_unite_taxon_inv(old.cd_nom, old.id_unite_geo);
			END IF;
		END IF;
		RETURN OLD;		
ELSIF (TG_OP = 'INSERT') THEN
	--calcul de l'embranchement du taxon inséré
        SELECT tx.phylum FROM taxonomie.taxref tx 
		WHERE tx.cd_nom = old.cd_nom;
	-- puis recalul des couleurs avec new.id_unite_geo et new.taxon selon que le taxon est vertébrés (embranchemet 1) ou invertébres
        IF monembranchement = 'Chordata' THEN
            PERFORM synthese.calcul_cor_unite_taxon_cf(new.cd_nom, new.id_unite_geo);
        ELSE
            PERFORM synthese.calcul_cor_unite_taxon_inv(new.cd_nom, new.id_unite_geo);
        END IF;
	RETURN NEW;
END IF;
END;
$$;


--
-- Name: maj_cor_zonesstatut_synthese(); Type: FUNCTION; Schema: synthese; Owner: -
--

CREATE FUNCTION maj_cor_zonesstatut_synthese() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
-- apres travail dans la table synthèsefaune on supprime la donnée correspondante dans la table cor_zonesstatut_synthese
IF (TG_OP = 'DELETE') or (TG_OP = 'UPDATE') THEN
	DELETE FROM synthese.cor_zonesstatut_synthese WHERE id_synthese = old.id_synthese;
END IF;
-- insert la donnée depuis la table synthèsefaune dans la table cor_zonesstatut_synthese :
-- La donnée dans la table synthèsefaune doit etre en supprime = FALSE sinon on ne l'insert pas,
-- on calcul la ou les zones à statuts correspondant à la donnée.
-- ces intersections  servent à eviter des intersect lourd en requete spatiale dans l'appli web, ainsi
-- les intersections avec les zones à statut principales sont déja calculées en tables relationelles
IF (TG_OP = 'INSERT') or (TG_OP = 'UPDATE') THEN
	IF new.supprime = FALSE THEN
		INSERT INTO synthese.cor_zonesstatut_synthese (id_zone,id_synthese)
		SELECT z.id_zone,s.id_synthese FROM synthese.syntheseff s, layers.l_zonesstatut z 
		WHERE ST_Intersects(z.the_geom, s.the_geom_2154)
		AND z.id_type IN(1,4,5,6,7,8,9,10,11) -- typologie limitée au coeur, reserve, natura2000 etc...
		AND s.id_synthese = new.id_synthese;
	END IF;
END IF;
RETURN NULL; 
END;
$$;


--
-- Name: update_syntheseff(); Type: FUNCTION; Schema: synthese; Owner: -
--

CREATE FUNCTION update_syntheseff() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	new.date_update= 'now';
	RETURN NEW; 			
END;
$$;


SET search_path = taxonomie, pg_catalog;

--
-- Name: find_cdref(integer); Type: FUNCTION; Schema: taxonomie; Owner: -
--

CREATE FUNCTION find_cdref(id integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
--fonction permettant de renvoyer le cd_ref d'un taxon à partir de son cd_nom
--
--Gil DELUERMOZ septembre 2011

  DECLARE ref integer;
  BEGIN
	SELECT INTO ref cd_ref FROM taxonomie.taxref WHERE cd_nom = id;
	return ref;
  END;
$$;


SET search_path = utilisateurs, pg_catalog;

--
-- Name: modify_date_insert(); Type: FUNCTION; Schema: utilisateurs; Owner: -
--

CREATE FUNCTION modify_date_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.date_insert := now();
    NEW.date_update := now();
    RETURN NEW;
END;
$$;


--
-- Name: modify_date_update(); Type: FUNCTION; Schema: utilisateurs; Owner: -
--

CREATE FUNCTION modify_date_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.date_update := now();
    RETURN NEW;
END;
$$;


SET search_path = contactfaune, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: bib_criteres_cf; Type: TABLE; Schema: contactfaune; Owner: -; Tablespace: 
--

CREATE TABLE bib_criteres_cf (
    id_critere_cf integer NOT NULL,
    code_critere_cf character varying(3),
    nom_critere_cf character varying(90),
    tri_cf integer,
    cincomplet character(2),
    id_critere_synthese integer
);


--
-- Name: bib_messages_cf; Type: TABLE; Schema: contactfaune; Owner: -; Tablespace: 
--

CREATE TABLE bib_messages_cf (
    id_message_cf integer NOT NULL,
    texte_message_cf character varying(255)
);


--
-- Name: cor_critere_groupe; Type: TABLE; Schema: contactfaune; Owner: -; Tablespace: 
--

CREATE TABLE cor_critere_groupe (
    id_critere_cf integer NOT NULL,
    id_groupe integer NOT NULL
);


--
-- Name: cor_message_taxon; Type: TABLE; Schema: contactfaune; Owner: -; Tablespace: 
--

CREATE TABLE cor_message_taxon (
    id_message_cf integer NOT NULL,
    id_taxon integer NOT NULL
);


--
-- Name: cor_role_fiche_cf; Type: TABLE; Schema: contactfaune; Owner: -; Tablespace: 
--

CREATE TABLE cor_role_fiche_cf (
    id_cf bigint NOT NULL,
    id_role integer NOT NULL
);


--
-- Name: cor_unite_taxon; Type: TABLE; Schema: contactfaune; Owner: -; Tablespace: 
--

CREATE TABLE cor_unite_taxon (
    id_unite_geo integer NOT NULL,
    id_taxon integer NOT NULL,
    derniere_date date,
    couleur character varying(10) NOT NULL,
    nb_obs integer
);


--
-- Name: log_colors; Type: TABLE; Schema: contactfaune; Owner: -; Tablespace: 
--

CREATE TABLE log_colors (
    annee integer NOT NULL,
    mois integer NOT NULL,
    id_unite_geo integer NOT NULL,
    couleur character varying NOT NULL,
    nbtaxons numeric,
    nb_data integer
);


--
-- Name: log_colors_day; Type: TABLE; Schema: contactfaune; Owner: -; Tablespace: 
--

CREATE TABLE log_colors_day (
    jour date NOT NULL,
    couleur character varying NOT NULL,
    nbtaxons numeric
);


--
-- Name: t_fiches_cf; Type: TABLE; Schema: contactfaune; Owner: -; Tablespace: 
--

CREATE TABLE t_fiches_cf (
    id_cf bigint NOT NULL,
    insee character(5),
    dateobs date NOT NULL,
    altitude_saisie integer,
    altitude_sig integer,
    altitude_retenue integer,
    date_insert timestamp without time zone,
    date_update timestamp without time zone,
    supprime boolean DEFAULT false NOT NULL,
    pdop double precision,
    saisie_initiale character varying(20),
    id_organisme integer,
    srid_dessin integer,
    id_protocole integer,
    id_lot integer,
    the_geom_3857 public.geometry,
    the_geom_2154 public.geometry,
    CONSTRAINT enforce_dims_the_geom_2154 CHECK ((public.st_ndims(the_geom_2154) = 2)),
    CONSTRAINT enforce_dims_the_geom_3857 CHECK ((public.st_ndims(the_geom_3857) = 2)),
    CONSTRAINT enforce_geotype_the_geom_2154 CHECK (((public.geometrytype(the_geom_2154) = 'POINT'::text) OR (the_geom_2154 IS NULL))),
    CONSTRAINT enforce_geotype_the_geom_3857 CHECK (((public.geometrytype(the_geom_3857) = 'POINT'::text) OR (the_geom_3857 IS NULL))),
    CONSTRAINT enforce_srid_the_geom_2154 CHECK ((public.st_srid(the_geom_2154) = 2154)),
    CONSTRAINT enforce_srid_the_geom_3857 CHECK ((public.st_srid(the_geom_3857) = 3857))
);


--
-- Name: t_releves_cf; Type: TABLE; Schema: contactfaune; Owner: -; Tablespace: 
--

CREATE TABLE t_releves_cf (
    id_releve_cf bigint NOT NULL,
    id_cf bigint NOT NULL,
    id_taxon integer NOT NULL,
    id_critere_cf integer NOT NULL,
    am integer,
    af integer,
    ai integer,
    na integer,
    sai integer,
    jeune integer,
    yearling integer,
    cd_ref_origine integer,
    nom_taxon_saisi character varying(255),
    commentaire text,
    determinateur character varying(255),
    supprime boolean DEFAULT false NOT NULL,
    prelevement boolean DEFAULT false NOT NULL,
    gid integer NOT NULL
);


--
-- Name: t_releves_cf_gid_seq; Type: SEQUENCE; Schema: contactfaune; Owner: -
--

CREATE SEQUENCE t_releves_cf_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: t_releves_cf_gid_seq; Type: SEQUENCE OWNED BY; Schema: contactfaune; Owner: -
--

ALTER SEQUENCE t_releves_cf_gid_seq OWNED BY t_releves_cf.gid;


SET search_path = bryophytes, pg_catalog;

--
-- TOC entry 179 (class 1259 OID 55310)
-- Name: bib_abondances; Type: TABLE; Schema: bryophytes; Owner: -; Tablespace: 
--

CREATE TABLE bib_abondances (
    id_abondance character(1) NOT NULL,
    nom_abondance character varying(128) NOT NULL
);

--
-- TOC entry 180 (class 1259 OID 55313)
-- Name: bib_expositions; Type: TABLE; Schema: bryophytes; Owner: -; Tablespace: 
--

CREATE TABLE bib_expositions (
    id_exposition character(2) NOT NULL,
    nom_exposition character varying(10) NOT NULL,
    tri_exposition integer
);

--
-- TOC entry 181 (class 1259 OID 55316)
-- Name: cor_bryo_observateur; Type: TABLE; Schema: bryophytes; Owner: -; Tablespace: 
--

CREATE TABLE cor_bryo_observateur (
    id_role integer NOT NULL,
    id_station bigint NOT NULL
);

CREATE SEQUENCE cor_bryo_taxon_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
    

--
-- TOC entry 183 (class 1259 OID 55321)
-- Name: cor_bryo_taxon; Type: TABLE; Schema: bryophytes; Owner: -; Tablespace: 
--

CREATE TABLE cor_bryo_taxon (
    id_station bigint NOT NULL,
    cd_nom integer NOT NULL,
    id_abondance character(1),
    taxon_saisi character varying(255),
    supprime boolean DEFAULT false,
    id_station_cd_nom integer NOT NULL,
    gid integer DEFAULT nextval('cor_bryo_taxon_gid_seq'::regclass) NOT NULL
);


--
-- TOC entry 184 (class 1259 OID 55326)
-- Name: cor_bryo_taxon_id_station_cd_nom_seq; Type: SEQUENCE; Schema: bryophytes; Owner: -
--

CREATE SEQUENCE cor_bryo_taxon_id_station_cd_nom_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

--
-- TOC entry 3675 (class 0 OID 0)
-- Dependencies: 184
-- Name: cor_bryo_taxon_id_station_cd_nom_seq; Type: SEQUENCE OWNED BY; Schema: bryophytes; Owner: -
--

ALTER SEQUENCE cor_bryo_taxon_id_station_cd_nom_seq OWNED BY cor_bryo_taxon.id_station_cd_nom;


--
-- TOC entry 185 (class 1259 OID 55328)
-- Name: t_stations_bryo; Type: TABLE; Schema: bryophytes; Owner: -; Tablespace: 
--

CREATE TABLE t_stations_bryo (
    id_station bigint NOT NULL,
    id_exposition character(2) NOT NULL,
    id_support integer NOT NULL,
    id_protocole integer NOT NULL,
    id_lot integer NOT NULL,
    id_organisme integer NOT NULL,
    dateobs date,
    info_acces character varying(255),
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
    the_geom_2154 public.geometry,
    srid_dessin integer,
    the_geom_3857 public.geometry,
    CONSTRAINT enforce_dims_the_geom_2154 CHECK ((public.st_ndims(the_geom_2154) = 2)),
    CONSTRAINT enforce_dims_the_geom_3857 CHECK ((public.st_ndims(the_geom_3857) = 2)),
    CONSTRAINT enforce_geotype_the_geom_2154 CHECK (((public.geometrytype(the_geom_2154) = 'POINT'::text) OR (the_geom_2154 IS NULL))),
    CONSTRAINT enforce_geotype_the_geom_3857 CHECK (((public.geometrytype(the_geom_3857) = 'POINT'::text) OR (the_geom_3857 IS NULL))),
    CONSTRAINT enforce_srid_the_geom_2154 CHECK ((public.st_srid(the_geom_2154) = 2154)),
    CONSTRAINT enforce_srid_the_geom_3857 CHECK ((public.st_srid(the_geom_3857) = 3857))
);


--
-- TOC entry 186 (class 1259 OID 55349)
-- Name: t_stations_bryo_gid_seq; Type: SEQUENCE; Schema: bryophytes; Owner: -
--

CREATE SEQUENCE t_stations_bryo_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

--
-- TOC entry 3676 (class 0 OID 0)
-- Dependencies: 186
-- Name: t_stations_bryo_gid_seq; Type: SEQUENCE OWNED BY; Schema: bryophytes; Owner: -
--

ALTER SEQUENCE t_stations_bryo_gid_seq OWNED BY t_stations_bryo.gid;


SET search_path = florepatri, pg_catalog;

--
-- TOC entry 187 (class 1259 OID 55397)
-- Name: bib_comptages_methodo; Type: TABLE; Schema: florepatri; Owner: -; Tablespace: 
--

CREATE TABLE bib_comptages_methodo (
    id_comptage_methodo integer NOT NULL,
    nom_comptage_methodo character varying(100)
);

--
-- TOC entry 188 (class 1259 OID 55400)
-- Name: bib_frequences_methodo_new; Type: TABLE; Schema: florepatri; Owner: -; Tablespace: 
--

CREATE TABLE bib_frequences_methodo_new (
    id_frequence_methodo_new character(1) NOT NULL,
    nom_frequence_methodo_new character varying(100)
);

--
-- TOC entry 189 (class 1259 OID 55403)
-- Name: bib_pentes; Type: TABLE; Schema: florepatri; Owner: -; Tablespace: 
--

CREATE TABLE bib_pentes (
    id_pente integer NOT NULL,
    val_pente real NOT NULL,
    nom_pente character varying(100)
);

--
-- TOC entry 190 (class 1259 OID 55406)
-- Name: bib_perturbations; Type: TABLE; Schema: florepatri; Owner: -; Tablespace: 
--

CREATE TABLE bib_perturbations (
    codeper smallint NOT NULL,
    classification character varying(30) NOT NULL,
    description character varying(65) NOT NULL
);

--
-- TOC entry 191 (class 1259 OID 55409)
-- Name: bib_phenologies; Type: TABLE; Schema: florepatri; Owner: -; Tablespace: 
--

CREATE TABLE bib_phenologies (
    codepheno smallint NOT NULL,
    pheno character varying(45) NOT NULL
);

--
-- TOC entry 192 (class 1259 OID 55412)
-- Name: bib_physionomies; Type: TABLE; Schema: florepatri; Owner: -; Tablespace: 
--

CREATE TABLE bib_physionomies (
    id_physionomie integer NOT NULL,
    groupe_physionomie character varying(20),
    nom_physionomie character varying(100),
    definition_physionomie text,
    code_physionomie character varying(3)
);

CREATE TABLE bib_rezo_ecrins
(
  id_rezo_ecrins integer NOT NULL,
  nom_rezo_ecrins character varying(100)
);

--
-- TOC entry 194 (class 1259 OID 55421)
-- Name: bib_statuts; Type: TABLE; Schema: florepatri; Owner: -; Tablespace: 
--

CREATE TABLE bib_statuts (
    id_statut integer NOT NULL,
    nom_statut character varying(20) NOT NULL,
    desc_statut text
);

--
-- TOC entry 195 (class 1259 OID 55427)
-- Name: bib_taxons_fp; Type: TABLE; Schema: florepatri; Owner: -; Tablespace: 
--

CREATE TABLE bib_taxons_fp (
    num_nomenclatural bigint NOT NULL,
    francais character varying(100),
    latin character varying(100),
    echelle smallint NOT NULL,
    cd_nom integer NOT NULL,
    nomade_ecrins boolean DEFAULT false NOT NULL
);

--
-- TOC entry 196 (class 1259 OID 55431)
-- Name: cor_ap_perturb; Type: TABLE; Schema: florepatri; Owner: -; Tablespace: 
--

CREATE TABLE cor_ap_perturb (
    indexap bigint NOT NULL,
    codeper smallint NOT NULL
);

--
-- TOC entry 197 (class 1259 OID 55434)
-- Name: cor_ap_physionomie; Type: TABLE; Schema: florepatri; Owner: -; Tablespace: 
--

CREATE TABLE cor_ap_physionomie (
    indexap bigint NOT NULL,
    id_physionomie smallint NOT NULL
);

--
-- TOC entry 198 (class 1259 OID 55437)
-- Name: cor_taxon_statut; Type: TABLE; Schema: florepatri; Owner: -; Tablespace: 
--

CREATE TABLE cor_taxon_statut (
    id_statut integer NOT NULL,
    cd_nom integer NOT NULL
);

--
-- TOC entry 199 (class 1259 OID 55440)
-- Name: cor_zp_obs; Type: TABLE; Schema: florepatri; Owner: -; Tablespace: 
--

CREATE TABLE cor_zp_obs (
    indexzp bigint NOT NULL,
    codeobs integer NOT NULL
);

--
-- TOC entry 200 (class 1259 OID 55443)
-- Name: t_apresence; Type: TABLE; Schema: florepatri; Owner: -; Tablespace: 
--

CREATE TABLE t_apresence (
    indexap bigint NOT NULL,
    codepheno smallint NOT NULL,
    indexzp bigint NOT NULL,
    altitude_saisie smallint,
    surfaceap integer NOT NULL,
    frequenceap real NOT NULL,
    date_insert timestamp without time zone,
    date_update timestamp without time zone,
    topo_valid boolean,
    supprime boolean DEFAULT false NOT NULL,
    erreur_signalee boolean DEFAULT false,
    altitude_sig integer DEFAULT 0,
    altitude_retenue integer DEFAULT 0,
    insee character(5),
    id_frequence_methodo_new character(1) NOT NULL,
    nb_transects_frequence integer DEFAULT 0,
    nb_points_frequence integer DEFAULT 0,
    nb_contacts_frequence integer DEFAULT 0,
    id_comptage_methodo integer NOT NULL,
    nb_placettes_comptage integer,
    surface_placette_comptage real,
    remarques text,
    the_geom_2154 public.geometry,
    the_geom_3857 public.geometry,
    longueur_pas numeric(10,2),
    effectif_placettes_steriles integer,
    effectif_placettes_fertiles integer,
    total_steriles integer,
    total_fertiles integer,
    CONSTRAINT enforce_dims_the_geom_2154 CHECK ((public.st_ndims(the_geom_2154) = 2)),
    CONSTRAINT enforce_dims_the_geom_3857 CHECK ((public.st_ndims(the_geom_3857) = 2)),
    CONSTRAINT enforce_srid_the_geom_2154 CHECK ((public.st_srid(the_geom_2154) = 2154)),
    CONSTRAINT enforce_srid_the_geom_3857 CHECK ((public.st_srid(the_geom_3857) = 3857))
);

--
-- TOC entry 201 (class 1259 OID 55462)
-- Name: t_zprospection; Type: TABLE; Schema: florepatri; Owner: -; Tablespace: 
--

CREATE TABLE t_zprospection (
    indexzp bigint NOT NULL,
    id_secteur integer NOT NULL,
    id_protocole integer NOT NULL,
    id_lot integer NOT NULL,
    id_organisme integer NOT NULL,
    dateobs date NOT NULL,
    date_insert timestamp without time zone,
    date_update timestamp without time zone,
    validation boolean DEFAULT false,
    topo_valid boolean,
    erreur_signalee boolean DEFAULT false,
    supprime boolean DEFAULT false NOT NULL,
    cd_nom integer,
    saisie_initiale character varying(20),
    insee character(5),
    taxon_saisi character varying(100),
    the_geom_2154 public.geometry,
    geom_point_3857 public.geometry,
    geom_mixte_3857 public.geometry,
    srid_dessin integer,
    the_geom_3857 public.geometry,
    id_rezo_ecrins integer DEFAULT 0 NOT NULL,
    CONSTRAINT enforce_dims_geom_mixte_3857 CHECK ((public.st_ndims(geom_mixte_3857) = 2)),
    CONSTRAINT enforce_dims_geom_point_3857 CHECK ((public.st_ndims(geom_point_3857) = 2)),
    CONSTRAINT enforce_dims_the_geom_2154 CHECK ((public.st_ndims(the_geom_2154) = 2)),
    CONSTRAINT enforce_dims_the_geom_3857 CHECK ((public.st_ndims(the_geom_3857) = 2)),
    CONSTRAINT enforce_geotype_geom_point_3857 CHECK (((public.geometrytype(geom_point_3857) = 'POINT'::text) OR (geom_point_3857 IS NULL))),
    CONSTRAINT enforce_geotype_the_geom_2154 CHECK (((public.geometrytype(the_geom_2154) = 'POLYGON'::text) OR (the_geom_2154 IS NULL))),
    CONSTRAINT enforce_geotype_the_geom_3857 CHECK (((public.geometrytype(the_geom_3857) = 'POLYGON'::text) OR (the_geom_3857 IS NULL))),
    CONSTRAINT enforce_srid_geom_mixte_3857 CHECK ((public.st_srid(geom_mixte_3857) = 3857)),
    CONSTRAINT enforce_srid_geom_point_3857 CHECK ((public.st_srid(geom_point_3857) = 3857)),
    CONSTRAINT enforce_srid_the_geom_2154 CHECK ((public.st_srid(the_geom_2154) = 2154)),
    CONSTRAINT enforce_srid_the_geom_3857 CHECK ((public.st_srid(the_geom_3857) = 3857))
);


SET search_path = florestation, pg_catalog;

--
-- TOC entry 212 (class 1259 OID 55555)
-- Name: bib_abondances; Type: TABLE; Schema: florestation; Owner: -; Tablespace: 
--

CREATE TABLE bib_abondances (
    id_abondance character(1) NOT NULL,
    nom_abondance character varying(128) NOT NULL
);

--
-- TOC entry 213 (class 1259 OID 55558)
-- Name: bib_expositions; Type: TABLE; Schema: florestation; Owner: -; Tablespace: 
--

CREATE TABLE bib_expositions (
    id_exposition character(2) NOT NULL,
    nom_exposition character varying(10) NOT NULL,
    tri_exposition integer
);

--
-- TOC entry 214 (class 1259 OID 55561)
-- Name: bib_homogenes; Type: TABLE; Schema: florestation; Owner: -; Tablespace: 
--

CREATE TABLE bib_homogenes (
    id_homogene integer NOT NULL,
    nom_homogene character varying(20) NOT NULL
);

--
-- TOC entry 215 (class 1259 OID 55564)
-- Name: bib_microreliefs; Type: TABLE; Schema: florestation; Owner: -; Tablespace: 
--

CREATE TABLE bib_microreliefs (
    id_microrelief integer NOT NULL,
    nom_microrelief character varying(128) NOT NULL
);

--
-- TOC entry 216 (class 1259 OID 55567)
-- Name: bib_programmes_fs; Type: TABLE; Schema: florestation; Owner: -; Tablespace: 
--

CREATE TABLE bib_programmes_fs (
    id_programme_fs integer NOT NULL,
    nom_programme_fs character varying(255) NOT NULL
);

--
-- TOC entry 217 (class 1259 OID 55570)
-- Name: bib_surfaces; Type: TABLE; Schema: florestation; Owner: -; Tablespace: 
--

CREATE TABLE bib_surfaces (
    id_surface integer NOT NULL,
    nom_surface character varying(20) NOT NULL
);

--
-- TOC entry 218 (class 1259 OID 55573)
-- Name: cor_fs_delphine; Type: TABLE; Schema: florestation; Owner: -; Tablespace: 
--

CREATE TABLE cor_fs_delphine (
    id_station bigint NOT NULL,
    id_delphine character varying(5) NOT NULL
);

--
-- TOC entry 219 (class 1259 OID 55576)
-- Name: cor_fs_microrelief; Type: TABLE; Schema: florestation; Owner: -; Tablespace: 
--

CREATE TABLE cor_fs_microrelief (
    id_station bigint NOT NULL,
    id_microrelief integer NOT NULL
);

--
-- TOC entry 220 (class 1259 OID 55579)
-- Name: cor_fs_observateur; Type: TABLE; Schema: florestation; Owner: -; Tablespace: 
--

CREATE TABLE cor_fs_observateur (
    id_role integer NOT NULL,
    id_station bigint NOT NULL
);

--
-- TOC entry 221 (class 1259 OID 55582)
-- Name: cor_fs_taxon_gid_seq; Type: SEQUENCE; Schema: florestation; Owner: -
--

CREATE SEQUENCE cor_fs_taxon_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

--
-- TOC entry 222 (class 1259 OID 55584)
-- Name: cor_fs_taxon; Type: TABLE; Schema: florestation; Owner: -; Tablespace: 
--

CREATE TABLE cor_fs_taxon (
    id_station bigint NOT NULL,
    cd_nom integer NOT NULL,
    herb character(1),
    inf_1m character(1),
    de_1_4m character(1),
    sup_4m character(1),
    taxon_saisi character varying(150),
    supprime boolean DEFAULT false,
    id_station_cd_nom integer NOT NULL,
    gid integer DEFAULT nextval('cor_fs_taxon_gid_seq'::regclass) NOT NULL
);

--
-- TOC entry 223 (class 1259 OID 55589)
-- Name: cor_fs_taxon_id_station_cd_nom_seq; Type: SEQUENCE; Schema: florestation; Owner: -
--

CREATE SEQUENCE cor_fs_taxon_id_station_cd_nom_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

--
-- TOC entry 3705 (class 0 OID 0)
-- Dependencies: 223
-- Name: cor_fs_taxon_id_station_cd_nom_seq; Type: SEQUENCE OWNED BY; Schema: florestation; Owner: -
--

ALTER SEQUENCE cor_fs_taxon_id_station_cd_nom_seq OWNED BY cor_fs_taxon.id_station_cd_nom;


--
-- TOC entry 224 (class 1259 OID 55591)
-- Name: t_stations_fs; Type: TABLE; Schema: florestation; Owner: -; Tablespace: 
--

CREATE TABLE t_stations_fs (
    id_station bigint NOT NULL,
    id_exposition character(2) NOT NULL,
    id_sophie character varying(5),
    id_programme_fs integer DEFAULT 999 NOT NULL,
    id_support integer NOT NULL,
    id_protocole integer NOT NULL,
    id_lot integer NOT NULL,
    id_organisme integer NOT NULL,
    id_homogene integer,
    dateobs date,
    info_acces character varying(255),
    id_surface integer DEFAULT 1,
    complet_partiel character(1),
    meso_longitudinal integer DEFAULT 0,
    meso_lateral integer DEFAULT 0,
    canopee real DEFAULT 0,
    ligneux_hauts integer DEFAULT 0,
    ligneux_bas integer DEFAULT 0,
    ligneux_tbas integer DEFAULT 0,
    herbaces integer DEFAULT 0,
    mousses integer DEFAULT 0,
    litiere integer DEFAULT 0,
    altitude_saisie integer DEFAULT 0,
    altitude_sig integer DEFAULT 0,
    altitude_retenue integer DEFAULT 0,
    remarques text,
    pdop real DEFAULT 0,
    supprime boolean DEFAULT false,
    date_insert timestamp without time zone,
    date_update timestamp without time zone,
    srid_dessin integer,
    the_geom_3857 public.geometry,
    the_geom_2154 public.geometry,
    insee character(5),
    gid integer NOT NULL,
    validation boolean DEFAULT false,
    CONSTRAINT enforce_dims_the_geom_2154 CHECK ((public.st_ndims(the_geom_2154) = 2)),
    CONSTRAINT enforce_dims_the_geom_3857 CHECK ((public.st_ndims(the_geom_3857) = 2)),
    CONSTRAINT enforce_geotype_the_geom_2154 CHECK (((public.geometrytype(the_geom_2154) = 'POINT'::text) OR (the_geom_2154 IS NULL))),
    CONSTRAINT enforce_geotype_the_geom_3857 CHECK (((public.geometrytype(the_geom_3857) = 'POINT'::text) OR (the_geom_3857 IS NULL))),
    CONSTRAINT enforce_srid_the_geom_2154 CHECK ((public.st_srid(the_geom_2154) = 2154)),
    CONSTRAINT enforce_srid_the_geom_3857 CHECK ((public.st_srid(the_geom_3857) = 3857))
);

--
-- TOC entry 225 (class 1259 OID 55616)
-- Name: t_stations_fs_gid_seq; Type: SEQUENCE; Schema: florestation; Owner: -
--

CREATE SEQUENCE t_stations_fs_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

--
-- TOC entry 3706 (class 0 OID 0)
-- Dependencies: 225
-- Name: t_stations_fs_gid_seq; Type: SEQUENCE OWNED BY; Schema: florestation; Owner: -
--

ALTER SEQUENCE t_stations_fs_gid_seq OWNED BY t_stations_fs.gid;


SET search_path = taxonomie, pg_catalog;

--
-- Name: bib_groupes; Type: TABLE; Schema: taxonomie; Owner: -; Tablespace: 
--

CREATE TABLE taxonomie.bib_groupes
(
  id_groupe integer NOT NULL,
  nom_groupe character varying(255),
  desc_groupe text
);


SET search_path = contactfaune, pg_catalog;


--
-- Name: v_nomade_criteres_cf; Type: VIEW; Schema: contactfaune; Owner: -
--

CREATE OR REPLACE VIEW contactfaune.v_nomade_criteres_cf AS 
SELECT 
	c.id_critere_cf,
	c.nom_critere_cf,
	c.tri_cf,
	ccc.id_groupe as id_classe
FROM contactfaune.bib_criteres_cf c
JOIN contactfaune.cor_critere_groupe ccc ON ccc.id_critere_cf = c.id_critere_cf
ORDER BY ccc.id_groupe, c.tri_cf;


SET search_path = utilisateurs, pg_catalog;

--
-- Name: cor_role_menu; Type: TABLE; Schema: utilisateurs; Owner: -; Tablespace: 
--

CREATE TABLE cor_role_menu (
    id_role integer NOT NULL,
    id_menu integer NOT NULL
);


--
-- Name: TABLE cor_role_menu; Type: COMMENT; Schema: utilisateurs; Owner: -
--

COMMENT ON TABLE cor_role_menu IS 'gestion du contenu des menus utilisateurs dans les applications';


--
-- Name: cor_roles; Type: TABLE; Schema: utilisateurs; Owner: -; Tablespace: 
--

CREATE TABLE cor_roles (
    id_role_groupe integer NOT NULL,
    id_role_utilisateur integer NOT NULL
);


--
-- Name: t_roles_id_seq; Type: SEQUENCE; Schema: utilisateurs; Owner: -
--

CREATE SEQUENCE t_roles_id_seq
    START WITH 1000000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: t_roles; Type: TABLE; Schema: utilisateurs; Owner: -; Tablespace: 
--

CREATE TABLE t_roles (
    groupe boolean DEFAULT false NOT NULL,
    id_role integer DEFAULT nextval('t_roles_id_seq'::regclass) NOT NULL,
    identifiant character varying(100),
    nom_role character varying(50),
    prenom_role character varying(50),
    desc_role text,
    pass character varying(100),
    email character varying(250),
    id_organisme integer,
    organisme character(32),
    id_unite integer,
    remarques text,
    pn boolean,
    session_appli character varying(50),
    date_insert timestamp without time zone,
    date_update timestamp without time zone
);


SET search_path = contactfaune, pg_catalog;

--
-- Name: v_nomade_observateurs_faune; Type: VIEW; Schema: contactfaune; Owner: -
--

CREATE VIEW v_nomade_observateurs_faune AS
    SELECT DISTINCT r.id_role, r.nom_role, r.prenom_role FROM utilisateurs.t_roles r WHERE ((r.id_role IN (SELECT DISTINCT cr.id_role_utilisateur FROM utilisateurs.cor_roles cr WHERE (cr.id_role_groupe IN (SELECT crm.id_role FROM utilisateurs.cor_role_menu crm WHERE (crm.id_menu = 9))) ORDER BY cr.id_role_utilisateur)) OR (r.id_role IN (SELECT crm.id_role FROM (utilisateurs.cor_role_menu crm JOIN utilisateurs.t_roles r ON ((((r.id_role = crm.id_role) AND (crm.id_menu = 9)) AND (r.groupe = false))))))) ORDER BY r.nom_role, r.prenom_role, r.id_role;


SET search_path = taxonomie, pg_catalog;

--
-- Name: bib_attributs; Type: TABLE; Schema: taxonomie; Owner: -; Tablespace: 
--

CREATE TABLE bib_attributs
   (
    id_attribut integer NOT NULL,
    nom_attribut character varying(255) NOT NULL,
    label_attribut character varying(50) NOT NULL,
    liste_valeur_attribut text NOT NULL,
    obligatoire boolean NOT NULL,
    desc_attribut text  
   );
 
--
-- Name: bib_listes; Type: TABLE; Schema: taxonomie; Owner: -; Tablespace: 
--

CREATE TABLE bib_listes
   (
    id_liste integer NOT NULL,
    nom_liste character varying(255) NOT NULL,
    desc_liste text
   );
   
--
-- Name: bib_taxons; Type: TABLE; Schema: taxonomie; Owner: -; Tablespace: 
--
   
CREATE TABLE bib_taxons (
    id_taxon integer NOT NULL,
    cd_nom integer,
    nom_latin character varying(100),
    nom_francais character varying(255),
    auteur character varying(200)
);  
 
--
-- Name: cor_taxon_attribut; Type: TABLE; Schema: taxonomie; Owner: -; Tablespace: 
--
   
CREATE TABLE cor_taxon_attribut
   (
    id_taxon integer NOT NULL,
    id_attribut integer NOT NULL,
    valeur_attribut character varying(50) NOT NULL
   );

 
--
-- Name: cor_taxon_groupe; Type: TABLE; Schema: taxonomie; Owner: -; Tablespace: 
--
   
CREATE TABLE cor_taxon_groupe
   (
    id_groupe integer NOT NULL,
    id_taxon integer NOT NULL
   );


 
--
-- Name: cor_taxon_liste; Type: TABLE; Schema: taxonomie; Owner: -; Tablespace: 
--
   
CREATE TABLE cor_taxon_liste
   (
    id_liste integer NOT NULL,
    id_taxon integer NOT NULL
   );


--
-- Name: taxref; Type: TABLE; Schema: taxonomie; Owner: -; Tablespace: 
--

CREATE TABLE taxref (
    cd_nom integer NOT NULL,
    id_statut character(1),
    id_habitat integer,
    id_rang character(4),
    regne character varying(20),
    phylum character varying(50),
    classe character varying(50),
    ordre character varying(50),
    famille character varying(50),
    cd_taxsup integer,
    cd_ref integer,
    lb_nom character varying(100),
    lb_auteur character varying(150),
    nom_complet character varying(255),
    nom_valide character varying(255),
    nom_vern character varying(255),
    nom_vern_eng character varying(255),
	group1_inpn character varying(255),
	group2_inpn character varying(255)
);


--
-- Name: bib_attributs_id_attribut_seq; Type: SEQUENCE; Schema: taxonomie; Owner: -
--

CREATE SEQUENCE bib_attributs_id_attribut_seq
    START WITH 1000000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
    
--
-- Name: bib_listes_id_liste_seq; Type: SEQUENCE; Schema: taxonomie; Owner: -
--

CREATE SEQUENCE bib_listes_id_liste_seq
    START WITH 1000000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

SET search_path = contactfaune, pg_catalog;

--
-- Name: v_nomade_classes; Type: VIEW; Schema: contactfaune; Owner: -
--

CREATE OR REPLACE VIEW contactfaune.v_nomade_classes AS 
 SELECT g.id_groupe AS id_classe,
    g.nom_groupe AS nom_classe_fr,
    g.desc_groupe AS desc_classe
   FROM ( SELECT gr.id_groupe,
            gr.nom_groupe,
            gr.desc_groupe,
            min(taxonomie.find_cdref(tx.cd_nom)) AS cd_ref
           FROM taxonomie.bib_groupes gr
             JOIN taxonomie.cor_taxon_groupe ctg ON ctg.id_groupe = gr.id_groupe
             JOIN taxonomie.bib_taxons tx ON tx.id_taxon = ctg.id_taxon
          GROUP BY gr.id_groupe, gr.nom_groupe, gr.desc_groupe) g
     JOIN taxonomie.taxref t ON t.cd_nom = g.cd_ref
  WHERE t.phylum::text = 'Chordata'::text;

--
-- Name: v_nomade_taxons_faune; Type: VIEW; Schema: contactfaune; Owner: -
--
CREATE OR REPLACE VIEW contactfaune.v_nomade_taxons_faune AS 
SELECT DISTINCT t.id_taxon,
    taxonomie.find_cdref(tx.cd_nom) AS cd_ref,
    tx.cd_nom,
    t.nom_latin,
    t.nom_francais,
    g.id_classe,
    5 AS denombrement,
        CASE
            WHEN tx_patri.valeur_attribut::text = 'oui'::text THEN true
            WHEN tx_patri.valeur_attribut::text = 'non'::text THEN false
            ELSE NULL::boolean
        END AS patrimonial,
    m.texte_message_cf AS message,
    true AS contactfaune,
    true AS mortalite
   FROM taxonomie.bib_taxons t
     LEFT JOIN contactfaune.cor_message_taxon cmt ON cmt.id_taxon = t.id_taxon
     LEFT JOIN contactfaune.bib_messages_cf m ON m.id_message_cf = cmt.id_message_cf
     LEFT JOIN taxonomie.cor_taxon_groupe ctg ON ctg.id_taxon = t.id_taxon
     JOIN (SELECT id_taxon, valeur_attribut FROM taxonomie.cor_taxon_attribut cta JOIN taxonomie.bib_attributs a ON a.id_attribut = cta.id_attribut AND a.nom_attribut = 'patrimonial') tx_patri ON tx_patri.id_taxon = t.id_taxon
     JOIN contactfaune.v_nomade_classes g ON g.id_classe = ctg.id_groupe
     JOIN taxonomie.taxref tx ON tx.cd_nom = t.cd_nom
     JOIN taxonomie.cor_taxon_liste ctl ON ctl.id_taxon = t.id_taxon AND ctl.id_liste = 1
  ORDER BY t.id_taxon, taxonomie.find_cdref(tx.cd_nom), t.nom_latin, t.nom_francais, g.id_classe,
patrimonial, m.texte_message_cf;


SET search_path = layers, pg_catalog;

--
-- Name: l_unites_geo; Type: TABLE; Schema: layers; Owner: -; Tablespace: 
--

CREATE TABLE l_unites_geo (
    id_unite_geo integer NOT NULL,
    coeur character varying(80),
    secteur character varying(80),
    code_insee character varying(80),
    commune character varying(80),
    reserve character varying(80),
    surface_ha character varying(80),
    n2000 character varying(50),
    the_geom public.geometry,
    CONSTRAINT enforce_dims_the_geom CHECK ((public.st_ndims(the_geom) = 2)),
    CONSTRAINT enforce_geotype_the_geom CHECK (((public.geometrytype(the_geom) = 'MULTIPOLYGON'::text) OR (public.geometrytype(the_geom) = 'POLYGON'::text) OR (the_geom IS NULL))),
    CONSTRAINT enforce_srid_the_geom CHECK ((public.st_srid(the_geom) = 2154))
);


SET search_path = contactfaune, pg_catalog;

--
-- Name: v_nomade_unites_geo_cf; Type: VIEW; Schema: contactfaune; Owner: -
--

CREATE VIEW v_nomade_unites_geo_cf AS
    SELECT public.st_simplifypreservetopology(l_unites_geo.the_geom, (15)::double precision) AS the_geom, l_unites_geo.id_unite_geo FROM layers.l_unites_geo GROUP BY l_unites_geo.the_geom, l_unites_geo.id_unite_geo;


SET search_path = contactinv, pg_catalog;

--
-- Name: bib_criteres_inv; Type: TABLE; Schema: contactinv; Owner: -; Tablespace: 
--

CREATE TABLE bib_criteres_inv (
    id_critere_inv integer NOT NULL,
    code_critere_inv character varying(3),
    nom_critere_inv character varying(90),
    tri_inv integer,
    id_critere_synthese integer
);


--
-- Name: bib_messages_inv; Type: TABLE; Schema: contactinv; Owner: -; Tablespace: 
--

CREATE TABLE bib_messages_inv (
    id_message_inv integer NOT NULL,
    texte_message_inv character varying(255)
);


--
-- Name: bib_milieux_inv; Type: TABLE; Schema: contactinv; Owner: -; Tablespace: 
--

CREATE TABLE bib_milieux_inv (
    id_milieu_inv integer NOT NULL,
    nom_milieu_inv character varying(50)
);


--
-- Name: cor_message_taxon; Type: TABLE; Schema: contactinv; Owner: -; Tablespace: 
--

CREATE TABLE cor_message_taxon (
    id_message_inv integer NOT NULL,
    id_taxon integer NOT NULL
);


--
-- Name: cor_role_fiche_inv; Type: TABLE; Schema: contactinv; Owner: -; Tablespace: 
--

CREATE TABLE cor_role_fiche_inv (
    id_inv bigint NOT NULL,
    id_role integer NOT NULL
);


--
-- Name: cor_unite_taxon_inv; Type: TABLE; Schema: contactinv; Owner: -; Tablespace: 
--

CREATE TABLE cor_unite_taxon_inv (
    id_unite_geo integer NOT NULL,
    id_taxon integer NOT NULL,
    derniere_date date,
    couleur character varying(10) NOT NULL,
    nb_obs integer
);


--
-- Name: log_colors; Type: TABLE; Schema: contactinv; Owner: -; Tablespace: 
--

CREATE TABLE log_colors (
    annee integer NOT NULL,
    mois integer NOT NULL,
    id_unite_geo integer NOT NULL,
    couleur character varying NOT NULL,
    nbtaxons numeric,
    nb_data integer
);


--
-- Name: log_colors_day; Type: TABLE; Schema: contactinv; Owner: -; Tablespace: 
--

CREATE TABLE log_colors_day (
    jour date NOT NULL,
    couleur character varying NOT NULL,
    nbtaxons numeric
);


--
-- Name: t_fiches_inv; Type: TABLE; Schema: contactinv; Owner: -; Tablespace: 
--

CREATE TABLE t_fiches_inv (
    id_inv bigint NOT NULL,
    insee character(5),
    dateobs date NOT NULL,
    heure integer,
    altitude_saisie integer,
    altitude_sig integer,
    altitude_retenue integer,
    date_insert timestamp without time zone,
    date_update timestamp without time zone,
    supprime boolean DEFAULT false NOT NULL,
    pdop integer,
    saisie_initiale character varying(20),
    id_organisme integer,
    srid_dessin integer,
    id_protocole integer,
    id_lot integer,
    the_geom_3857 public.geometry,
    id_milieu_inv integer,
    the_geom_2154 public.geometry,
    CONSTRAINT enforce_dims_the_geom_2154 CHECK ((public.st_ndims(the_geom_2154) = 2)),
    CONSTRAINT enforce_dims_the_geom_3857 CHECK ((public.st_ndims(the_geom_3857) = 2)),
    CONSTRAINT enforce_geotype_the_geom_2154 CHECK (((public.geometrytype(the_geom_2154) = 'POINT'::text) OR (the_geom_2154 IS NULL))),
    CONSTRAINT enforce_geotype_the_geom_3857 CHECK (((public.geometrytype(the_geom_3857) = 'POINT'::text) OR (the_geom_3857 IS NULL))),
    CONSTRAINT enforce_srid_the_geom_2154 CHECK ((public.st_srid(the_geom_2154) = 2154)),
    CONSTRAINT enforce_srid_the_geom_3857 CHECK ((public.st_srid(the_geom_3857) = 3857))
);


--
-- Name: t_releves_inv; Type: TABLE; Schema: contactinv; Owner: -; Tablespace: 
--

CREATE TABLE t_releves_inv (
    id_releve_inv bigint NOT NULL,
    id_inv bigint NOT NULL,
    id_taxon integer NOT NULL,
    id_critere_inv integer NOT NULL,
    am integer,
    af integer,
    ai integer,
    na integer,
    cd_ref_origine integer,
    nom_taxon_saisi character varying(255),
    commentaire text,
    determinateur character varying(255),
    supprime boolean DEFAULT false NOT NULL,
    prelevement boolean DEFAULT false NOT NULL,
    gid integer NOT NULL
);


--
-- Name: COLUMN t_releves_inv.gid; Type: COMMENT; Schema: contactinv; Owner: -
--

COMMENT ON COLUMN t_releves_inv.gid IS 'pour qgis';


--
-- Name: t_releves_inv_gid_seq; Type: SEQUENCE; Schema: contactinv; Owner: -
--

CREATE SEQUENCE t_releves_inv_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: t_releves_inv_gid_seq; Type: SEQUENCE OWNED BY; Schema: contactinv; Owner: -
--

ALTER SEQUENCE t_releves_inv_gid_seq OWNED BY t_releves_inv.gid;


--
-- Name: v_nomade_classes; Type: VIEW; Schema: contactinv; Owner: -
--

CREATE OR REPLACE VIEW contactinv.v_nomade_classes AS 
 SELECT g.id_groupe AS id_classe,
    g.nom_groupe AS nom_classe,
    g.desc_groupe AS desc_classe
   FROM ( SELECT gr.id_groupe,
            gr.nom_groupe,
            gr.desc_groupe,
            min(taxonomie.find_cdref(tx.cd_nom)) AS cd_ref
           FROM taxonomie.bib_groupes gr
             JOIN taxonomie.cor_taxon_groupe ctg ON ctg.id_groupe = gr.id_groupe
             JOIN taxonomie.bib_taxons tx ON tx.id_taxon = ctg.id_taxon
          GROUP BY gr.id_groupe, gr.nom_groupe, gr.desc_groupe) g
     JOIN taxonomie.taxref t ON t.cd_nom = g.cd_ref
WHERE NOT  phylum = 'Chordata';

--
-- Name: v_nomade_criteres_inv; Type: VIEW; Schema: contactinv; Owner: -
--

CREATE OR REPLACE VIEW contactinv.v_nomade_criteres_inv AS 
 SELECT c.id_critere_inv,
    c.nom_critere_inv,
    c.tri_inv
   FROM contactinv.bib_criteres_inv c
  ORDER BY c.tri_inv;

ALTER TABLE contactinv.v_nomade_criteres_inv
  OWNER TO geonatuser;
GRANT ALL ON TABLE contactinv.v_nomade_criteres_inv TO geonatuser;


--
-- Name: v_nomade_milieux_inv; Type: VIEW; Schema: contactinv; Owner: -
--

CREATE VIEW v_nomade_milieux_inv AS
    SELECT bib_milieux_inv.id_milieu_inv, bib_milieux_inv.nom_milieu_inv FROM bib_milieux_inv ORDER BY bib_milieux_inv.id_milieu_inv;


--
-- Name: v_nomade_observateurs_inv; Type: VIEW; Schema: contactinv; Owner: -
--

CREATE VIEW v_nomade_observateurs_inv AS
    SELECT DISTINCT r.id_role, r.nom_role, r.prenom_role FROM utilisateurs.t_roles r WHERE ((r.id_role IN (SELECT DISTINCT cr.id_role_utilisateur FROM utilisateurs.cor_roles cr WHERE (cr.id_role_groupe IN (SELECT crm.id_role FROM utilisateurs.cor_role_menu crm WHERE (crm.id_menu = 11))) ORDER BY cr.id_role_utilisateur)) OR (r.id_role IN (SELECT crm.id_role FROM (utilisateurs.cor_role_menu crm JOIN utilisateurs.t_roles r ON ((((r.id_role = crm.id_role) AND (crm.id_menu = 11)) AND (r.groupe = false))))))) ORDER BY r.nom_role, r.prenom_role, r.id_role;


--
-- Name: v_nomade_taxons_inv; Type: VIEW; Schema: contactinv; Owner: -
--

CREATE OR REPLACE VIEW contactinv.v_nomade_taxons_inv AS 
    SELECT t.id_taxon,
        taxonomie.find_cdref(tx.cd_nom) AS cd_ref,
        tx.cd_nom,
        t.nom_latin,
        t.nom_francais,
        g.id_classe,
        CASE
            WHEN tx_patri.valeur_attribut::text = 'oui'::text THEN true
            WHEN tx_patri.valeur_attribut::text = 'non'::text THEN false
            ELSE NULL::boolean
        END AS patrimonial,
        m.texte_message_inv AS message
    FROM taxonomie.bib_taxons t
    LEFT JOIN contactinv.cor_message_taxon cmt ON cmt.id_taxon = t.id_taxon
    LEFT JOIN contactinv.bib_messages_inv m ON m.id_message_inv = cmt.id_message_inv
    LEFT JOIN taxonomie.cor_taxon_groupe ctg ON ctg.id_taxon = t.id_taxon
    JOIN (SELECT id_taxon, valeur_attribut FROM taxonomie.cor_taxon_attribut cta JOIN taxonomie.bib_attributs a ON a.id_attribut = cta.id_attribut AND a.nom_attribut = 'patrimonial') tx_patri ON tx_patri.id_taxon = t.id_taxon
    JOIN contactinv.v_nomade_classes g ON g.id_classe = ctg.id_groupe
    JOIN taxonomie.cor_taxon_liste ctl ON ctl.id_taxon = t.id_taxon AND ctl.id_liste = 2
    JOIN taxonomie.taxref tx ON tx.cd_nom = t.cd_nom;


--
-- Name: v_nomade_unites_geo_inv; Type: VIEW; Schema: contactinv; Owner: -
--

CREATE VIEW v_nomade_unites_geo_inv AS
    SELECT public.st_simplifypreservetopology(l_unites_geo.the_geom, (15)::double precision) AS the_geom, l_unites_geo.id_unite_geo FROM layers.l_unites_geo GROUP BY l_unites_geo.the_geom, l_unites_geo.id_unite_geo;


SET search_path = layers, pg_catalog;

--
-- Name: bib_typeszones; Type: TABLE; Schema: layers; Owner: -; Tablespace: 
--

CREATE TABLE bib_typeszones (
    id_type integer NOT NULL,
    typezone character varying(200)
);


--
-- Name: l_aireadhesion; Type: TABLE; Schema: layers; Owner: -; Tablespace: 
--

CREATE TABLE l_aireadhesion (
    gid integer NOT NULL,
    id integer,
    nouveaucha integer,
    count integer,
    length double precision,
    the_geom public.geometry,
    CONSTRAINT enforce_dims_the_geom CHECK ((public.st_ndims(the_geom) = 2)),
    CONSTRAINT enforce_geotype_the_geom CHECK (((public.geometrytype(the_geom) = 'LINESTRING'::text) OR (public.geometrytype(the_geom) = 'MULTIPOLYGON'::text) OR (public.geometrytype(the_geom) = 'POLYGON'::text) OR the_geom IS NULL)),
    CONSTRAINT enforce_srid_the_geom CHECK ((public.st_srid(the_geom) = 2154))
);


--
-- Name: l_communes; Type: TABLE; Schema: layers; Owner: -; Tablespace: 
--

CREATE TABLE l_communes (
    insee character(5) NOT NULL,
    idbdcarto bigint,
    commune_maj character varying(50),
    commune_min character varying(50),
    inseedep character varying(3),
    nomdep character varying(30),
    inseereg character varying(2),
    nomreg character varying(30),
    inseearr character varying(1),
    inseecan character varying(2),
    statut character varying(20),
    xcom bigint,
    ycom bigint,
    surface bigint,
    epci character varying(40),
    coeur_aoa character varying(5),
    codenum integer,
    pays character varying(50),
    id_secteur integer,
    saisie boolean,
    organisme boolean,
    id_secteur_fp integer,
    the_geom public.geometry,
    CONSTRAINT enforce_dims_the_geom CHECK ((public.st_ndims(the_geom) = 2)),
    CONSTRAINT enforce_geotype_the_geom CHECK (((public.geometrytype(the_geom) = 'MULTIPOLYGON'::text) OR (the_geom IS NULL))),
    CONSTRAINT enforce_srid_the_geom CHECK ((public.st_srid(the_geom) = 2154))
);

--
-- Name: l_isolines20; Type: TABLE; Schema: layers; Owner: -; Tablespace: 
--

CREATE TABLE l_isolines20 (
    gid integer NOT NULL,
    iso bigint,
    the_geom public.geometry,
    CONSTRAINT enforce_dims_the_geom CHECK ((public.st_ndims(the_geom) = 2)),
    CONSTRAINT enforce_geotype_the_geom CHECK (((public.geometrytype(the_geom) = 'MULTILINESTRING'::text) OR (the_geom IS NULL))),
    CONSTRAINT enforce_srid_the_geom CHECK ((public.st_srid(the_geom) = 2154))
);


--
-- Name: l_isolines20_gid_seq; Type: SEQUENCE; Schema: layers; Owner: -
--

CREATE SEQUENCE l_isolines20_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: l_isolines20_gid_seq; Type: SEQUENCE OWNED BY; Schema: layers; Owner: -
--

ALTER SEQUENCE l_isolines20_gid_seq OWNED BY l_isolines20.gid;


--
-- Name: l_secteurs; Type: TABLE; Schema: layers; Owner: -; Tablespace: 
--

CREATE TABLE l_secteurs (
    nom_secteur character varying(50),
    id_secteur integer NOT NULL,
    the_geom public.geometry,
    CONSTRAINT enforce_dims_the_geom CHECK ((public.st_ndims(the_geom) = 2)),
    CONSTRAINT enforce_geotype_the_geom CHECK (((public.geometrytype(the_geom) = 'MULTIPOLYGON'::text) OR (the_geom IS NULL))),
    CONSTRAINT enforce_srid_the_geom CHECK ((public.st_srid(the_geom) = 2154))
);


--
-- Name: l_zonesstatut; Type: TABLE; Schema: layers; Owner: -; Tablespace: 
--

CREATE TABLE l_zonesstatut (
    id_zone integer NOT NULL,
    id_type integer NOT NULL,
    id_mnhn character varying(20),
    nomzone character varying(250),
    the_geom public.geometry,
    --CONSTRAINT enforce_dims_the_geom CHECK ((public.st_ndims(the_geom) = 2) OR (public.st_ndims(the_geom) = 4)),
    CONSTRAINT enforce_geotype_the_geom CHECK (((public.geometrytype(the_geom) = 'MULTIPOLYGON'::text) OR (the_geom IS NULL))),
    CONSTRAINT enforce_srid_the_geom CHECK ((public.st_srid(the_geom) = 2154))
);


SET search_path = meta, pg_catalog;

--
-- Name: bib_lots; Type: TABLE; Schema: meta; Owner: -; Tablespace: 
--

CREATE TABLE bib_lots (
    id_lot integer NOT NULL,
    nom_lot character varying(255),
    desc_lot text,
    menu_cf boolean DEFAULT false,
    pn boolean DEFAULT true,
    menu_inv boolean DEFAULT false,
    id_programme integer NOT NULL
);


--
-- Name: bib_programmes; Type: TABLE; Schema: meta; Owner: -; Tablespace: 
--

CREATE TABLE bib_programmes (
    id_programme integer NOT NULL,
    nom_programme character varying(255),
    desc_programme text,
    sitpn boolean,
    desc_programme_sitpn text
);

--
-- Name: bib_supports; Type: TABLE; Schema: meta; Owner: -; Tablespace: 
--

CREATE TABLE bib_supports
(
  id_support integer NOT NULL,
  nom_support character varying(20) NOT NULL
);


--
-- Name: t_precisions; Type: TABLE; Schema: meta; Owner: -; Tablespace: 
--

CREATE TABLE t_precisions (
    id_precision integer NOT NULL,
    nom_precision character varying(50),
    desc_precision text
);


--
-- Name: t_protocoles; Type: TABLE; Schema: meta; Owner: -; Tablespace: 
--

CREATE TABLE t_protocoles (
    id_protocole integer NOT NULL,
    nom_protocole character varying(250),
    question text,
    objectifs text,
    methode text,
    avancement character varying(50),
    date_debut date,
    date_fin date
);


SET search_path = synthese, pg_catalog;

--
-- Name: bib_criteres_synthese; Type: TABLE; Schema: synthese; Owner: -; Tablespace: 
--

CREATE TABLE bib_criteres_synthese (
    id_critere_synthese integer NOT NULL,
    code_critere_synthese character varying(3),
    nom_critere_synthese character varying(90),
    tri integer
);


--
-- Name: syntheseff; Type: TABLE; Schema: synthese; Owner: -; Tablespace: 
--

CREATE TABLE syntheseff (
    id_synthese integer NOT NULL,
    id_source integer,
    id_fiche_source character varying(50),
    code_fiche_source character varying(50),
    id_organisme integer,
    id_protocole integer,
    id_precision integer,
    cd_nom integer,
    insee character(5),
    dateobs date NOT NULL,
    observateurs character varying(255),
    determinateur character varying(255),
    altitude_retenue integer,
    remarques text,
    date_insert timestamp without time zone,
    date_update timestamp without time zone,
    derniere_action character(1),
    supprime boolean,
    the_geom_point public.geometry,
    id_lot integer,
    id_critere_synthese integer,
    the_geom_3857 public.geometry,
    effectif_total integer,
    the_geom_2154 public.geometry,
    CONSTRAINT enforce_dims_the_geom_2154 CHECK ((public.st_ndims(the_geom_2154) = 2)),
    CONSTRAINT enforce_dims_the_geom_3857 CHECK ((public.st_ndims(the_geom_3857) = 2)),
    CONSTRAINT enforce_dims_the_geom_point CHECK ((public.st_ndims(the_geom_point) = 2)),
    CONSTRAINT enforce_geotype_the_geom_2154 CHECK (((public.geometrytype(the_geom_2154) = 'POINT'::text) OR (the_geom_2154 IS NULL))),
    CONSTRAINT enforce_geotype_the_geom_point CHECK (((public.geometrytype(the_geom_point) = 'POINT'::text) OR (the_geom_point IS NULL))),
    CONSTRAINT enforce_srid_the_geom_2154 CHECK ((public.st_srid(the_geom_2154) = 2154)),
    CONSTRAINT enforce_srid_the_geom_3857 CHECK ((public.st_srid(the_geom_3857) = 3857)),
    CONSTRAINT enforce_srid_the_geom_point CHECK ((public.st_srid(the_geom_point) = 3857))
);


--
-- Name: TABLE syntheseff; Type: COMMENT; Schema: synthese; Owner: -
--

COMMENT ON TABLE syntheseff IS 'Table de synthèse destinée à recevoir les données de tous les schémas.Pour consultation uniquement';

SET search_path = utilisateurs, pg_catalog;

--
-- Name: bib_organismes_id_seq; Type: SEQUENCE; Schema: utilisateurs; Owner: -
--

CREATE SEQUENCE bib_organismes_id_seq
    START WITH 1000000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: bib_organismes; Type: TABLE; Schema: utilisateurs; Owner: -; Tablespace: 
--

CREATE TABLE bib_organismes (
    nom_organisme character varying(100) NOT NULL,
    adresse_organisme character varying(128),
    cp_organisme character varying(5),
    ville_organisme character varying(100),
    tel_organisme character varying(14),
    fax_organisme character varying(14),
    email_organisme character varying(100),
    id_organisme integer DEFAULT nextval('bib_organismes_id_seq'::regclass) NOT NULL
);


SET search_path = synchronomade, pg_catalog;

--
-- Name: erreurs_cf; Type: TABLE; Schema: synchronomade; Owner: -; Tablespace: 
--

CREATE TABLE erreurs_cf (
    id integer NOT NULL,
    json text,
    date_import date
);


--
-- Name: erreurs_cf_id_seq; Type: SEQUENCE; Schema: synchronomade; Owner: -
--

CREATE SEQUENCE erreurs_cf_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: erreurs_cf_id_seq; Type: SEQUENCE OWNED BY; Schema: synchronomade; Owner: -
--

ALTER SEQUENCE erreurs_cf_id_seq OWNED BY erreurs_cf.id;


--
-- Name: erreurs_inv; Type: TABLE; Schema: synchronomade; Owner: -; Tablespace: 
--

CREATE TABLE erreurs_inv (
    id integer NOT NULL,
    json text,
    date_import date
);


--
-- Name: erreurs_inv_id_seq; Type: SEQUENCE; Schema: synchronomade; Owner: -
--

CREATE SEQUENCE erreurs_inv_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: erreurs_inv_id_seq; Type: SEQUENCE OWNED BY; Schema: synchronomade; Owner: -
--

ALTER SEQUENCE erreurs_inv_id_seq OWNED BY erreurs_inv.id;


--
-- Name: erreurs_mortalite; Type: TABLE; Schema: synchronomade; Owner: -; Tablespace: 
--

CREATE TABLE erreurs_mortalite (
    id integer NOT NULL,
    json text,
    date_import date
);


--
-- Name: erreurs_mortalite_id_seq; Type: SEQUENCE; Schema: synchronomade; Owner: -
--

CREATE SEQUENCE erreurs_mortalite_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: erreurs_mortalite_id_seq; Type: SEQUENCE OWNED BY; Schema: synchronomade; Owner: -
--

ALTER SEQUENCE erreurs_mortalite_id_seq OWNED BY erreurs_mortalite.id;


--
-- TOC entry 329 (class 1259 OID 166465)
-- Name: erreurs_flora; Type: TABLE; Schema: synchronomade; Owner: -; Tablespace: 
--

CREATE TABLE erreurs_flora (
    id integer NOT NULL,
    json text,
    date_import date
);

--
-- TOC entry 328 (class 1259 OID 166463)
-- Name: erreurs_flora_id_seq; Type: SEQUENCE; Schema: synchronomade; Owner: -
--

CREATE SEQUENCE erreurs_flora_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

--
-- TOC entry 3711 (class 0 OID 0)
-- Dependencies: 328
-- Name: erreurs_flora_id_seq; Type: SEQUENCE OWNED BY; Schema: synchronomade; Owner: -
--

ALTER SEQUENCE erreurs_flora_id_seq OWNED BY erreurs_flora.id;

SET search_path = synthese, pg_catalog;

--
-- Name: bib_sources; Type: TABLE; Schema: synthese; Owner: -; Tablespace: 
--

CREATE TABLE bib_sources (
    id_source integer NOT NULL,
    nom_source character varying(255),
    desc_source text,
    host character varying(100),
    port integer,
    username character varying(50),
    pass character varying(50),
    db_name character varying(50),
    db_schema character varying(50),
    db_table character varying(50),
    db_field character varying(50)
);


--
-- Name: cor_unite_synthese; Type: TABLE; Schema: synthese; Owner: -; Tablespace: 
--

CREATE TABLE cor_unite_synthese (
    id_unite_geo integer NOT NULL,
    id_synthese integer NOT NULL,
    dateobs date,
    cd_nom integer
);


--
-- Name: cor_zonesstatut_synthese; Type: TABLE; Schema: synthese; Owner: -; Tablespace: 
--

CREATE TABLE cor_zonesstatut_synthese (
    id_zone integer NOT NULL,
    id_synthese integer NOT NULL
);


--
-- Name: syntheseff_id_synthese_seq; Type: SEQUENCE; Schema: synthese; Owner: -
--

CREATE SEQUENCE syntheseff_id_synthese_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: syntheseff_id_synthese_seq; Type: SEQUENCE OWNED BY; Schema: synthese; Owner: -
--

ALTER SEQUENCE syntheseff_id_synthese_seq OWNED BY syntheseff.id_synthese;

SET search_path = taxonomie, pg_catalog;

--
-- Name: bib_taxref_habitats; Type: TABLE; Schema: taxonomie; Owner: -; Tablespace: 
--

CREATE TABLE bib_taxref_habitats (
    id_habitat integer NOT NULL,
    nom_habitat character varying(50) NOT NULL
);


--
-- Name: bib_taxref_rangs; Type: TABLE; Schema: taxonomie; Owner: -; Tablespace: 
--

CREATE TABLE bib_taxref_rangs (
    id_rang character(4) NOT NULL,
    nom_rang character varying(20) NOT NULL
);


--
-- Name: bib_taxref_statuts; Type: TABLE; Schema: taxonomie; Owner: -; Tablespace: 
--

CREATE TABLE bib_taxref_statuts (
    id_statut character(1) NOT NULL,
    nom_statut character varying(50) NOT NULL
);


--
-- Name: import_taxref; Type: TABLE; Schema: taxonomie; Owner: -; Tablespace: 
--

CREATE TABLE import_taxref (
	regne character varying(20),
	phylum character varying(50),
	classe character varying(50),
	ordre character varying(50),
	famille character varying(50),
	group1_inpn character varying(50),
	group2_inpn character varying(50),
	cd_nom integer NOT NULL,
	cd_taxsup integer,
	cd_ref integer,
	rang character varying(10),
	lb_nom character varying(100),
	lb_auteur character varying(250),
	nom_complet character varying(255),
	nom_valide character varying(255),
	nom_vern character varying(500),
	nom_vern_eng character varying(500),
	habitat character varying(10),
	fr character varying(10),
	gf character varying(10),
	mar character varying(10),
	gua character varying(10),
	sm character varying(10),
	sb character varying(10),
	spm character varying(10),
	may character varying(10),
	epa character varying(10),
	reu character varying(10),
	taaf character varying(10),
	pf character varying(10),
	nc character varying(10),
	wf character varying(10),
	cli character varying(10),
	url text
);


--
-- Name: taxref_changes; Type: TABLE; Schema: taxonomie; Owner: -; Tablespace: 
--

CREATE TABLE taxref_changes (
    cd_nom integer NOT NULL,
    num_version_init character varying(5),
    num_version_final character varying(5),
    champ character varying(50) NOT NULL,
    valeur_init character varying(255),
    valeur_final character varying(255),
    type_change character varying(25)
);


--
-- Name: taxref_protection_articles; Type: TABLE; Schema: taxonomie; Owner: -; Tablespace: 
--

CREATE TABLE taxref_protection_articles (
  cd_protection character varying(20) NOT NULL,
  article character varying(100),
  intitule text,
  protection text,
  arrete text,
  fichier text,
  fg_afprot integer,
  niveau character varying(250),
  cd_arrete integer,
  url character varying(250),
  date_arrete integer,
  rang_niveau integer,
  lb_article text,
  type_protection character varying(250),
  concerne_mon_territoire boolean
);


--
-- Name: taxref_protection_especes; Type: TABLE; Schema: taxonomie; Owner: -; Tablespace: 
--

CREATE TABLE taxref_protection_especes (
    cd_nom integer NOT NULL,
    cd_protection character varying(20) NOT NULL,
    nom_cite character varying(200),
    syn_cite character varying(200),
    nom_francais_cite character varying(100),
    precisions text,
    cd_nom_cite character varying(255) NOT NULL
);


--
-- Name: v_tree_taxons_synthese; Type: VIEW; Schema: synthese; Owner: -
--

CREATE OR REPLACE VIEW synthese.v_tree_taxons_synthese AS 
 WITH taxon AS 
    (
        SELECT 
            tx.id_taxon,
            tx.nom_latin,
            tx.nom_francais,
            taxref.cd_nom,
            taxref.id_statut,
            taxref.id_habitat,
            taxref.id_rang,
            taxref.regne,
            taxref.phylum,
            taxref.classe,
            taxref.ordre,
            taxref.famille,
            taxref.cd_taxsup,
            taxref.cd_ref,
            taxref.lb_nom,
            taxref.lb_auteur,
            taxref.nom_complet,
            taxref.nom_valide,
            taxref.nom_vern,
            taxref.nom_vern_eng,
            taxref.group1_inpn,
            taxref.group2_inpn
        FROM 
           ( 
                SELECT 
                    tx_1.id_taxon,
                    taxref.cd_nom,
                    taxonomie.find_cdref(taxref.cd_nom) AS cd_ref,
                    taxref.lb_nom AS nom_latin,
                    CASE
                        WHEN tx_1.nom_francais IS NULL THEN taxref.lb_nom
                        WHEN tx_1.nom_francais = '' THEN taxref.lb_nom
                        ELSE tx_1.nom_francais
                    END AS nom_francais
                FROM taxonomie.taxref taxref
                LEFT JOIN taxonomie.bib_taxons tx_1 ON tx_1.cd_nom = taxref.cd_nom
                WHERE 
                (taxref.cd_nom IN 
                    ( 
                        SELECT DISTINCT syntheseff.cd_nom
                               FROM synthese.syntheseff
                              ORDER BY syntheseff.cd_nom
                    )
                )
            ) tx
        JOIN taxonomie.taxref taxref ON taxref.cd_nom = tx.cd_ref
    )
SELECT
    t.id_taxon,
    t.cd_ref,
    t.nom_latin,
    t.nom_francais,
    t.id_regne,
    t.nom_regne,
    COALESCE(t.id_embranchement, id_regne) AS id_embranchement,
    COALESCE(t.nom_embranchement, ' Sans embranchement dans taxref'::character varying) AS nom_embranchement,
    COALESCE(t.id_classe, t.id_embranchement) AS id_classe,
    COALESCE(t.nom_classe, ' Sans classe dans taxref'::character varying) AS nom_classe,
    COALESCE(t.desc_classe, ' Sans classe dans taxref'::character varying) AS desc_classe,
    COALESCE(t.id_ordre, t.id_classe) AS id_ordre,
    COALESCE(t.nom_ordre, ' Sans ordre dans taxref'::character varying) AS nom_ordre,
    COALESCE(t.id_famille, t.id_ordre) AS id_famille,
    COALESCE(t.nom_famille, ' Sans famille dans taxref'::character varying) AS nom_famille
FROM 
( 
    SELECT DISTINCT 
        t_1.id_taxon,
        t_1.cd_ref,
        t_1.nom_latin,
        t_1.nom_francais,
        ( 
            SELECT taxref.cd_nom
                FROM taxonomie.taxref
                WHERE taxref.id_rang = 'KD'::bpchar AND taxref.lb_nom::text = t_1.regne::text
        ) AS id_regne,
        t_1.regne AS nom_regne,
        CASE
            WHEN t_1.phylum IS NULL THEN NULL::integer
            ELSE 
            ( 
                SELECT taxref.cd_nom
                FROM taxonomie.taxref
                WHERE taxref.id_rang = 'PH'::bpchar AND taxref.lb_nom::text = t_1.phylum::text AND taxref.cd_nom = taxref.cd_ref
            )
        END AS id_embranchement,
        t_1.phylum AS nom_embranchement,
        t_1.phylum AS desc_embranchement,
        CASE
            WHEN t_1.classe IS NULL THEN NULL::integer
            ELSE 
            ( 
                SELECT taxref.cd_nom
                FROM taxonomie.taxref
                WHERE taxref.id_rang = 'CL'::bpchar AND taxref.lb_nom::text = t_1.classe::text AND taxref.cd_nom = taxref.cd_ref
            )
        END AS id_classe,
        t_1.classe AS nom_classe,
        t_1.classe AS desc_classe,
        CASE
            WHEN t_1.ordre IS NULL THEN NULL::integer
            ELSE
            ( 
                SELECT taxref.cd_nom
                FROM taxonomie.taxref
                WHERE taxref.id_rang = 'OR'::bpchar AND taxref.lb_nom::text = t_1.ordre::text AND taxref.cd_nom = taxref.cd_ref
            )
        END AS id_ordre,
        t_1.ordre AS nom_ordre,
        CASE
            WHEN t_1.famille IS NULL THEN NULL::integer
            ELSE 
            ( 
                SELECT taxref.cd_nom
                FROM taxonomie.taxref
                WHERE taxref.id_rang = 'FM'::bpchar AND taxref.lb_nom::text = t_1.famille::text AND taxref.phylum::text = t_1.phylum::text AND taxref.cd_nom = taxref.cd_ref
            )
        END AS id_famille,
        t_1.famille AS nom_famille
    FROM taxon t_1
) t;

SET search_path = utilisateurs, pg_catalog;

--
-- Name: bib_droits; Type: TABLE; Schema: utilisateurs; Owner: -; Tablespace: 
--

CREATE TABLE bib_droits (
    id_droit integer NOT NULL,
    nom_droit character varying(50),
    desc_droit text
);


--
-- Name: bib_unites_id_seq; Type: SEQUENCE; Schema: utilisateurs; Owner: -
--

CREATE SEQUENCE bib_unites_id_seq
    START WITH 1000000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: bib_unites; Type: TABLE; Schema: utilisateurs; Owner: -; Tablespace: 
--

CREATE TABLE bib_unites (
    nom_unite character varying(50) NOT NULL,
    adresse_unite character varying(128),
    cp_unite character varying(5),
    ville_unite character varying(100),
    tel_unite character varying(14),
    fax_unite character varying(14),
    email_unite character varying(100),
    id_unite integer DEFAULT nextval('bib_unites_id_seq'::regclass) NOT NULL
);


--
-- Name: cor_role_droit_application; Type: TABLE; Schema: utilisateurs; Owner: -; Tablespace: 
--

CREATE TABLE cor_role_droit_application (
    id_role integer NOT NULL,
    id_droit integer NOT NULL,
    id_application integer NOT NULL
);


--
-- Name: t_applications; Type: TABLE; Schema: utilisateurs; Owner: -; Tablespace: 
--

CREATE TABLE t_applications (
    id_application integer NOT NULL,
    nom_application character varying(50) NOT NULL,
    desc_application text
);


--
-- Name: t_applications_id_application_seq; Type: SEQUENCE; Schema: utilisateurs; Owner: -
--

CREATE SEQUENCE t_applications_id_application_seq
    START WITH 1000000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: t_applications_id_application_seq; Type: SEQUENCE OWNED BY; Schema: utilisateurs; Owner: -
--

ALTER SEQUENCE t_applications_id_application_seq OWNED BY t_applications.id_application;


--
-- Name: t_menus; Type: TABLE; Schema: utilisateurs; Owner: -; Tablespace: 
--

CREATE TABLE t_menus (
    id_menu integer NOT NULL,
    nom_menu character varying(50) NOT NULL,
    desc_menu text,
    id_application integer
);


--
-- Name: TABLE t_menus; Type: COMMENT; Schema: utilisateurs; Owner: -
--

COMMENT ON TABLE t_menus IS 'table des menus déroulants des applications. Les roles de niveau groupes ou utilisateurs devant figurer dans un menu sont gérés dans la table cor_role_menu_application.';


--
-- Name: t_menus_id_menu_seq; Type: SEQUENCE; Schema: utilisateurs; Owner: -
--

CREATE SEQUENCE t_menus_id_menu_seq
    START WITH 1000000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: t_menus_id_menu_seq; Type: SEQUENCE OWNED BY; Schema: utilisateurs; Owner: -
--

ALTER SEQUENCE t_menus_id_menu_seq OWNED BY t_menus.id_menu;


--
-- Name: v_nomade_observateurs_all; Type: VIEW; Schema: utilisateurs; Owner: -
--

CREATE VIEW v_nomade_observateurs_all AS
    ((SELECT DISTINCT r.id_role, r.nom_role, r.prenom_role, 'fauna'::text AS mode FROM t_roles r WHERE ((r.id_role IN (SELECT DISTINCT cr.id_role_utilisateur FROM cor_roles cr WHERE (cr.id_role_groupe IN (SELECT crm.id_role FROM cor_role_menu crm WHERE (crm.id_menu = 9))) ORDER BY cr.id_role_utilisateur)) OR (r.id_role IN (SELECT crm.id_role FROM (cor_role_menu crm JOIN t_roles r ON ((((r.id_role = crm.id_role) AND (crm.id_menu = 9)) AND (r.groupe = false))))))) ORDER BY r.nom_role, r.prenom_role, r.id_role) UNION (SELECT DISTINCT r.id_role, r.nom_role, r.prenom_role, 'flora'::text AS mode FROM t_roles r WHERE ((r.id_role IN (SELECT DISTINCT cr.id_role_utilisateur FROM cor_roles cr WHERE (cr.id_role_groupe IN (SELECT crm.id_role FROM cor_role_menu crm WHERE (crm.id_menu = 10))) ORDER BY cr.id_role_utilisateur)) OR (r.id_role IN (SELECT crm.id_role FROM (cor_role_menu crm JOIN t_roles r ON ((((r.id_role = crm.id_role) AND (crm.id_menu = 10)) AND (r.groupe = false))))))) ORDER BY r.nom_role, r.prenom_role, r.id_role)) UNION (SELECT DISTINCT r.id_role, r.nom_role, r.prenom_role, 'inv'::text AS mode FROM t_roles r WHERE ((r.id_role IN (SELECT DISTINCT cr.id_role_utilisateur FROM cor_roles cr WHERE (cr.id_role_groupe IN (SELECT crm.id_role FROM cor_role_menu crm WHERE (crm.id_menu = 11))) ORDER BY cr.id_role_utilisateur)) OR (r.id_role IN (SELECT crm.id_role FROM (cor_role_menu crm JOIN t_roles r ON ((((r.id_role = crm.id_role) AND (crm.id_menu = 11)) AND (r.groupe = false))))))) ORDER BY r.nom_role, r.prenom_role, r.id_role);


--
-- Name: v_observateurs; Type: VIEW; Schema: utilisateurs; Owner: -
--

CREATE VIEW v_observateurs AS
    SELECT DISTINCT r.id_role AS codeobs, (((r.nom_role)::text || ' '::text) || (r.prenom_role)::text) AS nomprenom FROM t_roles r WHERE ((r.id_role IN (SELECT DISTINCT cr.id_role_utilisateur FROM cor_roles cr WHERE (cr.id_role_groupe IN (SELECT crm.id_role FROM cor_role_menu crm WHERE (crm.id_menu = 9))) ORDER BY cr.id_role_utilisateur)) OR (r.id_role IN (SELECT crm.id_role FROM (cor_role_menu crm JOIN t_roles r ON ((((r.id_role = crm.id_role) AND (crm.id_menu = 9)) AND (r.groupe = false))))))) ORDER BY (((r.nom_role)::text || ' '::text) || (r.prenom_role)::text), r.id_role;

    
SET search_path = florepatri, pg_catalog;

--
-- TOC entry 322 (class 1259 OID 166430)
-- Name: v_mobile_observateurs_fp; Type: VIEW; Schema: florepatri; Owner: -
--

CREATE VIEW v_mobile_observateurs_fp AS
SELECT DISTINCT r.id_role, r.nom_role, r.prenom_role FROM utilisateurs.t_roles r WHERE ((r.id_role IN (SELECT DISTINCT cr.id_role_utilisateur FROM utilisateurs.cor_roles cr WHERE (cr.id_role_groupe IN (SELECT crm.id_role FROM utilisateurs.cor_role_menu crm WHERE (crm.id_menu = 5))) ORDER BY cr.id_role_utilisateur)) OR (r.id_role IN (SELECT crm.id_role FROM (utilisateurs.cor_role_menu crm JOIN utilisateurs.t_roles r ON ((((r.id_role = crm.id_role) AND (crm.id_menu = 5)) AND (r.groupe = false))))))) ORDER BY r.nom_role, r.prenom_role, r.id_role;

--
-- TOC entry 337 (class 1259 OID 167994)
-- Name: v_touteslesap_2154_line; Type: VIEW; Schema: florepatri; Owner: -
--

CREATE VIEW v_touteslesap_2154_line AS
SELECT ap.indexap AS gid, ap.indexzp, ap.indexap, s.nom_secteur AS secteur, zp.dateobs, t.latin AS taxon, o.observateurs, p.pheno AS phenologie, ap.surfaceap, ap.insee, com.commune_min, ap.altitude_retenue AS altitude, f.nom_frequence_methodo_new AS met_frequence, ap.frequenceap, compt.nom_comptage_methodo AS met_comptage, ap.total_fertiles AS tot_fertiles, ap.total_steriles AS tot_steriles, per.perturbations, phy.physionomies, ap.the_geom_2154, ap.topo_valid AS ap_topo_valid, zp.validation AS relue, ap.remarques FROM ((((((((((t_apresence ap JOIN t_zprospection zp ON ((ap.indexzp = zp.indexzp))) JOIN bib_taxons_fp t ON ((t.cd_nom = zp.cd_nom))) JOIN layers.l_secteurs s ON ((s.id_secteur = zp.id_secteur))) JOIN bib_phenologies p ON ((p.codepheno = ap.codepheno))) JOIN layers.l_communes com ON (((com.insee)::bpchar = ap.insee))) JOIN bib_frequences_methodo_new f ON ((f.id_frequence_methodo_new = ap.id_frequence_methodo_new))) JOIN bib_comptages_methodo compt ON ((compt.id_comptage_methodo = ap.id_comptage_methodo))) JOIN (SELECT c.indexzp, array_to_string(array_agg((((r.prenom_role)::text || ' '::text) || (r.nom_role)::text)), ', '::text) AS observateurs FROM (cor_zp_obs c JOIN utilisateurs.t_roles r ON ((r.id_role = c.codeobs))) GROUP BY c.indexzp) o ON ((o.indexzp = ap.indexzp))) LEFT JOIN (SELECT c.indexap, array_to_string(array_agg(((((per.description)::text || ' ('::text) || (per.classification)::text) || ')'::text)), ', '::text) AS perturbations FROM (cor_ap_perturb c JOIN bib_perturbations per ON ((per.codeper = c.codeper))) GROUP BY c.indexap) per ON ((per.indexap = ap.indexap))) LEFT JOIN (SELECT p.indexap, array_to_string(array_agg(((((phy.nom_physionomie)::text || ' ('::text) || (phy.groupe_physionomie)::text) || ')'::text)), ', '::text) AS physionomies FROM (cor_ap_physionomie p JOIN bib_physionomies phy ON ((phy.id_physionomie = p.id_physionomie))) GROUP BY p.indexap) phy ON ((phy.indexap = ap.indexap))) WHERE ((ap.supprime = false) AND (public.geometrytype(ap.the_geom_2154) = 'LINESTRING'::text)) ORDER BY s.nom_secteur, ap.indexzp;

--
-- TOC entry 336 (class 1259 OID 167989)
-- Name: v_touteslesap_2154_point; Type: VIEW; Schema: florepatri; Owner: -
--

CREATE VIEW v_touteslesap_2154_point AS
SELECT ap.indexap AS gid, ap.indexzp, ap.indexap, s.nom_secteur AS secteur, zp.dateobs, t.latin AS taxon, o.observateurs, p.pheno AS phenologie, ap.surfaceap, ap.insee, com.commune_min, ap.altitude_retenue AS altitude, f.nom_frequence_methodo_new AS met_frequence, ap.frequenceap, compt.nom_comptage_methodo AS met_comptage, ap.total_fertiles AS tot_fertiles, ap.total_steriles AS tot_steriles, per.perturbations, phy.physionomies, ap.the_geom_2154, ap.topo_valid AS ap_topo_valid, zp.validation AS relue, ap.remarques FROM ((((((((((t_apresence ap JOIN t_zprospection zp ON ((ap.indexzp = zp.indexzp))) JOIN bib_taxons_fp t ON ((t.cd_nom = zp.cd_nom))) JOIN layers.l_secteurs s ON ((s.id_secteur = zp.id_secteur))) JOIN bib_phenologies p ON ((p.codepheno = ap.codepheno))) JOIN layers.l_communes com ON (((com.insee)::bpchar = ap.insee))) JOIN bib_frequences_methodo_new f ON ((f.id_frequence_methodo_new = ap.id_frequence_methodo_new))) JOIN bib_comptages_methodo compt ON ((compt.id_comptage_methodo = ap.id_comptage_methodo))) JOIN (SELECT c.indexzp, array_to_string(array_agg((((r.prenom_role)::text || ' '::text) || (r.nom_role)::text)), ', '::text) AS observateurs FROM (cor_zp_obs c JOIN utilisateurs.t_roles r ON ((r.id_role = c.codeobs))) GROUP BY c.indexzp) o ON ((o.indexzp = ap.indexzp))) LEFT JOIN (SELECT c.indexap, array_to_string(array_agg(((((per.description)::text || ' ('::text) || (per.classification)::text) || ')'::text)), ', '::text) AS perturbations FROM (cor_ap_perturb c JOIN bib_perturbations per ON ((per.codeper = c.codeper))) GROUP BY c.indexap) per ON ((per.indexap = ap.indexap))) LEFT JOIN (SELECT p.indexap, array_to_string(array_agg(((((phy.nom_physionomie)::text || ' ('::text) || (phy.groupe_physionomie)::text) || ')'::text)), ', '::text) AS physionomies FROM (cor_ap_physionomie p JOIN bib_physionomies phy ON ((phy.id_physionomie = p.id_physionomie))) GROUP BY p.indexap) phy ON ((phy.indexap = ap.indexap))) WHERE ((ap.supprime = false) AND (public.geometrytype(ap.the_geom_2154) = 'POINT'::text)) ORDER BY s.nom_secteur, ap.indexzp;

--
-- TOC entry 338 (class 1259 OID 167999)
-- Name: v_touteslesap_2154_polygon; Type: VIEW; Schema: florepatri; Owner: -
--

CREATE VIEW v_touteslesap_2154_polygon AS
SELECT ap.indexap AS gid, ap.indexzp, ap.indexap, s.nom_secteur AS secteur, zp.dateobs, t.latin AS taxon, o.observateurs, p.pheno AS phenologie, ap.surfaceap, ap.insee, com.commune_min, ap.altitude_retenue AS altitude, f.nom_frequence_methodo_new AS met_frequence, ap.frequenceap, compt.nom_comptage_methodo AS met_comptage, ap.total_fertiles AS tot_fertiles, ap.total_steriles AS tot_steriles, per.perturbations, phy.physionomies, ap.the_geom_2154, ap.topo_valid AS ap_topo_valid, zp.validation AS relue, ap.remarques FROM ((((((((((t_apresence ap JOIN t_zprospection zp ON ((ap.indexzp = zp.indexzp))) JOIN bib_taxons_fp t ON ((t.cd_nom = zp.cd_nom))) JOIN layers.l_secteurs s ON ((s.id_secteur = zp.id_secteur))) JOIN bib_phenologies p ON ((p.codepheno = ap.codepheno))) JOIN layers.l_communes com ON (((com.insee)::bpchar = ap.insee))) JOIN bib_frequences_methodo_new f ON ((f.id_frequence_methodo_new = ap.id_frequence_methodo_new))) JOIN bib_comptages_methodo compt ON ((compt.id_comptage_methodo = ap.id_comptage_methodo))) JOIN (SELECT c.indexzp, array_to_string(array_agg((((r.prenom_role)::text || ' '::text) || (r.nom_role)::text)), ', '::text) AS observateurs FROM (cor_zp_obs c JOIN utilisateurs.t_roles r ON ((r.id_role = c.codeobs))) GROUP BY c.indexzp) o ON ((o.indexzp = ap.indexzp))) LEFT JOIN (SELECT c.indexap, array_to_string(array_agg(((((per.description)::text || ' ('::text) || (per.classification)::text) || ')'::text)), ', '::text) AS perturbations FROM (cor_ap_perturb c JOIN bib_perturbations per ON ((per.codeper = c.codeper))) GROUP BY c.indexap) per ON ((per.indexap = ap.indexap))) LEFT JOIN (SELECT p.indexap, array_to_string(array_agg(((((phy.nom_physionomie)::text || ' ('::text) || (phy.groupe_physionomie)::text) || ')'::text)), ', '::text) AS physionomies FROM (cor_ap_physionomie p JOIN bib_physionomies phy ON ((phy.id_physionomie = p.id_physionomie))) GROUP BY p.indexap) phy ON ((phy.indexap = ap.indexap))) WHERE ((ap.supprime = false) AND (public.geometrytype(ap.the_geom_2154) = 'POLYGON'::text)) ORDER BY s.nom_secteur, ap.indexzp;

--
-- TOC entry 339 (class 1259 OID 168004)
-- Name: v_toutesleszp_2154; Type: VIEW; Schema: florepatri; Owner: -
--

CREATE VIEW v_toutesleszp_2154 AS
SELECT zp.indexzp AS gid, zp.indexzp, s.nom_secteur AS secteur, count(ap.indexap) AS nbap, zp.dateobs, t.latin AS taxon, zp.taxon_saisi, o.observateurs, zp.the_geom_2154, zp.insee, com.commune_min AS commune, org.nom_organisme AS organisme_producteur, zp.topo_valid AS zp_topo_valid, zp.validation AS relue, zp.saisie_initiale, zp.srid_dessin FROM ((((((t_zprospection zp LEFT JOIN t_apresence ap ON ((ap.indexzp = zp.indexzp))) LEFT JOIN layers.l_communes com ON (((com.insee)::bpchar = zp.insee))) LEFT JOIN utilisateurs.bib_organismes org ON ((org.id_organisme = zp.id_organisme))) JOIN bib_taxons_fp t ON ((t.cd_nom = zp.cd_nom))) JOIN layers.l_secteurs s ON ((s.id_secteur = zp.id_secteur))) JOIN (SELECT c.indexzp, array_to_string(array_agg((((r.prenom_role)::text || ' '::text) || (r.nom_role)::text)), ', '::text) AS observateurs FROM (cor_zp_obs c JOIN utilisateurs.t_roles r ON ((r.id_role = c.codeobs))) GROUP BY c.indexzp) o ON ((o.indexzp = zp.indexzp))) WHERE (zp.supprime = false) GROUP BY s.nom_secteur, zp.indexzp, zp.dateobs, t.latin, zp.taxon_saisi, o.observateurs, zp.the_geom_2154, zp.insee, com.commune_min, org.nom_organisme, zp.topo_valid, zp.validation, zp.saisie_initiale, zp.srid_dessin ORDER BY s.nom_secteur, zp.indexzp;

--
-- TOC entry 304 (class 1259 OID 95759)
-- Name: v_ap_line; Type: VIEW; Schema: florepatri; Owner: -
--

CREATE VIEW v_ap_line AS
SELECT a.indexap, a.indexzp, a.surfaceap AS surface, a.altitude_saisie AS altitude, a.id_frequence_methodo_new AS id_frequence_methodo, a.the_geom_2154, a.frequenceap, a.topo_valid, a.date_update, a.supprime, a.date_insert FROM t_apresence a WHERE ((public.geometrytype(a.the_geom_2154) = 'MULTILINESTRING'::text) OR (public.geometrytype(a.the_geom_2154) = 'LINESTRING'::text));

--
-- TOC entry 303 (class 1259 OID 95755)
-- Name: v_ap_point; Type: VIEW; Schema: florepatri; Owner: -
--

CREATE VIEW v_ap_point AS
SELECT a.indexap, a.indexzp, a.surfaceap AS surface, a.altitude_saisie AS altitude, a.id_frequence_methodo_new AS id_frequence_methodo, a.the_geom_2154, a.frequenceap, a.topo_valid, a.date_update, a.supprime, a.date_insert FROM t_apresence a WHERE ((public.geometrytype(a.the_geom_2154) = 'POINT'::text) OR (public.geometrytype(a.the_geom_2154) = 'MULTIPOINT'::text));

--
-- TOC entry 302 (class 1259 OID 95751)
-- Name: v_ap_poly; Type: VIEW; Schema: florepatri; Owner: -
--

CREATE VIEW v_ap_poly AS
SELECT a.indexap, a.indexzp, a.surfaceap AS surface, a.altitude_saisie AS altitude, a.id_frequence_methodo_new AS id_frequence_methodo, a.the_geom_2154, a.frequenceap, a.topo_valid, a.date_update, a.supprime, a.date_insert FROM t_apresence a WHERE ((public.geometrytype(a.the_geom_2154) = 'POLYGON'::text) OR (public.geometrytype(a.the_geom_2154) = 'MULTIPOLYGON'::text));

--
-- TOC entry 324 (class 1259 OID 166439)
-- Name: v_mobile_pentes; Type: VIEW; Schema: florepatri; Owner: -
--

CREATE VIEW v_mobile_pentes AS
SELECT bib_pentes.id_pente, bib_pentes.val_pente, bib_pentes.nom_pente FROM bib_pentes ORDER BY bib_pentes.id_pente;

--
-- TOC entry 325 (class 1259 OID 166443)
-- Name: v_mobile_perturbations; Type: VIEW; Schema: florepatri; Owner: -
--

CREATE VIEW v_mobile_perturbations AS
SELECT bib_perturbations.codeper, bib_perturbations.classification, bib_perturbations.description FROM bib_perturbations ORDER BY bib_perturbations.codeper;

--
-- TOC entry 327 (class 1259 OID 166451)
-- Name: v_mobile_phenologies; Type: VIEW; Schema: florepatri; Owner: -
--

CREATE VIEW v_mobile_phenologies AS
SELECT bib_phenologies.codepheno, bib_phenologies.pheno FROM bib_phenologies ORDER BY bib_phenologies.codepheno;

--
-- TOC entry 326 (class 1259 OID 166447)
-- Name: v_mobile_physionomies; Type: VIEW; Schema: florepatri; Owner: -
--

CREATE VIEW v_mobile_physionomies AS
SELECT bib_physionomies.id_physionomie, bib_physionomies.groupe_physionomie, bib_physionomies.nom_physionomie FROM bib_physionomies ORDER BY bib_physionomies.id_physionomie;

--
-- TOC entry 323 (class 1259 OID 166435)
-- Name: v_mobile_taxons_fp; Type: VIEW; Schema: florepatri; Owner: -
--

CREATE VIEW v_mobile_taxons_fp AS
SELECT bt.cd_nom, bt.latin AS nom_latin, bt.francais AS nom_francais FROM bib_taxons_fp bt WHERE (bt.nomade_ecrins = true) ORDER BY bt.latin;

--
-- TOC entry 202 (class 1259 OID 55483)
-- Name: v_mobile_visu_zp; Type: VIEW; Schema: florepatri; Owner: -
--

CREATE VIEW v_mobile_visu_zp AS
SELECT t_zprospection.indexzp, t_zprospection.cd_nom, t_zprospection.the_geom_2154 FROM t_zprospection WHERE (date_part('year'::text, t_zprospection.dateobs) = date_part('year'::text, now()));

--
-- TOC entry 203 (class 1259 OID 55487)
-- Name: v_nomade_taxon; Type: VIEW; Schema: florepatri; Owner: -
--

CREATE VIEW v_nomade_taxon AS
SELECT bt.cd_nom, bt.latin, bt.francais, bt.echelle, '1,2,3,4,5,6,7,8'::character(15) AS codepheno, 'TF,RS'::character(5) AS codeobjet FROM bib_taxons_fp bt WHERE (bt.nomade_ecrins = true) ORDER BY bt.latin;

--
-- TOC entry 204 (class 1259 OID 55491)
-- Name: v_nomade_zp; Type: VIEW; Schema: florepatri; Owner: -
--

CREATE VIEW v_nomade_zp AS
SELECT zp.indexzp, zp.cd_nom, vobs.codeobs, zp.dateobs, 'Polygon'::character(7) AS montype, substr(public.st_asgml(zp.the_geom_2154), (strpos(public.st_asgml(zp.the_geom_2154), '<gml:coordinates>'::text) + 17), (strpos(public.st_asgml(zp.the_geom_2154), '</gml:coordinates>'::text) - (strpos(public.st_asgml(zp.the_geom_2154), '<gml:coordinates>'::text) + 17))) AS coordinates, vap.indexap, zp.id_secteur AS id_secteur_fp FROM ((t_zprospection zp JOIN (SELECT cor.indexzp, substr((array_agg(cor.codeobs))::text, 2, (strpos((array_agg(cor.codeobs))::text, '}'::text) - 2)) AS codeobs FROM (SELECT aa.indexzp, aa.codeobs FROM cor_zp_obs aa WHERE (aa.codeobs <> 247) ORDER BY aa.indexzp, aa.codeobs) cor GROUP BY cor.indexzp) vobs ON ((vobs.indexzp = zp.indexzp))) LEFT JOIN (SELECT ap.indexzp, substr((array_agg(ap.indexap))::text, 2, (strpos((array_agg(ap.indexap))::text, '}'::text) - 2)) AS indexap FROM (SELECT aa.indexzp, aa.indexap FROM t_apresence aa WHERE (aa.supprime = false) ORDER BY aa.indexzp, aa.indexap) ap GROUP BY ap.indexzp) vap ON ((vap.indexzp = zp.indexzp))) WHERE (((((zp.topo_valid = true) AND (zp.supprime = false)) AND (zp.id_secteur < 9)) AND (zp.dateobs > '2010-01-01'::date)) AND (zp.cd_nom IN (SELECT v_nomade_taxon.cd_nom FROM v_nomade_taxon))) ORDER BY zp.indexzp;

--
-- TOC entry 205 (class 1259 OID 55496)
-- Name: v_nomade_ap; Type: VIEW; Schema: florepatri; Owner: -
--

CREATE VIEW v_nomade_ap AS
SELECT ap.indexap, ap.codepheno, letypedegeom(ap.the_geom_2154) AS montype, substr(public.st_asgml(ap.the_geom_2154), (strpos(public.st_asgml(ap.the_geom_2154), '<gml:coordinates>'::text) + 17), (strpos(public.st_asgml(ap.the_geom_2154), '</gml:coordinates>'::text) - (strpos(public.st_asgml(ap.the_geom_2154), '<gml:coordinates>'::text) + 17))) AS coordinates, ap.surfaceap, (((ap.id_frequence_methodo_new)::text || ';'::text) || (ap.frequenceap)::integer) AS frequence, vper.codeper, ((('TF;'::text || ((ap.total_fertiles)::character(1))::text) || ',RS;'::text) || ((ap.total_steriles)::character(1))::text) AS denombrement, zp.id_secteur_fp FROM ((t_apresence ap JOIN v_nomade_zp zp ON ((ap.indexzp = zp.indexzp))) LEFT JOIN (SELECT ab.indexap, substr((array_agg(ab.codeper))::text, 2, (strpos((array_agg(ab.codeper))::text, '}'::text) - 2)) AS codeper FROM (SELECT aa.indexap, aa.codeper FROM cor_ap_perturb aa ORDER BY aa.indexap, aa.codeper) ab GROUP BY ab.indexap) vper ON ((vper.indexap = ap.indexap))) WHERE (ap.supprime = false) ORDER BY ap.indexap;



SET search_path = florestation, pg_catalog;

--
-- TOC entry 229 (class 1259 OID 55636)
-- Name: v_florestation_all; Type: VIEW; Schema: florestation; Owner: -
--

CREATE VIEW v_florestation_all AS
SELECT cor.id_station_cd_nom AS indexbidon, fs.id_station, fs.dateobs, cor.cd_nom, btrim((tr.nom_valide)::text) AS nom_valid, btrim((tr.nom_vern)::text) AS nom_vern, public.st_transform(fs.the_geom_2154, 2154) AS the_geom FROM ((t_stations_fs fs JOIN cor_fs_taxon cor ON ((cor.id_station = fs.id_station))) JOIN taxonomie.taxref tr ON ((cor.cd_nom = tr.cd_nom))) WHERE ((fs.supprime = false) AND (cor.supprime = false));

--
-- TOC entry 230 (class 1259 OID 55641)
-- Name: v_florestation_patrimoniale; Type: VIEW; Schema: florestation; Owner: -
--

CREATE VIEW v_florestation_patrimoniale AS
SELECT cor.id_station_cd_nom AS indexbidon, fs.id_station, bt.francais, bt.latin, fs.dateobs, fs.the_geom_2154 FROM ((t_stations_fs fs JOIN cor_fs_taxon cor ON ((cor.id_station = fs.id_station))) JOIN florepatri.bib_taxons_fp bt ON ((cor.cd_nom = bt.cd_nom))) WHERE ((fs.supprime = false) AND (cor.supprime = false)) ORDER BY fs.id_station, bt.latin;

--
-- TOC entry 231 (class 1259 OID 55646)
-- Name: v_taxons_fs; Type: VIEW; Schema: florestation; Owner: -
--

CREATE VIEW v_taxons_fs AS
SELECT t.cd_nom, t.nom_complet FROM (taxonomie.taxref t JOIN ((SELECT DISTINCT t.cd_ref FROM ((taxonomie.taxref t JOIN cor_fs_taxon c ON ((c.cd_nom = t.cd_nom))) RIGHT JOIN t_stations_fs s ON ((s.id_station = c.id_station))) WHERE ((s.supprime = false) AND (c.supprime = false)) ORDER BY t.cd_ref) UNION SELECT t.cd_ref FROM taxonomie.taxref t WHERE (t.cd_nom = ANY (ARRAY[106226, 95136, 134738, 91823, 109422, 84904, 113388, 97502, 138537, 611325, 81376, 115437, 127191, 115228, 88108, 137138, 139803, 89840, 124967, 82656, 136028, 97785, 117952, 112747, 117933, 125337, 123156, 111297, 1000001, 131447, 122118, 134958, 99882, 111311, 123711, 90319, 111996, 89881, 97262, 117951, 95186, 98474, 115110, 90259, 119818, 126541, 117087, 87690, 131610, 127450, 116265, 97502, 125816, 104221, 95398, 138515, 86429, 83528, 110994, 121039, 110410, 87143, 110421, 82285, 126628, 103478, 129325, 81065, 81166, 106220, 90561, 86948, 73574, 73558]))) a ON ((a.cd_ref = t.cd_nom)));


SET search_path = contactfaune, pg_catalog;

--
-- Name: gid; Type: DEFAULT; Schema: contactfaune; Owner: -
--

ALTER TABLE ONLY t_releves_cf ALTER COLUMN gid SET DEFAULT nextval('t_releves_cf_gid_seq'::regclass);


SET search_path = contactinv, pg_catalog;

--
-- Name: gid; Type: DEFAULT; Schema: contactinv; Owner: -
--

ALTER TABLE ONLY t_releves_inv ALTER COLUMN gid SET DEFAULT nextval('t_releves_inv_gid_seq'::regclass);


SET search_path = layers, pg_catalog;

--
-- Name: gid; Type: DEFAULT; Schema: layers; Owner: -
--

ALTER TABLE ONLY l_isolines20 ALTER COLUMN gid SET DEFAULT nextval('l_isolines20_gid_seq'::regclass);


SET search_path = synchronomade, pg_catalog;

--
-- Name: id; Type: DEFAULT; Schema: synchronomade; Owner: -
--

ALTER TABLE ONLY erreurs_cf ALTER COLUMN id SET DEFAULT nextval('erreurs_cf_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: synchronomade; Owner: -
--

ALTER TABLE ONLY erreurs_inv ALTER COLUMN id SET DEFAULT nextval('erreurs_inv_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: synchronomade; Owner: -
--

ALTER TABLE ONLY erreurs_mortalite ALTER COLUMN id SET DEFAULT nextval('erreurs_mortalite_id_seq'::regclass);


--
-- TOC entry 3363 (class 2604 OID 166468)
-- Name: id; Type: DEFAULT; Schema: synchronomade; Owner: -
--

ALTER TABLE ONLY erreurs_flora ALTER COLUMN id SET DEFAULT nextval('erreurs_flora_id_seq'::regclass);


SET search_path = synthese, pg_catalog;

--
-- Name: id_synthese; Type: DEFAULT; Schema: synthese; Owner: -
--

ALTER TABLE ONLY syntheseff ALTER COLUMN id_synthese SET DEFAULT nextval('syntheseff_id_synthese_seq'::regclass);


SET search_path = taxonomie, pg_catalog;

--
-- Name: id_liste; Type: DEFAULT; Schema: taxonomie; Owner: -
--

ALTER TABLE ONLY bib_listes ALTER COLUMN id_liste SET DEFAULT nextval('bib_listes_id_liste_seq'::regclass);

--
-- Name: id_attribut; Type: DEFAULT; Schema: taxonomie; Owner: -
--

ALTER TABLE ONLY bib_attributs ALTER COLUMN id_attribut SET DEFAULT nextval('bib_attributs_id_attribut_seq'::regclass);


SET search_path = utilisateurs, pg_catalog;

--
-- Name: id_application; Type: DEFAULT; Schema: utilisateurs; Owner: -
--

ALTER TABLE ONLY t_applications ALTER COLUMN id_application SET DEFAULT nextval('t_applications_id_application_seq'::regclass);


--
-- Name: id_menu; Type: DEFAULT; Schema: utilisateurs; Owner: -
--

ALTER TABLE ONLY t_menus ALTER COLUMN id_menu SET DEFAULT nextval('t_menus_id_menu_seq'::regclass);


SET search_path = bryophytes, pg_catalog;

--
-- TOC entry 3290 (class 2604 OID 55987)
-- Name: id_station_cd_nom; Type: DEFAULT; Schema: bryophytes; Owner: -
--

ALTER TABLE ONLY cor_bryo_taxon ALTER COLUMN id_station_cd_nom SET DEFAULT nextval('cor_bryo_taxon_id_station_cd_nom_seq'::regclass);


--
-- TOC entry 3297 (class 2604 OID 55988)
-- Name: gid; Type: DEFAULT; Schema: bryophytes; Owner: -
--

ALTER TABLE ONLY t_stations_bryo ALTER COLUMN gid SET DEFAULT nextval('t_stations_bryo_gid_seq'::regclass);


SET search_path = florestation, pg_catalog;

--
-- TOC entry 3341 (class 2604 OID 55992)
-- Name: id_station_cd_nom; Type: DEFAULT; Schema: florestation; Owner: -
--

ALTER TABLE ONLY cor_fs_taxon ALTER COLUMN id_station_cd_nom SET DEFAULT nextval('cor_fs_taxon_id_station_cd_nom_seq'::regclass);


--
-- TOC entry 3359 (class 2604 OID 55993)
-- Name: gid; Type: DEFAULT; Schema: florestation; Owner: -
--

ALTER TABLE ONLY t_stations_fs ALTER COLUMN gid SET DEFAULT nextval('t_stations_fs_gid_seq'::regclass);


SET search_path = contactfaune, pg_catalog;

--
-- Name: pk_bib_criteres_cf; Type: CONSTRAINT; Schema: contactfaune; Owner: -; Tablespace: 
--

ALTER TABLE ONLY bib_criteres_cf
    ADD CONSTRAINT pk_bib_criteres_cf PRIMARY KEY (id_critere_cf);


--
-- Name: pk_bib_types_comptage; Type: CONSTRAINT; Schema: contactfaune; Owner: -; Tablespace: 
--

ALTER TABLE ONLY bib_messages_cf
    ADD CONSTRAINT pk_bib_types_comptage PRIMARY KEY (id_message_cf);


--
-- Name: pk_cor_critere_groupe; Type: CONSTRAINT; Schema: contactfaune; Owner: -; Tablespace: 
--

ALTER TABLE ONLY cor_critere_groupe
    ADD CONSTRAINT pk_cor_critere_groupe PRIMARY KEY (id_critere_cf, id_groupe);


--
-- Name: pk_cor_message_taxon; Type: CONSTRAINT; Schema: contactfaune; Owner: -; Tablespace: 
--

ALTER TABLE ONLY cor_message_taxon
    ADD CONSTRAINT pk_cor_message_taxon PRIMARY KEY (id_message_cf, id_taxon);


--
-- Name: pk_cor_role_fiche_cf; Type: CONSTRAINT; Schema: contactfaune; Owner: -; Tablespace: 
--

ALTER TABLE ONLY cor_role_fiche_cf
    ADD CONSTRAINT pk_cor_role_fiche_cf PRIMARY KEY (id_cf, id_role);


--
-- Name: pk_cor_unite_taxon; Type: CONSTRAINT; Schema: contactfaune; Owner: -; Tablespace: 
--

ALTER TABLE ONLY cor_unite_taxon
    ADD CONSTRAINT pk_cor_unite_taxon PRIMARY KEY (id_unite_geo, id_taxon);


--
-- Name: pk_log_colors; Type: CONSTRAINT; Schema: contactfaune; Owner: -; Tablespace: 
--

ALTER TABLE ONLY log_colors
    ADD CONSTRAINT pk_log_colors PRIMARY KEY (annee, mois, id_unite_geo, couleur);


--
-- Name: pk_log_colors_day; Type: CONSTRAINT; Schema: contactfaune; Owner: -; Tablespace: 
--

ALTER TABLE ONLY log_colors_day
    ADD CONSTRAINT pk_log_colors_day PRIMARY KEY (jour, couleur);


--
-- Name: pk_t_fiches_cf; Type: CONSTRAINT; Schema: contactfaune; Owner: -; Tablespace: 
--

ALTER TABLE ONLY t_fiches_cf
    ADD CONSTRAINT pk_t_fiches_cf PRIMARY KEY (id_cf);


--
-- Name: pk_t_releves_cf; Type: CONSTRAINT; Schema: contactfaune; Owner: -; Tablespace: 
--

ALTER TABLE ONLY t_releves_cf
    ADD CONSTRAINT pk_t_releves_cf PRIMARY KEY (id_releve_cf);


SET search_path = contactinv, pg_catalog;

--
-- Name: pk_bib_criteres_inv; Type: CONSTRAINT; Schema: contactinv; Owner: -; Tablespace: 
--

ALTER TABLE ONLY bib_criteres_inv
    ADD CONSTRAINT pk_bib_criteres_inv PRIMARY KEY (id_critere_inv);


--
-- Name: pk_bib_milieux_inv; Type: CONSTRAINT; Schema: contactinv; Owner: -; Tablespace: 
--

ALTER TABLE ONLY bib_milieux_inv
    ADD CONSTRAINT pk_bib_milieux_inv PRIMARY KEY (id_milieu_inv);


--
-- Name: pk_bib_types_comptage; Type: CONSTRAINT; Schema: contactinv; Owner: -; Tablespace: 
--

ALTER TABLE ONLY bib_messages_inv
    ADD CONSTRAINT pk_bib_types_comptage PRIMARY KEY (id_message_inv);


--
-- Name: pk_cor_message_taxon_inv; Type: CONSTRAINT; Schema: contactinv; Owner: -; Tablespace: 
--

ALTER TABLE ONLY cor_message_taxon
    ADD CONSTRAINT pk_cor_message_taxon_inv PRIMARY KEY (id_message_inv, id_taxon);


--
-- Name: pk_cor_role_fiche_inv; Type: CONSTRAINT; Schema: contactinv; Owner: -; Tablespace: 
--

ALTER TABLE ONLY cor_role_fiche_inv
    ADD CONSTRAINT pk_cor_role_fiche_inv PRIMARY KEY (id_inv, id_role);


--
-- Name: pk_cor_unite_taxon_inv; Type: CONSTRAINT; Schema: contactinv; Owner: -; Tablespace: 
--

ALTER TABLE ONLY cor_unite_taxon_inv
    ADD CONSTRAINT pk_cor_unite_taxon_inv PRIMARY KEY (id_unite_geo, id_taxon);


--
-- Name: pk_log_colors_day_inv; Type: CONSTRAINT; Schema: contactinv; Owner: -; Tablespace: 
--

ALTER TABLE ONLY log_colors_day
    ADD CONSTRAINT pk_log_colors_day_inv PRIMARY KEY (jour, couleur);


--
-- Name: pk_log_colors_inv; Type: CONSTRAINT; Schema: contactinv; Owner: -; Tablespace: 
--

ALTER TABLE ONLY log_colors
    ADD CONSTRAINT pk_log_colors_inv PRIMARY KEY (annee, mois, id_unite_geo, couleur);


--
-- Name: pk_t_fiches_inv; Type: CONSTRAINT; Schema: contactinv; Owner: -; Tablespace: 
--

ALTER TABLE ONLY t_fiches_inv
    ADD CONSTRAINT pk_t_fiches_inv PRIMARY KEY (id_inv);


--
-- Name: pk_t_releves_inv; Type: CONSTRAINT; Schema: contactinv; Owner: -; Tablespace: 
--

ALTER TABLE ONLY t_releves_inv
    ADD CONSTRAINT pk_t_releves_inv PRIMARY KEY (id_releve_inv);

SET search_path = bryophytes, pg_catalog;

--
-- TOC entry 3365 (class 2606 OID 70342)
-- Name: pk_bib_abondances; Type: CONSTRAINT; Schema: bryophytes; Owner: -; Tablespace: 
--

ALTER TABLE ONLY bib_abondances
    ADD CONSTRAINT pk_bib_abondances PRIMARY KEY (id_abondance);


--
-- TOC entry 3367 (class 2606 OID 70344)
-- Name: pk_bib_expositions; Type: CONSTRAINT; Schema: bryophytes; Owner: -; Tablespace: 
--

ALTER TABLE ONLY bib_expositions
    ADD CONSTRAINT pk_bib_expositions PRIMARY KEY (id_exposition);


--
-- TOC entry 3369 (class 2606 OID 70346)
-- Name: pk_cor_bryo_observateur; Type: CONSTRAINT; Schema: bryophytes; Owner: -; Tablespace: 
--

ALTER TABLE ONLY cor_bryo_observateur
    ADD CONSTRAINT pk_cor_bryo_observateur PRIMARY KEY (id_role, id_station);


--
-- TOC entry 3372 (class 2606 OID 70348)
-- Name: pk_cor_bryo_taxons; Type: CONSTRAINT; Schema: bryophytes; Owner: -; Tablespace: 
--

ALTER TABLE ONLY cor_bryo_taxon
    ADD CONSTRAINT pk_cor_bryo_taxons PRIMARY KEY (id_station, cd_nom);


--
-- TOC entry 3377 (class 2606 OID 70350)
-- Name: pk_t_stations_bryo; Type: CONSTRAINT; Schema: bryophytes; Owner: -; Tablespace: 
--

ALTER TABLE ONLY t_stations_bryo
    ADD CONSTRAINT pk_t_stations_bryo PRIMARY KEY (id_station);


--
-- TOC entry 3379 (class 2606 OID 70352)
-- Name: t_stations_bryo_gid_key; Type: CONSTRAINT; Schema: bryophytes; Owner: -; Tablespace: 
--

ALTER TABLE ONLY t_stations_bryo
    ADD CONSTRAINT t_stations_bryo_gid_key UNIQUE (gid);


SET search_path = florepatri, pg_catalog;

--
-- TOC entry 3408 (class 2606 OID 70366)
-- Name: _t_apresence_pkey; Type: CONSTRAINT; Schema: florepatri; Owner: -; Tablespace: 
--

ALTER TABLE ONLY t_apresence
    ADD CONSTRAINT _t_apresence_pkey PRIMARY KEY (indexap);


--
-- TOC entry 3412 (class 2606 OID 70368)
-- Name: _t_zprospection_pkey; Type: CONSTRAINT; Schema: florepatri; Owner: -; Tablespace: 
--

ALTER TABLE ONLY t_zprospection
    ADD CONSTRAINT _t_zprospection_pkey PRIMARY KEY (indexzp);


--
-- TOC entry 3381 (class 2606 OID 70370)
-- Name: bib_comptages_methodo_pkey; Type: CONSTRAINT; Schema: florepatri; Owner: -; Tablespace: 
--

ALTER TABLE ONLY bib_comptages_methodo
    ADD CONSTRAINT bib_comptages_methodo_pkey PRIMARY KEY (id_comptage_methodo);


--
-- TOC entry 3383 (class 2606 OID 70372)
-- Name: bib_frequences_methodo_new_pkey; Type: CONSTRAINT; Schema: florepatri; Owner: -; Tablespace: 
--

ALTER TABLE ONLY bib_frequences_methodo_new
    ADD CONSTRAINT bib_frequences_methodo_new_pkey PRIMARY KEY (id_frequence_methodo_new);


--
-- TOC entry 3385 (class 2606 OID 70374)
-- Name: bib_pentes_pkey; Type: CONSTRAINT; Schema: florepatri; Owner: -; Tablespace: 
--

ALTER TABLE ONLY bib_pentes
    ADD CONSTRAINT bib_pentes_pkey PRIMARY KEY (id_pente);


--
-- TOC entry 3391 (class 2606 OID 70376)
-- Name: bib_physionomies_pk; Type: CONSTRAINT; Schema: florepatri; Owner: -; Tablespace: 
--

ALTER TABLE ONLY bib_physionomies
    ADD CONSTRAINT bib_physionomies_pk PRIMARY KEY (id_physionomie);


--
-- TOC entry 3393 (class 2606 OID 70378)
-- Name: bib_rezo_ecrins_pkey; Type: CONSTRAINT; Schema: florepatri; Owner: -; Tablespace: 
--

ALTER TABLE ONLY bib_rezo_ecrins
    ADD CONSTRAINT bib_rezo_ecrins_pkey PRIMARY KEY (id_rezo_ecrins);


--
-- TOC entry 3397 (class 2606 OID 70380)
-- Name: bib_taxons_fp_pkey; Type: CONSTRAINT; Schema: florepatri; Owner: -; Tablespace: 
--

ALTER TABLE ONLY bib_taxons_fp
    ADD CONSTRAINT bib_taxons_fp_pkey PRIMARY KEY (cd_nom);


--
-- TOC entry 3405 (class 2606 OID 70382)
-- Name: cor_zp_obs_pkey; Type: CONSTRAINT; Schema: florepatri; Owner: -; Tablespace: 
--

ALTER TABLE ONLY cor_zp_obs
    ADD CONSTRAINT cor_zp_obs_pkey PRIMARY KEY (indexzp, codeobs);


--
-- TOC entry 3387 (class 2606 OID 70384)
-- Name: pk_bib_perturbation; Type: CONSTRAINT; Schema: florepatri; Owner: -; Tablespace: 
--

ALTER TABLE ONLY bib_perturbations
    ADD CONSTRAINT pk_bib_perturbation PRIMARY KEY (codeper);


--
-- TOC entry 3389 (class 2606 OID 70386)
-- Name: pk_bib_phenologie; Type: CONSTRAINT; Schema: florepatri; Owner: -; Tablespace: 
--

ALTER TABLE ONLY bib_phenologies
    ADD CONSTRAINT pk_bib_phenologie PRIMARY KEY (codepheno);


--
-- TOC entry 3395 (class 2606 OID 70388)
-- Name: pk_bib_statuts; Type: CONSTRAINT; Schema: florepatri; Owner: -; Tablespace: 
--

ALTER TABLE ONLY bib_statuts
    ADD CONSTRAINT pk_bib_statuts PRIMARY KEY (id_statut);


--
-- TOC entry 3399 (class 2606 OID 70390)
-- Name: pk_cor_ap_perturb; Type: CONSTRAINT; Schema: florepatri; Owner: -; Tablespace: 
--

ALTER TABLE ONLY cor_ap_perturb
    ADD CONSTRAINT pk_cor_ap_perturb PRIMARY KEY (indexap, codeper);


--
-- TOC entry 3401 (class 2606 OID 70392)
-- Name: pk_cor_ap_physionomie; Type: CONSTRAINT; Schema: florepatri; Owner: -; Tablespace: 
--

ALTER TABLE ONLY cor_ap_physionomie
    ADD CONSTRAINT pk_cor_ap_physionomie PRIMARY KEY (indexap, id_physionomie);


--
-- TOC entry 3403 (class 2606 OID 70394)
-- Name: pk_cor_taxon_statut; Type: CONSTRAINT; Schema: florepatri; Owner: -; Tablespace: 
--

ALTER TABLE ONLY cor_taxon_statut
    ADD CONSTRAINT pk_cor_taxon_statut PRIMARY KEY (id_statut, cd_nom);


SET search_path = florestation, pg_catalog;

--
-- TOC entry 3415 (class 2606 OID 70396)
-- Name: pk_bib_abondances; Type: CONSTRAINT; Schema: florestation; Owner: -; Tablespace: 
--

ALTER TABLE ONLY bib_abondances
    ADD CONSTRAINT pk_bib_abondances PRIMARY KEY (id_abondance);


--
-- TOC entry 3417 (class 2606 OID 70398)
-- Name: pk_bib_expositions; Type: CONSTRAINT; Schema: florestation; Owner: -; Tablespace: 
--

ALTER TABLE ONLY bib_expositions
    ADD CONSTRAINT pk_bib_expositions PRIMARY KEY (id_exposition);


--
-- TOC entry 3419 (class 2606 OID 70400)
-- Name: pk_bib_homogenes; Type: CONSTRAINT; Schema: florestation; Owner: -; Tablespace: 
--

ALTER TABLE ONLY bib_homogenes
    ADD CONSTRAINT pk_bib_homogenes PRIMARY KEY (id_homogene);


--
-- TOC entry 3421 (class 2606 OID 70402)
-- Name: pk_bib_microreliefs; Type: CONSTRAINT; Schema: florestation; Owner: -; Tablespace: 
--

ALTER TABLE ONLY bib_microreliefs
    ADD CONSTRAINT pk_bib_microreliefs PRIMARY KEY (id_microrelief);


--
-- TOC entry 3423 (class 2606 OID 70404)
-- Name: pk_bib_programmes_fs; Type: CONSTRAINT; Schema: florestation; Owner: -; Tablespace: 
--

ALTER TABLE ONLY bib_programmes_fs
    ADD CONSTRAINT pk_bib_programmes_fs PRIMARY KEY (id_programme_fs);


--
-- TOC entry 3425 (class 2606 OID 70406)
-- Name: pk_bib_surfaces; Type: CONSTRAINT; Schema: florestation; Owner: -; Tablespace: 
--

ALTER TABLE ONLY bib_surfaces
    ADD CONSTRAINT pk_bib_surfaces PRIMARY KEY (id_surface);


--
-- TOC entry 3427 (class 2606 OID 70408)
-- Name: pk_cor_fs_delphine; Type: CONSTRAINT; Schema: florestation; Owner: -; Tablespace: 
--

ALTER TABLE ONLY cor_fs_delphine
    ADD CONSTRAINT pk_cor_fs_delphine PRIMARY KEY (id_station, id_delphine);


--
-- TOC entry 3429 (class 2606 OID 70410)
-- Name: pk_cor_fs_microrelief; Type: CONSTRAINT; Schema: florestation; Owner: -; Tablespace: 
--

ALTER TABLE ONLY cor_fs_microrelief
    ADD CONSTRAINT pk_cor_fs_microrelief PRIMARY KEY (id_station, id_microrelief);


--
-- TOC entry 3431 (class 2606 OID 70412)
-- Name: pk_cor_fs_observateur; Type: CONSTRAINT; Schema: florestation; Owner: -; Tablespace: 
--

ALTER TABLE ONLY cor_fs_observateur
    ADD CONSTRAINT pk_cor_fs_observateur PRIMARY KEY (id_role, id_station);


--
-- TOC entry 3434 (class 2606 OID 70414)
-- Name: pk_cor_fs_taxons; Type: CONSTRAINT; Schema: florestation; Owner: -; Tablespace: 
--

ALTER TABLE ONLY cor_fs_taxon
    ADD CONSTRAINT pk_cor_fs_taxons PRIMARY KEY (id_station, cd_nom);


--
-- TOC entry 3441 (class 2606 OID 70416)
-- Name: pk_t_stations_fs; Type: CONSTRAINT; Schema: florestation; Owner: -; Tablespace: 
--

ALTER TABLE ONLY t_stations_fs
    ADD CONSTRAINT pk_t_stations_fs PRIMARY KEY (id_station);


--
-- TOC entry 3443 (class 2606 OID 70418)
-- Name: t_stations_fs_gid_key; Type: CONSTRAINT; Schema: florestation; Owner: -; Tablespace: 
--

ALTER TABLE ONLY t_stations_fs
    ADD CONSTRAINT t_stations_fs_gid_key UNIQUE (gid);
    
    
SET search_path = layers, pg_catalog;

--
-- Name: aireadhesion_pkey; Type: CONSTRAINT; Schema: layers; Owner: -; Tablespace: 
--

ALTER TABLE ONLY l_aireadhesion
    ADD CONSTRAINT aireadhesion_pkey PRIMARY KEY (gid);


--
-- Name: l_communes_pkey; Type: CONSTRAINT; Schema: layers; Owner: -; Tablespace: 
--

ALTER TABLE ONLY l_communes
    ADD CONSTRAINT l_communes_pkey PRIMARY KEY (insee);


--
-- Name: l_isolines20_pkey; Type: CONSTRAINT; Schema: layers; Owner: -; Tablespace: 
--

ALTER TABLE ONLY l_isolines20
    ADD CONSTRAINT l_isolines20_pkey PRIMARY KEY (gid);


--
-- Name: pk_l_secteurs; Type: CONSTRAINT; Schema: layers; Owner: -; Tablespace: 
--

ALTER TABLE ONLY l_secteurs
    ADD CONSTRAINT pk_l_secteurs PRIMARY KEY (id_secteur);


--
-- Name: pk_l_unites_geo; Type: CONSTRAINT; Schema: layers; Owner: -; Tablespace: 
--

ALTER TABLE ONLY l_unites_geo
    ADD CONSTRAINT pk_l_unites_geo PRIMARY KEY (id_unite_geo);


--
-- Name: pk_l_zonesstatut; Type: CONSTRAINT; Schema: layers; Owner: -; Tablespace: 
--

ALTER TABLE ONLY l_zonesstatut
    ADD CONSTRAINT pk_l_zonesstatut PRIMARY KEY (id_zone);


--
-- Name: pk_typeszones; Type: CONSTRAINT; Schema: layers; Owner: -; Tablespace: 
--

ALTER TABLE ONLY bib_typeszones
    ADD CONSTRAINT pk_typeszones PRIMARY KEY (id_type);


SET search_path = meta, pg_catalog;

--
-- Name: bib_lots_pkey; Type: CONSTRAINT; Schema: meta; Owner: -; Tablespace: 
--

ALTER TABLE ONLY bib_lots
    ADD CONSTRAINT bib_lots_pkey PRIMARY KEY (id_lot);


--
-- Name: bib_programmes_pkey; Type: CONSTRAINT; Schema: meta; Owner: -; Tablespace: 
--

ALTER TABLE ONLY bib_programmes
    ADD CONSTRAINT bib_programmes_pkey PRIMARY KEY (id_programme);


--
-- Name: bib_supports_pkey; Type: CONSTRAINT; Schema: meta; Owner: -; Tablespace: 
--

ALTER TABLE ONLY bib_supports
    ADD CONSTRAINT bib_supports_pkey PRIMARY KEY (id_support);


--
-- Name: pk_bib_precision; Type: CONSTRAINT; Schema: meta; Owner: -; Tablespace: 
--

ALTER TABLE ONLY t_precisions
    ADD CONSTRAINT pk_bib_precision PRIMARY KEY (id_precision);


--
-- Name: pk_bib_protocoles; Type: CONSTRAINT; Schema: meta; Owner: -; Tablespace: 
--

ALTER TABLE ONLY t_protocoles
    ADD CONSTRAINT pk_bib_protocoles PRIMARY KEY (id_protocole);


SET search_path = synchronomade, pg_catalog;

--
-- Name: erreurs_cf_pkey; Type: CONSTRAINT; Schema: synchronomade; Owner: -; Tablespace: 
--

ALTER TABLE ONLY erreurs_cf
    ADD CONSTRAINT erreurs_cf_pkey PRIMARY KEY (id);


--
-- Name: erreurs_inv_pkey; Type: CONSTRAINT; Schema: synchronomade; Owner: -; Tablespace: 
--

ALTER TABLE ONLY erreurs_inv
    ADD CONSTRAINT erreurs_inv_pkey PRIMARY KEY (id);


--
-- Name: erreurs_mortalite_pkey; Type: CONSTRAINT; Schema: synchronomade; Owner: -; Tablespace: 
--

ALTER TABLE ONLY erreurs_mortalite
    ADD CONSTRAINT erreurs_mortalite_pkey PRIMARY KEY (id);
    
--
-- TOC entry 3445 (class 2606 OID 166473)
-- Name: erreurs_flora_pkey; Type: CONSTRAINT; Schema: synchronomade; Owner: -; Tablespace: 
--

ALTER TABLE ONLY erreurs_flora
    ADD CONSTRAINT erreurs_flora_pkey PRIMARY KEY (id);


SET search_path = synthese, pg_catalog;

--
-- Name: bib_sources_pkey; Type: CONSTRAINT; Schema: synthese; Owner: -; Tablespace: 
--

ALTER TABLE ONLY bib_sources
    ADD CONSTRAINT bib_sources_pkey PRIMARY KEY (id_source);


--
-- Name: pk_bib_criteres_synthese; Type: CONSTRAINT; Schema: synthese; Owner: -; Tablespace: 
--

ALTER TABLE ONLY bib_criteres_synthese
    ADD CONSTRAINT pk_bib_criteres_synthese PRIMARY KEY (id_critere_synthese);


--
-- Name: pk_cor_unite_synthese; Type: CONSTRAINT; Schema: synthese; Owner: -; Tablespace: 
--

ALTER TABLE ONLY cor_unite_synthese
    ADD CONSTRAINT pk_cor_unite_synthese PRIMARY KEY (id_unite_geo, id_synthese);


--
-- Name: pk_cor_zonesstatut_synthese; Type: CONSTRAINT; Schema: synthese; Owner: -; Tablespace: 
--

ALTER TABLE ONLY cor_zonesstatut_synthese
    ADD CONSTRAINT pk_cor_zonesstatut_synthese PRIMARY KEY (id_zone, id_synthese);


--
-- Name: syntheseff_pkey; Type: CONSTRAINT; Schema: synthese; Owner: -; Tablespace: 
--

ALTER TABLE ONLY syntheseff
    ADD CONSTRAINT syntheseff_pkey PRIMARY KEY (id_synthese);


SET search_path = taxonomie, pg_catalog;

--
-- Name: pk_bib_attributs; Type: CONSTRAINT; Schema: taxonomie; Owner: -; Tablespace: 
--

ALTER TABLE ONLY bib_attributs
    ADD CONSTRAINT pk_bib_attributs PRIMARY KEY (id_attribut);

--
-- Name: pk_bib_groupe; Type: CONSTRAINT; Schema: taxonomie; Owner: -; Tablespace: 
--

ALTER TABLE ONLY bib_groupes
    ADD CONSTRAINT pk_bib_groupe PRIMARY KEY (id_groupe);

--
-- Name: pk_bib_bib_listes; Type: CONSTRAINT; Schema: taxonomie; Owner: -; Tablespace: 
--

ALTER TABLE ONLY bib_listes
    ADD CONSTRAINT pk_bib_listes PRIMARY KEY (id_liste);   

--
-- Name: pk_bib_taxons; Type: CONSTRAINT; Schema: taxonomie; Owner: -; Tablespace: 
--

ALTER TABLE ONLY bib_taxons
    ADD CONSTRAINT pk_bib_taxons PRIMARY KEY (id_taxon);

--
-- Name: pk_bib_taxref_habitats; Type: CONSTRAINT; Schema: taxonomie; Owner: -; Tablespace: 
--

ALTER TABLE ONLY bib_taxref_habitats
    ADD CONSTRAINT pk_bib_taxref_habitats PRIMARY KEY (id_habitat);

--
-- Name: pk_bib_taxref_rangs; Type: CONSTRAINT; Schema: taxonomie; Owner: -; Tablespace: 
--

ALTER TABLE ONLY bib_taxref_rangs
    ADD CONSTRAINT pk_bib_taxref_rangs PRIMARY KEY (id_rang);

--
-- Name: pk_bib_taxref_statuts; Type: CONSTRAINT; Schema: taxonomie; Owner: -; Tablespace: 
--

ALTER TABLE ONLY bib_taxref_statuts
    ADD CONSTRAINT pk_bib_taxref_statuts PRIMARY KEY (id_statut);

--
-- Name: pk_import_taxref; Type: CONSTRAINT; Schema: taxonomie; Owner: -; Tablespace: 
--

ALTER TABLE ONLY import_taxref
    ADD CONSTRAINT pk_import_taxref PRIMARY KEY (cd_nom);

--
-- Name: pk_taxref; Type: CONSTRAINT; Schema: taxonomie; Owner: -; Tablespace: 
--

ALTER TABLE ONLY taxref
    ADD CONSTRAINT pk_taxref PRIMARY KEY (cd_nom);

--
-- Name: pk_taxref_changes; Type: CONSTRAINT; Schema: taxonomie; Owner: -; Tablespace: 
--

ALTER TABLE ONLY taxref_changes
    ADD CONSTRAINT pk_taxref_changes PRIMARY KEY (cd_nom, champ);

--
-- Name: taxref_protection_articles_pkey; Type: CONSTRAINT; Schema: taxonomie; Owner: -; Tablespace: 
--

ALTER TABLE ONLY taxref_protection_articles
    ADD CONSTRAINT taxref_protection_articles_pkey PRIMARY KEY (cd_protection);

--
-- Name: taxref_protection_especes_pkey; Type: CONSTRAINT; Schema: taxonomie; Owner: -; Tablespace: 
--

ALTER TABLE ONLY taxref_protection_especes
    ADD CONSTRAINT taxref_protection_especes_pkey PRIMARY KEY (cd_nom, cd_protection, cd_nom_cite);

--
-- Name: cor_taxon_attribut_pkey; Type: CONSTRAINT; Schema: taxonomie; Owner: -; Tablespace: 
--

ALTER TABLE ONLY cor_taxon_attribut
    ADD CONSTRAINT cor_taxon_attribut_pkey PRIMARY KEY (id_taxon, id_attribut);

--
-- Name: cor_taxon_groupe_pkey; Type: CONSTRAINT; Schema: taxonomie; Owner: -; Tablespace: 
--

ALTER TABLE ONLY cor_taxon_groupe
    ADD CONSTRAINT cor_taxon_groupe_pkey PRIMARY KEY (id_taxon, id_groupe);
    
--
-- Name: cor_taxon_liste_pkey; Type: CONSTRAINT; Schema: taxonomie; Owner: -; Tablespace: 
--

ALTER TABLE ONLY cor_taxon_liste
    ADD CONSTRAINT cor_taxon_liste_pkey PRIMARY KEY (id_taxon, id_liste);


SET search_path = utilisateurs, pg_catalog;

--
-- Name: bib_droits_pkey; Type: CONSTRAINT; Schema: utilisateurs; Owner: -; Tablespace: 
--

ALTER TABLE ONLY bib_droits
    ADD CONSTRAINT bib_droits_pkey PRIMARY KEY (id_droit);


--
-- Name: cor_role_droit_application_pkey; Type: CONSTRAINT; Schema: utilisateurs; Owner: -; Tablespace: 
--

ALTER TABLE ONLY cor_role_droit_application
    ADD CONSTRAINT cor_role_droit_application_pkey PRIMARY KEY (id_role, id_droit, id_application);


--
-- Name: cor_role_menu_pkey; Type: CONSTRAINT; Schema: utilisateurs; Owner: -; Tablespace: 
--

ALTER TABLE ONLY cor_role_menu
    ADD CONSTRAINT cor_role_menu_pkey PRIMARY KEY (id_role, id_menu);


--
-- Name: cor_roles_pkey; Type: CONSTRAINT; Schema: utilisateurs; Owner: -; Tablespace: 
--

ALTER TABLE ONLY cor_roles
    ADD CONSTRAINT cor_roles_pkey PRIMARY KEY (id_role_groupe, id_role_utilisateur);


--
-- Name: pk_bib_organismes; Type: CONSTRAINT; Schema: utilisateurs; Owner: -; Tablespace: 
--

ALTER TABLE ONLY bib_organismes
    ADD CONSTRAINT pk_bib_organismes PRIMARY KEY (id_organisme);


--
-- Name: pk_bib_services; Type: CONSTRAINT; Schema: utilisateurs; Owner: -; Tablespace: 
--

ALTER TABLE ONLY bib_unites
    ADD CONSTRAINT pk_bib_services PRIMARY KEY (id_unite);


--
-- Name: pk_roles; Type: CONSTRAINT; Schema: utilisateurs; Owner: -; Tablespace: 
--

ALTER TABLE ONLY t_roles
    ADD CONSTRAINT pk_roles PRIMARY KEY (id_role);


--
-- Name: t_applications_pkey; Type: CONSTRAINT; Schema: utilisateurs; Owner: -; Tablespace: 
--

ALTER TABLE ONLY t_applications
    ADD CONSTRAINT t_applications_pkey PRIMARY KEY (id_application);


--
-- Name: t_menus_pkey; Type: CONSTRAINT; Schema: utilisateurs; Owner: -; Tablespace: 
--

ALTER TABLE ONLY t_menus
    ADD CONSTRAINT t_menus_pkey PRIMARY KEY (id_menu);


SET search_path = contactfaune, pg_catalog;

--
-- Name: fki_; Type: INDEX; Schema: contactfaune; Owner: -; Tablespace: 
--

CREATE INDEX fki_ ON bib_criteres_cf USING btree (id_critere_synthese);


--
-- Name: i_fk_cor_critere_groupe_bib_gr; Type: INDEX; Schema: contactfaune; Owner: -; Tablespace: 
--

CREATE INDEX i_fk_cor_critere_groupe_bib_gr ON cor_critere_groupe USING btree (id_groupe);


--
-- Name: i_fk_cor_critere_groupe_bib_gr; Type: INDEX; Schema: contactfaune; Owner: -; Tablespace: 
--

CREATE INDEX i_fk_cor_critere_groupe_bib_cr ON cor_critere_groupe USING btree (id_critere_cf);


--
-- Name: i_fk_cor_message_cf_bib_me; Type: INDEX; Schema: contactfaune; Owner: -; Tablespace: 
--

CREATE INDEX i_fk_cor_message_cf_bib_me ON cor_message_taxon USING btree (id_message_cf);


--
-- Name: i_fk_cor_message_cf_bib_ta; Type: INDEX; Schema: contactfaune; Owner: -; Tablespace: 
--

CREATE INDEX i_fk_cor_message_cf_bib_ta ON cor_message_taxon USING btree (id_taxon);


--
-- Name: i_fk_cor_role_fiche_cf_t_fiche; Type: INDEX; Schema: contactfaune; Owner: -; Tablespace: 
--

CREATE INDEX i_fk_cor_role_fiche_cf_t_fiche ON cor_role_fiche_cf USING btree (id_cf);


--
-- Name: i_fk_cor_role_fiche_cf_t_roles; Type: INDEX; Schema: contactfaune; Owner: -; Tablespace: 
--

CREATE INDEX i_fk_cor_role_fiche_cf_t_roles ON cor_role_fiche_cf USING btree (id_role);


--
-- Name: i_fk_cor_unite_taxon_bib_taxon; Type: INDEX; Schema: contactfaune; Owner: -; Tablespace: 
--

CREATE INDEX i_fk_cor_unite_taxon_bib_taxon ON cor_unite_taxon USING btree (id_taxon);


--
-- Name: i_fk_cor_unite_taxon_l_unites_; Type: INDEX; Schema: contactfaune; Owner: -; Tablespace: 
--

CREATE INDEX i_fk_cor_unite_taxon_l_unites_ ON cor_unite_taxon USING btree (id_unite_geo);


--
-- Name: i_fk_t_fiches_cf_l_communes; Type: INDEX; Schema: contactfaune; Owner: -; Tablespace: 
--

CREATE INDEX i_fk_t_fiches_cf_l_communes ON t_fiches_cf USING btree (insee);


--
-- Name: i_fk_t_releves_cf_bib_criteres; Type: INDEX; Schema: contactfaune; Owner: -; Tablespace: 
--

CREATE INDEX i_fk_t_releves_cf_bib_criteres ON t_releves_cf USING btree (id_critere_cf);


--
-- Name: i_fk_t_releves_cf_bib_taxons_f; Type: INDEX; Schema: contactfaune; Owner: -; Tablespace: 
--

CREATE INDEX i_fk_t_releves_cf_bib_taxons_f ON t_releves_cf USING btree (id_taxon);


--
-- Name: i_fk_t_releves_cf_t_fiches_cf; Type: INDEX; Schema: contactfaune; Owner: -; Tablespace: 
--

CREATE INDEX i_fk_t_releves_cf_t_fiches_cf ON t_releves_cf USING btree (id_cf);


SET search_path = contactinv, pg_catalog;

--
-- Name: fki_; Type: INDEX; Schema: contactinv; Owner: -; Tablespace: 
--

CREATE INDEX fki_ ON bib_criteres_inv USING btree (id_critere_synthese);


--
-- Name: fki_t_fiches_inv_bib_milieux_inv; Type: INDEX; Schema: contactinv; Owner: -; Tablespace: 
--

CREATE INDEX fki_t_fiches_inv_bib_milieux_inv ON t_fiches_inv USING btree (id_milieu_inv);


--
-- Name: i_fk_cor_msg_inv_bib_msg; Type: INDEX; Schema: contactinv; Owner: -; Tablespace: 
--

CREATE INDEX i_fk_cor_msg_inv_bib_msg ON cor_message_taxon USING btree (id_message_inv);


--
-- Name: i_fk_cor_msg_inv_bib_taxons; Type: INDEX; Schema: contactinv; Owner: -; Tablespace: 
--

CREATE INDEX i_fk_cor_msg_inv_bib_taxons ON cor_message_taxon USING btree (id_taxon);


--
-- Name: i_fk_cor_role_fiche_inv_t_fiche; Type: INDEX; Schema: contactinv; Owner: -; Tablespace: 
--

CREATE INDEX i_fk_cor_role_fiche_inv_t_fiche ON cor_role_fiche_inv USING btree (id_inv);


--
-- Name: i_fk_cor_role_fiche_inv_t_roles; Type: INDEX; Schema: contactinv; Owner: -; Tablespace: 
--

CREATE INDEX i_fk_cor_role_fiche_inv_t_roles ON cor_role_fiche_inv USING btree (id_role);


--
-- Name: i_fk_cor_unite_taxon_inv_bib_taxon; Type: INDEX; Schema: contactinv; Owner: -; Tablespace: 
--

CREATE INDEX i_fk_cor_unite_taxon_inv_bib_taxon ON cor_unite_taxon_inv USING btree (id_taxon);


--
-- Name: i_fk_cor_unite_taxon_inv_l_unites; Type: INDEX; Schema: contactinv; Owner: -; Tablespace: 
--

CREATE INDEX i_fk_cor_unite_taxon_inv_l_unites ON cor_unite_taxon_inv USING btree (id_unite_geo);


--
-- Name: i_fk_t_fiches_inv_l_communes; Type: INDEX; Schema: contactinv; Owner: -; Tablespace: 
--

CREATE INDEX i_fk_t_fiches_inv_l_communes ON t_fiches_inv USING btree (insee);


--
-- Name: i_fk_t_releves_inv_bib_criteres; Type: INDEX; Schema: contactinv; Owner: -; Tablespace: 
--

CREATE INDEX i_fk_t_releves_inv_bib_criteres ON t_releves_inv USING btree (id_critere_inv);


--
-- Name: i_fk_t_releves_inv_bib_taxons_f; Type: INDEX; Schema: contactinv; Owner: -; Tablespace: 
--

CREATE INDEX i_fk_t_releves_inv_bib_taxons_f ON t_releves_inv USING btree (id_taxon);


--
-- Name: i_fk_t_releves_inv_t_fiches_inv; Type: INDEX; Schema: contactinv; Owner: -; Tablespace: 
--

CREATE INDEX i_fk_t_releves_inv_t_fiches_inv ON t_releves_inv USING btree (id_inv);

SET search_path = bryophytes, pg_catalog;

--
-- TOC entry 3373 (class 1259 OID 70531)
-- Name: fki_t_stations_bryo_gid; Type: INDEX; Schema: bryophytes; Owner: -; Tablespace: 
--

CREATE INDEX fki_t_stations_bryo_gid ON t_stations_bryo USING btree (gid);


--
-- TOC entry 3712 (class 0 OID 0)
-- Dependencies: 3373
-- Name: INDEX fki_t_stations_bryo_gid; Type: COMMENT; Schema: bryophytes; Owner: -
--

COMMENT ON INDEX fki_t_stations_bryo_gid IS 'pour le fonctionnement de qgis';


--
-- TOC entry 3374 (class 1259 OID 70532)
-- Name: i_fk_t_stations_bryo_bib_exposit; Type: INDEX; Schema: bryophytes; Owner: -; Tablespace: 
--

CREATE INDEX i_fk_t_stations_bryo_bib_exposit ON t_stations_bryo USING btree (id_exposition);


--
-- TOC entry 3375 (class 1259 OID 70533)
-- Name: i_fk_t_stations_bryo_bib_support; Type: INDEX; Schema: bryophytes; Owner: -; Tablespace: 
--

CREATE INDEX i_fk_t_stations_bryo_bib_support ON t_stations_bryo USING btree (id_support);


--
-- TOC entry 3370 (class 1259 OID 70534)
-- Name: index_cd_nom; Type: INDEX; Schema: bryophytes; Owner: -; Tablespace: 
--

CREATE INDEX index_cd_nom ON cor_bryo_taxon USING btree (cd_nom);


SET search_path = florepatri, pg_catalog;

--
-- TOC entry 3406 (class 1259 OID 70554)
-- Name: fki_cor_zp_obs_t_roles; Type: INDEX; Schema: florepatri; Owner: -; Tablespace: 
--

CREATE INDEX fki_cor_zp_obs_t_roles ON cor_zp_obs USING btree (codeobs);


--
-- TOC entry 3409 (class 1259 OID 70556)
-- Name: fki_t_apresence_t_zprospection; Type: INDEX; Schema: florepatri; Owner: -; Tablespace: 
--

CREATE INDEX fki_t_apresence_t_zprospection ON t_apresence USING btree (indexzp);


--
-- TOC entry 3410 (class 1259 OID 70562)
-- Name: i_fk_t_apresence_bib_phenologi; Type: INDEX; Schema: florepatri; Owner: -; Tablespace: 
--

CREATE INDEX i_fk_t_apresence_bib_phenologi ON t_apresence USING btree (codepheno);


--
-- TOC entry 3413 (class 1259 OID 70563)
-- Name: i_fk_t_zprospection_bib_secteu; Type: INDEX; Schema: florepatri; Owner: -; Tablespace: 
--

CREATE INDEX i_fk_t_zprospection_bib_secteu ON t_zprospection USING btree (id_secteur);


SET search_path = florestation, pg_catalog;

--
-- TOC entry 3435 (class 1259 OID 70564)
-- Name: fki_t_stations_fs_bib_homogenes; Type: INDEX; Schema: florestation; Owner: -; Tablespace: 
--

CREATE INDEX fki_t_stations_fs_bib_homogenes ON t_stations_fs USING btree (id_homogene);


--
-- TOC entry 3436 (class 1259 OID 70565)
-- Name: fki_t_stations_fs_gid; Type: INDEX; Schema: florestation; Owner: -; Tablespace: 
--

CREATE INDEX fki_t_stations_fs_gid ON t_stations_fs USING btree (gid);


--
-- TOC entry 3713 (class 0 OID 0)
-- Dependencies: 3436
-- Name: INDEX fki_t_stations_fs_gid; Type: COMMENT; Schema: florestation; Owner: -
--

COMMENT ON INDEX fki_t_stations_fs_gid IS 'pour le fonctionnement de qgis';


--
-- TOC entry 3437 (class 1259 OID 70567)
-- Name: i_fk_t_stations_fs_bib_exposit; Type: INDEX; Schema: florestation; Owner: -; Tablespace: 
--

CREATE INDEX i_fk_t_stations_fs_bib_exposit ON t_stations_fs USING btree (id_exposition);


--
-- TOC entry 3438 (class 1259 OID 70568)
-- Name: i_fk_t_stations_fs_bib_program; Type: INDEX; Schema: florestation; Owner: -; Tablespace: 
--

CREATE INDEX i_fk_t_stations_fs_bib_program ON t_stations_fs USING btree (id_programme_fs);


--
-- TOC entry 3439 (class 1259 OID 70569)
-- Name: i_fk_t_stations_fs_bib_support; Type: INDEX; Schema: florestation; Owner: -; Tablespace: 
--

CREATE INDEX i_fk_t_stations_fs_bib_support ON t_stations_fs USING btree (id_support);


--
-- TOC entry 3432 (class 1259 OID 70570)
-- Name: index_cd_nom; Type: INDEX; Schema: florestation; Owner: -; Tablespace: 
--

CREATE INDEX index_cd_nom ON cor_fs_taxon USING btree (cd_nom);


SET search_path = layers, pg_catalog;

--
-- Name: fki_; Type: INDEX; Schema: layers; Owner: -; Tablespace: 
--

CREATE INDEX fki_ ON l_communes USING btree (id_secteur);


SET search_path = synthese, pg_catalog;

--
-- Name: fki_synthese_bib_proprietaires; Type: INDEX; Schema: synthese; Owner: -; Tablespace: 
--

CREATE INDEX fki_synthese_bib_proprietaires ON syntheseff USING btree (id_organisme);


--
-- Name: fki_synthese_bib_protocoles_id; Type: INDEX; Schema: synthese; Owner: -; Tablespace: 
--

CREATE INDEX fki_synthese_bib_protocoles_id ON syntheseff USING btree (id_protocole);

--
-- Name: fki_synthese_insee_fkey; Type: INDEX; Schema: synthese; Owner: -; Tablespace: 
--

CREATE INDEX fki_synthese_insee_fkey ON syntheseff USING btree (insee);

--
-- Name: fki_syntheseff_bib_sources; Type: INDEX; Schema: synthese; Owner: -; Tablespace: 
--

CREATE INDEX fki_syntheseff_bib_sources ON syntheseff USING btree (id_source);


--
-- Name: i_fk_cor_cor_zonesstatut_synthese_l_zonesstatut; Type: INDEX; Schema: synthese; Owner: -; Tablespace: 
--

CREATE INDEX i_fk_cor_cor_zonesstatut_synthese_l_zonesstatut ON cor_zonesstatut_synthese USING btree (id_zone);


--
-- Name: i_fk_cor_unite_synthese_l_unites; Type: INDEX; Schema: synthese; Owner: -; Tablespace: 
--

CREATE INDEX i_fk_cor_unite_synthese_l_unites ON cor_unite_synthese USING btree (id_unite_geo);


--
-- Name: i_fk_cor_unite_synthese_syntheseff; Type: INDEX; Schema: synthese; Owner: -; Tablespace: 
--

CREATE INDEX i_fk_cor_unite_synthese_syntheseff ON cor_unite_synthese USING btree (id_synthese);


--
-- Name: i_synthese_cd_nom; Type: INDEX; Schema: synthese; Owner: -; Tablespace: 
--

CREATE INDEX i_synthese_cd_nom ON syntheseff USING btree (cd_nom);


--
-- Name: i_synthese_dateobs; Type: INDEX; Schema: synthese; Owner: -; Tablespace: 
--

CREATE INDEX i_synthese_dateobs ON syntheseff USING btree (dateobs DESC);


--
-- Name: i_synthese_id_lot; Type: INDEX; Schema: synthese; Owner: -; Tablespace: 
--

CREATE INDEX i_synthese_id_lot ON syntheseff USING btree (id_lot);


--
-- Name: index_gist_synthese_the_geom_point; Type: INDEX; Schema: synthese; Owner: -; Tablespace: 
--

CREATE INDEX index_gist_synthese_the_geom_point ON syntheseff USING gist (the_geom_point);


SET search_path = taxonomie, pg_catalog;

--
-- Index: taxonomie.i_taxref_hierarchy
--

CREATE INDEX i_taxref_hierarchy
  ON taxonomie.taxref
  USING btree
  (regne COLLATE pg_catalog."default" , phylum COLLATE pg_catalog."default" , classe COLLATE pg_catalog."default" , ordre COLLATE pg_catalog."default" , famille COLLATE pg_catalog."default" );
  
--
-- Name: fki_cor_taxon_attribut; Type: INDEX; Schema: taxonomie; Owner: -; Tablespace: 
--

CREATE INDEX fki_cor_taxon_attribut ON cor_taxon_attribut USING btree (valeur_attribut);

--
-- Name: fki_bib_taxons_bib_groupes; Type: INDEX; Schema: taxonomie; Owner: -; Tablespace: 
--

CREATE INDEX fki_bib_taxons_bib_groupes ON cor_taxon_groupe USING btree (id_groupe);


--
-- Name: fki_cd_nom_taxref_protection_especes; Type: INDEX; Schema: taxonomie; Owner: -; Tablespace: 
--

CREATE INDEX fki_cd_nom_taxref_protection_especes ON taxref_protection_especes USING btree (cd_nom);


--
-- Name: i_fk_bib_taxons_taxr; Type: INDEX; Schema: taxonomie; Owner: -; Tablespace: 
--

CREATE INDEX i_fk_bib_taxons_taxr ON bib_taxons USING btree (cd_nom);


--
-- Name: i_fk_taxref_bib_taxref_habitat; Type: INDEX; Schema: taxonomie; Owner: -; Tablespace: 
--

CREATE INDEX i_fk_taxref_bib_taxref_habitat ON taxref USING btree (id_habitat);


--
-- Name: i_fk_taxref_bib_taxref_rangs; Type: INDEX; Schema: taxonomie; Owner: -; Tablespace: 
--

CREATE INDEX i_fk_taxref_bib_taxref_rangs ON taxref USING btree (id_rang);


--
-- Name: i_fk_taxref_bib_taxref_statuts; Type: INDEX; Schema: taxonomie; Owner: -; Tablespace: 
--

CREATE INDEX i_fk_taxref_bib_taxref_statuts ON taxref USING btree (id_statut);


CREATE INDEX i_taxref_cd_nom ON taxonomie.taxref USING btree (cd_nom );

CREATE INDEX i_taxref_cd_ref ON taxonomie.taxref USING btree (cd_ref );


SET search_path = contactfaune, pg_catalog;

--
-- Name: tri_insert_fiche_cf; Type: TRIGGER; Schema: contactfaune; Owner: -
--

CREATE TRIGGER tri_insert_fiche_cf BEFORE INSERT ON t_fiches_cf FOR EACH ROW EXECUTE PROCEDURE insert_fiche_cf();


--
-- Name: tri_insert_releve_cf; Type: TRIGGER; Schema: contactfaune; Owner: -
--

CREATE TRIGGER tri_insert_releve_cf BEFORE INSERT ON t_releves_cf FOR EACH ROW EXECUTE PROCEDURE insert_releve_cf();


--
-- Name: tri_synthese_delete_releve_cf; Type: TRIGGER; Schema: contactfaune; Owner: -
--

CREATE TRIGGER tri_synthese_delete_releve_cf AFTER DELETE ON t_releves_cf FOR EACH ROW EXECUTE PROCEDURE synthese_delete_releve_cf();


--
-- Name: tri_synthese_insert_releve_cf; Type: TRIGGER; Schema: contactfaune; Owner: -
--

CREATE TRIGGER tri_synthese_insert_releve_cf AFTER INSERT ON t_releves_cf FOR EACH ROW EXECUTE PROCEDURE synthese_insert_releve_cf();


--
-- Name: tri_synthese_update_fiche_cf; Type: TRIGGER; Schema: contactfaune; Owner: -
--

CREATE TRIGGER tri_synthese_update_fiche_cf AFTER UPDATE ON t_fiches_cf FOR EACH ROW EXECUTE PROCEDURE synthese_update_fiche_cf();


--
-- Name: tri_synthese_update_releve_cf; Type: TRIGGER; Schema: contactfaune; Owner: -
--

CREATE TRIGGER tri_synthese_update_releve_cf AFTER UPDATE ON t_releves_cf FOR EACH ROW EXECUTE PROCEDURE synthese_update_releve_cf();


--
-- Name: tri_update_fiche_cf; Type: TRIGGER; Schema: contactfaune; Owner: -
--

CREATE TRIGGER tri_update_fiche_cf BEFORE UPDATE ON t_fiches_cf FOR EACH ROW EXECUTE PROCEDURE update_fiche_cf();


--
-- Name: tri_update_releve_cf; Type: TRIGGER; Schema: contactfaune; Owner: -
--

CREATE TRIGGER tri_update_releve_cf BEFORE UPDATE ON t_releves_cf FOR EACH ROW EXECUTE PROCEDURE update_releve_cf();


--
-- Name: tri_update_synthese_cor_role_fiche_cf; Type: TRIGGER; Schema: contactfaune; Owner: -
--

CREATE TRIGGER tri_update_synthese_cor_role_fiche_cf AFTER INSERT OR UPDATE ON cor_role_fiche_cf FOR EACH ROW EXECUTE PROCEDURE synthese_update_cor_role_fiche_cf();


SET search_path = contactinv, pg_catalog;

--
-- Name: tri_insert_fiche_inv; Type: TRIGGER; Schema: contactinv; Owner: -
--

CREATE TRIGGER tri_insert_fiche_inv BEFORE INSERT ON t_fiches_inv FOR EACH ROW EXECUTE PROCEDURE insert_fiche_inv();


--
-- Name: tri_insert_releve_inv; Type: TRIGGER; Schema: contactinv; Owner: -
--

CREATE TRIGGER tri_insert_releve_inv BEFORE INSERT ON t_releves_inv FOR EACH ROW EXECUTE PROCEDURE insert_releve_inv();


--
-- Name: tri_synthese_delete_releve_inv; Type: TRIGGER; Schema: contactinv; Owner: -
--

CREATE TRIGGER tri_synthese_delete_releve_inv AFTER DELETE ON t_releves_inv FOR EACH ROW EXECUTE PROCEDURE synthese_delete_releve_inv();


--
-- Name: tri_synthese_insert_releve_inv; Type: TRIGGER; Schema: contactinv; Owner: -
--

CREATE TRIGGER tri_synthese_insert_releve_inv AFTER INSERT ON t_releves_inv FOR EACH ROW EXECUTE PROCEDURE synthese_insert_releve_inv();


--
-- Name: tri_synthese_update_fiche_inv; Type: TRIGGER; Schema: contactinv; Owner: -
--

CREATE TRIGGER tri_synthese_update_fiche_inv AFTER UPDATE ON t_fiches_inv FOR EACH ROW EXECUTE PROCEDURE synthese_update_fiche_inv();


--
-- Name: tri_synthese_update_releve_inv; Type: TRIGGER; Schema: contactinv; Owner: -
--

CREATE TRIGGER tri_synthese_update_releve_inv AFTER UPDATE ON t_releves_inv FOR EACH ROW EXECUTE PROCEDURE synthese_update_releve_inv();


--
-- Name: tri_update_fiche_inv; Type: TRIGGER; Schema: contactinv; Owner: -
--

CREATE TRIGGER tri_update_fiche_inv BEFORE UPDATE ON t_fiches_inv FOR EACH ROW EXECUTE PROCEDURE update_fiche_inv();


--
-- Name: tri_update_releve_inv; Type: TRIGGER; Schema: contactinv; Owner: -
--

CREATE TRIGGER tri_update_releve_inv BEFORE UPDATE ON t_releves_inv FOR EACH ROW EXECUTE PROCEDURE update_releve_inv();


--
-- Name: tri_update_synthese_cor_role_fiche_inv; Type: TRIGGER; Schema: contactinv; Owner: -
--

CREATE TRIGGER tri_update_synthese_cor_role_fiche_inv AFTER INSERT OR UPDATE ON cor_role_fiche_inv FOR EACH ROW EXECUTE PROCEDURE synthese_update_cor_role_fiche_inv();

SET search_path = bryophytes, pg_catalog;

--
-- TOC entry 3489 (class 2620 OID 70619)
-- Name: tri_delete_synthese_cor_bryo_taxon; Type: TRIGGER; Schema: bryophytes; Owner: -
--

CREATE TRIGGER tri_delete_synthese_cor_bryo_taxon AFTER DELETE ON cor_bryo_taxon FOR EACH ROW EXECUTE PROCEDURE delete_synthese_cor_bryo_taxon();


--
-- TOC entry 3492 (class 2620 OID 70620)
-- Name: tri_insert; Type: TRIGGER; Schema: bryophytes; Owner: -
--

CREATE TRIGGER tri_insert BEFORE INSERT ON t_stations_bryo FOR EACH ROW EXECUTE PROCEDURE bryophytes_insert();


--
-- TOC entry 3488 (class 2620 OID 70621)
-- Name: tri_insert_synthese_cor_bryo_observateur; Type: TRIGGER; Schema: bryophytes; Owner: -
--

CREATE TRIGGER tri_insert_synthese_cor_bryo_observateur AFTER INSERT ON cor_bryo_observateur FOR EACH ROW EXECUTE PROCEDURE update_synthese_cor_bryo_observateur();


--
-- TOC entry 3490 (class 2620 OID 70622)
-- Name: tri_insert_synthese_cor_bryo_taxon; Type: TRIGGER; Schema: bryophytes; Owner: -
--

CREATE TRIGGER tri_insert_synthese_cor_bryo_taxon AFTER INSERT ON cor_bryo_taxon FOR EACH ROW EXECUTE PROCEDURE insert_synthese_cor_bryo_taxon();


--
-- TOC entry 3493 (class 2620 OID 70623)
-- Name: tri_update; Type: TRIGGER; Schema: bryophytes; Owner: -
--

CREATE TRIGGER tri_update BEFORE UPDATE ON t_stations_bryo FOR EACH ROW EXECUTE PROCEDURE bryophytes_update();


--
-- TOC entry 3491 (class 2620 OID 70624)
-- Name: tri_update_synthese_cor_bryo_taxon; Type: TRIGGER; Schema: bryophytes; Owner: -
--

CREATE TRIGGER tri_update_synthese_cor_bryo_taxon AFTER UPDATE ON cor_bryo_taxon FOR EACH ROW EXECUTE PROCEDURE update_synthese_cor_bryo_taxon();


--
-- TOC entry 3494 (class 2620 OID 70625)
-- Name: tri_update_synthese_stations_bryo; Type: TRIGGER; Schema: bryophytes; Owner: -
--

CREATE TRIGGER tri_update_synthese_stations_bryo AFTER UPDATE ON t_stations_bryo FOR EACH ROW EXECUTE PROCEDURE update_synthese_stations_bryo();


SET search_path = florepatri, pg_catalog;

--
-- TOC entry 3497 (class 2620 OID 70626)
-- Name: tri_delete_synthese_ap; Type: TRIGGER; Schema: florepatri; Owner: -
--

CREATE TRIGGER tri_delete_synthese_ap AFTER DELETE ON t_apresence FOR EACH ROW EXECUTE PROCEDURE delete_synthese_ap();


--
-- TOC entry 3498 (class 2620 OID 70627)
-- Name: tri_insert_ap; Type: TRIGGER; Schema: florepatri; Owner: -
--

CREATE TRIGGER tri_insert_ap BEFORE INSERT ON t_apresence FOR EACH ROW EXECUTE PROCEDURE insert_ap();

--
-- TOC entry 3499 (class 2620 OID 70628)
-- Name: tri_insert_synthese_ap; Type: TRIGGER; Schema: florepatri; Owner: -
--

CREATE TRIGGER tri_insert_synthese_ap AFTER INSERT ON t_apresence FOR EACH ROW EXECUTE PROCEDURE insert_synthese_ap();


--
-- TOC entry 3495 (class 2620 OID 70629)
-- Name: tri_insert_synthese_cor_zp_obs; Type: TRIGGER; Schema: florepatri; Owner: -
--

CREATE TRIGGER tri_insert_synthese_cor_zp_obs AFTER INSERT ON cor_zp_obs FOR EACH ROW EXECUTE PROCEDURE update_synthese_cor_zp_obs();


--
-- TOC entry 3503 (class 2620 OID 70630)
-- Name: tri_insert_zp; Type: TRIGGER; Schema: florepatri; Owner: -
--

CREATE TRIGGER tri_insert_zp BEFORE INSERT ON t_zprospection FOR EACH ROW EXECUTE PROCEDURE insert_zp();


--
-- TOC entry 3502 (class 2620 OID 70631)
-- Name: tri_update_ap; Type: TRIGGER; Schema: florepatri; Owner: -
--

CREATE TRIGGER tri_update_ap BEFORE UPDATE ON t_apresence FOR EACH ROW EXECUTE PROCEDURE update_ap();


--
-- TOC entry 3500 (class 2620 OID 70632)
-- Name: tri_update_synthese_ap; Type: TRIGGER; Schema: florepatri; Owner: -
--

CREATE TRIGGER tri_update_synthese_ap AFTER UPDATE ON t_apresence FOR EACH ROW EXECUTE PROCEDURE update_synthese_ap();


--
-- TOC entry 3504 (class 2620 OID 70633)
-- Name: tri_update_synthese_zp; Type: TRIGGER; Schema: florepatri; Owner: -
--

CREATE TRIGGER tri_update_synthese_zp AFTER UPDATE ON t_zprospection FOR EACH ROW EXECUTE PROCEDURE update_synthese_zp();


--
-- TOC entry 3505 (class 2620 OID 70634)
-- Name: tri_update_zp; Type: TRIGGER; Schema: florepatri; Owner: -
--

CREATE TRIGGER tri_update_zp BEFORE UPDATE ON t_zprospection FOR EACH ROW EXECUTE PROCEDURE update_zp();


SET search_path = florestation, pg_catalog;

--
-- TOC entry 3508 (class 2620 OID 70635)
-- Name: tri_delete_synthese_cor_fs_taxon; Type: TRIGGER; Schema: florestation; Owner: -
--

CREATE TRIGGER tri_delete_synthese_cor_fs_taxon AFTER DELETE ON cor_fs_taxon FOR EACH ROW EXECUTE PROCEDURE delete_synthese_cor_fs_taxon();


--
-- TOC entry 3511 (class 2620 OID 70636)
-- Name: tri_insert; Type: TRIGGER; Schema: florestation; Owner: -
--

CREATE TRIGGER tri_insert BEFORE INSERT ON t_stations_fs FOR EACH ROW EXECUTE PROCEDURE florestation_insert();


--
-- TOC entry 3507 (class 2620 OID 70637)
-- Name: tri_insert_synthese_cor_fs_observateur; Type: TRIGGER; Schema: florestation; Owner: -
--

CREATE TRIGGER tri_insert_synthese_cor_fs_observateur AFTER INSERT ON cor_fs_observateur FOR EACH ROW EXECUTE PROCEDURE update_synthese_cor_fs_observateur();


--
-- TOC entry 3509 (class 2620 OID 70638)
-- Name: tri_insert_synthese_cor_fs_taxon; Type: TRIGGER; Schema: florestation; Owner: -
--

CREATE TRIGGER tri_insert_synthese_cor_fs_taxon AFTER INSERT ON cor_fs_taxon FOR EACH ROW EXECUTE PROCEDURE insert_synthese_cor_fs_taxon();


--
-- TOC entry 3512 (class 2620 OID 70639)
-- Name: tri_update; Type: TRIGGER; Schema: florestation; Owner: -
--

CREATE TRIGGER tri_update BEFORE UPDATE ON t_stations_fs FOR EACH ROW EXECUTE PROCEDURE florestation_update();


--
-- TOC entry 3510 (class 2620 OID 70640)
-- Name: tri_update_synthese_cor_fs_taxon; Type: TRIGGER; Schema: florestation; Owner: -
--

CREATE TRIGGER tri_update_synthese_cor_fs_taxon AFTER UPDATE ON cor_fs_taxon FOR EACH ROW EXECUTE PROCEDURE update_synthese_cor_fs_taxon();


--
-- TOC entry 3513 (class 2620 OID 70641)
-- Name: tri_update_synthese_stations_fs; Type: TRIGGER; Schema: florestation; Owner: -
--

CREATE TRIGGER tri_update_synthese_stations_fs AFTER UPDATE ON t_stations_fs FOR EACH ROW EXECUTE PROCEDURE update_synthese_stations_fs();


SET search_path = synthese, pg_catalog;

--
-- Name: tri_insert_syntheseff; Type: TRIGGER; Schema: synthese; Owner: -
--

CREATE TRIGGER tri_insert_syntheseff BEFORE INSERT ON syntheseff FOR EACH ROW EXECUTE PROCEDURE insert_syntheseff();


--
-- Name: tri_maj_cor_unite_synthese; Type: TRIGGER; Schema: synthese; Owner: -
--

CREATE TRIGGER tri_maj_cor_unite_synthese AFTER INSERT OR DELETE OR UPDATE ON syntheseff FOR EACH ROW EXECUTE PROCEDURE maj_cor_unite_synthese();


--
-- Name: tri_maj_cor_unite_taxon; Type: TRIGGER; Schema: synthese; Owner: -
--

CREATE TRIGGER tri_maj_cor_unite_taxon AFTER INSERT OR DELETE ON cor_unite_synthese FOR EACH ROW EXECUTE PROCEDURE maj_cor_unite_taxon();


--
-- Name: tri_maj_cor_zonesstatut_synthese; Type: TRIGGER; Schema: synthese; Owner: -
--

CREATE TRIGGER tri_maj_cor_zonesstatut_synthese AFTER INSERT OR DELETE OR UPDATE ON syntheseff FOR EACH ROW EXECUTE PROCEDURE maj_cor_zonesstatut_synthese();


--
-- Name: tri_update_syntheseff; Type: TRIGGER; Schema: synthese; Owner: -
--

CREATE TRIGGER tri_update_syntheseff BEFORE UPDATE ON syntheseff FOR EACH ROW EXECUTE PROCEDURE update_syntheseff();


SET search_path = utilisateurs, pg_catalog;

--
-- Name: modify_date_insert_trigger; Type: TRIGGER; Schema: utilisateurs; Owner: -
--

CREATE TRIGGER modify_date_insert_trigger BEFORE INSERT ON t_roles FOR EACH ROW EXECUTE PROCEDURE modify_date_insert();


--
-- Name: modify_date_update_trigger; Type: TRIGGER; Schema: utilisateurs; Owner: -
--

CREATE TRIGGER modify_date_update_trigger BEFORE UPDATE ON t_roles FOR EACH ROW EXECUTE PROCEDURE modify_date_update();


SET search_path = contactfaune, pg_catalog;

--
-- Name: bib_criteres_cf_id_critere_synthese_fkey; Type: FK CONSTRAINT; Schema: contactfaune; Owner: -
--

ALTER TABLE ONLY bib_criteres_cf
    ADD CONSTRAINT bib_criteres_cf_id_critere_synthese_fkey FOREIGN KEY (id_critere_synthese) REFERENCES synthese.bib_criteres_synthese(id_critere_synthese);


--
-- Name: fk_cor_critere_groupe_bib_groupe; Type: FK CONSTRAINT; Schema: contactfaune; Owner: -
--

ALTER TABLE ONLY cor_critere_groupe
    ADD CONSTRAINT fk_cor_critere_groupe_bib_groupe FOREIGN KEY (id_groupe) REFERENCES taxonomie.bib_groupes(id_groupe) ON UPDATE CASCADE;


--
-- Name: fk_cor_critere_groupe_bib_criter; Type: FK CONSTRAINT; Schema: contactfaune; Owner: -
--

ALTER TABLE ONLY cor_critere_groupe
    ADD CONSTRAINT fk_cor_critere_groupe_bib_criter FOREIGN KEY (id_critere_cf) REFERENCES bib_criteres_cf(id_critere_cf) ON UPDATE CASCADE;


--
-- Name: fk_cor_message_taxon_bib_taxons_fa; Type: FK CONSTRAINT; Schema: contactfaune; Owner: -
--

ALTER TABLE ONLY cor_message_taxon
    ADD CONSTRAINT fk_cor_message_taxon_bib_taxons_fa FOREIGN KEY (id_taxon) REFERENCES taxonomie.bib_taxons(id_taxon) ON UPDATE CASCADE;


--
-- Name: fk_cor_message_taxon_l_unites_geo; Type: FK CONSTRAINT; Schema: contactfaune; Owner: -
--

ALTER TABLE ONLY cor_message_taxon
    ADD CONSTRAINT fk_cor_message_taxon_l_unites_geo FOREIGN KEY (id_message_cf) REFERENCES bib_messages_cf(id_message_cf) ON UPDATE CASCADE;


--
-- Name: fk_cor_role_fiche_cf_t_fiches_cf; Type: FK CONSTRAINT; Schema: contactfaune; Owner: -
--

ALTER TABLE ONLY cor_role_fiche_cf
    ADD CONSTRAINT fk_cor_role_fiche_cf_t_fiches_cf FOREIGN KEY (id_cf) REFERENCES t_fiches_cf(id_cf) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_cor_role_fiche_cf_t_roles; Type: FK CONSTRAINT; Schema: contactfaune; Owner: -
--

ALTER TABLE ONLY cor_role_fiche_cf
    ADD CONSTRAINT fk_cor_role_fiche_cf_t_roles FOREIGN KEY (id_role) REFERENCES utilisateurs.t_roles(id_role) ON UPDATE CASCADE;


--
-- Name: fk_cor_unite_taxon_bib_taxons_fa; Type: FK CONSTRAINT; Schema: contactfaune; Owner: -
--

ALTER TABLE ONLY cor_unite_taxon
    ADD CONSTRAINT fk_cor_unite_taxon_bib_taxons_fa FOREIGN KEY (id_taxon) REFERENCES taxonomie.bib_taxons(id_taxon) ON UPDATE CASCADE;


--
-- Name: fk_t_releves_cf_bib_criteres_cf; Type: FK CONSTRAINT; Schema: contactfaune; Owner: -
--

ALTER TABLE ONLY t_releves_cf
    ADD CONSTRAINT fk_t_releves_cf_bib_criteres_cf FOREIGN KEY (id_critere_cf) REFERENCES bib_criteres_cf(id_critere_cf) ON UPDATE CASCADE;


--
-- Name: fk_t_releves_cf_bib_taxons; Type: FK CONSTRAINT; Schema: contactfaune; Owner: -
--

ALTER TABLE ONLY t_releves_cf
    ADD CONSTRAINT fk_t_releves_cf_bib_taxons FOREIGN KEY (id_taxon) REFERENCES taxonomie.bib_taxons(id_taxon) ON UPDATE CASCADE;


--
-- Name: fk_t_releves_cf_t_fiches_cf; Type: FK CONSTRAINT; Schema: contactfaune; Owner: -
--

ALTER TABLE ONLY t_releves_cf
    ADD CONSTRAINT fk_t_releves_cf_t_fiches_cf FOREIGN KEY (id_cf) REFERENCES t_fiches_cf(id_cf) ON UPDATE CASCADE;


--
-- Name: t_fiches_cf_id_lot_fkey; Type: FK CONSTRAINT; Schema: contactfaune; Owner: -
--

ALTER TABLE ONLY t_fiches_cf
    ADD CONSTRAINT t_fiches_cf_id_lot_fkey FOREIGN KEY (id_lot) REFERENCES meta.bib_lots(id_lot) ON UPDATE CASCADE;


--
-- Name: t_fiches_cf_id_organisme_fkey; Type: FK CONSTRAINT; Schema: contactfaune; Owner: -
--

ALTER TABLE ONLY t_fiches_cf
    ADD CONSTRAINT t_fiches_cf_id_organisme_fkey FOREIGN KEY (id_organisme) REFERENCES utilisateurs.bib_organismes(id_organisme) ON UPDATE CASCADE;


--
-- Name: t_fiches_cf_id_protocole_fkey; Type: FK CONSTRAINT; Schema: contactfaune; Owner: -
--

ALTER TABLE ONLY t_fiches_cf
    ADD CONSTRAINT t_fiches_cf_id_protocole_fkey FOREIGN KEY (id_protocole) REFERENCES meta.t_protocoles(id_protocole) ON UPDATE CASCADE;


SET search_path = contactinv, pg_catalog;

--
-- Name: bib_criteres_inv_id_critere_synthese_fkey; Type: FK CONSTRAINT; Schema: contactinv; Owner: -
--

ALTER TABLE ONLY bib_criteres_inv
    ADD CONSTRAINT bib_criteres_inv_id_critere_synthese_fkey FOREIGN KEY (id_critere_synthese) REFERENCES synthese.bib_criteres_synthese(id_critere_synthese);


--
-- Name: fk_cor_message_taxon_inv_bib_taxons; Type: FK CONSTRAINT; Schema: contactinv; Owner: -
--

ALTER TABLE ONLY cor_message_taxon
    ADD CONSTRAINT fk_cor_message_taxon_inv_bib_taxons FOREIGN KEY (id_taxon) REFERENCES taxonomie.bib_taxons(id_taxon) ON UPDATE CASCADE;


--
-- Name: fk_cor_message_taxon_inv_l_unites_geo; Type: FK CONSTRAINT; Schema: contactinv; Owner: -
--

ALTER TABLE ONLY cor_message_taxon
    ADD CONSTRAINT fk_cor_message_taxon_inv_l_unites_geo FOREIGN KEY (id_message_inv) REFERENCES bib_messages_inv(id_message_inv) ON UPDATE CASCADE;


--
-- Name: fk_cor_role_fiche_inv_t_fiches_inv; Type: FK CONSTRAINT; Schema: contactinv; Owner: -
--

ALTER TABLE ONLY cor_role_fiche_inv
    ADD CONSTRAINT fk_cor_role_fiche_inv_t_fiches_inv FOREIGN KEY (id_inv) REFERENCES t_fiches_inv(id_inv) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_cor_role_fiche_inv_t_roles; Type: FK CONSTRAINT; Schema: contactinv; Owner: -
--

ALTER TABLE ONLY cor_role_fiche_inv
    ADD CONSTRAINT fk_cor_role_fiche_inv_t_roles FOREIGN KEY (id_role) REFERENCES utilisateurs.t_roles(id_role) ON UPDATE CASCADE;


--
-- Name: fk_cor_unite_taxon_inv_bib_taxons; Type: FK CONSTRAINT; Schema: contactinv; Owner: -
--

ALTER TABLE ONLY cor_unite_taxon_inv
    ADD CONSTRAINT fk_cor_unite_taxon_inv_bib_taxons FOREIGN KEY (id_taxon) REFERENCES taxonomie.bib_taxons(id_taxon) ON UPDATE CASCADE;


--
-- Name: fk_t_fiches_inv_bib_milieux_inv; Type: FK CONSTRAINT; Schema: contactinv; Owner: -
--

ALTER TABLE ONLY t_fiches_inv
    ADD CONSTRAINT fk_t_fiches_inv_bib_milieux_inv FOREIGN KEY (id_milieu_inv) REFERENCES bib_milieux_inv(id_milieu_inv) ON UPDATE CASCADE;


--
-- Name: fk_t_releves_inv_bib_criteres_inv; Type: FK CONSTRAINT; Schema: contactinv; Owner: -
--

ALTER TABLE ONLY t_releves_inv
    ADD CONSTRAINT fk_t_releves_inv_bib_criteres_inv FOREIGN KEY (id_critere_inv) REFERENCES bib_criteres_inv(id_critere_inv) ON UPDATE CASCADE;


--
-- Name: fk_t_releves_inv_bib_taxons; Type: FK CONSTRAINT; Schema: contactinv; Owner: -
--

ALTER TABLE ONLY t_releves_inv
    ADD CONSTRAINT fk_t_releves_inv_bib_taxons FOREIGN KEY (id_taxon) REFERENCES taxonomie.bib_taxons(id_taxon) ON UPDATE CASCADE;


--
-- Name: fk_t_releves_inv_t_fiches_inv; Type: FK CONSTRAINT; Schema: contactinv; Owner: -
--

ALTER TABLE ONLY t_releves_inv
    ADD CONSTRAINT fk_t_releves_inv_t_fiches_inv FOREIGN KEY (id_inv) REFERENCES t_fiches_inv(id_inv) ON UPDATE CASCADE;


--
-- Name: t_fiches_inv_id_lot_fkey; Type: FK CONSTRAINT; Schema: contactinv; Owner: -
--

ALTER TABLE ONLY t_fiches_inv
    ADD CONSTRAINT t_fiches_inv_id_lot_fkey FOREIGN KEY (id_lot) REFERENCES meta.bib_lots(id_lot) ON UPDATE CASCADE;


--
-- Name: t_fiches_inv_id_organisme_fkey; Type: FK CONSTRAINT; Schema: contactinv; Owner: -
--

ALTER TABLE ONLY t_fiches_inv
    ADD CONSTRAINT t_fiches_inv_id_organisme_fkey FOREIGN KEY (id_organisme) REFERENCES utilisateurs.bib_organismes(id_organisme) ON UPDATE CASCADE;


--
-- Name: t_fiches_inv_id_protocole_fkey; Type: FK CONSTRAINT; Schema: contactinv; Owner: -
--

ALTER TABLE ONLY t_fiches_inv
    ADD CONSTRAINT t_fiches_inv_id_protocole_fkey FOREIGN KEY (id_protocole) REFERENCES meta.t_protocoles(id_protocole) ON UPDATE CASCADE;


SET search_path = bryophytes, pg_catalog;

--
-- TOC entry 3449 (class 2606 OID 70678)
-- Name: cor_bryo_observateur_id_station_fkey; Type: FK CONSTRAINT; Schema: bryophytes; Owner: -
--

ALTER TABLE ONLY cor_bryo_observateur
    ADD CONSTRAINT cor_bryo_observateur_id_station_fkey FOREIGN KEY (id_station) REFERENCES t_stations_bryo(id_station) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 3450 (class 2606 OID 179965)
-- Name: cor_bryo_taxons_cd_nom_fkey; Type: FK CONSTRAINT; Schema: bryophytes; Owner: -
--

ALTER TABLE ONLY cor_bryo_taxon
    ADD CONSTRAINT cor_bryo_taxons_cd_nom_fkey FOREIGN KEY (cd_nom) REFERENCES taxonomie.taxref(cd_nom) ON UPDATE CASCADE;


--
-- TOC entry 3452 (class 2606 OID 70688)
-- Name: cor_bryo_taxons_id_abondance_fkey; Type: FK CONSTRAINT; Schema: bryophytes; Owner: -
--

ALTER TABLE ONLY cor_bryo_taxon
    ADD CONSTRAINT cor_bryo_taxons_id_abondance_fkey FOREIGN KEY (id_abondance) REFERENCES bib_abondances(id_abondance) ON UPDATE CASCADE;


--
-- TOC entry 3451 (class 2606 OID 70693)
-- Name: cor_bryo_taxons_id_station_fkey; Type: FK CONSTRAINT; Schema: bryophytes; Owner: -
--

ALTER TABLE ONLY cor_bryo_taxon
    ADD CONSTRAINT cor_bryo_taxons_id_station_fkey FOREIGN KEY (id_station) REFERENCES t_stations_bryo(id_station) ON UPDATE CASCADE;


--
-- TOC entry 3448 (class 2606 OID 70698)
-- Name: fk_cor_bryo_observateur_t_roles; Type: FK CONSTRAINT; Schema: bryophytes; Owner: -
--

ALTER TABLE ONLY cor_bryo_observateur
    ADD CONSTRAINT fk_cor_bryo_observateur_t_roles FOREIGN KEY (id_role) REFERENCES utilisateurs.t_roles(id_role) ON UPDATE CASCADE;


--
-- TOC entry 3453 (class 2606 OID 70703)
-- Name: fk_t_stations_bryo_bib_expositions; Type: FK CONSTRAINT; Schema: bryophytes; Owner: -
--

ALTER TABLE ONLY t_stations_bryo
    ADD CONSTRAINT fk_t_stations_bryo_bib_expositions FOREIGN KEY (id_exposition) REFERENCES bib_expositions(id_exposition) ON UPDATE CASCADE;


--
-- TOC entry 3453 (class 2606 OID 70703)
-- Name: fk_t_stations_bryo_t_protocoles; Type: FK CONSTRAINT; Schema: bryophytes; Owner: -
--

ALTER TABLE ONLY t_stations_bryo
    ADD CONSTRAINT fk_t_stations_bryo_t_protocoles FOREIGN KEY (id_protocole) REFERENCES meta.t_protocoles(id_protocole) ON UPDATE CASCADE;


--
-- TOC entry 3453 (class 2606 OID 70703)
-- Name: fk_t_stations_bryo_bib_lots; Type: FK CONSTRAINT; Schema: bryophytes; Owner: -
--

ALTER TABLE ONLY t_stations_bryo
    ADD CONSTRAINT fk_t_stations_bryo_bib_lots FOREIGN KEY (id_lot) REFERENCES meta.bib_lots(id_lot) ON UPDATE CASCADE;


--
-- TOC entry 3453 (class 2606 OID 70703)
-- Name: fk_t_stations_bryo_bib_organismes; Type: FK CONSTRAINT; Schema: bryophytes; Owner: -
--

ALTER TABLE ONLY t_stations_bryo
    ADD CONSTRAINT fk_t_stations_bryo_bib_organismes FOREIGN KEY (id_organisme) REFERENCES utilisateurs.bib_organismes(id_organisme) ON UPDATE CASCADE;


--
-- TOC entry 3454 (class 2606 OID 70708)
-- Name: fk_t_stations_bryo_bib_supports; Type: FK CONSTRAINT; Schema: bryophytes; Owner: -
--

ALTER TABLE ONLY t_stations_bryo
    ADD CONSTRAINT fk_t_stations_bryo_bib_supports FOREIGN KEY (id_support) REFERENCES meta.bib_supports(id_support) ON UPDATE CASCADE;


SET search_path = florepatri, pg_catalog;

--
-- TOC entry 3455 (class 2606 OID 179960)
-- Name: bib_taxons_fp_cd_nom_fkey; Type: FK CONSTRAINT; Schema: florepatri; Owner: -
--

ALTER TABLE ONLY bib_taxons_fp
    ADD CONSTRAINT bib_taxons_fp_cd_nom_fkey FOREIGN KEY (cd_nom) REFERENCES taxonomie.taxref(cd_nom) ON UPDATE CASCADE;


--
-- TOC entry 3461 (class 2606 OID 70718)
-- Name: cor_taxon_statut_cd_nom_fkey; Type: FK CONSTRAINT; Schema: florepatri; Owner: -
--

ALTER TABLE ONLY cor_taxon_statut
    ADD CONSTRAINT cor_taxon_statut_cd_nom_fkey FOREIGN KEY (cd_nom) REFERENCES bib_taxons_fp(cd_nom) ON UPDATE CASCADE;


--
-- TOC entry 3457 (class 2606 OID 70723)
-- Name: fk_cor_ap_perturb_bib_perturbati; Type: FK CONSTRAINT; Schema: florepatri; Owner: -
--

ALTER TABLE ONLY cor_ap_perturb
    ADD CONSTRAINT fk_cor_ap_perturb_bib_perturbati FOREIGN KEY (codeper) REFERENCES bib_perturbations(codeper) ON UPDATE CASCADE;


--
-- TOC entry 3456 (class 2606 OID 70728)
-- Name: fk_cor_ap_perturb_t_apresence; Type: FK CONSTRAINT; Schema: florepatri; Owner: -
--

ALTER TABLE ONLY cor_ap_perturb
    ADD CONSTRAINT fk_cor_ap_perturb_t_apresence FOREIGN KEY (indexap) REFERENCES t_apresence(indexap) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 3459 (class 2606 OID 70733)
-- Name: fk_cor_ap_physionomie_bib_physio; Type: FK CONSTRAINT; Schema: florepatri; Owner: -
--

ALTER TABLE ONLY cor_ap_physionomie
    ADD CONSTRAINT fk_cor_ap_physionomie_bib_physio FOREIGN KEY (id_physionomie) REFERENCES bib_physionomies(id_physionomie) ON UPDATE CASCADE;


--
-- TOC entry 3458 (class 2606 OID 70738)
-- Name: fk_cor_ap_physionomie_t_apresence; Type: FK CONSTRAINT; Schema: florepatri; Owner: -
--

ALTER TABLE ONLY cor_ap_physionomie
    ADD CONSTRAINT fk_cor_ap_physionomie_t_apresence FOREIGN KEY (indexap) REFERENCES t_apresence(indexap) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 3460 (class 2606 OID 70743)
-- Name: fk_cor_taxon_statut_bib_statuts; Type: FK CONSTRAINT; Schema: florepatri; Owner: -
--

ALTER TABLE ONLY cor_taxon_statut
    ADD CONSTRAINT fk_cor_taxon_statut_bib_statuts FOREIGN KEY (id_statut) REFERENCES bib_statuts(id_statut) ON UPDATE CASCADE;


--
-- TOC entry 3463 (class 2606 OID 70748)
-- Name: fk_cor_zp_obs_t_roles; Type: FK CONSTRAINT; Schema: florepatri; Owner: -
--

ALTER TABLE ONLY cor_zp_obs
    ADD CONSTRAINT fk_cor_zp_obs_t_roles FOREIGN KEY (codeobs) REFERENCES utilisateurs.t_roles(id_role);


--
-- TOC entry 3462 (class 2606 OID 70753)
-- Name: fk_cor_zp_obs_t_zprospection; Type: FK CONSTRAINT; Schema: florepatri; Owner: -
--

ALTER TABLE ONLY cor_zp_obs
    ADD CONSTRAINT fk_cor_zp_obs_t_zprospection FOREIGN KEY (indexzp) REFERENCES t_zprospection(indexzp) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 3464 (class 2606 OID 70758)
-- Name: fk_t_apresence_bib_phenologie; Type: FK CONSTRAINT; Schema: florepatri; Owner: -
--

ALTER TABLE ONLY t_apresence
    ADD CONSTRAINT fk_t_apresence_bib_phenologie FOREIGN KEY (codepheno) REFERENCES bib_phenologies(codepheno) ON UPDATE CASCADE;


--
-- TOC entry 3465 (class 2606 OID 70763)
-- Name: fk_t_apresence_t_zprospection; Type: FK CONSTRAINT; Schema: florepatri; Owner: -
--

ALTER TABLE ONLY t_apresence
    ADD CONSTRAINT fk_t_apresence_t_zprospection FOREIGN KEY (indexzp) REFERENCES t_zprospection(indexzp) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 3468 (class 2606 OID 70768)
-- Name: fk_t_zprospection_bib_taxon_fp; Type: FK CONSTRAINT; Schema: florepatri; Owner: -
--

ALTER TABLE ONLY t_zprospection
    ADD CONSTRAINT fk_t_zprospection_bib_taxon_fp FOREIGN KEY (cd_nom) REFERENCES bib_taxons_fp(cd_nom) ON UPDATE CASCADE;


--
-- TOC entry 3466 (class 2606 OID 70773)
-- Name: t_apresence_comptage_methodo_fkey; Type: FK CONSTRAINT; Schema: florepatri; Owner: -
--

ALTER TABLE ONLY t_apresence
    ADD CONSTRAINT t_apresence_comptage_methodo_fkey FOREIGN KEY (id_comptage_methodo) REFERENCES bib_comptages_methodo(id_comptage_methodo) ON UPDATE CASCADE;


--
-- TOC entry 3467 (class 2606 OID 70778)
-- Name: t_apresence_frequence_methodo_new_fkey; Type: FK CONSTRAINT; Schema: florepatri; Owner: -
--

ALTER TABLE ONLY t_apresence
    ADD CONSTRAINT t_apresence_frequence_methodo_new_fkey FOREIGN KEY (id_frequence_methodo_new) REFERENCES bib_frequences_methodo_new(id_frequence_methodo_new) ON UPDATE CASCADE;


--
-- TOC entry 3469 (class 2606 OID 70783)
-- Name: t_zprospection_id_organisme_fkey; Type: FK CONSTRAINT; Schema: florepatri; Owner: -
--

ALTER TABLE ONLY t_zprospection
    ADD CONSTRAINT t_zprospection_id_organisme_fkey FOREIGN KEY (id_organisme) REFERENCES utilisateurs.bib_organismes(id_organisme) ON UPDATE CASCADE;


--
-- TOC entry 3453 (class 2606 OID 70703)
-- Name: fk_t_zprospection_t_protocoles; Type: FK CONSTRAINT; Schema: florepatri; Owner: -
--

ALTER TABLE ONLY t_zprospection
    ADD CONSTRAINT fk_t_zprospection_t_protocoles FOREIGN KEY (id_protocole) REFERENCES meta.t_protocoles(id_protocole) ON UPDATE CASCADE;


--
-- TOC entry 3453 (class 2606 OID 70703)
-- Name: fk_t_zprospection_bib_lots; Type: FK CONSTRAINT; Schema: florepatri; Owner: -
--

ALTER TABLE ONLY t_zprospection
    ADD CONSTRAINT fk_t_zprospection_bib_lots FOREIGN KEY (id_lot) REFERENCES meta.bib_lots(id_lot) ON UPDATE CASCADE;


--
-- TOC entry 3470 (class 2606 OID 70788)
-- Name: t_zprospection_id_rezo_ecrins_fkey; Type: FK CONSTRAINT; Schema: florepatri; Owner: -
--

ALTER TABLE ONLY t_zprospection
    ADD CONSTRAINT t_zprospection_id_rezo_ecrins_fkey FOREIGN KEY (id_rezo_ecrins) REFERENCES bib_rezo_ecrins(id_rezo_ecrins) ON UPDATE CASCADE;


--
-- TOC entry 3471 (class 2606 OID 70793)
-- Name: t_zprospection_id_secteur_fkey; Type: FK CONSTRAINT; Schema: florepatri; Owner: -
--

ALTER TABLE ONLY t_zprospection
    ADD CONSTRAINT t_zprospection_id_secteur_fkey FOREIGN KEY (id_secteur) REFERENCES layers.l_secteurs(id_secteur) ON UPDATE CASCADE;


SET search_path = florestation, pg_catalog;

--
-- TOC entry 3472 (class 2606 OID 70798)
-- Name: cor_fs_delphine_id_station_fkey; Type: FK CONSTRAINT; Schema: florestation; Owner: -
--

ALTER TABLE ONLY cor_fs_delphine
    ADD CONSTRAINT cor_fs_delphine_id_station_fkey FOREIGN KEY (id_station) REFERENCES t_stations_fs(id_station) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 3474 (class 2606 OID 70803)
-- Name: cor_fs_microrelief_id_station_fkey; Type: FK CONSTRAINT; Schema: florestation; Owner: -
--

ALTER TABLE ONLY cor_fs_microrelief
    ADD CONSTRAINT cor_fs_microrelief_id_station_fkey FOREIGN KEY (id_station) REFERENCES t_stations_fs(id_station) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 3476 (class 2606 OID 70808)
-- Name: cor_fs_observateur_id_station_fkey; Type: FK CONSTRAINT; Schema: florestation; Owner: -
--

ALTER TABLE ONLY cor_fs_observateur
    ADD CONSTRAINT cor_fs_observateur_id_station_fkey FOREIGN KEY (id_station) REFERENCES t_stations_fs(id_station) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 3482 (class 2606 OID 179975)
-- Name: cor_fs_taxons_cd_nom_fkey; Type: FK CONSTRAINT; Schema: florestation; Owner: -
--

ALTER TABLE ONLY cor_fs_taxon
    ADD CONSTRAINT cor_fs_taxons_cd_nom_fkey FOREIGN KEY (cd_nom) REFERENCES taxonomie.taxref(cd_nom) ON UPDATE CASCADE;


--
-- TOC entry 3477 (class 2606 OID 70818)
-- Name: cor_fs_taxons_id_station_fkey; Type: FK CONSTRAINT; Schema: florestation; Owner: -
--

ALTER TABLE ONLY cor_fs_taxon
    ADD CONSTRAINT cor_fs_taxons_id_station_fkey FOREIGN KEY (id_station) REFERENCES t_stations_fs(id_station) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 3473 (class 2606 OID 70823)
-- Name: fk_cor_fs_microrelief_bib_microreliefs; Type: FK CONSTRAINT; Schema: florestation; Owner: -
--

ALTER TABLE ONLY cor_fs_microrelief
    ADD CONSTRAINT fk_cor_fs_microrelief_bib_microreliefs FOREIGN KEY (id_microrelief) REFERENCES bib_microreliefs(id_microrelief) ON UPDATE CASCADE;


--
-- TOC entry 3475 (class 2606 OID 70828)
-- Name: fk_cor_fs_observateur_t_roles; Type: FK CONSTRAINT; Schema: florestation; Owner: -
--

ALTER TABLE ONLY cor_fs_observateur
    ADD CONSTRAINT fk_cor_fs_observateur_t_roles FOREIGN KEY (id_role) REFERENCES utilisateurs.t_roles(id_role) ON UPDATE CASCADE;


--
-- TOC entry 3478 (class 2606 OID 70833)
-- Name: fk_de_1_4m; Type: FK CONSTRAINT; Schema: florestation; Owner: -
--

ALTER TABLE ONLY cor_fs_taxon
    ADD CONSTRAINT fk_de_1_4m FOREIGN KEY (de_1_4m) REFERENCES bib_abondances(id_abondance) ON UPDATE CASCADE;


--
-- TOC entry 3479 (class 2606 OID 70838)
-- Name: fk_herb; Type: FK CONSTRAINT; Schema: florestation; Owner: -
--

ALTER TABLE ONLY cor_fs_taxon
    ADD CONSTRAINT fk_herb FOREIGN KEY (herb) REFERENCES bib_abondances(id_abondance) ON UPDATE CASCADE;


--
-- TOC entry 3480 (class 2606 OID 70843)
-- Name: fk_inf_1m; Type: FK CONSTRAINT; Schema: florestation; Owner: -
--

ALTER TABLE ONLY cor_fs_taxon
    ADD CONSTRAINT fk_inf_1m FOREIGN KEY (inf_1m) REFERENCES bib_abondances(id_abondance) ON UPDATE CASCADE;


--
-- TOC entry 3481 (class 2606 OID 70848)
-- Name: fk_sup_4m; Type: FK CONSTRAINT; Schema: florestation; Owner: -
--

ALTER TABLE ONLY cor_fs_taxon
    ADD CONSTRAINT fk_sup_4m FOREIGN KEY (sup_4m) REFERENCES bib_abondances(id_abondance) ON UPDATE CASCADE;


--
-- TOC entry 3483 (class 2606 OID 70853)
-- Name: fk_t_stations_fs_bib_expositions; Type: FK CONSTRAINT; Schema: florestation; Owner: -
--

ALTER TABLE ONLY t_stations_fs
    ADD CONSTRAINT fk_t_stations_fs_bib_expositions FOREIGN KEY (id_exposition) REFERENCES bib_expositions(id_exposition) ON UPDATE CASCADE;


--
-- TOC entry 3484 (class 2606 OID 70858)
-- Name: fk_t_stations_fs_bib_homogenes; Type: FK CONSTRAINT; Schema: florestation; Owner: -
--

ALTER TABLE ONLY t_stations_fs
    ADD CONSTRAINT fk_t_stations_fs_bib_homogenes FOREIGN KEY (id_homogene) REFERENCES bib_homogenes(id_homogene) ON UPDATE CASCADE;


--
-- TOC entry 3485 (class 2606 OID 70863)
-- Name: fk_t_stations_fs_bib_programmes_; Type: FK CONSTRAINT; Schema: florestation; Owner: -
--

ALTER TABLE ONLY t_stations_fs
    ADD CONSTRAINT fk_t_stations_fs_bib_programmes_ FOREIGN KEY (id_programme_fs) REFERENCES bib_programmes_fs(id_programme_fs) ON UPDATE CASCADE;


--
-- TOC entry 3486 (class 2606 OID 70868)
-- Name: fk_t_stations_fs_bib_supports; Type: FK CONSTRAINT; Schema: florestation; Owner: -
--

ALTER TABLE ONLY t_stations_fs
    ADD CONSTRAINT fk_t_stations_fs_bib_supports FOREIGN KEY (id_support) REFERENCES meta.bib_supports(id_support) ON UPDATE CASCADE;


--
-- TOC entry 3453 (class 2606 OID 70703)
-- Name: fk_t_stations_fs_t_protocoles; Type: FK CONSTRAINT; Schema: florestation; Owner: -
--

ALTER TABLE ONLY t_stations_fs
    ADD CONSTRAINT fk_t_stations_fs_t_protocoles FOREIGN KEY (id_protocole) REFERENCES meta.t_protocoles(id_protocole) ON UPDATE CASCADE;


--
-- TOC entry 3453 (class 2606 OID 70703)
-- Name: fk_t_stations_fs_bib_organismes; Type: FK CONSTRAINT; Schema: florestation; Owner: -
--

ALTER TABLE ONLY t_stations_fs
    ADD CONSTRAINT fk_t_stations_fs_bib_organismes FOREIGN KEY (id_organisme) REFERENCES utilisateurs.bib_organismes(id_organisme) ON UPDATE CASCADE;


--
-- TOC entry 3453 (class 2606 OID 70703)
-- Name: fk_t_stations_fs_bib_lots; Type: FK CONSTRAINT; Schema: florestation; Owner: -
--

ALTER TABLE ONLY t_stations_fs
    ADD CONSTRAINT fk_t_stations_fs_bib_lots FOREIGN KEY (id_lot) REFERENCES meta.bib_lots(id_lot) ON UPDATE CASCADE;


--
-- TOC entry 3487 (class 2606 OID 70873)
-- Name: fk_t_stations_fs_bib_surfaces; Type: FK CONSTRAINT; Schema: florestation; Owner: -
--

ALTER TABLE ONLY t_stations_fs
    ADD CONSTRAINT fk_t_stations_fs_bib_surfaces FOREIGN KEY (id_surface) REFERENCES bib_surfaces(id_surface) ON UPDATE CASCADE;


SET search_path = layers, pg_catalog;

--
-- Name: l_communes_id_secteur_fkey; Type: FK CONSTRAINT; Schema: layers; Owner: -
--

ALTER TABLE ONLY l_communes
    ADD CONSTRAINT l_communes_id_secteur_fkey FOREIGN KEY (id_secteur) REFERENCES l_secteurs(id_secteur);


--
-- Name: l_zonesstatut_id_type_fkey; Type: FK CONSTRAINT; Schema: layers; Owner: -
--

ALTER TABLE ONLY l_zonesstatut
    ADD CONSTRAINT l_zonesstatut_id_type_fkey FOREIGN KEY (id_type) REFERENCES bib_typeszones(id_type) ON UPDATE CASCADE;


SET search_path = meta, pg_catalog;

--
-- Name: fk_bib_programmes_bib_lots; Type: FK CONSTRAINT; Schema: meta; Owner: -
--

ALTER TABLE ONLY bib_lots
    ADD CONSTRAINT fk_bib_programmes_bib_lots FOREIGN KEY (id_programme) REFERENCES bib_programmes(id_programme) ON UPDATE CASCADE;


SET search_path = synthese, pg_catalog;

--
-- Name: fk_cor_unite_synthese_syntheseff; Type: FK CONSTRAINT; Schema: synthese; Owner: -
--

ALTER TABLE ONLY cor_unite_synthese
    ADD CONSTRAINT fk_cor_unite_synthese_syntheseff FOREIGN KEY (id_synthese) REFERENCES syntheseff(id_synthese) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_cor_zonesstatut_synthese_syntheseff; Type: FK CONSTRAINT; Schema: synthese; Owner: -
--

ALTER TABLE ONLY cor_zonesstatut_synthese
    ADD CONSTRAINT fk_cor_zonesstatut_synthese_syntheseff FOREIGN KEY (id_synthese) REFERENCES syntheseff(id_synthese) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_synthese_bib_organismes; Type: FK CONSTRAINT; Schema: synthese; Owner: -
--

ALTER TABLE ONLY syntheseff
    ADD CONSTRAINT fk_synthese_bib_organismes FOREIGN KEY (id_organisme) REFERENCES utilisateurs.bib_organismes(id_organisme) ON UPDATE CASCADE;


--
-- Name: synthese_id_critere_synthese_fkey; Type: FK CONSTRAINT; Schema: synthese; Owner: -
--

ALTER TABLE ONLY syntheseff
    ADD CONSTRAINT synthese_id_critere_synthese_fkey FOREIGN KEY (id_critere_synthese) REFERENCES bib_criteres_synthese(id_critere_synthese) ON UPDATE CASCADE;


--
-- Name: synthese_id_lot_fkey; Type: FK CONSTRAINT; Schema: synthese; Owner: -
--

ALTER TABLE ONLY syntheseff
    ADD CONSTRAINT synthese_id_lot_fkey FOREIGN KEY (id_lot) REFERENCES meta.bib_lots(id_lot) ON UPDATE CASCADE;


--
-- Name: synthese_id_precision_fkey; Type: FK CONSTRAINT; Schema: synthese; Owner: -
--

ALTER TABLE ONLY syntheseff
    ADD CONSTRAINT synthese_id_precision_fkey FOREIGN KEY (id_precision) REFERENCES meta.t_precisions(id_precision) ON UPDATE CASCADE;


--
-- Name: synthese_id_protocole_fkey; Type: FK CONSTRAINT; Schema: synthese; Owner: -
--

ALTER TABLE ONLY syntheseff
    ADD CONSTRAINT synthese_id_protocole_fkey FOREIGN KEY (id_protocole) REFERENCES meta.t_protocoles(id_protocole) ON UPDATE CASCADE;


--
-- Name: synthese_id_source_fkey; Type: FK CONSTRAINT; Schema: synthese; Owner: -
--

ALTER TABLE ONLY syntheseff
    ADD CONSTRAINT synthese_id_source_fkey FOREIGN KEY (id_source) REFERENCES bib_sources(id_source) ON UPDATE CASCADE;


SET search_path = taxonomie, pg_catalog;

--
-- Name: cor_taxon_listes_bib_taxons_fkey; Type: FK CONSTRAINT; Schema: taxonomie; Owner: -
--

ALTER TABLE ONLY cor_taxon_liste 
    ADD CONSTRAINT cor_taxon_listes_bib_taxons_fkey FOREIGN KEY (id_taxon) REFERENCES bib_taxons (id_taxon);
 
--
-- Name: cor_taxon_listes_bib_listes_fkey; Type: FK CONSTRAINT; Schema: taxonomie; Owner: -
--

ALTER TABLE ONLY cor_taxon_liste 
    ADD CONSTRAINT cor_taxon_listes_bib_listes_fkey FOREIGN KEY (id_liste) REFERENCES bib_listes (id_liste);
 
--
-- Name: cor_taxon_groupe_bib_groupes_fkey; Type: FK CONSTRAINT; Schema: taxonomie; Owner: -
--

ALTER TABLE ONLY cor_taxon_groupe 
    ADD CONSTRAINT cor_taxon_groupe_bib_groupes_fkey FOREIGN KEY (id_groupe) REFERENCES bib_groupes (id_groupe);
    
--
-- Name: cor_taxon_groupe_bib_taxons_fkey; Type: FK CONSTRAINT; Schema: taxonomie; Owner: -
--

ALTER TABLE ONLY cor_taxon_groupe 
    ADD CONSTRAINT cor_taxon_groupe_bib_taxons_fkey FOREIGN KEY (id_taxon) REFERENCES bib_taxons (id_taxon);
    
--
-- Name: cor_taxon_attrib_bib_taxons_fkey; Type: FK CONSTRAINT; Schema: taxonomie; Owner: -
--

ALTER TABLE ONLY cor_taxon_attribut 
    ADD CONSTRAINT cor_taxon_attrib_bib_taxons_fkey FOREIGN KEY (id_taxon) REFERENCES bib_taxons (id_taxon);
    
--
-- Name: cor_taxon_attrib_bib_attrib_fkey; Type: FK CONSTRAINT; Schema: taxonomie; Owner: -
--

ALTER TABLE ONLY cor_taxon_attribut 
    ADD CONSTRAINT cor_taxon_attrib_bib_attrib_fkey FOREIGN KEY (id_attribut) REFERENCES bib_attributs (id_attribut);

--
-- Name: fk_bib_taxons_taxref; Type: FK CONSTRAINT; Schema: taxonomie; Owner: -
--

ALTER TABLE ONLY bib_taxons
    ADD CONSTRAINT fk_bib_taxons_taxref FOREIGN KEY (cd_nom) REFERENCES taxref(cd_nom);


--
-- Name: fk_taxref_bib_taxref_habitats; Type: FK CONSTRAINT; Schema: taxonomie; Owner: -
--

ALTER TABLE ONLY taxref
    ADD CONSTRAINT fk_taxref_bib_taxref_habitats FOREIGN KEY (id_habitat) REFERENCES bib_taxref_habitats(id_habitat) ON UPDATE CASCADE;


--
-- Name: fk_taxref_bib_taxref_rangs; Type: FK CONSTRAINT; Schema: taxonomie; Owner: -
--

ALTER TABLE ONLY taxref
    ADD CONSTRAINT fk_taxref_bib_taxref_rangs FOREIGN KEY (id_rang) REFERENCES bib_taxref_rangs(id_rang) ON UPDATE CASCADE;


--
-- Name: taxref_id_statut_fkey; Type: FK CONSTRAINT; Schema: taxonomie; Owner: -
--

ALTER TABLE ONLY taxref
    ADD CONSTRAINT taxref_id_statut_fkey FOREIGN KEY (id_statut) REFERENCES bib_taxref_statuts(id_statut) ON UPDATE CASCADE;


--
-- Name: taxref_protection_especes_cd_nom_fkey; Type: FK CONSTRAINT; Schema: taxonomie; Owner: -
--

ALTER TABLE ONLY taxref_protection_especes
    ADD CONSTRAINT taxref_protection_especes_cd_nom_fkey FOREIGN KEY (cd_nom) REFERENCES taxref(cd_nom) ON UPDATE CASCADE;


--
-- Name: taxref_protection_especes_cd_protection_fkey; Type: FK CONSTRAINT; Schema: taxonomie; Owner: -
--

ALTER TABLE ONLY taxref_protection_especes
    ADD CONSTRAINT taxref_protection_especes_cd_protection_fkey FOREIGN KEY (cd_protection) REFERENCES taxref_protection_articles(cd_protection);


SET search_path = utilisateurs, pg_catalog;

--
-- Name: cor_role_droit_application_id_application_fkey; Type: FK CONSTRAINT; Schema: utilisateurs; Owner: -
--

ALTER TABLE ONLY cor_role_droit_application
    ADD CONSTRAINT cor_role_droit_application_id_application_fkey FOREIGN KEY (id_application) REFERENCES t_applications(id_application) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: cor_role_droit_application_id_droit_fkey; Type: FK CONSTRAINT; Schema: utilisateurs; Owner: -
--

ALTER TABLE ONLY cor_role_droit_application
    ADD CONSTRAINT cor_role_droit_application_id_droit_fkey FOREIGN KEY (id_droit) REFERENCES bib_droits(id_droit) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: cor_role_droit_application_id_role_fkey; Type: FK CONSTRAINT; Schema: utilisateurs; Owner: -
--

ALTER TABLE ONLY cor_role_droit_application
    ADD CONSTRAINT cor_role_droit_application_id_role_fkey FOREIGN KEY (id_role) REFERENCES t_roles(id_role) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: cor_role_menu_application_id_menu_fkey; Type: FK CONSTRAINT; Schema: utilisateurs; Owner: -
--

ALTER TABLE ONLY cor_role_menu
    ADD CONSTRAINT cor_role_menu_application_id_menu_fkey FOREIGN KEY (id_menu) REFERENCES t_menus(id_menu) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: cor_role_menu_application_id_role_fkey; Type: FK CONSTRAINT; Schema: utilisateurs; Owner: -
--

ALTER TABLE ONLY cor_role_menu
    ADD CONSTRAINT cor_role_menu_application_id_role_fkey FOREIGN KEY (id_role) REFERENCES t_roles(id_role) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: cor_roles_id_role_groupe_fkey; Type: FK CONSTRAINT; Schema: utilisateurs; Owner: -
--

ALTER TABLE ONLY cor_roles
    ADD CONSTRAINT cor_roles_id_role_groupe_fkey FOREIGN KEY (id_role_groupe) REFERENCES t_roles(id_role) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: cor_roles_id_role_utilisateur_fkey; Type: FK CONSTRAINT; Schema: utilisateurs; Owner: -
--

ALTER TABLE ONLY cor_roles
    ADD CONSTRAINT cor_roles_id_role_utilisateur_fkey FOREIGN KEY (id_role_utilisateur) REFERENCES t_roles(id_role) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: t_menus_id_application_fkey; Type: FK CONSTRAINT; Schema: utilisateurs; Owner: -
--

ALTER TABLE ONLY t_menus
    ADD CONSTRAINT t_menus_id_application_fkey FOREIGN KEY (id_application) REFERENCES t_applications(id_application) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: t_roles_id_organisme_fkey; Type: FK CONSTRAINT; Schema: utilisateurs; Owner: -
--

ALTER TABLE ONLY t_roles
    ADD CONSTRAINT t_roles_id_organisme_fkey FOREIGN KEY (id_organisme) REFERENCES bib_organismes(id_organisme) ON UPDATE CASCADE;


--
-- Name: t_roles_id_unite_fkey; Type: FK CONSTRAINT; Schema: utilisateurs; Owner: -
--

ALTER TABLE ONLY t_roles
    ADD CONSTRAINT t_roles_id_unite_fkey FOREIGN KEY (id_unite) REFERENCES bib_unites(id_unite) ON UPDATE CASCADE;


--
-- Name: contactfaune; Type: ACL; Schema: -; Owner: -
--

REVOKE ALL ON SCHEMA contactfaune FROM PUBLIC;
REVOKE ALL ON SCHEMA contactfaune FROM geonatuser;
GRANT ALL ON SCHEMA contactfaune TO geonatuser;


--
-- Name: contactinv; Type: ACL; Schema: -; Owner: -
--

REVOKE ALL ON SCHEMA contactinv FROM PUBLIC;
REVOKE ALL ON SCHEMA contactinv FROM geonatuser;
GRANT ALL ON SCHEMA contactinv TO geonatuser;


--
-- Name: bryophytes; Type: ACL; Schema: -; Owner: -
--

REVOKE ALL ON SCHEMA bryophytes FROM PUBLIC;
REVOKE ALL ON SCHEMA bryophytes FROM geonatuser;
GRANT ALL ON SCHEMA bryophytes TO geonatuser;


--
-- Name: florepatri; Type: ACL; Schema: -; Owner: -
--

REVOKE ALL ON SCHEMA florepatri FROM PUBLIC;
REVOKE ALL ON SCHEMA florepatri FROM geonatuser;
GRANT ALL ON SCHEMA florepatri TO geonatuser;


--
-- Name: florestation; Type: ACL; Schema: -; Owner: -
--

REVOKE ALL ON SCHEMA florestation FROM PUBLIC;
REVOKE ALL ON SCHEMA florestation FROM geonatuser;
GRANT ALL ON SCHEMA florestation TO geonatuser;


--
-- Name: layers; Type: ACL; Schema: -; Owner: -
--

REVOKE ALL ON SCHEMA layers FROM PUBLIC;
REVOKE ALL ON SCHEMA layers FROM geonatuser;
GRANT ALL ON SCHEMA layers TO geonatuser;
GRANT ALL ON SCHEMA layers TO postgres;


--
-- Name: meta; Type: ACL; Schema: -; Owner: -
--

REVOKE ALL ON SCHEMA meta FROM PUBLIC;
REVOKE ALL ON SCHEMA meta FROM geonatuser;
GRANT ALL ON SCHEMA meta TO geonatuser;


--
-- Name: synchronomade; Type: ACL; Schema: -; Owner: -
--

REVOKE ALL ON SCHEMA synchronomade FROM PUBLIC;
REVOKE ALL ON SCHEMA synchronomade FROM geonatuser;
GRANT ALL ON SCHEMA synchronomade TO geonatuser;


--
-- Name: synthese; Type: ACL; Schema: -; Owner: -
--

REVOKE ALL ON SCHEMA synthese FROM PUBLIC;
REVOKE ALL ON SCHEMA synthese FROM geonatuser;
GRANT ALL ON SCHEMA synthese TO geonatuser;


--
-- Name: taxonomie; Type: ACL; Schema: -; Owner: -
--

REVOKE ALL ON SCHEMA taxonomie FROM PUBLIC;
REVOKE ALL ON SCHEMA taxonomie FROM geonatuser;
GRANT ALL ON SCHEMA taxonomie TO geonatuser;


--
-- Name: utilisateurs; Type: ACL; Schema: -; Owner: -
--

REVOKE ALL ON SCHEMA utilisateurs FROM PUBLIC;
REVOKE ALL ON SCHEMA utilisateurs FROM geonatuser;
GRANT ALL ON SCHEMA utilisateurs TO geonatuser;


SET search_path = contactfaune, pg_catalog;

--
-- Name: insert_fiche_cf(); Type: ACL; Schema: contactfaune; Owner: -
--

REVOKE ALL ON FUNCTION insert_fiche_cf() FROM PUBLIC;
REVOKE ALL ON FUNCTION insert_fiche_cf() FROM geonatuser;
GRANT ALL ON FUNCTION insert_fiche_cf() TO geonatuser;
GRANT ALL ON FUNCTION insert_fiche_cf() TO PUBLIC;


--
-- Name: insert_releve_cf(); Type: ACL; Schema: contactfaune; Owner: -
--

REVOKE ALL ON FUNCTION insert_releve_cf() FROM PUBLIC;
REVOKE ALL ON FUNCTION insert_releve_cf() FROM geonatuser;
GRANT ALL ON FUNCTION insert_releve_cf() TO geonatuser;
GRANT ALL ON FUNCTION insert_releve_cf() TO postgres;
GRANT ALL ON FUNCTION insert_releve_cf() TO PUBLIC;


--
-- Name: synthese_delete_releve_cf(); Type: ACL; Schema: contactfaune; Owner: -
--

REVOKE ALL ON FUNCTION synthese_delete_releve_cf() FROM PUBLIC;
REVOKE ALL ON FUNCTION synthese_delete_releve_cf() FROM geonatuser;
GRANT ALL ON FUNCTION synthese_delete_releve_cf() TO geonatuser;
GRANT ALL ON FUNCTION synthese_delete_releve_cf() TO PUBLIC;


--
-- Name: synthese_insert_releve_cf(); Type: ACL; Schema: contactfaune; Owner: -
--

REVOKE ALL ON FUNCTION synthese_insert_releve_cf() FROM PUBLIC;
REVOKE ALL ON FUNCTION synthese_insert_releve_cf() FROM geonatuser;
GRANT ALL ON FUNCTION synthese_insert_releve_cf() TO geonatuser;
GRANT ALL ON FUNCTION synthese_insert_releve_cf() TO PUBLIC;


--
-- Name: synthese_update_cor_role_fiche_cf(); Type: ACL; Schema: contactfaune; Owner: -
--

REVOKE ALL ON FUNCTION synthese_update_cor_role_fiche_cf() FROM PUBLIC;
REVOKE ALL ON FUNCTION synthese_update_cor_role_fiche_cf() FROM geonatuser;
GRANT ALL ON FUNCTION synthese_update_cor_role_fiche_cf() TO geonatuser;
GRANT ALL ON FUNCTION synthese_update_cor_role_fiche_cf() TO PUBLIC;


--
-- Name: synthese_update_fiche_cf(); Type: ACL; Schema: contactfaune; Owner: -
--

REVOKE ALL ON FUNCTION synthese_update_fiche_cf() FROM PUBLIC;
REVOKE ALL ON FUNCTION synthese_update_fiche_cf() FROM geonatuser;
GRANT ALL ON FUNCTION synthese_update_fiche_cf() TO geonatuser;
GRANT ALL ON FUNCTION synthese_update_fiche_cf() TO PUBLIC;


--
-- Name: synthese_update_releve_cf(); Type: ACL; Schema: contactfaune; Owner: -
--

REVOKE ALL ON FUNCTION synthese_update_releve_cf() FROM PUBLIC;
REVOKE ALL ON FUNCTION synthese_update_releve_cf() FROM geonatuser;
GRANT ALL ON FUNCTION synthese_update_releve_cf() TO geonatuser;
GRANT ALL ON FUNCTION synthese_update_releve_cf() TO PUBLIC;


--
-- Name: update_fiche_cf(); Type: ACL; Schema: contactfaune; Owner: -
--

REVOKE ALL ON FUNCTION update_fiche_cf() FROM PUBLIC;
REVOKE ALL ON FUNCTION update_fiche_cf() FROM geonatuser;
GRANT ALL ON FUNCTION update_fiche_cf() TO geonatuser;
GRANT ALL ON FUNCTION update_fiche_cf() TO PUBLIC;


--
-- Name: update_releve_cf(); Type: ACL; Schema: contactfaune; Owner: -
--

REVOKE ALL ON FUNCTION update_releve_cf() FROM PUBLIC;
REVOKE ALL ON FUNCTION update_releve_cf() FROM geonatuser;
GRANT ALL ON FUNCTION update_releve_cf() TO geonatuser;
GRANT ALL ON FUNCTION update_releve_cf() TO PUBLIC;


SET search_path = contactinv, pg_catalog;

--
-- Name: insert_fiche_inv(); Type: ACL; Schema: contactinv; Owner: -
--

REVOKE ALL ON FUNCTION insert_fiche_inv() FROM PUBLIC;
REVOKE ALL ON FUNCTION insert_fiche_inv() FROM geonatuser;
GRANT ALL ON FUNCTION insert_fiche_inv() TO geonatuser;
GRANT ALL ON FUNCTION insert_fiche_inv() TO PUBLIC;


--
-- Name: insert_releve_inv(); Type: ACL; Schema: contactinv; Owner: -
--

REVOKE ALL ON FUNCTION insert_releve_inv() FROM PUBLIC;
REVOKE ALL ON FUNCTION insert_releve_inv() FROM geonatuser;
GRANT ALL ON FUNCTION insert_releve_inv() TO geonatuser;
GRANT ALL ON FUNCTION insert_releve_inv() TO PUBLIC;


--
-- Name: synthese_delete_releve_inv(); Type: ACL; Schema: contactinv; Owner: -
--

REVOKE ALL ON FUNCTION synthese_delete_releve_inv() FROM PUBLIC;
REVOKE ALL ON FUNCTION synthese_delete_releve_inv() FROM geonatuser;
GRANT ALL ON FUNCTION synthese_delete_releve_inv() TO geonatuser;
GRANT ALL ON FUNCTION synthese_delete_releve_inv() TO PUBLIC;


--
-- Name: synthese_insert_releve_inv(); Type: ACL; Schema: contactinv; Owner: -
--

REVOKE ALL ON FUNCTION synthese_insert_releve_inv() FROM PUBLIC;
REVOKE ALL ON FUNCTION synthese_insert_releve_inv() FROM geonatuser;
GRANT ALL ON FUNCTION synthese_insert_releve_inv() TO geonatuser;
GRANT ALL ON FUNCTION synthese_insert_releve_inv() TO PUBLIC;


--
-- Name: synthese_update_cor_role_fiche_inv(); Type: ACL; Schema: contactinv; Owner: -
--

REVOKE ALL ON FUNCTION synthese_update_cor_role_fiche_inv() FROM PUBLIC;
REVOKE ALL ON FUNCTION synthese_update_cor_role_fiche_inv() FROM geonatuser;
GRANT ALL ON FUNCTION synthese_update_cor_role_fiche_inv() TO geonatuser;
GRANT ALL ON FUNCTION synthese_update_cor_role_fiche_inv() TO PUBLIC;


--
-- Name: synthese_update_fiche_inv(); Type: ACL; Schema: contactinv; Owner: -
--

REVOKE ALL ON FUNCTION synthese_update_fiche_inv() FROM PUBLIC;
REVOKE ALL ON FUNCTION synthese_update_fiche_inv() FROM geonatuser;
GRANT ALL ON FUNCTION synthese_update_fiche_inv() TO geonatuser;
GRANT ALL ON FUNCTION synthese_update_fiche_inv() TO PUBLIC;


--
-- Name: synthese_update_releve_inv(); Type: ACL; Schema: contactinv; Owner: -
--

REVOKE ALL ON FUNCTION synthese_update_releve_inv() FROM PUBLIC;
REVOKE ALL ON FUNCTION synthese_update_releve_inv() FROM geonatuser;
GRANT ALL ON FUNCTION synthese_update_releve_inv() TO geonatuser;
GRANT ALL ON FUNCTION synthese_update_releve_inv() TO PUBLIC;


--
-- Name: update_fiche_inv(); Type: ACL; Schema: contactinv; Owner: -
--

REVOKE ALL ON FUNCTION update_fiche_inv() FROM PUBLIC;
REVOKE ALL ON FUNCTION update_fiche_inv() FROM geonatuser;
GRANT ALL ON FUNCTION update_fiche_inv() TO geonatuser;
GRANT ALL ON FUNCTION update_fiche_inv() TO PUBLIC;


--
-- Name: update_releve_inv(); Type: ACL; Schema: contactinv; Owner: -
--

REVOKE ALL ON FUNCTION update_releve_inv() FROM PUBLIC;
REVOKE ALL ON FUNCTION update_releve_inv() FROM geonatuser;
GRANT ALL ON FUNCTION update_releve_inv() TO geonatuser;
GRANT ALL ON FUNCTION update_releve_inv() TO PUBLIC;


SET search_path = synthese, pg_catalog;

--
-- Name: insert_syntheseff(); Type: ACL; Schema: synthese; Owner: -
--

REVOKE ALL ON FUNCTION insert_syntheseff() FROM PUBLIC;
REVOKE ALL ON FUNCTION insert_syntheseff() FROM geonatuser;
GRANT ALL ON FUNCTION insert_syntheseff() TO geonatuser;
GRANT ALL ON FUNCTION insert_syntheseff() TO PUBLIC;


--
-- Name: maj_cor_unite_synthese(); Type: ACL; Schema: synthese; Owner: -
--

REVOKE ALL ON FUNCTION maj_cor_unite_synthese() FROM PUBLIC;
REVOKE ALL ON FUNCTION maj_cor_unite_synthese() FROM geonatuser;
GRANT ALL ON FUNCTION maj_cor_unite_synthese() TO geonatuser;
GRANT ALL ON FUNCTION maj_cor_unite_synthese() TO PUBLIC;


--
-- Name: maj_cor_unite_taxon(); Type: ACL; Schema: synthese; Owner: -
--

REVOKE ALL ON FUNCTION maj_cor_unite_taxon() FROM PUBLIC;
REVOKE ALL ON FUNCTION maj_cor_unite_taxon() FROM geonatuser;
GRANT ALL ON FUNCTION maj_cor_unite_taxon() TO geonatuser;
GRANT ALL ON FUNCTION maj_cor_unite_taxon() TO PUBLIC;


--
-- Name: maj_cor_zonesstatut_synthese(); Type: ACL; Schema: synthese; Owner: -
--

REVOKE ALL ON FUNCTION maj_cor_zonesstatut_synthese() FROM PUBLIC;
REVOKE ALL ON FUNCTION maj_cor_zonesstatut_synthese() FROM geonatuser;
GRANT ALL ON FUNCTION maj_cor_zonesstatut_synthese() TO geonatuser;
GRANT ALL ON FUNCTION maj_cor_zonesstatut_synthese() TO PUBLIC;


--
-- Name: update_syntheseff(); Type: ACL; Schema: synthese; Owner: -
--

REVOKE ALL ON FUNCTION update_syntheseff() FROM PUBLIC;
REVOKE ALL ON FUNCTION update_syntheseff() FROM geonatuser;
GRANT ALL ON FUNCTION update_syntheseff() TO geonatuser;
GRANT ALL ON FUNCTION update_syntheseff() TO PUBLIC;


SET search_path = bryophytes, pg_catalog;

--
-- TOC entry 3654 (class 0 OID 0)
-- Dependencies: 1192
-- Name: delete_synthese_cor_bryo_taxon(); Type: ACL; Schema: bryophytes; Owner: -
--

REVOKE ALL ON FUNCTION delete_synthese_cor_bryo_taxon() FROM PUBLIC;
REVOKE ALL ON FUNCTION delete_synthese_cor_bryo_taxon() FROM geonatuser;
GRANT ALL ON FUNCTION delete_synthese_cor_bryo_taxon() TO geonatuser;



--
-- TOC entry 3655 (class 0 OID 0)
-- Dependencies: 1196
-- Name: insert_synthese_cor_bryo_taxon(); Type: ACL; Schema: bryophytes; Owner: -
--

REVOKE ALL ON FUNCTION insert_synthese_cor_bryo_taxon() FROM PUBLIC;
REVOKE ALL ON FUNCTION insert_synthese_cor_bryo_taxon() FROM geonatuser;
GRANT ALL ON FUNCTION insert_synthese_cor_bryo_taxon() TO geonatuser;



--
-- TOC entry 3656 (class 0 OID 0)
-- Dependencies: 1197
-- Name: update_synthese_cor_bryo_observateur(); Type: ACL; Schema: bryophytes; Owner: -
--

REVOKE ALL ON FUNCTION update_synthese_cor_bryo_observateur() FROM PUBLIC;
REVOKE ALL ON FUNCTION update_synthese_cor_bryo_observateur() FROM geonatuser;
GRANT ALL ON FUNCTION update_synthese_cor_bryo_observateur() TO geonatuser;


--
-- TOC entry 3657 (class 0 OID 0)
-- Dependencies: 1142
-- Name: update_synthese_cor_bryo_taxon(); Type: ACL; Schema: bryophytes; Owner: -
--

REVOKE ALL ON FUNCTION update_synthese_cor_bryo_taxon() FROM PUBLIC;
REVOKE ALL ON FUNCTION update_synthese_cor_bryo_taxon() FROM geonatuser;
GRANT ALL ON FUNCTION update_synthese_cor_bryo_taxon() TO geonatuser;


--
-- TOC entry 3658 (class 0 OID 0)
-- Dependencies: 1198
-- Name: update_synthese_stations_bryo(); Type: ACL; Schema: bryophytes; Owner: -
--

REVOKE ALL ON FUNCTION update_synthese_stations_bryo() FROM PUBLIC;
REVOKE ALL ON FUNCTION update_synthese_stations_bryo() FROM geonatuser;
GRANT ALL ON FUNCTION update_synthese_stations_bryo() TO geonatuser;


SET search_path = florepatri, pg_catalog;

--
-- TOC entry 3659 (class 0 OID 0)
-- Dependencies: 1143
-- Name: delete_synthese_ap(); Type: ACL; Schema: florepatri; Owner: -
--

REVOKE ALL ON FUNCTION delete_synthese_ap() FROM PUBLIC;
REVOKE ALL ON FUNCTION delete_synthese_ap() FROM geonatuser;
GRANT ALL ON FUNCTION delete_synthese_ap() TO geonatuser;



--
-- TOC entry 3660 (class 0 OID 0)
-- Dependencies: 1141
-- Name: insert_ap(); Type: ACL; Schema: florepatri; Owner: -
--

REVOKE ALL ON FUNCTION insert_ap() FROM PUBLIC;
REVOKE ALL ON FUNCTION insert_ap() FROM geonatuser;
GRANT ALL ON FUNCTION insert_ap() TO geonatuser;



--
-- TOC entry 3661 (class 0 OID 0)
-- Dependencies: 1199
-- Name: insert_synthese_ap(); Type: ACL; Schema: florepatri; Owner: -
--

REVOKE ALL ON FUNCTION insert_synthese_ap() FROM PUBLIC;
REVOKE ALL ON FUNCTION insert_synthese_ap() FROM geonatuser;
GRANT ALL ON FUNCTION insert_synthese_ap() TO geonatuser;


--
-- TOC entry 3662 (class 0 OID 0)
-- Dependencies: 1201
-- Name: letypedegeom(public.geometry); Type: ACL; Schema: florepatri; Owner: -
--

REVOKE ALL ON FUNCTION letypedegeom(variablegeom public.geometry) FROM PUBLIC;
REVOKE ALL ON FUNCTION letypedegeom(variablegeom public.geometry) FROM geonatuser;
GRANT ALL ON FUNCTION letypedegeom(variablegeom public.geometry) TO geonatuser;
GRANT ALL ON FUNCTION letypedegeom(variablegeom public.geometry) TO postgres;

--
-- TOC entry 3664 (class 0 OID 0)
-- Dependencies: 1202
-- Name: update_ap(); Type: ACL; Schema: florepatri; Owner: -
--

REVOKE ALL ON FUNCTION update_ap() FROM PUBLIC;
REVOKE ALL ON FUNCTION update_ap() FROM geonatuser;
GRANT ALL ON FUNCTION update_ap() TO geonatuser;


--
-- TOC entry 3665 (class 0 OID 0)
-- Dependencies: 1206
-- Name: update_synthese_ap(); Type: ACL; Schema: florepatri; Owner: -
--

REVOKE ALL ON FUNCTION update_synthese_ap() FROM PUBLIC;
REVOKE ALL ON FUNCTION update_synthese_ap() FROM geonatuser;
GRANT ALL ON FUNCTION update_synthese_ap() TO geonatuser;


--
-- TOC entry 3666 (class 0 OID 0)
-- Dependencies: 1146
-- Name: update_synthese_cor_zp_obs(); Type: ACL; Schema: florepatri; Owner: -
--

REVOKE ALL ON FUNCTION update_synthese_cor_zp_obs() FROM PUBLIC;
REVOKE ALL ON FUNCTION update_synthese_cor_zp_obs() FROM geonatuser;
GRANT ALL ON FUNCTION update_synthese_cor_zp_obs() TO geonatuser;


--
-- TOC entry 3667 (class 0 OID 0)
-- Dependencies: 1195
-- Name: update_synthese_zp(); Type: ACL; Schema: florepatri; Owner: -
--

REVOKE ALL ON FUNCTION update_synthese_zp() FROM PUBLIC;
REVOKE ALL ON FUNCTION update_synthese_zp() FROM geonatuser;
GRANT ALL ON FUNCTION update_synthese_zp() TO geonatuser;


--
-- TOC entry 3668 (class 0 OID 0)
-- Dependencies: 1157
-- Name: update_zp(); Type: ACL; Schema: florepatri; Owner: -
--

REVOKE ALL ON FUNCTION update_zp() FROM PUBLIC;
REVOKE ALL ON FUNCTION update_zp() FROM geonatuser;
GRANT ALL ON FUNCTION update_zp() TO geonatuser;


SET search_path = florestation, pg_catalog;

--
-- TOC entry 3669 (class 0 OID 0)
-- Dependencies: 1154
-- Name: delete_synthese_cor_fs_taxon(); Type: ACL; Schema: florestation; Owner: -
--

REVOKE ALL ON FUNCTION delete_synthese_cor_fs_taxon() FROM PUBLIC;
REVOKE ALL ON FUNCTION delete_synthese_cor_fs_taxon() FROM geonatuser;
GRANT ALL ON FUNCTION delete_synthese_cor_fs_taxon() TO geonatuser;


--
-- TOC entry 3670 (class 0 OID 0)
-- Dependencies: 1203
-- Name: etiquette_utm(public.geometry); Type: ACL; Schema: florestation; Owner: -
--

REVOKE ALL ON FUNCTION etiquette_utm(mongeom public.geometry) FROM PUBLIC;
REVOKE ALL ON FUNCTION etiquette_utm(mongeom public.geometry) FROM geonatuser;
GRANT ALL ON FUNCTION etiquette_utm(mongeom public.geometry) TO geonatuser;
GRANT ALL ON FUNCTION etiquette_utm(mongeom public.geometry) TO postgres;


--
-- TOC entry 3671 (class 0 OID 0)
-- Dependencies: 1204
-- Name: insert_synthese_cor_fs_taxon(); Type: ACL; Schema: florestation; Owner: -
--

REVOKE ALL ON FUNCTION insert_synthese_cor_fs_taxon() FROM PUBLIC;
REVOKE ALL ON FUNCTION insert_synthese_cor_fs_taxon() FROM geonatuser;
GRANT ALL ON FUNCTION insert_synthese_cor_fs_taxon() TO geonatuser;


--
-- TOC entry 3672 (class 0 OID 0)
-- Dependencies: 1163
-- Name: update_synthese_cor_fs_observateur(); Type: ACL; Schema: florestation; Owner: -
--

REVOKE ALL ON FUNCTION update_synthese_cor_fs_observateur() FROM PUBLIC;
REVOKE ALL ON FUNCTION update_synthese_cor_fs_observateur() FROM geonatuser;
GRANT ALL ON FUNCTION update_synthese_cor_fs_observateur() TO geonatuser;


--
-- TOC entry 3673 (class 0 OID 0)
-- Dependencies: 1164
-- Name: update_synthese_cor_fs_taxon(); Type: ACL; Schema: florestation; Owner: -
--

REVOKE ALL ON FUNCTION update_synthese_cor_fs_taxon() FROM PUBLIC;
REVOKE ALL ON FUNCTION update_synthese_cor_fs_taxon() FROM geonatuser;
GRANT ALL ON FUNCTION update_synthese_cor_fs_taxon() TO geonatuser;


--
-- TOC entry 3674 (class 0 OID 0)
-- Dependencies: 1205
-- Name: update_synthese_stations_fs(); Type: ACL; Schema: florestation; Owner: -
--

REVOKE ALL ON FUNCTION update_synthese_stations_fs() FROM PUBLIC;
REVOKE ALL ON FUNCTION update_synthese_stations_fs() FROM geonatuser;
GRANT ALL ON FUNCTION update_synthese_stations_fs() TO geonatuser;


SET search_path = utilisateurs, pg_catalog;

--
-- Name: modify_date_insert(); Type: ACL; Schema: utilisateurs; Owner: -
--

REVOKE ALL ON FUNCTION modify_date_insert() FROM PUBLIC;
REVOKE ALL ON FUNCTION modify_date_insert() FROM geonatuser;
GRANT ALL ON FUNCTION modify_date_insert() TO geonatuser;
GRANT ALL ON FUNCTION modify_date_insert() TO PUBLIC;


--
-- Name: modify_date_update(); Type: ACL; Schema: utilisateurs; Owner: -
--

REVOKE ALL ON FUNCTION modify_date_update() FROM PUBLIC;
REVOKE ALL ON FUNCTION modify_date_update() FROM geonatuser;
GRANT ALL ON FUNCTION modify_date_update() TO geonatuser;
GRANT ALL ON FUNCTION modify_date_update() TO PUBLIC;


SET search_path = contactfaune, pg_catalog;

--
-- Name: bib_criteres_cf; Type: ACL; Schema: contactfaune; Owner: -
--

REVOKE ALL ON TABLE bib_criteres_cf FROM PUBLIC;
REVOKE ALL ON TABLE bib_criteres_cf FROM geonatuser;
GRANT ALL ON TABLE bib_criteres_cf TO geonatuser;


--
-- Name: bib_messages_cf; Type: ACL; Schema: contactfaune; Owner: -
--

REVOKE ALL ON TABLE bib_messages_cf FROM PUBLIC;
REVOKE ALL ON TABLE bib_messages_cf FROM geonatuser;
GRANT ALL ON TABLE bib_messages_cf TO geonatuser;


--
-- Name: cor_critere_groupe; Type: ACL; Schema: contactfaune; Owner: -
--

REVOKE ALL ON TABLE cor_critere_groupe FROM PUBLIC;
REVOKE ALL ON TABLE cor_critere_groupe FROM geonatuser;
GRANT ALL ON TABLE cor_critere_groupe TO geonatuser;


--
-- Name: cor_message_taxon; Type: ACL; Schema: contactfaune; Owner: -
--

REVOKE ALL ON TABLE cor_message_taxon FROM PUBLIC;
REVOKE ALL ON TABLE cor_message_taxon FROM geonatuser;
GRANT ALL ON TABLE cor_message_taxon TO geonatuser;


--
-- Name: cor_role_fiche_cf; Type: ACL; Schema: contactfaune; Owner: -
--

REVOKE ALL ON TABLE cor_role_fiche_cf FROM PUBLIC;
REVOKE ALL ON TABLE cor_role_fiche_cf FROM geonatuser;
GRANT ALL ON TABLE cor_role_fiche_cf TO geonatuser;


--
-- Name: cor_unite_taxon; Type: ACL; Schema: contactfaune; Owner: -
--

REVOKE ALL ON TABLE cor_unite_taxon FROM PUBLIC;
REVOKE ALL ON TABLE cor_unite_taxon FROM geonatuser;
GRANT ALL ON TABLE cor_unite_taxon TO geonatuser;


--
-- Name: log_colors; Type: ACL; Schema: contactfaune; Owner: -
--

REVOKE ALL ON TABLE log_colors FROM PUBLIC;
REVOKE ALL ON TABLE log_colors FROM geonatuser;
GRANT ALL ON TABLE log_colors TO geonatuser;


--
-- Name: log_colors_day; Type: ACL; Schema: contactfaune; Owner: -
--

REVOKE ALL ON TABLE log_colors_day FROM PUBLIC;
REVOKE ALL ON TABLE log_colors_day FROM geonatuser;
GRANT ALL ON TABLE log_colors_day TO geonatuser;


--
-- Name: t_fiches_cf; Type: ACL; Schema: contactfaune; Owner: -
--

REVOKE ALL ON TABLE t_fiches_cf FROM PUBLIC;
REVOKE ALL ON TABLE t_fiches_cf FROM geonatuser;
GRANT ALL ON TABLE t_fiches_cf TO geonatuser;


--
-- Name: t_releves_cf; Type: ACL; Schema: contactfaune; Owner: -
--

REVOKE ALL ON TABLE t_releves_cf FROM PUBLIC;
REVOKE ALL ON TABLE t_releves_cf FROM geonatuser;
GRANT ALL ON TABLE t_releves_cf TO geonatuser;



SET search_path = florepatri, pg_catalog;

--
-- TOC entry 3677 (class 0 OID 0)
-- Dependencies: 187
-- Name: bib_comptages_methodo; Type: ACL; Schema: florepatri; Owner: -
--

REVOKE ALL ON TABLE bib_comptages_methodo FROM PUBLIC;
REVOKE ALL ON TABLE bib_comptages_methodo FROM geonatuser;
GRANT ALL ON TABLE bib_comptages_methodo TO geonatuser;


--
-- TOC entry 3678 (class 0 OID 0)
-- Dependencies: 188
-- Name: bib_frequences_methodo_new; Type: ACL; Schema: florepatri; Owner: -
--

REVOKE ALL ON TABLE bib_frequences_methodo_new FROM PUBLIC;
REVOKE ALL ON TABLE bib_frequences_methodo_new FROM geonatuser;
GRANT ALL ON TABLE bib_frequences_methodo_new TO geonatuser;


--
-- TOC entry 3679 (class 0 OID 0)
-- Dependencies: 190
-- Name: bib_perturbations; Type: ACL; Schema: florepatri; Owner: -
--

REVOKE ALL ON TABLE bib_perturbations FROM PUBLIC;
REVOKE ALL ON TABLE bib_perturbations FROM geonatuser;
GRANT ALL ON TABLE bib_perturbations TO geonatuser;
GRANT ALL ON TABLE bib_perturbations TO postgres;


--
-- TOC entry 3680 (class 0 OID 0)
-- Dependencies: 191
-- Name: bib_phenologies; Type: ACL; Schema: florepatri; Owner: -
--

REVOKE ALL ON TABLE bib_phenologies FROM PUBLIC;
REVOKE ALL ON TABLE bib_phenologies FROM geonatuser;
GRANT ALL ON TABLE bib_phenologies TO geonatuser;
GRANT ALL ON TABLE bib_phenologies TO postgres;


--
-- TOC entry 3681 (class 0 OID 0)
-- Dependencies: 192
-- Name: bib_physionomies; Type: ACL; Schema: florepatri; Owner: -
--

REVOKE ALL ON TABLE bib_physionomies FROM PUBLIC;
REVOKE ALL ON TABLE bib_physionomies FROM geonatuser;
GRANT ALL ON TABLE bib_physionomies TO geonatuser;
GRANT ALL ON TABLE bib_physionomies TO postgres;


--
-- TOC entry 3682 (class 0 OID 0)
-- Dependencies: 193
-- Name: bib_rezo_ecrins; Type: ACL; Schema: florepatri; Owner: -
--

REVOKE ALL ON TABLE bib_rezo_ecrins FROM PUBLIC;
REVOKE ALL ON TABLE bib_rezo_ecrins FROM geonatuser;
GRANT ALL ON TABLE bib_rezo_ecrins TO geonatuser;
GRANT ALL ON TABLE bib_rezo_ecrins TO postgres;


--
-- TOC entry 3683 (class 0 OID 0)
-- Dependencies: 194
-- Name: bib_statuts; Type: ACL; Schema: florepatri; Owner: -
--

REVOKE ALL ON TABLE bib_statuts FROM PUBLIC;
REVOKE ALL ON TABLE bib_statuts FROM geonatuser;
GRANT ALL ON TABLE bib_statuts TO geonatuser;
GRANT ALL ON TABLE bib_statuts TO postgres;


--
-- TOC entry 3684 (class 0 OID 0)
-- Dependencies: 195
-- Name: bib_taxons_fp; Type: ACL; Schema: florepatri; Owner: -
--

REVOKE ALL ON TABLE bib_taxons_fp FROM PUBLIC;
REVOKE ALL ON TABLE bib_taxons_fp FROM geonatuser;
GRANT ALL ON TABLE bib_taxons_fp TO geonatuser;
GRANT ALL ON TABLE bib_taxons_fp TO postgres;


--
-- TOC entry 3685 (class 0 OID 0)
-- Dependencies: 196
-- Name: cor_ap_perturb; Type: ACL; Schema: florepatri; Owner: -
--

REVOKE ALL ON TABLE cor_ap_perturb FROM PUBLIC;
REVOKE ALL ON TABLE cor_ap_perturb FROM geonatuser;
GRANT ALL ON TABLE cor_ap_perturb TO geonatuser;
GRANT ALL ON TABLE cor_ap_perturb TO postgres;


--
-- TOC entry 3686 (class 0 OID 0)
-- Dependencies: 197
-- Name: cor_ap_physionomie; Type: ACL; Schema: florepatri; Owner: -
--

REVOKE ALL ON TABLE cor_ap_physionomie FROM PUBLIC;
REVOKE ALL ON TABLE cor_ap_physionomie FROM geonatuser;
GRANT ALL ON TABLE cor_ap_physionomie TO geonatuser;
GRANT ALL ON TABLE cor_ap_physionomie TO postgres;


--
-- TOC entry 3687 (class 0 OID 0)
-- Dependencies: 198
-- Name: cor_taxon_statut; Type: ACL; Schema: florepatri; Owner: -
--

REVOKE ALL ON TABLE cor_taxon_statut FROM PUBLIC;
REVOKE ALL ON TABLE cor_taxon_statut FROM geonatuser;
GRANT ALL ON TABLE cor_taxon_statut TO geonatuser;
GRANT ALL ON TABLE cor_taxon_statut TO postgres;


--
-- TOC entry 3688 (class 0 OID 0)
-- Dependencies: 304
-- Name: v_ap_line; Type: ACL; Schema: florepatri; Owner: -
--

REVOKE ALL ON TABLE v_ap_line FROM PUBLIC;
REVOKE ALL ON TABLE v_ap_line FROM geonatuser;
GRANT ALL ON TABLE v_ap_line TO geonatuser;
GRANT ALL ON TABLE v_ap_line TO postgres;


--
-- TOC entry 3689 (class 0 OID 0)
-- Dependencies: 303
-- Name: v_ap_point; Type: ACL; Schema: florepatri; Owner: -
--

REVOKE ALL ON TABLE v_ap_point FROM PUBLIC;
REVOKE ALL ON TABLE v_ap_point FROM geonatuser;
GRANT ALL ON TABLE v_ap_point TO geonatuser;
GRANT ALL ON TABLE v_ap_point TO postgres;


--
-- TOC entry 3690 (class 0 OID 0)
-- Dependencies: 302
-- Name: v_ap_poly; Type: ACL; Schema: florepatri; Owner: -
--

REVOKE ALL ON TABLE v_ap_poly FROM PUBLIC;
REVOKE ALL ON TABLE v_ap_poly FROM geonatuser;
GRANT ALL ON TABLE v_ap_poly TO geonatuser;
GRANT ALL ON TABLE v_ap_poly TO postgres;


--
-- TOC entry 3691 (class 0 OID 0)
-- Dependencies: 322
-- Name: v_mobile_observateurs_fp; Type: ACL; Schema: florepatri; Owner: -
--

REVOKE ALL ON TABLE v_mobile_observateurs_fp FROM PUBLIC;
REVOKE ALL ON TABLE v_mobile_observateurs_fp FROM geonatuser;
GRANT ALL ON TABLE v_mobile_observateurs_fp TO geonatuser;
GRANT ALL ON TABLE v_mobile_observateurs_fp TO postgres;


--
-- TOC entry 3692 (class 0 OID 0)
-- Dependencies: 324
-- Name: v_mobile_pentes; Type: ACL; Schema: florepatri; Owner: -
--

REVOKE ALL ON TABLE v_mobile_pentes FROM PUBLIC;
REVOKE ALL ON TABLE v_mobile_pentes FROM geonatuser;
GRANT ALL ON TABLE v_mobile_pentes TO geonatuser;
GRANT ALL ON TABLE v_mobile_pentes TO postgres;


--
-- TOC entry 3693 (class 0 OID 0)
-- Dependencies: 325
-- Name: v_mobile_perturbations; Type: ACL; Schema: florepatri; Owner: -
--

REVOKE ALL ON TABLE v_mobile_perturbations FROM PUBLIC;
REVOKE ALL ON TABLE v_mobile_perturbations FROM geonatuser;
GRANT ALL ON TABLE v_mobile_perturbations TO geonatuser;
GRANT ALL ON TABLE v_mobile_perturbations TO postgres;


--
-- TOC entry 3694 (class 0 OID 0)
-- Dependencies: 327
-- Name: v_mobile_phenologies; Type: ACL; Schema: florepatri; Owner: -
--

REVOKE ALL ON TABLE v_mobile_phenologies FROM PUBLIC;
REVOKE ALL ON TABLE v_mobile_phenologies FROM geonatuser;
GRANT ALL ON TABLE v_mobile_phenologies TO geonatuser;
GRANT ALL ON TABLE v_mobile_phenologies TO postgres;


--
-- TOC entry 3695 (class 0 OID 0)
-- Dependencies: 326
-- Name: v_mobile_physionomies; Type: ACL; Schema: florepatri; Owner: -
--

REVOKE ALL ON TABLE v_mobile_physionomies FROM PUBLIC;
REVOKE ALL ON TABLE v_mobile_physionomies FROM geonatuser;
GRANT ALL ON TABLE v_mobile_physionomies TO geonatuser;
GRANT ALL ON TABLE v_mobile_physionomies TO postgres;


--
-- TOC entry 3696 (class 0 OID 0)
-- Dependencies: 323
-- Name: v_mobile_taxons_fp; Type: ACL; Schema: florepatri; Owner: -
--

REVOKE ALL ON TABLE v_mobile_taxons_fp FROM PUBLIC;
REVOKE ALL ON TABLE v_mobile_taxons_fp FROM geonatuser;
GRANT ALL ON TABLE v_mobile_taxons_fp TO geonatuser;
GRANT ALL ON TABLE v_mobile_taxons_fp TO postgres;


--
-- TOC entry 3697 (class 0 OID 0)
-- Dependencies: 202
-- Name: v_mobile_visu_zp; Type: ACL; Schema: florepatri; Owner: -
--

REVOKE ALL ON TABLE v_mobile_visu_zp FROM PUBLIC;
REVOKE ALL ON TABLE v_mobile_visu_zp FROM geonatuser;
GRANT ALL ON TABLE v_mobile_visu_zp TO geonatuser;
GRANT ALL ON TABLE v_mobile_visu_zp TO postgres;


--
-- TOC entry 3698 (class 0 OID 0)
-- Dependencies: 203
-- Name: v_nomade_taxon; Type: ACL; Schema: florepatri; Owner: -
--

REVOKE ALL ON TABLE v_nomade_taxon FROM PUBLIC;
REVOKE ALL ON TABLE v_nomade_taxon FROM geonatuser;
GRANT ALL ON TABLE v_nomade_taxon TO geonatuser;
GRANT ALL ON TABLE v_nomade_taxon TO postgres;


--
-- TOC entry 3699 (class 0 OID 0)
-- Dependencies: 204
-- Name: v_nomade_zp; Type: ACL; Schema: florepatri; Owner: -
--

REVOKE ALL ON TABLE v_nomade_zp FROM PUBLIC;
REVOKE ALL ON TABLE v_nomade_zp FROM geonatuser;
GRANT ALL ON TABLE v_nomade_zp TO geonatuser;
GRANT ALL ON TABLE v_nomade_zp TO postgres;


--
-- TOC entry 3700 (class 0 OID 0)
-- Dependencies: 205
-- Name: v_nomade_ap; Type: ACL; Schema: florepatri; Owner: -
--

REVOKE ALL ON TABLE v_nomade_ap FROM PUBLIC;
REVOKE ALL ON TABLE v_nomade_ap FROM geonatuser;
GRANT ALL ON TABLE v_nomade_ap TO geonatuser;
GRANT ALL ON TABLE v_nomade_ap TO postgres;


--
-- TOC entry 3701 (class 0 OID 0)
-- Dependencies: 337
-- Name: v_touteslesap_2154_line; Type: ACL; Schema: florepatri; Owner: -
--

REVOKE ALL ON TABLE v_touteslesap_2154_line FROM PUBLIC;
REVOKE ALL ON TABLE v_touteslesap_2154_line FROM geonatuser;
GRANT ALL ON TABLE v_touteslesap_2154_line TO geonatuser;
GRANT ALL ON TABLE v_touteslesap_2154_line TO postgres;


--
-- TOC entry 3702 (class 0 OID 0)
-- Dependencies: 336
-- Name: v_touteslesap_2154_point; Type: ACL; Schema: florepatri; Owner: -
--

REVOKE ALL ON TABLE v_touteslesap_2154_point FROM PUBLIC;
REVOKE ALL ON TABLE v_touteslesap_2154_point FROM geonatuser;
GRANT ALL ON TABLE v_touteslesap_2154_point TO geonatuser;
GRANT ALL ON TABLE v_touteslesap_2154_point TO postgres;


--
-- TOC entry 3703 (class 0 OID 0)
-- Dependencies: 338
-- Name: v_touteslesap_2154_polygon; Type: ACL; Schema: florepatri; Owner: -
--

REVOKE ALL ON TABLE v_touteslesap_2154_polygon FROM PUBLIC;
REVOKE ALL ON TABLE v_touteslesap_2154_polygon FROM geonatuser;
GRANT ALL ON TABLE v_touteslesap_2154_polygon TO geonatuser;
GRANT ALL ON TABLE v_touteslesap_2154_polygon TO postgres;


--
-- TOC entry 3704 (class 0 OID 0)
-- Dependencies: 339
-- Name: v_toutesleszp_2154; Type: ACL; Schema: florepatri; Owner: -
--

REVOKE ALL ON TABLE v_toutesleszp_2154 FROM PUBLIC;
REVOKE ALL ON TABLE v_toutesleszp_2154 FROM geonatuser;
GRANT ALL ON TABLE v_toutesleszp_2154 TO geonatuser;
GRANT ALL ON TABLE v_toutesleszp_2154 TO postgres;


SET search_path = florestation, pg_catalog;

--
-- TOC entry 3708 (class 0 OID 0)
-- Dependencies: 229
-- Name: v_florestation_all; Type: ACL; Schema: florestation; Owner: -
--

REVOKE ALL ON TABLE v_florestation_all FROM PUBLIC;
REVOKE ALL ON TABLE v_florestation_all FROM geonatuser;
GRANT ALL ON TABLE v_florestation_all TO geonatuser;
GRANT ALL ON TABLE v_florestation_all TO postgres;


--
-- TOC entry 3709 (class 0 OID 0)
-- Dependencies: 230
-- Name: v_florestation_patrimoniale; Type: ACL; Schema: florestation; Owner: -
--

REVOKE ALL ON TABLE v_florestation_patrimoniale FROM PUBLIC;
REVOKE ALL ON TABLE v_florestation_patrimoniale FROM geonatuser;
GRANT ALL ON TABLE v_florestation_patrimoniale TO geonatuser;
GRANT ALL ON TABLE v_florestation_patrimoniale TO postgres;


--
-- TOC entry 3710 (class 0 OID 0)
-- Dependencies: 231
-- Name: v_taxons_fs; Type: ACL; Schema: florestation; Owner: -
--

REVOKE ALL ON TABLE v_taxons_fs FROM PUBLIC;
REVOKE ALL ON TABLE v_taxons_fs FROM geonatuser;
GRANT ALL ON TABLE v_taxons_fs TO geonatuser;
GRANT ALL ON TABLE v_taxons_fs TO postgres;


SET search_path = taxonomie, pg_catalog;

--
-- Name: bib_groupes; Type: ACL; Schema: taxonomie; Owner: -
--

REVOKE ALL ON TABLE bib_groupes FROM PUBLIC;
REVOKE ALL ON TABLE bib_groupes FROM geonatuser;
GRANT ALL ON TABLE bib_groupes TO geonatuser;


SET search_path = contactfaune, pg_catalog;

--
-- Name: v_nomade_classes; Type: ACL; Schema: contactfaune; Owner: -
--

REVOKE ALL ON TABLE v_nomade_classes FROM PUBLIC;
REVOKE ALL ON TABLE v_nomade_classes FROM geonatuser;
GRANT ALL ON TABLE v_nomade_classes TO geonatuser;


--
-- Name: v_nomade_criteres_cf; Type: ACL; Schema: contactfaune; Owner: -
--

REVOKE ALL ON TABLE v_nomade_criteres_cf FROM PUBLIC;
REVOKE ALL ON TABLE v_nomade_criteres_cf FROM geonatuser;
GRANT ALL ON TABLE v_nomade_criteres_cf TO geonatuser;


SET search_path = utilisateurs, pg_catalog;

--
-- Name: cor_role_menu; Type: ACL; Schema: utilisateurs; Owner: -
--

REVOKE ALL ON TABLE cor_role_menu FROM PUBLIC;
REVOKE ALL ON TABLE cor_role_menu FROM geonatuser;
GRANT ALL ON TABLE cor_role_menu TO geonatuser;


--
-- Name: cor_roles; Type: ACL; Schema: utilisateurs; Owner: -
--

REVOKE ALL ON TABLE cor_roles FROM PUBLIC;
REVOKE ALL ON TABLE cor_roles FROM geonatuser;
GRANT ALL ON TABLE cor_roles TO geonatuser;


--
-- Name: t_roles_id_seq; Type: ACL; Schema: utilisateurs; Owner: -
--

REVOKE ALL ON SEQUENCE t_roles_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE t_roles_id_seq FROM geonatuser;
GRANT ALL ON SEQUENCE t_roles_id_seq TO geonatuser;
GRANT ALL ON SEQUENCE t_roles_id_seq TO postgres;


--
-- Name: t_roles; Type: ACL; Schema: utilisateurs; Owner: -
--

REVOKE ALL ON TABLE t_roles FROM PUBLIC;
REVOKE ALL ON TABLE t_roles FROM geonatuser;
GRANT ALL ON TABLE t_roles TO geonatuser;


SET search_path = contactfaune, pg_catalog;

--
-- Name: v_nomade_observateurs_faune; Type: ACL; Schema: contactfaune; Owner: -
--

REVOKE ALL ON TABLE v_nomade_observateurs_faune FROM PUBLIC;
REVOKE ALL ON TABLE v_nomade_observateurs_faune FROM geonatuser;
GRANT ALL ON TABLE v_nomade_observateurs_faune TO geonatuser;


SET search_path = taxonomie, pg_catalog;

--
-- Name: bib_groupes; Type: ACL; Schema: taxonomie; Owner: -
--

REVOKE ALL ON TABLE bib_groupes FROM PUBLIC;
REVOKE ALL ON TABLE bib_groupes FROM geonatuser;
GRANT ALL ON TABLE bib_groupes TO geonatuser;


--
-- Name: bib_taxons; Type: ACL; Schema: taxonomie; Owner: -
--

REVOKE ALL ON TABLE bib_taxons FROM PUBLIC;
REVOKE ALL ON TABLE bib_taxons FROM geonatuser;
GRANT ALL ON TABLE bib_taxons TO geonatuser;


--
-- Name: taxref; Type: ACL; Schema: taxonomie; Owner: -
--

REVOKE ALL ON TABLE taxref FROM PUBLIC;
REVOKE ALL ON TABLE taxref FROM geonatuser;
GRANT ALL ON TABLE taxref TO geonatuser;


SET search_path = contactfaune, pg_catalog;

--
-- Name: v_nomade_taxons_faune; Type: ACL; Schema: contactfaune; Owner: -
--

REVOKE ALL ON TABLE v_nomade_taxons_faune FROM PUBLIC;
REVOKE ALL ON TABLE v_nomade_taxons_faune FROM geonatuser;
GRANT ALL ON TABLE v_nomade_taxons_faune TO geonatuser;
GRANT ALL ON TABLE v_nomade_taxons_faune TO postgres;


SET search_path = layers, pg_catalog;

--
-- Name: l_unites_geo; Type: ACL; Schema: layers; Owner: -
--

REVOKE ALL ON TABLE l_unites_geo FROM PUBLIC;
REVOKE ALL ON TABLE l_unites_geo FROM geonatuser;
GRANT ALL ON TABLE l_unites_geo TO geonatuser;
GRANT ALL ON TABLE l_unites_geo TO postgres;


SET search_path = contactfaune, pg_catalog;

--
-- Name: v_nomade_unites_geo_cf; Type: ACL; Schema: contactfaune; Owner: -
--

REVOKE ALL ON TABLE v_nomade_unites_geo_cf FROM PUBLIC;
REVOKE ALL ON TABLE v_nomade_unites_geo_cf FROM geonatuser;
GRANT ALL ON TABLE v_nomade_unites_geo_cf TO geonatuser;
GRANT ALL ON TABLE v_nomade_unites_geo_cf TO postgres;


SET search_path = contactinv, pg_catalog;

--
-- Name: bib_criteres_inv; Type: ACL; Schema: contactinv; Owner: -
--

REVOKE ALL ON TABLE bib_criteres_inv FROM PUBLIC;
REVOKE ALL ON TABLE bib_criteres_inv FROM geonatuser;
GRANT ALL ON TABLE bib_criteres_inv TO geonatuser;


--
-- Name: bib_messages_inv; Type: ACL; Schema: contactinv; Owner: -
--

REVOKE ALL ON TABLE bib_messages_inv FROM PUBLIC;
REVOKE ALL ON TABLE bib_messages_inv FROM geonatuser;
GRANT ALL ON TABLE bib_messages_inv TO geonatuser;


--
-- Name: bib_milieux_inv; Type: ACL; Schema: contactinv; Owner: -
--

REVOKE ALL ON TABLE bib_milieux_inv FROM PUBLIC;
REVOKE ALL ON TABLE bib_milieux_inv FROM geonatuser;
GRANT ALL ON TABLE bib_milieux_inv TO geonatuser;


--
-- Name: cor_message_taxon; Type: ACL; Schema: contactinv; Owner: -
--

REVOKE ALL ON TABLE cor_message_taxon FROM PUBLIC;
REVOKE ALL ON TABLE cor_message_taxon FROM geonatuser;
GRANT ALL ON TABLE cor_message_taxon TO geonatuser;


--
-- Name: cor_role_fiche_inv; Type: ACL; Schema: contactinv; Owner: -
--

REVOKE ALL ON TABLE cor_role_fiche_inv FROM PUBLIC;
REVOKE ALL ON TABLE cor_role_fiche_inv FROM geonatuser;
GRANT ALL ON TABLE cor_role_fiche_inv TO geonatuser;


--
-- Name: cor_unite_taxon_inv; Type: ACL; Schema: contactinv; Owner: -
--

REVOKE ALL ON TABLE cor_unite_taxon_inv FROM PUBLIC;
REVOKE ALL ON TABLE cor_unite_taxon_inv FROM geonatuser;
GRANT ALL ON TABLE cor_unite_taxon_inv TO geonatuser;


--
-- Name: log_colors; Type: ACL; Schema: contactinv; Owner: -
--

REVOKE ALL ON TABLE log_colors FROM PUBLIC;
REVOKE ALL ON TABLE log_colors FROM geonatuser;
GRANT ALL ON TABLE log_colors TO geonatuser;


--
-- Name: log_colors_day; Type: ACL; Schema: contactinv; Owner: -
--

REVOKE ALL ON TABLE log_colors_day FROM PUBLIC;
REVOKE ALL ON TABLE log_colors_day FROM geonatuser;
GRANT ALL ON TABLE log_colors_day TO geonatuser;


--
-- Name: t_fiches_inv; Type: ACL; Schema: contactinv; Owner: -
--

REVOKE ALL ON TABLE t_fiches_inv FROM PUBLIC;
REVOKE ALL ON TABLE t_fiches_inv FROM geonatuser;
GRANT ALL ON TABLE t_fiches_inv TO geonatuser;


--
-- Name: t_releves_inv; Type: ACL; Schema: contactinv; Owner: -
--

REVOKE ALL ON TABLE t_releves_inv FROM PUBLIC;
REVOKE ALL ON TABLE t_releves_inv FROM geonatuser;
GRANT ALL ON TABLE t_releves_inv TO geonatuser;


--
-- Name: v_nomade_classes; Type: ACL; Schema: contactinv; Owner: -
--

REVOKE ALL ON TABLE v_nomade_classes FROM PUBLIC;
REVOKE ALL ON TABLE v_nomade_classes FROM geonatuser;
GRANT ALL ON TABLE v_nomade_classes TO geonatuser;


--
-- Name: v_nomade_criteres_inv; Type: ACL; Schema: contactinv; Owner: -
--

REVOKE ALL ON TABLE v_nomade_criteres_inv FROM PUBLIC;
REVOKE ALL ON TABLE v_nomade_criteres_inv FROM geonatuser;
GRANT ALL ON TABLE v_nomade_criteres_inv TO geonatuser;


--
-- Name: v_nomade_milieux_inv; Type: ACL; Schema: contactinv; Owner: -
--

REVOKE ALL ON TABLE v_nomade_milieux_inv FROM PUBLIC;
REVOKE ALL ON TABLE v_nomade_milieux_inv FROM geonatuser;
GRANT ALL ON TABLE v_nomade_milieux_inv TO geonatuser;


--
-- Name: v_nomade_observateurs_inv; Type: ACL; Schema: contactinv; Owner: -
--

REVOKE ALL ON TABLE v_nomade_observateurs_inv FROM PUBLIC;
REVOKE ALL ON TABLE v_nomade_observateurs_inv FROM geonatuser;
GRANT ALL ON TABLE v_nomade_observateurs_inv TO geonatuser;


--
-- Name: v_nomade_taxons_inv; Type: ACL; Schema: contactinv; Owner: -
--

REVOKE ALL ON TABLE v_nomade_taxons_inv FROM PUBLIC;
REVOKE ALL ON TABLE v_nomade_taxons_inv FROM geonatuser;
GRANT ALL ON TABLE v_nomade_taxons_inv TO geonatuser;
GRANT ALL ON TABLE v_nomade_taxons_inv TO postgres;


--
-- Name: v_nomade_unites_geo_inv; Type: ACL; Schema: contactinv; Owner: -
--

REVOKE ALL ON TABLE v_nomade_unites_geo_inv FROM PUBLIC;
REVOKE ALL ON TABLE v_nomade_unites_geo_inv FROM geonatuser;
GRANT ALL ON TABLE v_nomade_unites_geo_inv TO geonatuser;
GRANT ALL ON TABLE v_nomade_unites_geo_inv TO postgres;


SET search_path = layers, pg_catalog;

--
-- Name: bib_typeszones; Type: ACL; Schema: layers; Owner: -
--

REVOKE ALL ON TABLE bib_typeszones FROM PUBLIC;
REVOKE ALL ON TABLE bib_typeszones FROM geonatuser;
GRANT ALL ON TABLE bib_typeszones TO geonatuser;
GRANT ALL ON TABLE bib_typeszones TO postgres;


--
-- Name: l_aireadhesion; Type: ACL; Schema: layers; Owner: -
--

REVOKE ALL ON TABLE l_aireadhesion FROM PUBLIC;
REVOKE ALL ON TABLE l_aireadhesion FROM geonatuser;
GRANT ALL ON TABLE l_aireadhesion TO geonatuser;
GRANT ALL ON TABLE l_aireadhesion TO postgres;


--
-- Name: l_communes; Type: ACL; Schema: layers; Owner: -
--

REVOKE ALL ON TABLE l_communes FROM PUBLIC;
REVOKE ALL ON TABLE l_communes FROM geonatuser;
GRANT ALL ON TABLE l_communes TO geonatuser;
GRANT ALL ON TABLE l_communes TO postgres;


--
-- Name: l_isolines20; Type: ACL; Schema: layers; Owner: -
--

REVOKE ALL ON TABLE l_isolines20 FROM PUBLIC;
REVOKE ALL ON TABLE l_isolines20 FROM geonatuser;
GRANT ALL ON TABLE l_isolines20 TO geonatuser;


--
-- Name: l_secteurs; Type: ACL; Schema: layers; Owner: -
--

REVOKE ALL ON TABLE l_secteurs FROM PUBLIC;
REVOKE ALL ON TABLE l_secteurs FROM geonatuser;
GRANT ALL ON TABLE l_secteurs TO geonatuser;
GRANT ALL ON TABLE l_secteurs TO postgres;


--
-- Name: l_zonesstatut; Type: ACL; Schema: layers; Owner: -
--

REVOKE ALL ON TABLE l_zonesstatut FROM PUBLIC;
REVOKE ALL ON TABLE l_zonesstatut FROM geonatuser;
GRANT ALL ON TABLE l_zonesstatut TO geonatuser;
GRANT ALL ON TABLE l_zonesstatut TO postgres;


SET search_path = meta, pg_catalog;

--
-- Name: bib_lots; Type: ACL; Schema: meta; Owner: -
--

REVOKE ALL ON TABLE bib_lots FROM PUBLIC;
REVOKE ALL ON TABLE bib_lots FROM geonatuser;
GRANT ALL ON TABLE bib_lots TO geonatuser;


--
-- Name: bib_programmes; Type: ACL; Schema: meta; Owner: -
--

REVOKE ALL ON TABLE bib_programmes FROM PUBLIC;
REVOKE ALL ON TABLE bib_programmes FROM geonatuser;
GRANT ALL ON TABLE bib_programmes TO geonatuser;


--
-- Name: bib_supports; Type: ACL; Schema: meta; Owner: -
--

REVOKE ALL ON TABLE bib_supports FROM PUBLIC;
REVOKE ALL ON TABLE bib_supports FROM geonatuser;
GRANT ALL ON TABLE bib_supports TO geonatuser;


--
-- Name: t_precisions; Type: ACL; Schema: meta; Owner: -
--

REVOKE ALL ON TABLE t_precisions FROM PUBLIC;
REVOKE ALL ON TABLE t_precisions FROM geonatuser;
GRANT ALL ON TABLE t_precisions TO geonatuser;


--
-- Name: t_protocoles; Type: ACL; Schema: meta; Owner: -
--

REVOKE ALL ON TABLE t_protocoles FROM PUBLIC;
REVOKE ALL ON TABLE t_protocoles FROM geonatuser;
GRANT ALL ON TABLE t_protocoles TO geonatuser;


SET search_path = synthese, pg_catalog;

--
-- Name: bib_criteres_synthese; Type: ACL; Schema: synthese; Owner: -
--

REVOKE ALL ON TABLE bib_criteres_synthese FROM PUBLIC;
REVOKE ALL ON TABLE bib_criteres_synthese FROM geonatuser;
GRANT ALL ON TABLE bib_criteres_synthese TO geonatuser;


--
-- Name: syntheseff; Type: ACL; Schema: synthese; Owner: -
--

REVOKE ALL ON TABLE syntheseff FROM PUBLIC;
REVOKE ALL ON TABLE syntheseff FROM geonatuser;
GRANT ALL ON TABLE syntheseff TO geonatuser;


SET search_path = utilisateurs, pg_catalog;

--
-- Name: bib_organismes_id_seq; Type: ACL; Schema: utilisateurs; Owner: -
--

REVOKE ALL ON SEQUENCE bib_organismes_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE bib_organismes_id_seq FROM geonatuser;
GRANT ALL ON SEQUENCE bib_organismes_id_seq TO geonatuser;
GRANT ALL ON SEQUENCE bib_organismes_id_seq TO postgres;


--
-- Name: bib_organismes; Type: ACL; Schema: utilisateurs; Owner: -
--

REVOKE ALL ON TABLE bib_organismes FROM PUBLIC;
REVOKE ALL ON TABLE bib_organismes FROM geonatuser;
GRANT ALL ON TABLE bib_organismes TO geonatuser;


SET search_path = synchronomade, pg_catalog;

--
-- Name: erreurs_cf; Type: ACL; Schema: synchronomade; Owner: -
--

REVOKE ALL ON TABLE erreurs_cf FROM PUBLIC;
REVOKE ALL ON TABLE erreurs_cf FROM geonatuser;
GRANT ALL ON TABLE erreurs_cf TO geonatuser;


--
-- Name: erreurs_inv; Type: ACL; Schema: synchronomade; Owner: -
--

REVOKE ALL ON TABLE erreurs_inv FROM PUBLIC;
REVOKE ALL ON TABLE erreurs_inv FROM geonatuser;
GRANT ALL ON TABLE erreurs_inv TO geonatuser;


--
-- Name: erreurs_mortalite; Type: ACL; Schema: synchronomade; Owner: -
--

REVOKE ALL ON TABLE erreurs_mortalite FROM PUBLIC;
REVOKE ALL ON TABLE erreurs_mortalite FROM geonatuser;
GRANT ALL ON TABLE erreurs_mortalite TO geonatuser;


SET search_path = synthese, pg_catalog;

--
-- Name: bib_sources; Type: ACL; Schema: synthese; Owner: -
--

REVOKE ALL ON TABLE bib_sources FROM PUBLIC;
REVOKE ALL ON TABLE bib_sources FROM geonatuser;
GRANT ALL ON TABLE bib_sources TO geonatuser;


--
-- Name: cor_unite_synthese; Type: ACL; Schema: synthese; Owner: -
--

REVOKE ALL ON TABLE cor_unite_synthese FROM PUBLIC;
REVOKE ALL ON TABLE cor_unite_synthese FROM geonatuser;
GRANT ALL ON TABLE cor_unite_synthese TO geonatuser;


--
-- Name: cor_zonesstatut_synthese; Type: ACL; Schema: synthese; Owner: -
--

REVOKE ALL ON TABLE cor_zonesstatut_synthese FROM PUBLIC;
REVOKE ALL ON TABLE cor_zonesstatut_synthese FROM geonatuser;
GRANT ALL ON TABLE cor_zonesstatut_synthese TO geonatuser;


SET search_path = synthese, pg_catalog;

--
-- Name: v_tree_taxons_synthese; Type: ACL; Schema: synthese; Owner: -
--

REVOKE ALL ON TABLE v_tree_taxons_synthese FROM PUBLIC;
REVOKE ALL ON TABLE v_tree_taxons_synthese FROM geonatuser;
GRANT ALL ON TABLE v_tree_taxons_synthese TO geonatuser;


SET search_path = taxonomie, pg_catalog;

--
-- Name: bib_listes; Type: ACL; Schema: taxonomie; Owner: -
--

REVOKE ALL ON TABLE bib_listes FROM PUBLIC;
REVOKE ALL ON TABLE bib_listes FROM geonatuser;
GRANT ALL ON TABLE bib_listes TO geonatuser;


--
-- Name: bib_attributs; Type: ACL; Schema: taxonomie; Owner: -
--

REVOKE ALL ON TABLE bib_attributs FROM PUBLIC;
REVOKE ALL ON TABLE bib_attributs FROM geonatuser;
GRANT ALL ON TABLE bib_attributs TO geonatuser;


--
-- Name: bib_taxref_habitats; Type: ACL; Schema: taxonomie; Owner: -
--

REVOKE ALL ON TABLE bib_taxref_habitats FROM PUBLIC;
REVOKE ALL ON TABLE bib_taxref_habitats FROM geonatuser;
GRANT ALL ON TABLE bib_taxref_habitats TO geonatuser;


--
-- Name: bib_taxref_rangs; Type: ACL; Schema: taxonomie; Owner: -
--

REVOKE ALL ON TABLE bib_taxref_rangs FROM PUBLIC;
REVOKE ALL ON TABLE bib_taxref_rangs FROM geonatuser;
GRANT ALL ON TABLE bib_taxref_rangs TO geonatuser;


--
-- Name: bib_taxref_statuts; Type: ACL; Schema: taxonomie; Owner: -
--

REVOKE ALL ON TABLE bib_taxref_statuts FROM PUBLIC;
REVOKE ALL ON TABLE bib_taxref_statuts FROM geonatuser;
GRANT ALL ON TABLE bib_taxref_statuts TO geonatuser;


--
-- Name: import_taxref; Type: ACL; Schema: taxonomie; Owner: -
--

REVOKE ALL ON TABLE import_taxref FROM PUBLIC;
REVOKE ALL ON TABLE import_taxref FROM postgres;
GRANT ALL ON TABLE import_taxref TO postgres;


--
-- Name: taxref_changes; Type: ACL; Schema: taxonomie; Owner: -
--

REVOKE ALL ON TABLE taxref_changes FROM PUBLIC;
REVOKE ALL ON TABLE taxref_changes FROM geonatuser;
GRANT ALL ON TABLE taxref_changes TO geonatuser;


--
-- Name: taxref_protection_articles; Type: ACL; Schema: taxonomie; Owner: -
--

REVOKE ALL ON TABLE taxref_protection_articles FROM PUBLIC;
REVOKE ALL ON TABLE taxref_protection_articles FROM geonatuser;
GRANT ALL ON TABLE taxref_protection_articles TO geonatuser;


--
-- Name: taxref_protection_especes; Type: ACL; Schema: taxonomie; Owner: -
--

REVOKE ALL ON TABLE taxref_protection_especes FROM PUBLIC;
REVOKE ALL ON TABLE taxref_protection_especes FROM geonatuser;
GRANT ALL ON TABLE taxref_protection_especes TO geonatuser;


--
-- Name: cor_taxon_attribut; Type: ACL; Schema: taxonomie; Owner: -
--

REVOKE ALL ON TABLE cor_taxon_attribut FROM PUBLIC;
REVOKE ALL ON TABLE cor_taxon_attribut FROM geonatuser;
GRANT ALL ON TABLE cor_taxon_attribut TO geonatuser;


--
-- Name: cor_taxon_groupe; Type: ACL; Schema: taxonomie; Owner: -
--

REVOKE ALL ON TABLE cor_taxon_groupe FROM PUBLIC;
REVOKE ALL ON TABLE cor_taxon_groupe FROM geonatuser;
GRANT ALL ON TABLE cor_taxon_groupe TO geonatuser;


--
-- Name: cor_taxon_liste; Type: ACL; Schema: taxonomie; Owner: -
--

REVOKE ALL ON TABLE cor_taxon_liste FROM PUBLIC;
REVOKE ALL ON TABLE cor_taxon_liste FROM geonatuser;
GRANT ALL ON TABLE cor_taxon_liste TO geonatuser;


SET search_path = utilisateurs, pg_catalog;

--
-- Name: bib_droits; Type: ACL; Schema: utilisateurs; Owner: -
--

REVOKE ALL ON TABLE bib_droits FROM PUBLIC;
REVOKE ALL ON TABLE bib_droits FROM geonatuser;
GRANT ALL ON TABLE bib_droits TO geonatuser;


--
-- Name: bib_unites_id_seq; Type: ACL; Schema: utilisateurs; Owner: -
--

REVOKE ALL ON SEQUENCE bib_unites_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE bib_unites_id_seq FROM geonatuser;
GRANT ALL ON SEQUENCE bib_unites_id_seq TO geonatuser;
GRANT ALL ON SEQUENCE bib_unites_id_seq TO postgres;


--
-- Name: bib_unites; Type: ACL; Schema: utilisateurs; Owner: -
--

REVOKE ALL ON TABLE bib_unites FROM PUBLIC;
REVOKE ALL ON TABLE bib_unites FROM geonatuser;
GRANT ALL ON TABLE bib_unites TO geonatuser;


--
-- Name: cor_role_droit_application; Type: ACL; Schema: utilisateurs; Owner: -
--

REVOKE ALL ON TABLE cor_role_droit_application FROM PUBLIC;
REVOKE ALL ON TABLE cor_role_droit_application FROM geonatuser;
GRANT ALL ON TABLE cor_role_droit_application TO geonatuser;


--
-- Name: t_applications; Type: ACL; Schema: utilisateurs; Owner: -
--

REVOKE ALL ON TABLE t_applications FROM PUBLIC;
REVOKE ALL ON TABLE t_applications FROM geonatuser;
GRANT ALL ON TABLE t_applications TO geonatuser;


--
-- Name: t_applications_id_application_seq; Type: ACL; Schema: utilisateurs; Owner: -
--

REVOKE ALL ON SEQUENCE t_applications_id_application_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE t_applications_id_application_seq FROM geonatuser;
GRANT ALL ON SEQUENCE t_applications_id_application_seq TO geonatuser;


--
-- Name: t_menus; Type: ACL; Schema: utilisateurs; Owner: -
--

REVOKE ALL ON TABLE t_menus FROM PUBLIC;
REVOKE ALL ON TABLE t_menus FROM geonatuser;
GRANT ALL ON TABLE t_menus TO geonatuser;


--
-- Name: t_menus_id_menu_seq; Type: ACL; Schema: utilisateurs; Owner: -
--

REVOKE ALL ON SEQUENCE t_menus_id_menu_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE t_menus_id_menu_seq FROM geonatuser;
GRANT ALL ON SEQUENCE t_menus_id_menu_seq TO geonatuser;


--
-- Name: v_nomade_observateurs_all; Type: ACL; Schema: utilisateurs; Owner: -
--

REVOKE ALL ON TABLE v_nomade_observateurs_all FROM PUBLIC;
REVOKE ALL ON TABLE v_nomade_observateurs_all FROM geonatuser;
GRANT ALL ON TABLE v_nomade_observateurs_all TO geonatuser;
GRANT ALL ON TABLE v_nomade_observateurs_all TO postgres;


--
-- Name: v_observateurs; Type: ACL; Schema: utilisateurs; Owner: -
--

REVOKE ALL ON TABLE v_observateurs FROM PUBLIC;
REVOKE ALL ON TABLE v_observateurs FROM geonatuser;
GRANT ALL ON TABLE v_observateurs TO geonatuser;

--
-- PostgreSQL database dump complete
--

