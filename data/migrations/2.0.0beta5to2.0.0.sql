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


--Passage de t_parameters en serial
CREATE SEQUENCE gn_commons.t_parameters_id_parameter_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE gn_commons.t_parameters_id_parameter_seq OWNED BY gn_commons.t_parameters.id_parameter;
ALTER TABLE ONLY gn_commons.t_parameters ALTER COLUMN id_parameter SET DEFAULT nextval('gn_commons.t_parameters_id_parameter_seq'::regclass);
SELECT pg_catalog.setval('gn_commons.t_parameters_id_parameter_seq', (SELECT max(id_parameter)+1 FROM gn_commons.t_parameters), false);


-- modification de la table gn_commons.t_modules
ALTER TABLE gn_commons.t_modules RENAME COLUMN module_url TO module_path;
ALTER TABLE gn_commons.t_modules ADD COLUMN module_external_url character varying(255);

-- passage a fontawesome
UPDATE gn_commons.t_modules SET module_picto = 
CASE 
  WHEN module_picto='extension' THEN 'fa-puzzle-piece'
  WHEN module_picto='place' THEN 'fa-map-marker'
  WHEN module_picto='file_download' THEN 'fa-download'
END;

UPDATE gn_commons.t_modules SET module_path = 
CASE 
  WHEN module_name='occtax' THEN 'occtax'
  WHEN module_name='admin' THEN 'admin'
  WHEN module_name='suivi_chiro' THEN 'suivi_chiro'
  WHEN module_name='suivi_flore_territoire' THEN 'suivi_flore_territoire'
END;

------------------------------
----- UPDATE REF_GEO ---------
------------------------------

-- Passage de ref_geo.bib_areas_types.id_type en serial

CREATE SEQUENCE ref_geo.bib_areas_types_id_type_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE ref_geo.bib_areas_types_id_type_seq OWNED BY ref_geo.bib_areas_types.id_type;
ALTER TABLE ONLY ref_geo.bib_areas_types ALTER COLUMN id_type SET DEFAULT nextval('ref_geo.bib_areas_types_id_type_seq'::regclass);
SELECT pg_catalog.setval('ref_geo.bib_areas_types_id_type_seq', (SELECT max(id_type)+1 FROM ref_geo.bib_areas_types), false);	
	

-- Création d'une fonction pour retrouver l'id_type d'un type de zonage à partir de son code

CREATE OR REPLACE FUNCTION ref_geo.get_id_area_type(mytype character varying)
  RETURNS integer AS
$BODY$
--Function which return the id_type_area from the type_code of an area type
DECLARE theidtype character varying;
  BEGIN
SELECT INTO theidtype id_type FROM ref_geo.bib_areas_types WHERE type_code = mytype;
return theidtype;
  END;
$BODY$
  LANGUAGE plpgsql IMMUTABLE
  COST 100;

-- Ajout de codes pour tous les bib_areas_types

UPDATE ref_geo.bib_areas_types SET type_code = 'ZNIEFF2' WHERE type_name = 'ZNIEFF2';
UPDATE ref_geo.bib_areas_types SET type_code = 'ZNIEFF1' WHERE type_name = 'ZNIEFF1';
UPDATE ref_geo.bib_areas_types SET type_code = 'APB' WHERE type_name = 'Aires de protection de biotope';
UPDATE ref_geo.bib_areas_types SET type_code = 'RNN' WHERE type_name = 'Réserves naturelles nationales';
UPDATE ref_geo.bib_areas_types SET type_code = 'RNR' WHERE type_name = 'Réserves naturelles regionales';
UPDATE ref_geo.bib_areas_types SET type_code = 'RNCFS' WHERE type_name = 'Réserves nationales de chasse et faune sauvage';
UPDATE ref_geo.bib_areas_types SET type_code = 'RIPN' WHERE type_name = 'Réserves intégrales de parc national';
UPDATE ref_geo.bib_areas_types SET type_code = 'SCEN' WHERE type_name = 'Sites acquis des Conservatoires d''espaces naturels';
UPDATE ref_geo.bib_areas_types SET type_code = 'SCL' WHERE type_name = 'Sites du Conservatoire du Littoral';
UPDATE ref_geo.bib_areas_types SET type_code = 'PNM' WHERE type_name = 'Parcs naturels marins';
UPDATE ref_geo.bib_areas_types SET type_code = 'RBIOL' WHERE type_name = 'Réserves biologiques';
UPDATE ref_geo.bib_areas_types SET type_code = 'RBIOS' WHERE type_name = 'Réserves de biosphère';
UPDATE ref_geo.bib_areas_types SET type_code = 'RNC' WHERE type_name = 'Réserves naturelles de Corse';
UPDATE ref_geo.bib_areas_types SET type_code = 'SRAM' WHERE type_name = 'Sites Ramsar';
UPDATE ref_geo.bib_areas_types SET type_code = 'UG' WHERE type_name = 'Unités géographiques';
UPDATE ref_geo.bib_areas_types SET type_code = 'COM' WHERE type_name = 'Communes';
UPDATE ref_geo.bib_areas_types SET type_code = 'DEP' WHERE type_name = 'Départements';
UPDATE ref_geo.bib_areas_types SET type_code = 'M10' WHERE type_name = 'Mailles10*10';
UPDATE ref_geo.bib_areas_types SET type_code = 'M1' WHERE type_name = 'Mailles1*1';
UPDATE ref_geo.bib_areas_types SET type_code = 'SEC' WHERE type_name = 'Secteurs';
UPDATE ref_geo.bib_areas_types SET type_code = 'MAS' WHERE type_name = 'Massifs';
UPDATE ref_geo.bib_areas_types SET type_code = 'ZBIOG' WHERE type_name = 'Zones biogéographiques';

-- Ajustement des descriptions de certains bib_areas_types

UPDATE ref_geo.bib_areas_types SET type_desc = 'Type commune' WHERE type_name = 'Communes';
UPDATE ref_geo.bib_areas_types SET type_desc = 'Type département' WHERE type_name = 'Départements';
UPDATE ref_geo.bib_areas_types SET type_desc = 'Type maille INPN 10*10km' WHERE type_name = 'Mailles10*10';
UPDATE ref_geo.bib_areas_types SET type_desc = 'Type maille INPN 1*1km' WHERE type_name = 'Mailles1*1';

-- Passage de type_name et type_code en NOT NULL dans bib_areas_types

ALTER TABLE ref_geo.bib_areas_types
    ALTER COLUMN type_name SET NOT NULL, 
	ALTER COLUMN type_code SET NOT NULL;
