

CREATE MATERIALIZED VIEW taxonomie.vm_regne AS
 SELECT DISTINCT tx.regne
   FROM taxonomie.taxref tx
  WITH NO DATA;

CREATE UNIQUE INDEX i_unique_regne ON taxonomie.vm_regne USING btree (regne);


