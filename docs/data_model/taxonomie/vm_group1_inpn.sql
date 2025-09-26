

CREATE MATERIALIZED VIEW taxonomie.vm_group1_inpn AS
 SELECT DISTINCT tx.group1_inpn
   FROM taxonomie.taxref tx
  WITH NO DATA;

CREATE UNIQUE INDEX i_unique_group1_inpn ON taxonomie.vm_group1_inpn USING btree (group1_inpn);


