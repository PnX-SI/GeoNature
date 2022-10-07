"""fix altitude trigger

Revision ID: 681306b27407
Revises: 4882d6141a41
Create Date: 2021-11-30 14:48:23.458154

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "681306b27407"
down_revision = "4882d6141a41"
branch_labels = None
depends_on = None


def upgrade():
    op.execute(
        """
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
        ;
        """
    )


def downgrade():
    op.execute(
        """
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
        ELSIF (TG_OP = 'UPDATE' AND NOT public.ST_EQUALS(hstore(OLD)-> the4326geomcol, hstore(NEW)-> the4326geomcol)) then
            -- on vérifie que les altitude ne sont pas null 
            -- OU si les altitudes ont changé, si oui =  elles ont déjà été calculés - on ne relance pas le calcul
            IF (new.altitude_min is null or new.altitude_max is null) OR (NOT OLD.altitude_min = NEW.altitude_min or NOT OLD.altitude_max = OLD.altitude_max) THEN 
                --récupérer le srid local	
                SELECT Find_SRID('ref_geo', 'l_areas', 'geom') INTO thelocalsrid;
                --Calcul de l'altitude
                SELECT (ref_geo.fct_get_altitude_intersection(st_transform(hstore(NEW)-> the4326geomcol,thelocalsrid))).*  INTO NEW.altitude_min, NEW.altitude_max;
            end IF;
        else 
        END IF;
        RETURN NEW;
        END;
        $function$
        ;
        """
    )
