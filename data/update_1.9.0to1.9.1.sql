--Correction d'un trigger provocant une récursion
CREATE OR REPLACE FUNCTION contactflore.update_fiche_cflore()
  RETURNS trigger AS
$BODY$
DECLARE
macommune character(5);
nbreleves integer;
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
	IF st_isvalid(new.the_geom_local) = true THEN	-- si la topologie est bonne alors...
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
    --Pour éviter un bouclage des triggers, on vérifie qu'il y a bien des relevés non supprimés à modifier
    SELECT INTO nbreleves count(*) FROM contactflore.t_releves_cflore WHERE id_cflore = old.id_cflore AND supprime = false;
    IF nbreleves > 0 THEN
	update contactflore.t_releves_cflore set supprime = 't' WHERE id_cflore = old.id_cflore; 
     END IF;
  END IF;
  IF new.supprime = 'f' THEN
     --action discutable. S'il y a des relevés douteux dans la fiche, il faut les garder supprimés
     --update contactflore.t_releves_cflore set supprime = 'f' WHERE id_cflore = old.id_cflore; 
  END IF;
END IF;
RETURN NEW; 
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

 
--Corriger les fonction de calcul de la couleur des taxons par unités géo

CREATE OR REPLACE FUNCTION contactflore.couleur_taxon(
    id integer,
    maxdateobs date)
  RETURNS text AS
$BODY$
  --fonction permettant de renvoyer la couleur d'un taxon à partir de la dernière date d'observation 
  DECLARE
  couleur text;
  patri character(3);
  BEGIN
    SELECT cta.valeur_attribut INTO patri 
    FROM taxonomie.bib_noms n
    JOIN taxonomie.cor_taxon_attribut cta ON cta.cd_ref = n.cd_ref AND cta.id_attribut = 1
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
ALTER FUNCTION contactflore.couleur_taxon(integer, date)
  OWNER TO cartopne;



CREATE OR REPLACE FUNCTION contactinv.couleur_taxon(
    id integer,
    maxdateobs date)
  RETURNS text AS
$BODY$
  --fonction permettant de renvoyer la couleur d'un taxon à partir de la dernière date d'observation 
  DECLARE
  couleur text;
  patri character(3);
  BEGIN
    SELECT cta.valeur_attribut INTO patri 
    FROM taxonomie.bib_noms n
    JOIN taxonomie.cor_taxon_attribut cta ON cta.cd_ref = n.cd_ref AND cta.id_attribut = 1
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
ALTER FUNCTION contactinv.couleur_taxon(integer, date)
  OWNER TO cartopne;


CREATE OR REPLACE FUNCTION contactfaune.couleur_taxon(
    id integer,
    maxdateobs date)
  RETURNS text AS
$BODY$
  --fonction permettant de renvoyer la couleur d'un taxon à partir de la dernière date d'observation 
  DECLARE
  couleur text;
  patri character(3);
  BEGIN
    SELECT cta.valeur_attribut INTO patri 
    FROM taxonomie.bib_noms n
    JOIN taxonomie.cor_taxon_attribut cta ON cta.cd_ref = n.cd_ref AND cta.id_attribut = 1
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
ALTER FUNCTION contactfaune.couleur_taxon(integer, date)
  OWNER TO cartopne;

  --Vous devez vérifier si des couleurs ne sont pas = à 'f' dans contactflore.cor_unite_taxon_cflore, contactfaune.cor_unite_taxon et contactinv.cor_unite_taxon_inv
  --ATTENTION LES SCRIPTS CI-DESSOUS SONT FOURNIS A TITRE D'EXEMPLE
  --A VERIFIER ET ADAPTER A VOTRE CONTEXTE DE DONNEES

  --Corrections à adapter
--trouver les taxons avec une couleur = à 'f'
SELECT DISTINCT n.cd_nom, n.cd_ref, c.id_nom FROM contactfaune.cor_unite_taxon c
JOIN taxonomie.bib_noms n ON n.id_nom = c.id_nom
WHERE couleur = 'f'
--copier les id_nom dans le résultat
SELECT DISTINCT n.cd_nom, n.cd_ref, c.id_nom FROM contactflore.cor_unite_taxon_cflore c
JOIN taxonomie.bib_noms n ON n.id_nom = c.id_nom
WHERE couleur = 'f'
--copier les id_nom dans le résultat
WHERE couleur = 'f'
--copier les id_nom dans le résultat
SELECT DISTINCT n.cd_nom, n.cd_ref, c.id_nom FROM contactinv.cor_unite_taxon_inv c
JOIN taxonomie.bib_noms n ON n.id_nom = c.id_nom
WHERE couleur = 'f'
--copier les id_nom dans le résultat

--Corriger les enregistrements invalides (suppression et recréation)
--Exemple pour contactflore à adapter pour contactinv et contactfaune
delete FROM contactflore.cor_unite_taxon_cflore WHERE id_nom in(1000780,
956,
101629,
200049,
101350,
...);
INSERT INTO contactflore.cor_unite_taxon_cflore (id_unite_geo,id_nom,derniere_date,couleur,nb_obs)
SELECT id_unite_geo, n.id_nom,  max(dateobs) AS derniere_date, contactinv.couleur_taxon(n.id_nom,max(dateobs)) AS couleur, count(s.id_synthese) AS nb_obs
FROM synthese.cor_unite_synthese s
JOIN taxonomie.bib_noms n ON n.cd_nom = s.cd_nom
WHERE n.id_nom in(1000780,
956,
101629,
200049,
101350,
...)
GROUP BY id_unite_geo, n.id_nom;

--Autre approche si les taxons avec une couleur 'f' sont nombreux
--S'ils sont nombreux utiliser une table temporaire à supprimer ensuite
SELECT id_nom INTO temp_txflore FROM contactflore.cor_unite_taxon_cflore WHERE id_nom IN(SELECT DISTINCT id_nom FROM contactflore.cor_unite_taxon_cflore WHERE couleur = 'f');
SELECT id_nom INTO temp_txfaune FROM contactfaune.cor_unite_taxon WHERE id_nom IN(SELECT DISTINCT id_nom FROM contactfaune.cor_unite_taxon WHERE couleur = 'f');
SELECT id_nom INTO temp_txinv FROM contactinv.cor_unite_taxon_inv WHERE id_nom IN(SELECT DISTINCT id_nom FROM contactinv.cor_unite_taxon_inv WHERE couleur = 'f');

DELETE FROM contactflore.cor_unite_taxon_cflore WHERE id_nom in(SELECT id_nom FROM temp_txflore);
INSERT INTO contactflore.cor_unite_taxon_cflore (id_unite_geo,id_nom,derniere_date,couleur,nb_obs)
SELECT id_unite_geo, n.id_nom,  max(dateobs) AS derniere_date, contactinv.couleur_taxon(n.id_nom,max(dateobs)) AS couleur, count(s.id_synthese) AS nb_obs
FROM synthese.cor_unite_synthese s
JOIN taxonomie.bib_noms n ON n.cd_nom = s.cd_nom
JOIN taxonomie.cor_nom_liste cnl ON cnl.id_nom = n.id_nom
WHERE n.id_nom in(SELECT id_nom FROM temp_txflore)
GROUP BY id_unite_geo, n.id_nom;
--idem pour cfaune et invertébrés

--puis suppression des tables temporaires
DROP TABLE temp_txflore;
DROP TABLE temp_txfaune;
DROP TABLE temp_txinv;

--ATTETION, IL FAUT PAR AILLEURS S'ASSURER QUE TOUS LES TAXONS (cd_ref) ONT UNE VALEUR POUR L'ATTRIBUT 1 (patrimonial) DANS LA TABLE taxonomie.cor_taxon_attribut
