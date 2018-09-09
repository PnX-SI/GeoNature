CREATE OR REPLACE FUNCTION gn_commons.is_in_period(
    dateobs date,
    datebegin date,
    dateend date)
  RETURNS boolean
IMMUTABLE
LANGUAGE plpgsql
AS $$
DECLARE
day_obs int;
begin_day int;
end_day int;
test int; 

--Function to check if a date (dateobs) is in a period (datebegin, dateend)
--USAGE : SELECT gn_commons.is_in_period(dateobs, datebegin, dateend);
 
 
BEGIN
day_obs = extract(doy FROM dateobs);--jour de la date passée
begin_day = extract(doy FROM datebegin);--jour début
end_day = extract(doy FROM dateend); --jour fin
test = end_day - begin_day; --test si la période est sur 2 année ou pas
 
--si on est sur 2 années
IF test < 0 then
	IF day_obs BETWEEN begin_day AND 366 OR day_obs BETWEEN 1 AND end_day THEN RETURN true;
	END IF;
-- si on est dans la même année
else 
	IF day_obs BETWEEN begin_day AND end_day THEN RETURN true;
	END IF;
END IF;
	RETURN false;	
END;
$$;


CREATE OR REPLACE FUNCTION gn_commons.fct_trg_add_default_validation_status()
  RETURNS trigger AS
$BODY$
DECLARE
	theschema text := quote_ident(TG_TABLE_SCHEMA);
	thetable text := quote_ident(TG_TABLE_NAME);
	theidtablelocation int;
	theuuidfieldname character varying(50);
	theuuid uuid;
  thecomment text := 'auto = default value';
BEGIN
	--retrouver l'id de la table source stockant l'enregistrement en cours de validation
	SELECT INTO theidtablelocation gn_commons.get_table_location_id(theschema,thetable);
  --retouver le nom du champ stockant l'uuid de l'enregistrement en cours de validation
	SELECT INTO theuuidfieldname gn_commons.get_uuid_field_name(theschema,thetable);
  --récupérer l'uuid de l'enregistrement en cours de validation
	EXECUTE format('SELECT $1.%I', theuuidfieldname) INTO theuuid USING NEW;
  --insertion du statut de validation et des informations associées dans t_validations
  INSERT INTO gn_commons.t_validations (id_table_location,uuid_attached_row,id_nomenclature_valid_status,id_validator,validation_comment,validation_date)
  VALUES(
    theidtablelocation,
    theuuid,
    ref_nomenclatures.get_default_nomenclature_value('STATUT_VALID'), --comme la fonction est générique, cette valeur par défaut doit exister et est la même pour tous les modules
    null,
    thecomment,
    NOW()
  );
  RETURN NEW;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

--suppression du champ id_area inutile (gestion en nn dans cor_area_synthese)
ALTER TABLE gn_synthese.synthese DROP COLUMN id_area;
