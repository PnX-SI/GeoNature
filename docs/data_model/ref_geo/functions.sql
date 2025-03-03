CREATE OR REPLACE FUNCTION ref_geo.fct_get_altitude_intersection(mygeom geometry)
 RETURNS TABLE(altitude_min integer, altitude_max integer)
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
            DECLARE
                thesrid int;
                is_vectorized int;
            BEGIN
              SELECT Find_SRID('ref_geo', 'l_areas', 'geom')
              INTO thesrid;

              SELECT COALESCE(gid, NULL)
              FROM ref_geo.dem_vector
              LIMIT 1
              INTO is_vectorized;

            IF is_vectorized IS NULL AND st_geometrytype(myGeom) = 'ST_Point' THEN
               -- Use dem and st_value function
                RETURN QUERY WITH alt AS (
                    SELECT st_value(rast, public.st_transform(myGeom, thesrid))::int altitude
                    FROM ref_geo.dem AS altitude
                    WHERE public.st_intersects(rast, public.st_transform(myGeom, thesrid))
                )
                SELECT min(altitude) AS altitude_min, max(altitude) AS altitude_max
                FROM alt;
            ELSIF is_vectorized IS NULL THEN
                -- Use dem ans st_intersection function
                RETURN QUERY
                SELECT min((altitude).val)::integer AS altitude_min, max((altitude).val)::integer AS altitude_max
                FROM (
                    SELECT public.ST_Intersection(
                        rast,
                        public.ST_Transform(myGeom, thesrid)
                    ) AS altitude
                    FROM ref_geo.dem AS altitude
                    WHERE public.ST_Intersects(rast,public.ST_Transform(myGeom, thesrid))
                ) AS a;
              -- Use dem_vector
            ELSE
                RETURN QUERY
                WITH d AS (
                    SELECT public.ST_Transform(myGeom,thesrid) a
                 )
                SELECT min(val)::int AS altitude_min, max(val)::int AS altitude_max
                FROM ref_geo.dem_vector, d
                WHERE public.ST_Intersects(a,geom);
              END IF;
            END;

        $function$

CREATE OR REPLACE FUNCTION ref_geo.fct_get_area_intersection(mygeom geometry, myidtype integer DEFAULT NULL::integer)
 RETURNS TABLE(id_area integer, id_type integer, area_code character varying, area_name character varying)
 LANGUAGE plpgsql
AS $function$
    DECLARE
      isrid int;
    BEGIN
      SELECT Find_SRID('ref_geo', 'l_areas', 'geom') INTO isrid;
      RETURN QUERY
      WITH d  as (
          SELECT public.st_transform(myGeom,isrid) geom_trans
      )
      SELECT a.id_area, a.id_type, a.area_code, a.area_name
      FROM ref_geo.l_areas a, d
      WHERE public.st_intersects(geom_trans, a.geom)
        AND (myIdType IS NULL OR a.id_type = myIdType)
        AND enable=true;
    END;
    $function$

CREATE OR REPLACE FUNCTION ref_geo.fct_trg_calculate_alt_minmax()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
        DECLARE
            the4326geomcol text := quote_ident(TG_ARGV[0]);
        thelocalsrid int;
        BEGIN
        -- si c'est un insert et que l'altitude min ou max est null -> on calcule
        IF (TG_OP = 'INSERT' and (new.altitude_min IS NULL or new.altitude_max IS NULL)) THEN
            --récupérer le srid local
            SELECT Find_SRID('ref_geo', 'l_areas', 'geom') INTO thelocalsrid;
            --Calcul de l'altitude
            SELECT (ref_geo.fct_get_altitude_intersection(st_transform(hstore(NEW)-> the4326geomcol,thelocalsrid))).*  INTO NEW.altitude_min, NEW.altitude_max;
        -- si c'est un update et que la geom a changé
        -- on vérifie que les altitude ne sont pas null
        -- OU si les altitudes ont changé, si oui =  elles ont déjà été calculés - on ne relance pas le calcul
        ELSIF (
                TG_OP = 'UPDATE' 
                AND NOT public.ST_EQUALS(hstore(OLD)-> the4326geomcol, hstore(NEW)-> the4326geomcol)
                and (new.altitude_min = old.altitude_max or new.altitude_max = old.altitude_max)
                and not(new.altitude_min is null or new.altitude_max is null)
                ) then
            --récupérer le srid local
            SELECT Find_SRID('ref_geo', 'l_areas', 'geom') INTO thelocalsrid;
            --Calcul de l'altitude
            SELECT (ref_geo.fct_get_altitude_intersection(st_transform(hstore(NEW)-> the4326geomcol,thelocalsrid))).*  INTO NEW.altitude_min, NEW.altitude_max;
        END IF;
        RETURN NEW;
        END;
        $function$

CREATE OR REPLACE FUNCTION ref_geo.fct_trg_calculate_geom_local()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    DECLARE
        the4326geomcol text := quote_ident(TG_ARGV[0]);
        thelocalgeomcol text := quote_ident(TG_ARGV[1]);
            thelocalsrid int;
            thegeomlocalvalue public.geometry;
            thegeomchange boolean;
    BEGIN
        -- si c'est un insert ou que c'est un UPDATE ET que le geom_4326 a été modifié
        IF (TG_OP = 'INSERT' OR (TG_OP = 'UPDATE' AND NOT public.ST_EQUALS(hstore(OLD)-> the4326geomcol, hstore(NEW)-> the4326geomcol)  )) THEN
            --récupérer le srid local
            SELECT Find_SRID('ref_geo', 'l_areas', 'geom') INTO thelocalsrid;
            EXECUTE FORMAT ('SELECT public.ST_TRANSFORM($1.%I, $2)',the4326geomcol) INTO thegeomlocalvalue USING NEW, thelocalsrid;
                    -- insertion dans le NEW de la geom transformée
            NEW := NEW#= hstore(thelocalgeomcol, thegeomlocalvalue);
        END IF;
      RETURN NEW;
    END;
    $function$

CREATE OR REPLACE FUNCTION ref_geo.fct_tri_transform_geom()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
            DECLARE
              local_srid integer;
              c integer;
            BEGIN
              IF (TG_OP = 'INSERT') THEN
                -- Insert policy: we set geom from geom_4326 if geom is null and geom_4326 is not null, and reciprocally.
                -- If both geom and geom_4326 have been set (or both are null), we do nothing.
                IF (NEW.geom IS NULL AND NEW.geom_4326 IS NOT NULL) THEN
                  NEW.geom = ST_Transform(NEW.geom_4326, local_srid);
                  RAISE NOTICE '(I) Updated geom';
                ELSEIF (NEW.geom IS NOT NULL AND NEW.geom_4326 IS NULL) THEN
                  NEW.geom_4326 = ST_Transform(NEW.geom, 4326);
                  RAISE NOTICE '(I) Updated geom_4326';
                END IF;
              ELSEIF (TG_OP = 'UPDATE') THEN
                -- Update policy: we set geom from geom_4326 if geom_4326 have been updated to non null value,
                -- unless geom have also been modified to non null value, and reciprocally.
                -- We also set geom from geom_4326 if geom is modified to null, and geom_4326 is not null (modified or not),
                -- in order to be consistent when updating one or two columns at the same time.
                IF (
                  NEW.geom_4326 IS NOT NULL
                  AND
                  (
                    (OLD.geom IS NOT DISTINCT FROM NEW.geom AND OLD.geom_4326 IS DISTINCT FROM NEW.geom_4326)
                    OR
                    (NEW.geom IS NULL AND OLD.geom IS NOT NULL)
                  )
                ) THEN
                  SELECT INTO local_srid Find_SRID('ref_geo', 'l_areas', 'geom');
                  NEW.geom = ST_Transform(NEW.geom_4326, local_srid);
                  RAISE NOTICE '(U) Updated geom';
                ELSEIF (
                  NEW.geom IS NOT NULL
                  AND
                  (
                    (OLD.geom_4326 IS NOT DISTINCT FROM NEW.geom_4326 AND OLD.geom IS DISTINCT FROM NEW.geom)
                    OR
                    (NEW.geom_4326 IS NULL AND OLD.geom_4326 IS NOT NULL)
                  )
                ) THEN
                  NEW.geom_4326 = ST_Transform(NEW.geom, 4326);
                  RAISE NOTICE '(U) Updated geom_4326';
                END IF;
              END IF;
              RETURN NEW;
            END;
          $function$

CREATE OR REPLACE FUNCTION ref_geo.get_id_area_type(mytype character varying)
 RETURNS integer
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
--Function which return the id_type_area from the type_code of an area type
DECLARE theidtype character varying;
  BEGIN
SELECT INTO theidtype id_type FROM ref_geo.bib_areas_types WHERE type_code = mytype;
return theidtype;
  END;
$function$

