CREATE OR REPLACE FUNCTION ref_habitats.is_communitarian(my_cd_hab integer)
 RETURNS boolean
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
--fonction permettant de savoir si un habitat est communautaire
  DECLARE is_com integer;
  BEGIN
    SELECT INTO is_com count(*)
    FROM ref_habitats.habref hab
    JOIN ref_habitats.typoref typ ON hab.cd_typo = typ.cd_typo
    WHERE typ.cd_table = 'TYPO_HIC' 
    AND hab.cd_hab = my_cd_hab;
    RETURN is_com = 1;
 END;
$function$

