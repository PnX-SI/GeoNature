CREATE OR REPLACE FUNCTION ref_nomenclatures.check_nomenclature_type_by_cd_nomenclature(mycdnomenclature character varying, mytype character varying)
 RETURNS boolean
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
--Function that checks if an id_nomenclature matches with wanted nomenclature type (use mnemonique type)
  BEGIN
    IF (mycdnomenclature IN (SELECT cd_nomenclature FROM ref_nomenclatures.t_nomenclatures WHERE id_type = ref_nomenclatures.get_id_nomenclature_type(mytype))
        OR mycdnomenclature IS NULL) THEN
      RETURN true;
    ELSE
	    RAISE EXCEPTION 'Error : cd_nomenclature --> % and nomenclature type --> % didn''t match.', mycdnomenclature, mytype
	    USING HINT = 'Use cd_nomenclature in corresponding type (mnemonique field). See ref_nomenclatures.t_nomenclatures.id_type and ref_nomenclatures.bib_nomenclatures_types.mnemonique';
    END IF;
    RETURN false;
  END;
$function$

CREATE OR REPLACE FUNCTION ref_nomenclatures.check_nomenclature_type_by_id(id integer, myidtype integer)
 RETURNS boolean
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
--Function that checks if an id_nomenclature matches with wanted nomenclature type (use id_type)
  BEGIN
    IF (id IN (SELECT id_nomenclature FROM ref_nomenclatures.t_nomenclatures WHERE id_type = myidtype )
        OR id IS NULL) THEN
      RETURN true;
    ELSE
	    RAISE EXCEPTION 'Error : id_nomenclature --> (%) and id_type --> (%) didn''t match. Use nomenclature with corresponding type (id_type). See ref_nomenclatures.t_nomenclatures.id_type and ref_nomenclatures.bib_nomenclatures_types.id_type.', id, myidtype ;
    END IF;
    RETURN false;
  END;
$function$

CREATE OR REPLACE FUNCTION ref_nomenclatures.check_nomenclature_type_by_mnemonique(id integer, mytype character varying)
 RETURNS boolean
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
--Function that checks if an id_nomenclature matches with wanted nomenclature type (use mnemonique type)
  BEGIN
    IF (id IN (SELECT id_nomenclature FROM ref_nomenclatures.t_nomenclatures WHERE id_type = ref_nomenclatures.get_id_nomenclature_type(mytype))
        OR id IS NULL) THEN
      RETURN true;
    ELSE
	    RAISE EXCEPTION 'Error : id_nomenclature --> (%) and nomenclature --> (%) type didn''t match. Use id_nomenclature in corresponding type (mnemonique field). See ref_nomenclatures.t_nomenclatures.id_type.', id,mytype;
    END IF;
    RETURN false;
  END;
$function$

CREATE OR REPLACE FUNCTION ref_nomenclatures.get_cd_nomenclature(myidnomenclature integer)
 RETURNS character varying
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
--Function which return the cd_nomenclature from an id_nomenclature
DECLARE thecdnomenclature character varying;
  BEGIN
SELECT INTO thecdnomenclature cd_nomenclature
FROM ref_nomenclatures.t_nomenclatures n
WHERE myidnomenclature = n.id_nomenclature;
return thecdnomenclature;
  END;
$function$

CREATE OR REPLACE FUNCTION ref_nomenclatures.get_default_nomenclature_value(mytype character varying, myidorganism integer DEFAULT NULL::integer)
 RETURNS integer
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
    --Function that return the default nomenclature id with wanted nomenclature type (mnemonique), organism id
    --Return -1 if nothing matches with given parameters
      DECLARE
        thenomenclatureid integer;
      BEGIN
        SELECT
            INTO thenomenclatureid id_nomenclature,
            CASE 
                WHEN id_organisme = myidorganism THEN 1
                ELSE 0
            END priority
        FROM ref_nomenclatures.defaults_nomenclatures_value dnv
        JOIN utilisateurs.bib_organismes o
        ON o.id_organisme = dnv.id_organism 
        WHERE mnemonique_type = mytype
        AND (id_organisme = myidorganism OR id_organisme = NULL OR nom_organisme = 'ALL')
        ORDER BY priority DESC
        LIMIT 1;
        RETURN thenomenclatureid;
      END;
    $function$

CREATE OR REPLACE FUNCTION ref_nomenclatures.get_filtered_nomenclature(mytype character varying, myregne character varying, mygroup character varying)
 RETURNS SETOF integer
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
--Function that returns a list of id_nomenclature depending on regne and/or group2_inpn sent with parameters.
  DECLARE
    thegroup character varying(255);
    theregne character varying(255);
    r integer;

BEGIN
  thegroup = NULL;
  theregne = NULL;

  IF mygroup IS NOT NULL THEN
      SELECT INTO thegroup DISTINCT group2_inpn
      FROM ref_nomenclatures.cor_taxref_nomenclature ctn
      JOIN ref_nomenclatures.t_nomenclatures n ON n.id_nomenclature = ctn.id_nomenclature
      WHERE n.id_type = ref_nomenclatures.get_id_nomenclature_type(mytype)
      AND group2_inpn = mygroup;
  END IF;

  IF myregne IS NOT NULL THEN
    SELECT INTO theregne DISTINCT regne
    FROM ref_nomenclatures.cor_taxref_nomenclature ctn
    JOIN ref_nomenclatures.t_nomenclatures n ON n.id_nomenclature = ctn.id_nomenclature
    WHERE n.id_type = ref_nomenclatures.get_id_nomenclature_type(mytype)
    AND regne = myregne;
  END IF;

  IF theregne IS NOT NULL THEN
    IF thegroup IS NOT NULL THEN
      FOR r IN
        SELECT DISTINCT ctn.id_nomenclature
        FROM taxonomie.cor_taxref_nomenclature ctn
        JOIN ref_nomenclatures.t_nomenclatures n ON n.id_nomenclature = ctn.id_nomenclature
        WHERE n.id_type = ref_nomenclatures.get_id_nomenclature_type(mytype)
        AND regne = theregne
        AND group2_inpn = mygroup
      LOOP
        RETURN NEXT r;
      END LOOP;
      RETURN;
    ELSE
      FOR r IN
        SELECT DISTINCT ctn.id_nomenclature
        FROM taxonomie.cor_taxref_nomenclature ctn
        JOIN ref_nomenclatures.t_nomenclatures n ON n.id_nomenclature = ctn.id_nomenclature
        WHERE n.id_type = ref_nomenclatures.get_id_nomenclature_type(mytype)
        AND regne = theregne
      LOOP
        RETURN NEXT r;
      END LOOP;
      RETURN;
    END IF;
  ELSE
    FOR r IN
      SELECT DISTINCT ctn.id_nomenclature
      FROM taxonomie.cor_taxref_nomenclature ctn
      JOIN ref_nomenclatures.t_nomenclatures n ON n.id_nomenclature = ctn.id_nomenclature
      WHERE n.id_type = ref_nomenclatures.get_id_nomenclature_type(mytype)
    LOOP
      RETURN NEXT r;
    END LOOP;
    RETURN;
  END IF;
END;
$function$

CREATE OR REPLACE FUNCTION ref_nomenclatures.get_id_nomenclature(mytype character varying, mycdnomenclature character varying)
 RETURNS integer
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
--Function which return the id_nomenclature from an mnemonique_type and an cd_nomenclature
DECLARE theidnomenclature integer;
  BEGIN
SELECT INTO theidnomenclature id_nomenclature
FROM ref_nomenclatures.t_nomenclatures n
WHERE n.id_type = ref_nomenclatures.get_id_nomenclature_type(mytype) AND mycdnomenclature = n.cd_nomenclature;
return theidnomenclature;
  END;
$function$

CREATE OR REPLACE FUNCTION ref_nomenclatures.get_id_nomenclature_type(mytype character varying)
 RETURNS integer
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
--Function which return the id_type from the mnemonique of a nomenclature type
DECLARE theidtype character varying;
  BEGIN
SELECT INTO theidtype id_type FROM ref_nomenclatures.bib_nomenclatures_types WHERE mnemonique = mytype;
return theidtype;
  END;
$function$

CREATE OR REPLACE FUNCTION ref_nomenclatures.get_nomenclature_label(myidnomenclature integer DEFAULT NULL::integer, mylanguage character varying DEFAULT 'fr'::character varying)
 RETURNS character varying
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
        --Function which return the label from the id_nomenclature and the language
        DECLARE
            labelfield character varying;
            thelabel character varying;
        BEGIN
        IF myidnomenclature IS NULL THEN
            RETURN NULL;
        END IF;

        labelfield = 'label_'||mylanguage;
        EXECUTE format('
            SELECT  %s
            FROM ref_nomenclatures.t_nomenclatures n
            WHERE id_nomenclature = %s
        ',labelfield, myidnomenclature
        )
        INTO thelabel;
        return thelabel;
        END;
        $function$

CREATE OR REPLACE FUNCTION ref_nomenclatures.get_nomenclature_label_by_cdnom_mnemonique(mytype character varying, mycdnomenclature character varying)
 RETURNS character varying
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
--Function which return the label from the id_nomenclature and the language
DECLARE
	labelfield character varying;
	thelabel character varying;
  BEGIN
  EXECUTE format( ' SELECT  label_default
  FROM ref_nomenclatures.t_nomenclatures n
  WHERE cd_nomenclature = $1 AND id_type = ref_nomenclatures.get_id_nomenclature_type($2)' )INTO thelabel USING mycdnomenclature, mytype;
return thelabel;
  END;
$function$

CREATE OR REPLACE FUNCTION ref_nomenclatures.get_nomenclature_label_by_cdnom_mnemonique_and_language(mytype character varying, mycdnomenclature character varying, mylanguage character varying)
 RETURNS character varying
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
--Function which return the label from the cd_nomenclature, the code_type and the language
DECLARE
	labelfield character varying;
	thelabel character varying;
  BEGIN
  labelfield = 'label_'||mylanguage;
  EXECUTE format( ' SELECT  %s
  FROM ref_nomenclatures.t_nomenclatures n
  WHERE cd_nomenclature = $1 AND id_type = ref_nomenclatures.get_id_nomenclature_type($2)',labelfield )INTO thelabel USING mycdnomenclature, mytype;
return thelabel;
  END;
$function$

