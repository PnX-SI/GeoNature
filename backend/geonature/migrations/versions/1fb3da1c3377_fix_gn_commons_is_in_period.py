"""Fix function gn_commons.is_in_period

Revision ID: 1fb3da1c3377
Revises: 1ca1e8ec50f4
Create Date: 2026-08-12 16:53:58.435778

"""

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "1fb3da1c3377"
down_revision = "1ca1e8ec50f4"
branch_labels = None
depends_on = None


def upgrade():
    """Redefine the utility function gn_commons.is_in_period
    to use the string representation 'MM-DD' of dates objects,
    so it handles both leap and non-leap years correctly."""
    op.execute("""
        CREATE OR REPLACE FUNCTION gn_commons.is_in_period(dateobs date, datebegin date, dateend date)
         RETURNS boolean
         LANGUAGE plpgsql
         IMMUTABLE
        AS $function$
        DECLARE
        day_obs char(5);
        begin_day char(5);
        end_day char(5);
        -- Function to check if a date (dateobs) is in a period (datebegin, dateend)
        -- USAGE : SELECT gn_commons.is_in_period(dateobs, datebegin, dateend);
        BEGIN
        day_obs = to_char(dateobs, 'MM-DD');--jour de la date passée
        begin_day = to_char(datebegin, 'MM-DD');--jour début
        end_day = to_char(dateend, 'MM-DD'); --jour fin
        -- si on est sur 2 années
        IF begin_day > end_day then
            RETURN day_obs <= end_day OR day_obs >= begin_day;
        -- si on est dans la même année
        else 
            RETURN day_obs >= begin_day AND day_obs <= end_day;
        END IF;
        END;
        $function$
        ;
    """)


def downgrade():
    """Redefine the utility function gn_commons.is_in_period
    the way it was, using DOY to calculate period appartenance.
    This version only works with leap years."""
    op.execute("""
        CREATE OR REPLACE FUNCTION gn_commons.is_in_period(dateobs date, datebegin date, dateend date)
         RETURNS boolean
         LANGUAGE plpgsql
         IMMUTABLE
        AS $function$
        DECLARE
        day_obs int;
        begin_day int;
        end_day int;
        test int; 
        -- Function to check if a date (dateobs) is in a period (datebegin, dateend)
        -- USAGE : SELECT gn_commons.is_in_period(dateobs, datebegin, dateend);
        BEGIN
        day_obs = extract(doy FROM dateobs);--jour de la date passée
        begin_day = extract(doy FROM datebegin);--jour début
        end_day = extract(doy FROM dateend); --jour fin
        test = end_day - begin_day; --test si la période est sur 2 année ou pas
        -- si on est sur 2 années
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
        $function$
        ;
    """)