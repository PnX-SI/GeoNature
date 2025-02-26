CREATE OR REPLACE FUNCTION pr_occhab.get_default_nomenclature_value(mytype character varying, myidorganism integer DEFAULT 0)
 RETURNS integer
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
        --Function that return the default nomenclature id with wanteds nomenclature type, organism id
        --Return -1 if nothing matche with given parameters
          DECLARE
            thenomenclatureid integer;
          BEGIN
              SELECT INTO thenomenclatureid id_nomenclature
              FROM (
              	SELECT
              	  n.id_nomenclature,
              	  CASE
        	        WHEN n.id_organism = myidorganism THEN 1
                    ELSE 0
                  END prio_organisme
                FROM
                  pr_occhab.defaults_nomenclatures_value n
                JOIN
                  utilisateurs.bib_organismes o ON o.id_organisme = n.id_organism
                WHERE
                  mnemonique_type = mytype
                  AND (n.id_organism = myidorganism OR o.nom_organisme = 'ALL')
              ) AS defaults_nomenclatures_value
              ORDER BY prio_organisme DESC LIMIT 1;
             
            RETURN thenomenclatureid;
          END;
        $function$

