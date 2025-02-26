CREATE OR REPLACE FUNCTION taxonomie.check_is_cd_ref(mycdnom integer)
 RETURNS boolean
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
    --fonction permettant de vérifier si une valeur est bien un cd_ref existant
    --peut notamment servir pour les contraintes de certaines tables comme "gn_profiles.cor_taxons_profiles_parameters"
      BEGIN
        IF EXISTS( SELECT cd_ref FROM taxonomie.taxref WHERE cd_ref=mycdnom )
            THEN
          RETURN true;
        ELSE
            RAISE EXCEPTION 'Error : The code entered as argument is not a valid cd_ref' ;
        END IF;
        RETURN false;
      END;
    $function$

CREATE OR REPLACE FUNCTION taxonomie.check_is_group2inpn(mygroup text)
 RETURNS boolean
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
--fonction permettant de vérifier si un texte proposé correspond à un group2_inpn dans la table taxref
  BEGIN
    IF mygroup IN(SELECT group2_inpn FROM taxonomie.vm_group2_inpn) OR mygroup IS NULL THEN
      RETURN true;
    ELSE
      RETURN false;
    END IF;
  END;
$function$

CREATE OR REPLACE FUNCTION taxonomie.check_is_group3inpn(mygroup text)
 RETURNS boolean
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
                --fonction permettant de vérifier si un texte proposé correspond à un group3_inpn dans la table taxref
                BEGIN
                    IF EXISTS (SELECT 1 FROM taxonomie.taxref WHERE group3_inpn = mygroup ) OR mygroup IS NULL THEN
                    RETURN true;
                    ELSE
                    RETURN false;
                    END IF;
                END;
                $function$

CREATE OR REPLACE FUNCTION taxonomie.check_is_inbibnoms(mycdnom integer)
 RETURNS boolean
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
--fonction permettant de vérifier si un texte proposé correspond à un group2_inpn dans la table taxref
  BEGIN
    IF mycdnom IN(SELECT cd_nom FROM taxonomie.bib_noms) THEN
      RETURN true;
    ELSE
      RETURN false;
    END IF;
  END;
$function$

CREATE OR REPLACE FUNCTION taxonomie.check_is_regne(myregne text)
 RETURNS boolean
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
--fonction permettant de vérifier si un texte proposé correspond à un regne dans la table taxref
  BEGIN
    IF myregne IN(SELECT regne FROM taxonomie.vm_regne) OR myregne IS NULL THEN
      return true;
    ELSE
      RETURN false;
    END IF;
  END;
$function$

CREATE OR REPLACE FUNCTION taxonomie.find_all_taxons_children(id integer)
 RETURNS TABLE(cd_nom integer, cd_ref integer)
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
 --Param : cd_nom ou cd_ref d'un taxon quelque soit son rang
 --Retourne le cd_nom de tous les taxons enfants sous forme d'un jeu de données utilisable comme une table
 --Usage SELECT taxonomie.find_all_taxons_children(197047);
 --ou SELECT * FROM atlas.vm_taxons WHERE cd_ref IN(SELECT * FROM taxonomie.find_all_taxons_children(197047))
  BEGIN
      RETURN QUERY
      WITH RECURSIVE descendants AS (
        SELECT tx1.cd_nom, tx1.cd_ref FROM taxonomie.taxref tx1 WHERE tx1.cd_sup = id
      UNION ALL
      SELECT tx2.cd_nom, tx2.cd_ref FROM descendants d JOIN taxonomie.taxref tx2 ON tx2.cd_sup = d.cd_nom
      )
      SELECT * FROM descendants;

  END;
$function$

CREATE OR REPLACE FUNCTION taxonomie.find_all_taxons_children(ids integer[])
 RETURNS TABLE(cd_nom integer, cd_ref integer)
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
 --Param : cd_nom ou cd_ref d'un taxon quelque soit son rang
 --Retourne le cd_nom de tous les taxons enfants sous forme d'un jeu de données utilisable comme une table
 --Usage SELECT taxonomie.find_all_taxons_children(197047);
 --ou SELECT * FROM atlas.vm_taxons WHERE cd_ref IN(SELECT * FROM taxonomie.find_all_taxons_children(197047))
  BEGIN
      RETURN QUERY
      WITH RECURSIVE descendants AS (
        SELECT tx1.cd_nom, tx1.cd_ref FROM taxonomie.taxref tx1 WHERE tx1.cd_sup = ANY(ids)
      UNION ALL
      SELECT tx2.cd_nom, tx2.cd_ref FROM descendants d JOIN taxonomie.taxref tx2 ON tx2.cd_sup = d.cd_nom
      )
      SELECT * FROM descendants;

  END;
$function$

CREATE OR REPLACE FUNCTION taxonomie.find_all_taxons_parents(mycdnom integer)
 RETURNS TABLE(cd_nom integer, distance smallint)
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
     -- Param : cd_nom d'un taxon quelque soit son rang.
     -- Retourne une table avec le cd_nom de tout les taxons parents et leur distance au dessus du cd_nom
     -- donné en argument. Les cd_nom sont ordonnées du plus bas (celui passé en argument) vers le plus
     -- haut (Dumm). Usage SELECT * FROM taxonomie.find_all_taxons_parents(457346);
      DECLARE
        inf RECORD;
     BEGIN
        RETURN QUERY
            WITH RECURSIVE parents AS (
                SELECT tx1.cd_nom,tx1.cd_sup, tx1.id_rang, 0 AS nr
                FROM taxonomie.taxref tx1
                WHERE tx1.cd_nom = taxonomie.find_cdref(mycdnom)
                UNION ALL
                SELECT tx2.cd_nom,tx2.cd_sup, tx2.id_rang, nr + 1
                    FROM parents p
                    JOIN taxonomie.taxref tx2 ON tx2.cd_nom = p.cd_sup
            )
            SELECT parents.cd_nom, nr::smallint AS distance FROM parents
            ORDER BY parents.nr;
      END;
    $function$

CREATE OR REPLACE FUNCTION taxonomie.find_cdref(id integer)
 RETURNS integer
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
--fonction permettant de renvoyer le cd_ref d'un taxon à partir de son cd_nom
--
--Gil DELUERMOZ septembre 2011

  DECLARE ref integer;
  BEGIN
	SELECT INTO ref cd_ref FROM taxonomie.taxref WHERE cd_nom = id;
	return ref;
  END;
$function$

CREATE OR REPLACE FUNCTION taxonomie.find_group2inpn(mycdnom integer)
 RETURNS text
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
--fonction permettant de renvoyer le group2_inpn d'un taxon à partir de son cd_nom
  DECLARE group2 character varying(255);
  BEGIN
    SELECT INTO group2 group2_inpn FROM taxonomie.taxref WHERE cd_nom = mycdnom;
    return group2;
  END;
$function$

CREATE OR REPLACE FUNCTION taxonomie.find_regne(mycdnom integer)
 RETURNS text
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
--fonction permettant de renvoyer le regne d'un taxon à partir de son cd_nom
  DECLARE theregne character varying(255);
  BEGIN
    SELECT INTO theregne regne FROM taxonomie.taxref WHERE cd_nom = mycdnom;
    return theregne;
  END;
$function$

CREATE OR REPLACE FUNCTION taxonomie.insert_t_medias()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    DECLARE
        trimtitre text;
    BEGIN
        new.date_media = now();
        new.cd_ref = taxonomie.find_cdref(new.cd_ref);
        trimtitre = replace(new.titre, ' ', '');
        RETURN NEW;
    END;
    $function$

CREATE OR REPLACE FUNCTION taxonomie.match_binomial_taxref(mytaxonname character varying)
 RETURNS integer
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
    --fonction permettant de rattacher un nom latin à son cd_nom taxref sur le principe suivant :
    -- - Si un seul cd_nom existe pour ce nom latin, la fonction retourne le cd_nom en question
    -- - Si plusieurs cd_noms existent pour ce nom latin, mais qu'ils appartiennent tous à un unique cd_ref, la fonction renvoie le cd_ref (= cd_nom valide)
    -- - Si plusieurs cd_noms existent pour ce nom latin et qu'ils correspondent à plusieurs cd_ref, la fonction renvoie NULL : le rattachement devra être fait manuellement
    DECLARE
        matching_cd integer;
    BEGIN
        IF (SELECT count(DISTINCT cd_nom) FROM taxonomie.taxref WHERE lb_nom=mytaxonname OR nom_valide=mytaxonname)=1 THEN matching_cd:= cd_nom FROM taxonomie.taxref WHERE lb_nom=mytaxonname OR nom_valide=mytaxonname ;
        ELSIF (SELECT count(DISTINCT cd_ref) FROM taxonomie.taxref WHERE lb_nom=mytaxonname OR nom_valide=mytaxonname)=1 THEN matching_cd:= DISTINCT(cd_ref) FROM taxonomie.taxref WHERE lb_nom=mytaxonname OR nom_valide=mytaxonname ;
        ELSE matching_cd:= NULL;
        END IF;
        RETURN matching_cd;
    END ;
    $function$

CREATE OR REPLACE FUNCTION taxonomie.unique_type1()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    nbimgprincipale integer;
    mymedia record;
BEGIN
  IF new.id_type = 1 THEN
    SELECT count(*) INTO nbimgprincipale FROM taxonomie.t_medias WHERE cd_ref = new.cd_ref AND id_type = 1 AND NOT id_media = NEW.id_media;
    IF nbimgprincipale > 0 THEN
      FOR mymedia  IN SELECT * FROM taxonomie.t_medias WHERE cd_ref = new.cd_ref AND id_type = 1 LOOP
        UPDATE taxonomie.t_medias SET id_type = 2 WHERE id_media = mymedia.id_media;
        RAISE NOTICE USING MESSAGE =
        'La photo principale a été mise à jour pour le cd_ref ' || new.cd_ref ||
        '. La photo avec l''id_media ' || mymedia.id_media  || ' n''est plus la photo principale.';
      END LOOP;
    END IF;
  END IF;
  RETURN NEW;
END;
$function$

