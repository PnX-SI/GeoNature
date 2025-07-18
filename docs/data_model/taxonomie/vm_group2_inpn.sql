
CREATE MATERIALIZED VIEW taxonomie.vm_group2_inpn AS
 SELECT DISTINCT tx.group2_inpn
   FROM taxonomie.taxref tx
  WITH NO DATA;

CREATE UNIQUE INDEX i_unique_group2_inpn ON taxonomie.vm_group2_inpn USING btree (group2_inpn);

