

CREATE MATERIALIZED VIEW taxonomie.vm_ordre AS
 SELECT DISTINCT tx.ordre
   FROM taxonomie.taxref tx
  WITH NO DATA;

CREATE UNIQUE INDEX i_unique_ordre ON taxonomie.vm_ordre USING btree (ordre);


