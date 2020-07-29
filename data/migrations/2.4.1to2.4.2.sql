--Ne plus modifier meta_date_create lors d'un UPDATE
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

--Ne plus exectuer le trigger à l'INSERT
DROP TRIGGER tri_meta_dates_change_synthese ON gn_synthese.synthese;
CREATE TRIGGER tri_meta_dates_change_synthese
  BEFORE UPDATE
  ON gn_synthese.synthese
  FOR EACH ROW
  EXECUTE PROCEDURE public.fct_trg_meta_dates_change();
