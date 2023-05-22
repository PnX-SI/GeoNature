CREATE EXTENSION IF NOT EXISTS "hstore";
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";
CREATE EXTENSION IF NOT EXISTS "unaccent";

-- postgis

CREATE EXTENSION IF NOT EXISTS "postgis";

-- check if postgis_raster is available
DO
$$
BEGIN
    IF EXISTS (
        SELECT name FROM PG_CATALOG.PG_AVAILABLE_EXTENSIONS WHERE name = 'postgis_raster'
    ) THEN
        CREATE EXTENSION IF NOT EXISTS "postgis_raster";
    END IF;
END
$$