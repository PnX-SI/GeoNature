
CREATE MATERIALIZED VIEW taxonomie.vm_famille AS
 SELECT DISTINCT tx.famille
   FROM taxonomie.taxref tx
  WITH NO DATA;

CREATE UNIQUE INDEX i_unique_famille ON taxonomie.vm_famille USING btree (famille);

