----------------------------------------------
--Mise à jour des champs the_geom_2154--------
--partant du principe qu'aucune structure-----
--n'a de geonature avec une autre projection--
----------------------------------------------

----------------------------------------------
--BRYOPHYTES----------------------------------
----------------------------------------------

ALTER TABLE bryophytes.t_stations_bryo RENAME the_geom_2154  TO the_geom_local;
ALTER TABLE bryophytes.t_stations_bryo DROP CONSTRAINT enforce_srid_the_geom_2154;
ALTER TABLE bryophytes.t_stations_bryo ADD CONSTRAINT enforce_srid_the_geom_local CHECK (st_srid(the_geom_local) = 2154);
ALTER TABLE bryophytes.t_stations_bryo DROP CONSTRAINT enforce_geotype_the_geom_2154;
ALTER TABLE bryophytes.t_stations_bryo ADD CONSTRAINT enforce_geotype_the_geom_local CHECK (geometrytype(the_geom_local) = 'POINT'::text OR the_geom_local IS NULL);
ALTER TABLE bryophytes.t_stations_bryo DROP CONSTRAINT enforce_dims_the_geom_2154;
ALTER TABLE bryophytes.t_stations_bryo ADD CONSTRAINT enforce_dims_the_geom_local CHECK (st_ndims(the_geom_local) = 2);
--TODO : add gist index


-- Function: bryophytes.bryophytes_insert()
CREATE OR REPLACE FUNCTION bryophytes.bryophytes_insert()
  RETURNS trigger AS
$BODY$

BEGIN

new.date_insert= 'now';  -- mise a jour de date insert
new.the_geom_local = public.st_transform(new.the_geom_3857,2154);
new.insee = layers.f_insee(new.the_geom_local);-- mise a jour du code insee
new.altitude_sig = layers.f_isolines20(new.the_geom_local); -- mise à jour de l'altitude sig

IF new.altitude_saisie is null or new.altitude_saisie = 0 then -- mis à jour de l'altitude retenue
  new.altitude_retenue = new.altitude_sig;
ELSE
  new.altitude_retenue = new.altitude_saisie;
END IF;

RETURN new; -- return new procède à l'insertion de la donnée dans PG avec les nouvelles valeures.     

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

-- Function: bryophytes.bryophytes_update()
CREATE OR REPLACE FUNCTION bryophytes.bryophytes_update()
  RETURNS trigger AS
$BODY$
BEGIN
IF (NOT public.st_equals(new.the_geom_local,old.the_geom_local) OR (old.the_geom_local is null AND new.the_geom_local is NOT NULL))
  OR (NOT public.st_equals(new.the_geom_3857,old.the_geom_3857) OR (old.the_geom_3857 is null AND new.the_geom_3857 is NOT NULL)) 
   THEN

  IF NOT public.st_equals(new.the_geom_3857,old.the_geom_3857) OR (old.the_geom_3857 is null AND new.the_geom_3857 is NOT NULL) THEN
    new.the_geom_local = public.st_transform(new.the_geom_3857,2154);
    new.srid_dessin = 3857;
  ELSIF NOT public.st_equals(new.the_geom_local,old.the_geom_local) OR (old.the_geom_local is null AND new.the_geom_local is NOT NULL) THEN
    new.the_geom_3857 = public.st_transform(new.the_geom_local,3857);
    new.srid_dessin = 2154;
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

new.date_update= 'now';  -- mise a jour de date insert

RETURN new; -- return new procède à l'insertion de la donnée dans PG avec les nouvelles valeures.     
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;


-- Function: bryophytes.update_synthese_stations_bryo()
CREATE OR REPLACE FUNCTION bryophytes.update_synthese_stations_bryo()
  RETURNS trigger AS
$BODY$
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
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;


-- Function: bryophytes.insert_synthese_cor_bryo_taxon()
CREATE OR REPLACE FUNCTION bryophytes.insert_synthese_cor_bryo_taxon()
  RETURNS trigger AS
$BODY$
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
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

----------------------------------------------
--CONTACT FAUNE-------------------------------
----------------------------------------------

ALTER TABLE contactfaune.t_fiches_cf RENAME the_geom_2154  TO the_geom_local;
ALTER TABLE contactfaune.t_fiches_cf DROP CONSTRAINT enforce_srid_the_geom_2154;
ALTER TABLE contactfaune.t_fiches_cf ADD CONSTRAINT enforce_srid_the_geom_local CHECK (st_srid(the_geom_local) = 2154);
ALTER TABLE contactfaune.t_fiches_cf DROP CONSTRAINT enforce_geotype_the_geom_2154;
ALTER TABLE contactfaune.t_fiches_cf ADD CONSTRAINT enforce_geotype_the_geom_local CHECK (geometrytype(the_geom_local) = 'POINT'::text OR the_geom_local IS NULL);
ALTER TABLE contactfaune.t_fiches_cf DROP CONSTRAINT enforce_dims_the_geom_2154;
ALTER TABLE contactfaune.t_fiches_cf ADD CONSTRAINT enforce_dims_the_geom_local CHECK (st_ndims(the_geom_local) = 2);

-- Function: contactfaune.insert_fiche_cf()
CREATE OR REPLACE FUNCTION contactfaune.insert_fiche_cf()
  RETURNS trigger AS
$BODY$
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
    new.the_geom_3857 = public.st_transform(new.the_geom_local,3857);
  ELSIF new.saisie_initiale = 'web' THEN
    new.srid_dessin = 3857;
    -- attention : pas de creation des geom locaux car c'est fait par l'application web
  ELSIF new.saisie_initiale ISNULL THEN
    new.srid_dessin = 0;
    -- pas d'info sur le srid utilisé, cas des importations à gérer manuellement. Ne devrait pas exister.
  END IF;
-------gestion des divers control avec attributions des secteurs + communes : dans le cas d'un insert depuis le nomade uniquement via the_geom !!!!
  IF st_isvalid(new.the_geom_local) = true THEN  -- si la topologie est bonne alors...
    -- on calcul la commune
    SELECT INTO macommune c.insee FROM layers.l_communes c WHERE public.st_intersects(c.the_geom, new.the_geom_local);
    new.insee = macommune;
    -- on calcul l'altitude
    new.altitude_sig = layers.f_isolines20(new.the_geom_local); -- mise à jour de l'altitude sig
    IF new.altitude_saisie IS null OR new.altitude_saisie = -1 THEN-- mis à jour de l'altitude retenue
        new.altitude_retenue = new.altitude_sig;
    ELSE
        new.altitude_retenue = new.altitude_saisie;
    END IF;
  ELSE          
    SELECT INTO macommune c.insee FROM layers.l_communes c WHERE public.st_intersects(c.the_geom, public.ST_PointFromWKB(public.st_centroid(Box2D(new.the_geom_local)),2154));
    new.insee = macommune;
    -- on calcul l'altitude
    new.altitude_sig = layers.f_isolines20(public.ST_PointFromWKB(public.st_centroid(Box2D(new.the_geom_local)),2154)); -- mise à jour de l'altitude sig
    IF new.altitude_saisie IS null OR new.altitude_saisie = -1 THEN-- mis à jour de l'altitude retenue
      new.altitude_retenue = new.altitude_sig;
    ELSE
      new.altitude_retenue = new.altitude_saisie;
    END IF;
  END IF;
  RETURN NEW;       
END IF;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;


-- Function: contactfaune.insert_releve_cf()
CREATE OR REPLACE FUNCTION contactfaune.insert_releve_cf()
  RETURNS trigger AS
$BODY$
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
  SELECT INTO unite u.id_unite_geo FROM layers.l_unites_geo u WHERE public.st_intersects(fiche.the_geom_local,u.the_geom);
  --si on est dans une des unités on peut mettre à jour la table cor_unite_taxon, sinon on fait rien
  IF unite>0 THEN
    SELECT INTO line * FROM contactfaune.cor_unite_taxon WHERE id_unite_geo = unite AND id_nom = new.id_nom;
    --si la ligne existe dans cor_unite_taxon on la supprime
    IF line IS NOT NULL THEN
      DELETE FROM contactfaune.cor_unite_taxon WHERE id_unite_geo = unite AND id_nom = new.id_nom;
    END IF;
    --on compte le nombre d'enregistrement pour ce taxon dans l'unité
    SELECT INTO nbobs count(*) from synthese.syntheseff s
    JOIN layers.l_unites_geo u ON public.st_intersects(u.the_geom, s.the_geom_local) AND u.id_unite_geo = unite
    WHERE s.cd_nom = cdnom;
    --on créé ou recréé la ligne
    INSERT INTO contactfaune.cor_unite_taxon VALUES(unite,new.id_nom,fiche.dateobs,contactfaune.couleur_taxon(new.id_nom,fiche.dateobs), nbobs+1);
  END IF;
  RETURN NEW;       
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;


-- Function: contactfaune.synthese_insert_releve_cf()
CREATE OR REPLACE FUNCTION contactfaune.synthese_insert_releve_cf()
  RETURNS trigger AS
$BODY$
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
    the_geom_local,
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
  fiche.the_geom_local,
  fiche.the_geom_3857,
  fiche.id_lot,
  criteresynthese,
  new.am+new.af+new.ai+new.na+new.jeune+new.yearling+new.sai
  );
  RETURN NEW;       
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;


-- Function: contactfaune.synthese_update_fiche_cf()
CREATE OR REPLACE FUNCTION contactfaune.synthese_update_fiche_cf()
  RETURNS trigger AS
$BODY$
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
      IF NOT public.st_equals(new.the_geom_3857,old.the_geom_3857) OR NOT public.st_equals(new.the_geom_local,old.the_geom_local) THEN
        
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
        the_geom_local = new.the_geom_local,
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
        the_geom_local = new.the_geom_local,
        the_geom_point = new.the_geom_3857,
        id_lot = new.id_lot
          WHERE id_fiche_source = releves.id_releve_cf::text AND (id_source = idsourcecf OR id_source = idsourcem);
      END IF;
    END IF;
  END LOOP;
  RETURN NEW;       
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;


-- Function: contactfaune.update_fiche_cf()
CREATE OR REPLACE FUNCTION contactfaune.update_fiche_cf()
  RETURNS trigger AS
$BODY$
DECLARE
  macommune character(5);
  nbreleves integer;
BEGIN
-------------------------- gestion des infos relatives a la numerisation (srid utilisé et support utilisé : pda ou web ou sig)
-------------------------- attention la saisie sur le web réalise un insert sur qq données mais the_geom_3857 est "faussement inséré" par un update !!!
IF (NOT public.st_equals(new.the_geom_local,old.the_geom_local) OR (old.the_geom_local is null AND new.the_geom_local is NOT NULL))
  OR (NOT public.st_equals(new.the_geom_3857,old.the_geom_3857) OR (old.the_geom_3857 is null AND new.the_geom_3857 is NOT NULL)) 
   THEN
  IF NOT public.st_equals(new.the_geom_3857,old.the_geom_3857) OR (old.the_geom_3857 is null AND new.the_geom_3857 is NOT NULL) THEN
    new.the_geom_local = public.st_transform(new.the_geom_3857,2154);
    new.srid_dessin = 3857;
  ELSIF NOT public.st_equals(new.the_geom_local,old.the_geom_local) OR (old.the_geom_local is null AND new.the_geom_local is NOT NULL) THEN
    new.the_geom_3857 = public.st_transform(new.the_geom_local,3857);
    new.srid_dessin = 2154;
  END IF;
-------gestion des divers control avec attributions de la commune : dans le cas d'un insert depuis le nomade uniquement via the_geom_local !!!!
  IF st_isvalid(new.the_geom_local) = true THEN  -- si la topologie est bonne alors...
    -- on calcul la commune (celle qui contient le plus de zp en surface)...
    SELECT INTO macommune c.insee FROM layers.l_communes c WHERE public.st_intersects(c.the_geom, new.the_geom_local);
    new.insee = macommune;
    -- on calcul l'altitude
    new.altitude_sig = layers.f_isolines20(new.the_geom_local); -- mise à jour de l'altitude sig
    IF new.altitude_saisie IS null OR new.altitude_saisie = -1 THEN-- mis à jour de l'altitude retenue
        new.altitude_retenue = new.altitude_sig;
    ELSE
        new.altitude_retenue = new.altitude_saisie;
    END IF;
  ELSE          
    SELECT INTO macommune c.insee FROM layers.l_communes c WHERE public.st_intersects(c.the_geom, public.ST_PointFromWKB(public.st_centroid(Box2D(new.the_geom_local)),2154));
    new.insee = macommune;
    -- on calcul l'altitude
    new.altitude_sig = layers.f_isolines20(public.ST_PointFromWKB(public.st_centroid(Box2D(new.the_geom_local)),2154)); -- mise à jour de l'altitude sig
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
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;


----------------------------------------------
--CONTACT FLORE-------------------------------
----------------------------------------------

ALTER TABLE contactflore.t_fiches_cflore RENAME the_geom_2154  TO the_geom_local;
ALTER TABLE contactflore.t_fiches_cflore DROP CONSTRAINT enforce_srid_the_geom_2154;
ALTER TABLE contactflore.t_fiches_cflore ADD CONSTRAINT enforce_srid_the_geom_local CHECK (st_srid(the_geom_local) = 2154);
ALTER TABLE contactflore.t_fiches_cflore DROP CONSTRAINT enforce_geotype_the_geom_2154;
ALTER TABLE contactflore.t_fiches_cflore ADD CONSTRAINT enforce_geotype_the_geom_local CHECK (geometrytype(the_geom_local) = 'POINT'::text OR the_geom_local IS NULL);
ALTER TABLE contactflore.t_fiches_cflore DROP CONSTRAINT enforce_dims_the_geom_2154;
ALTER TABLE contactflore.t_fiches_cflore ADD CONSTRAINT enforce_dims_the_geom_local CHECK (st_ndims(the_geom_local) = 2);


-- Function: contactflore.insert_fiche_cflore()
CREATE OR REPLACE FUNCTION contactflore.insert_fiche_cflore()
  RETURNS trigger AS
$BODY$
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
    new.the_geom_3857 = st_transform(new.the_geom_local,3857);
  ELSIF new.saisie_initiale = 'web' THEN
    new.srid_dessin = 3857;
    -- attention : pas de creation des geom locaux car c'est fait par l'application web
  ELSIF new.saisie_initiale ISNULL THEN
    new.srid_dessin = 0;
    -- pas d'info sur le srid utilisé, cas des importations à gérer manuellement. Ne devrait pas exister.
  END IF;
-------gestion des divers control avec attributions des secteurs + communes : dans le cas d'un insert depuis le nomade uniquement via the_geom !!!!
  IF st_isvalid(new.the_geom_local) = true THEN  -- si la topologie est bonne alors...
    -- on calcul la commune
    SELECT INTO macommune c.insee FROM layers.l_communes c WHERE st_intersects(c.the_geom, new.the_geom_local);
    new.insee = macommune;
    -- on calcul l'altitude
    new.altitude_sig = layers.f_isolines20(new.the_geom_local); -- mise à jour de l'altitude sig
    IF new.altitude_saisie IS null OR new.altitude_saisie = -1 THEN-- mis à jour de l'altitude retenue
        new.altitude_retenue = new.altitude_sig;
    ELSE
        new.altitude_retenue = new.altitude_saisie;
    END IF;
  ELSE          
    SELECT INTO macommune c.insee FROM layers.l_communes c WHERE st_intersects(c.the_geom, ST_PointFromWKB(st_centroid(Box2D(new.the_geom_local)),2154));
    new.insee = macommune;
    -- on calcul l'altitude
    new.altitude_sig = layers.f_isolines20(ST_PointFromWKB(st_centroid(Box2D(new.the_geom_local)),2154)); -- mise à jour de l'altitude sig
    IF new.altitude_saisie IS null OR new.altitude_saisie = -1 THEN-- mis à jour de l'altitude retenue
      new.altitude_retenue = new.altitude_sig;
    ELSE
      new.altitude_retenue = new.altitude_saisie;
    END IF;
  END IF;
  RETURN NEW;       
END IF;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;


-- Function: contactflore.insert_releve_cflore()
CREATE OR REPLACE FUNCTION contactflore.insert_releve_cflore()
  RETURNS trigger AS
$BODY$
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
  SELECT INTO unite u.id_unite_geo FROM layers.l_unites_geo u WHERE ST_INTERSECTS(fiche.the_geom_local,u.the_geom);
  --si on est dans une des unités on peut mettre à jour la table cor_unite_taxon_cflore, sinon on fait rien
  IF unite>0 THEN
    SELECT INTO line * FROM contactflore.cor_unite_taxon_cflore WHERE id_unite_geo = unite AND id_nom = new.id_nom;
    --si la ligne existe dans cor_unite_taxon_cflore on la supprime
    IF line IS NOT NULL THEN
      DELETE FROM contactflore.cor_unite_taxon_cflore WHERE id_unite_geo = unite AND id_nom = new.id_nom;
    END IF;
    --on compte le nombre d'enregistrement pour ce taxon dans l'unité
    SELECT INTO nbobs count(*) from synthese.syntheseff s
    JOIN layers.l_unites_geo u ON ST_Intersects(u.the_geom, s.the_geom_local) AND u.id_unite_geo = unite
    WHERE s.cd_nom = cdnom;
    --on créé ou recréé la ligne
    INSERT INTO contactflore.cor_unite_taxon_cflore VALUES(unite,new.id_nom,fiche.dateobs,contactflore.couleur_taxon(new.id_nom,fiche.dateobs), nbobs+1);
  END IF;
  RETURN NEW;       
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;


-- Function: contactflore.synthese_insert_releve_cflore()
CREATE OR REPLACE FUNCTION contactflore.synthese_insert_releve_cflore()
  RETURNS trigger AS
$BODY$
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
    the_geom_local,
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
  fiche.the_geom_local,
  fiche.the_geom_3857,
  fiche.id_lot
  );
  RETURN NEW;       
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;


-- Function: contactflore.synthese_update_fiche_cflore()
CREATE OR REPLACE FUNCTION contactflore.synthese_update_fiche_cflore()
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
      IF NOT St_Equals(new.the_geom_3857,old.the_geom_3857) OR NOT St_Equals(new.the_geom_local,old.the_geom_local) THEN
        
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
        the_geom_local = new.the_geom_local,
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
        the_geom_local = new.the_geom_local,
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


-- Function: contactflore.update_fiche_cflore()
CREATE OR REPLACE FUNCTION contactflore.update_fiche_cflore()
  RETURNS trigger AS
$BODY$
DECLARE
macommune character(5);
BEGIN
-------------------------- gestion des infos relatives a la numerisation (srid utilisé et support utilisé : pda ou web ou sig)
-------------------------- attention la saisie sur le web réalise un insert sur qq données mais the_geom_3857 est "faussement inséré" par un update !!!
IF (NOT ST_Equals(new.the_geom_local,old.the_geom_local) OR (old.the_geom_local is null AND new.the_geom_local is NOT NULL))
  OR (NOT ST_Equals(new.the_geom_3857,old.the_geom_3857) OR (old.the_geom_3857 is null AND new.the_geom_3857 is NOT NULL)) 
   THEN
  IF NOT ST_Equals(new.the_geom_3857,old.the_geom_3857) OR (old.the_geom_3857 is null AND new.the_geom_3857 is NOT NULL) THEN
    new.the_geom_local = st_transform(new.the_geom_3857,2154);
    new.srid_dessin = 3857;
  ELSIF NOT ST_Equals(new.the_geom_local,old.the_geom_local) OR (old.the_geom_local is null AND new.the_geom_local is NOT NULL) THEN
    new.the_geom_3857 = st_transform(new.the_geom_local,3857);
    new.srid_dessin = 2154;
  END IF;
-------gestion des divers control avec attributions de la commune : dans le cas d'un insert depuis le nomade uniquement via the_geom_local !!!!
  IF st_isvalid(new.the_geom_local) = true THEN  -- si la topologie est bonne alors...
    -- on calcul la commune (celle qui contient le plus de zp en surface)...
    SELECT INTO macommune c.insee FROM layers.l_communes c WHERE st_intersects(c.the_geom, new.the_geom_local);
    new.insee = macommune;
    -- on calcul l'altitude
    new.altitude_sig = layers.f_isolines20(new.the_geom_local); -- mise à jour de l'altitude sig
    IF new.altitude_saisie IS null OR new.altitude_saisie = -1 THEN-- mis à jour de l'altitude retenue
        new.altitude_retenue = new.altitude_sig;
    ELSE
        new.altitude_retenue = new.altitude_saisie;
    END IF;
  ELSE          
    SELECT INTO macommune c.insee FROM layers.l_communes c WHERE st_intersects(c.the_geom, ST_PointFromWKB(st_centroid(Box2D(new.the_geom_local)),2154));
    new.insee = macommune;
    -- on calcul l'altitude
    new.altitude_sig = layers.f_isolines20(ST_PointFromWKB(st_centroid(Box2D(new.the_geom_local)),2154)); -- mise à jour de l'altitude sig
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
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;


----------------------------------------------
--CONTACT INVERTEBRES-------------------------------
----------------------------------------------

ALTER TABLE contactinv.t_fiches_inv RENAME the_geom_2154  TO the_geom_local;
ALTER TABLE contactinv.t_fiches_inv DROP CONSTRAINT enforce_srid_the_geom_2154;
ALTER TABLE contactinv.t_fiches_inv ADD CONSTRAINT enforce_srid_the_geom_local CHECK (st_srid(the_geom_local) = 2154);
ALTER TABLE contactinv.t_fiches_inv DROP CONSTRAINT enforce_geotype_the_geom_2154;
ALTER TABLE contactinv.t_fiches_inv ADD CONSTRAINT enforce_geotype_the_geom_local CHECK (geometrytype(the_geom_local) = 'POINT'::text OR the_geom_local IS NULL);
ALTER TABLE contactinv.t_fiches_inv DROP CONSTRAINT enforce_dims_the_geom_2154;
ALTER TABLE contactinv.t_fiches_inv ADD CONSTRAINT enforce_dims_the_geom_local CHECK (st_ndims(the_geom_local) = 2);


-- Function: contactinv.insert_fiche_inv()
CREATE OR REPLACE FUNCTION contactinv.insert_fiche_inv()
  RETURNS trigger AS
$BODY$
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
    new.the_geom_3857 = public.st_transform(new.the_geom_local,3857);
  ELSIF new.saisie_initiale = 'web' THEN
    new.srid_dessin = 3857;
    -- attention : pas de creation du geom local car c'est fait par l'application web
  ELSIF new.saisie_initiale ISNULL THEN
    new.srid_dessin = 0;
    -- pas d'info sur le srid utilisé, cas des importations à gérer manuellement. Ne devrait pas exister.
  END IF;
-------gestion des divers control avec attributions des secteurs + communes : dans le cas d'un insert depuis le nomade uniquement via the_geom !!!!
  IF st_isvalid(new.the_geom_local) = true THEN  -- si la topologie est bonne alors...
    -- on calcul la commune (celle qui contient le plus de zp en surface)...
    SELECT INTO macommune c.insee FROM layers.l_communes c WHERE public.st_intersects(c.the_geom, new.the_geom_local);
    new.insee = macommune;
    -- on calcul l'altitude
    new.altitude_sig = layers.f_isolines20(new.the_geom_local); -- mise à jour de l'altitude sig
    IF new.altitude_saisie IS null OR new.altitude_saisie = -1 THEN-- mis à jour de l'altitude retenue
        new.altitude_retenue = new.altitude_sig;
    ELSE
        new.altitude_retenue = new.altitude_saisie;
    END IF;
  ELSE          
    SELECT INTO macommune c.insee FROM layers.l_communes c WHERE public.st_intersects(c.the_geom, public.ST_PointFromWKB(public.st_centroid(Box2D(new.the_geom_local)),2154));
    new.insee = macommune;
    -- on calcul l'altitude
    new.altitude_sig = layers.f_isolines20(public.ST_PointFromWKB(public.st_centroid(Box2D(new.the_geom_local)),2154)); -- mise à jour de l'altitude sig
    IF new.altitude_saisie IS null OR new.altitude_saisie = -1 THEN-- mis à jour de l'altitude retenue
      new.altitude_retenue = new.altitude_sig;
    ELSE
      new.altitude_retenue = new.altitude_saisie;
    END IF;
  END IF;
  RETURN NEW;       
END IF;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;


-- Function: contactinv.insert_releve_inv()
CREATE OR REPLACE FUNCTION contactinv.insert_releve_inv()
  RETURNS trigger AS
$BODY$
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
  SELECT INTO unite u.id_unite_geo FROM layers.l_unites_geo u WHERE public.st_intersects(fiche.the_geom_local,u.the_geom);
  --si on est dans une des unités on peut mettre à jour la table cor_unite_taxon_inv, sinon on fait rien
  IF unite>0 THEN
    SELECT INTO line * FROM contactinv.cor_unite_taxon_inv WHERE id_unite_geo = unite AND id_nom = new.id_nom;
    --si la ligne existe dans cor_unite_taxon_inv on la supprime
    IF line IS NOT NULL THEN
      DELETE FROM contactinv.cor_unite_taxon_inv WHERE id_unite_geo = unite AND id_nom = new.id_nom;
    END IF;
    --on compte le nombre d'enregistrement pour ce taxon dans l'unité
    SELECT INTO nbobs count(*) from synthese.syntheseff s
    JOIN layers.l_unites_geo u ON public.st_intersects(u.the_geom, s.the_geom_local) AND u.id_unite_geo = unite
    WHERE s.cd_nom = cdnom;
    --on créé ou recréé la ligne
    INSERT INTO contactinv.cor_unite_taxon_inv VALUES(unite,new.id_nom,fiche.dateobs,contactinv.couleur_taxon(new.id_nom,fiche.dateobs), nbobs+1);
  END IF;
  RETURN NEW;       
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;


-- Function: contactinv.synthese_insert_releve_inv()
CREATE OR REPLACE FUNCTION contactinv.synthese_insert_releve_inv()
  RETURNS trigger AS
$BODY$
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
    the_geom_local,
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
  fiche.the_geom_local,
  fiche.the_geom_3857,
  fiche.id_lot,
  criteresynthese,
  new.am+new.af+new.ai+new.na
  );
  RETURN NEW;       
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;


-- Function: contactinv.synthese_update_fiche_inv()
CREATE OR REPLACE FUNCTION contactinv.synthese_update_fiche_inv()
  RETURNS trigger AS
$BODY$
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
            
      IF NOT public.st_equals(new.the_geom_3857,old.the_geom_3857) OR NOT public.st_equals(new.the_geom_local,old.the_geom_local) THEN
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
          the_geom_local = new.the_geom_local,
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
          the_geom_local = new.the_geom_local,
          the_geom_point = new.the_geom_3857,
          id_lot = new.id_lot
        WHERE id_source = idsource AND id_fiche_source = releves.id_releve_inv::text;
      END IF;
    END IF;
  END LOOP;
  RETURN NEW;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;


-- Function: contactinv.update_fiche_inv()
CREATE OR REPLACE FUNCTION contactinv.update_fiche_inv()
  RETURNS trigger AS
$BODY$
DECLARE
  macommune character(5);
  nbreleves integer;
BEGIN
-------------------------- gestion des infos relatives a la numerisation (srid utilisé et support utilisé : pda ou web ou sig)
-------------------------- attention la saisie sur le web réalise un insert sur qq données mais the_geom_3857 est "faussement inséré" par un update !!!
IF (NOT public.st_equals(new.the_geom_local,old.the_geom_local) OR (old.the_geom_local is null AND new.the_geom_local is NOT NULL))
  OR (NOT public.st_equals(new.the_geom_3857,old.the_geom_3857) OR (old.the_geom_3857 is null AND new.the_geom_3857 is NOT NULL)) 
   THEN
  IF NOT public.st_equals(new.the_geom_3857,old.the_geom_3857) OR (old.the_geom_3857 is null AND new.the_geom_3857 is NOT NULL) THEN
    new.the_geom_local = public.st_transform(new.the_geom_3857,2154);
    new.srid_dessin = 3857;
  ELSIF NOT public.st_equals(new.the_geom_local,old.the_geom_local) OR (old.the_geom_local is null AND new.the_geom_local is NOT NULL) THEN
    new.the_geom_3857 = public.st_transform(new.the_geom_local,3857);
    new.srid_dessin = 2154;
  END IF;
-------gestion des divers control avec attributions de la commune : dans le cas d'un insert depuis le nomade uniquement via the_geom_local !!!!
  IF st_isvalid(new.the_geom_local) = true THEN  -- si la topologie est bonne alors...
    -- on calcul la commune (celle qui contient le plus de zp en surface)...
    SELECT INTO macommune c.insee FROM layers.l_communes c WHERE public.st_intersects(c.the_geom, new.the_geom_local);
    new.insee = macommune;
    -- on calcul l'altitude
    new.altitude_sig = layers.f_isolines20(new.the_geom_local); -- mise à jour de l'altitude sig
    IF new.altitude_saisie IS null OR new.altitude_saisie = -1 THEN-- mis à jour de l'altitude retenue
        new.altitude_retenue = new.altitude_sig;
    ELSE
        new.altitude_retenue = new.altitude_saisie;
    END IF;
  ELSE          
    SELECT INTO macommune c.insee FROM layers.l_communes c WHERE public.st_intersects(c.the_geom, public.ST_PointFromWKB(public.st_centroid(Box2D(new.the_geom_local)),2154));
    new.insee = macommune;
    -- on calcul l'altitude
    new.altitude_sig = layers.f_isolines20(public.ST_PointFromWKB(public.st_centroid(Box2D(new.the_geom_local)),2154)); -- mise à jour de l'altitude sig
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
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;


----------------------------------------------
--FLORE PATRIMONIALE-------------------------------
----------------------------------------------

ALTER TABLE florepatri.t_apresence RENAME the_geom_2154  TO the_geom_local;
ALTER TABLE florepatri.t_apresence DROP CONSTRAINT enforce_srid_the_geom_2154;
ALTER TABLE florepatri.t_apresence ADD CONSTRAINT enforce_srid_the_geom_local CHECK (st_srid(the_geom_local) = 2154);
ALTER TABLE florepatri.t_apresence DROP CONSTRAINT enforce_dims_the_geom_2154;
ALTER TABLE florepatri.t_apresence ADD CONSTRAINT enforce_dims_the_geom_local CHECK (st_ndims(the_geom_local) = 2);

ALTER TABLE florepatri.t_zprospection RENAME the_geom_2154  TO the_geom_local;
ALTER TABLE florepatri.t_zprospection DROP CONSTRAINT enforce_geotype_the_geom_2154;
ALTER TABLE florepatri.t_zprospection ADD CONSTRAINT enforce_geotype_the_geom_2154 CHECK (geometrytype(the_geom_local) = 'POLYGON'::text OR the_geom_local IS NULL);
ALTER TABLE florepatri.t_zprospection DROP CONSTRAINT enforce_srid_the_geom_2154;
ALTER TABLE florepatri.t_zprospection ADD CONSTRAINT enforce_srid_the_geom_local CHECK (st_srid(the_geom_local) = 2154);
ALTER TABLE florepatri.t_zprospection DROP CONSTRAINT enforce_dims_the_geom_2154;
ALTER TABLE florepatri.t_zprospection ADD CONSTRAINT enforce_dims_the_geom_local CHECK (st_ndims(the_geom_local) = 2);


-- Function: florepatri.insert_ap()
CREATE OR REPLACE FUNCTION florepatri.insert_ap()
  RETURNS trigger AS
$BODY$
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
    new.the_geom_local = public.st_transform(new.the_geom_3857,2154);
  ELSIF new.the_geom_local IS NOT NULL THEN  -- saisie avec outil nomade android avec the_geom_local
    new.the_geom_3857 = public.st_transform(new.the_geom_local,3857);
  END IF;
------ calcul de validité sur la base d'un double control (sur les deux polygones même si on a un seul champ topo_valid)
------ puis gestion des croisements SIG avec les layers altitude et communes en projection Lambert93
  IF ST_isvalid(new.the_geom_local) AND ST_isvalid(new.the_geom_3857) THEN
    new.topo_valid = 'true';
    new.insee = layers.f_insee(new.the_geom_local);-- mise a jour du code insee avec la fonction f_insee
    new.altitude_sig = layers.f_isolines20(new.the_geom_local); -- mise à jour de l'altitude sig avec la fonction f_isolines20
    IF new.altitude_saisie IS NULL OR new.altitude_saisie = 0 THEN-- mis à jour de l'altitude retenue
      new.altitude_retenue = new.altitude_sig;
    ELSE
      new.altitude_retenue = new.altitude_saisie;
    END IF;
  ELSE
    new.topo_valid = 'false';
    moncentroide = ST_setsrid(public.st_centroid(Box2D(new.the_geom_local)),2154); -- calcul le centroid de la bbox pour les croisements SIG
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
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;


-- Function: florepatri.insert_synthese_ap()
CREATE OR REPLACE FUNCTION florepatri.insert_synthese_ap()
  RETURNS trigger AS
$BODY$
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
        the_geom_local,
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
        new.the_geom_local,
        mongeompoint);
  RETURN NEW;       
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;


-- Function: florepatri.insert_zp()
CREATE OR REPLACE FUNCTION florepatri.insert_zp()
  RETURNS trigger AS
$BODY$
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
    new.the_geom_3857 = public.st_transform(new.the_geom_local,3857);
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
    IF ST_isvalid(new.the_geom_local) AND ST_isvalid(new.the_geom_3857) THEN
      new.topo_valid = 'true';
      -- calcul du geom_point_3857 
      new.geom_point_3857 = ST_pointonsurface(new.the_geom_3857);  -- calcul du point pour le premier niveau de zoom appli web
      -- croisement secteur (celui qui contient le plus de zp en surface)
      SELECT INTO monsectfp ls.id_secteur FROM layers.l_secteurs ls WHERE public.st_intersects(ls.the_geom, new.the_geom_local)
      ORDER BY public.ST_area(public.ST_intersection(ls.the_geom, new.the_geom_local)) DESC LIMIT 1;
      -- croisement commune (celle qui contient le plus de zp en surface)
      SELECT INTO macommune lc.insee FROM layers.l_communes lc WHERE public.st_intersects(lc.the_geom, new.the_geom_local)
      ORDER BY public.ST_area(public.ST_intersection(lc.the_geom, new.the_geom_local)) DESC LIMIT 1;
    ELSE
      new.topo_valid = 'false';
      -- calcul du geom_point_3857
      new.geom_point_3857 = ST_setsrid(public.st_centroid(Box2D(new.the_geom_3857)),3857);  -- calcul le centroid de la bbox pour premier niveau de zoom appli web
      moncentroide = ST_setsrid(public.st_centroid(Box2D(new.the_geom_local)),2154); -- calcul le centroid de la bbox pour les croisements SIG
      -- croisement secteur (celui qui contient moncentroide)
      SELECT INTO monsectfp ls.id_secteur FROM layers.l_secteurs ls WHERE public.st_intersects(ls.the_geom, moncentroide);
      -- croisement commune (celle qui contient moncentroid)
      SELECT INTO macommune lc.insee FROM layers.l_communes lc WHERE public.st_intersects(lc.the_geom, moncentroide);
    END IF;
    new.insee = macommune;
    IF monsectfp IS NULL THEN     -- suite calcul secteur : si la requete sql renvoit null (cad pas d'intersection donc dessin hors zone)
      new.id_secteur = 999; -- alors on met 999 (hors zone) en code secteur fp
    ELSE
      new.id_secteur = monsectfp; --sinon on met le code du secteur.
    END IF;
    ------ calcul du geom_mixte_3857
    IF public.ST_area(new.the_geom_3857) <10000 THEN     -- calcul du point (ou de la surface si > 1 hectare) pour le second niveau de zoom appli web
      new.geom_mixte_3857 = new.geom_point_3857;
    ELSE
      new.geom_mixte_3857 = new.the_geom_3857;
    END IF;
    
  ------ fin de calcul
------  fin du ELSE et return des valeurs :
  RETURN NEW;
END IF;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;


-- Function: florepatri.update_ap()
CREATE OR REPLACE FUNCTION florepatri.update_ap()
  RETURNS trigger AS
$BODY$
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
    (NOT public.st_equals(new.the_geom_local,old.the_geom_local) OR (old.the_geom_local IS null AND new.the_geom_local IS NOT NULL))
    OR (NOT public.st_equals(new.the_geom_3857,old.the_geom_3857)OR (old.the_geom_3857 IS null AND new.the_geom_3857 IS NOT NULL)) 
THEN
    IF NOT public.st_equals(new.the_geom_3857,old.the_geom_3857) OR (old.the_geom_3857 IS null AND new.the_geom_3857 IS NOT NULL) THEN
    new.the_geom_local = public.st_transform(new.the_geom_3857,2154);
  ELSIF NOT public.st_equals(new.the_geom_local,old.the_geom_local) OR (old.the_geom_local IS null AND new.the_geom_local IS NOT NULL) THEN
    new.the_geom_3857 = public.st_transform(new.the_geom_local,3857);
  END IF;
puis suite du THEN
fin de section en attente */ 
------------------------------------------------------------------------------------------------------
------ gestion des infos relatives aux géométries
------ ATTENTION : la saisie en web insert quelques données MAIS the_geom_3857 est "inséré" par une commande update !
------ POUR LE MOMENT gestion des update dans l'appli web uniquement à partir du geom 3857
IF ST_NumGeometries(new.the_geom_3857)=1 THEN -- si le Multi objet renvoyé par le oueb ne contient qu'un objet
  new.the_geom_3857 = ST_GeometryN(new.the_geom_3857, 1); -- alors on passe en objet simple ( multi vers single)
END IF;
new.the_geom_local = public.st_transform(new.the_geom_3857,2154);
------ calcul de validité sur la base d'un double control (sur les deux polygones même si on a un seul champ topo_valid)
------ puis gestion des croisements SIG avec les layers altitude et communes en projection Lambert93
IF ST_isvalid(new.the_geom_local) AND ST_isvalid(new.the_geom_3857) THEN
  new.topo_valid = 'true';
  new.insee = layers.f_insee(new.the_geom_local);        -- mise a jour du code insee avec la fonction f_insee
  new.altitude_sig = layers.f_isolines20(new.the_geom_local);    -- mise à jour de l'altitude sig avec la fonction f_isolines20
  IF new.altitude_saisie IS NULL OR new.altitude_saisie = 0 THEN  -- mise à jour de l'altitude retenue
    new.altitude_retenue = new.altitude_sig;
  ELSE
    new.altitude_retenue = new.altitude_saisie;
  END IF;
ELSE
  new.topo_valid = 'false';
  moncentroide = ST_setsrid(public.st_centroid(Box2D(new.the_geom_local)),2154); -- calcul le centroid de la bbox pour les croisements SIG
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
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;


-- Function: florepatri.update_synthese_ap()
CREATE OR REPLACE FUNCTION florepatri.update_synthese_ap()
  RETURNS trigger AS
$BODY$
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
        OR (NOT public.st_equals(new.the_geom_3857,old.the_geom_3857) OR NOT public.st_equals(new.the_geom_local,old.the_geom_local))
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
    the_geom_local = new.the_geom_local,
    the_geom_point = mongeompoint
  WHERE id_source = 4 AND id_fiche_source = CAST(old.indexap AS VARCHAR(25));
END IF;
RETURN NEW;       
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;


-- Function: florepatri.update_zp()
CREATE OR REPLACE FUNCTION florepatri.update_zp()
  RETURNS trigger AS
$BODY$
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
OR ((old.the_geom_local is null AND new.the_geom_local is NOT NULL) OR NOT public.st_equals(new.the_geom_local,old.the_geom_local)) THEN

-- si oui on regarde lequel et on repercute les modif :
  IF (old.the_geom_3857 is null AND new.the_geom_3857 is NOT NULL) OR NOT public.st_equals(new.the_geom_3857,old.the_geom_3857) THEN
    -- verif si on est en multipolygon ou pas : A FAIRE !!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    new.the_geom_local = public.st_transform(new.the_geom_3857,2154);
    new.srid_dessin = 3857; 
  ELSIF (old.the_geom_local is null AND new.the_geom_local is NOT NULL) OR NOT public.st_equals(new.the_geom_local,old.the_geom_local) THEN
    new.the_geom_3857 = public.st_transform(new.the_geom_local,3857);
    new.srid_dessin = 2154;
  END IF;
puis suite du THEN...
fin de section en attente */ 
------------------------------------------------------------------------------------------------------
------ gestion des infos relatives aux géométries
------ ATTENTION : la saisie en web insert quelques données MAIS the_geom_3857 est "faussement inséré" par une commande update !
------ POUR LE MOMENT gestion des update dans l'appli web uniquement à partir du geom 3857
IF ST_NumGeometries(new.the_geom_3857)=1 THEN -- si le Multi objet renvoyé par le oueb ne contient qu'un objet
  new.the_geom_3857 = ST_GeometryN(new.the_geom_3857, 1); -- alors on passe en objet simple ( multi vers single)
END IF;

new.the_geom_local = public.st_transform(new.the_geom_3857,2154);
new.srid_dessin = 3857;

------ 2) puis on calcul la validité des geom + on refait les calcul du geom_point_3857 + on refait les croisements SIG secteurs + communes
------    c'est la même chose que lors d'un INSERT ( cf trigger insert_zp)
IF ST_isvalid(new.the_geom_local) AND ST_isvalid(new.the_geom_3857) THEN
  new.topo_valid = 'true';
  -- calcul du geom_point_3857 
  new.geom_point_3857 = ST_pointonsurface(new.the_geom_3857);  -- calcul du point pour le premier niveau de zoom appli web
  -- croisement secteur (celui qui contient le plus de zp en surface)
  SELECT INTO monsectfp ls.id_secteur FROM layers.l_secteurs ls WHERE public.st_intersects(ls.the_geom, new.the_geom_local)
  ORDER BY public.ST_area(public.ST_intersection(ls.the_geom, new.the_geom_local)) DESC LIMIT 1;
  -- croisement commune (celle qui contient le plus de zp en surface)
  SELECT INTO macommune lc.insee FROM layers.l_communes lc WHERE public.st_intersects(lc.the_geom, new.the_geom_local)
  ORDER BY public.ST_area(public.ST_intersection(lc.the_geom, new.the_geom_local)) DESC LIMIT 1;
ELSE
  new.topo_valid = 'false';
  -- calcul du geom_point_3857
  new.geom_point_3857 = ST_setsrid(public.st_centroid(Box2D(new.the_geom_3857)),3857);  -- calcul le centroid de la bbox pour premier niveau de zoom appli web
  moncentroide = ST_setsrid(public.st_centroid(Box2D(new.the_geom_local)),2154); -- calcul le centroid de la bbox pour les croisements SIG
  -- croisement secteur (celui qui contient moncentroide)
  SELECT INTO monsectfp ls.id_secteur FROM layers.l_secteurs ls WHERE public.st_intersects(ls.the_geom, moncentroide);
  -- croisement commune (celle qui contient moncentroid)
  SELECT INTO macommune lc.insee FROM layers.l_communes lc WHERE public.st_intersects(lc.the_geom, moncentroide);
  END IF;
  new.insee = macommune;
  IF monsectfp IS NULL THEN     -- suite calcul secteur : si la requete sql renvoit null (cad pas d'intersection donc dessin hors zone)
    new.id_secteur = 999; -- alors on met 999 (hors zone) en code secteur fp
  ELSE
    new.id_secteur = monsectfp; --sinon on met le code du secteur.
END IF;

------ 3) puis calcul du geom_mixte_3857
------    c'est la même chose que lors d'un INSERT ( cf trigger insert_zp)
IF public.ST_area(new.the_geom_3857) <10000 THEN     -- calcul du point (ou de la surface si > 1 hectare) pour le second niveau de zoom appli web
  new.geom_mixte_3857 = new.geom_point_3857;
ELSE
  new.geom_mixte_3857 = new.the_geom_3857;
END IF;
------  fin du IF pour les traitemenst sur les geometries

------  fin du trigger et return des valeurs :
  RETURN NEW;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;


DROP VIEW florepatri.v_ap_line;
DROP VIEW florepatri.v_ap_point;
DROP VIEW florepatri.v_ap_poly;
DROP VIEW florepatri.v_mobile_visu_zp;
DROP VIEW florepatri.v_nomade_ap;
DROP VIEW florepatri.v_nomade_zp;
DROP VIEW florepatri.v_touteslesap_2154_line;
DROP VIEW florepatri.v_touteslesap_2154_point;
DROP VIEW florepatri.v_touteslesap_2154_polygon;
DROP VIEW florepatri.v_toutesleszp_2154;


-- View: florepatri.v_ap_line
CREATE OR REPLACE VIEW florepatri.v_ap_line AS 
 SELECT a.indexap,
    a.indexzp,
    a.surfaceap AS surface,
    a.altitude_saisie AS altitude,
    a.id_frequence_methodo_new AS id_frequence_methodo,
    a.the_geom_local,
    a.frequenceap,
    a.topo_valid,
    a.date_update,
    a.supprime,
    a.date_insert
   FROM florepatri.t_apresence a
  WHERE geometrytype(a.the_geom_local) = 'MULTILINESTRING'::text OR geometrytype(a.the_geom_local) = 'LINESTRING'::text;


-- View: florepatri.v_ap_point
CREATE OR REPLACE VIEW florepatri.v_ap_point AS 
 SELECT a.indexap,
    a.indexzp,
    a.surfaceap AS surface,
    a.altitude_saisie AS altitude,
    a.id_frequence_methodo_new AS id_frequence_methodo,
    a.the_geom_local,
    a.frequenceap,
    a.topo_valid,
    a.date_update,
    a.supprime,
    a.date_insert
   FROM florepatri.t_apresence a
  WHERE geometrytype(a.the_geom_local) = 'POINT'::text OR geometrytype(a.the_geom_local) = 'MULTIPOINT'::text;


-- View: florepatri.v_ap_poly
CREATE OR REPLACE VIEW florepatri.v_ap_poly AS 
 SELECT a.indexap,
    a.indexzp,
    a.surfaceap AS surface,
    a.altitude_saisie AS altitude,
    a.id_frequence_methodo_new AS id_frequence_methodo,
    a.the_geom_local,
    a.frequenceap,
    a.topo_valid,
    a.date_update,
    a.supprime,
    a.date_insert
   FROM florepatri.t_apresence a
  WHERE geometrytype(a.the_geom_local) = 'POLYGON'::text OR geometrytype(a.the_geom_local) = 'MULTIPOLYGON'::text;


-- View: florepatri.v_mobile_visu_zp
CREATE OR REPLACE VIEW florepatri.v_mobile_visu_zp AS 
 SELECT t_zprospection.indexzp,
    t_zprospection.cd_nom,
    t_zprospection.the_geom_local
   FROM florepatri.t_zprospection
  WHERE date_part('year'::text, t_zprospection.dateobs) = date_part('year'::text, now());


-- View: florepatri.v_nomade_zp
CREATE OR REPLACE VIEW florepatri.v_nomade_zp AS 
 SELECT zp.indexzp,
    zp.cd_nom,
    vobs.codeobs,
    zp.dateobs,
    'Polygon'::character(7) AS montype,
    substr(st_asgml(zp.the_geom_local), strpos(st_asgml(zp.the_geom_local), '<gml:coordinates>'::text) + 17, strpos(st_asgml(zp.the_geom_local), '</gml:coordinates>'::text) - (strpos(st_asgml(zp.the_geom_local), '<gml:coordinates>'::text) + 17)) AS coordinates,
    vap.indexap,
    zp.id_secteur AS id_secteur_fp
   FROM florepatri.t_zprospection zp
     JOIN ( SELECT cor.indexzp,
            substr(array_agg(cor.codeobs)::text, 2, strpos(array_agg(cor.codeobs)::text, '}'::text) - 2) AS codeobs
           FROM ( SELECT aa.indexzp,
                    aa.codeobs
                   FROM florepatri.cor_zp_obs aa
                  WHERE aa.codeobs <> 247
                  ORDER BY aa.indexzp, aa.codeobs) cor
          GROUP BY cor.indexzp) vobs ON vobs.indexzp = zp.indexzp
     LEFT JOIN ( SELECT ap.indexzp,
            substr(array_agg(ap.indexap)::text, 2, strpos(array_agg(ap.indexap)::text, '}'::text) - 2) AS indexap
           FROM ( SELECT aa.indexzp,
                    aa.indexap
                   FROM florepatri.t_apresence aa
                  WHERE aa.supprime = false
                  ORDER BY aa.indexzp, aa.indexap) ap
          GROUP BY ap.indexzp) vap ON vap.indexzp = zp.indexzp
  WHERE zp.topo_valid = true AND zp.supprime = false AND zp.id_secteur < 9 AND zp.dateobs > '2010-01-01'::date AND (zp.cd_nom IN ( SELECT v_nomade_taxon.cd_nom
           FROM florepatri.v_nomade_taxon))
  ORDER BY zp.indexzp;


-- View: florepatri.v_nomade_ap
CREATE OR REPLACE VIEW florepatri.v_nomade_ap AS 
 SELECT ap.indexap,
    ap.codepheno,
    florepatri.letypedegeom(ap.the_geom_local) AS montype,
    substr(st_asgml(ap.the_geom_local), strpos(st_asgml(ap.the_geom_local), '<gml:coordinates>'::text) + 17, strpos(st_asgml(ap.the_geom_local), '</gml:coordinates>'::text) - (strpos(st_asgml(ap.the_geom_local), '<gml:coordinates>'::text) + 17)) AS coordinates,
    ap.surfaceap,
    (ap.id_frequence_methodo_new::text || ';'::text) || ap.frequenceap::integer AS frequence,
    vper.codeper,
    (('TF;'::text || ap.total_fertiles::character(1)::text) || ',RS;'::text) || ap.total_steriles::character(1)::text AS denombrement,
    zp.id_secteur_fp
   FROM florepatri.t_apresence ap
     JOIN florepatri.v_nomade_zp zp ON ap.indexzp = zp.indexzp
     LEFT JOIN ( SELECT ab.indexap,
            substr(array_agg(ab.codeper)::text, 2, strpos(array_agg(ab.codeper)::text, '}'::text) - 2) AS codeper
           FROM ( SELECT aa.indexap,
                    aa.codeper
                   FROM florepatri.cor_ap_perturb aa
                  ORDER BY aa.indexap, aa.codeper) ab
          GROUP BY ab.indexap) vper ON vper.indexap = ap.indexap
  WHERE ap.supprime = false
  ORDER BY ap.indexap;


-- View: florepatri.v_touteslesap_2154_line
CREATE OR REPLACE VIEW florepatri.v_touteslesap_sridlocal_line AS 
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
    ap.the_geom_local,
    ap.topo_valid AS ap_topo_valid,
    zp.validation AS relue,
    ap.remarques
   FROM florepatri.t_apresence ap
     JOIN florepatri.t_zprospection zp ON ap.indexzp = zp.indexzp
     JOIN florepatri.bib_taxons_fp t ON t.cd_nom = zp.cd_nom
     JOIN layers.l_secteurs s ON s.id_secteur = zp.id_secteur
     JOIN florepatri.bib_phenologies p ON p.codepheno = ap.codepheno
     JOIN layers.l_communes com ON com.insee = ap.insee
     JOIN florepatri.bib_frequences_methodo_new f ON f.id_frequence_methodo_new = ap.id_frequence_methodo_new
     JOIN florepatri.bib_comptages_methodo compt ON compt.id_comptage_methodo = ap.id_comptage_methodo
     JOIN ( SELECT c.indexzp,
            array_to_string(array_agg((r.prenom_role::text || ' '::text) || r.nom_role::text), ', '::text) AS observateurs
           FROM florepatri.cor_zp_obs c
             JOIN utilisateurs.t_roles r ON r.id_role = c.codeobs
          GROUP BY c.indexzp) o ON o.indexzp = ap.indexzp
     LEFT JOIN ( SELECT c.indexap,
            array_to_string(array_agg(((per_1.description::text || ' ('::text) || per_1.classification::text) || ')'::text), ', '::text) AS perturbations
           FROM florepatri.cor_ap_perturb c
             JOIN florepatri.bib_perturbations per_1 ON per_1.codeper = c.codeper
          GROUP BY c.indexap) per ON per.indexap = ap.indexap
     LEFT JOIN ( SELECT p_1.indexap,
            array_to_string(array_agg(((phy_1.nom_physionomie::text || ' ('::text) || phy_1.groupe_physionomie::text) || ')'::text), ', '::text) AS physionomies
           FROM florepatri.cor_ap_physionomie p_1
             JOIN florepatri.bib_physionomies phy_1 ON phy_1.id_physionomie = p_1.id_physionomie
          GROUP BY p_1.indexap) phy ON phy.indexap = ap.indexap
  WHERE ap.supprime = false AND geometrytype(ap.the_geom_local) = 'LINESTRING'::text
  ORDER BY s.nom_secteur, ap.indexzp;


-- View: florepatri.v_touteslesap_2154_point
CREATE OR REPLACE VIEW florepatri.v_touteslesap_sridlocal_point AS 
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
    ap.the_geom_local,
    ap.topo_valid AS ap_topo_valid,
    zp.validation AS relue,
    ap.remarques
   FROM florepatri.t_apresence ap
     JOIN florepatri.t_zprospection zp ON ap.indexzp = zp.indexzp
     JOIN florepatri.bib_taxons_fp t ON t.cd_nom = zp.cd_nom
     JOIN layers.l_secteurs s ON s.id_secteur = zp.id_secteur
     JOIN florepatri.bib_phenologies p ON p.codepheno = ap.codepheno
     JOIN layers.l_communes com ON com.insee = ap.insee
     JOIN florepatri.bib_frequences_methodo_new f ON f.id_frequence_methodo_new = ap.id_frequence_methodo_new
     JOIN florepatri.bib_comptages_methodo compt ON compt.id_comptage_methodo = ap.id_comptage_methodo
     JOIN ( SELECT c.indexzp,
            array_to_string(array_agg((r.prenom_role::text || ' '::text) || r.nom_role::text), ', '::text) AS observateurs
           FROM florepatri.cor_zp_obs c
             JOIN utilisateurs.t_roles r ON r.id_role = c.codeobs
          GROUP BY c.indexzp) o ON o.indexzp = ap.indexzp
     LEFT JOIN ( SELECT c.indexap,
            array_to_string(array_agg(((per_1.description::text || ' ('::text) || per_1.classification::text) || ')'::text), ', '::text) AS perturbations
           FROM florepatri.cor_ap_perturb c
             JOIN florepatri.bib_perturbations per_1 ON per_1.codeper = c.codeper
          GROUP BY c.indexap) per ON per.indexap = ap.indexap
     LEFT JOIN ( SELECT p_1.indexap,
            array_to_string(array_agg(((phy_1.nom_physionomie::text || ' ('::text) || phy_1.groupe_physionomie::text) || ')'::text), ', '::text) AS physionomies
           FROM florepatri.cor_ap_physionomie p_1
             JOIN florepatri.bib_physionomies phy_1 ON phy_1.id_physionomie = p_1.id_physionomie
          GROUP BY p_1.indexap) phy ON phy.indexap = ap.indexap
  WHERE ap.supprime = false AND geometrytype(ap.the_geom_local) = 'POINT'::text
  ORDER BY s.nom_secteur, ap.indexzp;


-- View: florepatri.v_touteslesap_2154_polygon
CREATE OR REPLACE VIEW florepatri.v_touteslesap_sridlocal_polygon AS 
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
    ap.the_geom_local,
    ap.topo_valid AS ap_topo_valid,
    zp.validation AS relue,
    ap.remarques
   FROM florepatri.t_apresence ap
     JOIN florepatri.t_zprospection zp ON ap.indexzp = zp.indexzp
     JOIN florepatri.bib_taxons_fp t ON t.cd_nom = zp.cd_nom
     JOIN layers.l_secteurs s ON s.id_secteur = zp.id_secteur
     JOIN florepatri.bib_phenologies p ON p.codepheno = ap.codepheno
     JOIN layers.l_communes com ON com.insee = ap.insee
     JOIN florepatri.bib_frequences_methodo_new f ON f.id_frequence_methodo_new = ap.id_frequence_methodo_new
     JOIN florepatri.bib_comptages_methodo compt ON compt.id_comptage_methodo = ap.id_comptage_methodo
     JOIN ( SELECT c.indexzp,
            array_to_string(array_agg((r.prenom_role::text || ' '::text) || r.nom_role::text), ', '::text) AS observateurs
           FROM florepatri.cor_zp_obs c
             JOIN utilisateurs.t_roles r ON r.id_role = c.codeobs
          GROUP BY c.indexzp) o ON o.indexzp = ap.indexzp
     LEFT JOIN ( SELECT c.indexap,
            array_to_string(array_agg(((per_1.description::text || ' ('::text) || per_1.classification::text) || ')'::text), ', '::text) AS perturbations
           FROM florepatri.cor_ap_perturb c
             JOIN florepatri.bib_perturbations per_1 ON per_1.codeper = c.codeper
          GROUP BY c.indexap) per ON per.indexap = ap.indexap
     LEFT JOIN ( SELECT p_1.indexap,
            array_to_string(array_agg(((phy_1.nom_physionomie::text || ' ('::text) || phy_1.groupe_physionomie::text) || ')'::text), ', '::text) AS physionomies
           FROM florepatri.cor_ap_physionomie p_1
             JOIN florepatri.bib_physionomies phy_1 ON phy_1.id_physionomie = p_1.id_physionomie
          GROUP BY p_1.indexap) phy ON phy.indexap = ap.indexap
  WHERE ap.supprime = false AND geometrytype(ap.the_geom_local) = 'POLYGON'::text
  ORDER BY s.nom_secteur, ap.indexzp;


-- View: florepatri.v_toutesleszp_2154
CREATE OR REPLACE VIEW florepatri.v_toutesleszp_sridlocal AS 
 SELECT zp.indexzp AS gid,
    zp.indexzp,
    s.nom_secteur AS secteur,
    count(ap.indexap) AS nbap,
    zp.dateobs,
    t.latin AS taxon,
    zp.taxon_saisi,
    o.observateurs,
    zp.the_geom_local,
    zp.insee,
    com.commune_min AS commune,
    org.nom_organisme AS organisme_producteur,
    zp.topo_valid AS zp_topo_valid,
    zp.validation AS relue,
    zp.saisie_initiale,
    zp.srid_dessin
   FROM florepatri.t_zprospection zp
     LEFT JOIN florepatri.t_apresence ap ON ap.indexzp = zp.indexzp
     LEFT JOIN layers.l_communes com ON com.insee = zp.insee
     LEFT JOIN utilisateurs.bib_organismes org ON org.id_organisme = zp.id_organisme
     JOIN florepatri.bib_taxons_fp t ON t.cd_nom = zp.cd_nom
     JOIN layers.l_secteurs s ON s.id_secteur = zp.id_secteur
     JOIN ( SELECT c.indexzp,
            array_to_string(array_agg((r.prenom_role::text || ' '::text) || r.nom_role::text), ', '::text) AS observateurs
           FROM florepatri.cor_zp_obs c
             JOIN utilisateurs.t_roles r ON r.id_role = c.codeobs
          GROUP BY c.indexzp) o ON o.indexzp = zp.indexzp
  WHERE zp.supprime = false
  GROUP BY s.nom_secteur, zp.indexzp, zp.dateobs, t.latin, zp.taxon_saisi, o.observateurs, zp.the_geom_local, zp.insee, com.commune_min, org.nom_organisme, zp.topo_valid, zp.validation, zp.saisie_initiale, zp.srid_dessin
  ORDER BY s.nom_secteur, zp.indexzp;


----------------------------------------------
--FLORE STATION-------------------------------
----------------------------------------------

ALTER TABLE florestation.t_stations_fs RENAME the_geom_2154  TO the_geom_local;
ALTER TABLE florestation.t_stations_fs DROP CONSTRAINT enforce_geotype_the_geom_2154;
ALTER TABLE florestation.t_stations_fs ADD CONSTRAINT enforce_geotype_the_geom_local CHECK (geometrytype(the_geom_local) = 'POINT'::text OR the_geom_local IS NULL);
ALTER TABLE florestation.t_stations_fs DROP CONSTRAINT enforce_srid_the_geom_2154;
ALTER TABLE florestation.t_stations_fs ADD CONSTRAINT enforce_srid_the_geom_local CHECK (st_srid(the_geom_local) = 2154);
ALTER TABLE florestation.t_stations_fs DROP CONSTRAINT enforce_dims_the_geom_2154;
ALTER TABLE florestation.t_stations_fs ADD CONSTRAINT enforce_dims_the_geom_local CHECK (st_ndims(the_geom_local) = 2);


-- Function: florestation.florestation_insert()
CREATE OR REPLACE FUNCTION florestation.florestation_insert()
  RETURNS trigger AS
$BODY$
BEGIN 
new.date_insert= 'now';  -- mise a jour de date insert
new.date_update= 'now';  -- mise a jour de date update
--new.the_geom_local = public.st_transform(new.the_geom_3857,2154);
--new.insee = layers.f_insee(new.the_geom_local);-- mise a jour du code insee
--new.altitude_sig = layers.f_isolines20(new.the_geom_local); -- mise à jour de l'altitude sig
--if new.altitude_saisie is null or new.altitude_saisie = 0 then -- mis à jour de l'altitude retenue
  --new.altitude_retenue = new.altitude_sig;
--else
  --new.altitude_retenue = new.altitude_saisie;
--end if;
return new; -- return new procède à l'insertion de la donnée dans PG avec les nouvelles valeures.     
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;


-- Function: florestation.florestation_update()
CREATE OR REPLACE FUNCTION florestation.florestation_update()
  RETURNS trigger AS
$BODY$
BEGIN
--si aucun geom n'existait et qu'au moins un geom est ajouté, on créé les 2 geom
IF (old.the_geom_local is null AND old.the_geom_3857 is null) THEN
    IF (new.the_geom_local is NOT NULL) THEN
        new.the_geom_3857 = public.st_transform(new.the_geom_local,3857);
    new.srid_dessin = 2154;
    END IF;
    IF (new.the_geom_3857 is NOT NULL) THEN
        new.the_geom_local = public.st_transform(new.the_geom_3857,2154);
    new.srid_dessin = 3857;
    END IF;
    -- on calcul la commune...
    new.insee = layers.f_insee(new.the_geom_local);-- mise à jour du code insee
    -- on calcul l'altitude
    new.altitude_sig = layers.f_isolines20(new.the_geom_local); -- mise à jour de l'altitude sig
    IF new.altitude_saisie IS null OR new.altitude_saisie = -1 THEN-- mis à jour de l'altitude retenue
        new.altitude_retenue = new.altitude_sig;
    ELSE
        new.altitude_retenue = new.altitude_saisie;
    END IF;
END IF;
--si au moins un geom existait et qu'il a changé on fait une mise à jour
IF (old.the_geom_local is NOT NULL OR old.the_geom_3857 is NOT NULL) THEN
    --si c'est le 2154 qui existait on teste s'il a changé
    IF (old.the_geom_local is NOT NULL AND new.the_geom_local is NOT NULL) THEN
        IF NOT public.st_equals(new.the_geom_local,old.the_geom_local) THEN
            new.the_geom_3857 = public.st_transform(new.the_geom_local,3857);
            new.srid_dessin = 2154;
        END IF;
    END IF;
    --si c'est le 3857 qui existait on teste s'il a changé
    IF (old.the_geom_3857 is NOT NULL AND new.the_geom_3857 is NOT NULL) THEN
        IF NOT public.st_equals(new.the_geom_3857,old.the_geom_3857) THEN
            new.the_geom_local = public.st_transform(new.the_geom_3857,2154);
            new.srid_dessin = 3857;
        END IF;
    END IF;
    -- on calcul la commune...
    new.insee = layers.f_insee(new.the_geom_local);-- mise à jour du code insee
    -- on calcul l'altitude
    new.altitude_sig = layers.f_isolines20(new.the_geom_local); -- mise à jour de l'altitude sig
    IF new.altitude_saisie IS null OR new.altitude_saisie = -1 THEN-- mis à jour de l'altitude retenue
        new.altitude_retenue = new.altitude_sig;
    ELSE
        new.altitude_retenue = new.altitude_saisie;
    END IF;
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
new.date_update= 'now';  -- mise a jour de date insert
RETURN new; -- return new procède à l'insertion de la donnée dans PG avec les nouvelles valeures.     
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;


-- Function: florestation.insert_synthese_cor_fs_taxon()
CREATE OR REPLACE FUNCTION florestation.insert_synthese_cor_fs_taxon()
  RETURNS trigger AS
$BODY$
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
      the_geom_local,
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
      fiche.the_geom_local,
      fiche.the_geom_3857
    );
RETURN NEW;       
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;


-- Function: florestation.update_synthese_stations_fs()
CREATE OR REPLACE FUNCTION florestation.update_synthese_stations_fs()
  RETURNS trigger AS
$BODY$
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
            the_geom_local = new.the_geom_local,
            the_geom_point = new.the_geom_3857
        WHERE id_source = 5 AND id_fiche_source = CAST(monreleve.gid AS VARCHAR(25));
    END IF;
END LOOP;
  RETURN NEW; 
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;


-- View: florestation.v_florestation_all
DROP VIEW florestation.v_florestation_all;
CREATE OR REPLACE VIEW florestation.v_florestation_all AS 
 SELECT cor.id_station_cd_nom AS indexbidon,
    fs.id_station,
    fs.dateobs,
    cor.cd_nom,
    btrim(tr.nom_valide::text) AS nom_valid,
    btrim(tr.nom_vern::text) AS nom_vern,
    st_transform(fs.the_geom_local, 2154) AS the_geom
   FROM florestation.t_stations_fs fs
     JOIN florestation.cor_fs_taxon cor ON cor.id_station = fs.id_station
     JOIN taxonomie.taxref tr ON cor.cd_nom = tr.cd_nom
  WHERE fs.supprime = false AND cor.supprime = false;


-- View: florestation.v_florestation_patrimoniale
DROP VIEW florestation.v_florestation_patrimoniale;
CREATE OR REPLACE VIEW florestation.v_florestation_patrimoniale AS 
 SELECT cft.id_station_cd_nom AS indexbidon,
    fs.id_station,
    tx.nom_vern AS francais,
    tx.nom_complet AS latin,
    fs.dateobs,
    fs.the_geom_local
   FROM florestation.t_stations_fs fs
     JOIN florestation.cor_fs_taxon cft ON cft.id_station = fs.id_station
     JOIN taxonomie.bib_noms n ON n.cd_nom = cft.cd_nom
     LEFT JOIN taxonomie.taxref tx ON tx.cd_nom = cft.cd_nom
     JOIN taxonomie.cor_taxon_attribut cta ON cta.cd_ref = n.cd_ref AND cta.id_attribut = 1 AND cta.valeur_attribut = 'oui'::text
  WHERE fs.supprime = false AND cft.supprime = false
  ORDER BY fs.id_station, tx.nom_vern;


----------------------------------------------
--SYNTHESE------------------------------------
----------------------------------------------

ALTER TABLE synthese.syntheseff RENAME the_geom_2154  TO the_geom_local;
ALTER TABLE synthese.syntheseff DROP CONSTRAINT enforce_srid_the_geom_2154;
ALTER TABLE synthese.syntheseff ADD CONSTRAINT enforce_srid_the_geom_local CHECK (st_srid(the_geom_local) = 2154);
ALTER TABLE synthese.syntheseff DROP CONSTRAINT enforce_dims_the_geom_2154;
ALTER TABLE synthese.syntheseff ADD CONSTRAINT enforce_dims_the_geom_local CHECK (st_ndims(the_geom_local) = 2);
--Cette contrainte doit être supprimée car les géométries de la synthèse peuvent comporter tous les types
--Il est possible que vous l'ayez déjà supprimée de votre base
ALTER TABLE synthese.syntheseff DROP CONSTRAINT enforce_geotype_the_geom_2154;


-- Function: synthese.maj_cor_unite_synthese()
CREATE OR REPLACE FUNCTION synthese.maj_cor_unite_synthese()
  RETURNS trigger AS
$BODY$
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
    WHERE public.st_intersects(u.the_geom, s.the_geom_local) 
    AND s.id_synthese = new.id_synthese;
  END IF;
END IF; 
RETURN NULL;  
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;


-- Function: synthese.maj_cor_zonesstatut_synthese()
CREATE OR REPLACE FUNCTION synthese.maj_cor_zonesstatut_synthese()
  RETURNS trigger AS
$BODY$
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
    WHERE public.st_intersects(z.the_geom, s.the_geom_local)
    AND z.id_type IN(1,4,5,6,7,8,9,10,11) -- typologie limitée au coeur, reserve, natura2000 etc...
    AND s.id_synthese = new.id_synthese;
  END IF;
END IF;
RETURN NULL; 
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
