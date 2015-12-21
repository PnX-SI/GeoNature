--ajout de la source 0 utilisée par la web api si l'id_source n'est pas transmis
INSERT INTO bib_sources (id_source, nom_source, desc_source, host, port, username, pass, db_name, db_schema, db_table, db_field, url, target, picto, groupe, actif) VALUES (0, 'Web API', 'Donnée externe non définie (insérée dans la synthese à partir du service reste de la web API sans id_source fourni)', 'localhost', 22, NULL, NULL, 'geonaturedb', 'synthese', 'syntheseff', 'id_fiche_source', NULL, NULL, NULL, 'NONE', false);
CREATE OR REPLACE FUNCTION contactinv.couleur_taxon(
    id integer,
    maxdateobs date)
  RETURNS text AS
$BODY$
--fonction permettant de renvoyer la couleur d'un taxon à partir de la dernière date d'observation 
--
--Gil DELUERMOZ mars 2012

  DECLARE
  couleur text;
  patri character(3);
  BEGIN
    SELECT filtre2 INTO patri 
    FROM taxonomie.bib_taxons
    WHERE id_taxon = id;
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