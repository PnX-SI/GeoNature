
\restrict 7N0oFh6Y75hVLP3M1f7BDBZcTk0aoeO55IQnGdfF7Xg1Tag3QIa0sSXoBRpEjxR

CREATE MATERIALIZED VIEW taxonomie.vm_phylum AS
 SELECT DISTINCT tx.phylum
   FROM taxonomie.taxref tx
  WITH NO DATA;

CREATE UNIQUE INDEX i_unique_phylum ON taxonomie.vm_phylum USING btree (phylum);

\unrestrict 7N0oFh6Y75hVLP3M1f7BDBZcTk0aoeO55IQnGdfF7Xg1Tag3QIa0sSXoBRpEjxR

