

CREATE MATERIALIZED VIEW taxonomie.vm_phylum AS
 SELECT DISTINCT tx.phylum
   FROM taxonomie.taxref tx
  WITH NO DATA;

CREATE UNIQUE INDEX i_unique_phylum ON taxonomie.vm_phylum USING btree (phylum);


