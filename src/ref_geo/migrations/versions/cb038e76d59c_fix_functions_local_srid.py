"""fix functions local srid

Revision ID: cb038e76d59c
Revises: 681306b27407
Create Date: 2022-05-02 10:45:54.662631

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "cb038e76d59c"
down_revision = "681306b27407"
branch_labels = None
depends_on = None


def upgrade():
    op.execute(
        """
    CREATE OR REPLACE FUNCTION ref_geo.fct_trg_calculate_geom_local()
      RETURNS trigger AS
    -- trigger qui reprojete une geom a partir d'une geom source fournie et l'insert dans le NEW
    -- en prenant le srid local (srid de la colonne ref_geo.l_areas.geom)
    -- 1er param: nom de la colonne source
    -- 2eme param: nom de la colonne a reprojeter
    -- utiliser pour calculer les geom_local à partir des geom_4326
    $BODY$
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
    $BODY$
      LANGUAGE plpgsql VOLATILE
      COST 100;
    """
    )
    op.execute(
        """
    CREATE OR REPLACE FUNCTION ref_geo.fct_get_altitude_intersection(IN mygeom public.geometry)
      RETURNS TABLE(altitude_min integer, altitude_max integer) AS
    $BODY$
    DECLARE
        thesrid int;
        is_vectorized int;
    BEGIN
      SELECT Find_SRID('ref_geo', 'l_areas', 'geom') INTO thesrid;
      SELECT COALESCE(gid, NULL) FROM ref_geo.dem_vector LIMIT 1 INTO is_vectorized;

      IF is_vectorized IS NULL THEN
        -- Use dem
        RETURN QUERY
        SELECT min((altitude).val)::integer AS altitude_min, max((altitude).val)::integer AS altitude_max
        FROM (
        SELECT public.ST_DumpAsPolygons(public.ST_clip(
        rast,
        1,
          public.st_transform(myGeom,thesrid),
        true)
      ) AS altitude
        FROM ref_geo.dem AS altitude
        WHERE public.st_intersects(rast,public.st_transform(myGeom,thesrid))
        ) AS a;
      -- Use dem_vector
      ELSE
        RETURN QUERY
        WITH d  as (
            SELECT public.st_transform(myGeom,thesrid) a
         )
        SELECT min(val)::int as altitude_min, max(val)::int as altitude_max
        FROM ref_geo.dem_vector, d
        WHERE public.st_intersects(a,geom);
      END IF;
    END;
    $BODY$
      LANGUAGE plpgsql VOLATILE
      COST 100
      ROWS 1000;
    """
    )
    op.execute(
        """
    CREATE OR REPLACE FUNCTION ref_geo.fct_get_area_intersection(
      IN mygeom public.geometry,
      IN myidtype integer DEFAULT NULL::integer)
    RETURNS TABLE(id_area integer, id_type integer, area_code character varying, area_name character varying) AS
    $BODY$
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
    $BODY$
    LANGUAGE plpgsql VOLATILE
    COST 100
    ROWS 1000;
    """
    )


def downgrade():
    pass
