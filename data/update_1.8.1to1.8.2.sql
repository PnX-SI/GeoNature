--------------------MODULE CONTACT FAUNE--------------------

-- Function: contactfaune.calcul_cor_unite_taxon_cfaune(integer, integer)
-- DROP FUNCTION contactfaune.calcul_cor_unite_taxon_cfaune(integer, integer);
CREATE OR REPLACE FUNCTION contactfaune.calcul_cor_unite_taxon_cfaune(
    monidtaxon integer,
    monunite integer)
  RETURNS void AS
$BODY$
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
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;


-- Function: contactfaune.maj_cor_unite_taxon_cfaune()
-- DROP FUNCTION contactfaune.maj_cor_unite_taxon_cfaune();
CREATE OR REPLACE FUNCTION contactfaune.maj_cor_unite_taxon_cfaune()
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
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;


-- Trigger: tri_maj_cor_unite_taxon_cfaune on synthese.cor_unite_synthese
CREATE TRIGGER tri_maj_cor_unite_taxon_cfaune
  AFTER INSERT OR DELETE
  ON synthese.cor_unite_synthese
  FOR EACH ROW
  EXECUTE PROCEDURE contactfaune.maj_cor_unite_taxon_cfaune();



--------------------MODULE CONTACT INVERTEBRES--------------------

-- Function: contactinv.calcul_cor_unite_taxon_inv(integer, integer)
-- DROP FUNCTION contactinv.calcul_cor_unite_taxon_inv(integer, integer);
CREATE OR REPLACE FUNCTION contactinv.calcul_cor_unite_taxon_inv(
    monidtaxon integer,
    monunite integer)
  RETURNS void AS
$BODY$
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
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;


-- Function: contactinv.maj_cor_unite_taxon_inv()
-- DROP FUNCTION contactinv.maj_cor_unite_taxon_inv();
CREATE OR REPLACE FUNCTION contactinv.maj_cor_unite_taxon_inv()
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
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;


-- Trigger: tri_maj_cor_unite_taxon_inv on synthese.cor_unite_synthese
CREATE TRIGGER tri_maj_cor_unite_taxon_inv
  AFTER INSERT OR DELETE
  ON synthese.cor_unite_synthese
  FOR EACH ROW
  EXECUTE PROCEDURE contactinv.maj_cor_unite_taxon_inv();



--------------------MODULE CONTACT FLORE--------------------

-- Function: contactflore.calcul_cor_unite_taxon_cflore(integer, integer)
-- DROP FUNCTION contactflore.calcul_cor_unite_taxon_cflore(integer, integer);
CREATE OR REPLACE FUNCTION contactflore.calcul_cor_unite_taxon_cflore(
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


-- Function: contactflore.maj_cor_unite_taxon_cflore()
-- DROP FUNCTION contactflore.maj_cor_unite_taxon_cflore();
CREATE OR REPLACE FUNCTION contactflore.maj_cor_unite_taxon_cflore()
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


-- Trigger: tri_maj_cor_unite_taxon_cflore on synthese.cor_unite_synthese
CREATE TRIGGER tri_maj_cor_unite_taxon_cflore
  AFTER INSERT OR DELETE
  ON synthese.cor_unite_synthese
  FOR EACH ROW
  EXECUTE PROCEDURE contactflore.maj_cor_unite_taxon_cflore();



--------------------NETTOYAGE--------------------
DROP TRIGGER tri_maj_cor_unite_taxon ON synthese.cor_unite_synthese;
DROP FUNCTION synthese.maj_cor_unite_taxon();
DROP FUNCTION synthese.calcul_cor_unite_taxon_cf(integer, integer);
DROP FUNCTION synthese.calcul_cor_unite_taxon_inv(integer, integer);
DROP FUNCTION synthese.calcul_cor_unite_taxon_cflore(integer, integer);



--------------------CORRECTIONS--------------------

-- Function: contactflore.synthese_update_fiche_cflore()
-- DROP FUNCTION contactflore.synthese_update_fiche_cflore();
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

-- Function: contactflore.synthese_insert_releve_cflore()
-- DROP FUNCTION contactflore.synthese_insert_releve_cflore();
CREATE OR REPLACE FUNCTION contactflore.synthese_insert_releve_cflore() RETURNS trigger
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


--modification de la vue florestation.v_florestation_patrimoniale pour ne plus dépendre du schéma florepatri
DROP VIEW florestation.v_florestation_patrimoniale;
CREATE OR REPLACE VIEW florestation.v_florestation_patrimoniale AS 
 SELECT cft.id_station_cd_nom AS indexbidon,
    fs.id_station,
    tx.nom_vern AS francais,
    tx.nom_complet AS latin,
    fs.dateobs,
    fs.the_geom_2154
   FROM florestation.t_stations_fs fs
     JOIN florestation.cor_fs_taxon cft ON cft.id_station = fs.id_station
     JOIN taxonomie.bib_noms n ON n.cd_nom = cft.cd_nom
     LEFT JOIN taxonomie.taxref tx ON tx.cd_nom = cft.cd_nom
     JOIN taxonomie.cor_taxon_attribut cta ON cta.cd_ref = n.cd_ref AND cta.id_attribut = 1 AND cta.valeur_attribut = 'oui'::text
  WHERE fs.supprime = false AND cft.supprime = false
  ORDER BY fs.id_station, tx.nom_vern;


--récupération des taxons protégés. 
--Cette opération aurait du être faite dans le script "update_1.7to1.8.sql" mais une coquille sur la requête l'a rendu inopérante.  
INSERT INTO taxonomie.cor_taxon_attribut
SELECT 2 as id_attribut, 'oui' as valeur_attribut, taxonomie.find_cdref(t.cd_nom)
FROM save.bib_taxons t
LEFT JOIN taxonomie.taxref tx ON tx.cd_nom = t.cd_nom
WHERE filtre3 = 'oui'
AND tx.cd_nom = tx.cd_ref;

