-- Script added by Adrien Pajot, 1/09/2021
-- From this discussion I took the makegrid_2d function : https://gis.stackexchange.com/questions/16374/creating-regular-polygon-grid-in-postgis
-- More about this topic : https://github.com/imran-5/Postgis-Custom

-- First create the function 
drop function public.makegrid_2d;

CREATE OR REPLACE FUNCTION public.makegrid_2d (
  bound_polygon public.geometry, metersx int, metersy int
  ) -- metersx and metersy are the dimension in meter you want to set in x and y (width and height)
RETURNS public.geometry AS
$body$
DECLARE
  Xmin DOUBLE PRECISION;
  Xmax DOUBLE PRECISION;
  Ymax DOUBLE PRECISION;
  X DOUBLE PRECISION;
  Y DOUBLE PRECISION;
  NextX DOUBLE PRECISION;
  NextY DOUBLE PRECISION;
  CPoint public.geometry;
  sectors public.geometry[];
  i INTEGER;
  SRID INTEGER;
BEGIN
  Xmin := ST_XMin(bound_polygon);
  Xmax := ST_XMax(bound_polygon);
  Ymax := ST_YMax(bound_polygon);
  SRID := ST_SRID(bound_polygon);

  Y := ST_YMin(bound_polygon); --current sector's corner coordinate
  i := -1;
  <<yloop>>
  LOOP
    IF (Y > Ymax) THEN  
        EXIT;
    END IF;

    X := Xmin;
    <<xloop>>
    LOOP
      IF (X > Xmax) THEN
          EXIT;
      END IF;

      CPoint := ST_SetSRID(ST_MakePoint(X, Y), SRID);
      NextX := ST_X(ST_Project(CPoint, metersx, radians(90))::geometry); 
      NextY := ST_Y(ST_Project(CPoint, metersy, radians(0))::geometry);

      i := i + 1;
      sectors[i] := ST_MakeEnvelope(X, Y, NextX, NextY, SRID);

      X := NextX;
    END LOOP xloop;
    CPoint := ST_SetSRID(ST_MakePoint(X, Y), SRID);
    NextY := ST_Y(ST_Project(CPoint, metersy, radians(0))::geometry);
    Y := NextY;
  END LOOP yloop;

  RETURN ST_Collect(sectors);
END;
$body$
LANGUAGE 'plpgsql';

-- Then, test if it creates well the grid inside the  it inside the polygon of your area (coming from l_areas)
  
SELECT (
    ST_Dump(
      makegrid_2d(
       (SELECT st_transform(geom, 4326) FROM ref_geo.l_areas WHERE id_type=23), 10000,5000) 
    )
  ) .geom AS cell;
 

-- Then store it inside the l_areas table 
   
INSERT INTO ref_geo.l_areas(id_type,
geom) 
SELECT 27 AS id_type, --the id_type value depends of the size of your mesh, here it is for 10x10 grids
    ST_Multi(st_transform((ST_Dump(
      makegrid_2d(
       (SELECT st_transform(geom, 4326) FROM ref_geo.l_areas WHERE id_type=23),
         1000, -- width step in meters
         1000  -- height step in meters
       ) 
    )
  ) .geom, 2154)) ;
 
-- Will be more intersting to put more data if needed, in the creation of the grid function. 

-- Now, manually DROP index_l_areas_geom and then recreate it

CREATE INDEX index_l_areas_geom ON ref_geo.l_areas USING gist (geom);

-- You are now ready to play with your your new meshs. If you already have a ref_geo in your GeoNature, don't hesitate to set_enable=false to the previous ones
