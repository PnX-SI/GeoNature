SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
--SET row_security = off;

SET search_path = public, pg_catalog;

--------------------
--PUBLIC FUNCTIONS--
--------------------
CREATE OR REPLACE FUNCTION public.fct_trg_meta_dates_change()
  RETURNS trigger AS
$BODY$
begin
        IF(TG_OP = 'UPDATE') THEN
                NEW.meta_update_date = NOW();
        end IF;
        return NEW;
end;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
