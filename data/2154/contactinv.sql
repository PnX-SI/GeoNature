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
-- TOC entry 10 (class 2615 OID 2747597)
-- Name: contactinv; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA contactinv;


--
-- TOC entry 3957 (class 0 OID 0)
-- Dependencies: 10
-- Name: SCHEMA contactinv; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA contactinv IS 'schéma contenant les données et les bibliothèques du protocole contact invertébrés sur le modèle de contactfaune';


SET search_path = contactinv, pg_catalog;

--
-- TOC entry 1506 (class 1255 OID 2832063)
-- Name: calcul_cor_unite_taxon_inv(integer, integer); Type: FUNCTION; Schema: contactinv; Owner: -
--

CREATE FUNCTION calcul_cor_unite_taxon_inv(monidtaxon integer, monunite integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    cdnom integer;
BEGIN
	--récup du cd_nom du taxon
	SELECT INTO cdnom cd_nom FROM taxonomie.bib_noms WHERE id_nom = monidtaxon;
    DELETE FROM contactinv.cor_unite_taxon_inv WHERE id_unite_geo = monunite AND id_nom = monidtaxon;
	INSERT INTO contactinv.cor_unite_taxon_inv (id_unite_geo,id_nom,derniere_date,couleur,nb_obs)
	SELECT monunite, monidtaxon,  max(dateobs) AS derniere_date, contactinv.couleur_taxon(monidtaxon,max(dateobs)) AS couleur, count(id_synthese) AS nb_obs
	FROM synthese.cor_unite_synthese
	WHERE cd_nom = cdnom
	AND id_unite_geo = monunite;
END;
$$;


--
-- TOC entry 1466 (class 1255 OID 2747619)
-- Name: couleur_taxon(integer, date); Type: FUNCTION; Schema: contactinv; Owner: -
--

CREATE FUNCTION couleur_taxon(id integer, maxdateobs date) RETURNS text
    LANGUAGE plpgsql
    AS $$
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
$$;


--
-- TOC entry 1468 (class 1255 OID 2747620)
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
		new.the_geom_3857 = public.st_transform(new.the_geom_2154,3857);
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
		SELECT INTO macommune c.insee FROM layers.l_communes c WHERE public.st_intersects(c.the_geom, new.the_geom_2154);
		new.insee = macommune;
		-- on calcul l'altitude
		new.altitude_sig = layers.f_isolines20(new.the_geom_2154); -- mise à jour de l'altitude sig
		IF new.altitude_saisie IS null OR new.altitude_saisie = -1 THEN-- mis à jour de l'altitude retenue
		    new.altitude_retenue = new.altitude_sig;
		ELSE
		    new.altitude_retenue = new.altitude_saisie;
		END IF;
	ELSE					
		SELECT INTO macommune c.insee FROM layers.l_communes c WHERE public.st_intersects(c.the_geom, public.ST_PointFromWKB(public.st_centroid(Box2D(new.the_geom_2154)),2154));
		new.insee = macommune;
		-- on calcul l'altitude
		new.altitude_sig = layers.f_isolines20(public.ST_PointFromWKB(public.st_centroid(Box2D(new.the_geom_2154)),2154)); -- mise à jour de l'altitude sig
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
-- TOC entry 1492 (class 1255 OID 2747621)
-- Name: insert_releve_inv(); Type: FUNCTION; Schema: contactinv; Owner: -
--

CREATE FUNCTION insert_releve_inv() RETURNS trigger
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
    -- MAJ de la table cor_unite_taxon_inv, on commence par récupérer l'unité à partir du pointage (table t_fiches_inv)
	SELECT INTO fiche * FROM contactinv.t_fiches_inv WHERE id_inv = new.id_inv;
	SELECT INTO unite u.id_unite_geo FROM layers.l_unites_geo u WHERE public.st_intersects(fiche.the_geom_2154,u.the_geom);
	--si on est dans une des unités on peut mettre à jour la table cor_unite_taxon_inv, sinon on fait rien
	IF unite>0 THEN
		SELECT INTO line * FROM contactinv.cor_unite_taxon_inv WHERE id_unite_geo = unite AND id_nom = new.id_nom;
		--si la ligne existe dans cor_unite_taxon_inv on la supprime
		IF line IS NOT NULL THEN
			DELETE FROM contactinv.cor_unite_taxon_inv WHERE id_unite_geo = unite AND id_nom = new.id_nom;
		END IF;
		--on compte le nombre d'enregistrement pour ce taxon dans l'unité
		SELECT INTO nbobs count(*) from synthese.syntheseff s
		JOIN layers.l_unites_geo u ON public.st_intersects(u.the_geom, s.the_geom_2154) AND u.id_unite_geo = unite
		WHERE s.cd_nom = cdnom;
		--on créé ou recréé la ligne
		INSERT INTO contactinv.cor_unite_taxon_inv VALUES(unite,new.id_nom,fiche.dateobs,contactinv.couleur_taxon(new.id_nom,fiche.dateobs), nbobs+1);
	END IF;
	RETURN NEW; 			
END;
$$;


--
-- TOC entry 1526 (class 1255 OID 2832064)
-- Name: maj_cor_unite_taxon_inv(); Type: FUNCTION; Schema: contactinv; Owner: -
--

CREATE FUNCTION maj_cor_unite_taxon_inv() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
		IF monregne = 'Animalia' THEN
			--calcul de l'embranchement du taxon supprimé
			SELECT  INTO monembranchement tx.phylum FROM taxonomie.taxref tx WHERE tx.cd_nom = old.cd_nom;
			-- puis recalul des couleurs avec old.id_unite_geo et old.taxon pour un taxon est invertébrés
			IF monembranchement != 'Chordata' THEN
				IF (SELECT count(*) FROM synthese.cor_unite_synthese WHERE cd_nom = old.cd_nom AND id_unite_geo = old.id_unite_geo)= 0 THEN
					DELETE FROM contactinv.cor_unite_taxon_inv WHERE id_nom = monidtaxon AND id_unite_geo = old.id_unite_geo;
				ELSE
					PERFORM contactinv.calcul_cor_unite_taxon_inv(monidtaxon, old.id_unite_geo);
				END IF;
			END IF;
		END IF;
		RETURN OLD;		
		
	ELSIF (TG_OP = 'INSERT') THEN
		--retrouver le id_nom
		SELECT INTO monidtaxon id_nom FROM taxonomie.bib_noms WHERE cd_nom = new.cd_nom LIMIT 1;
		--calcul du règne du taxon inséré
		SELECT  INTO monregne tx.regne FROM taxonomie.taxref tx WHERE tx.cd_nom = new.cd_nom;
		IF monregne = 'Animalia' THEN
			--calcul de l'embranchement du taxon inséré
			SELECT INTO monembranchement tx.phylum FROM taxonomie.taxref tx WHERE tx.cd_nom = new.cd_nom;
			-- puis recalul des couleurs avec new.id_unite_geo et new.taxon selon que le taxon est vertébrés (embranchemet 1) ou invertébres
			IF monembranchement != 'Chordata' THEN
			    PERFORM contactinv.calcul_cor_unite_taxon_inv(monidtaxon, new.id_unite_geo);
			END IF;
		END IF;
		RETURN NEW;
	END IF;
END;
$$;


--
-- TOC entry 1470 (class 1255 OID 2747622)
-- Name: synthese_delete_releve_inv(); Type: FUNCTION; Schema: contactinv; Owner: -
--

CREATE FUNCTION synthese_delete_releve_inv() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    idsource integer;
    nbreleves integer;
BEGIN
    
    SELECT INTO idsource id_source FROM synthese.bib_sources  WHERE db_schema='contactinv' AND db_field = 'id_releve_inv' ;
    --SUPRESSION EN SYNTHESE
    DELETE FROM synthese.syntheseff WHERE id_source = idsource AND id_fiche_source = old.id_releve_inv::text;
    -- SUPPRESSION DE LA FICHE S'IL N'Y A PLUS DE RELEVE
    SELECT INTO nbreleves count(*) FROM contactinv.t_releves_inv WHERE id_inv = old.id_releve_inv;
    IF nbreleves < 1 THEN
	DELETE FROM contactinv.t_fiches_inv WHERE id_inv = old.id_releve_inv;
    END IF; 
    RETURN OLD; 
END;
$$;


--
-- TOC entry 1493 (class 1255 OID 2747623)
-- Name: synthese_insert_releve_inv(); Type: FUNCTION; Schema: contactinv; Owner: -
--

CREATE FUNCTION synthese_insert_releve_inv() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
	fiche RECORD;
	test integer;
	criteresynthese integer;
	mesobservateurs character varying(255);
	unite integer;
	idsource integer;
    cdnom integer;
BEGIN

	--Récupération des données id_source dans la table synthese.bib_sources
	SELECT INTO idsource id_source FROM synthese.bib_sources  WHERE db_schema='contactinv' AND db_field = 'id_releve_inv';
	--récup du cd_nom du taxon
	SELECT INTO cdnom cd_nom FROM taxonomie.bib_noms WHERE id_nom = new.id_nom;
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
	fiche.id_lot,
	criteresynthese,
	new.am+new.af+new.ai+new.na
	);
	RETURN NEW; 			
END;
$$;


--
-- TOC entry 1494 (class 1255 OID 2747624)
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
-- TOC entry 1471 (class 1255 OID 2747625)
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
            
			IF NOT public.st_equals(new.the_geom_3857,old.the_geom_3857) OR NOT public.st_equals(new.the_geom_2154,old.the_geom_2154) THEN
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
-- TOC entry 1495 (class 1255 OID 2747626)
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
    cdnom integer;
    nbreleves integer;
BEGIN

	--Récupération des données id_source dans la table synthese.bib_sources
	SELECT INTO idsource id_source FROM synthese.bib_sources  WHERE db_schema='contactinv' AND db_field = 'id_releve_inv';
    --récup du cd_nom du taxon
	SELECT INTO cdnom cd_nom FROM taxonomie.bib_noms WHERE id_nom = new.id_nom;
	--test si on a bien l'enregistrement dans la table syntheseff avant de le mettre à jour
	SELECT INTO test id_fiche_source FROM synthese.syntheseff WHERE id_source = idsource AND id_fiche_source = old.id_releve_inv::text;
	IF test IS NOT NULL THEN
		--Récupération des données dans la table t_fiches_inv et de la liste des observateurs
		SELECT INTO criteresynthese id_critere_synthese FROM contactinv.bib_criteres_inv WHERE id_critere_inv = new.id_critere_inv;

		--mise à jour de l'enregistrement correspondant dans syntheseff
		UPDATE synthese.syntheseff SET
			id_fiche_source = new.id_releve_inv,
			code_fiche_source = 'f'||new.id_inv||'-r'||new.id_releve_inv,
			cd_nom = cdnom,
			remarques = new.commentaire,
            determinateur = new.determinateur,
			derniere_action = 'u',
			supprime = new.supprime,
			id_critere_synthese = criteresynthese,
			effectif_total = new.am+new.af+new.ai+new.na
		WHERE id_source = idsource AND id_fiche_source = old.id_releve_inv::text; -- Ici on utilise le OLD id_releve_inv pour être sur 
		--qu'il existe dans la table synthese (cas improbable où on changerait la pk de la table t_releves_inv
		--le trigger met à jour avec le NEW --> SET id_fiche_source = new.id_releve_inv
	END IF;
	-- SUPPRESSION (supprime = true) DE LA FICHE S'IL N'Y A PLUS DE RELEVE (supprime = false)
	SELECT INTO nbreleves count(*) FROM contactinv.t_releves_inv WHERE id_inv = new.id_inv AND supprime = false;
	IF nbreleves < 1 THEN
		UPDATE contactinv.t_fiches_inv SET supprime = true WHERE id_inv = new.id_inv;
	END IF;
	RETURN NEW;
END;
$$;


--
-- TOC entry 1520 (class 1255 OID 2747627)
-- Name: update_fiche_inv(); Type: FUNCTION; Schema: contactinv; Owner: -
--

CREATE FUNCTION update_fiche_inv() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  macommune character(5);
  nbreleves integer;
BEGIN
-------------------------- gestion des infos relatives a la numerisation (srid utilisé et support utilisé : pda ou web ou sig)
-------------------------- attention la saisie sur le web réalise un insert sur qq données mais the_geom_3857 est "faussement inséré" par un update !!!
IF (NOT public.st_equals(new.the_geom_2154,old.the_geom_2154) OR (old.the_geom_2154 is null AND new.the_geom_2154 is NOT NULL))
  OR (NOT public.st_equals(new.the_geom_3857,old.the_geom_3857) OR (old.the_geom_3857 is null AND new.the_geom_3857 is NOT NULL)) 
   THEN
	IF NOT public.st_equals(new.the_geom_3857,old.the_geom_3857) OR (old.the_geom_3857 is null AND new.the_geom_3857 is NOT NULL) THEN
		new.the_geom_2154 = public.st_transform(new.the_geom_3857,2154);
		new.srid_dessin = 3857;
	ELSIF NOT public.st_equals(new.the_geom_2154,old.the_geom_2154) OR (old.the_geom_2154 is null AND new.the_geom_2154 is NOT NULL) THEN
		new.the_geom_3857 = public.st_transform(new.the_geom_2154,3857);
		new.srid_dessin = 2154;
	END IF;

-------gestion des divers control avec attributions de la commune : dans le cas d'un insert depuis le nomade uniquement via the_geom_2154 !!!!
	IF st_isvalid(new.the_geom_2154) = true THEN	-- si la topologie est bonne alors...
		-- on calcul la commune (celle qui contient le plus de zp en surface)...
		SELECT INTO macommune c.insee FROM layers.l_communes c WHERE public.st_intersects(c.the_geom, new.the_geom_2154);
		new.insee = macommune;
		-- on calcul l'altitude
		new.altitude_sig = layers.f_isolines20(new.the_geom_2154); -- mise à jour de l'altitude sig
		IF new.altitude_saisie IS null OR new.altitude_saisie = -1 THEN-- mis à jour de l'altitude retenue
		    new.altitude_retenue = new.altitude_sig;
		ELSE
		    new.altitude_retenue = new.altitude_saisie;
		END IF;
	ELSE					
		SELECT INTO macommune c.insee FROM layers.l_communes c WHERE public.st_intersects(c.the_geom, public.ST_PointFromWKB(public.st_centroid(Box2D(new.the_geom_2154)),2154));
		new.insee = macommune;
		-- on calcul l'altitude
		new.altitude_sig = layers.f_isolines20(public.ST_PointFromWKB(public.st_centroid(Box2D(new.the_geom_2154)),2154)); -- mise à jour de l'altitude sig
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
    --Pour éviter un bouclage des triggers, on vérifie qu'il y a bien des relevés non supprimés à modifier
    SELECT INTO nbreleves count(*) FROM contactinv.t_releves_inv WHERE id_inv = old.id_inv AND supprime = false;
    IF nbreleves > 0 THEN
      update contactinv.t_releves_inv set supprime = 't' WHERE id_inv = old.id_inv; 
    END IF;
  END IF;
  IF new.supprime = 'f' THEN
     --action discutable. S'il y a des relevés douteux dans la fiche, il faut les garder supprimés
     --update contactfaune.t_releves_inv set supprime = 'f' WHERE id_inv = old.id_inv; 
  END IF;
END IF;
RETURN NEW; 
END;
$$;


--
-- TOC entry 1496 (class 1255 OID 2747628)
-- Name: update_releve_inv(); Type: FUNCTION; Schema: contactinv; Owner: -
--

CREATE FUNCTION update_releve_inv() RETURNS trigger
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


SET default_with_oids = false;

--
-- TOC entry 300 (class 1259 OID 2747944)
-- Name: bib_criteres_inv; Type: TABLE; Schema: contactinv; Owner: -
--

CREATE TABLE bib_criteres_inv (
    id_critere_inv integer NOT NULL,
    code_critere_inv character varying(3),
    nom_critere_inv character varying(90),
    tri_inv integer,
    id_critere_synthese integer
);


--
-- TOC entry 301 (class 1259 OID 2747947)
-- Name: bib_messages_inv; Type: TABLE; Schema: contactinv; Owner: -
--

CREATE TABLE bib_messages_inv (
    id_message_inv integer NOT NULL,
    texte_message_inv character varying(255)
);


--
-- TOC entry 302 (class 1259 OID 2747950)
-- Name: bib_milieux_inv; Type: TABLE; Schema: contactinv; Owner: -
--

CREATE TABLE bib_milieux_inv (
    id_milieu_inv integer NOT NULL,
    nom_milieu_inv character varying(50)
);


--
-- TOC entry 303 (class 1259 OID 2747953)
-- Name: cor_message_taxon; Type: TABLE; Schema: contactinv; Owner: -
--

CREATE TABLE cor_message_taxon (
    id_message_inv integer NOT NULL,
    id_nom integer NOT NULL
);


--
-- TOC entry 304 (class 1259 OID 2747956)
-- Name: cor_role_fiche_inv; Type: TABLE; Schema: contactinv; Owner: -
--

CREATE TABLE cor_role_fiche_inv (
    id_inv bigint NOT NULL,
    id_role integer NOT NULL
);


--
-- TOC entry 305 (class 1259 OID 2747959)
-- Name: cor_unite_taxon_inv; Type: TABLE; Schema: contactinv; Owner: -
--

CREATE TABLE cor_unite_taxon_inv (
    id_unite_geo integer NOT NULL,
    id_nom integer NOT NULL,
    derniere_date date,
    couleur character varying(10) NOT NULL,
    nb_obs integer
);


--
-- TOC entry 306 (class 1259 OID 2747962)
-- Name: log_colors; Type: TABLE; Schema: contactinv; Owner: -
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
-- TOC entry 307 (class 1259 OID 2747968)
-- Name: log_colors_day; Type: TABLE; Schema: contactinv; Owner: -
--

CREATE TABLE log_colors_day (
    jour date NOT NULL,
    couleur character varying NOT NULL,
    nbtaxons numeric
);


--
-- TOC entry 308 (class 1259 OID 2747974)
-- Name: t_fiches_inv; Type: TABLE; Schema: contactinv; Owner: -
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
-- TOC entry 309 (class 1259 OID 2747987)
-- Name: t_releves_inv; Type: TABLE; Schema: contactinv; Owner: -
--

CREATE TABLE t_releves_inv (
    id_releve_inv bigint NOT NULL,
    id_inv bigint NOT NULL,
    id_nom integer NOT NULL,
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
-- TOC entry 3958 (class 0 OID 0)
-- Dependencies: 309
-- Name: COLUMN t_releves_inv.gid; Type: COMMENT; Schema: contactinv; Owner: -
--

COMMENT ON COLUMN t_releves_inv.gid IS 'pour qgis';


--
-- TOC entry 310 (class 1259 OID 2747995)
-- Name: t_releves_inv_gid_seq; Type: SEQUENCE; Schema: contactinv; Owner: -
--

CREATE SEQUENCE t_releves_inv_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 3959 (class 0 OID 0)
-- Dependencies: 310
-- Name: t_releves_inv_gid_seq; Type: SEQUENCE OWNED BY; Schema: contactinv; Owner: -
--

ALTER SEQUENCE t_releves_inv_gid_seq OWNED BY t_releves_inv.gid;


--
-- TOC entry 311 (class 1259 OID 2747997)
-- Name: v_nomade_classes; Type: VIEW; Schema: contactinv; Owner: -
--

CREATE VIEW v_nomade_classes AS
 SELECT g.id_liste AS id_classe,
    g.nom_liste AS nom_classe_fr,
    g.desc_liste AS desc_classe
   FROM (( SELECT l.id_liste,
            l.nom_liste,
            l.desc_liste,
            min(taxonomie.find_cdref(n.cd_nom)) AS cd_ref
           FROM ((taxonomie.bib_listes l
             JOIN taxonomie.cor_nom_liste cnl ON ((cnl.id_liste = l.id_liste)))
             JOIN taxonomie.bib_noms n ON ((n.id_nom = cnl.id_nom)))
          WHERE (l.id_liste = ANY (ARRAY[2, 5, 8, 9, 10, 15, 16]))
          GROUP BY l.id_liste, l.nom_liste, l.desc_liste) g
     JOIN taxonomie.taxref t ON ((t.cd_nom = g.cd_ref)))
  WHERE (((t.phylum)::text <> 'Chordata'::text) AND ((t.regne)::text = 'Animalia'::text));


--
-- TOC entry 312 (class 1259 OID 2748002)
-- Name: v_nomade_criteres_inv; Type: VIEW; Schema: contactinv; Owner: -
--

CREATE VIEW v_nomade_criteres_inv AS
 SELECT c.id_critere_inv,
    c.nom_critere_inv,
    c.tri_inv
   FROM bib_criteres_inv c
  ORDER BY c.tri_inv;


--
-- TOC entry 313 (class 1259 OID 2748006)
-- Name: v_nomade_milieux_inv; Type: VIEW; Schema: contactinv; Owner: -
--

CREATE VIEW v_nomade_milieux_inv AS
 SELECT bib_milieux_inv.id_milieu_inv,
    bib_milieux_inv.nom_milieu_inv
   FROM bib_milieux_inv
  ORDER BY bib_milieux_inv.id_milieu_inv;


--
-- TOC entry 314 (class 1259 OID 2748010)
-- Name: v_nomade_observateurs_inv; Type: VIEW; Schema: contactinv; Owner: -
--

CREATE VIEW v_nomade_observateurs_inv AS
 SELECT DISTINCT r.id_role,
    r.nom_role,
    r.prenom_role
   FROM utilisateurs.t_roles r
  WHERE ((r.id_role IN ( SELECT DISTINCT cr.id_role_utilisateur
           FROM utilisateurs.cor_roles cr
          WHERE (cr.id_role_groupe IN ( SELECT crm.id_role
                   FROM utilisateurs.cor_role_menu crm
                  WHERE (crm.id_menu = 11)))
          ORDER BY cr.id_role_utilisateur)) OR (r.id_role IN ( SELECT crm.id_role
           FROM (utilisateurs.cor_role_menu crm
             JOIN utilisateurs.t_roles r_1 ON ((((r_1.id_role = crm.id_role) AND (crm.id_menu = 11)) AND (r_1.groupe = false)))))))
  ORDER BY r.nom_role, r.prenom_role, r.id_role;


--
-- TOC entry 315 (class 1259 OID 2748015)
-- Name: v_nomade_taxons_inv; Type: VIEW; Schema: contactinv; Owner: -
--

CREATE VIEW v_nomade_taxons_inv AS
  SELECT DISTINCT n.id_nom,
    taxonomie.find_cdref(tx.cd_nom) AS cd_ref,
    tx.cd_nom,
    tx.lb_nom AS nom_latin,
    n.nom_francais,
    g.id_classe,
    f2.bool AS patrimonial,
    m.texte_message_inv AS message
  FROM taxonomie.bib_noms n
     LEFT JOIN cor_message_taxon cmt ON cmt.id_nom = n.id_nom
     LEFT JOIN bib_messages_inv m ON m.id_message_inv = cmt.id_message_inv
     LEFT JOIN taxonomie.cor_taxon_attribut cta ON cta.cd_ref = n.cd_ref
     JOIN taxonomie.bib_attributs a ON a.id_attribut = cta.id_attribut
     JOIN taxonomie.cor_nom_liste cnl ON cnl.id_nom = n.id_nom
     JOIN v_nomade_classes g ON g.id_classe = cnl.id_liste
     JOIN taxonomie.taxref tx ON tx.cd_nom = n.cd_nom
     JOIN public.cor_boolean f2 ON f2.expression::text = cta.valeur_attribut AND cta.id_attribut = 1
  WHERE n.id_nom IN(SELECT id_nom FROM taxonomie.cor_nom_liste WHERE id_liste = 500)
  ORDER BY n.id_nom, taxonomie.find_cdref(tx.cd_nom), tx.lb_nom, n.nom_francais, g.id_classe, f2.bool, m.texte_message_inv;


--
-- TOC entry 316 (class 1259 OID 2748020)
-- Name: v_nomade_unites_geo_inv; Type: VIEW; Schema: contactinv; Owner: -
--

CREATE VIEW v_nomade_unites_geo_inv AS
 SELECT public.st_simplifypreservetopology(l_unites_geo.the_geom, (15)::double precision) AS the_geom,
    l_unites_geo.id_unite_geo
   FROM layers.l_unites_geo
  GROUP BY l_unites_geo.the_geom, l_unites_geo.id_unite_geo;


--
-- TOC entry 3735 (class 2604 OID 2748287)
-- Name: gid; Type: DEFAULT; Schema: contactinv; Owner: -
--

ALTER TABLE ONLY t_releves_inv ALTER COLUMN gid SET DEFAULT nextval('t_releves_inv_gid_seq'::regclass);


--
-- TOC entry 3738 (class 2606 OID 2748321)
-- Name: pk_bib_criteres_inv; Type: CONSTRAINT; Schema: contactinv; Owner: -
--

ALTER TABLE ONLY bib_criteres_inv
    ADD CONSTRAINT pk_bib_criteres_inv PRIMARY KEY (id_critere_inv);


--
-- TOC entry 3742 (class 2606 OID 2748323)
-- Name: pk_bib_milieux_inv; Type: CONSTRAINT; Schema: contactinv; Owner: -
--

ALTER TABLE ONLY bib_milieux_inv
    ADD CONSTRAINT pk_bib_milieux_inv PRIMARY KEY (id_milieu_inv);


--
-- TOC entry 3740 (class 2606 OID 2748325)
-- Name: pk_bib_types_comptage; Type: CONSTRAINT; Schema: contactinv; Owner: -
--

ALTER TABLE ONLY bib_messages_inv
    ADD CONSTRAINT pk_bib_types_comptage PRIMARY KEY (id_message_inv);


--
-- TOC entry 3746 (class 2606 OID 2748327)
-- Name: pk_cor_message_taxon_inv; Type: CONSTRAINT; Schema: contactinv; Owner: -
--

ALTER TABLE ONLY cor_message_taxon
    ADD CONSTRAINT pk_cor_message_taxon_inv PRIMARY KEY (id_message_inv, id_nom);


--
-- TOC entry 3750 (class 2606 OID 2748329)
-- Name: pk_cor_role_fiche_inv; Type: CONSTRAINT; Schema: contactinv; Owner: -
--

ALTER TABLE ONLY cor_role_fiche_inv
    ADD CONSTRAINT pk_cor_role_fiche_inv PRIMARY KEY (id_inv, id_role);


--
-- TOC entry 3754 (class 2606 OID 2748331)
-- Name: pk_cor_unite_taxon_inv; Type: CONSTRAINT; Schema: contactinv; Owner: -
--

ALTER TABLE ONLY cor_unite_taxon_inv
    ADD CONSTRAINT pk_cor_unite_taxon_inv PRIMARY KEY (id_unite_geo, id_nom);


--
-- TOC entry 3758 (class 2606 OID 2748333)
-- Name: pk_log_colors_day_inv; Type: CONSTRAINT; Schema: contactinv; Owner: -
--

ALTER TABLE ONLY log_colors_day
    ADD CONSTRAINT pk_log_colors_day_inv PRIMARY KEY (jour, couleur);


--
-- TOC entry 3756 (class 2606 OID 2748335)
-- Name: pk_log_colors_inv; Type: CONSTRAINT; Schema: contactinv; Owner: -
--

ALTER TABLE ONLY log_colors
    ADD CONSTRAINT pk_log_colors_inv PRIMARY KEY (annee, mois, id_unite_geo, couleur);


--
-- TOC entry 3762 (class 2606 OID 2748337)
-- Name: pk_t_fiches_inv; Type: CONSTRAINT; Schema: contactinv; Owner: -
--

ALTER TABLE ONLY t_fiches_inv
    ADD CONSTRAINT pk_t_fiches_inv PRIMARY KEY (id_inv);


--
-- TOC entry 3767 (class 2606 OID 2748339)
-- Name: pk_t_releves_inv; Type: CONSTRAINT; Schema: contactinv; Owner: -
--

ALTER TABLE ONLY t_releves_inv
    ADD CONSTRAINT pk_t_releves_inv PRIMARY KEY (id_releve_inv);


--
-- TOC entry 3736 (class 1259 OID 2748461)
-- Name: fki_; Type: INDEX; Schema: contactinv; Owner: -
--

CREATE INDEX fki_ ON bib_criteres_inv USING btree (id_critere_synthese);


--
-- TOC entry 3759 (class 1259 OID 2748462)
-- Name: fki_t_fiches_inv_bib_milieux_inv; Type: INDEX; Schema: contactinv; Owner: -
--

CREATE INDEX fki_t_fiches_inv_bib_milieux_inv ON t_fiches_inv USING btree (id_milieu_inv);


--
-- TOC entry 3743 (class 1259 OID 2748463)
-- Name: i_fk_cor_msg_inv_bib_msg; Type: INDEX; Schema: contactinv; Owner: -
--

CREATE INDEX i_fk_cor_msg_inv_bib_msg ON cor_message_taxon USING btree (id_message_inv);


--
-- TOC entry 3744 (class 1259 OID 2748464)
-- Name: i_fk_cor_msg_inv_bib_noms; Type: INDEX; Schema: contactinv; Owner: -
--

CREATE INDEX i_fk_cor_msg_inv_bib_noms ON cor_message_taxon USING btree (id_nom);


--
-- TOC entry 3747 (class 1259 OID 2748465)
-- Name: i_fk_cor_role_fiche_inv_t_fiche; Type: INDEX; Schema: contactinv; Owner: -
--

CREATE INDEX i_fk_cor_role_fiche_inv_t_fiche ON cor_role_fiche_inv USING btree (id_inv);


--
-- TOC entry 3748 (class 1259 OID 2748466)
-- Name: i_fk_cor_role_fiche_inv_t_roles; Type: INDEX; Schema: contactinv; Owner: -
--

CREATE INDEX i_fk_cor_role_fiche_inv_t_roles ON cor_role_fiche_inv USING btree (id_role);


--
-- TOC entry 3751 (class 1259 OID 2748467)
-- Name: i_fk_cor_unite_taxon_inv_bib_noms; Type: INDEX; Schema: contactinv; Owner: -
--

CREATE INDEX i_fk_cor_unite_taxon_inv_bib_noms ON cor_unite_taxon_inv USING btree (id_nom);


--
-- TOC entry 3752 (class 1259 OID 2748468)
-- Name: i_fk_cor_unite_taxon_inv_l_unites; Type: INDEX; Schema: contactinv; Owner: -
--

CREATE INDEX i_fk_cor_unite_taxon_inv_l_unites ON cor_unite_taxon_inv USING btree (id_unite_geo);


--
-- TOC entry 3760 (class 1259 OID 2748469)
-- Name: i_fk_t_fiches_inv_l_communes; Type: INDEX; Schema: contactinv; Owner: -
--

CREATE INDEX i_fk_t_fiches_inv_l_communes ON t_fiches_inv USING btree (insee);


--
-- TOC entry 3763 (class 1259 OID 2748470)
-- Name: i_fk_t_releves_inv_bib_criteres; Type: INDEX; Schema: contactinv; Owner: -
--

CREATE INDEX i_fk_t_releves_inv_bib_criteres ON t_releves_inv USING btree (id_critere_inv);


--
-- TOC entry 3764 (class 1259 OID 2748471)
-- Name: i_fk_t_releves_inv_bib_noms; Type: INDEX; Schema: contactinv; Owner: -
--

CREATE INDEX i_fk_t_releves_inv_bib_noms ON t_releves_inv USING btree (id_nom);


--
-- TOC entry 3765 (class 1259 OID 2748472)
-- Name: i_fk_t_releves_inv_t_fiches_inv; Type: INDEX; Schema: contactinv; Owner: -
--

CREATE INDEX i_fk_t_releves_inv_t_fiches_inv ON t_releves_inv USING btree (id_inv);


--
-- TOC entry 3782 (class 2620 OID 2748509)
-- Name: tri_insert_fiche_inv; Type: TRIGGER; Schema: contactinv; Owner: -
--

CREATE TRIGGER tri_insert_fiche_inv BEFORE INSERT ON t_fiches_inv FOR EACH ROW EXECUTE PROCEDURE insert_fiche_inv();


--
-- TOC entry 3785 (class 2620 OID 2748510)
-- Name: tri_insert_releve_inv; Type: TRIGGER; Schema: contactinv; Owner: -
--

CREATE TRIGGER tri_insert_releve_inv BEFORE INSERT ON t_releves_inv FOR EACH ROW EXECUTE PROCEDURE insert_releve_inv();


--
-- TOC entry 3786 (class 2620 OID 2748511)
-- Name: tri_synthese_delete_releve_inv; Type: TRIGGER; Schema: contactinv; Owner: -
--

CREATE TRIGGER tri_synthese_delete_releve_inv AFTER DELETE ON t_releves_inv FOR EACH ROW EXECUTE PROCEDURE synthese_delete_releve_inv();


--
-- TOC entry 3787 (class 2620 OID 2748512)
-- Name: tri_synthese_insert_releve_inv; Type: TRIGGER; Schema: contactinv; Owner: -
--

CREATE TRIGGER tri_synthese_insert_releve_inv AFTER INSERT ON t_releves_inv FOR EACH ROW EXECUTE PROCEDURE synthese_insert_releve_inv();


--
-- TOC entry 3783 (class 2620 OID 2748513)
-- Name: tri_synthese_update_fiche_inv; Type: TRIGGER; Schema: contactinv; Owner: -
--

CREATE TRIGGER tri_synthese_update_fiche_inv AFTER UPDATE ON t_fiches_inv FOR EACH ROW EXECUTE PROCEDURE synthese_update_fiche_inv();


--
-- TOC entry 3788 (class 2620 OID 2748514)
-- Name: tri_synthese_update_releve_inv; Type: TRIGGER; Schema: contactinv; Owner: -
--

CREATE TRIGGER tri_synthese_update_releve_inv AFTER UPDATE ON t_releves_inv FOR EACH ROW EXECUTE PROCEDURE synthese_update_releve_inv();


--
-- TOC entry 3784 (class 2620 OID 2748515)
-- Name: tri_update_fiche_inv; Type: TRIGGER; Schema: contactinv; Owner: -
--

CREATE TRIGGER tri_update_fiche_inv BEFORE UPDATE ON t_fiches_inv FOR EACH ROW EXECUTE PROCEDURE update_fiche_inv();


--
-- TOC entry 3789 (class 2620 OID 2748516)
-- Name: tri_update_releve_inv; Type: TRIGGER; Schema: contactinv; Owner: -
--

CREATE TRIGGER tri_update_releve_inv BEFORE UPDATE ON t_releves_inv FOR EACH ROW EXECUTE PROCEDURE update_releve_inv();


--
-- TOC entry 3781 (class 2620 OID 2748517)
-- Name: tri_update_synthese_cor_role_fiche_inv; Type: TRIGGER; Schema: contactinv; Owner: -
--

CREATE TRIGGER tri_update_synthese_cor_role_fiche_inv AFTER INSERT OR UPDATE ON cor_role_fiche_inv FOR EACH ROW EXECUTE PROCEDURE synthese_update_cor_role_fiche_inv();


--
-- TOC entry 3781 (class 2620 OID 2748517)
-- Name: tri_maj_cor_unite_taxon_inv; Type: TRIGGER; Schema: contactinv; Owner: -
--

CREATE TRIGGER tri_maj_cor_unite_taxon_inv AFTER INSERT OR DELETE ON synthese.cor_unite_synthese FOR EACH ROW EXECUTE PROCEDURE maj_cor_unite_taxon_inv();


--
-- TOC entry 3768 (class 2606 OID 2748616)
-- Name: bib_criteres_inv_id_critere_synthese_fkey; Type: FK CONSTRAINT; Schema: contactinv; Owner: -
--

ALTER TABLE ONLY bib_criteres_inv
    ADD CONSTRAINT bib_criteres_inv_id_critere_synthese_fkey FOREIGN KEY (id_critere_synthese) REFERENCES synthese.bib_criteres_synthese(id_critere_synthese);


--
-- TOC entry 3769 (class 2606 OID 2748621)
-- Name: fk_cor_message_taxon_inv_bib_noms; Type: FK CONSTRAINT; Schema: contactinv; Owner: -
--

ALTER TABLE ONLY cor_message_taxon
    ADD CONSTRAINT fk_cor_message_taxon_inv_bib_noms FOREIGN KEY (id_nom) REFERENCES taxonomie.bib_noms(id_nom) ON UPDATE CASCADE;


--
-- TOC entry 3770 (class 2606 OID 2748626)
-- Name: fk_cor_message_taxon_inv_l_unites_geo; Type: FK CONSTRAINT; Schema: contactinv; Owner: -
--

ALTER TABLE ONLY cor_message_taxon
    ADD CONSTRAINT fk_cor_message_taxon_inv_l_unites_geo FOREIGN KEY (id_message_inv) REFERENCES bib_messages_inv(id_message_inv) ON UPDATE CASCADE;


--
-- TOC entry 3771 (class 2606 OID 2748631)
-- Name: fk_cor_role_fiche_inv_t_fiches_inv; Type: FK CONSTRAINT; Schema: contactinv; Owner: -
--

ALTER TABLE ONLY cor_role_fiche_inv
    ADD CONSTRAINT fk_cor_role_fiche_inv_t_fiches_inv FOREIGN KEY (id_inv) REFERENCES t_fiches_inv(id_inv) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 3772 (class 2606 OID 2748636)
-- Name: fk_cor_role_fiche_inv_t_roles; Type: FK CONSTRAINT; Schema: contactinv; Owner: -
--

ALTER TABLE ONLY cor_role_fiche_inv
    ADD CONSTRAINT fk_cor_role_fiche_inv_t_roles FOREIGN KEY (id_role) REFERENCES utilisateurs.t_roles(id_role) ON UPDATE CASCADE;


--
-- TOC entry 3773 (class 2606 OID 2748641)
-- Name: fk_cor_unite_taxon_inv_bib_noms; Type: FK CONSTRAINT; Schema: contactinv; Owner: -
--

ALTER TABLE ONLY cor_unite_taxon_inv
    ADD CONSTRAINT fk_cor_unite_taxon_inv_bib_noms FOREIGN KEY (id_nom) REFERENCES taxonomie.bib_noms(id_nom) ON UPDATE CASCADE;


--
-- TOC entry 3774 (class 2606 OID 2748646)
-- Name: fk_t_fiches_inv_bib_milieux_inv; Type: FK CONSTRAINT; Schema: contactinv; Owner: -
--

ALTER TABLE ONLY t_fiches_inv
    ADD CONSTRAINT fk_t_fiches_inv_bib_milieux_inv FOREIGN KEY (id_milieu_inv) REFERENCES bib_milieux_inv(id_milieu_inv) ON UPDATE CASCADE;


--
-- TOC entry 3778 (class 2606 OID 2748651)
-- Name: fk_t_releves_inv_bib_criteres_inv; Type: FK CONSTRAINT; Schema: contactinv; Owner: -
--

ALTER TABLE ONLY t_releves_inv
    ADD CONSTRAINT fk_t_releves_inv_bib_criteres_inv FOREIGN KEY (id_critere_inv) REFERENCES bib_criteres_inv(id_critere_inv) ON UPDATE CASCADE;


--
-- TOC entry 3779 (class 2606 OID 2748656)
-- Name: fk_t_releves_inv_bib_noms; Type: FK CONSTRAINT; Schema: contactinv; Owner: -
--

ALTER TABLE ONLY t_releves_inv
    ADD CONSTRAINT fk_t_releves_inv_bib_noms FOREIGN KEY (id_nom) REFERENCES taxonomie.bib_noms(id_nom) ON UPDATE CASCADE;


--
-- TOC entry 3780 (class 2606 OID 2748661)
-- Name: fk_t_releves_inv_t_fiches_inv; Type: FK CONSTRAINT; Schema: contactinv; Owner: -
--

ALTER TABLE ONLY t_releves_inv
    ADD CONSTRAINT fk_t_releves_inv_t_fiches_inv FOREIGN KEY (id_inv) REFERENCES t_fiches_inv(id_inv) ON UPDATE CASCADE;


--
-- TOC entry 3775 (class 2606 OID 2748666)
-- Name: t_fiches_inv_id_lot_fkey; Type: FK CONSTRAINT; Schema: contactinv; Owner: -
--

ALTER TABLE ONLY t_fiches_inv
    ADD CONSTRAINT t_fiches_inv_id_lot_fkey FOREIGN KEY (id_lot) REFERENCES meta.bib_lots(id_lot) ON UPDATE CASCADE;


--
-- TOC entry 3776 (class 2606 OID 2748671)
-- Name: t_fiches_inv_id_organisme_fkey; Type: FK CONSTRAINT; Schema: contactinv; Owner: -
--

ALTER TABLE ONLY t_fiches_inv
    ADD CONSTRAINT t_fiches_inv_id_organisme_fkey FOREIGN KEY (id_organisme) REFERENCES utilisateurs.bib_organismes(id_organisme) ON UPDATE CASCADE;


--
-- TOC entry 3777 (class 2606 OID 2748676)
-- Name: t_fiches_inv_id_protocole_fkey; Type: FK CONSTRAINT; Schema: contactinv; Owner: -
--

ALTER TABLE ONLY t_fiches_inv
    ADD CONSTRAINT t_fiches_inv_id_protocole_fkey FOREIGN KEY (id_protocole) REFERENCES meta.t_protocoles(id_protocole) ON UPDATE CASCADE;


SET search_path = synchronomade, pg_catalog;

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
-- Name: id; Type: DEFAULT; Schema: synchronomade; Owner: -
--

ALTER TABLE ONLY erreurs_inv ALTER COLUMN id SET DEFAULT nextval('erreurs_inv_id_seq'::regclass);


--
-- Name: erreurs_inv_pkey; Type: CONSTRAINT; Schema: synchronomade; Owner: -; Tablespace: 
--

ALTER TABLE ONLY erreurs_inv
    ADD CONSTRAINT erreurs_inv_pkey PRIMARY KEY (id);

--------------------------------------------------------------------------------------
--------------------INSERTION DES DONNEES DES TABLES DICTIONNAIRES--------------------
--------------------------------------------------------------------------------------

SET search_path = contactinv, pg_catalog;

INSERT INTO bib_criteres_inv (id_critere_inv, code_critere_inv, nom_critere_inv, tri_inv, id_critere_synthese) VALUES (1, '1', 'larve, oeuf, chenille, nymphe...', 1, 101);
INSERT INTO bib_criteres_inv (id_critere_inv, code_critere_inv, nom_critere_inv, tri_inv, id_critere_synthese) VALUES (2, '2', 'adultes en parade nuptiale...', 2, 102);
INSERT INTO bib_criteres_inv (id_critere_inv, code_critere_inv, nom_critere_inv, tri_inv, id_critere_synthese) VALUES (5, '5', 'autres indices', 5, 105);
INSERT INTO bib_criteres_inv (id_critere_inv, code_critere_inv, nom_critere_inv, tri_inv, id_critere_synthese) VALUES (3, '3', 'adulte observé de corps', 3, 103);
INSERT INTO bib_criteres_inv (id_critere_inv, code_critere_inv, nom_critere_inv, tri_inv, id_critere_synthese) VALUES (8, '8', 'animal mort', 8, 2);

INSERT INTO bib_milieux_inv (id_milieu_inv, nom_milieu_inv) VALUES (0, 'Indéterminé');
INSERT INTO bib_milieux_inv (id_milieu_inv, nom_milieu_inv) VALUES (11, 'Friche');
INSERT INTO bib_milieux_inv (id_milieu_inv, nom_milieu_inv) VALUES (12, 'Prairie');
INSERT INTO bib_milieux_inv (id_milieu_inv, nom_milieu_inv) VALUES (13, 'Culture');
INSERT INTO bib_milieux_inv (id_milieu_inv, nom_milieu_inv) VALUES (14, 'Jardin');
INSERT INTO bib_milieux_inv (id_milieu_inv, nom_milieu_inv) VALUES (15, 'Vigne');
INSERT INTO bib_milieux_inv (id_milieu_inv, nom_milieu_inv) VALUES (16, 'Verger');
INSERT INTO bib_milieux_inv (id_milieu_inv, nom_milieu_inv) VALUES (17, 'Haie');
INSERT INTO bib_milieux_inv (id_milieu_inv, nom_milieu_inv) VALUES (18, 'Reposoir');
INSERT INTO bib_milieux_inv (id_milieu_inv, nom_milieu_inv) VALUES (19, 'Habitat, ruine, route');
INSERT INTO bib_milieux_inv (id_milieu_inv, nom_milieu_inv) VALUES (20, 'Combe à neige');
INSERT INTO bib_milieux_inv (id_milieu_inv, nom_milieu_inv) VALUES (21, 'Pelouse');
INSERT INTO bib_milieux_inv (id_milieu_inv, nom_milieu_inv) VALUES (22, 'Lande');
INSERT INTO bib_milieux_inv (id_milieu_inv, nom_milieu_inv) VALUES (23, 'Fourré');
INSERT INTO bib_milieux_inv (id_milieu_inv, nom_milieu_inv) VALUES (24, 'Bois, Futaie');
INSERT INTO bib_milieux_inv (id_milieu_inv, nom_milieu_inv) VALUES (25, 'Ripisylve');
INSERT INTO bib_milieux_inv (id_milieu_inv, nom_milieu_inv) VALUES (26, 'Clairière');
INSERT INTO bib_milieux_inv (id_milieu_inv, nom_milieu_inv) VALUES (27, 'Reboisement (jeune)');
INSERT INTO bib_milieux_inv (id_milieu_inv, nom_milieu_inv) VALUES (28, 'Taillis');
INSERT INTO bib_milieux_inv (id_milieu_inv, nom_milieu_inv) VALUES (31, 'Arête');
INSERT INTO bib_milieux_inv (id_milieu_inv, nom_milieu_inv) VALUES (32, 'Barre');
INSERT INTO bib_milieux_inv (id_milieu_inv, nom_milieu_inv) VALUES (33, 'Falaise, grotte');
INSERT INTO bib_milieux_inv (id_milieu_inv, nom_milieu_inv) VALUES (34, 'Moraine');
INSERT INTO bib_milieux_inv (id_milieu_inv, nom_milieu_inv) VALUES (35, 'Eboulis');
INSERT INTO bib_milieux_inv (id_milieu_inv, nom_milieu_inv) VALUES (36, 'Roc, bloc');
INSERT INTO bib_milieux_inv (id_milieu_inv, nom_milieu_inv) VALUES (37, 'Gravière');
INSERT INTO bib_milieux_inv (id_milieu_inv, nom_milieu_inv) VALUES (41, 'Tourbière');
INSERT INTO bib_milieux_inv (id_milieu_inv, nom_milieu_inv) VALUES (42, 'Mare');
INSERT INTO bib_milieux_inv (id_milieu_inv, nom_milieu_inv) VALUES (43, 'Marais');
INSERT INTO bib_milieux_inv (id_milieu_inv, nom_milieu_inv) VALUES (44, 'Etang');
INSERT INTO bib_milieux_inv (id_milieu_inv, nom_milieu_inv) VALUES (45, 'Lac');
INSERT INTO bib_milieux_inv (id_milieu_inv, nom_milieu_inv) VALUES (46, 'Ruisseau');
INSERT INTO bib_milieux_inv (id_milieu_inv, nom_milieu_inv) VALUES (47, 'Torrent');
INSERT INTO bib_milieux_inv (id_milieu_inv, nom_milieu_inv) VALUES (48, 'Rivière');
INSERT INTO bib_milieux_inv (id_milieu_inv, nom_milieu_inv) VALUES (49, 'Neige, glace (permanente)');
INSERT INTO bib_milieux_inv (id_milieu_inv, nom_milieu_inv) VALUES (88, 'Atmosphère');


--------------------------------------------------------------------------------------
--------------------AJOUT DU MODULE DANS LES TABLES DE DESCRIPTION--------------------
--------------------------------------------------------------------------------------

SET search_path = meta, pg_catalog;
INSERT INTO bib_programmes (id_programme, nom_programme, desc_programme, actif, programme_public, desc_programme_public) VALUES (3, 'Contact invertébrés', 'Contact aléatoire de la faune invertébrée.', true, true, 'Contact aléatoire de la faune invertébrée.');
INSERT INTO bib_lots (id_lot, nom_lot, desc_lot, menu_cf, pn, menu_inv, id_programme) VALUES (3, 'Contact invertébrés', 'Contact invertébrés', false, true, false, 3);
INSERT INTO t_protocoles VALUES (3, 'contact invertébrés', 'à compléter', 'à compléter', 'à compléter', 'non', NULL, NULL);
SET search_path = synthese, pg_catalog;
INSERT INTO bib_sources (id_source, nom_source, desc_source, host, port, username, pass, db_name, db_schema, db_table, db_field, url, target, picto, groupe, actif) VALUES (3, 'Contact invertébrés', 'contenu des tables t_fiches_inv et t_releves_inv de la base faune postgres', 'localhost', 22, NULL, NULL, 'geonaturedb', 'contactinv', 't_releves_inv', 'id_releve_inv', 'invertebre', NULL, 'images/pictos/insecte.gif', 'FAUNE', true);


--------------------------------------------------------------------------------------
--------------------AJOUT DU MODULE DANS LES TABLES SPATIALES-------------------------
--------------------------------------------------------------------------------------

SET search_path = public, pg_catalog;
INSERT INTO geometry_columns (f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, type) VALUES ('', 'contactinv', 't_fiches_inv', 'the_geom_2154', 2, 2154, 'POINT');
INSERT INTO geometry_columns (f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, type) VALUES ('', 'contactinv', 't_fiches_inv', 'the_geom_3857', 2, 3857, 'POINT');
INSERT INTO geometry_columns (f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, type) VALUES ('', 'contactinv', 'v_nomade_unites_geo_inv', 'the_geom', 2, 2154, 'MULTIPOLYGON');
