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
-- TOC entry 12 (class 2615 OID 2747599)
-- Name: florepatri; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA florepatri;


SET search_path = florepatri, pg_catalog;

--
-- TOC entry 1462 (class 1255 OID 2747636)
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
-- TOC entry 1509 (class 1255 OID 2747637)
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
		new.the_geom_2154 = public.st_transform(new.the_geom_3857,2154);
	ELSIF new.the_geom_2154 IS NOT NULL THEN	-- saisie avec outil nomade android avec the_geom_2154
		new.the_geom_3857 = public.st_transform(new.the_geom_2154,3857);
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
		moncentroide = ST_setsrid(public.st_centroid(Box2D(new.the_geom_2154)),2154); -- calcul le centroid de la bbox pour les croisements SIG
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
-- TOC entry 1465 (class 1255 OID 2747638)
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
    ELSE mongeompoint = public.ST_PointFromWKB(public.st_centroid(Box2D(new.the_geom_3857)),3857);
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
-- TOC entry 1475 (class 1255 OID 2747639)
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
		new.the_geom_3857 = public.st_transform(new.the_geom_2154,3857);
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
			SELECT INTO monsectfp ls.id_secteur FROM layers.l_secteurs ls WHERE public.st_intersects(ls.the_geom, new.the_geom_2154)
			ORDER BY public.ST_area(public.ST_intersection(ls.the_geom, new.the_geom_2154)) DESC LIMIT 1;
			-- croisement commune (celle qui contient le plus de zp en surface)
			SELECT INTO macommune lc.insee FROM layers.l_communes lc WHERE public.st_intersects(lc.the_geom, new.the_geom_2154)
			ORDER BY public.ST_area(public.ST_intersection(lc.the_geom, new.the_geom_2154)) DESC LIMIT 1;
		ELSE
			new.topo_valid = 'false';
			-- calcul du geom_point_3857
			new.geom_point_3857 = ST_setsrid(public.st_centroid(Box2D(new.the_geom_3857)),3857);  -- calcul le centroid de la bbox pour premier niveau de zoom appli web
			moncentroide = ST_setsrid(public.st_centroid(Box2D(new.the_geom_2154)),2154); -- calcul le centroid de la bbox pour les croisements SIG
			-- croisement secteur (celui qui contient moncentroide)
			SELECT INTO monsectfp ls.id_secteur FROM layers.l_secteurs ls WHERE public.st_intersects(ls.the_geom, moncentroide);
			-- croisement commune (celle qui contient moncentroid)
			SELECT INTO macommune lc.insee FROM layers.l_communes lc WHERE public.st_intersects(lc.the_geom, moncentroide);
		END IF;
		new.insee = macommune;
		IF monsectfp IS NULL THEN 		-- suite calcul secteur : si la requete sql renvoit null (cad pas d'intersection donc dessin hors zone)
			new.id_secteur = 999;	-- alors on met 999 (hors zone) en code secteur fp
		ELSE
			new.id_secteur = monsectfp; --sinon on met le code du secteur.
		END IF;

		------ calcul du geom_mixte_3857
		IF public.ST_area(new.the_geom_3857) <10000 THEN	   -- calcul du point (ou de la surface si > 1 hectare) pour le second niveau de zoom appli web
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
-- TOC entry 1508 (class 1255 OID 2747640)
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
-- TOC entry 1510 (class 1255 OID 2747641)
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
code ci dessous a revoir car public.st_equals ne marche pas avec les objets invalid

IF 
    (NOT public.st_equals(new.the_geom_2154,old.the_geom_2154) OR (old.the_geom_2154 IS null AND new.the_geom_2154 IS NOT NULL))
    OR (NOT public.st_equals(new.the_geom_3857,old.the_geom_3857)OR (old.the_geom_3857 IS null AND new.the_geom_3857 IS NOT NULL)) 
THEN
    IF NOT public.st_equals(new.the_geom_3857,old.the_geom_3857) OR (old.the_geom_3857 IS null AND new.the_geom_3857 IS NOT NULL) THEN
		new.the_geom_2154 = public.st_transform(new.the_geom_3857,2154);
	ELSIF NOT public.st_equals(new.the_geom_2154,old.the_geom_2154) OR (old.the_geom_2154 IS null AND new.the_geom_2154 IS NOT NULL) THEN
		new.the_geom_3857 = public.st_transform(new.the_geom_2154,3857);
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

new.the_geom_2154 = public.st_transform(new.the_geom_3857,2154);

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
	moncentroide = ST_setsrid(public.st_centroid(Box2D(new.the_geom_2154)),2154); -- calcul le centroid de la bbox pour les croisements SIG
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
-- TOC entry 1501 (class 1255 OID 2747642)
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
        OR (NOT public.st_equals(new.the_geom_3857,old.the_geom_3857) OR NOT public.st_equals(new.the_geom_2154,old.the_geom_2154))
    ) THEN
    -- création du geom_point
    IF st_isvalid(new.the_geom_3857) THEN mongeompoint = st_pointonsurface(new.the_geom_3857);
    ELSE mongeompoint = public.ST_PointFromWKB(public.st_centroid(Box2D(new.the_geom_3857)),3857);
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
-- TOC entry 1476 (class 1255 OID 2747643)
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
-- TOC entry 1477 (class 1255 OID 2747644)
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
-- TOC entry 1467 (class 1255 OID 2747645)
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
code ci dessous a revoir car public.st_equals ne marche pas avec les objets invalid
 -- on verfie si 1 des 3 geom a changé
IF((old.the_geom_3857 is null AND new.the_geom_3857 is NOT NULL) OR NOT public.st_equals(new.the_geom_3857,old.the_geom_3857))
OR ((old.the_geom_2154 is null AND new.the_geom_2154 is NOT NULL) OR NOT public.st_equals(new.the_geom_2154,old.the_geom_2154)) THEN

-- si oui on regarde lequel et on repercute les modif :
	IF (old.the_geom_3857 is null AND new.the_geom_3857 is NOT NULL) OR NOT public.st_equals(new.the_geom_3857,old.the_geom_3857) THEN
		-- verif si on est en multipolygon ou pas : A FAIRE !!!!!!!!!!!!!!!!!!!!!!!!!!!!!
		new.the_geom_2154 = public.st_transform(new.the_geom_3857,2154);
		new.srid_dessin = 3857;	
	ELSIF (old.the_geom_2154 is null AND new.the_geom_2154 is NOT NULL) OR NOT public.st_equals(new.the_geom_2154,old.the_geom_2154) THEN
		new.the_geom_3857 = public.st_transform(new.the_geom_2154,3857);
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

new.the_geom_2154 = public.st_transform(new.the_geom_3857,2154);
new.srid_dessin = 3857;

------ 2) puis on calcul la validité des geom + on refait les calcul du geom_point_3857 + on refait les croisements SIG secteurs + communes
------    c'est la même chose que lors d'un INSERT ( cf trigger insert_zp)
IF ST_isvalid(new.the_geom_2154) AND ST_isvalid(new.the_geom_3857) THEN
	new.topo_valid = 'true';
	-- calcul du geom_point_3857 
	new.geom_point_3857 = ST_pointonsurface(new.the_geom_3857);  -- calcul du point pour le premier niveau de zoom appli web
	-- croisement secteur (celui qui contient le plus de zp en surface)
	SELECT INTO monsectfp ls.id_secteur FROM layers.l_secteurs ls WHERE public.st_intersects(ls.the_geom, new.the_geom_2154)
	ORDER BY public.ST_area(public.ST_intersection(ls.the_geom, new.the_geom_2154)) DESC LIMIT 1;
	-- croisement commune (celle qui contient le plus de zp en surface)
	SELECT INTO macommune lc.insee FROM layers.l_communes lc WHERE public.st_intersects(lc.the_geom, new.the_geom_2154)
	ORDER BY public.ST_area(public.ST_intersection(lc.the_geom, new.the_geom_2154)) DESC LIMIT 1;
ELSE
	new.topo_valid = 'false';
	-- calcul du geom_point_3857
	new.geom_point_3857 = ST_setsrid(public.st_centroid(Box2D(new.the_geom_3857)),3857);  -- calcul le centroid de la bbox pour premier niveau de zoom appli web
	moncentroide = ST_setsrid(public.st_centroid(Box2D(new.the_geom_2154)),2154); -- calcul le centroid de la bbox pour les croisements SIG
	-- croisement secteur (celui qui contient moncentroide)
	SELECT INTO monsectfp ls.id_secteur FROM layers.l_secteurs ls WHERE public.st_intersects(ls.the_geom, moncentroide);
	-- croisement commune (celle qui contient moncentroid)
	SELECT INTO macommune lc.insee FROM layers.l_communes lc WHERE public.st_intersects(lc.the_geom, moncentroide);
	END IF;
	new.insee = macommune;
	IF monsectfp IS NULL THEN 		-- suite calcul secteur : si la requete sql renvoit null (cad pas d'intersection donc dessin hors zone)
		new.id_secteur = 999;	-- alors on met 999 (hors zone) en code secteur fp
	ELSE
		new.id_secteur = monsectfp; --sinon on met le code du secteur.
END IF;

------ 3) puis calcul du geom_mixte_3857
------    c'est la même chose que lors d'un INSERT ( cf trigger insert_zp)
IF public.ST_area(new.the_geom_3857) <10000 THEN	   -- calcul du point (ou de la surface si > 1 hectare) pour le second niveau de zoom appli web
	new.geom_mixte_3857 = new.geom_point_3857;
ELSE
	new.geom_mixte_3857 = new.the_geom_3857;
END IF;
------  fin du IF pour les traitemenst sur les geometries

------  fin du trigger et return des valeurs :
	RETURN NEW;
END;
$$;


SET default_with_oids = false;

--
-- TOC entry 265 (class 1259 OID 2747761)
-- Name: bib_comptages_methodo; Type: TABLE; Schema: florepatri; Owner: -
--

CREATE TABLE bib_comptages_methodo (
    id_comptage_methodo integer NOT NULL,
    nom_comptage_methodo character varying(100)
);


--
-- TOC entry 266 (class 1259 OID 2747764)
-- Name: bib_frequences_methodo_new; Type: TABLE; Schema: florepatri; Owner: -
--

CREATE TABLE bib_frequences_methodo_new (
    id_frequence_methodo_new character(1) NOT NULL,
    nom_frequence_methodo_new character varying(100)
);


--
-- TOC entry 267 (class 1259 OID 2747767)
-- Name: bib_pentes; Type: TABLE; Schema: florepatri; Owner: -
--

CREATE TABLE bib_pentes (
    id_pente integer NOT NULL,
    val_pente real NOT NULL,
    nom_pente character varying(100)
);


--
-- TOC entry 268 (class 1259 OID 2747770)
-- Name: bib_perturbations; Type: TABLE; Schema: florepatri; Owner: -
--

CREATE TABLE bib_perturbations (
    codeper smallint NOT NULL,
    classification character varying(30) NOT NULL,
    description character varying(65) NOT NULL
);


--
-- TOC entry 269 (class 1259 OID 2747773)
-- Name: bib_phenologies; Type: TABLE; Schema: florepatri; Owner: -
--

CREATE TABLE bib_phenologies (
    codepheno smallint NOT NULL,
    pheno character varying(45) NOT NULL
);


--
-- TOC entry 270 (class 1259 OID 2747776)
-- Name: bib_physionomies; Type: TABLE; Schema: florepatri; Owner: -
--

CREATE TABLE bib_physionomies (
    id_physionomie integer NOT NULL,
    groupe_physionomie character varying(20),
    nom_physionomie character varying(100),
    definition_physionomie text,
    code_physionomie character varying(3)
);


--
-- TOC entry 271 (class 1259 OID 2747782)
-- Name: bib_rezo_ecrins; Type: TABLE; Schema: florepatri; Owner: -
--

CREATE TABLE bib_rezo_ecrins (
    id_rezo_ecrins integer NOT NULL,
    nom_rezo_ecrins character varying(100)
);


--
-- TOC entry 272 (class 1259 OID 2747785)
-- Name: bib_statuts; Type: TABLE; Schema: florepatri; Owner: -
--

CREATE TABLE bib_statuts (
    id_statut integer NOT NULL,
    nom_statut character varying(20) NOT NULL,
    desc_statut text
);


--
-- TOC entry 273 (class 1259 OID 2747791)
-- Name: bib_taxons_fp; Type: TABLE; Schema: florepatri; Owner: -
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
-- TOC entry 274 (class 1259 OID 2747795)
-- Name: cor_ap_perturb; Type: TABLE; Schema: florepatri; Owner: -
--

CREATE TABLE cor_ap_perturb (
    indexap bigint NOT NULL,
    codeper smallint NOT NULL
);


--
-- TOC entry 275 (class 1259 OID 2747798)
-- Name: cor_ap_physionomie; Type: TABLE; Schema: florepatri; Owner: -
--

CREATE TABLE cor_ap_physionomie (
    indexap bigint NOT NULL,
    id_physionomie smallint NOT NULL
);


--
-- TOC entry 276 (class 1259 OID 2747801)
-- Name: cor_taxon_statut; Type: TABLE; Schema: florepatri; Owner: -
--

CREATE TABLE cor_taxon_statut (
    id_statut integer NOT NULL,
    cd_nom integer NOT NULL
);


--
-- TOC entry 277 (class 1259 OID 2747804)
-- Name: cor_zp_obs; Type: TABLE; Schema: florepatri; Owner: -
--

CREATE TABLE cor_zp_obs (
    indexzp bigint NOT NULL,
    codeobs integer NOT NULL
);


--
-- TOC entry 278 (class 1259 OID 2747807)
-- Name: t_apresence; Type: TABLE; Schema: florepatri; Owner: -
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
-- TOC entry 279 (class 1259 OID 2747824)
-- Name: t_zprospection; Type: TABLE; Schema: florepatri; Owner: -
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


--
-- TOC entry 352 (class 1259 OID 2748211)
-- Name: v_ap_line; Type: VIEW; Schema: florepatri; Owner: -
--

CREATE VIEW v_ap_line AS
 SELECT a.indexap,
    a.indexzp,
    a.surfaceap AS surface,
    a.altitude_saisie AS altitude,
    a.id_frequence_methodo_new AS id_frequence_methodo,
    a.the_geom_2154,
    a.frequenceap,
    a.topo_valid,
    a.date_update,
    a.supprime,
    a.date_insert
   FROM t_apresence a
  WHERE ((public.geometrytype(a.the_geom_2154) = 'MULTILINESTRING'::text) OR (public.geometrytype(a.the_geom_2154) = 'LINESTRING'::text));


--
-- TOC entry 353 (class 1259 OID 2748215)
-- Name: v_ap_point; Type: VIEW; Schema: florepatri; Owner: -
--

CREATE VIEW v_ap_point AS
 SELECT a.indexap,
    a.indexzp,
    a.surfaceap AS surface,
    a.altitude_saisie AS altitude,
    a.id_frequence_methodo_new AS id_frequence_methodo,
    a.the_geom_2154,
    a.frequenceap,
    a.topo_valid,
    a.date_update,
    a.supprime,
    a.date_insert
   FROM t_apresence a
  WHERE ((public.geometrytype(a.the_geom_2154) = 'POINT'::text) OR (public.geometrytype(a.the_geom_2154) = 'MULTIPOINT'::text));


--
-- TOC entry 354 (class 1259 OID 2748219)
-- Name: v_ap_poly; Type: VIEW; Schema: florepatri; Owner: -
--

CREATE VIEW v_ap_poly AS
 SELECT a.indexap,
    a.indexzp,
    a.surfaceap AS surface,
    a.altitude_saisie AS altitude,
    a.id_frequence_methodo_new AS id_frequence_methodo,
    a.the_geom_2154,
    a.frequenceap,
    a.topo_valid,
    a.date_update,
    a.supprime,
    a.date_insert
   FROM t_apresence a
  WHERE ((public.geometrytype(a.the_geom_2154) = 'POLYGON'::text) OR (public.geometrytype(a.the_geom_2154) = 'MULTIPOLYGON'::text));


--
-- TOC entry 347 (class 1259 OID 2748186)
-- Name: v_mobile_observateurs_fp; Type: VIEW; Schema: florepatri; Owner: -
--

CREATE VIEW v_mobile_observateurs_fp AS
 SELECT DISTINCT r.id_role,
    r.nom_role,
    r.prenom_role
   FROM utilisateurs.t_roles r
  WHERE ((r.id_role IN ( SELECT DISTINCT cr.id_role_utilisateur
           FROM utilisateurs.cor_roles cr
          WHERE (cr.id_role_groupe IN ( SELECT crm.id_role
                   FROM utilisateurs.cor_role_menu crm
                  WHERE (crm.id_menu = 5)))
          ORDER BY cr.id_role_utilisateur)) OR (r.id_role IN ( SELECT crm.id_role
           FROM (utilisateurs.cor_role_menu crm
             JOIN utilisateurs.t_roles r_1 ON ((((r_1.id_role = crm.id_role) AND (crm.id_menu = 5)) AND (r_1.groupe = false)))))))
  ORDER BY r.nom_role, r.prenom_role, r.id_role;


--
-- TOC entry 355 (class 1259 OID 2748223)
-- Name: v_mobile_pentes; Type: VIEW; Schema: florepatri; Owner: -
--

CREATE VIEW v_mobile_pentes AS
 SELECT bib_pentes.id_pente,
    bib_pentes.val_pente,
    bib_pentes.nom_pente
   FROM bib_pentes
  ORDER BY bib_pentes.id_pente;


--
-- TOC entry 356 (class 1259 OID 2748227)
-- Name: v_mobile_perturbations; Type: VIEW; Schema: florepatri; Owner: -
--

CREATE VIEW v_mobile_perturbations AS
 SELECT bib_perturbations.codeper,
    bib_perturbations.classification,
    bib_perturbations.description
   FROM bib_perturbations
  ORDER BY bib_perturbations.codeper;


--
-- TOC entry 357 (class 1259 OID 2748231)
-- Name: v_mobile_phenologies; Type: VIEW; Schema: florepatri; Owner: -
--

CREATE VIEW v_mobile_phenologies AS
 SELECT bib_phenologies.codepheno,
    bib_phenologies.pheno
   FROM bib_phenologies
  ORDER BY bib_phenologies.codepheno;


--
-- TOC entry 358 (class 1259 OID 2748235)
-- Name: v_mobile_physionomies; Type: VIEW; Schema: florepatri; Owner: -
--

CREATE VIEW v_mobile_physionomies AS
 SELECT bib_physionomies.id_physionomie,
    bib_physionomies.groupe_physionomie,
    bib_physionomies.nom_physionomie
   FROM bib_physionomies
  ORDER BY bib_physionomies.id_physionomie;


--
-- TOC entry 359 (class 1259 OID 2748239)
-- Name: v_mobile_taxons_fp; Type: VIEW; Schema: florepatri; Owner: -
--

CREATE VIEW v_mobile_taxons_fp AS
 SELECT bt.cd_nom,
    bt.latin AS nom_latin,
    bt.francais AS nom_francais
   FROM bib_taxons_fp bt
  WHERE (bt.nomade_ecrins = true)
  ORDER BY bt.latin;


--
-- TOC entry 360 (class 1259 OID 2748243)
-- Name: v_mobile_visu_zp; Type: VIEW; Schema: florepatri; Owner: -
--

CREATE VIEW v_mobile_visu_zp AS
 SELECT t_zprospection.indexzp,
    t_zprospection.cd_nom,
    t_zprospection.the_geom_2154
   FROM t_zprospection
  WHERE (date_part('year'::text, t_zprospection.dateobs) = date_part('year'::text, now()));


--
-- TOC entry 361 (class 1259 OID 2748247)
-- Name: v_nomade_taxon; Type: VIEW; Schema: florepatri; Owner: -
--

CREATE VIEW v_nomade_taxon AS
 SELECT bt.cd_nom,
    bt.latin,
    bt.francais,
    bt.echelle,
    '1,2,3,4,5,6,7,8'::character(15) AS codepheno,
    'TF,RS'::character(5) AS codeobjet
   FROM bib_taxons_fp bt
  WHERE (bt.nomade_ecrins = true)
  ORDER BY bt.latin;


--
-- TOC entry 362 (class 1259 OID 2748251)
-- Name: v_nomade_zp; Type: VIEW; Schema: florepatri; Owner: -
--

CREATE VIEW v_nomade_zp AS
 SELECT zp.indexzp,
    zp.cd_nom,
    vobs.codeobs,
    zp.dateobs,
    'Polygon'::character(7) AS montype,
    substr(public.st_asgml(zp.the_geom_2154), (strpos(public.st_asgml(zp.the_geom_2154), '<gml:coordinates>'::text) + 17), (strpos(public.st_asgml(zp.the_geom_2154), '</gml:coordinates>'::text) - (strpos(public.st_asgml(zp.the_geom_2154), '<gml:coordinates>'::text) + 17))) AS coordinates,
    vap.indexap,
    zp.id_secteur AS id_secteur_fp
   FROM ((t_zprospection zp
     JOIN ( SELECT cor.indexzp,
            substr((array_agg(cor.codeobs))::text, 2, (strpos((array_agg(cor.codeobs))::text, '}'::text) - 2)) AS codeobs
           FROM ( SELECT aa.indexzp,
                    aa.codeobs
                   FROM cor_zp_obs aa
                  WHERE (aa.codeobs <> 247)
                  ORDER BY aa.indexzp, aa.codeobs) cor
          GROUP BY cor.indexzp) vobs ON ((vobs.indexzp = zp.indexzp)))
     LEFT JOIN ( SELECT ap.indexzp,
            substr((array_agg(ap.indexap))::text, 2, (strpos((array_agg(ap.indexap))::text, '}'::text) - 2)) AS indexap
           FROM ( SELECT aa.indexzp,
                    aa.indexap
                   FROM t_apresence aa
                  WHERE (aa.supprime = false)
                  ORDER BY aa.indexzp, aa.indexap) ap
          GROUP BY ap.indexzp) vap ON ((vap.indexzp = zp.indexzp)))
  WHERE (((((zp.topo_valid = true) AND (zp.supprime = false)) AND (zp.id_secteur < 9)) AND (zp.dateobs > '2010-01-01'::date)) AND (zp.cd_nom IN ( SELECT v_nomade_taxon.cd_nom
           FROM v_nomade_taxon)))
  ORDER BY zp.indexzp;


--
-- TOC entry 363 (class 1259 OID 2748256)
-- Name: v_nomade_ap; Type: VIEW; Schema: florepatri; Owner: -
--

CREATE VIEW v_nomade_ap AS
 SELECT ap.indexap,
    ap.codepheno,
    letypedegeom(ap.the_geom_2154) AS montype,
    substr(public.st_asgml(ap.the_geom_2154), (strpos(public.st_asgml(ap.the_geom_2154), '<gml:coordinates>'::text) + 17), (strpos(public.st_asgml(ap.the_geom_2154), '</gml:coordinates>'::text) - (strpos(public.st_asgml(ap.the_geom_2154), '<gml:coordinates>'::text) + 17))) AS coordinates,
    ap.surfaceap,
    (((ap.id_frequence_methodo_new)::text || ';'::text) || (ap.frequenceap)::integer) AS frequence,
    vper.codeper,
    ((('TF;'::text || ((ap.total_fertiles)::character(1))::text) || ',RS;'::text) || ((ap.total_steriles)::character(1))::text) AS denombrement,
    zp.id_secteur_fp
   FROM ((t_apresence ap
     JOIN v_nomade_zp zp ON ((ap.indexzp = zp.indexzp)))
     LEFT JOIN ( SELECT ab.indexap,
            substr((array_agg(ab.codeper))::text, 2, (strpos((array_agg(ab.codeper))::text, '}'::text) - 2)) AS codeper
           FROM ( SELECT aa.indexap,
                    aa.codeper
                   FROM cor_ap_perturb aa
                  ORDER BY aa.indexap, aa.codeper) ab
          GROUP BY ab.indexap) vper ON ((vper.indexap = ap.indexap)))
  WHERE (ap.supprime = false)
  ORDER BY ap.indexap;


--
-- TOC entry 364 (class 1259 OID 2748261)
-- Name: v_nomade_classes; Type: VIEW; Schema: florepatri; Owner: -
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
          WHERE ((l.id_liste > 300) AND (l.id_liste < 400))
          GROUP BY l.id_liste, l.nom_liste, l.desc_liste) g
     JOIN taxonomie.taxref t ON ((t.cd_nom = g.cd_ref)))
  WHERE ((t.regne)::text = 'Plantae'::text);


--
-- TOC entry 348 (class 1259 OID 2748191)
-- Name: v_touteslesap_2154_line; Type: VIEW; Schema: florepatri; Owner: -
--

CREATE VIEW v_touteslesap_2154_line AS
 SELECT ap.indexap AS gid,
    ap.indexzp,
    ap.indexap,
    s.nom_secteur AS secteur,
    zp.dateobs,
    t.latin AS taxon,
    o.observateurs,
    p.pheno AS phenologie,
    ap.surfaceap,
    ap.insee,
    com.commune_min,
    ap.altitude_retenue AS altitude,
    f.nom_frequence_methodo_new AS met_frequence,
    ap.frequenceap,
    compt.nom_comptage_methodo AS met_comptage,
    ap.total_fertiles AS tot_fertiles,
    ap.total_steriles AS tot_steriles,
    per.perturbations,
    phy.physionomies,
    ap.the_geom_2154,
    ap.topo_valid AS ap_topo_valid,
    zp.validation AS relue,
    ap.remarques
   FROM ((((((((((t_apresence ap
     JOIN t_zprospection zp ON ((ap.indexzp = zp.indexzp)))
     JOIN bib_taxons_fp t ON ((t.cd_nom = zp.cd_nom)))
     JOIN layers.l_secteurs s ON ((s.id_secteur = zp.id_secteur)))
     JOIN bib_phenologies p ON ((p.codepheno = ap.codepheno)))
     JOIN layers.l_communes com ON ((com.insee = ap.insee)))
     JOIN bib_frequences_methodo_new f ON ((f.id_frequence_methodo_new = ap.id_frequence_methodo_new)))
     JOIN bib_comptages_methodo compt ON ((compt.id_comptage_methodo = ap.id_comptage_methodo)))
     JOIN ( SELECT c.indexzp,
            array_to_string(array_agg((((r.prenom_role)::text || ' '::text) || (r.nom_role)::text)), ', '::text) AS observateurs
           FROM (cor_zp_obs c
             JOIN utilisateurs.t_roles r ON ((r.id_role = c.codeobs)))
          GROUP BY c.indexzp) o ON ((o.indexzp = ap.indexzp)))
     LEFT JOIN ( SELECT c.indexap,
            array_to_string(array_agg(((((per_1.description)::text || ' ('::text) || (per_1.classification)::text) || ')'::text)), ', '::text) AS perturbations
           FROM (cor_ap_perturb c
             JOIN bib_perturbations per_1 ON ((per_1.codeper = c.codeper)))
          GROUP BY c.indexap) per ON ((per.indexap = ap.indexap)))
     LEFT JOIN ( SELECT p_1.indexap,
            array_to_string(array_agg(((((phy_1.nom_physionomie)::text || ' ('::text) || (phy_1.groupe_physionomie)::text) || ')'::text)), ', '::text) AS physionomies
           FROM (cor_ap_physionomie p_1
             JOIN bib_physionomies phy_1 ON ((phy_1.id_physionomie = p_1.id_physionomie)))
          GROUP BY p_1.indexap) phy ON ((phy.indexap = ap.indexap)))
  WHERE ((ap.supprime = false) AND (public.geometrytype(ap.the_geom_2154) = 'LINESTRING'::text))
  ORDER BY s.nom_secteur, ap.indexzp;


--
-- TOC entry 349 (class 1259 OID 2748196)
-- Name: v_touteslesap_2154_point; Type: VIEW; Schema: florepatri; Owner: -
--

CREATE VIEW v_touteslesap_2154_point AS
 SELECT ap.indexap AS gid,
    ap.indexzp,
    ap.indexap,
    s.nom_secteur AS secteur,
    zp.dateobs,
    t.latin AS taxon,
    o.observateurs,
    p.pheno AS phenologie,
    ap.surfaceap,
    ap.insee,
    com.commune_min,
    ap.altitude_retenue AS altitude,
    f.nom_frequence_methodo_new AS met_frequence,
    ap.frequenceap,
    compt.nom_comptage_methodo AS met_comptage,
    ap.total_fertiles AS tot_fertiles,
    ap.total_steriles AS tot_steriles,
    per.perturbations,
    phy.physionomies,
    ap.the_geom_2154,
    ap.topo_valid AS ap_topo_valid,
    zp.validation AS relue,
    ap.remarques
   FROM ((((((((((t_apresence ap
     JOIN t_zprospection zp ON ((ap.indexzp = zp.indexzp)))
     JOIN bib_taxons_fp t ON ((t.cd_nom = zp.cd_nom)))
     JOIN layers.l_secteurs s ON ((s.id_secteur = zp.id_secteur)))
     JOIN bib_phenologies p ON ((p.codepheno = ap.codepheno)))
     JOIN layers.l_communes com ON ((com.insee = ap.insee)))
     JOIN bib_frequences_methodo_new f ON ((f.id_frequence_methodo_new = ap.id_frequence_methodo_new)))
     JOIN bib_comptages_methodo compt ON ((compt.id_comptage_methodo = ap.id_comptage_methodo)))
     JOIN ( SELECT c.indexzp,
            array_to_string(array_agg((((r.prenom_role)::text || ' '::text) || (r.nom_role)::text)), ', '::text) AS observateurs
           FROM (cor_zp_obs c
             JOIN utilisateurs.t_roles r ON ((r.id_role = c.codeobs)))
          GROUP BY c.indexzp) o ON ((o.indexzp = ap.indexzp)))
     LEFT JOIN ( SELECT c.indexap,
            array_to_string(array_agg(((((per_1.description)::text || ' ('::text) || (per_1.classification)::text) || ')'::text)), ', '::text) AS perturbations
           FROM (cor_ap_perturb c
             JOIN bib_perturbations per_1 ON ((per_1.codeper = c.codeper)))
          GROUP BY c.indexap) per ON ((per.indexap = ap.indexap)))
     LEFT JOIN ( SELECT p_1.indexap,
            array_to_string(array_agg(((((phy_1.nom_physionomie)::text || ' ('::text) || (phy_1.groupe_physionomie)::text) || ')'::text)), ', '::text) AS physionomies
           FROM (cor_ap_physionomie p_1
             JOIN bib_physionomies phy_1 ON ((phy_1.id_physionomie = p_1.id_physionomie)))
          GROUP BY p_1.indexap) phy ON ((phy.indexap = ap.indexap)))
  WHERE ((ap.supprime = false) AND (public.geometrytype(ap.the_geom_2154) = 'POINT'::text))
  ORDER BY s.nom_secteur, ap.indexzp;


--
-- TOC entry 350 (class 1259 OID 2748201)
-- Name: v_touteslesap_2154_polygon; Type: VIEW; Schema: florepatri; Owner: -
--

CREATE VIEW v_touteslesap_2154_polygon AS
 SELECT ap.indexap AS gid,
    ap.indexzp,
    ap.indexap,
    s.nom_secteur AS secteur,
    zp.dateobs,
    t.latin AS taxon,
    o.observateurs,
    p.pheno AS phenologie,
    ap.surfaceap,
    ap.insee,
    com.commune_min,
    ap.altitude_retenue AS altitude,
    f.nom_frequence_methodo_new AS met_frequence,
    ap.frequenceap,
    compt.nom_comptage_methodo AS met_comptage,
    ap.total_fertiles AS tot_fertiles,
    ap.total_steriles AS tot_steriles,
    per.perturbations,
    phy.physionomies,
    ap.the_geom_2154,
    ap.topo_valid AS ap_topo_valid,
    zp.validation AS relue,
    ap.remarques
   FROM ((((((((((t_apresence ap
     JOIN t_zprospection zp ON ((ap.indexzp = zp.indexzp)))
     JOIN bib_taxons_fp t ON ((t.cd_nom = zp.cd_nom)))
     JOIN layers.l_secteurs s ON ((s.id_secteur = zp.id_secteur)))
     JOIN bib_phenologies p ON ((p.codepheno = ap.codepheno)))
     JOIN layers.l_communes com ON ((com.insee = ap.insee)))
     JOIN bib_frequences_methodo_new f ON ((f.id_frequence_methodo_new = ap.id_frequence_methodo_new)))
     JOIN bib_comptages_methodo compt ON ((compt.id_comptage_methodo = ap.id_comptage_methodo)))
     JOIN ( SELECT c.indexzp,
            array_to_string(array_agg((((r.prenom_role)::text || ' '::text) || (r.nom_role)::text)), ', '::text) AS observateurs
           FROM (cor_zp_obs c
             JOIN utilisateurs.t_roles r ON ((r.id_role = c.codeobs)))
          GROUP BY c.indexzp) o ON ((o.indexzp = ap.indexzp)))
     LEFT JOIN ( SELECT c.indexap,
            array_to_string(array_agg(((((per_1.description)::text || ' ('::text) || (per_1.classification)::text) || ')'::text)), ', '::text) AS perturbations
           FROM (cor_ap_perturb c
             JOIN bib_perturbations per_1 ON ((per_1.codeper = c.codeper)))
          GROUP BY c.indexap) per ON ((per.indexap = ap.indexap)))
     LEFT JOIN ( SELECT p_1.indexap,
            array_to_string(array_agg(((((phy_1.nom_physionomie)::text || ' ('::text) || (phy_1.groupe_physionomie)::text) || ')'::text)), ', '::text) AS physionomies
           FROM (cor_ap_physionomie p_1
             JOIN bib_physionomies phy_1 ON ((phy_1.id_physionomie = p_1.id_physionomie)))
          GROUP BY p_1.indexap) phy ON ((phy.indexap = ap.indexap)))
  WHERE ((ap.supprime = false) AND (public.geometrytype(ap.the_geom_2154) = 'POLYGON'::text))
  ORDER BY s.nom_secteur, ap.indexzp;


--
-- TOC entry 351 (class 1259 OID 2748206)
-- Name: v_toutesleszp_2154; Type: VIEW; Schema: florepatri; Owner: -
--

CREATE VIEW v_toutesleszp_2154 AS
 SELECT zp.indexzp AS gid,
    zp.indexzp,
    s.nom_secteur AS secteur,
    count(ap.indexap) AS nbap,
    zp.dateobs,
    t.latin AS taxon,
    zp.taxon_saisi,
    o.observateurs,
    zp.the_geom_2154,
    zp.insee,
    com.commune_min AS commune,
    org.nom_organisme AS organisme_producteur,
    zp.topo_valid AS zp_topo_valid,
    zp.validation AS relue,
    zp.saisie_initiale,
    zp.srid_dessin
   FROM ((((((t_zprospection zp
     LEFT JOIN t_apresence ap ON ((ap.indexzp = zp.indexzp)))
     LEFT JOIN layers.l_communes com ON ((com.insee = zp.insee)))
     LEFT JOIN utilisateurs.bib_organismes org ON ((org.id_organisme = zp.id_organisme)))
     JOIN bib_taxons_fp t ON ((t.cd_nom = zp.cd_nom)))
     JOIN layers.l_secteurs s ON ((s.id_secteur = zp.id_secteur)))
     JOIN ( SELECT c.indexzp,
            array_to_string(array_agg((((r.prenom_role)::text || ' '::text) || (r.nom_role)::text)), ', '::text) AS observateurs
           FROM (cor_zp_obs c
             JOIN utilisateurs.t_roles r ON ((r.id_role = c.codeobs)))
          GROUP BY c.indexzp) o ON ((o.indexzp = zp.indexzp)))
  WHERE (zp.supprime = false)
  GROUP BY s.nom_secteur, zp.indexzp, zp.dateobs, t.latin, zp.taxon_saisi, o.observateurs, zp.the_geom_2154, zp.insee, com.commune_min, org.nom_organisme, zp.topo_valid, zp.validation, zp.saisie_initiale, zp.srid_dessin
  ORDER BY s.nom_secteur, zp.indexzp;


--
-- TOC entry 3798 (class 2606 OID 2748353)
-- Name: _t_apresence_pkey; Type: CONSTRAINT; Schema: florepatri; Owner: -
--

ALTER TABLE ONLY t_apresence
    ADD CONSTRAINT _t_apresence_pkey PRIMARY KEY (indexap);


--
-- TOC entry 3802 (class 2606 OID 2748355)
-- Name: _t_zprospection_pkey; Type: CONSTRAINT; Schema: florepatri; Owner: -
--

ALTER TABLE ONLY t_zprospection
    ADD CONSTRAINT _t_zprospection_pkey PRIMARY KEY (indexzp);


--
-- TOC entry 3771 (class 2606 OID 2748357)
-- Name: bib_comptages_methodo_pkey; Type: CONSTRAINT; Schema: florepatri; Owner: -
--

ALTER TABLE ONLY bib_comptages_methodo
    ADD CONSTRAINT bib_comptages_methodo_pkey PRIMARY KEY (id_comptage_methodo);


--
-- TOC entry 3773 (class 2606 OID 2748359)
-- Name: bib_frequences_methodo_new_pkey; Type: CONSTRAINT; Schema: florepatri; Owner: -
--

ALTER TABLE ONLY bib_frequences_methodo_new
    ADD CONSTRAINT bib_frequences_methodo_new_pkey PRIMARY KEY (id_frequence_methodo_new);


--
-- TOC entry 3775 (class 2606 OID 2748361)
-- Name: bib_pentes_pkey; Type: CONSTRAINT; Schema: florepatri; Owner: -
--

ALTER TABLE ONLY bib_pentes
    ADD CONSTRAINT bib_pentes_pkey PRIMARY KEY (id_pente);


--
-- TOC entry 3781 (class 2606 OID 2748363)
-- Name: bib_physionomies_pk; Type: CONSTRAINT; Schema: florepatri; Owner: -
--

ALTER TABLE ONLY bib_physionomies
    ADD CONSTRAINT bib_physionomies_pk PRIMARY KEY (id_physionomie);


--
-- TOC entry 3783 (class 2606 OID 2748365)
-- Name: bib_rezo_ecrins_pkey; Type: CONSTRAINT; Schema: florepatri; Owner: -
--

ALTER TABLE ONLY bib_rezo_ecrins
    ADD CONSTRAINT bib_rezo_ecrins_pkey PRIMARY KEY (id_rezo_ecrins);


--
-- TOC entry 3787 (class 2606 OID 2748367)
-- Name: bib_taxons_fp_pkey; Type: CONSTRAINT; Schema: florepatri; Owner: -
--

ALTER TABLE ONLY bib_taxons_fp
    ADD CONSTRAINT bib_taxons_fp_pkey PRIMARY KEY (cd_nom);


--
-- TOC entry 3795 (class 2606 OID 2748369)
-- Name: cor_zp_obs_pkey; Type: CONSTRAINT; Schema: florepatri; Owner: -
--

ALTER TABLE ONLY cor_zp_obs
    ADD CONSTRAINT cor_zp_obs_pkey PRIMARY KEY (indexzp, codeobs);


--
-- TOC entry 3777 (class 2606 OID 2748371)
-- Name: pk_bib_perturbation; Type: CONSTRAINT; Schema: florepatri; Owner: -
--

ALTER TABLE ONLY bib_perturbations
    ADD CONSTRAINT pk_bib_perturbation PRIMARY KEY (codeper);


--
-- TOC entry 3779 (class 2606 OID 2748373)
-- Name: pk_bib_phenologie; Type: CONSTRAINT; Schema: florepatri; Owner: -
--

ALTER TABLE ONLY bib_phenologies
    ADD CONSTRAINT pk_bib_phenologie PRIMARY KEY (codepheno);


--
-- TOC entry 3785 (class 2606 OID 2748375)
-- Name: pk_bib_statuts; Type: CONSTRAINT; Schema: florepatri; Owner: -
--

ALTER TABLE ONLY bib_statuts
    ADD CONSTRAINT pk_bib_statuts PRIMARY KEY (id_statut);


--
-- TOC entry 3789 (class 2606 OID 2748377)
-- Name: pk_cor_ap_perturb; Type: CONSTRAINT; Schema: florepatri; Owner: -
--

ALTER TABLE ONLY cor_ap_perturb
    ADD CONSTRAINT pk_cor_ap_perturb PRIMARY KEY (indexap, codeper);


--
-- TOC entry 3791 (class 2606 OID 2748379)
-- Name: pk_cor_ap_physionomie; Type: CONSTRAINT; Schema: florepatri; Owner: -
--

ALTER TABLE ONLY cor_ap_physionomie
    ADD CONSTRAINT pk_cor_ap_physionomie PRIMARY KEY (indexap, id_physionomie);


--
-- TOC entry 3793 (class 2606 OID 2748381)
-- Name: pk_cor_taxon_statut; Type: CONSTRAINT; Schema: florepatri; Owner: -
--

ALTER TABLE ONLY cor_taxon_statut
    ADD CONSTRAINT pk_cor_taxon_statut PRIMARY KEY (id_statut, cd_nom);


--
-- TOC entry 3796 (class 1259 OID 2748477)
-- Name: fki_cor_zp_obs_t_roles; Type: INDEX; Schema: florepatri; Owner: -
--

CREATE INDEX fki_cor_zp_obs_t_roles ON cor_zp_obs USING btree (codeobs);


--
-- TOC entry 3799 (class 1259 OID 2748478)
-- Name: fki_t_apresence_t_zprospection; Type: INDEX; Schema: florepatri; Owner: -
--

CREATE INDEX fki_t_apresence_t_zprospection ON t_apresence USING btree (indexzp);


--
-- TOC entry 3800 (class 1259 OID 2748479)
-- Name: i_fk_t_apresence_bib_phenologi; Type: INDEX; Schema: florepatri; Owner: -
--

CREATE INDEX i_fk_t_apresence_bib_phenologi ON t_apresence USING btree (codepheno);


--
-- TOC entry 3803 (class 1259 OID 2748480)
-- Name: i_fk_t_zprospection_bib_secteu; Type: INDEX; Schema: florepatri; Owner: -
--

CREATE INDEX i_fk_t_zprospection_bib_secteu ON t_zprospection USING btree (id_secteur);


--
-- TOC entry 3824 (class 2620 OID 2748525)
-- Name: tri_delete_synthese_ap; Type: TRIGGER; Schema: florepatri; Owner: -
--

CREATE TRIGGER tri_delete_synthese_ap AFTER DELETE ON t_apresence FOR EACH ROW EXECUTE PROCEDURE delete_synthese_ap();


--
-- TOC entry 3825 (class 2620 OID 2748526)
-- Name: tri_insert_ap; Type: TRIGGER; Schema: florepatri; Owner: -
--

CREATE TRIGGER tri_insert_ap BEFORE INSERT ON t_apresence FOR EACH ROW EXECUTE PROCEDURE insert_ap();


--
-- TOC entry 3826 (class 2620 OID 2748527)
-- Name: tri_insert_synthese_ap; Type: TRIGGER; Schema: florepatri; Owner: -
--

CREATE TRIGGER tri_insert_synthese_ap AFTER INSERT ON t_apresence FOR EACH ROW EXECUTE PROCEDURE insert_synthese_ap();


--
-- TOC entry 3823 (class 2620 OID 2748528)
-- Name: tri_insert_synthese_cor_zp_obs; Type: TRIGGER; Schema: florepatri; Owner: -
--

CREATE TRIGGER tri_insert_synthese_cor_zp_obs AFTER INSERT ON cor_zp_obs FOR EACH ROW EXECUTE PROCEDURE update_synthese_cor_zp_obs();


--
-- TOC entry 3829 (class 2620 OID 2748529)
-- Name: tri_insert_zp; Type: TRIGGER; Schema: florepatri; Owner: -
--

CREATE TRIGGER tri_insert_zp BEFORE INSERT ON t_zprospection FOR EACH ROW EXECUTE PROCEDURE insert_zp();


--
-- TOC entry 3827 (class 2620 OID 2748530)
-- Name: tri_update_ap; Type: TRIGGER; Schema: florepatri; Owner: -
--

CREATE TRIGGER tri_update_ap BEFORE UPDATE ON t_apresence FOR EACH ROW EXECUTE PROCEDURE update_ap();


--
-- TOC entry 3828 (class 2620 OID 2748531)
-- Name: tri_update_synthese_ap; Type: TRIGGER; Schema: florepatri; Owner: -
--

CREATE TRIGGER tri_update_synthese_ap AFTER UPDATE ON t_apresence FOR EACH ROW EXECUTE PROCEDURE update_synthese_ap();


--
-- TOC entry 3830 (class 2620 OID 2748532)
-- Name: tri_update_synthese_zp; Type: TRIGGER; Schema: florepatri; Owner: -
--

CREATE TRIGGER tri_update_synthese_zp AFTER UPDATE ON t_zprospection FOR EACH ROW EXECUTE PROCEDURE update_synthese_zp();


--
-- TOC entry 3831 (class 2620 OID 2748533)
-- Name: tri_update_zp; Type: TRIGGER; Schema: florepatri; Owner: -
--

CREATE TRIGGER tri_update_zp BEFORE UPDATE ON t_zprospection FOR EACH ROW EXECUTE PROCEDURE update_zp();


--
-- TOC entry 3804 (class 2606 OID 2748731)
-- Name: bib_taxons_fp_cd_nom_fkey; Type: FK CONSTRAINT; Schema: florepatri; Owner: -
--

ALTER TABLE ONLY bib_taxons_fp
    ADD CONSTRAINT bib_taxons_fp_cd_nom_fkey FOREIGN KEY (cd_nom) REFERENCES taxonomie.taxref(cd_nom) ON UPDATE CASCADE;


--
-- TOC entry 3809 (class 2606 OID 2748736)
-- Name: cor_taxon_statut_cd_nom_fkey; Type: FK CONSTRAINT; Schema: florepatri; Owner: -
--

ALTER TABLE ONLY cor_taxon_statut
    ADD CONSTRAINT cor_taxon_statut_cd_nom_fkey FOREIGN KEY (cd_nom) REFERENCES bib_taxons_fp(cd_nom) ON UPDATE CASCADE;


--
-- TOC entry 3805 (class 2606 OID 2748741)
-- Name: fk_cor_ap_perturb_bib_perturbati; Type: FK CONSTRAINT; Schema: florepatri; Owner: -
--

ALTER TABLE ONLY cor_ap_perturb
    ADD CONSTRAINT fk_cor_ap_perturb_bib_perturbati FOREIGN KEY (codeper) REFERENCES bib_perturbations(codeper) ON UPDATE CASCADE;


--
-- TOC entry 3806 (class 2606 OID 2748746)
-- Name: fk_cor_ap_perturb_t_apresence; Type: FK CONSTRAINT; Schema: florepatri; Owner: -
--

ALTER TABLE ONLY cor_ap_perturb
    ADD CONSTRAINT fk_cor_ap_perturb_t_apresence FOREIGN KEY (indexap) REFERENCES t_apresence(indexap) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 3807 (class 2606 OID 2748751)
-- Name: fk_cor_ap_physionomie_bib_physio; Type: FK CONSTRAINT; Schema: florepatri; Owner: -
--

ALTER TABLE ONLY cor_ap_physionomie
    ADD CONSTRAINT fk_cor_ap_physionomie_bib_physio FOREIGN KEY (id_physionomie) REFERENCES bib_physionomies(id_physionomie) ON UPDATE CASCADE;


--
-- TOC entry 3808 (class 2606 OID 2748756)
-- Name: fk_cor_ap_physionomie_t_apresence; Type: FK CONSTRAINT; Schema: florepatri; Owner: -
--

ALTER TABLE ONLY cor_ap_physionomie
    ADD CONSTRAINT fk_cor_ap_physionomie_t_apresence FOREIGN KEY (indexap) REFERENCES t_apresence(indexap) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 3810 (class 2606 OID 2748761)
-- Name: fk_cor_taxon_statut_bib_statuts; Type: FK CONSTRAINT; Schema: florepatri; Owner: -
--

ALTER TABLE ONLY cor_taxon_statut
    ADD CONSTRAINT fk_cor_taxon_statut_bib_statuts FOREIGN KEY (id_statut) REFERENCES bib_statuts(id_statut) ON UPDATE CASCADE;


--
-- TOC entry 3811 (class 2606 OID 2748766)
-- Name: fk_cor_zp_obs_t_roles; Type: FK CONSTRAINT; Schema: florepatri; Owner: -
--

ALTER TABLE ONLY cor_zp_obs
    ADD CONSTRAINT fk_cor_zp_obs_t_roles FOREIGN KEY (codeobs) REFERENCES utilisateurs.t_roles(id_role);


--
-- TOC entry 3812 (class 2606 OID 2748771)
-- Name: fk_cor_zp_obs_t_zprospection; Type: FK CONSTRAINT; Schema: florepatri; Owner: -
--

ALTER TABLE ONLY cor_zp_obs
    ADD CONSTRAINT fk_cor_zp_obs_t_zprospection FOREIGN KEY (indexzp) REFERENCES t_zprospection(indexzp) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 3813 (class 2606 OID 2748776)
-- Name: fk_t_apresence_bib_phenologie; Type: FK CONSTRAINT; Schema: florepatri; Owner: -
--

ALTER TABLE ONLY t_apresence
    ADD CONSTRAINT fk_t_apresence_bib_phenologie FOREIGN KEY (codepheno) REFERENCES bib_phenologies(codepheno) ON UPDATE CASCADE;


--
-- TOC entry 3814 (class 2606 OID 2748781)
-- Name: fk_t_apresence_t_zprospection; Type: FK CONSTRAINT; Schema: florepatri; Owner: -
--

ALTER TABLE ONLY t_apresence
    ADD CONSTRAINT fk_t_apresence_t_zprospection FOREIGN KEY (indexzp) REFERENCES t_zprospection(indexzp) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 3820 (class 2606 OID 2748811)
-- Name: fk_t_zprospection_bib_lots; Type: FK CONSTRAINT; Schema: florepatri; Owner: -
--

ALTER TABLE ONLY t_zprospection
    ADD CONSTRAINT fk_t_zprospection_bib_lots FOREIGN KEY (id_lot) REFERENCES meta.bib_lots(id_lot) ON UPDATE CASCADE;


--
-- TOC entry 3817 (class 2606 OID 2748786)
-- Name: fk_t_zprospection_bib_taxon_fp; Type: FK CONSTRAINT; Schema: florepatri; Owner: -
--

ALTER TABLE ONLY t_zprospection
    ADD CONSTRAINT fk_t_zprospection_bib_taxon_fp FOREIGN KEY (cd_nom) REFERENCES bib_taxons_fp(cd_nom) ON UPDATE CASCADE;


--
-- TOC entry 3819 (class 2606 OID 2748806)
-- Name: fk_t_zprospection_t_protocoles; Type: FK CONSTRAINT; Schema: florepatri; Owner: -
--

ALTER TABLE ONLY t_zprospection
    ADD CONSTRAINT fk_t_zprospection_t_protocoles FOREIGN KEY (id_protocole) REFERENCES meta.t_protocoles(id_protocole) ON UPDATE CASCADE;


--
-- TOC entry 3815 (class 2606 OID 2748791)
-- Name: t_apresence_comptage_methodo_fkey; Type: FK CONSTRAINT; Schema: florepatri; Owner: -
--

ALTER TABLE ONLY t_apresence
    ADD CONSTRAINT t_apresence_comptage_methodo_fkey FOREIGN KEY (id_comptage_methodo) REFERENCES bib_comptages_methodo(id_comptage_methodo) ON UPDATE CASCADE;


--
-- TOC entry 3816 (class 2606 OID 2748796)
-- Name: t_apresence_frequence_methodo_new_fkey; Type: FK CONSTRAINT; Schema: florepatri; Owner: -
--

ALTER TABLE ONLY t_apresence
    ADD CONSTRAINT t_apresence_frequence_methodo_new_fkey FOREIGN KEY (id_frequence_methodo_new) REFERENCES bib_frequences_methodo_new(id_frequence_methodo_new) ON UPDATE CASCADE;


--
-- TOC entry 3818 (class 2606 OID 2748801)
-- Name: t_zprospection_id_organisme_fkey; Type: FK CONSTRAINT; Schema: florepatri; Owner: -
--

ALTER TABLE ONLY t_zprospection
    ADD CONSTRAINT t_zprospection_id_organisme_fkey FOREIGN KEY (id_organisme) REFERENCES utilisateurs.bib_organismes(id_organisme) ON UPDATE CASCADE;


--
-- TOC entry 3821 (class 2606 OID 2748816)
-- Name: t_zprospection_id_rezo_ecrins_fkey; Type: FK CONSTRAINT; Schema: florepatri; Owner: -
--

ALTER TABLE ONLY t_zprospection
    ADD CONSTRAINT t_zprospection_id_rezo_ecrins_fkey FOREIGN KEY (id_rezo_ecrins) REFERENCES bib_rezo_ecrins(id_rezo_ecrins) ON UPDATE CASCADE;


--
-- TOC entry 3822 (class 2606 OID 2748821)
-- Name: t_zprospection_id_secteur_fkey; Type: FK CONSTRAINT; Schema: florepatri; Owner: -
--

ALTER TABLE ONLY t_zprospection
    ADD CONSTRAINT t_zprospection_id_secteur_fkey FOREIGN KEY (id_secteur) REFERENCES layers.l_secteurs(id_secteur) ON UPDATE CASCADE;


SET search_path = synchronomade, pg_catalog;

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


--
-- TOC entry 3363 (class 2604 OID 166468)
-- Name: id; Type: DEFAULT; Schema: synchronomade; Owner: -
--

ALTER TABLE ONLY erreurs_flora ALTER COLUMN id SET DEFAULT nextval('erreurs_flora_id_seq'::regclass);


--
-- TOC entry 3445 (class 2606 OID 166473)
-- Name: erreurs_flora_pkey; Type: CONSTRAINT; Schema: synchronomade; Owner: -; Tablespace: 
--

ALTER TABLE ONLY erreurs_flora
    ADD CONSTRAINT erreurs_flora_pkey PRIMARY KEY (id);



--------------------------------------------------------------------------------------
--------------------INSERTION DES DONNEES DES TABLES DICTIONNAIRES--------------------
--------------------------------------------------------------------------------------

SET search_path = florepatri, pg_catalog;

INSERT INTO bib_comptages_methodo (id_comptage_methodo, nom_comptage_methodo) VALUES (1, 'Recensement exhaustif');
INSERT INTO bib_comptages_methodo (id_comptage_methodo, nom_comptage_methodo) VALUES (2, 'Echantillonage');
INSERT INTO bib_comptages_methodo (id_comptage_methodo, nom_comptage_methodo) VALUES (9, 'Aucun comptage');

INSERT INTO bib_frequences_methodo_new (id_frequence_methodo_new, nom_frequence_methodo_new) VALUES ('N', 'Nouveau transect');
INSERT INTO bib_frequences_methodo_new (id_frequence_methodo_new, nom_frequence_methodo_new) VALUES ('S', 'Estimation');

INSERT INTO bib_pentes (id_pente, val_pente, nom_pente) VALUES (1, 2.5, 'Labourable (0-5)');
INSERT INTO bib_pentes (id_pente, val_pente, nom_pente) VALUES (2, 7.5, 'Fauchable (5-10)');
INSERT INTO bib_pentes (id_pente, val_pente, nom_pente) VALUES (3, 12.5, 'Haut d''un cône de déjection torrentiel (10-15)');
INSERT INTO bib_pentes (id_pente, val_pente, nom_pente) VALUES (4, 17.5, 'Haut d''un cône d''avalanche (15-20)');
INSERT INTO bib_pentes (id_pente, val_pente, nom_pente) VALUES (5, 22.5, 'Pied d''éboulis (20-25)');
INSERT INTO bib_pentes (id_pente, val_pente, nom_pente) VALUES (6, 30, 'Tablier d''éboulis (25-35)');
INSERT INTO bib_pentes (id_pente, val_pente, nom_pente) VALUES (7, 37.5, 'Sommet d''éboulis (35-40)');
INSERT INTO bib_pentes (id_pente, val_pente, nom_pente) VALUES (8, 45, 'Rochillon (sans les mains) (40-50)');
INSERT INTO bib_pentes (id_pente, val_pente, nom_pente) VALUES (9, 55, 'Rochillon (avec les mains) (50-60)');
INSERT INTO bib_pentes (id_pente, val_pente, nom_pente) VALUES (10, 90, 'Vires et barres (>60)');
INSERT INTO bib_pentes (id_pente, val_pente, nom_pente) VALUES (0, 0, 'Aucune pente');

INSERT INTO bib_perturbations (codeper, classification, description) VALUES (73, 'Processus naturels d''érosion', 'Engravement (laves torrentielles et divagation d''une rivière)');
INSERT INTO bib_perturbations (codeper, classification, description) VALUES (11, 'Gestion par le feu', 'Brûlage contrôlé');
INSERT INTO bib_perturbations (codeper, classification, description) VALUES (78, 'Processus naturels d''érosion', 'Eboulement récent');
INSERT INTO bib_perturbations (codeper, classification, description) VALUES (24, 'Activités de loisirs', 'Véhicules à moteur (écrasement)');
INSERT INTO bib_perturbations (codeper, classification, description) VALUES (54, 'Activités forestières', 'Elagage (haie et bord de route)');
INSERT INTO bib_perturbations (codeper, classification, description) VALUES (76, 'Processus naturels d''érosion', 'Sapement de la berge d''un cours d''eau');
INSERT INTO bib_perturbations (codeper, classification, description) VALUES (43, 'Activités agricoles', 'Produits phytosanitaires (épandage)');
INSERT INTO bib_perturbations (codeper, classification, description) VALUES (75, 'Processus naturels d''érosion', 'Erosion s''exerçant sur de vastes surfaces (gélifluxion)');
INSERT INTO bib_perturbations (codeper, classification, description) VALUES (12, 'Gestion par le feu', 'Incendie (naturel ou incontrôlé)');
INSERT INTO bib_perturbations (codeper, classification, description) VALUES (21, 'Activités de loisirs', 'Récolte des fleurs');
INSERT INTO bib_perturbations (codeper, classification, description) VALUES (22, 'Activités de loisirs', 'Arrachage des pieds');
INSERT INTO bib_perturbations (codeper, classification, description) VALUES (23, 'Activités de loisirs', 'Piétinement pédestre');
INSERT INTO bib_perturbations (codeper, classification, description) VALUES (25, 'Activités de loisirs', 'Plongée dans un lac');
INSERT INTO bib_perturbations (codeper, classification, description) VALUES (31, 'Gestion de l''eau', 'Pompage');
INSERT INTO bib_perturbations (codeper, classification, description) VALUES (32, 'Gestion de l''eau', 'Drainage');
INSERT INTO bib_perturbations (codeper, classification, description) VALUES (33, 'Gestion de l''eau', 'Irrigation par gravité');
INSERT INTO bib_perturbations (codeper, classification, description) VALUES (34, 'Gestion de l''eau', 'Irrigation par aspersion');
INSERT INTO bib_perturbations (codeper, classification, description) VALUES (35, 'Gestion de l''eau', 'Curage (fossé, mare, serve)');
INSERT INTO bib_perturbations (codeper, classification, description) VALUES (36, 'Gestion de l''eau', 'Extraction de granulats');
INSERT INTO bib_perturbations (codeper, classification, description) VALUES (41, 'Activités agricoles', 'Labour');
INSERT INTO bib_perturbations (codeper, classification, description) VALUES (42, 'Activités agricoles', 'Fertilisation');
INSERT INTO bib_perturbations (codeper, classification, description) VALUES (44, 'Activités agricoles', 'Fauchaison');
INSERT INTO bib_perturbations (codeper, classification, description) VALUES (45, 'Activités agricoles', 'Apport de blocs (déterrés par le labour)');
INSERT INTO bib_perturbations (codeper, classification, description) VALUES (46, 'Activités agricoles', 'Gyrobroyage');
INSERT INTO bib_perturbations (codeper, classification, description) VALUES (47, 'Activités agricoles', 'Revégétalisation (sur semis)');
INSERT INTO bib_perturbations (codeper, classification, description) VALUES (51, 'Activités forestières', 'Jeune plantation de feuillus');
INSERT INTO bib_perturbations (codeper, classification, description) VALUES (52, 'Activités forestières', 'Jeune plantation mixte (feuillus et résineux)');
INSERT INTO bib_perturbations (codeper, classification, description) VALUES (53, 'Activités forestières', 'Jeune plantation de résineux');
INSERT INTO bib_perturbations (codeper, classification, description) VALUES (55, 'Activités forestières', 'Coupe d''éclaircie');
INSERT INTO bib_perturbations (codeper, classification, description) VALUES (56, 'Activités forestières', 'Coupe à blanc');
INSERT INTO bib_perturbations (codeper, classification, description) VALUES (57, 'Activités forestières', 'Bois coupé et laissé sur place');
INSERT INTO bib_perturbations (codeper, classification, description) VALUES (58, 'Activités forestières', 'Ouverture de piste forestière');
INSERT INTO bib_perturbations (codeper, classification, description) VALUES (61, 'Comportement des animaux', 'Jas (couchades nocturnes des animaux domestiques)');
INSERT INTO bib_perturbations (codeper, classification, description) VALUES (62, 'Comportement des animaux', 'Chaume (couchades aux heures chaudes des animaux domestiques)');
INSERT INTO bib_perturbations (codeper, classification, description) VALUES (63, 'Comportement des animaux', 'Faune sauvage (reposoir)');
INSERT INTO bib_perturbations (codeper, classification, description) VALUES (64, 'Comportement des animaux', 'Piétinement, sans apports de déjection');
INSERT INTO bib_perturbations (codeper, classification, description) VALUES (65, 'Comportement des animaux', 'Pâturage (sur herbacées exclusivement)');
INSERT INTO bib_perturbations (codeper, classification, description) VALUES (66, 'Comportement des animaux', 'Abroutissement et écorçage (sur ligneux)');
INSERT INTO bib_perturbations (codeper, classification, description) VALUES (71, 'Processus naturels d''érosion', 'Submersion temporaire');
INSERT INTO bib_perturbations (codeper, classification, description) VALUES (72, 'Processus naturels d''érosion', 'Envasement');
INSERT INTO bib_perturbations (codeper, classification, description) VALUES (74, 'Processus naturels d''érosion', 'Avalanche : apport de matériaux non triés');
INSERT INTO bib_perturbations (codeper, classification, description) VALUES (77, 'Processus naturels d''érosion', 'Avalanche : ramonage du terrain');
INSERT INTO bib_perturbations (codeper, classification, description) VALUES (81, 'Aménagements lourds', 'Carrière en roche dure');
INSERT INTO bib_perturbations (codeper, classification, description) VALUES (82, 'Aménagements lourds', 'Fossé pare-blocs');
INSERT INTO bib_perturbations (codeper, classification, description) VALUES (83, 'Aménagements lourds', 'Endiguement');
INSERT INTO bib_perturbations (codeper, classification, description) VALUES (84, 'Aménagements lourds', 'Terrassement pour aménagements lourds');
INSERT INTO bib_perturbations (codeper, classification, description) VALUES (85, 'Aménagements lourds', 'Déboisement avec désouchage');
INSERT INTO bib_perturbations (codeper, classification, description) VALUES (86, 'Aménagements lourds', 'Béton, goudron : revêtement abiotique');
INSERT INTO bib_perturbations (codeper, classification, description) VALUES (67, 'Comportement des animaux', 'Sangliers : labours et grattis');
INSERT INTO bib_perturbations (codeper, classification, description) VALUES (68, 'Comportement des animaux', 'Marmottes : terriers');
INSERT INTO bib_perturbations (codeper, classification, description) VALUES (69, 'Comportement des animaux', 'Chenilles : défoliation');
INSERT INTO bib_perturbations (codeper, classification, description) VALUES (91, 'Gestion des invasives', 'Arrachage');
INSERT INTO bib_perturbations (codeper, classification, description) VALUES (92, 'Gestion des invasives', 'Fauchage');
INSERT INTO bib_perturbations (codeper, classification, description) VALUES (93, 'Gestion des invasives', 'Débroussaillage');
INSERT INTO bib_perturbations (codeper, classification, description) VALUES (94, 'Gestion des invasives', 'Recouvrement avec bâches');

INSERT INTO bib_phenologies (codepheno, pheno) VALUES (1, 'Stade végétatif');
INSERT INTO bib_phenologies (codepheno, pheno) VALUES (2, 'Stade boutons floraux');
INSERT INTO bib_phenologies (codepheno, pheno) VALUES (3, 'Début de floraison');
INSERT INTO bib_phenologies (codepheno, pheno) VALUES (4, 'Pleine floraison');
INSERT INTO bib_phenologies (codepheno, pheno) VALUES (5, 'Fin de floraison et maturation des fruits');
INSERT INTO bib_phenologies (codepheno, pheno) VALUES (6, 'Dissémination');
INSERT INTO bib_phenologies (codepheno, pheno) VALUES (7, 'Stade de décrépitude');
INSERT INTO bib_phenologies (codepheno, pheno) VALUES (8, 'Stage végétatif permanent ');

INSERT INTO bib_physionomies (id_physionomie, groupe_physionomie, nom_physionomie, definition_physionomie, code_physionomie) VALUES (1, 'Herbacée', 'Alluvions (Végétation herbacée pionnière des)', 'Formation très ouverte pionnière des alluvions actifs, régulièrement perturbés et alimentés, des torrents, des rivières et des fleuves à régime nival (bilan hydrique largement déficient sur un substrat très drainant), riches en galets mêlés ou non de terre fine.', 'AL');
INSERT INTO bib_physionomies (id_physionomie, groupe_physionomie, nom_physionomie, definition_physionomie, code_physionomie) VALUES (2, 'Herbacée', 'Végétation aquatique', 'Ensemble vaste de formations végétales strictement aquatiques (non hélophytiques), des eaux stagnantes et courantes, enracinées ou libres, immergées ou submergées. Comprend les herbiers à Sparganium angustifolium des étages subalpin et alpin.', 'AQ');
INSERT INTO bib_physionomies (id_physionomie, groupe_physionomie, nom_physionomie, definition_physionomie, code_physionomie) VALUES (3, 'Herbacée', 'Autre formation herbacée artificielle', 'à garder ?', 'AR');
INSERT INTO bib_physionomies (id_physionomie, groupe_physionomie, nom_physionomie, definition_physionomie, code_physionomie) VALUES (4, 'Herbacée', 'Bas-marais et marais de transition', 'Formation basse dominée par des cypéracées de petites et moyennes taille à nappe d''eau proche ou juste au dessus de la surface. Comprend aussi les formations amphibies franchement aquatiques (ceinture à Eriophorum scheuchzeri) des étages subalpin et alpin.', 'BM');
INSERT INTO bib_physionomies (id_physionomie, groupe_physionomie, nom_physionomie, definition_physionomie, code_physionomie) VALUES (5, 'Herbacée', 'Combe à neige (Végétation des)', 'Formation à degré d''ouverture variable des zones longuement enneigées de l''étage alpin (rare au subalpin) souvent dominée par des nanophanérophytes du genre Salix. Substrat variable, formes minérales  caractérisées le tassement des éléments du substrat (fins à moyens)', 'CN');
INSERT INTO bib_physionomies (id_physionomie, groupe_physionomie, nom_physionomie, definition_physionomie, code_physionomie) VALUES (6, 'Herbacée', 'Cultures  (Végétation des)', 'Formation basse et très ouverte dominée par des plantes annuelles (à bisannuelles) des terrains agricoles exploités et les cultures arboricoles à terre retournée.', 'CU');
INSERT INTO bib_physionomies (id_physionomie, groupe_physionomie, nom_physionomie, definition_physionomie, code_physionomie) VALUES (7, 'Herbacée', 'Dalles rocheuses (Végétation pionnière des)', 'Formation herbacée ouverte pionnière des affleurements rocheux (souvent tabulaires avec pente peu marqué), riche en plantes grasses et à composition mixte vivaces et annuelles. Elle comprend la végétation pionnière des lapiaz vifs', 'DA');
INSERT INTO bib_physionomies (id_physionomie, groupe_physionomie, nom_physionomie, definition_physionomie, code_physionomie) VALUES (8, 'Herbacée', 'Éboulis (Végétation des)', 'Formation très ouverte pionnière des éboulis et chaos rocheux, actifs ou stabilisés, comprenant la végétation colonisant les moraines. Formation caractérisée par la (quasi) absence de sol. Ne comprend pas les formations pionnières à saules nains des chaos rocheux longuement enneigés qui sont à coder sous CN (combes à neige)', 'EB');
INSERT INTO bib_physionomies (id_physionomie, groupe_physionomie, nom_physionomie, definition_physionomie, code_physionomie) VALUES (9, 'Herbacée', 'Bordure d''eaux courantes  (Végétation amphibie des)', 'Formation amphibie vivace dense (petits hélophytes souvent) et entremêlée occupant les petits cours d''eau et leurs berges ainsi que les lones et bras-mort à courant faible (comprend les herbiers à Glyceria, Berula, Apium, Nasturtium et Leersia).', 'EC');
INSERT INTO bib_physionomies (id_physionomie, groupe_physionomie, nom_physionomie, definition_physionomie, code_physionomie) VALUES (10, 'Herbacée', 'Grèves exondées  (Végétation pionnière des)', 'Formation pionnière annuelle et vivace de petite taille (Eleocharis acicularis, Littorella uniflora, Ludwigia palustris, Juncus bulbosus…) ou plus haute (Polygonum lapathifolium, Bidens pl.sp. etc.). des  zones périodiquement exondées des eaux stagnantes et courantes, végétation à caractère amphibie souvent marqué.', 'EX');
INSERT INTO bib_physionomies (id_physionomie, groupe_physionomie, nom_physionomie, definition_physionomie, code_physionomie) VALUES (11, 'Herbacée', 'Végétation fontinale', 'Formation en majorité dominée par les bryophytes, avec végétation vasculaire peu diversifiée mais parfois assez recouvrante (Epilobium alsinifolium, Saxifraga aizoides, Carex frigida), colonisant les sources, les bords de ruisselets et les rochers suintants, milieux imbibé en permanence', 'FO');
INSERT INTO bib_physionomies (id_physionomie, groupe_physionomie, nom_physionomie, definition_physionomie, code_physionomie) VALUES (12, 'Herbacée', 'Grands hélophytes  (Communauté de)', 'Formation souvent dense de grands hélophytes graminoïdes (roselières au sens large à Phragmites, Phalaris, Typha, Schoenoplectus, Cladium...) comprenant à la fois les communautés franchement aquatique et les communautés terrestres (atterries).', 'GH');
INSERT INTO bib_physionomies (id_physionomie, groupe_physionomie, nom_physionomie, definition_physionomie, code_physionomie) VALUES (13, 'Herbacée', 'Haut-marais', 'Formation mixte bryophytique (sphaignes), herbacée (cypéracée) et sous-arbustive (éricacées) formant un paysage lâchement moutonné de buttes de sphaignes et de creux plus ou moins inondés ', 'HM');
INSERT INTO bib_physionomies (id_physionomie, groupe_physionomie, nom_physionomie, definition_physionomie, code_physionomie) VALUES (14, 'Herbacée', 'Végétation rase hyperpiétinée', 'Formation dominée par des plantes annuelles prostrées supportant le piétinement régulier de toute nature', 'HY');
INSERT INTO bib_physionomies (id_physionomie, groupe_physionomie, nom_physionomie, definition_physionomie, code_physionomie) VALUES (15, 'Herbacée', 'Magnocariçaie', 'Formation haute dominée par des hélophytes de la famille des cypéracées comprenant à la fois les communautés franchement aquatiques et des communautés terrestres à sol mouillé une partie de l''année.', 'MC');
INSERT INTO bib_physionomies (id_physionomie, groupe_physionomie, nom_physionomie, definition_physionomie, code_physionomie) VALUES (16, 'Herbacée', 'Mégaphorbiaie', 'Formation dense et haute dominée par des dicotylédones à feuillage très recouvrant des milieux frais à humides, riches en éléments minéraux. Comprend aussi les formations montagnardes à subalpines mésophiles composition mixte entre graminées et dicotylédones (Calamagrostis sp. souvent), d’origine naturelle (praires de couloirs d’avalanche). Plaine, montagnard et subalpin. Urtica, Anthriscus, Convolvulus, lisière nitrophiles ?', 'MG');
INSERT INTO bib_physionomies (id_physionomie, groupe_physionomie, nom_physionomie, definition_physionomie, code_physionomie) VALUES (17, 'Herbacée', 'Murs  (Végétation anthropique des)', 'Formation colonisant les murs', 'MU');
INSERT INTO bib_physionomies (id_physionomie, groupe_physionomie, nom_physionomie, definition_physionomie, code_physionomie) VALUES (18, 'Herbacée', 'Coupes et ourlets forestiers', 'Formation intraforestière, constituée de grandes dicotylédones vivaces colonisant les coupes forestières récentes et les clairières à sol riches, ou de dicotylédones moins grande en situation de lisière et de clairière (Aegopodium, … ). Comprend également les formations de lisière intraforestièresd dominées par des graminées (Festuca gigantea, Bromus ramosus / benekenii, Calamagrostis varia, Elytrigia / Roegneria ou encore à Hordelymus europaeus ). A préciser JCV. Comprend les ronciers forestiers. Les formations riveraines à Petasites albus (souvent intraforestières) sont codées sous MG – Mégaphorbiaie. Les formations de lisère humides à Petasites albus sont quant à elles traités ici. ', 'OF');
INSERT INTO bib_physionomies (id_physionomie, groupe_physionomie, nom_physionomie, definition_physionomie, code_physionomie) VALUES (19, 'Herbacée', 'Ourlet maigre', 'Formation mésophile à méso-xérophile, peu élevée, développées sur des terrains maigres en bordure externe de végétations arbustives et forestières (conditions héliophiles à hémi-héliophiles) ou colonisant d’ancien espaces agro-pastoraux, dominée par des espèces à développement tardif, parmi lesquels les graminées sont (co-)dominantes. Les formations à Rubus sont codés OU ou OF en fonction de leur situation. Les manteaux arbustifs sont traités dans les fourré quand le recouvrement arbustif > 25 %, < 25 %, ils sont traités ici', 'OU');
INSERT INTO bib_physionomies (id_physionomie, groupe_physionomie, nom_physionomie, definition_physionomie, code_physionomie) VALUES (20, 'Herbacée', 'Pelouse alpine et pâturage d''altitude', 'Formation basse diversifiée à dominante de graminées et de cypéracées peu élevées des étages supérieurs (subalpin et alpin). Recouvrement minéral souvent important, comprend aussi les pelouses rocailleuses de colonisation d''éboulis et des roches altérées. L''altitude est le critère déterminant.', 'PA');
INSERT INTO bib_physionomies (id_physionomie, groupe_physionomie, nom_physionomie, definition_physionomie, code_physionomie) VALUES (21, 'Herbacée', 'Prairie humide', 'Formation herbacée d''origine anthropique diversifiée, dense et haute à dominante graminéenne, fauchée et/ou pâturée, humide à mouillée (nappe affleurante) une partie de l''année, périodiquement inondée. Les prairies alluviales à Arrhenatherum elatius à tendance mésohygrophile des niveaux topo supérieurs sont traitées sous PM. Les formations basses méditerranéennes à Deschampsia media sont comprises dans PH.', 'PH');
INSERT INTO bib_physionomies (id_physionomie, groupe_physionomie, nom_physionomie, definition_physionomie, code_physionomie) VALUES (22, 'Herbacée', 'Prairie mésophile', 'Formation diversifiée d''origine anthropique, dense et haute à dominante graminéenne de hauteur supérieure à 50 cm, fauchée et/ou pâturée, temporairement humide, exceptionnellement inondée et mouillée. Les formations semi hautes pâturées d''altitude ne sont pas comprises. La hauteur de certaines formations (ex. formation dense à Brome érigé) doit examinées attentivement pour distinguer la pelouse de la prairie. Les formations naturelles montagnardes à hautes herbes mixte (graminées et dicotylédones) sont à coder sous MG Mégaphorbiaie.', 'PM');
INSERT INTO bib_physionomies (id_physionomie, groupe_physionomie, nom_physionomie, definition_physionomie, code_physionomie) VALUES (23, 'Herbacée', 'Pelouse (de basse et moyenne altitude)', 'Formation basse diversifiée, de hauteur moyenne inférieure à 50 cm à dominante graminéenne, des sols maigres des étages planitiaire, collinéen et montagnard. Recouvrement minéral variable, comprend aussi les pelouses rocailleuses de colonisation d''éboulis et des roches altérées. La hauteur de certaines formations (ex. formation dense à Brome érigé) doit examinées attentivement pour distinguer la pelouse de la prairie.', 'PS');
INSERT INTO bib_physionomies (id_physionomie, groupe_physionomie, nom_physionomie, definition_physionomie, code_physionomie) VALUES (24, 'Herbacée', 'Petits hélophytes (Communauté de)', 'Formation souvent clairsemée de petits hélophytes non graminoïdes des eaux stagnantes peu profondes à niveau variable (Sparganium sppl., Alisma sppl., Equisetum fluviatile, Oenanthe aquatica, Rorippa amphibia, Butomus umbellatus, Sagitaria sagitifolia), également appelé roselière basse.', 'RB');
INSERT INTO bib_physionomies (id_physionomie, groupe_physionomie, nom_physionomie, definition_physionomie, code_physionomie) VALUES (25, 'Herbacée', 'Parois et façades rocheuses (Végétation des)', 'Formation clairsemée des anfractuosités rocheuses, végétation saxicole au sens strict, incluant la végétation des rochers frais méridionaux mais pas les suintement quasi permanents', 'RO');
INSERT INTO bib_physionomies (id_physionomie, groupe_physionomie, nom_physionomie, definition_physionomie, code_physionomie) VALUES (26, 'Herbacée', 'Friche herbacée et végétation rudérale', 'Formation dominée par des espèces annuelles et/ou bisannuelles des terrains agricoles, urbains, industriels irrégulièrement perturbé, souvent nitrophile. Comprend aussi la végétation rudérale vivace  des reposoirs à bestiaux et des friches à graminées (chiendent) sur anciens terrains agricoles. Comprend également les formations vivaces de substitution de xénopytes (Reynoutria japonica/ bohemica ou Impatiens glandulifera. lisières nitrophiles ?', 'RU');
INSERT INTO bib_physionomies (id_physionomie, groupe_physionomie, nom_physionomie, definition_physionomie, code_physionomie) VALUES (27, 'Herbacée', 'Pelouse pionnière annuelle', 'Formation très ouverte primaire dominée par espèces annuelles de petite taille à cycle court, fréquemment sur substrats fins et mobiles', 'TH');
INSERT INTO bib_physionomies (id_physionomie, groupe_physionomie, nom_physionomie, definition_physionomie, code_physionomie) VALUES (101, 'Sous-arbustive', 'Lande  (et landine)', 'Formation végétale dominée par des petits chaméphytes (landines) ou des grands chaméphytes (landes). Les seuils de recouvrement de la strate sous-arbustive sont donnés dans « Physionomies complexes ».', 'LA');
INSERT INTO bib_physionomies (id_physionomie, groupe_physionomie, nom_physionomie, definition_physionomie, code_physionomie) VALUES (102, 'Sous-arbustive', 'Garrigue  (incluant les ourlets herbacés méditerranéens)', 'Formation végétale dominée par des chaméphytes des secteurs supra- et oro-méditerranéens', 'GA');
INSERT INTO bib_physionomies (id_physionomie, groupe_physionomie, nom_physionomie, definition_physionomie, code_physionomie) VALUES (201, 'Arbustive', 'Fourré mésophile (mésophile à sec)', 'Formation dominée des espèces caducifoliées des autres situations (Coryllaie, coudraie, accru à …, fourré à Amelanchier, …). ', 'FM');
INSERT INTO bib_physionomies (id_physionomie, groupe_physionomie, nom_physionomie, definition_physionomie, code_physionomie) VALUES (202, 'Arbustive', 'Fourré artificiel', 'ex. : haie bocagère', 'FR');
INSERT INTO bib_physionomies (id_physionomie, groupe_physionomie, nom_physionomie, definition_physionomie, code_physionomie) VALUES (203, 'Arbustive', 'Fourré sempervirent', 'Formation dominée par des espèces à feuillage persistant, épineuses ou non', 'FS');
INSERT INTO bib_physionomies (id_physionomie, groupe_physionomie, nom_physionomie, definition_physionomie, code_physionomie) VALUES (204, 'Arbustive', 'Fourré humide', 'Formation dominée des des espèces caducifoliées des sols engorgés, des bordures d''eaux calmes et courantes (saulaie arbustive, fourré à bourdaine, …). Les aulnaies vertes sont traitées sous FM', 'FU');
INSERT INTO bib_physionomies (id_physionomie, groupe_physionomie, nom_physionomie, definition_physionomie, code_physionomie) VALUES (301, 'Arborescente', 'Boisement artificiel', NULL, 'BA');
INSERT INTO bib_physionomies (id_physionomie, groupe_physionomie, nom_physionomie, definition_physionomie, code_physionomie) VALUES (302, 'Arborescente', 'Boisement de conifères humide', 'Formation dominée par les conifères ( > 75 %  recouvrement) des sols humides ou engorgés. Les pré-bois de Pin à crochet sur tourbe sont considérés comme des formations arborescentes dès 15 % de recouvrement (au lieu de 30 % pour les autres essences).', 'BCH');
INSERT INTO bib_physionomies (id_physionomie, groupe_physionomie, nom_physionomie, definition_physionomie, code_physionomie) VALUES (303, 'Arborescente', 'Boisement de conifère  (mésophile à sec)', 'Formation dominée par les conifères (> 75 %  recouvrement) des situations  sèches ou mésophiles. Les pré-bois de Mélèze, Arolle, Pin à crochet et de Thurifère sont considérés comme des formations arborescentes dès 15 % de recouvrement (au lieu de 30 % pour les autres essences).', 'BCM');
INSERT INTO bib_physionomies (id_physionomie, groupe_physionomie, nom_physionomie, definition_physionomie, code_physionomie) VALUES (304, 'Arborescente', 'Boisement feuillu humide', 'Formation dominée par des espèces feuillues  (> 75 % de recouvrement) caducifoliées des sols engorgés (nappe affleurante ou peu profonde) et des situations alluviales et riveraines (nappe  circulante à niveau variable et crues). Les boisements à sous bois de mégaphorbiaie non riverain ou alluviaux sont traités sous BFM.', 'BFH');
INSERT INTO bib_physionomies (id_physionomie, groupe_physionomie, nom_physionomie, definition_physionomie, code_physionomie) VALUES (305, 'Arborescente', 'Boisement feuillu  (mésophile à sec)', 'Formation dominée par des espèces feuillues  (> 75 % de recouvrement) caducifoliées des autres situations, sèches ou mésophiles', 'BFM');
INSERT INTO bib_physionomies (id_physionomie, groupe_physionomie, nom_physionomie, definition_physionomie, code_physionomie) VALUES (306, 'Arborescente', 'Boisement feuillu sempervirent', 'Formation dominée par des espèces feuillues  (> 75 % de recouvrement) sempervirentes', 'BFS');
INSERT INTO bib_physionomies (id_physionomie, groupe_physionomie, nom_physionomie, definition_physionomie, code_physionomie) VALUES (307, 'Arborescente', 'Boisement mixte  (conifères/feuillus, sempervirent/caduc.)', 'Formation mixte conifères/feuillus ou feuillus sempervirents/feuillus caducifolié dans laquelle aucune des essences atteint individuellement 75 % de la surface. Les combinaisons mixte d’essences sont retenues dans la liste de peuplements.', 'BMI');

INSERT INTO bib_rezo_ecrins (id_rezo_ecrins, nom_rezo_ecrins) VALUES (1, 'La synchronisation de la base Ecrins vers la base Rezo a été faite avec succès');
INSERT INTO bib_rezo_ecrins (id_rezo_ecrins, nom_rezo_ecrins) VALUES (2, 'La synchronisation de la base Rézo vers la base Ecrins a été faite avec succès');
INSERT INTO bib_rezo_ecrins (id_rezo_ecrins, nom_rezo_ecrins) VALUES (0, 'Erreur de synchronisation entre les 2 bases');
INSERT INTO bib_rezo_ecrins (id_rezo_ecrins, nom_rezo_ecrins) VALUES (9, 'Pas de synchronisation entre les 2 bases (données existantes avant mise en place synchronisations)');

INSERT INTO bib_statuts (id_statut, nom_statut, desc_statut) VALUES (1, 'UICN Vu', 'Liste rouge UICN - Vulnérable');
INSERT INTO bib_statuts (id_statut, nom_statut, desc_statut) VALUES (2, 'UICN En', 'Liste rouge UICN - En danger');
INSERT INTO bib_statuts (id_statut, nom_statut, desc_statut) VALUES (3, 'UICN Cr', 'Liste rouge UICN - En danger critique d''extinction');
INSERT INTO bib_statuts (id_statut, nom_statut, desc_statut) VALUES (10, 'PR PACA', 'Protection régionale Provence Alpes Caôte d''Azur');
INSERT INTO bib_statuts (id_statut, nom_statut, desc_statut) VALUES (11, 'PR RA', 'Protection régionale Rhône-Alpes');
INSERT INTO bib_statuts (id_statut, nom_statut, desc_statut) VALUES (12, 'PD 05', 'Protection départementale Hautes-Alpes');
INSERT INTO bib_statuts (id_statut, nom_statut, desc_statut) VALUES (13, 'PD 38', 'Protection départementale Isère');
INSERT INTO bib_statuts (id_statut, nom_statut, desc_statut) VALUES (14, 'PD 01', 'Protection départementale Ain');
INSERT INTO bib_statuts (id_statut, nom_statut, desc_statut) VALUES (15, 'PD 04', 'Protection départementale Alpes de Haute Provence');
INSERT INTO bib_statuts (id_statut, nom_statut, desc_statut) VALUES (16, 'PD 73', 'Protection départementale Savoie');
INSERT INTO bib_statuts (id_statut, nom_statut, desc_statut) VALUES (17, 'PD 74', 'Protection départementale Haute Savoie');
INSERT INTO bib_statuts (id_statut, nom_statut, desc_statut) VALUES (18, 'PD 26', 'Protection départementale Drôme');
INSERT INTO bib_statuts (id_statut, nom_statut, desc_statut) VALUES (30, 'PNat', 'Protection national');
INSERT INTO bib_statuts (id_statut, nom_statut, desc_statut) VALUES (40, 'EEE', 'Espèce exotique invasive');

INSERT INTO bib_taxons_fp (num_nomenclatural, francais, latin, echelle, cd_nom, nomade_ecrins) VALUES (102232, 'Herbe aux cosaques', 'Litwinowia tenuissima', 4000, 611131, true);
INSERT INTO bib_taxons_fp (num_nomenclatural, francais, latin, echelle, cd_nom, nomade_ecrins) VALUES (35676, 'Houx', 'Ilex aquifolium', 8000, 103514, false);
INSERT INTO bib_taxons_fp (num_nomenclatural, francais, latin, echelle, cd_nom, nomade_ecrins) VALUES (43424, 'Cerfeuil musqué', 'Myrrhis odorata', 4000, 109161, false);
INSERT INTO bib_taxons_fp (num_nomenclatural, francais, latin, echelle, cd_nom, nomade_ecrins) VALUES (1071, 'Aethionéma des rochers', 'Aethionema saxatile', 8000, 130869, false);
INSERT INTO bib_taxons_fp (num_nomenclatural, francais, latin, echelle, cd_nom, nomade_ecrins) VALUES (14752, 'Châtaigner', 'Castanea sativa', 8000, 89304, false);
INSERT INTO bib_taxons_fp (num_nomenclatural, francais, latin, echelle, cd_nom, nomade_ecrins) VALUES (19204, 'Cotonéaster intermédiaire', 'Cotoneaster intermedius', 8000, 92715, false);
INSERT INTO bib_taxons_fp (num_nomenclatural, francais, latin, echelle, cd_nom, nomade_ecrins) VALUES (19226, 'Cotonéaster de Rabou', 'Cotoneaster raboutensis', 8000, 92700, false);
INSERT INTO bib_taxons_fp (num_nomenclatural, francais, latin, echelle, cd_nom, nomade_ecrins) VALUES (26575, 'Fétuque alpine', 'Festuca alpina', 8000, 98054, false);
INSERT INTO bib_taxons_fp (num_nomenclatural, francais, latin, echelle, cd_nom, nomade_ecrins) VALUES (29235, 'Gaillet des rochers', 'Galium saxosum', 8000, 99530, false);
INSERT INTO bib_taxons_fp (num_nomenclatural, francais, latin, echelle, cd_nom, nomade_ecrins) VALUES (39494, 'Liparis de loesel', 'Liparis loeselii', 4000, 106353, false);


--------------------------------------------------------------------------------------
--------------------AJOUT DU MODULE DANS LES TABLES DE DESCRIPTION--------------------
--------------------------------------------------------------------------------------

SET search_path = meta, pg_catalog;
INSERT INTO bib_programmes (id_programme, nom_programme, desc_programme, actif, programme_public, desc_programme_public) VALUES (4, 'Flore prioritaire', 'Inventaire et suivi en présence absence de la Flore prioritaire.', true, true, 'Inventaire et suivi en présence absence de la Flore prioritaire.');
INSERT INTO bib_lots (id_lot, nom_lot, desc_lot, menu_cf, pn, menu_inv, id_programme) VALUES (4, 'flore prioritaire', 'Inventaire et suivi en présence absence de la Flore prioritaire', false, true, false, 4);
INSERT INTO t_protocoles VALUES (4, 'Flore prioritaire', 'à compléter', 'à compléter', 'à compléter', 'non', NULL, NULL);
SET search_path = synthese, pg_catalog;
INSERT INTO bib_sources (id_source, nom_source, desc_source, host, port, username, pass, db_name, db_schema, db_table, db_field, url, target, picto, groupe, actif) VALUES (4, 'Flore prioritaire', 'Relevés en présence-absence de la flore prioritaire', 'localhost', 22, NULL, NULL, 'geonaturedb', 'florepatri', 't_apresence', 'indexap', 'pda', NULL, 'images/pictos/plante.gif', 'FLORE', false);


--------------------------------------------------------------------------------------
--------------------AJOUT DU MODULE DANS LES TABLES SPATIALES-------------------------
--------------------------------------------------------------------------------------

SET search_path = public, pg_catalog;
INSERT INTO geometry_columns (f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, type) VALUES ('', 'florepatri', 'v_mobile_visu_zp', 'the_geom_2154', 2, 2154, 'POLYGON');
INSERT INTO geometry_columns (f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, type) VALUES ('', 'florepatri', 'v_ap_poly', 'the_geom_2154', 2, 2154, 'POLYGON');
INSERT INTO geometry_columns (f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, type) VALUES ('', 'florepatri', 'v_ap_point', 'the_geom_2154', 2, 2154, 'POINT');
INSERT INTO geometry_columns (f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, type) VALUES ('', 'florepatri', 'v_ap_line', 'the_geom_2154', 2, 2154, 'LINESTRING');
INSERT INTO geometry_columns (f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, type) VALUES ('', 'florepatri', 'v_touteslesap_2154_point', 'the_geom_2154', 2, 2154, 'POINT');
INSERT INTO geometry_columns (f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, type) VALUES ('', 'florepatri', 'v_touteslesap_2154_line', 'the_geom_2154', 2, 2154, 'LINESTRING');
INSERT INTO geometry_columns (f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, type) VALUES ('', 'florepatri', 'v_touteslesap_2154_polygon', 'the_geom_2154', 2, 2154, 'POLYGON');
INSERT INTO geometry_columns (f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, type) VALUES ('', 'florepatri', 'v_toutesleszp_2154', 'the_geom_2154', 2, 2154, 'POLYGON');
INSERT INTO geometry_columns (f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, type) VALUES ('', 'florepatri', 't_apresence', 'the_geom_2154', 2, 2154, 'POINT');
INSERT INTO geometry_columns (f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, type) VALUES ('', 'florepatri', 't_apresence', 'the_geom_3857', 2, 3857, 'POINT');
INSERT INTO geometry_columns (f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, type) VALUES ('', 'florepatri', 't_zprospection', 'the_geom_2154', 2, 2154, 'POLYGON');
INSERT INTO geometry_columns (f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, type) VALUES ('', 'florepatri', 't_zprospection', 'geom_point_3857', 2, 3857, 'POINT');
INSERT INTO geometry_columns (f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, type) VALUES ('', 'florepatri', 't_zprospection', 'geom_mixte_3857', 2, 3857, 'POLYGON');
INSERT INTO geometry_columns (f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, type) VALUES ('', 'florepatri', 't_zprospection', 'the_geom_3857', 2, 3857, 'POLYGON');