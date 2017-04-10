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
-- TOC entry 9 (class 2615 OID 2747596)
-- Name: contactfaune; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA contactfaune;


--
-- TOC entry 3958 (class 0 OID 0)
-- Dependencies: 9
-- Name: SCHEMA contactfaune; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA contactfaune IS 'schéma contenant les données et les bibliothèques du protocole contact faune';


SET search_path = contactfaune, pg_catalog;

--
-- TOC entry 1524 (class 1255 OID 2832060)
-- Name: calcul_cor_unite_taxon_cfaune(integer, integer); Type: FUNCTION; Schema: contactfaune; Owner: -
--

CREATE FUNCTION calcul_cor_unite_taxon_cfaune(monidtaxon integer, monunite integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
  DECLARE
  cdnom integer;
  BEGIN
	--récup du cd_nom du taxon
	SELECT INTO cdnom cd_nom FROM taxonomie.bib_noms WHERE id_nom = monidtaxon;
	DELETE FROM contactfaune.cor_unite_taxon WHERE id_unite_geo = monunite AND id_nom = monidtaxon;
	INSERT INTO contactfaune.cor_unite_taxon (id_unite_geo,id_nom,derniere_date,couleur,nb_obs)
	SELECT monunite, monidtaxon,  max(dateobs) AS derniere_date, contactfaune.couleur_taxon(monidtaxon,max(dateobs)) AS couleur, count(id_synthese) AS nb_obs
	FROM synthese.cor_unite_synthese
	WHERE cd_nom = cdnom
	AND id_unite_geo = monunite;
  END;
$$;


--
-- TOC entry 1459 (class 1255 OID 2747609)
-- Name: couleur_taxon(integer, date); Type: FUNCTION; Schema: contactfaune; Owner: -
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
-- TOC entry 1488 (class 1255 OID 2747610)
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
		new.the_geom_3857 = public.st_transform(new.the_geom_2154,3857);
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
-- TOC entry 1490 (class 1255 OID 2747611)
-- Name: insert_releve_cf(); Type: FUNCTION; Schema: contactfaune; Owner: -
--

CREATE FUNCTION insert_releve_cf() RETURNS trigger
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
    -- MAJ de la table cor_unite_taxon, on commence par récupérer l'unité à partir du pointage (table t_fiches_cf)
	SELECT INTO fiche * FROM contactfaune.t_fiches_cf WHERE id_cf = new.id_cf;
	SELECT INTO unite u.id_unite_geo FROM layers.l_unites_geo u WHERE public.st_intersects(fiche.the_geom_2154,u.the_geom);
	--si on est dans une des unités on peut mettre à jour la table cor_unite_taxon, sinon on fait rien
	IF unite>0 THEN
		SELECT INTO line * FROM contactfaune.cor_unite_taxon WHERE id_unite_geo = unite AND id_nom = new.id_nom;
		--si la ligne existe dans cor_unite_taxon on la supprime
		IF line IS NOT NULL THEN
			DELETE FROM contactfaune.cor_unite_taxon WHERE id_unite_geo = unite AND id_nom = new.id_nom;
		END IF;
		--on compte le nombre d'enregistrement pour ce taxon dans l'unité
		SELECT INTO nbobs count(*) from synthese.syntheseff s
		JOIN layers.l_unites_geo u ON public.st_intersects(u.the_geom, s.the_geom_2154) AND u.id_unite_geo = unite
		WHERE s.cd_nom = cdnom;
		--on créé ou recréé la ligne
		INSERT INTO contactfaune.cor_unite_taxon VALUES(unite,new.id_nom,fiche.dateobs,contactfaune.couleur_taxon(new.id_nom,fiche.dateobs), nbobs+1);
	END IF;
	RETURN NEW; 			
END;
$$;


--
-- TOC entry 1525 (class 1255 OID 2832061)
-- Name: maj_cor_unite_taxon_cfaune(); Type: FUNCTION; Schema: contactfaune; Owner: -
--

CREATE FUNCTION maj_cor_unite_taxon_cfaune() RETURNS trigger
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
			-- puis recalul des couleurs avec old.id_unite_geo et old.taxon pour les vertébrés
			IF monembranchement = 'Chordata' THEN
				IF (SELECT count(*) FROM synthese.cor_unite_synthese WHERE cd_nom = old.cd_nom AND id_unite_geo = old.id_unite_geo)= 0 THEN
						DELETE FROM contactfaune.cor_unite_taxon WHERE id_nom = monidtaxon AND id_unite_geo = old.id_unite_geo;
				ELSE
						PERFORM contactfaune.calcul_cor_unite_taxon_cfaune(monidtaxon, old.id_unite_geo);
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
			-- puis recalul des couleurs avec new.id_unite_geo et new.taxon pour un taxon vertébrés
			IF monembranchement = 'Chordata' THEN
			    PERFORM contactfaune.calcul_cor_unite_taxon_cfaune(monidtaxon, new.id_unite_geo);
			END IF;
		END IF;
		RETURN NEW;
	END IF;
END;
$$;


--
-- TOC entry 1461 (class 1255 OID 2747612)
-- Name: synthese_delete_releve_cf(); Type: FUNCTION; Schema: contactfaune; Owner: -
--

CREATE FUNCTION synthese_delete_releve_cf() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    idsource integer;
    nbreleves integer;
BEGIN
    --SUPRESSION EN SYNTHESE
    SELECT INTO idsource id_source FROM synthese.bib_sources  WHERE db_schema='contactfaune' AND db_field = 'id_releve_cf' ;
    DELETE FROM synthese.syntheseff WHERE id_source = idsource AND id_fiche_source = old.id_releve_cf::text;
    -- SUPPRESSION DE LA FICHE S'IL N'Y A PLUS DE RELEVE
    SELECT INTO nbreleves count(*) FROM contactfaune.t_releves_cf WHERE id_cf = old.id_cf;
    IF nbreleves < 1 THEN
	DELETE FROM contactfaune.t_fiches_cf WHERE id_cf = old.id_cf;
    END IF;
    RETURN OLD; 
END;
$$;


--
-- TOC entry 1491 (class 1255 OID 2747613)
-- Name: synthese_insert_releve_cf(); Type: FUNCTION; Schema: contactfaune; Owner: -
--

CREATE FUNCTION synthese_insert_releve_cf() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
	fiche RECORD;
	mesobservateurs character varying(255);
	criteresynthese integer;
	idsource integer;
	idsourcem integer;
	idsourcecf integer;
	unite integer;
    cdnom integer;
BEGIN
	--Récupération des données id_source dans la table synthese.bib_sources
	SELECT INTO idsourcem id_source FROM synthese.bib_sources  WHERE db_schema='contactfaune' AND db_field = 'id_releve_cf' AND nom_source = 'Mortalité';
	SELECT INTO idsourcecf id_source FROM synthese.bib_sources  WHERE db_schema='contactfaune' AND db_field = 'id_releve_cf' AND nom_source = 'Contact faune';
	--récup du cd_nom du taxon
	SELECT INTO cdnom cd_nom FROM taxonomie.bib_noms WHERE id_nom = new.id_nom;
    --Récupération des données dans la table t_fiches_cf et de la liste des observateurs
	SELECT INTO fiche * FROM contactfaune.t_fiches_cf WHERE id_cf = new.id_cf;
	SELECT INTO criteresynthese id_critere_synthese FROM contactfaune.bib_criteres_cf WHERE id_critere_cf = new.id_critere_cf;
	-- Récupération du id_source selon le critère d'observation, Si critère = 2 alors on est dans une source mortalité (=2) sinon cf (=1)
	IF criteresynthese = 2 THEN idsource = idsourcem;
	ELSE
	    idsource = idsourcecf;
	END IF;
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
	new.am+new.af+new.ai+new.na+new.jeune+new.yearling+new.sai
	);
	RETURN NEW; 			
END;
$$;


--
-- TOC entry 1463 (class 1255 OID 2747614)
-- Name: synthese_update_cor_role_fiche_cf(); Type: FUNCTION; Schema: contactfaune; Owner: -
--

CREATE FUNCTION synthese_update_cor_role_fiche_cf() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    releves RECORD;
    test integer;
    mesobservateurs character varying(255);
    sources RECORD;
    idsource integer;
    idsourcem integer;
    idsourcecf integer;
BEGIN
    --
    --CE TRIGGER NE DEVRAIT SERVIR QU'EN CAS DE MISE A JOUR MANUELLE SUR CETTE TABLE cor_role_fiche_cf
    --L'APPLI WEB ET LES TABLETTES NE FONT QUE DES INSERTS QUI SONT GERER PAR LE TRIGGER INSERT DE t_releves_cf
    --
        --on doit boucler pour récupérer le id_source car il y en a 2 possibles (cf et mortalité) pour le même schéma
    FOR sources IN SELECT id_source, url  FROM synthese.bib_sources WHERE db_schema='contactfaune' AND db_field = 'id_releve_cf' LOOP
        IF sources.url = 'cf' THEN
            idsourcecf = sources.id_source;
        ELSIF sources.url = 'mortalite' THEN
            idsourcem = sources.id_source;
        END IF;
    END LOOP;
    
    --Récupération des enregistrements de la table t_releves_cf avec l'id_cf de la table cor_role_fiche_cf
    FOR releves IN SELECT * FROM contactfaune.t_releves_cf WHERE id_cf = new.id_cf LOOP
        --test si on a bien l'enregistrement dans la table syntheseff avant de le mettre à jour
        SELECT INTO test id_fiche_source FROM synthese.syntheseff 
        WHERE (id_source = idsourcem OR id_source = idsourcecf) AND id_fiche_source = releves.id_releve_cf::text;
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
            WHERE (id_source = idsourcem OR id_source = idsourcecf) AND id_fiche_source = releves.id_releve_cf::text; 
        END IF;
    END LOOP;
    RETURN NEW; 
END;
$$;


--
-- TOC entry 1464 (class 1255 OID 2747615)
-- Name: synthese_update_fiche_cf(); Type: FUNCTION; Schema: contactfaune; Owner: -
--

CREATE FUNCTION synthese_update_fiche_cf() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    releves RECORD;
    test integer;
    mesobservateurs character varying(255);
    sources RECORD;
    idsourcem integer;
    idsourcecf integer;
BEGIN

    --on doit boucler pour récupérer le id_source car il y en a 2 possibles (cf et mortalité) pour le même schéma
    FOR sources IN SELECT id_source, url  FROM synthese.bib_sources WHERE db_schema='contactfaune' AND db_field = 'id_releve_cf' LOOP
	IF sources.url = 'cf' THEN
	    idsourcecf = sources.id_source;
	ELSIF sources.url = 'mortalite' THEN
	    idsourcem = sources.id_source;
	END IF;
    END LOOP;
	--Récupération des données de la table t_releves_cf avec l'id_cf de la fiche modifié
	-- Ici on utilise le OLD id_cf pour être sur qu'il existe dans la table synthese (cas improbable où on changerait la pk de la table t_fiches_cf
	--le trigger met à jour avec le NEW --> SET code_fiche_source =  ....
	FOR releves IN SELECT * FROM contactfaune.t_releves_cf WHERE id_cf = old.id_cf LOOP
		--test si on a bien l'enregistrement dans la table syntheseff avant de le mettre à jour
		SELECT INTO test id_fiche_source FROM synthese.syntheseff WHERE id_fiche_source = releves.id_releve_cf::text AND (id_source = idsourcecf OR id_source = idsourcem);
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
			IF NOT public.st_equals(new.the_geom_3857,old.the_geom_3857) OR NOT public.st_equals(new.the_geom_2154,old.the_geom_2154) THEN
				
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
				WHERE id_fiche_source = releves.id_releve_cf::text AND (id_source = idsourcecf OR id_source = idsourcem) ;
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
			    WHERE id_fiche_source = releves.id_releve_cf::text AND (id_source = idsourcecf OR id_source = idsourcem);
			END IF;
		END IF;
	END LOOP;
	RETURN NEW; 			
END;
$$;


--
-- TOC entry 1519 (class 1255 OID 2747616)
-- Name: synthese_update_releve_cf(); Type: FUNCTION; Schema: contactfaune; Owner: -
--

CREATE FUNCTION synthese_update_releve_cf() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    test integer;
    criteresynthese integer;
    sources RECORD;
    idsourcem integer;
    idsourcecf integer;
    cdnom integer;
    nbreleves integer;
BEGIN
    
	--on doit boucler pour récupérer le id_source car il y en a 2 possibles (cf et mortalité) pour le même schéma
        FOR sources IN SELECT id_source, url  FROM synthese.bib_sources WHERE db_schema='contactfaune' AND db_field = 'id_releve_cf' LOOP
	    IF sources.url = 'cf' THEN
	        idsourcecf = sources.id_source;
	    ELSIF sources.url = 'mortalite' THEN
	        idsourcem = sources.id_source;
	    END IF;
        END LOOP;
    --récup du cd_nom du taxon
	SELECT INTO cdnom cd_nom FROM taxonomie.bib_noms WHERE id_nom = new.id_nom;
	--test si on a bien l'enregistrement dans la table syntheseff avant de le mettre à jour
	SELECT INTO test id_fiche_source FROM synthese.syntheseff WHERE id_fiche_source = old.id_releve_cf::text AND (id_source = idsourcecf OR id_source = idsourcem);
	IF test IS NOT NULL THEN
		SELECT INTO criteresynthese id_critere_synthese FROM contactfaune.bib_criteres_cf WHERE id_critere_cf = new.id_critere_cf;

		--mise à jour de l'enregistrement correspondant dans syntheseff
		UPDATE synthese.syntheseff SET
			id_fiche_source = new.id_releve_cf,
			code_fiche_source = 'f'||new.id_cf||'-r'||new.id_releve_cf,
			cd_nom = cdnom,
			remarques = new.commentaire,
			determinateur = new.determinateur,
			derniere_action = 'u',
			supprime = new.supprime,
			id_critere_synthese = criteresynthese,
			effectif_total = new.am+new.af+new.ai+new.na+new.jeune+new.yearling+new.sai
		WHERE id_fiche_source = old.id_releve_cf::text AND (id_source = idsourcecf OR id_source = idsourcem); -- Ici on utilise le OLD id_releve_cf pour être sur 
		--qu'il existe dans la table synthese (cas improbable où on changerait la pk de la table t_releves_cf
		--le trigger met à jour avec le NEW --> SET id_fiche_source = new.id_releve_cf
	END IF;
	-- SUPPRESSION (supprime = true) DE LA FICHE S'IL N'Y A PLUS DE RELEVE (supprime = false)
	SELECT INTO nbreleves count(*) FROM contactfaune.t_releves_cf WHERE id_cf = new.id_cf AND supprime = false;
	IF nbreleves < 1 THEN
		UPDATE contactfaune.t_fiches_cf SET supprime = true WHERE id_cf = new.id_cf;
	END IF;
	RETURN NEW; 			
END;
$$;


--
-- TOC entry 1521 (class 1255 OID 2747617)
-- Name: update_fiche_cf(); Type: FUNCTION; Schema: contactfaune; Owner: -
--

CREATE FUNCTION update_fiche_cf() RETURNS trigger
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
--- divers update
IF new.altitude_saisie <> old.altitude_saisie THEN
   new.altitude_retenue = new.altitude_saisie;
END IF;
new.date_update = 'now';
IF new.supprime <> old.supprime THEN	 
  IF new.supprime = 't' THEN
     --Pour éviter un bouclage des triggers, on vérifie qu'il y a bien des relevés non supprimés à modifier
     SELECT INTO nbreleves count(*) FROM contactfaune.t_releves_cf WHERE id_cf = old.id_cf AND supprime = false;
     IF nbreleves > 0 THEN
	update contactfaune.t_releves_cf set supprime = 't' WHERE id_cf = old.id_cf; 
     END IF;
  END IF;
  IF new.supprime = 'f' THEN
     --action discutable. S'il y a des relevés douteux dans la fiche, il faut les garder supprimés
     --update contactfaune.t_releves_cf set supprime = 'f' WHERE id_cf = old.id_cf; 
  END IF;
END IF;
RETURN NEW; 
END;
$$;


--
-- TOC entry 1469 (class 1255 OID 2747618)
-- Name: update_releve_cf(); Type: FUNCTION; Schema: contactfaune; Owner: -
--

CREATE FUNCTION update_releve_cf() RETURNS trigger
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
-- TOC entry 246 (class 1259 OID 2747670)
-- Name: bib_criteres_cf; Type: TABLE; Schema: contactfaune; Owner: -
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
-- TOC entry 247 (class 1259 OID 2747673)
-- Name: bib_messages_cf; Type: TABLE; Schema: contactfaune; Owner: -
--

CREATE TABLE bib_messages_cf (
    id_message_cf integer NOT NULL,
    texte_message_cf character varying(255)
);


--
-- TOC entry 248 (class 1259 OID 2747676)
-- Name: cor_critere_liste; Type: TABLE; Schema: contactfaune; Owner: -
--

CREATE TABLE cor_critere_liste (
    id_critere_cf integer NOT NULL,
    id_liste integer NOT NULL
);


--
-- TOC entry 249 (class 1259 OID 2747679)
-- Name: cor_message_taxon; Type: TABLE; Schema: contactfaune; Owner: -
--

CREATE TABLE cor_message_taxon (
    id_message_cf integer NOT NULL,
    id_nom integer NOT NULL
);


--
-- TOC entry 250 (class 1259 OID 2747682)
-- Name: cor_role_fiche_cf; Type: TABLE; Schema: contactfaune; Owner: -
--

CREATE TABLE cor_role_fiche_cf (
    id_cf bigint NOT NULL,
    id_role integer NOT NULL
);


--
-- TOC entry 251 (class 1259 OID 2747685)
-- Name: cor_unite_taxon; Type: TABLE; Schema: contactfaune; Owner: -
--

CREATE TABLE cor_unite_taxon (
    id_unite_geo integer NOT NULL,
    id_nom integer NOT NULL,
    derniere_date date,
    couleur character varying(10) NOT NULL,
    nb_obs integer
);


--
-- TOC entry 252 (class 1259 OID 2747688)
-- Name: log_colors; Type: TABLE; Schema: contactfaune; Owner: -
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
-- TOC entry 253 (class 1259 OID 2747694)
-- Name: log_colors_day; Type: TABLE; Schema: contactfaune; Owner: -
--

CREATE TABLE log_colors_day (
    jour date NOT NULL,
    couleur character varying NOT NULL,
    nbtaxons numeric
);


--
-- TOC entry 254 (class 1259 OID 2747700)
-- Name: t_fiches_cf; Type: TABLE; Schema: contactfaune; Owner: -
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
-- TOC entry 255 (class 1259 OID 2747713)
-- Name: t_releves_cf; Type: TABLE; Schema: contactfaune; Owner: -
--

CREATE TABLE t_releves_cf (
    id_releve_cf bigint NOT NULL,
    id_cf bigint NOT NULL,
    id_nom integer NOT NULL,
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
-- TOC entry 256 (class 1259 OID 2747721)
-- Name: t_releves_cf_gid_seq; Type: SEQUENCE; Schema: contactfaune; Owner: -
--

CREATE SEQUENCE t_releves_cf_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 3959 (class 0 OID 0)
-- Dependencies: 256
-- Name: t_releves_cf_gid_seq; Type: SEQUENCE OWNED BY; Schema: contactfaune; Owner: -
--

ALTER SEQUENCE t_releves_cf_gid_seq OWNED BY t_releves_cf.gid;


--
-- TOC entry 296 (class 1259 OID 2747921)
-- Name: v_nomade_classes; Type: VIEW; Schema: contactfaune; Owner: -
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
          WHERE (l.id_liste = ANY (ARRAY[1, 11, 12, 13, 14]))
          GROUP BY l.id_liste, l.nom_liste, l.desc_liste) g
     JOIN taxonomie.taxref t ON ((t.cd_nom = g.cd_ref)))
  WHERE ((t.phylum)::text = 'Chordata'::text);


--
-- TOC entry 294 (class 1259 OID 2747912)
-- Name: v_nomade_criteres_cf; Type: VIEW; Schema: contactfaune; Owner: -
--

CREATE VIEW v_nomade_criteres_cf AS
 SELECT c.id_critere_cf,
    c.nom_critere_cf,
    c.tri_cf,
    ccl.id_liste AS id_classe
   FROM (bib_criteres_cf c
     JOIN cor_critere_liste ccl ON ((ccl.id_critere_cf = c.id_critere_cf)))
  ORDER BY ccl.id_liste, c.tri_cf;


--
-- TOC entry 295 (class 1259 OID 2747916)
-- Name: v_nomade_observateurs_faune; Type: VIEW; Schema: contactfaune; Owner: -
--

CREATE VIEW v_nomade_observateurs_faune AS
 SELECT DISTINCT r.id_role,
    r.nom_role,
    r.prenom_role
   FROM utilisateurs.t_roles r
  WHERE ((r.id_role IN ( SELECT DISTINCT cr.id_role_utilisateur
           FROM utilisateurs.cor_roles cr
          WHERE (cr.id_role_groupe IN ( SELECT crm.id_role
                   FROM utilisateurs.cor_role_menu crm
                  WHERE (crm.id_menu = 9)))
          ORDER BY cr.id_role_utilisateur)) OR (r.id_role IN ( SELECT crm.id_role
           FROM (utilisateurs.cor_role_menu crm
             JOIN utilisateurs.t_roles r_1 ON ((((r_1.id_role = crm.id_role) AND (crm.id_menu = 9)) AND (r_1.groupe = false)))))))
  ORDER BY r.nom_role, r.prenom_role, r.id_role;


--
-- TOC entry 297 (class 1259 OID 2747926)
-- Name: v_nomade_taxons_faune; Type: VIEW; Schema: contactfaune; Owner: -
--

CREATE VIEW v_nomade_taxons_faune AS
  SELECT DISTINCT n.id_nom,
    taxonomie.find_cdref(tx.cd_nom) AS cd_ref,
    tx.cd_nom,
    tx.lb_nom AS nom_latin,
    n.nom_francais,
    g.id_classe,
        CASE
            WHEN tx.cd_nom = ANY (ARRAY[61098, 61119, 61000]) THEN 6
            ELSE 5
        END AS denombrement,
    f2.bool AS patrimonial,
    m.texte_message_cf AS message,
        CASE
            WHEN tx.cd_nom = ANY (ARRAY[60577, 60612]) THEN false
            ELSE true
        END AS contactfaune,
    true AS mortalite
  FROM taxonomie.bib_noms n
     LEFT JOIN cor_message_taxon cmt ON cmt.id_nom = n.id_nom
     LEFT JOIN bib_messages_cf m ON m.id_message_cf = cmt.id_message_cf
     LEFT JOIN taxonomie.cor_taxon_attribut cta ON cta.cd_ref = n.cd_ref
     JOIN taxonomie.cor_nom_liste cnl ON cnl.id_nom = n.id_nom
     JOIN v_nomade_classes g ON g.id_classe = cnl.id_liste
     JOIN taxonomie.taxref tx ON tx.cd_nom = n.cd_nom
     JOIN public.cor_boolean f2 ON f2.expression::text = cta.valeur_attribut AND cta.id_attribut = 1
  WHERE n.id_nom IN(SELECT id_nom FROM taxonomie.cor_nom_liste WHERE id_liste = 500)
  ORDER BY n.id_nom, taxonomie.find_cdref(tx.cd_nom), tx.lb_nom, n.nom_francais, g.id_classe, f2.bool, m.texte_message_cf;


--
-- TOC entry 299 (class 1259 OID 2747940)
-- Name: v_nomade_unites_geo_cf; Type: VIEW; Schema: contactfaune; Owner: -
--

CREATE VIEW v_nomade_unites_geo_cf AS
 SELECT public.st_simplifypreservetopology(l_unites_geo.the_geom, (15)::double precision) AS the_geom,
    l_unites_geo.id_unite_geo
   FROM layers.l_unites_geo
  GROUP BY l_unites_geo.the_geom, l_unites_geo.id_unite_geo;


--
-- TOC entry 3734 (class 2604 OID 2748286)
-- Name: gid; Type: DEFAULT; Schema: contactfaune; Owner: -
--

ALTER TABLE ONLY t_releves_cf ALTER COLUMN gid SET DEFAULT nextval('t_releves_cf_gid_seq'::regclass);


--
-- TOC entry 3737 (class 2606 OID 2748301)
-- Name: pk_bib_criteres_cf; Type: CONSTRAINT; Schema: contactfaune; Owner: -
--

ALTER TABLE ONLY bib_criteres_cf
    ADD CONSTRAINT pk_bib_criteres_cf PRIMARY KEY (id_critere_cf);


--
-- TOC entry 3739 (class 2606 OID 2748303)
-- Name: pk_bib_types_comptage; Type: CONSTRAINT; Schema: contactfaune; Owner: -
--

ALTER TABLE ONLY bib_messages_cf
    ADD CONSTRAINT pk_bib_types_comptage PRIMARY KEY (id_message_cf);


--
-- TOC entry 3743 (class 2606 OID 2748305)
-- Name: pk_cor_critere_liste; Type: CONSTRAINT; Schema: contactfaune; Owner: -
--

ALTER TABLE ONLY cor_critere_liste
    ADD CONSTRAINT pk_cor_critere_liste PRIMARY KEY (id_critere_cf, id_liste);


--
-- TOC entry 3747 (class 2606 OID 2748307)
-- Name: pk_cor_message_taxon; Type: CONSTRAINT; Schema: contactfaune; Owner: -
--

ALTER TABLE ONLY cor_message_taxon
    ADD CONSTRAINT pk_cor_message_taxon PRIMARY KEY (id_message_cf, id_nom);


--
-- TOC entry 3751 (class 2606 OID 2748309)
-- Name: pk_cor_role_fiche_cf; Type: CONSTRAINT; Schema: contactfaune; Owner: -
--

ALTER TABLE ONLY cor_role_fiche_cf
    ADD CONSTRAINT pk_cor_role_fiche_cf PRIMARY KEY (id_cf, id_role);


--
-- TOC entry 3755 (class 2606 OID 2748311)
-- Name: pk_cor_unite_taxon; Type: CONSTRAINT; Schema: contactfaune; Owner: -
--

ALTER TABLE ONLY cor_unite_taxon
    ADD CONSTRAINT pk_cor_unite_taxon PRIMARY KEY (id_unite_geo, id_nom);


--
-- TOC entry 3757 (class 2606 OID 2748313)
-- Name: pk_log_colors; Type: CONSTRAINT; Schema: contactfaune; Owner: -
--

ALTER TABLE ONLY log_colors
    ADD CONSTRAINT pk_log_colors PRIMARY KEY (annee, mois, id_unite_geo, couleur);


--
-- TOC entry 3759 (class 2606 OID 2748315)
-- Name: pk_log_colors_day; Type: CONSTRAINT; Schema: contactfaune; Owner: -
--

ALTER TABLE ONLY log_colors_day
    ADD CONSTRAINT pk_log_colors_day PRIMARY KEY (jour, couleur);


--
-- TOC entry 3762 (class 2606 OID 2748317)
-- Name: pk_t_fiches_cf; Type: CONSTRAINT; Schema: contactfaune; Owner: -
--

ALTER TABLE ONLY t_fiches_cf
    ADD CONSTRAINT pk_t_fiches_cf PRIMARY KEY (id_cf);


--
-- TOC entry 3767 (class 2606 OID 2748319)
-- Name: pk_t_releves_cf; Type: CONSTRAINT; Schema: contactfaune; Owner: -
--

ALTER TABLE ONLY t_releves_cf
    ADD CONSTRAINT pk_t_releves_cf PRIMARY KEY (id_releve_cf);


--
-- TOC entry 3735 (class 1259 OID 2748448)
-- Name: fki_; Type: INDEX; Schema: contactfaune; Owner: -
--

CREATE INDEX fki_ ON bib_criteres_cf USING btree (id_critere_synthese);


--
-- TOC entry 3740 (class 1259 OID 2748450)
-- Name: i_fk_cor_critere_liste_bib_cr; Type: INDEX; Schema: contactfaune; Owner: -
--

CREATE INDEX i_fk_cor_critere_liste_bib_cr ON cor_critere_liste USING btree (id_critere_cf);


--
-- TOC entry 3741 (class 1259 OID 2748449)
-- Name: i_fk_cor_critere_liste_bib_li; Type: INDEX; Schema: contactfaune; Owner: -
--

CREATE INDEX i_fk_cor_critere_liste_bib_li ON cor_critere_liste USING btree (id_liste);


--
-- TOC entry 3744 (class 1259 OID 2748451)
-- Name: i_fk_cor_message_cf_bib_me; Type: INDEX; Schema: contactfaune; Owner: -
--

CREATE INDEX i_fk_cor_message_cf_bib_me ON cor_message_taxon USING btree (id_message_cf);


--
-- TOC entry 3745 (class 1259 OID 2748452)
-- Name: i_fk_cor_message_cf_bib_noms; Type: INDEX; Schema: contactfaune; Owner: -
--

CREATE INDEX i_fk_cor_message_cf_bib_noms ON cor_message_taxon USING btree (id_nom);


--
-- TOC entry 3748 (class 1259 OID 2748453)
-- Name: i_fk_cor_role_fiche_cf_t_fiche; Type: INDEX; Schema: contactfaune; Owner: -
--

CREATE INDEX i_fk_cor_role_fiche_cf_t_fiche ON cor_role_fiche_cf USING btree (id_cf);


--
-- TOC entry 3749 (class 1259 OID 2748454)
-- Name: i_fk_cor_role_fiche_cf_t_roles; Type: INDEX; Schema: contactfaune; Owner: -
--

CREATE INDEX i_fk_cor_role_fiche_cf_t_roles ON cor_role_fiche_cf USING btree (id_role);


--
-- TOC entry 3752 (class 1259 OID 2748455)
-- Name: i_fk_cor_unite_taxon_bib_noms; Type: INDEX; Schema: contactfaune; Owner: -
--

CREATE INDEX i_fk_cor_unite_taxon_bib_noms ON cor_unite_taxon USING btree (id_nom);


--
-- TOC entry 3753 (class 1259 OID 2748456)
-- Name: i_fk_cor_unite_taxon_l_unites_; Type: INDEX; Schema: contactfaune; Owner: -
--

CREATE INDEX i_fk_cor_unite_taxon_l_unites_ ON cor_unite_taxon USING btree (id_unite_geo);


--
-- TOC entry 3760 (class 1259 OID 2748457)
-- Name: i_fk_t_fiches_cf_l_communes; Type: INDEX; Schema: contactfaune; Owner: -
--

CREATE INDEX i_fk_t_fiches_cf_l_communes ON t_fiches_cf USING btree (insee);


--
-- TOC entry 3763 (class 1259 OID 2748458)
-- Name: i_fk_t_releves_cf_bib_criteres; Type: INDEX; Schema: contactfaune; Owner: -
--

CREATE INDEX i_fk_t_releves_cf_bib_criteres ON t_releves_cf USING btree (id_critere_cf);


--
-- TOC entry 3764 (class 1259 OID 2748459)
-- Name: i_fk_t_releves_cf_bib_noms; Type: INDEX; Schema: contactfaune; Owner: -
--

CREATE INDEX i_fk_t_releves_cf_bib_noms ON t_releves_cf USING btree (id_nom);


--
-- TOC entry 3765 (class 1259 OID 2748460)
-- Name: i_fk_t_releves_cf_t_fiches_cf; Type: INDEX; Schema: contactfaune; Owner: -
--

CREATE INDEX i_fk_t_releves_cf_t_fiches_cf ON t_releves_cf USING btree (id_cf);


--
-- TOC entry 3783 (class 2620 OID 2748500)
-- Name: tri_insert_fiche_cf; Type: TRIGGER; Schema: contactfaune; Owner: -
--

CREATE TRIGGER tri_insert_fiche_cf BEFORE INSERT ON t_fiches_cf FOR EACH ROW EXECUTE PROCEDURE insert_fiche_cf();


--
-- TOC entry 3786 (class 2620 OID 2748501)
-- Name: tri_insert_releve_cf; Type: TRIGGER; Schema: contactfaune; Owner: -
--

CREATE TRIGGER tri_insert_releve_cf BEFORE INSERT ON t_releves_cf FOR EACH ROW EXECUTE PROCEDURE insert_releve_cf();


--
-- TOC entry 3787 (class 2620 OID 2748502)
-- Name: tri_synthese_delete_releve_cf; Type: TRIGGER; Schema: contactfaune; Owner: -
--

CREATE TRIGGER tri_synthese_delete_releve_cf AFTER DELETE ON t_releves_cf FOR EACH ROW EXECUTE PROCEDURE synthese_delete_releve_cf();


--
-- TOC entry 3788 (class 2620 OID 2748503)
-- Name: tri_synthese_insert_releve_cf; Type: TRIGGER; Schema: contactfaune; Owner: -
--

CREATE TRIGGER tri_synthese_insert_releve_cf AFTER INSERT ON t_releves_cf FOR EACH ROW EXECUTE PROCEDURE synthese_insert_releve_cf();


--
-- TOC entry 3784 (class 2620 OID 2748504)
-- Name: tri_synthese_update_fiche_cf; Type: TRIGGER; Schema: contactfaune; Owner: -
--

CREATE TRIGGER tri_synthese_update_fiche_cf AFTER UPDATE ON t_fiches_cf FOR EACH ROW EXECUTE PROCEDURE synthese_update_fiche_cf();


--
-- TOC entry 3789 (class 2620 OID 2748505)
-- Name: tri_synthese_update_releve_cf; Type: TRIGGER; Schema: contactfaune; Owner: -
--

CREATE TRIGGER tri_synthese_update_releve_cf AFTER UPDATE ON t_releves_cf FOR EACH ROW EXECUTE PROCEDURE synthese_update_releve_cf();


--
-- TOC entry 3785 (class 2620 OID 2748506)
-- Name: tri_update_fiche_cf; Type: TRIGGER; Schema: contactfaune; Owner: -
--

CREATE TRIGGER tri_update_fiche_cf BEFORE UPDATE ON t_fiches_cf FOR EACH ROW EXECUTE PROCEDURE update_fiche_cf();


--
-- TOC entry 3790 (class 2620 OID 2748507)
-- Name: tri_update_releve_cf; Type: TRIGGER; Schema: contactfaune; Owner: -
--

CREATE TRIGGER tri_update_releve_cf BEFORE UPDATE ON t_releves_cf FOR EACH ROW EXECUTE PROCEDURE update_releve_cf();


--
-- TOC entry 3782 (class 2620 OID 2748508)
-- Name: tri_update_synthese_cor_role_fiche_cf; Type: TRIGGER; Schema: contactfaune; Owner: -
--

CREATE TRIGGER tri_update_synthese_cor_role_fiche_cf AFTER INSERT OR UPDATE ON cor_role_fiche_cf FOR EACH ROW EXECUTE PROCEDURE synthese_update_cor_role_fiche_cf();


--
-- TOC entry 3782 (class 2620 OID 2748508)
-- Name: tri_maj_cor_unite_taxon_cfaune; Type: TRIGGER; Schema: synthese; Owner: -
--

CREATE TRIGGER tri_maj_cor_unite_taxon_cfaune AFTER INSERT OR DELETE ON synthese.cor_unite_synthese FOR EACH ROW EXECUTE PROCEDURE maj_cor_unite_taxon_cfaune();
--
-- TOC entry 3768 (class 2606 OID 2748546)
-- Name: bib_criteres_cf_id_critere_synthese_fkey; Type: FK CONSTRAINT; Schema: contactfaune; Owner: -
--

ALTER TABLE ONLY bib_criteres_cf
    ADD CONSTRAINT bib_criteres_cf_id_critere_synthese_fkey FOREIGN KEY (id_critere_synthese) REFERENCES synthese.bib_criteres_synthese(id_critere_synthese);


--
-- TOC entry 3770 (class 2606 OID 2748556)
-- Name: fk_cor_critere_liste_bib_criter; Type: FK CONSTRAINT; Schema: contactfaune; Owner: -
--

ALTER TABLE ONLY cor_critere_liste
    ADD CONSTRAINT fk_cor_critere_liste_bib_criter FOREIGN KEY (id_critere_cf) REFERENCES bib_criteres_cf(id_critere_cf) ON UPDATE CASCADE;


--
-- TOC entry 3769 (class 2606 OID 2748551)
-- Name: fk_cor_critere_liste_bib_liste; Type: FK CONSTRAINT; Schema: contactfaune; Owner: -
--

ALTER TABLE ONLY cor_critere_liste
    ADD CONSTRAINT fk_cor_critere_liste_bib_liste FOREIGN KEY (id_liste) REFERENCES taxonomie.bib_listes(id_liste) ON UPDATE CASCADE;


--
-- TOC entry 3771 (class 2606 OID 2748561)
-- Name: fk_cor_message_taxon_bib_noms_fa; Type: FK CONSTRAINT; Schema: contactfaune; Owner: -
--

ALTER TABLE ONLY cor_message_taxon
    ADD CONSTRAINT fk_cor_message_taxon_bib_noms_fa FOREIGN KEY (id_nom) REFERENCES taxonomie.bib_noms(id_nom) ON UPDATE CASCADE;


--
-- TOC entry 3772 (class 2606 OID 2748566)
-- Name: fk_cor_message_taxon_l_unites_geo; Type: FK CONSTRAINT; Schema: contactfaune; Owner: -
--

ALTER TABLE ONLY cor_message_taxon
    ADD CONSTRAINT fk_cor_message_taxon_l_unites_geo FOREIGN KEY (id_message_cf) REFERENCES bib_messages_cf(id_message_cf) ON UPDATE CASCADE;


--
-- TOC entry 3773 (class 2606 OID 2748571)
-- Name: fk_cor_role_fiche_cf_t_fiches_cf; Type: FK CONSTRAINT; Schema: contactfaune; Owner: -
--

ALTER TABLE ONLY cor_role_fiche_cf
    ADD CONSTRAINT fk_cor_role_fiche_cf_t_fiches_cf FOREIGN KEY (id_cf) REFERENCES t_fiches_cf(id_cf) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 3774 (class 2606 OID 2748576)
-- Name: fk_cor_role_fiche_cf_t_roles; Type: FK CONSTRAINT; Schema: contactfaune; Owner: -
--

ALTER TABLE ONLY cor_role_fiche_cf
    ADD CONSTRAINT fk_cor_role_fiche_cf_t_roles FOREIGN KEY (id_role) REFERENCES utilisateurs.t_roles(id_role) ON UPDATE CASCADE;


--
-- TOC entry 3775 (class 2606 OID 2748581)
-- Name: fk_cor_unite_taxon_bib_noms_fa; Type: FK CONSTRAINT; Schema: contactfaune; Owner: -
--

ALTER TABLE ONLY cor_unite_taxon
    ADD CONSTRAINT fk_cor_unite_taxon_bib_noms_fa FOREIGN KEY (id_nom) REFERENCES taxonomie.bib_noms(id_nom) ON UPDATE CASCADE;


--
-- TOC entry 3779 (class 2606 OID 2748586)
-- Name: fk_t_releves_cf_bib_criteres_cf; Type: FK CONSTRAINT; Schema: contactfaune; Owner: -
--

ALTER TABLE ONLY t_releves_cf
    ADD CONSTRAINT fk_t_releves_cf_bib_criteres_cf FOREIGN KEY (id_critere_cf) REFERENCES bib_criteres_cf(id_critere_cf) ON UPDATE CASCADE;


--
-- TOC entry 3780 (class 2606 OID 2748591)
-- Name: fk_t_releves_cf_bib_noms; Type: FK CONSTRAINT; Schema: contactfaune; Owner: -
--

ALTER TABLE ONLY t_releves_cf
    ADD CONSTRAINT fk_t_releves_cf_bib_noms FOREIGN KEY (id_nom) REFERENCES taxonomie.bib_noms(id_nom) ON UPDATE CASCADE;


--
-- TOC entry 3781 (class 2606 OID 2748596)
-- Name: fk_t_releves_cf_t_fiches_cf; Type: FK CONSTRAINT; Schema: contactfaune; Owner: -
--

ALTER TABLE ONLY t_releves_cf
    ADD CONSTRAINT fk_t_releves_cf_t_fiches_cf FOREIGN KEY (id_cf) REFERENCES t_fiches_cf(id_cf) ON UPDATE CASCADE;


--
-- TOC entry 3776 (class 2606 OID 2748601)
-- Name: t_fiches_cf_id_lot_fkey; Type: FK CONSTRAINT; Schema: contactfaune; Owner: -
--

ALTER TABLE ONLY t_fiches_cf
    ADD CONSTRAINT t_fiches_cf_id_lot_fkey FOREIGN KEY (id_lot) REFERENCES meta.bib_lots(id_lot) ON UPDATE CASCADE;


--
-- TOC entry 3777 (class 2606 OID 2748606)
-- Name: t_fiches_cf_id_organisme_fkey; Type: FK CONSTRAINT; Schema: contactfaune; Owner: -
--

ALTER TABLE ONLY t_fiches_cf
    ADD CONSTRAINT t_fiches_cf_id_organisme_fkey FOREIGN KEY (id_organisme) REFERENCES utilisateurs.bib_organismes(id_organisme) ON UPDATE CASCADE;


--
-- TOC entry 3778 (class 2606 OID 2748611)
-- Name: t_fiches_cf_id_protocole_fkey; Type: FK CONSTRAINT; Schema: contactfaune; Owner: -
--

ALTER TABLE ONLY t_fiches_cf
    ADD CONSTRAINT t_fiches_cf_id_protocole_fkey FOREIGN KEY (id_protocole) REFERENCES meta.t_protocoles(id_protocole) ON UPDATE CASCADE;


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
-- Name: id; Type: DEFAULT; Schema: synchronomade; Owner: -
--

ALTER TABLE ONLY erreurs_cf ALTER COLUMN id SET DEFAULT nextval('erreurs_cf_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: synchronomade; Owner: -
--

ALTER TABLE ONLY erreurs_mortalite ALTER COLUMN id SET DEFAULT nextval('erreurs_mortalite_id_seq'::regclass);


--
-- Name: erreurs_cf_pkey; Type: CONSTRAINT; Schema: synchronomade; Owner: -; Tablespace: 
--

ALTER TABLE ONLY erreurs_cf
    ADD CONSTRAINT erreurs_cf_pkey PRIMARY KEY (id);


--
-- Name: erreurs_mortalite_pkey; Type: CONSTRAINT; Schema: synchronomade; Owner: -; Tablespace: 
--

ALTER TABLE ONLY erreurs_mortalite
    ADD CONSTRAINT erreurs_mortalite_pkey PRIMARY KEY (id);


--------------------------------------------------------------------------------------
--------------------INSERTION DES DONNEES DES TABLES DICTIONNAIRES--------------------
--------------------------------------------------------------------------------------

SET search_path = contactfaune, pg_catalog;

INSERT INTO bib_criteres_cf (id_critere_cf, code_critere_cf, nom_critere_cf, tri_cf, cincomplet, id_critere_synthese) VALUES (15, 'o10', 'Nid utilisé récemment ou coquille vide', 15, '10', 15);
INSERT INTO bib_criteres_cf (id_critere_cf, code_critere_cf, nom_critere_cf, tri_cf, cincomplet, id_critere_synthese) VALUES (16, 'o11', 'Jeunes fraîchement envolés ou poussins', 16, '11', 16);
INSERT INTO bib_criteres_cf (id_critere_cf, code_critere_cf, nom_critere_cf, tri_cf, cincomplet, id_critere_synthese) VALUES (17, 'o12', 'Nid occupé', 17, '12', 17);
INSERT INTO bib_criteres_cf (id_critere_cf, code_critere_cf, nom_critere_cf, tri_cf, cincomplet, id_critere_synthese) VALUES (18, 'o13', 'Adulte transportant des sacs fécaux ou de la nourriture pour les jeunes', 18, '13', 18);
INSERT INTO bib_criteres_cf (id_critere_cf, code_critere_cf, nom_critere_cf, tri_cf, cincomplet, id_critere_synthese) VALUES (19, 'o14', 'Nid avec oeuf(s)', 19, '14', 19);
INSERT INTO bib_criteres_cf (id_critere_cf, code_critere_cf, nom_critere_cf, tri_cf, cincomplet, id_critere_synthese) VALUES (20, 'o15', 'Nid avec jeune(s)', 20, '15', 20);
INSERT INTO bib_criteres_cf (id_critere_cf, code_critere_cf, nom_critere_cf, tri_cf, cincomplet, id_critere_synthese) VALUES (31, 'a1 ', 'Accouplement', 31, '1 ', 31);
INSERT INTO bib_criteres_cf (id_critere_cf, code_critere_cf, nom_critere_cf, tri_cf, cincomplet, id_critere_synthese) VALUES (32, 'a2 ', 'Ponte', 32, '2 ', 32);
INSERT INTO bib_criteres_cf (id_critere_cf, code_critere_cf, nom_critere_cf, tri_cf, cincomplet, id_critere_synthese) VALUES (33, 'a3 ', 'Têtards ou larves', 33, '3 ', 33);
INSERT INTO bib_criteres_cf (id_critere_cf, code_critere_cf, nom_critere_cf, tri_cf, cincomplet, id_critere_synthese) VALUES (34, 'a4 ', 'Léthargie hivernale', 34, '4 ', 34);
INSERT INTO bib_criteres_cf (id_critere_cf, code_critere_cf, nom_critere_cf, tri_cf, cincomplet, id_critere_synthese) VALUES (21, 'm1 ', 'Accouplement ', 21, '1 ', 21);
INSERT INTO bib_criteres_cf (id_critere_cf, code_critere_cf, nom_critere_cf, tri_cf, cincomplet, id_critere_synthese) VALUES (22, 'm2 ', 'Femelle gestante', 22, '2 ', 22);
INSERT INTO bib_criteres_cf (id_critere_cf, code_critere_cf, nom_critere_cf, tri_cf, cincomplet, id_critere_synthese) VALUES (23, 'm3 ', 'Femelle allaitante, suitée', 23, '3 ', 23);
INSERT INTO bib_criteres_cf (id_critere_cf, code_critere_cf, nom_critere_cf, tri_cf, cincomplet, id_critere_synthese) VALUES (24, 'm4 ', 'Terrier occupé', 24, '4 ', 24);
INSERT INTO bib_criteres_cf (id_critere_cf, code_critere_cf, nom_critere_cf, tri_cf, cincomplet, id_critere_synthese) VALUES (25, 'm5 ', 'Terrier non occupé', 25, '5 ', 25);
INSERT INTO bib_criteres_cf (id_critere_cf, code_critere_cf, nom_critere_cf, tri_cf, cincomplet, id_critere_synthese) VALUES (26, 'm6 ', 'Hibernation', 26, '6 ', 26);
INSERT INTO bib_criteres_cf (id_critere_cf, code_critere_cf, nom_critere_cf, tri_cf, cincomplet, id_critere_synthese) VALUES (6, 'o1 ', 'Immature', 6, '1 ', 6);
INSERT INTO bib_criteres_cf (id_critere_cf, code_critere_cf, nom_critere_cf, tri_cf, cincomplet, id_critere_synthese) VALUES (7, 'o2 ', 'Mâle chanteur', 7, '2 ', 7);
INSERT INTO bib_criteres_cf (id_critere_cf, code_critere_cf, nom_critere_cf, tri_cf, cincomplet, id_critere_synthese) VALUES (8, 'o3 ', 'Couple', 8, '3 ', 8);
INSERT INTO bib_criteres_cf (id_critere_cf, code_critere_cf, nom_critere_cf, tri_cf, cincomplet, id_critere_synthese) VALUES (10, 'o5 ', 'Parades nuptiales', 10, '5 ', 10);
INSERT INTO bib_criteres_cf (id_critere_cf, code_critere_cf, nom_critere_cf, tri_cf, cincomplet, id_critere_synthese) VALUES (11, 'o6 ', 'Signes ou cris d''inquiétude d''un individu adulte', 11, '6 ', 11);
INSERT INTO bib_criteres_cf (id_critere_cf, code_critere_cf, nom_critere_cf, tri_cf, cincomplet, id_critere_synthese) VALUES (13, 'o8 ', 'Construction d''un nid', 13, '8 ', 13);
INSERT INTO bib_criteres_cf (id_critere_cf, code_critere_cf, nom_critere_cf, tri_cf, cincomplet, id_critere_synthese) VALUES (14, 'o9 ', 'Adulte feignant une blessure ou cherchant à détourner l''attention', 14, '9 ', 14);
INSERT INTO bib_criteres_cf (id_critere_cf, code_critere_cf, nom_critere_cf, tri_cf, cincomplet, id_critere_synthese) VALUES (35, 'p1 ', 'Activité de frai', 35, '1 ', 35);
INSERT INTO bib_criteres_cf (id_critere_cf, code_critere_cf, nom_critere_cf, tri_cf, cincomplet, id_critere_synthese) VALUES (36, 'p2 ', 'Ponte ou nids de ponte', 36, '2 ', 36);
INSERT INTO bib_criteres_cf (id_critere_cf, code_critere_cf, nom_critere_cf, tri_cf, cincomplet, id_critere_synthese) VALUES (30, 'r4 ', 'Léthargie hivernale', 30, '4 ', 30);
INSERT INTO bib_criteres_cf (id_critere_cf, code_critere_cf, nom_critere_cf, tri_cf, cincomplet, id_critere_synthese) VALUES (29, 'r3 ', 'Jeune éclos', 29, '3 ', 29);
INSERT INTO bib_criteres_cf (id_critere_cf, code_critere_cf, nom_critere_cf, tri_cf, cincomplet, id_critere_synthese) VALUES (28, 'r2 ', 'Ponte', 28, '2 ', 28);
INSERT INTO bib_criteres_cf (id_critere_cf, code_critere_cf, nom_critere_cf, tri_cf, cincomplet, id_critere_synthese) VALUES (27, 'r1 ', 'Accouplement', 27, '1 ', 27);
INSERT INTO bib_criteres_cf (id_critere_cf, code_critere_cf, nom_critere_cf, tri_cf, cincomplet, id_critere_synthese) VALUES (38, 'p4 ', 'Remontées migratoires', 38, '4 ', 38);
INSERT INTO bib_criteres_cf (id_critere_cf, code_critere_cf, nom_critere_cf, tri_cf, cincomplet, id_critere_synthese) VALUES (37, 'p3 ', 'Alevins ou larves', 37, '3 ', 37);
INSERT INTO bib_criteres_cf (id_critere_cf, code_critere_cf, nom_critere_cf, tri_cf, cincomplet, id_critere_synthese) VALUES (2, 'C  ', 'Cadavre', NULL, 'C ', 2);
INSERT INTO bib_criteres_cf (id_critere_cf, code_critere_cf, nom_critere_cf, tri_cf, cincomplet, id_critere_synthese) VALUES (1, 'X  ', 'Absence de critère d’observation', 999, 'X ', 1);
INSERT INTO bib_criteres_cf (id_critere_cf, code_critere_cf, nom_critere_cf, tri_cf, cincomplet, id_critere_synthese) VALUES (4, 'E  ', 'Entendu', 101, 'E ', 4);
INSERT INTO bib_criteres_cf (id_critere_cf, code_critere_cf, nom_critere_cf, tri_cf, cincomplet, id_critere_synthese) VALUES (5, 'V  ', 'Vu', 100, 'V ', 5);
INSERT INTO bib_criteres_cf (id_critere_cf, code_critere_cf, nom_critere_cf, tri_cf, cincomplet, id_critere_synthese) VALUES (3, 'T  ', 'Traces ou indices de présence', 102, 'T ', 3);
INSERT INTO bib_criteres_cf (id_critere_cf, code_critere_cf, nom_critere_cf, tri_cf, cincomplet, id_critere_synthese) VALUES (12, 'o7 ', 'Plaque incubatrice ', 12, '7 ', 12);
INSERT INTO bib_criteres_cf (id_critere_cf, code_critere_cf, nom_critere_cf, tri_cf, cincomplet, id_critere_synthese) VALUES (9, 'o4 ', 'Comportements territoriaux', 9, '4 ', 9);

INSERT INTO bib_messages_cf (id_message_cf, texte_message_cf) VALUES (1, 'Exemple de message : l''élephant rose est extrèmement rare ; merci de fournir une photo pour confirmer l''observation');

INSERT INTO cor_critere_liste (id_critere_cf, id_liste) VALUES (31, 1);
INSERT INTO cor_critere_liste (id_critere_cf, id_liste) VALUES (32, 1);
INSERT INTO cor_critere_liste (id_critere_cf, id_liste) VALUES (33, 1);
INSERT INTO cor_critere_liste (id_critere_cf, id_liste) VALUES (34, 1);
INSERT INTO cor_critere_liste (id_critere_cf, id_liste) VALUES (21, 11);
INSERT INTO cor_critere_liste (id_critere_cf, id_liste) VALUES (22, 11);
INSERT INTO cor_critere_liste (id_critere_cf, id_liste) VALUES (23, 11);
INSERT INTO cor_critere_liste (id_critere_cf, id_liste) VALUES (24, 11);
INSERT INTO cor_critere_liste (id_critere_cf, id_liste) VALUES (25, 11);
INSERT INTO cor_critere_liste (id_critere_cf, id_liste) VALUES (26, 11);
INSERT INTO cor_critere_liste (id_critere_cf, id_liste) VALUES (6, 12);
INSERT INTO cor_critere_liste (id_critere_cf, id_liste) VALUES (7, 12);
INSERT INTO cor_critere_liste (id_critere_cf, id_liste) VALUES (8, 12);
INSERT INTO cor_critere_liste (id_critere_cf, id_liste) VALUES (9, 12);
INSERT INTO cor_critere_liste (id_critere_cf, id_liste) VALUES (10, 12);
INSERT INTO cor_critere_liste (id_critere_cf, id_liste) VALUES (11, 12);
INSERT INTO cor_critere_liste (id_critere_cf, id_liste) VALUES (12, 12);
INSERT INTO cor_critere_liste (id_critere_cf, id_liste) VALUES (13, 12);
INSERT INTO cor_critere_liste (id_critere_cf, id_liste) VALUES (14, 12);
INSERT INTO cor_critere_liste (id_critere_cf, id_liste) VALUES (15, 12);
INSERT INTO cor_critere_liste (id_critere_cf, id_liste) VALUES (16, 12);
INSERT INTO cor_critere_liste (id_critere_cf, id_liste) VALUES (17, 12);
INSERT INTO cor_critere_liste (id_critere_cf, id_liste) VALUES (18, 12);
INSERT INTO cor_critere_liste (id_critere_cf, id_liste) VALUES (19, 12);
INSERT INTO cor_critere_liste (id_critere_cf, id_liste) VALUES (20, 12);
INSERT INTO cor_critere_liste (id_critere_cf, id_liste) VALUES (35, 13);
INSERT INTO cor_critere_liste (id_critere_cf, id_liste) VALUES (36, 13);
INSERT INTO cor_critere_liste (id_critere_cf, id_liste) VALUES (37, 13);
INSERT INTO cor_critere_liste (id_critere_cf, id_liste) VALUES (38, 13);
INSERT INTO cor_critere_liste (id_critere_cf, id_liste) VALUES (27, 14);
INSERT INTO cor_critere_liste (id_critere_cf, id_liste) VALUES (28, 14);
INSERT INTO cor_critere_liste (id_critere_cf, id_liste) VALUES (29, 14);
INSERT INTO cor_critere_liste (id_critere_cf, id_liste) VALUES (30, 14);
INSERT INTO cor_critere_liste (id_critere_cf, id_liste) VALUES (5, 14);
INSERT INTO cor_critere_liste (id_critere_cf, id_liste) VALUES (5, 13);
INSERT INTO cor_critere_liste (id_critere_cf, id_liste) VALUES (5, 12);
INSERT INTO cor_critere_liste (id_critere_cf, id_liste) VALUES (5, 11);
INSERT INTO cor_critere_liste (id_critere_cf, id_liste) VALUES (5, 1);
INSERT INTO cor_critere_liste (id_critere_cf, id_liste) VALUES (4, 12);
INSERT INTO cor_critere_liste (id_critere_cf, id_liste) VALUES (4, 11);
INSERT INTO cor_critere_liste (id_critere_cf, id_liste) VALUES (4, 1);
INSERT INTO cor_critere_liste (id_critere_cf, id_liste) VALUES (3, 14);
INSERT INTO cor_critere_liste (id_critere_cf, id_liste) VALUES (3, 12);
INSERT INTO cor_critere_liste (id_critere_cf, id_liste) VALUES (3, 11);


--------------------------------------------------------------------------------------
--------------------AJOUT DU MODULE DANS LES TABLES DE DESCRIPTION--------------------
--------------------------------------------------------------------------------------

SET search_path = meta, pg_catalog;
INSERT INTO bib_programmes (id_programme, nom_programme, desc_programme, actif, programme_public, desc_programme_public) VALUES (1, 'Contact vertébrés', 'Contact aléatoire de la faune vertébrée.', true, true, 'Contact aléatoire de la faune vertébrée.');
INSERT INTO bib_programmes (id_programme, nom_programme, desc_programme, actif, programme_public, desc_programme_public) VALUES (2, 'Mortalité', 'Données issue du protocole mortalité.', true, true, 'Données issue du protocole mortalité.');
INSERT INTO bib_lots (id_lot, nom_lot, desc_lot, menu_cf, pn, menu_inv, id_programme) VALUES (1, 'Contact vertébrés', 'Contact vertébrés', true, true, false, 1);
INSERT INTO bib_lots (id_lot, nom_lot, desc_lot, menu_cf, pn, menu_inv, id_programme) VALUES (2, 'Mortalité', 'Mortalité', true, true, false, 2);
INSERT INTO t_protocoles VALUES (1, 'contact faune', 'à compléter', 'à compléter', 'à compléter', 'non', NULL, NULL);
INSERT INTO t_protocoles VALUES (2, 'mortalité', 'à compléter', 'à compléter', 'à compléter', 'non', NULL, NULL);
SET search_path = synthese, pg_catalog;
INSERT INTO bib_sources (id_source, nom_source, desc_source, host, port, username, pass, db_name, db_schema, db_table, db_field, url, target, picto, groupe, actif) VALUES (1, 'Contact faune', 'Contenu des tables t_fiche_cf et t_releves_cf de la base faune postgres', 'localhost', 22, NULL, NULL, 'geonaturedb', 'contactfaune', 't_releves_cf', 'id_releve_cf', 'cf', NULL, 'images/pictos/amphibien.gif', 'FAUNE', true);
INSERT INTO bib_sources (id_source, nom_source, desc_source, host, port, username, pass, db_name, db_schema, db_table, db_field, url, target, picto, groupe, actif) VALUES (2, 'Mortalité', 'Contenu des tables t_fiche_cf et t_releves_cf de la base faune postgres', 'localhost', 22, NULL, NULL, 'geonaturedb', 'contactfaune', 't_releves_cf', 'id_releve_cf', 'mortalite', NULL, 'images/pictos/squelette.png', 'FAUNE', true);


--------------------------------------------------------------------------------------
--------------------AJOUT DU MODULE DANS LES TABLES SPATIALES-------------------------
--------------------------------------------------------------------------------------

SET search_path = public, pg_catalog;
INSERT INTO geometry_columns (f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, type) VALUES ('', 'contactfaune', 't_fiches_cf', 'the_geom_3857', 2, 3857, 'POINT');
INSERT INTO geometry_columns (f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, type) VALUES ('', 'contactfaune', 't_fiches_cf', 'the_geom_2154', 2, 2154, 'POINT');
INSERT INTO geometry_columns (f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, type) VALUES ('', 'contactfaune', 'v_nomade_unites_geo_cf', 'the_geom', 2, 2154, 'MULTIPOLYGON');
