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
  patri boolean;
  BEGIN
	SELECT patrimonial INTO patri FROM taxonomie.bib_taxons WHERE id_taxon = id;
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
		SELECT INTO nbobs count(*) from synthese.synthesefaune s
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
    
	DELETE FROM synthese.synthesefaune WHERE id_source = idsource AND id_fiche_source = old.id_releve_cf::text; 
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
	danslecoeur boolean;
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
	-- on calcul si on est dans le coeur
	IF st_intersects((SELECT the_geom FROM layers.l_zonesstatut WHERE id_zone = 3249), fiche.the_geom_2154) THEN 
	    danslecoeur = true;
	ELSE
	    danslecoeur = false;
	END IF;
	INSERT INTO synthese.synthesefaune (
		id_source,
		id_fiche_source,
		code_fiche_source,
		id_organisme,
		id_protocole,
		codeprotocole,
		ids_protocoles,
		id_precision,
		cd_nom,
		id_taxon,
		insee,
		dateobs,
		observateurs,
		altitude_retenue,
		remarques,
		derniere_action,
		supprime,
		the_geom_3857,
		the_geom_2154,
		the_geom_point,
		id_lot,
		id_critere_synthese,
		effectif_total,
		coeur
	)
	VALUES(
	idsource,
	new.id_releve_cf,
	'f'||new.id_cf||'-r'||new.id_releve_cf,
	fiche.id_organisme,
	fiche.id_protocole,
	1,
	fiche.id_protocole,
	1,
	new.cd_ref_origine,
	new.id_taxon,
	fiche.insee,
	fiche.dateobs,
	mesobservateurs,
	fiche.altitude_retenue,
	new.commentaire,
	'c',
	false,
	fiche.the_geom_3857,
	fiche.the_geom_2154,
	fiche.the_geom_3857,
	fiche.id_lot,
	criteresynthese,
	new.am+new.af+new.ai+new.na+new.jeune+new.yearling+new.sai,
	danslecoeur
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
		--test si on a bien l'enregistrement dans la table synthesefaune avant de le mettre à jour
		SELECT INTO test id_fiche_source FROM synthese.synthesefaune 
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
			--mise à jour de l'enregistrement correspondant dans synthesefaune ; uniquement le champ observateurs ici
			UPDATE synthese.synthesefaune SET
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
	danslecoeur boolean;
    idsource integer;
BEGIN

    
    SELECT INTO idsource id_source FROM synthese.bib_sources  WHERE db_schema='contactfaune' AND db_field = 'id_releve_cf' ;

	--Récupération des données de la table t_releves_cf avec l'id_cf de la fiche modifié
	-- Ici on utilise le OLD id_cf pour être sur qu'il existe dans la table synthese (cas improbable où on changerait la pk de la table t_fiches_cf
	--le trigger met à jour avec le NEW --> SET code_fiche_source =  ....
	FOR releves IN SELECT * FROM contactfaune.t_releves_cf WHERE id_cf = old.id_cf LOOP
		--test si on a bien l'enregistrement dans la table synthesefaune avant de le mettre à jour
		SELECT INTO test id_fiche_source FROM synthese.synthesefaune WHERE id_source = idsource AND id_fiche_source = releves.id_releve_cf::text;
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
			--si la géométrie a changé on doit vérifier si on est toujours dans le coeur, sinon on ne change pas la valeur du champ coeur
			IF NOT St_Equals(new.the_geom_3857,old.the_geom_3857) OR NOT St_Equals(new.the_geom_2154,old.the_geom_2154) THEN
				IF st_intersects((SELECT the_geom FROM layers.l_zonesstatut WHERE id_zone = 3249), new.the_geom_2154) THEN 
				danslecoeur = true;
			        ELSE
				danslecoeur = false;
				END IF;
				--mise à jour de l'enregistrement correspondant dans synthesefaune
				UPDATE synthese.synthesefaune SET
				code_fiche_source = 'f'||new.id_cf||'-r'||releves.id_releve_cf,
				id_organisme = new.id_organisme,
				id_protocole = new.id_protocole,
				ids_protocoles = new.id_protocole,
				insee = new.insee,
				dateobs = new.dateobs,
				observateurs = mesobservateurs,
				altitude_retenue = new.altitude_retenue,
				derniere_action = 'u',
				supprime = new.supprime,
				the_geom_3857 = new.the_geom_3857,
				the_geom_2154 = new.the_geom_2154,
				the_geom_point = new.the_geom_3857,
				id_lot = new.id_lot,
				coeur = danslecoeur
				WHERE id_source = idsource AND id_fiche_source = releves.id_releve_cf::text;
			ELSE
				--mise à jour de l'enregistrement correspondant dans synthesefaune mais on ne change rien pour le champ coeur
				UPDATE synthese.synthesefaune SET
				code_fiche_source = 'f'||new.id_cf||'-r'||releves.id_releve_cf,
				id_organisme = new.id_organisme,
				id_protocole = new.id_protocole,
				ids_protocoles = new.id_protocole,
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

	--test si on a bien l'enregistrement dans la table synthesefaune avant de le mettre à jour
	SELECT INTO test id_fiche_source FROM synthese.synthesefaune WHERE id_source = idsource AND id_fiche_source = old.id_releve_cf::text;
	IF test IS NOT NULL THEN
		SELECT INTO criteresynthese id_critere_synthese FROM contactfaune.bib_criteres_cf WHERE id_critere_cf = new.id_critere_cf;
		-- on ne calcule pas si on est dans le coeur car ce travail est déjà fait par le trigger sur la fiche qui comporte la géométrie

		--mise à jour de l'enregistrement correspondant dans synthesefaune
		UPDATE synthese.synthesefaune SET
			id_fiche_source = new.id_releve_cf,
			code_fiche_source = 'f'||new.id_cf||'-r'||new.id_releve_cf,
			cd_nom = new.cd_ref_origine,
			id_taxon = new.id_taxon,
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
IF (NOT ST_Equals(new.the_geom_2154,old.the_geom_2154) OR (old.the_geom_2154 is null AND new.the_geom_2154 is not null))
  OR (NOT ST_Equals(new.the_geom_3857,old.the_geom_3857) OR (old.the_geom_3857 is null AND new.the_geom_3857 is not null)) 
   THEN
	IF NOT ST_Equals(new.the_geom_3857,old.the_geom_3857) OR (old.the_geom_3857 is null AND new.the_geom_3857 is not null) THEN
		new.the_geom_2154 = st_transform(new.the_geom_3857,2154);
		new.srid_dessin = 3857;
	ELSIF NOT ST_Equals(new.the_geom_2154,old.the_geom_2154) OR (old.the_geom_2154 is null AND new.the_geom_2154 is not null) THEN
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
	SELECT patrimonial INTO patri FROM taxonomie.bib_taxons WHERE id_taxon = id;
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
		SELECT INTO nbobs count(*) from synthese.synthesefaune s
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
	DELETE FROM synthese.synthesefaune WHERE id_source = idsource AND id_fiche_source = old.id_releve_inv::text; 
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
	danslecoeur boolean;
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
    
	--On calcul si on est dans le coeur
	IF st_intersects((SELECT the_geom FROM layers.l_zonesstatut WHERE id_zone = 3249), fiche.the_geom_2154) THEN 
	    danslecoeur = true;
	ELSE
	    danslecoeur = false;
	END IF;
    
	--On fait le INSERT dans synthesefaune
	INSERT INTO synthese.synthesefaune (
		id_source,
		id_fiche_source,
		code_fiche_source,
		id_organisme,
		id_protocole,
		codeprotocole,
		ids_protocoles,
		id_precision,
		cd_nom,
		id_taxon,
		insee,
		dateobs,
		observateurs,
		altitude_retenue,
		remarques,
		derniere_action,
		supprime,
		the_geom_3857,
		the_geom_2154,
		the_geom_point,
		id_lot,
		id_critere_synthese,
		effectif_total,
		coeur
	)
	VALUES(
	idsource,
	new.id_releve_inv,
	'f'||new.id_inv||'-r'||new.id_releve_inv,
	fiche.id_organisme,
	fiche.id_protocole,
	2,
	fiche.id_protocole,
	1,
	new.cd_ref_origine,
	new.id_taxon,
	fiche.insee,
	fiche.dateobs,
	mesobservateurs,
	fiche.altitude_retenue,
	new.commentaire,
	'c',
	false,
	fiche.the_geom_3857,
	fiche.the_geom_2154,
	fiche.the_geom_3857,
	fiche.id_lot,
	criteresynthese,
	new.am+new.af+new.ai+new.na,
	danslecoeur
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
		--test si on a bien l'enregistrement dans la table synthesefaune avant de le mettre à jour
		SELECT INTO test id_fiche_source FROM synthese.synthesefaune WHERE id_source = idsource AND id_fiche_source = releves.id_releve_inv::text;
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
			--mise à jour de l'enregistrement correspondant dans synthesefaune ; uniquement le champ observateurs ici
			UPDATE synthese.synthesefaune SET
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
	danslecoeur boolean;
    idsource integer;
BEGIN

    
	--Récupération des données id_source dans la table synthese.bib_sources
	SELECT INTO idsource id_source FROM synthese.bib_sources  WHERE db_schema='contactinv' AND db_field = 'id_releve_inv';
    
	--Récupération des données de la table t_releves_inv avec l'id_inv de la fiche modifié
	-- Ici on utilise le OLD id_inv pour être sur qu'il existe dans la table synthese (cas improbable où on changerait la pk de la table t_fiches_inv
	--le trigger met à jour avec le NEW --> SET code_fiche_source =  ....
	FOR releves IN SELECT * FROM contactinv.t_releves_inv WHERE id_inv = old.id_inv LOOP
		--test si on a bien l'enregistrement dans la table synthesefaune avant de le mettre à jour
		SELECT INTO test id_fiche_source FROM synthese.synthesefaune WHERE id_source = idsource AND id_fiche_source = releves.id_releve_inv::text;
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
			--si la géométrie a changé on doit vérifier si on est toujours dans le coeur, sinon on ne change pas la valeur du champ coeur
			IF NOT St_Equals(new.the_geom_3857,old.the_geom_3857) OR NOT St_Equals(new.the_geom_2154,old.the_geom_2154) THEN
				IF st_intersects((SELECT the_geom FROM layers.l_zonesstatut WHERE id_zone = 3249), new.the_geom_2154) THEN 
				  danslecoeur = true;
			        ELSE
				  danslecoeur = false;
				END IF;
			--mise à jour de l'enregistrement correspondant dans synthesefaune
				UPDATE synthese.synthesefaune SET
					code_fiche_source = 'f'||new.id_inv||'-r'||releves.id_releve_inv,
					id_organisme = new.id_organisme,
					id_protocole = new.id_protocole,
					ids_protocoles = new.id_protocole,
					insee = new.insee,
					dateobs = new.dateobs,
					observateurs = mesobservateurs,
					altitude_retenue = new.altitude_retenue,
					derniere_action = 'u',
					supprime = new.supprime,
					the_geom_3857 = new.the_geom_3857,
					the_geom_2154 = new.the_geom_2154,
					the_geom_point = new.the_geom_3857,
					id_lot = new.id_lot,
					coeur = danslecoeur
				WHERE id_source = idsource AND id_fiche_source = releves.id_releve_inv::text;
			ELSE
			--mise à jour de l'enregistrement correspondant dans synthesefaune mais sans le coeur
				UPDATE synthese.synthesefaune SET
					code_fiche_source = 'f'||new.id_inv||'-r'||releves.id_releve_inv,
					id_organisme = new.id_organisme,
					id_protocole = new.id_protocole,
					ids_protocoles = new.id_protocole,
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
    
	--test si on a bien l'enregistrement dans la table synthesefaune avant de le mettre à jour
	SELECT INTO test id_fiche_source FROM synthese.synthesefaune WHERE id_source = idsource AND id_fiche_source = old.id_releve_inv::text;
	IF test IS NOT NULL THEN
		--Récupération des données dans la table t_fiches_inv et de la liste des observateurs
		SELECT INTO criteresynthese id_critere_synthese FROM contactinv.bib_criteres_inv WHERE id_critere_inv = new.id_critere_inv;

		--mise à jour de l'enregistrement correspondant dans synthesefaune
		UPDATE synthese.synthesefaune SET
			id_fiche_source = new.id_releve_inv,
			code_fiche_source = 'f'||new.id_inv||'-r'||new.id_releve_inv,
			cd_nom = new.cd_ref_origine,
			id_taxon = new.id_taxon,
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
IF (NOT ST_Equals(new.the_geom_2154,old.the_geom_2154) OR (old.the_geom_2154 is null AND new.the_geom_2154 is not null))
  OR (NOT ST_Equals(new.the_geom_3857,old.the_geom_3857) OR (old.the_geom_3857 is null AND new.the_geom_3857 is not null)) 
   THEN
	IF NOT ST_Equals(new.the_geom_3857,old.the_geom_3857) OR (old.the_geom_3857 is null AND new.the_geom_3857 is not null) THEN
		new.the_geom_2154 = st_transform(new.the_geom_3857,2154);
		new.srid_dessin = 3857;
	ELSIF NOT ST_Equals(new.the_geom_2154,old.the_geom_2154) OR (old.the_geom_2154 is null AND new.the_geom_2154 is not null) THEN
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
-- Name: insert_synthesefaune(); Type: FUNCTION; Schema: synthese; Owner: -
--

CREATE FUNCTION insert_synthesefaune() RETURNS trigger
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
		INSERT INTO synthese.cor_unite_synthese (id_synthese, id_taxon, dateobs, id_unite_geo)
		SELECT s.id_synthese, s.id_taxon, s.dateobs,u.id_unite_geo FROM synthese.synthesefaune s, layers.l_unites_geo u 
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
		SELECT tx.phylum FROM taxonomie.bib_taxons t
        JOIN taxonomie.taxref tx ON tx.cd_nom = t.cd_nom
		WHERE t.id_taxon = old.id_taxon;
		-- puis recalul des couleurs avec old.id_unite_geo et old.taxon selon que le taxon est vertébrés (embranchemet 1) ou invertébres
		IF monembranchement = 'Chordata' THEN
			IF (SELECT count(*) FROM synthese.cor_unite_synthese WHERE id_taxon = old.id_taxon AND id_unite_geo = old.id_unite_geo)= 0 THEN
				DELETE FROM contactfaune.cor_unite_taxon WHERE id_taxon = old.id_taxon AND id_unite_geo = old.id_unite_geo;
			ELSE
				PERFORM synthese.calcul_cor_unite_taxon_cf(old.id_taxon, old.id_unite_geo);
			END IF;
		ELSE
			IF (SELECT count(*) FROM synthese.cor_unite_synthese WHERE id_taxon = old.id_taxon AND id_unite_geo = old.id_unite_geo)= 0 THEN
				DELETE FROM contactinv.cor_unite_taxon_inv WHERE id_taxon = old.id_taxon AND id_unite_geo = old.id_unite_geo;
			ELSE
				PERFORM synthese.calcul_cor_unite_taxon_inv(old.id_taxon, old.id_unite_geo);
			END IF;
		END IF;
		RETURN OLD;		
ELSIF (TG_OP = 'INSERT') THEN
	--calcul de l'embranchement du taxon inséré
        SELECT tx.phylum FROM taxonomie.bib_taxons t
        JOIN taxonomie.taxref tx ON tx.cd_nom = t.cd_nom
        WHERE t.id_taxon = new.id_taxon;
	-- puis recalul des couleurs avec new.id_unite_geo et new.taxon selon que le taxon est vertébrés (embranchemet 1) ou invertébres
        IF monembranchement = 'Chordata' THEN
            PERFORM synthese.calcul_cor_unite_taxon_cf(new.id_taxon, new.id_unite_geo);
        ELSE
            PERFORM synthese.calcul_cor_unite_taxon_inv(new.id_taxon, new.id_unite_geo);
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
		SELECT z.id_zone,s.id_synthese FROM synthese.synthesefaune s, layers.l_zonesstatut z 
		WHERE ST_Intersects(z.the_geom, s.the_geom_2154)
		AND z.id_type IN(4,5,8,9,11,12,13) -- typologie limitée au coeur, reserve, natura2000 etc...
		AND s.id_synthese = new.id_synthese;
	END IF;
END IF;
RETURN NULL; 
END;
$$;


--
-- Name: update_synthesefaune(); Type: FUNCTION; Schema: synthese; Owner: -
--

CREATE FUNCTION update_synthesefaune() RETURNS trigger
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


SET search_path = taxonomie, pg_catalog;

--
-- Name: bib_groupes; Type: TABLE; Schema: taxonomie; Owner: -; Tablespace: 
--

CREATE TABLE taxonomie.bib_groupes
(
  id_groupe integer NOT NULL,
  nom_groupe character varying(255),
  desc_groupe text,
  filtre_sql text
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
    START WITH 1
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
    organisme character(32),
    id_unite integer,
    pn boolean,
    assermentes boolean,
    enposte boolean,
    dernieracces timestamp without time zone,
    session_appli character varying(50),
    date_insert timestamp without time zone,
    date_update timestamp without time zone,
    id_organisme integer
);


SET search_path = contactfaune, pg_catalog;

--
-- Name: v_nomade_observateurs_faune; Type: VIEW; Schema: contactfaune; Owner: -
--

CREATE VIEW v_nomade_observateurs_faune AS
    SELECT DISTINCT r.id_role, r.nom_role, r.prenom_role FROM utilisateurs.t_roles r WHERE ((r.id_role IN (SELECT DISTINCT cr.id_role_utilisateur FROM utilisateurs.cor_roles cr WHERE (cr.id_role_groupe IN (SELECT crm.id_role FROM utilisateurs.cor_role_menu crm WHERE (crm.id_menu = 9))) ORDER BY cr.id_role_utilisateur)) OR (r.id_role IN (SELECT crm.id_role FROM (utilisateurs.cor_role_menu crm JOIN utilisateurs.t_roles r ON ((((r.id_role = crm.id_role) AND (crm.id_menu = 9)) AND (r.groupe = false))))))) ORDER BY r.nom_role, r.prenom_role, r.id_role;


SET search_path = taxonomie, pg_catalog;

--
-- Name: bib_taxons; Type: TABLE; Schema: taxonomie; Owner: -; Tablespace: 
--

CREATE TABLE bib_taxons (
    id_taxon integer NOT NULL,
    cd_nom integer,
    nom_latin character varying(100),
    nom_francais character varying(255),
    auteur character varying(200),
    saisie_autorisee integer,
    id_groupe integer,
    patrimonial boolean DEFAULT false NOT NULL,
    id_responsabilite_pn integer,
    id_statut_migration integer,
    id_importance_population integer,
    reproducteur boolean,
    protection_stricte boolean
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
            gr.filtre_sql,
            min(taxonomie.find_cdref(tx.cd_nom)) AS cd_ref
           FROM taxonomie.bib_groupes gr
             JOIN taxonomie.bib_taxons tx ON gr.id_groupe = tx.id_groupe
          GROUP BY gr.id_groupe, gr.nom_groupe, gr.desc_groupe, gr.filtre_sql) g
     JOIN taxonomie.taxref t ON t.cd_nom = g.cd_ref
  WHERE t.phylum::text = 'Chordata'::text;

--
-- Name: v_nomade_taxons_faune; Type: VIEW; Schema: contactfaune; Owner: -
--
CREATE OR REPLACE VIEW contactfaune.v_nomade_taxons_faune AS 
SELECT DISTINCT t.id_taxon,
    taxonomie.find_cdref(tx.cd_nom) AS cd_ref,
    t.nom_latin,
    t.nom_francais,
    g.id_classe,
    5 AS denombrement,
    t.patrimonial,
    m.texte_message_cf AS message,
    true AS contactfaune,
    true AS mortalite
FROM taxonomie.bib_taxons t
LEFT JOIN contactfaune.cor_message_taxon cmt ON cmt.id_taxon = t.id_taxon
LEFT JOIN contactfaune.bib_messages_cf m ON m.id_message_cf = cmt.id_message_cf
JOIN contactfaune.v_nomade_classes g ON g.id_classe = t.id_groupe
JOIN taxonomie.taxref tx ON tx.cd_nom = t.cd_nom
WHERE t.saisie_autorisee = 1
ORDER BY t.id_taxon, taxonomie.find_cdref(tx.cd_nom), t.nom_latin, t.nom_francais, g.id_classe, t.patrimonial, m.texte_message_cf;


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
    supprime boolean DEFAULT false NOT NULL,
    prelevement boolean DEFAULT false NOT NULL,
    gid integer NOT NULL,
    determinateur character varying(255)
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
            gr.filtre_sql,
            min(taxonomie.find_cdref(tx.cd_nom)) AS cd_ref
           FROM taxonomie.bib_groupes gr
             JOIN taxonomie.bib_taxons tx ON gr.id_groupe = tx.id_groupe
          GROUP BY gr.id_groupe, gr.nom_groupe, gr.desc_groupe, gr.filtre_sql) g
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
SELECT 
    t.id_taxon,
    taxonomie.find_cdref(tx.cd_nom) AS cd_ref,
    t.nom_latin,
    t.nom_francais,
    g.id_classe,
    t.patrimonial,
    m.texte_message_inv AS message
FROM taxonomie.bib_taxons t
LEFT JOIN contactinv.cor_message_taxon cmt ON cmt.id_taxon = t.id_taxon
LEFT JOIN contactinv.bib_messages_inv m ON m.id_message_inv = cmt.id_message_inv
JOIN contactinv.v_nomade_classes g ON g.id_classe = t.id_groupe
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
    commune_maj character varying(40),
    insee character(5) NOT NULL,
    departement character(3),
    commune_min character varying(40),
    epci character varying(40),
    coeur_aoa character(2),
    codenum integer,
    pays character varying(50),
    id_secteur integer,
    saisie_fv boolean,
    saisie_fp boolean,
    pn boolean,
    atlas boolean,
    leader2 boolean,
    leaderplus boolean,
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
    nomzone character varying(250),
    id_zone integer NOT NULL,
    id_type integer DEFAULT 1 NOT NULL,
    the_geom public.geometry,
    CONSTRAINT enforce_dims_the_geom CHECK ((public.st_ndims(the_geom) = 2)),
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
-- Name: synthesefaune; Type: TABLE; Schema: synthese; Owner: -; Tablespace: 
--

CREATE TABLE synthesefaune (
    id_synthese integer NOT NULL,
    id_source integer,
    id_fiche_source character varying(50),
    code_fiche_source character varying(50),
    id_organisme integer,
    id_protocole integer,
    codeprotocole integer,
    ids_protocoles character varying(255) NOT NULL,
    id_precision integer,
    cd_nom integer,
    insee character(5),
    dateobs date NOT NULL,
    observateurs character varying(255),
    altitude_retenue integer,
    remarques text,
    date_insert timestamp without time zone,
    date_update timestamp without time zone,
    derniere_action character(1),
    supprime boolean,
    the_geom_point public.geometry,
    id_taxon integer,
    id_lot integer,
    id_critere_synthese integer,
    the_geom_3857 public.geometry,
    effectif_total integer,
    coeur boolean,
    determinateur character varying(255),
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
-- Name: TABLE synthesefaune; Type: COMMENT; Schema: synthese; Owner: -
--

COMMENT ON TABLE synthesefaune IS 'Table de synthèse destinée à recevoir les données de tous les schémas.Pour consultation uniquement';


--
-- Name: COLUMN synthesefaune.ids_protocoles; Type: COMMENT; Schema: synthese; Owner: -
--

COMMENT ON COLUMN synthesefaune.ids_protocoles IS 'Identifiant du ou des protocoles qui ont servi au recueil de cette donnée. Certaines anciennes données ont des informations de protocole qui regroupe potentiellement plusieurs protocoles';


SET search_path = utilisateurs, pg_catalog;

--
-- Name: bib_organismes_id_seq; Type: SEQUENCE; Schema: utilisateurs; Owner: -
--

CREATE SEQUENCE bib_organismes_id_seq
    START WITH 100
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
    id_taxon integer
);


--
-- Name: cor_zonesstatut_synthese; Type: TABLE; Schema: synthese; Owner: -; Tablespace: 
--

CREATE TABLE cor_zonesstatut_synthese (
    id_zone integer NOT NULL,
    id_synthese integer NOT NULL
);


--
-- Name: synthesefaune_id_synthese_seq; Type: SEQUENCE; Schema: synthese; Owner: -
--

CREATE SEQUENCE synthesefaune_id_synthese_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: synthesefaune_id_synthese_seq; Type: SEQUENCE OWNED BY; Schema: synthese; Owner: -
--

ALTER SEQUENCE synthesefaune_id_synthese_seq OWNED BY synthesefaune.id_synthese;

SET search_path = taxonomie, pg_catalog;

--
-- Name: bib_importances_population; Type: TABLE; Schema: taxonomie; Owner: -; Tablespace: 
--

CREATE TABLE bib_importances_population (
    id_importance_population integer NOT NULL,
    nom_importance_population character varying(50),
    desc_importance_population character varying(255)
);


--
-- Name: bib_responsabilites_pn; Type: TABLE; Schema: taxonomie; Owner: -; Tablespace: 
--

CREATE TABLE bib_responsabilites_pn (
    id_responsabilite_pn integer NOT NULL,
    nom_responsabilite_pn character varying(50),
    desc_responsabilite_pn character varying(255)
);


--
-- Name: bib_statuts_migration; Type: TABLE; Schema: taxonomie; Owner: -; Tablespace: 
--

CREATE TABLE bib_statuts_migration (
    id_statut_migration integer NOT NULL,
    nom_statut_migration character varying(50),
    desc_statut_migration character varying(255)
);


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
  pn boolean
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
WITH taxon AS (
  SELECT tx.id_taxon, tx.nom_latin,tx.nom_francais, tx.patrimonial, tx.protection_stricte , taxref.*
  FROM (
      SELECT id_taxon, cd_nom,  taxonomie.find_cdref(tx.cd_nom) AS cd_ref, nom_latin, nom_francais, patrimonial, protection_stricte
      FROM taxonomie.bib_taxons tx
      WHERE (tx.id_taxon IN ( SELECT DISTINCT synthesefaune.id_taxon FROM synthese.synthesefaune  ORDER BY synthesefaune.id_taxon))
  ) tx
  JOIN taxonomie.taxref taxref 
  ON taxref.cd_nom = tx.cd_ref
) 
SELECT id_taxon, cd_ref, nom_latin, nom_francais, 
    id_embranchement, nom_embranchement, 
    COALESCE(id_classe, id_embranchement) as id_classe, COALESCE(nom_classe, ' No class in taxref') as nom_classe, COALESCE(desc_classe, ' No class in taxref') as desc_classe, 
    COALESCE(id_ordre, id_classe) as id_ordre, COALESCE(nom_ordre, ' No order in taxref') as nom_ordre, 
    COALESCE(id_famille, id_ordre) as id_famille, COALESCE(nom_famille, ' No family in taxref') as nom_famille,
    patrimonial, protection_stricte
FROM (
  SELECT DISTINCT 
    t.id_taxon,  t.cd_ref,  t.nom_latin, t.nom_francais,
    (SELECT cd_nom  FROM taxonomie.taxref WHERE id_rang ='PH' and lb_nom = t.phylum) as id_embranchement,
    t.phylum as nom_embranchement,
    CASE WHEN t.classe  IS NULL THEN NULL 
      ELSE (SELECT cd_nom FROM taxonomie.taxref WHERE id_rang ='CL' and lb_nom = t.classe AND cd_nom =cd_ref) END as id_classe,
    t.classe  as nom_classe,
    t.classe as desc_classe,
    CASE WHEN t.ordre  IS NULL THEN NULL 
      ELSE (SELECT cd_nom FROM taxonomie.taxref WHERE id_rang ='OR' and lb_nom = t.ordre AND cd_nom =cd_ref) END as id_ordre,
    t.ordre  as nom_ordre,
    CASE WHEN t.famille  IS NULL THEN NULL 
      ELSE (SELECT cd_nom FROM taxonomie.taxref WHERE id_rang ='FM' and lb_nom = t.famille AND phylum = t.phylum AND cd_nom =cd_ref) END as id_famille,
    famille as nom_famille,
    t.patrimonial,
    t.protection_stricte
  FROM taxon t
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
    START WITH 1
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
    desc_application text,
    connect_host character varying(100),
    connect_database character varying(50),
    connect_user character varying(50),
    connect_pass character varying(20)
);


--
-- Name: t_applications_id_application_seq; Type: SEQUENCE; Schema: utilisateurs; Owner: -
--

CREATE SEQUENCE t_applications_id_application_seq
    START WITH 1
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
    START WITH 1
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


SET search_path = synthese, pg_catalog;

--
-- Name: id_synthese; Type: DEFAULT; Schema: synthese; Owner: -
--

ALTER TABLE ONLY synthesefaune ALTER COLUMN id_synthese SET DEFAULT nextval('synthesefaune_id_synthese_seq'::regclass);


SET search_path = utilisateurs, pg_catalog;

--
-- Name: id_application; Type: DEFAULT; Schema: utilisateurs; Owner: -
--

ALTER TABLE ONLY t_applications ALTER COLUMN id_application SET DEFAULT nextval('t_applications_id_application_seq'::regclass);


--
-- Name: id_menu; Type: DEFAULT; Schema: utilisateurs; Owner: -
--

ALTER TABLE ONLY t_menus ALTER COLUMN id_menu SET DEFAULT nextval('t_menus_id_menu_seq'::regclass);


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
-- Name: synthesefaune_pkey; Type: CONSTRAINT; Schema: synthese; Owner: -; Tablespace: 
--

ALTER TABLE ONLY synthesefaune
    ADD CONSTRAINT synthesefaune_pkey PRIMARY KEY (id_synthese);


SET search_path = taxonomie, pg_catalog;


--
-- Name: pk_bib_groupe; Type: CONSTRAINT; Schema: taxonomie; Owner: -; Tablespace: 
--

ALTER TABLE ONLY bib_groupes
    ADD CONSTRAINT pk_bib_groupe PRIMARY KEY (id_groupe);


--
-- Name: pk_bib_importances_population; Type: CONSTRAINT; Schema: taxonomie; Owner: -; Tablespace: 
--

ALTER TABLE ONLY bib_importances_population
    ADD CONSTRAINT pk_bib_importances_population PRIMARY KEY (id_importance_population);

--
-- Name: pk_bib_responsabilites_pn; Type: CONSTRAINT; Schema: taxonomie; Owner: -; Tablespace: 
--

ALTER TABLE ONLY bib_responsabilites_pn
    ADD CONSTRAINT pk_bib_responsabilites_pn PRIMARY KEY (id_responsabilite_pn);


--
-- Name: pk_bib_statuts_migration; Type: CONSTRAINT; Schema: taxonomie; Owner: -; Tablespace: 
--

ALTER TABLE ONLY bib_statuts_migration
    ADD CONSTRAINT pk_bib_statuts_migration PRIMARY KEY (id_statut_migration);


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


SET search_path = layers, pg_catalog;

--
-- Name: fki_; Type: INDEX; Schema: layers; Owner: -; Tablespace: 
--

CREATE INDEX fki_ ON l_communes USING btree (id_secteur);


SET search_path = synthese, pg_catalog;

--
-- Name: fki_synthese_bib_proprietaires; Type: INDEX; Schema: synthese; Owner: -; Tablespace: 
--

CREATE INDEX fki_synthese_bib_proprietaires ON synthesefaune USING btree (id_organisme);


--
-- Name: fki_synthese_bib_protocoles_id; Type: INDEX; Schema: synthese; Owner: -; Tablespace: 
--

CREATE INDEX fki_synthese_bib_protocoles_id ON synthesefaune USING btree (id_protocole);


--
-- Name: fki_synthese_id_taxon_fkey; Type: INDEX; Schema: synthese; Owner: -; Tablespace: 
--

CREATE INDEX fki_synthese_id_taxon_fkey ON synthesefaune USING btree (id_taxon);


--
-- Name: fki_synthese_insee_fkey; Type: INDEX; Schema: synthese; Owner: -; Tablespace: 
--

CREATE INDEX fki_synthese_insee_fkey ON synthesefaune USING btree (insee);


--
-- Name: fki_synthese_t_protocoles_code; Type: INDEX; Schema: synthese; Owner: -; Tablespace: 
--

CREATE INDEX fki_synthese_t_protocoles_code ON synthesefaune USING btree (codeprotocole);


--
-- Name: fki_synthesefaune_bib_sources; Type: INDEX; Schema: synthese; Owner: -; Tablespace: 
--

CREATE INDEX fki_synthesefaune_bib_sources ON synthesefaune USING btree (id_source);


--
-- Name: i_fk_cor_cor_zonesstatut_synthese_l_zonesstatut; Type: INDEX; Schema: synthese; Owner: -; Tablespace: 
--

CREATE INDEX i_fk_cor_cor_zonesstatut_synthese_l_zonesstatut ON cor_zonesstatut_synthese USING btree (id_zone);


--
-- Name: i_fk_cor_unite_synthese_l_unites; Type: INDEX; Schema: synthese; Owner: -; Tablespace: 
--

CREATE INDEX i_fk_cor_unite_synthese_l_unites ON cor_unite_synthese USING btree (id_unite_geo);


--
-- Name: i_fk_cor_unite_synthese_synthesefaune; Type: INDEX; Schema: synthese; Owner: -; Tablespace: 
--

CREATE INDEX i_fk_cor_unite_synthese_synthesefaune ON cor_unite_synthese USING btree (id_synthese);


--
-- Name: i_synthese_cd_nom; Type: INDEX; Schema: synthese; Owner: -; Tablespace: 
--

CREATE INDEX i_synthese_cd_nom ON synthesefaune USING btree (cd_nom);


--
-- Name: i_synthese_dateobs; Type: INDEX; Schema: synthese; Owner: -; Tablespace: 
--

CREATE INDEX i_synthese_dateobs ON synthesefaune USING btree (dateobs DESC);


--
-- Name: i_synthese_id_lot; Type: INDEX; Schema: synthese; Owner: -; Tablespace: 
--

CREATE INDEX i_synthese_id_lot ON synthesefaune USING btree (id_lot);


--
-- Name: index_gist_synthese_the_geom_point; Type: INDEX; Schema: synthese; Owner: -; Tablespace: 
--

CREATE INDEX index_gist_synthese_the_geom_point ON synthesefaune USING gist (the_geom_point);


SET search_path = taxonomie, pg_catalog;

--
-- Index: taxonomie.i_taxref_hierarchy
--

CREATE INDEX i_taxref_hierarchy
  ON taxonomie.taxref
  USING btree
  (regne COLLATE pg_catalog."default" , phylum COLLATE pg_catalog."default" , classe COLLATE pg_catalog."default" , ordre COLLATE pg_catalog."default" , famille COLLATE pg_catalog."default" );
  
--
-- Name: fki_bib_taxons_bib_groupes; Type: INDEX; Schema: taxonomie; Owner: -; Tablespace: 
--

CREATE INDEX fki_bib_taxons_bib_groupes ON bib_taxons USING btree (id_groupe);


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


SET search_path = synthese, pg_catalog;

--
-- Name: tri_insert_synthesefaune; Type: TRIGGER; Schema: synthese; Owner: -
--

CREATE TRIGGER tri_insert_synthesefaune BEFORE INSERT ON synthesefaune FOR EACH ROW EXECUTE PROCEDURE insert_synthesefaune();


--
-- Name: tri_maj_cor_unite_synthese; Type: TRIGGER; Schema: synthese; Owner: -
--

CREATE TRIGGER tri_maj_cor_unite_synthese AFTER INSERT OR DELETE OR UPDATE ON synthesefaune FOR EACH ROW EXECUTE PROCEDURE maj_cor_unite_synthese();


--
-- Name: tri_maj_cor_unite_taxon; Type: TRIGGER; Schema: synthese; Owner: -
--

CREATE TRIGGER tri_maj_cor_unite_taxon AFTER INSERT OR DELETE ON cor_unite_synthese FOR EACH ROW EXECUTE PROCEDURE maj_cor_unite_taxon();


--
-- Name: tri_maj_cor_zonesstatut_synthese; Type: TRIGGER; Schema: synthese; Owner: -
--

CREATE TRIGGER tri_maj_cor_zonesstatut_synthese AFTER INSERT OR DELETE OR UPDATE ON synthesefaune FOR EACH ROW EXECUTE PROCEDURE maj_cor_zonesstatut_synthese();


--
-- Name: tri_update_synthesefaune; Type: TRIGGER; Schema: synthese; Owner: -
--

CREATE TRIGGER tri_update_synthesefaune BEFORE UPDATE ON synthesefaune FOR EACH ROW EXECUTE PROCEDURE update_synthesefaune();


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
-- Name: fk_cor_unite_synthese_synthesefaune; Type: FK CONSTRAINT; Schema: synthese; Owner: -
--

ALTER TABLE ONLY cor_unite_synthese
    ADD CONSTRAINT fk_cor_unite_synthese_synthesefaune FOREIGN KEY (id_synthese) REFERENCES synthesefaune(id_synthese) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_cor_zonesstatut_synthese_synthesefaune; Type: FK CONSTRAINT; Schema: synthese; Owner: -
--

ALTER TABLE ONLY cor_zonesstatut_synthese
    ADD CONSTRAINT fk_cor_zonesstatut_synthese_synthesefaune FOREIGN KEY (id_synthese) REFERENCES synthesefaune(id_synthese) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fk_synthese_bib_organismes; Type: FK CONSTRAINT; Schema: synthese; Owner: -
--

ALTER TABLE ONLY synthesefaune
    ADD CONSTRAINT fk_synthese_bib_organismes FOREIGN KEY (id_organisme) REFERENCES utilisateurs.bib_organismes(id_organisme) ON UPDATE CASCADE;


--
-- Name: synthese_id_critere_synthese_fkey; Type: FK CONSTRAINT; Schema: synthese; Owner: -
--

ALTER TABLE ONLY synthesefaune
    ADD CONSTRAINT synthese_id_critere_synthese_fkey FOREIGN KEY (id_critere_synthese) REFERENCES bib_criteres_synthese(id_critere_synthese) ON UPDATE CASCADE;


--
-- Name: synthese_id_lot_fkey; Type: FK CONSTRAINT; Schema: synthese; Owner: -
--

ALTER TABLE ONLY synthesefaune
    ADD CONSTRAINT synthese_id_lot_fkey FOREIGN KEY (id_lot) REFERENCES meta.bib_lots(id_lot) ON UPDATE CASCADE;


--
-- Name: synthese_id_precision_fkey; Type: FK CONSTRAINT; Schema: synthese; Owner: -
--

ALTER TABLE ONLY synthesefaune
    ADD CONSTRAINT synthese_id_precision_fkey FOREIGN KEY (id_precision) REFERENCES meta.t_precisions(id_precision) ON UPDATE CASCADE;


--
-- Name: synthese_id_protocole_fkey; Type: FK CONSTRAINT; Schema: synthese; Owner: -
--

ALTER TABLE ONLY synthesefaune
    ADD CONSTRAINT synthese_id_protocole_fkey FOREIGN KEY (id_protocole) REFERENCES meta.t_protocoles(id_protocole) ON UPDATE CASCADE;


--
-- Name: synthese_id_source_fkey; Type: FK CONSTRAINT; Schema: synthese; Owner: -
--

ALTER TABLE ONLY synthesefaune
    ADD CONSTRAINT synthese_id_source_fkey FOREIGN KEY (id_source) REFERENCES bib_sources(id_source) ON UPDATE CASCADE;


--
-- Name: synthese_id_taxon_fkey; Type: FK CONSTRAINT; Schema: synthese; Owner: -
--

ALTER TABLE ONLY synthesefaune
    ADD CONSTRAINT synthese_id_taxon_fkey FOREIGN KEY (id_taxon) REFERENCES taxonomie.bib_taxons(id_taxon) ON UPDATE CASCADE;


SET search_path = taxonomie, pg_catalog;

--
-- Name: bib_taxons_id_responsabilite_fkey; Type: FK CONSTRAINT; Schema: taxonomie; Owner: -
--

ALTER TABLE ONLY bib_taxons
    ADD CONSTRAINT bib_taxons_id_responsabilite_fkey FOREIGN KEY (id_responsabilite_pn) REFERENCES bib_responsabilites_pn(id_responsabilite_pn) ON UPDATE CASCADE;


--
-- Name: bib_taxons_id_groupe_fkey; Type: FK CONSTRAINT; Schema: taxonomie; Owner: -
--

ALTER TABLE ONLY bib_taxons
    ADD CONSTRAINT bib_taxons_id_groupe_fkey FOREIGN KEY (id_groupe) REFERENCES bib_groupes(id_groupe) ON UPDATE CASCADE;


--
-- Name: bib_taxons_id_importance_pop_fkey; Type: FK CONSTRAINT; Schema: taxonomie; Owner: -
--

ALTER TABLE ONLY bib_taxons
    ADD CONSTRAINT bib_taxons_id_importance_pop_fkey FOREIGN KEY (id_importance_population) REFERENCES bib_importances_population(id_importance_population) ON UPDATE CASCADE;


--
-- Name: bib_taxons_id_migration_fkey; Type: FK CONSTRAINT; Schema: taxonomie; Owner: -
--

ALTER TABLE ONLY bib_taxons
    ADD CONSTRAINT bib_taxons_id_migration_fkey FOREIGN KEY (id_statut_migration) REFERENCES bib_statuts_migration(id_statut_migration) ON UPDATE CASCADE;

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
-- Name: insert_synthesefaune(); Type: ACL; Schema: synthese; Owner: -
--

REVOKE ALL ON FUNCTION insert_synthesefaune() FROM PUBLIC;
REVOKE ALL ON FUNCTION insert_synthesefaune() FROM geonatuser;
GRANT ALL ON FUNCTION insert_synthesefaune() TO geonatuser;
GRANT ALL ON FUNCTION insert_synthesefaune() TO PUBLIC;


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
-- Name: update_synthesefaune(); Type: ACL; Schema: synthese; Owner: -
--

REVOKE ALL ON FUNCTION update_synthesefaune() FROM PUBLIC;
REVOKE ALL ON FUNCTION update_synthesefaune() FROM geonatuser;
GRANT ALL ON FUNCTION update_synthesefaune() TO geonatuser;
GRANT ALL ON FUNCTION update_synthesefaune() TO PUBLIC;


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
-- Name: synthesefaune; Type: ACL; Schema: synthese; Owner: -
--

REVOKE ALL ON TABLE synthesefaune FROM PUBLIC;
REVOKE ALL ON TABLE synthesefaune FROM geonatuser;
GRANT ALL ON TABLE synthesefaune TO geonatuser;


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
-- Name: bib_importances_population; Type: ACL; Schema: taxonomie; Owner: -
--

REVOKE ALL ON TABLE bib_importances_population FROM PUBLIC;
REVOKE ALL ON TABLE bib_importances_population FROM geonatuser;
GRANT ALL ON TABLE bib_importances_population TO geonatuser;


--
-- Name: bib_responsabilites_pn; Type: ACL; Schema: taxonomie; Owner: -
--

REVOKE ALL ON TABLE bib_responsabilites_pn FROM PUBLIC;
REVOKE ALL ON TABLE bib_responsabilites_pn FROM geonatuser;
GRANT ALL ON TABLE bib_responsabilites_pn TO geonatuser;


--
-- Name: bib_statuts_migration; Type: ACL; Schema: taxonomie; Owner: -
--

REVOKE ALL ON TABLE bib_statuts_migration FROM PUBLIC;
REVOKE ALL ON TABLE bib_statuts_migration FROM geonatuser;
GRANT ALL ON TABLE bib_statuts_migration TO geonatuser;


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

