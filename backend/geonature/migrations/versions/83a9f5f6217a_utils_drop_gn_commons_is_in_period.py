"""[utils] drop gn_commons.is_in_period

Revision ID: 83a9f5f6217a
Revises: 0444c425fa27
Create Date: 2026-08-20 17:35:30.568373

"""

from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision = "83a9f5f6217a"
down_revision = "0444c425fa27"
branch_labels = None
depends_on = None


def upgrade():
    op.execute("DROP FUNCTION IF EXISTS gn_commons.is_in_period;")


def downgrade():
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
    $function$
    ;
""")
