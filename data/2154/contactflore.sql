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
-- TOC entry 18 (class 2615 OID 1387972)
-- Name: contactflore; Type: SCHEMA; Schema: -;
--

CREATE SCHEMA contactflore;


SET search_path = contactflore, pg_catalog;

--
-- TOC entry 1504 (class 1255 OID 1388146)
-- Name: couleur_taxon(integer, date); Type: FUNCTION; Schema: contactflore;
--

CREATE OR REPLACE FUNCTION couleur_taxon(id integer, maxdateobs date)
  RETURNS text AS
$BODY$
  --fonction permettant de renvoyer la couleur d'un taxon à partir de la dernière date d'observation 
  DECLARE
  couleur text;
  patri character(3);
  BEGIN
    SELECT cta.valeur_attribut INTO patri 
    FROM taxonomie.bib_noms n
    JOIN taxonomie.cor_taxon_attribut cta ON cta.cd_ref = n.cd_nom AND cta.id_attribut = 1
    WHERE n.id_nom = id;
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
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

-- Function: contactflore.calcul_cor_unite_taxon_cflore(integer, integer)
-- DROP FUNCTION contactflore.calcul_cor_unite_taxon_cflore(integer, integer);
CREATE OR REPLACE FUNCTION calcul_cor_unite_taxon_cflore(
    monidtaxon integer,
    monunite integer)
  RETURNS void AS
$BODY$
  DECLARE
  cdnom integer;
  BEGIN
	--récup du cd_nom du taxon
	SELECT INTO cdnom cd_nom FROM taxonomie.bib_noms WHERE id_nom = monidtaxon;
	DELETE FROM contactflore.cor_unite_taxon_cflore WHERE id_unite_geo = monunite AND id_nom = monidtaxon;
	INSERT INTO contactflore.cor_unite_taxon_cflore (id_unite_geo,id_nom,derniere_date,couleur,nb_obs)
	SELECT monunite, monidtaxon,  max(dateobs) AS derniere_date, contactflore.couleur_taxon(monidtaxon,max(dateobs)) AS couleur, count(id_synthese) AS nb_obs
	FROM synthese.cor_unite_synthese
	WHERE cd_nom = cdnom
	AND id_unite_geo = monunite;
  END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

--
-- TOC entry 1496 (class 1255 OID 1387973)
-- Name: insert_fiche_cflore(); Type: FUNCTION; Schema: contactflore;
--

CREATE FUNCTION insert_fiche_cflore() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
macommune character(5);
BEGIN
------- si le pointage est deja dans la BDD alors le trigger retourne null (l'insertion de la ligne est annulée).
IF new.id_cflore in (SELECT id_cflore FROM contactflore.t_fiches_cflore) THEN	
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
-- TOC entry 1497 (class 1255 OID 1387974)
-- Name: insert_releve_cflore(); Type: FUNCTION; Schema: contactflore;
--

CREATE OR REPLACE FUNCTION insert_releve_cflore() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
cdnom integer;
re integer;
unite integer;
nbobs integer;
line record;
fiche record;
BEGIN
    --récup du cd_nom du taxon
	SELECT INTO cdnom cd_nom FROM taxonomie.bib_noms WHERE id_nom = new.id_nom;
    --récup du cd_ref du taxon pour le stocker en base au moment de l'enregistrement (= conseil inpn)
	SELECT INTO re taxonomie.find_cdref(cd_nom) FROM taxonomie.bib_noms WHERE id_nom = new.id_nom;
	new.cd_ref_origine = re;
    -- MAJ de la table cor_unite_taxon_cflore, on commence par récupérer l'unité à partir du pointage (table t_fiches_cf)
	SELECT INTO fiche * FROM contactflore.t_fiches_cflore WHERE id_cflore = new.id_cflore;
	SELECT INTO unite u.id_unite_geo FROM layers.l_unites_geo u WHERE ST_INTERSECTS(fiche.the_geom_2154,u.the_geom);
	--si on est dans une des unités on peut mettre à jour la table cor_unite_taxon_cflore, sinon on fait rien
	IF unite>0 THEN
		SELECT INTO line * FROM contactflore.cor_unite_taxon_cflore WHERE id_unite_geo = unite AND id_nom = new.id_nom;
		--si la ligne existe dans cor_unite_taxon_cflore on la supprime
		IF line IS NOT NULL THEN
			DELETE FROM contactflore.cor_unite_taxon_cflore WHERE id_unite_geo = unite AND id_nom = new.id_nom;
		END IF;
		--on compte le nombre d'enregistrement pour ce taxon dans l'unité
		SELECT INTO nbobs count(*) from synthese.syntheseff s
		JOIN layers.l_unites_geo u ON ST_Intersects(u.the_geom, s.the_geom_2154) AND u.id_unite_geo = unite
		WHERE s.cd_nom = cdnom;
		--on créé ou recréé la ligne
		INSERT INTO contactflore.cor_unite_taxon_cflore VALUES(unite,new.id_nom,fiche.dateobs,contactflore.couleur_taxon(new.id_nom,fiche.dateobs), nbobs+1);
	END IF;
	RETURN NEW; 			
END;
$$;


--
-- TOC entry 1498 (class 1255 OID 1387975)
-- Name: synthese_delete_releve_cflore(); Type: FUNCTION; Schema: contactflore;
--

CREATE OR REPLACE FUNCTION synthese_delete_releve_cflore()
  RETURNS trigger AS
$BODY$
DECLARE
    idsource integer;
    nbreleves integer;
BEGIN
    --SUPRESSION EN SYNTHESE
    SELECT INTO idsource id_source FROM synthese.bib_sources  WHERE db_schema='contactflore' AND db_field = 'id_releve_cflore' ;
    DELETE FROM synthese.syntheseff WHERE id_source = idsource AND id_fiche_source = old.id_releve_cflore::text; 
    -- SUPPRESSION DE LA FICHE S'IL N'Y A PLUS DE RELEVE
    SELECT INTO nbreleves count(*) FROM contactflore.t_releves_cflore WHERE id_cflore = old.id_releve_cflore;
    IF nbreleves < 1 THEN
        DELETE FROM contactflore.t_fiches_cflore WHERE id_cflore = old.id_releve_cflore;
    END IF;
    RETURN OLD; 
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;


--
-- TOC entry 1505 (class 1255 OID 1387976)
-- Name: synthese_insert_releve_cflore(); Type: FUNCTION; Schema: contactflore;
--

CREATE FUNCTION synthese_insert_releve_cflore() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
	fiche RECORD;
	mesobservateurs character varying(255);
	idsourcecflore integer;
    cdnom integer;
BEGIN
	--Récupération des données id_source dans la table synthese.bib_sources
	SELECT INTO idsourcecflore id_source FROM synthese.bib_sources  WHERE db_schema='contactflore' AND db_field = 'id_releve_cflore' AND nom_source = 'Contact flore';
    --récup du cd_nom du taxon
	SELECT INTO cdnom cd_nom FROM taxonomie.bib_noms WHERE id_nom = new.id_nom;
	--Récupération des données dans la table t_fiches_cf et de la liste des observateurs
	SELECT INTO fiche * FROM contactflore.t_fiches_cflore WHERE id_cflore = new.id_cflore;
	
	SELECT INTO mesobservateurs o.observateurs FROM contactflore.t_releves_cflore r
	JOIN contactflore.t_fiches_cflore f ON f.id_cflore = r.id_cflore
	LEFT JOIN (
                SELECT id_cflore, array_to_string(array_agg(r.nom_role || ' ' || r.prenom_role), ', ') AS observateurs 
                FROM contactflore.cor_role_fiche_cflore c
                JOIN utilisateurs.t_roles r ON r.id_role = c.id_role
                GROUP BY id_cflore
            ) o ON o.id_cflore = f.id_cflore
	WHERE r.id_releve_cflore = new.id_releve_cflore;
	
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
		id_lot
	)
	VALUES(
	idsourcecflore,
	new.id_releve_cflore,
	'f'||new.id_cflore||'-r'||new.id_releve_cflore,
	fiche.id_organisme,
	fiche.id_protocole,
	1,
	cdnom,
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
	fiche.id_lot
	);
	RETURN NEW; 			
END;
$$;


--
-- TOC entry 1499 (class 1255 OID 1387977)
-- Name: synthese_update_cor_role_fiche_cflore(); Type: FUNCTION; Schema: contactflore;
--

CREATE FUNCTION synthese_update_cor_role_fiche_cflore() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    releves RECORD;
    test integer;
    mesobservateurs character varying(255);
    sources RECORD;
    idsource integer;
    idsourcecflore integer;
BEGIN
    --
    --CE TRIGGER NE DEVRAIT SERVIR QU'EN CAS DE MISE A JOUR MANUELLE SUR CETTE TABLE cor_role_fiche_cf
    --L'APPLI WEB ET LES TABLETTES NE FONT QUE DES INSERTS QUI SONT GERER PAR LE TRIGGER INSERT DE t_releves_cf
    --
        --on doit boucler pour récupérer le id_source car il y en a 2 possibles (cf et mortalité) pour le même schéma
    FOR sources IN SELECT id_source, url  FROM synthese.bib_sources WHERE db_schema='contactflore' AND db_field = 'id_releve_cflore' LOOP
        IF sources.url = 'cflore' THEN
            idsourcecflore = sources.id_source;
        END IF;
    END LOOP;
    
    --Récupération des enregistrements de la table t_releves_cf avec l'id_cf de la table cor_role_fiche_cf
    FOR releves IN SELECT * FROM contactflore.t_releves_cflore WHERE id_cflore = new.id_cflore LOOP
        --test si on a bien l'enregistrement dans la table syntheseff avant de le mettre à jour
        SELECT INTO test id_fiche_source FROM synthese.syntheseff 
        WHERE (id_source = idsourcecflore) AND id_fiche_source = releves.id_releve_cflore::text;
        IF test ISNULL THEN
            RETURN null;
        ELSE
            SELECT INTO mesobservateurs o.observateurs FROM contactflore.t_releves_cflore r
            JOIN contactflore.t_fiches_cflore f ON f.id_cflore = r.id_cflore
            LEFT JOIN (
                SELECT id_cflore, array_to_string(array_agg(r.nom_role || ' ' || r.prenom_role), ', ') AS observateurs 
                FROM contactflore.cor_role_fiche_cflore c
                JOIN utilisateurs.t_roles r ON r.id_role = c.id_role
                GROUP BY id_cflore
            ) o ON o.id_cflore = f.id_cflore
            WHERE r.id_releve_cflore = releves.id_releve_cflore;
            --mise à jour de l'enregistrement correspondant dans syntheseff ; uniquement le champ observateurs ici
            UPDATE synthese.syntheseff SET
                observateurs = mesobservateurs
            WHERE (id_source = idsourcecflore) AND id_fiche_source = releves.id_releve_cflore::text; 
        END IF;
    END LOOP;
    RETURN NEW; 
END;
$$;


--
-- TOC entry 1500 (class 1255 OID 1387978)
-- Name: synthese_update_fiche_cflore(); Type: FUNCTION; Schema: contactflore;
--

CREATE OR REPLACE FUNCTION synthese_update_fiche_cflore()
  RETURNS trigger AS
$BODY$
DECLARE
    releves RECORD;
    test integer;
    mesobservateurs character varying(255);
    sources RECORD;
    idsourcecflore integer;
BEGIN

    --on doit boucler pour récupérer le id_source car il y en a 2 possibles (cf et mortalité) pour le même schéma
    FOR sources IN SELECT id_source, url  FROM synthese.bib_sources WHERE db_schema='contactflore' AND db_field = 'id_releve_cflore' LOOP
	IF sources.url = 'cflore' THEN
	    idsourcecflore = sources.id_source;
	END IF;
    END LOOP;
	--Récupération des données de la table t_releves_cf avec l'id_cf de la fiche modifié
	-- Ici on utilise le OLD id_cf pour être sur qu'il existe dans la table synthese (cas improbable où on changerait la pk de la table t_fiches_cf
	--le trigger met à jour avec le NEW --> SET code_fiche_source =  ....
	FOR releves IN SELECT * FROM contactflore.t_releves_cflore WHERE id_cflore = old.id_cflore LOOP
		--test si on a bien l'enregistrement dans la table syntheseff avant de le mettre à jour
		SELECT INTO test id_fiche_source FROM synthese.syntheseff WHERE id_fiche_source = releves.id_releve_cflore::text AND (id_source = idsourcecflore);
		IF test IS NOT NULL THEN
			SELECT INTO mesobservateurs o.observateurs FROM contactflore.t_releves_cflore r
			JOIN contactflore.t_fiches_cflore f ON f.id_cflore = r.id_cflore
			LEFT JOIN (
				SELECT id_cflore, array_to_string(array_agg(r.nom_role || ' ' || r.prenom_role), ', ') AS observateurs 
				FROM contactflore.cor_role_fiche_cflore c
				JOIN utilisateurs.t_roles r ON r.id_role = c.id_role
				GROUP BY id_cflore
			) o ON o.id_cflore = f.id_cflore
			WHERE r.id_releve_cflore = releves.id_releve_cflore;
			IF NOT St_Equals(new.the_geom_3857,old.the_geom_3857) OR NOT St_Equals(new.the_geom_2154,old.the_geom_2154) THEN
				
				--mise à jour de l'enregistrement correspondant dans syntheseff
				UPDATE synthese.syntheseff SET
				code_fiche_source = 'f'||new.id_cflore||'-r'||releves.id_releve_cflore,
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
				WHERE id_fiche_source = releves.id_releve_cflore::text AND (id_source = idsourcecflore) ;
			ELSE
				--mise à jour de l'enregistrement correspondant dans syntheseff
				UPDATE synthese.syntheseff SET
				code_fiche_source = 'f'||new.id_cflore||'-r'||releves.id_releve_cflore,
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
			    WHERE id_fiche_source = releves.id_releve_cflore::text AND (id_source = idsourcecflore);
			END IF;
		END IF;
	END LOOP;
	RETURN NEW; 			
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;


--
-- TOC entry 1501 (class 1255 OID 1387979)
-- Name: synthese_update_releve_cflore(); Type: FUNCTION; Schema: contactflore;
--

CREATE OR REPLACE FUNCTION synthese_update_releve_cflore()
  RETURNS trigger AS
$BODY$
DECLARE
    test integer;
    sources RECORD;
    idsourcecflore integer;
    cdnom integer;
    nbreleves integer;
BEGIN
    
	--Récupération des données id_source dans la table synthese.bib_sources
    SELECT INTO idsourcecflore id_source FROM synthese.bib_sources  WHERE db_schema='contactflore' AND db_field = 'id_releve_cflore';
	--récup du cd_nom du taxon
	SELECT INTO cdnom cd_nom FROM taxonomie.bib_noms WHERE id_nom = new.id_nom;
	--test si on a bien l'enregistrement dans la table syntheseff avant de le mettre à jour
	--test si on a bien l'enregistrement dans la table syntheseff avant de le mettre à jour
	SELECT INTO test id_fiche_source FROM synthese.syntheseff WHERE id_fiche_source = old.id_releve_cflore::text AND (id_source = idsourcecflore);
	IF test IS NOT NULL THEN
		

		--mise à jour de l'enregistrement correspondant dans syntheseff
		UPDATE synthese.syntheseff SET
			id_fiche_source = new.id_releve_cflore,
			code_fiche_source = 'f'||new.id_cflore||'-r'||new.id_releve_cflore,
			cd_nom = cdnom,
			remarques = new.commentaire,
			determinateur = new.determinateur,
			derniere_action = 'u',
			supprime = new.supprime
		WHERE id_fiche_source = old.id_releve_cflore::text AND (id_source = idsourcecflore); -- Ici on utilise le OLD id_releve_cflore pour être sur 
		--qu'il existe dans la table synthese (cas improbable où on changerait la pk de la table t_releves_cflore
		--le trigger met à jour avec le NEW --> SET id_fiche_source = new.id_releve_cflore
	END IF;
	-- SUPPRESSION (supprime = true) DE LA FICHE S'IL N'Y A PLUS DE RELEVE (supprime = false)
	SELECT INTO nbreleves count(*) FROM contactflore.t_releves_cflore WHERE id_cflore = new.id_cflore AND supprime = false;
	IF nbreleves < 1 THEN
		UPDATE contactflore.t_fiches_cflore SET supprime = true WHERE id_cflore = new.id_cflore;
	END IF;
	RETURN NEW; 			
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;


--
-- TOC entry 1502 (class 1255 OID 1387980)
-- Name: update_fiche_cflore(); Type: FUNCTION; Schema: contactflore;
--

CREATE FUNCTION update_fiche_cflore() RETURNS trigger
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
     update contactflore.t_releves_cflore set supprime = 't' WHERE id_cflore = old.id_cflore; 
  END IF;
  IF new.supprime = 'f' THEN
     update contactflore.t_releves_cflore set supprime = 'f' WHERE id_cflore = old.id_cflore; 
  END IF;
END IF;
RETURN NEW; 
END;
$$;


--
-- TOC entry 1503 (class 1255 OID 1387981)
-- Name: update_releve_cflore(); Type: FUNCTION; Schema: contactflore;
--

CREATE OR REPLACE FUNCTION update_releve_cflore() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
	re integer;
BEGIN
   -- Si changement de taxon, 
	IF new.id_nom<>old.id_nom THEN
	   -- Correction du cd_ref_origine
		SELECT INTO re taxonomie.find_cdref(cd_nom) FROM taxonomie.bib_noms WHERE id_nom = new.id_nom;
		new.cd_ref_origine = re;
	END IF;
RETURN NEW;			
END;
$$;


-- Function: contactflore.maj_cor_unite_taxon_cflore()
-- DROP FUNCTION contactflore.maj_cor_unite_taxon_cflore();
CREATE OR REPLACE FUNCTION maj_cor_unite_taxon_cflore()
  RETURNS trigger AS
$BODY$
DECLARE
monembranchement varchar;
monregne varchar;
monidtaxon integer;
BEGIN
	IF (TG_OP = 'DELETE') THEN
		--retrouver le id_nom
		SELECT INTO monidtaxon id_nom FROM taxonomie.bib_noms WHERE cd_nom = old.cd_nom LIMIT 1; 
		--calcul du règne du taxon supprimé
		SELECT  INTO monregne tx.regne FROM taxonomie.taxref tx WHERE tx.cd_nom = old.cd_nom;
		IF monregne = 'Plantae' THEN
			IF (SELECT count(*) FROM synthese.cor_unite_synthese WHERE cd_nom = old.cd_nom AND id_unite_geo = old.id_unite_geo)= 0 THEN
				DELETE FROM contactflore.cor_unite_taxon_cflore WHERE id_nom = monidtaxon AND id_unite_geo = old.id_unite_geo;
			ELSE
				PERFORM contactflore.calcul_cor_unite_taxon_cflore(monidtaxon, old.id_unite_geo);
			END IF;
		END IF;
		RETURN OLD;		
		
	ELSIF (TG_OP = 'INSERT') THEN
		--retrouver le id_nom
		SELECT INTO monidtaxon id_nom FROM taxonomie.bib_noms WHERE cd_nom = new.cd_nom LIMIT 1;
		--calcul du règne du taxon inséré
			SELECT  INTO monregne tx.regne FROM taxonomie.taxref tx WHERE tx.cd_nom = new.cd_nom;
		IF monregne = 'Plantae' THEN
			PERFORM contactflore.calcul_cor_unite_taxon_cflore(monidtaxon, new.id_unite_geo);
	    END IF;
		RETURN NEW;
	END IF;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;


SET default_tablespace = '';

SET default_with_oids = false;

--
-- TOC entry 347 (class 1259 OID 1387982)
-- Name: bib_abondances_cflore; Type: TABLE; Schema: contactflore;
--

CREATE TABLE bib_abondances_cflore (
    id_abondance_cflore integer NOT NULL,
    nom_abondance_cflore character varying(25)
);


--
-- TOC entry 358 (class 1259 OID 1388106)
-- Name: bib_messages_cflore; Type: TABLE; Schema: contactflore;
--

CREATE TABLE bib_messages_cflore (
    id_message_cflore integer NOT NULL,
    texte_message_cflore character varying(255)
);


--
-- TOC entry 348 (class 1259 OID 1387985)
-- Name: bib_phenologies_cflore; Type: TABLE; Schema: contactflore;
--

CREATE TABLE bib_phenologies_cflore (
    id_phenologie_cflore integer NOT NULL,
    nom_phenologie_cflore character varying(100)
);


--
-- TOC entry 359 (class 1259 OID 1388111)
-- Name: cor_message_taxon_cflore; Type: TABLE; Schema: contactflore; 
--

CREATE TABLE cor_message_taxon_cflore (
    id_message_cflore integer NOT NULL,
    id_nom integer NOT NULL
);


--
-- TOC entry 360 (class 1259 OID 1388128)
-- Name: cor_role_fiche_cflore; Type: TABLE; Schema: contactflore;
--

CREATE TABLE cor_role_fiche_cflore (
    id_cflore bigint NOT NULL,
    id_role integer NOT NULL
);


--
-- TOC entry 349 (class 1259 OID 1387991)
-- Name: cor_unite_taxon_cflore; Type: TABLE; Schema: contactflore;
--

CREATE TABLE cor_unite_taxon_cflore (
    id_unite_geo integer NOT NULL,
    id_nom integer NOT NULL,
    derniere_date date,
    couleur character varying(10) NOT NULL,
    nb_obs integer
);


--
-- TOC entry 352 (class 1259 OID 1388006)
-- Name: t_fiches_cflore; Type: TABLE; Schema: contactflore; 
--

CREATE TABLE t_fiches_cflore (
    id_cflore bigint NOT NULL,
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
-- TOC entry 353 (class 1259 OID 1388019)
-- Name: t_releves_cflore; Type: TABLE; Schema: contactflore; 
--

CREATE TABLE t_releves_cflore (
    id_releve_cflore bigint NOT NULL,
    id_cflore bigint NOT NULL,
    id_nom integer NOT NULL,
    id_abondance_cflore integer NOT NULL,
    id_phenologie_cflore integer NOT NULL,
    cd_ref_origine integer,
    nom_taxon_saisi character varying(255),
    commentaire text,
    determinateur character varying(255),
    supprime boolean DEFAULT false NOT NULL,
    herbier boolean DEFAULT false NOT NULL,
    gid integer NOT NULL,
    validite_cflore boolean
);


--
-- TOC entry 354 (class 1259 OID 1388027)
-- Name: t_releves_cflore_gid_seq; Type: SEQUENCE; Schema: contactflore;
--

CREATE SEQUENCE t_releves_cflore_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 3897 (class 0 OID 0)
-- Dependencies: 354
-- Name: t_releves_cflore_gid_seq; Type: SEQUENCE OWNED BY; Schema: contactflore;
--

ALTER SEQUENCE t_releves_cflore_gid_seq OWNED BY t_releves_cflore.gid;


--
-- TOC entry 362 (class 1259 OID 1388156)
-- Name: v_nomade_abondances_cflore; Type: VIEW; Schema: contactflore;
--

CREATE VIEW v_nomade_abondances_cflore AS
 SELECT a.id_abondance_cflore,
    a.nom_abondance_cflore
   FROM bib_abondances_cflore a
  ORDER BY a.id_abondance_cflore;


--
-- TOC entry 355 (class 1259 OID 1388029)
-- Name: v_nomade_classes; Type: VIEW; Schema: contactflore;
--

CREATE OR REPLACE VIEW v_nomade_classes AS 
 SELECT g.id_liste AS id_classe,
    g.nom_liste AS nom_classe_fr,
    g.desc_liste AS desc_classe
   FROM ( SELECT l.id_liste,
            l.nom_liste,
            l.desc_liste,
            min(taxonomie.find_cdref(n.cd_nom)) AS cd_ref
           FROM taxonomie.bib_listes l
             JOIN taxonomie.cor_nom_liste cnl ON cnl.id_liste = l.id_liste
             JOIN taxonomie.bib_noms n ON n.id_nom = cnl.id_nom
          WHERE l.id_liste > 300 AND l.id_liste < 400
          GROUP BY l.id_liste, l.nom_liste, l.desc_liste) g
     JOIN taxonomie.taxref t ON t.cd_nom = g.cd_ref
  WHERE t.regne::text = 'Plantae'::text;


--
-- TOC entry 356 (class 1259 OID 1388034)
-- Name: v_nomade_observateurs_flore; Type: VIEW; Schema: contactflore;
--

CREATE VIEW v_nomade_observateurs_flore AS
 SELECT DISTINCT r.id_role,
    r.nom_role,
    r.prenom_role
   FROM utilisateurs.t_roles r
  WHERE ((r.id_role IN ( SELECT DISTINCT cr.id_role_utilisateur
           FROM utilisateurs.cor_roles cr
          WHERE (cr.id_role_groupe IN ( SELECT crm.id_role
                   FROM utilisateurs.cor_role_menu crm
                  WHERE (crm.id_menu = 10)))
          ORDER BY cr.id_role_utilisateur)) OR (r.id_role IN ( SELECT crm.id_role
           FROM (utilisateurs.cor_role_menu crm
             JOIN utilisateurs.t_roles r_1 ON ((((r_1.id_role = crm.id_role) AND (crm.id_menu = 9)) AND (r_1.groupe = false)))))))
  ORDER BY r.nom_role, r.prenom_role, r.id_role;


--
-- TOC entry 363 (class 1259 OID 1388160)
-- Name: v_nomade_phenologies_cflore; Type: VIEW; Schema: contactflore;
--

CREATE VIEW v_nomade_phenologies_cflore AS
 SELECT p.id_phenologie_cflore,
    p.nom_phenologie_cflore
   FROM bib_phenologies_cflore p
  ORDER BY p.id_phenologie_cflore;


--
-- TOC entry 361 (class 1259 OID 1388147)
-- Name: v_nomade_taxons_flore; Type: VIEW; Schema: contactflore;
--

CREATE OR REPLACE VIEW v_nomade_taxons_flore AS 
  SELECT DISTINCT n.id_nom,
    taxonomie.find_cdref(tx.cd_nom) AS cd_ref,
    tx.cd_nom,
    tx.lb_nom AS nom_latin,
    n.nom_francais,
    g.id_classe,
    f2.bool AS patrimonial,
    m.texte_message_cflore AS message
   FROM taxonomie.bib_noms n
     LEFT JOIN cor_message_taxon_cflore cmt ON cmt.id_nom = n.id_nom
     LEFT JOIN bib_messages_cflore m ON m.id_message_cflore = cmt.id_message_cflore
     LEFT JOIN taxonomie.cor_taxon_attribut cta ON cta.cd_ref = n.cd_ref
     JOIN taxonomie.cor_nom_liste cnl ON cnl.id_nom = n.id_nom 
     JOIN v_nomade_classes g ON g.id_classe = cnl.id_liste
     JOIN taxonomie.taxref tx ON tx.cd_nom = n.cd_nom
     JOIN public.cor_boolean f2 ON f2.expression::text = cta.valeur_attribut AND cta.id_attribut = 1
   WHERE n.id_nom IN(SELECT id_nom FROM taxonomie.cor_nom_liste WHERE id_liste = 500)
   ORDER BY n.id_nom, taxonomie.find_cdref(tx.cd_nom), tx.lb_nom, n.nom_francais, g.id_classe, f2.bool, m.texte_message_cflore;


--
-- TOC entry 357 (class 1259 OID 1388044)
-- Name: v_nomade_unites_geo_cflore; Type: VIEW; Schema:
--

CREATE VIEW v_nomade_unites_geo_cflore AS
 SELECT public.st_simplifypreservetopology(l_unites_geo.the_geom, (15)::double precision) AS the_geom,
    l_unites_geo.id_unite_geo
   FROM layers.l_unites_geo
  GROUP BY l_unites_geo.the_geom, l_unites_geo.id_unite_geo;


--
-- TOC entry 3680 (class 2604 OID 1388048)
-- Name: gid; Type: DEFAULT; Schema: contactflore;
--

ALTER TABLE ONLY t_releves_cflore ALTER COLUMN gid SET DEFAULT nextval('t_releves_cflore_gid_seq'::regclass);


--
-- TOC entry 3900 (class 0 OID 0)
-- Dependencies: 354
-- Name: t_releves_cflore_gid_seq; Type: SEQUENCE SET; Schema: contactflore;
--

SELECT pg_catalog.setval('t_releves_cflore_gid_seq', 1, true);


--
-- TOC entry 3682 (class 2606 OID 1388050)
-- Name: bib_abondance_cflore_pkey; Type: CONSTRAINT; Schema: contactflore;
--

ALTER TABLE ONLY bib_abondances_cflore
    ADD CONSTRAINT bib_abondance_cflore_pkey PRIMARY KEY (id_abondance_cflore);


--
-- TOC entry 3684 (class 2606 OID 1388052)
-- Name: bib_phenologie_cflore_pkey; Type: CONSTRAINT; Schema: contactflore; Owner: 
--

ALTER TABLE ONLY bib_phenologies_cflore
    ADD CONSTRAINT bib_phenologie_cflore_pkey PRIMARY KEY (id_phenologie_cflore);


--
-- TOC entry 3686 (class 2606 OID 1388056)
-- Name: cor_unite_taxon_cflore_pkey; Type: CONSTRAINT; Schema: contactflore;
--

ALTER TABLE ONLY cor_unite_taxon_cflore
    ADD CONSTRAINT cor_unite_taxon_cflore_pkey PRIMARY KEY (id_unite_geo, id_nom);


--
-- TOC entry 3693 (class 2606 OID 1388110)
-- Name: pk_bib_messages_cflore; Type: CONSTRAINT; Schema: contactflore; 
--

ALTER TABLE ONLY bib_messages_cflore
    ADD CONSTRAINT pk_bib_messages_cflore PRIMARY KEY (id_message_cflore);


--
-- TOC entry 3697 (class 2606 OID 1388115)
-- Name: pk_cor_message_taxon_cflore; Type: CONSTRAINT; Schema: contactflore; 
--

ALTER TABLE ONLY cor_message_taxon_cflore
    ADD CONSTRAINT pk_cor_message_taxon_cflore PRIMARY KEY (id_message_cflore, id_nom);


--
-- TOC entry 3701 (class 2606 OID 1388132)
-- Name: pk_cor_role_fiche_cflore; Type: CONSTRAINT; Schema: contactflore; 
--

ALTER TABLE ONLY cor_role_fiche_cflore
    ADD CONSTRAINT pk_cor_role_fiche_cflore PRIMARY KEY (id_cflore, id_role);


--
-- TOC entry 3689 (class 2606 OID 1388058)
-- Name: pk_t_fiches_cflore; Type: CONSTRAINT; Schema: contactflore; 
--

ALTER TABLE ONLY t_fiches_cflore
    ADD CONSTRAINT pk_t_fiches_cflore PRIMARY KEY (id_cflore);


--
-- TOC entry 3691 (class 2606 OID 1388190)
-- Name: t_releves_cflore_pkey; Type: CONSTRAINT; Schema: contactflore; 
--

ALTER TABLE ONLY t_releves_cflore
    ADD CONSTRAINT t_releves_cflore_pkey PRIMARY KEY (id_releve_cflore);


--
-- TOC entry 3694 (class 1259 OID 1388126)
-- Name: i_fk_cor_message_cflore_bib_me; Type: INDEX; Schema: contactflore; 
--

CREATE INDEX i_fk_cor_message_cflore_bib_me ON cor_message_taxon_cflore USING btree (id_message_cflore);


--
-- TOC entry 3695 (class 1259 OID 1388127)
-- Name: i_fk_cor_message_cflore_bib_ta; Type: INDEX; Schema: contactflore; 
--

CREATE INDEX i_fk_cor_message_cflore_bib_noms ON cor_message_taxon_cflore USING btree (id_nom);


--
-- TOC entry 3698 (class 1259 OID 1388143)
-- Name: i_fk_cor_role_fiche_cflore_t_fiche; Type: INDEX; Schema: contactflore; 
--

CREATE INDEX i_fk_cor_role_fiche_cflore_t_fiche ON cor_role_fiche_cflore USING btree (id_cflore);


--
-- TOC entry 3699 (class 1259 OID 1388144)
-- Name: i_fk_cor_role_fiche_cflore_t_roles; Type: INDEX; Schema: contactflore; 
--

CREATE INDEX i_fk_cor_role_fiche_cflore_t_roles ON cor_role_fiche_cflore USING btree (id_role);


--
-- TOC entry 3687 (class 1259 OID 1388078)
-- Name: i_fk_t_fiches_cflore_l_communes; Type: INDEX; Schema: contactflore; 
--

CREATE INDEX i_fk_t_fiches_cflore_l_communes ON t_fiches_cflore USING btree (insee);


--
-- TOC entry 3713 (class 2620 OID 1388074)
-- Name: tri_insert_fiche_cflore; Type: TRIGGER; Schema: contactflore;
--

CREATE TRIGGER tri_insert_fiche_cflore BEFORE INSERT ON t_fiches_cflore FOR EACH ROW EXECUTE PROCEDURE insert_fiche_cflore();


--
-- TOC entry 3716 (class 2620 OID 1388184)
-- Name: tri_insert_releve_cflore; Type: TRIGGER; Schema: contactflore;
--

CREATE TRIGGER tri_insert_releve_cflore BEFORE INSERT ON t_releves_cflore FOR EACH ROW EXECUTE PROCEDURE insert_releve_cflore();


--
-- TOC entry 3717 (class 2620 OID 1388185)
-- Name: tri_synthese_delete_releve_cflore; Type: TRIGGER; Schema: contactflore;
--

CREATE TRIGGER tri_synthese_delete_releve_cflore AFTER DELETE ON t_releves_cflore FOR EACH ROW EXECUTE PROCEDURE synthese_delete_releve_cflore();


--
-- TOC entry 3718 (class 2620 OID 1388186)
-- Name: tri_synthese_insert_releve_cflore; Type: TRIGGER; Schema: contactflore;
--

CREATE TRIGGER tri_synthese_insert_releve_cflore AFTER INSERT ON t_releves_cflore FOR EACH ROW EXECUTE PROCEDURE synthese_insert_releve_cflore();


--
-- TOC entry 3714 (class 2620 OID 1388075)
-- Name: tri_synthese_update_fiche_cflore; Type: TRIGGER; Schema: contactflore;
--

CREATE TRIGGER tri_synthese_update_fiche_cflore AFTER UPDATE ON t_fiches_cflore FOR EACH ROW EXECUTE PROCEDURE synthese_update_fiche_cflore();


--
-- TOC entry 3719 (class 2620 OID 1388187)
-- Name: tri_synthese_update_releve_cflore; Type: TRIGGER; Schema: contactflore;
--

CREATE TRIGGER tri_synthese_update_releve_cflore AFTER UPDATE ON t_releves_cflore FOR EACH ROW EXECUTE PROCEDURE synthese_update_releve_cflore();


--
-- TOC entry 3715 (class 2620 OID 1388077)
-- Name: tri_update_fiche_cflore; Type: TRIGGER; Schema: contactflore;
--

CREATE TRIGGER tri_update_fiche_cflore BEFORE UPDATE ON t_fiches_cflore FOR EACH ROW EXECUTE PROCEDURE update_fiche_cflore();


--
-- TOC entry 3720 (class 2620 OID 1388188)
-- Name: tri_update_releve_cflore; Type: TRIGGER; Schema: contactflore;
--

CREATE TRIGGER tri_update_releve_cflore BEFORE UPDATE ON t_releves_cflore FOR EACH ROW EXECUTE PROCEDURE update_releve_cflore();


--
-- TOC entry 3721 (class 2620 OID 1388145)
-- Name: tri_update_synthese_cor_role_fiche_cflore; Type: TRIGGER; Schema: contactflore;
--

CREATE TRIGGER tri_update_synthese_cor_role_fiche_cflore AFTER INSERT OR UPDATE ON cor_role_fiche_cflore FOR EACH ROW EXECUTE PROCEDURE synthese_update_cor_role_fiche_cflore();


--
-- Name: tri_maj_cor_unite_taxon_cflore; Type: TRIGGER; Schema: contactflore;
--

CREATE TRIGGER tri_maj_cor_unite_taxon_cflore AFTER INSERT OR DELETE ON synthese.cor_unite_synthese FOR EACH ROW EXECUTE PROCEDURE maj_cor_unite_taxon_cflore();

--
-- TOC entry 3710 (class 2606 OID 1388116)
-- Name: fk_cor_message_taxon_cflore_bib_noms; Type: FK CONSTRAINT; Schema: contactflore;
--

ALTER TABLE ONLY cor_message_taxon_cflore
    ADD CONSTRAINT fk_cor_message_taxon_cflore_bib_noms FOREIGN KEY (id_nom) REFERENCES taxonomie.bib_noms(id_nom) ON UPDATE CASCADE;


--
-- TOC entry 3709 (class 2606 OID 1388121)
-- Name: fk_cor_message_taxon_cflore_l_unites_geo; Type: FK CONSTRAINT; Schema: contactflore;
--

ALTER TABLE ONLY cor_message_taxon_cflore
    ADD CONSTRAINT fk_cor_message_taxon_cflore_l_unites_geo FOREIGN KEY (id_message_cflore) REFERENCES bib_messages_cflore(id_message_cflore) ON UPDATE CASCADE;


--
-- TOC entry 3712 (class 2606 OID 1388133)
-- Name: fk_cor_role_fiche_cflore_t_fiches_cflore; Type: FK CONSTRAINT; Schema: contactflore;
--

ALTER TABLE ONLY cor_role_fiche_cflore
    ADD CONSTRAINT fk_cor_role_fiche_cflore_t_fiches_cflore FOREIGN KEY (id_cflore) REFERENCES t_fiches_cflore(id_cflore) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 3711 (class 2606 OID 1388138)
-- Name: fk_cor_role_fiche_cflore_t_roles; Type: FK CONSTRAINT; Schema: contactflore;
--

ALTER TABLE ONLY cor_role_fiche_cflore
    ADD CONSTRAINT fk_cor_role_fiche_cflore_t_roles FOREIGN KEY (id_role) REFERENCES utilisateurs.t_roles(id_role) ON UPDATE CASCADE;


--
-- TOC entry 3711 (class 2606 OID 1388138)
-- Name: fk_cor_unite_taxon_cflore_bib_noms; Type: FK CONSTRAINT; Schema: contactflore;
--

ALTER TABLE ONLY cor_unite_taxon_cflore
  ADD CONSTRAINT fk_cor_unite_taxon_cflore_bib_noms FOREIGN KEY (id_nom) REFERENCES taxonomie.bib_noms (id_nom) ON UPDATE CASCADE;
--
-- TOC entry 3708 (class 2606 OID 1388079)
-- Name: fk_t_releves_cflore_bib_abondances_cflore; Type: FK CONSTRAINT; Schema: contactflore;
--

ALTER TABLE ONLY t_releves_cflore
    ADD CONSTRAINT fk_t_releves_cflore_bib_abondances_cflore FOREIGN KEY (id_abondance_cflore) REFERENCES bib_abondances_cflore(id_abondance_cflore) ON UPDATE CASCADE;


--
-- TOC entry 3707 (class 2606 OID 1388084)
-- Name: fk_t_releves_cflore_bib_phenologies_cflore; Type: FK CONSTRAINT; Schema: contactflore;
--

ALTER TABLE ONLY t_releves_cflore
    ADD CONSTRAINT fk_t_releves_cflore_bib_phenologies_cflore FOREIGN KEY (id_phenologie_cflore) REFERENCES bib_phenologies_cflore(id_phenologie_cflore) ON UPDATE CASCADE;


--
-- TOC entry 3706 (class 2606 OID 1388094)
-- Name: fk_t_releves_cflore_bib_noms; Type: FK CONSTRAINT; Schema: contactflore;
--

ALTER TABLE ONLY t_releves_cflore
    ADD CONSTRAINT fk_t_releves_cflore_bib_noms FOREIGN KEY (id_nom) REFERENCES taxonomie.bib_noms(id_nom) ON UPDATE CASCADE;


--
-- TOC entry 3705 (class 2606 OID 1388101)
-- Name: fk_t_releves_cflore_t_fiches_cflore; Type: FK CONSTRAINT; Schema: contactflore;
--

ALTER TABLE ONLY t_releves_cflore
    ADD CONSTRAINT fk_t_releves_cflore_t_fiches_cflore FOREIGN KEY (id_cflore) REFERENCES t_fiches_cflore(id_cflore) ON UPDATE CASCADE;


--
-- TOC entry 3704 (class 2606 OID 1388059)
-- Name: t_fiches_cflore_id_lot_fkey; Type: FK CONSTRAINT; Schema: contactflore;
--

ALTER TABLE ONLY t_fiches_cflore
    ADD CONSTRAINT t_fiches_cflore_id_lot_fkey FOREIGN KEY (id_lot) REFERENCES meta.bib_lots(id_lot) ON UPDATE CASCADE;


--
-- TOC entry 3703 (class 2606 OID 1388064)
-- Name: t_fiches_cflore_id_organisme_fkey; Type: FK CONSTRAINT; Schema: contactflore;
--

ALTER TABLE ONLY t_fiches_cflore
    ADD CONSTRAINT t_fiches_cflore_id_organisme_fkey FOREIGN KEY (id_organisme) REFERENCES utilisateurs.bib_organismes(id_organisme) ON UPDATE CASCADE;


--
-- TOC entry 3702 (class 2606 OID 1388069)
-- Name: t_fiches_cflore_id_protocole_fkey; Type: FK CONSTRAINT; Schema: contactflore;
--

ALTER TABLE ONLY t_fiches_cflore
    ADD CONSTRAINT t_fiches_cflore_id_protocole_fkey FOREIGN KEY (id_protocole) REFERENCES meta.t_protocoles(id_protocole) ON UPDATE CASCADE;


--------------------------------------------------------------------------------------
--------------------INSERTION DES DONNEES DES TABLES DICTIONNAIRES--------------------
--------------------------------------------------------------------------------------

SET search_path = contactflore, pg_catalog;

INSERT INTO bib_abondances_cflore (id_abondance_cflore, nom_abondance_cflore) VALUES (1, '1 individu');
INSERT INTO bib_abondances_cflore (id_abondance_cflore, nom_abondance_cflore) VALUES (2, 'De 1 à 10 individus');
INSERT INTO bib_abondances_cflore (id_abondance_cflore, nom_abondance_cflore) VALUES (3, 'De 10 à 100 individus');
INSERT INTO bib_abondances_cflore (id_abondance_cflore, nom_abondance_cflore) VALUES (4, 'Plus de 100 individus');

INSERT INTO bib_phenologies_cflore (id_phenologie_cflore, nom_phenologie_cflore) VALUES (1, 'Stade végétatif');
INSERT INTO bib_phenologies_cflore (id_phenologie_cflore, nom_phenologie_cflore) VALUES (2, 'Stade boutons floraux');
INSERT INTO bib_phenologies_cflore (id_phenologie_cflore, nom_phenologie_cflore) VALUES (3, 'Début de floraison');
INSERT INTO bib_phenologies_cflore (id_phenologie_cflore, nom_phenologie_cflore) VALUES (4, 'Pleine floraison');
INSERT INTO bib_phenologies_cflore (id_phenologie_cflore, nom_phenologie_cflore) VALUES (5, 'Fin de floraison et maturation des fruits');
INSERT INTO bib_phenologies_cflore (id_phenologie_cflore, nom_phenologie_cflore) VALUES (6, 'Dissémination');
INSERT INTO bib_phenologies_cflore (id_phenologie_cflore, nom_phenologie_cflore) VALUES (7, 'Stade de décrépitude');
INSERT INTO bib_phenologies_cflore (id_phenologie_cflore, nom_phenologie_cflore) VALUES (8, 'Stage végétatif permanent ');


--------------------------------------------------------------------------------------
--------------------AJOUT DU MODULE DANS LES TABLES DE DESCRIPTION--------------------
--------------------------------------------------------------------------------------

SET search_path = meta, pg_catalog;
INSERT INTO bib_programmes (id_programme, nom_programme, desc_programme, actif, programme_public, desc_programme_public) VALUES (7, 'Contact flore', 'Contact aléatoire de la flore.', true, true, 'Contact aléatoire de la faune invertébrée.');
INSERT INTO bib_lots (id_lot, nom_lot, desc_lot, menu_cf, pn, menu_inv, id_programme) VALUES (7, 'Contact flore', 'Contact flore', false, true, false, 7);
INSERT INTO t_protocoles VALUES (7, 'contact flore', 'à compléter', 'à compléter', 'à compléter', 'non', NULL, NULL);
SET search_path = synthese, pg_catalog;
INSERT INTO bib_sources (id_source, nom_source, desc_source, host, port, username, pass, db_name, db_schema, db_table, db_field, url, target, picto, groupe, actif) VALUES (7,'Contact flore','Contenu des tables t_fiches_cflore et t_releves_cflore de la base GeoNature postgres','localhost',22,NULL,NULL,'geonaturedb','contactflore','t_releves_cflore','id_releve_cflore','cflore',NULL,'images/pictos/plante.gif','FLORE',true);


--------------------------------------------------------------------------------------
--------------------AJOUT DU MODULE DANS LES TABLES SPATIALES-------------------------
--------------------------------------------------------------------------------------

SET search_path = public, pg_catalog;
INSERT INTO geometry_columns (f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, type) VALUES ('', 'contactflore', 't_fiches_cflore', 'the_geom_3857', 2, 3857, 'POINT');
INSERT INTO geometry_columns (f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, type) VALUES ('', 'contactflore', 't_fiches_cflore', 'the_geom_2154', 2, 2154, 'POINT');
INSERT INTO geometry_columns (f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, type) VALUES ('', 'contactflore', 'v_nomade_unites_geo_cflore', 'the_geom', 2, 2154, 'MULTIPOLYGON');
