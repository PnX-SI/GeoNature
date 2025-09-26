
\restrict m3SN25rivorHdbf0bqp5lbXk2jHUeoMNeNAGefxDaNiD1ThNNpQfFpqgZdaFgC5

CREATE MATERIALIZED VIEW taxonomie.vm_taxref_tree AS
 WITH RECURSIVE biota AS (
         SELECT t.cd_nom,
            ((t.cd_ref)::text)::public.ltree AS path
           FROM taxonomie.taxref t
          WHERE (t.cd_nom = 349525)
        UNION ALL
         SELECT child.cd_nom,
            (parent.path OPERATOR(public.||) (child.cd_ref)::text) AS path
           FROM ((taxonomie.taxref child
             JOIN taxonomie.taxref child_ref ON ((child.cd_ref = child_ref.cd_nom)))
             JOIN biota parent ON ((parent.cd_nom = child_ref.cd_sup)))
        ), orphans AS (
         SELECT t.cd_nom,
            ((t.cd_ref)::text)::public.ltree AS path
           FROM ((taxonomie.taxref t
             JOIN taxonomie.taxref t_ref ON ((t.cd_ref = t_ref.cd_nom)))
             LEFT JOIN taxonomie.taxref parent ON (((t_ref.cd_sup = parent.cd_nom) AND (parent.cd_nom <> t_ref.cd_nom))))
          WHERE (parent.cd_nom IS NULL)
        )
 SELECT biota.cd_nom,
    biota.path
   FROM biota
UNION
 SELECT orphans.cd_nom,
    orphans.path
   FROM orphans
  WITH NO DATA;

CREATE UNIQUE INDEX taxref_tree_cd_nom_idx ON taxonomie.vm_taxref_tree USING btree (cd_nom);

CREATE INDEX taxref_tree_path_idx ON taxonomie.vm_taxref_tree USING gist (path);

\unrestrict m3SN25rivorHdbf0bqp5lbXk2jHUeoMNeNAGefxDaNiD1ThNNpQfFpqgZdaFgC5

