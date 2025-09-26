

CREATE VIEW gn_synthese.v_tree_taxons_synthese AS
 WITH cd_famille AS (
         SELECT t_1.cd_ref,
            t_1.lb_nom AS nom_latin,
            t_1.nom_vern AS nom_francais,
            t_1.cd_nom,
            t_1.id_rang,
            t_1.regne,
            t_1.phylum,
            t_1.classe,
            t_1.ordre,
            t_1.famille,
            t_1.lb_nom
           FROM taxonomie.taxref t_1
          WHERE ((t_1.lb_nom)::text IN ( SELECT DISTINCT t_2.famille
                   FROM (gn_synthese.synthese s
                     JOIN taxonomie.taxref t_2 ON ((t_2.cd_nom = s.cd_nom)))))
        ), cd_regne AS (
         SELECT DISTINCT taxref.cd_nom,
            taxref.regne
           FROM taxonomie.taxref
          WHERE (((taxref.id_rang)::text = 'KD'::text) AND (taxref.cd_nom = taxref.cd_ref))
        )
 SELECT t.cd_ref,
    t.nom_latin,
    t.nom_francais,
    t.id_regne,
    t.nom_regne,
    COALESCE(t.id_embranchement, t.id_regne) AS id_embranchement,
    COALESCE(t.nom_embranchement, ' Sans embranchement dans taxref'::character varying) AS nom_embranchement,
    COALESCE(t.id_classe, t.id_embranchement) AS id_classe,
    COALESCE(t.nom_classe, ' Sans classe dans taxref'::character varying) AS nom_classe,
    COALESCE(t.desc_classe, ' Sans classe dans taxref'::character varying) AS desc_classe,
    COALESCE(t.id_ordre, t.id_classe) AS id_ordre,
    COALESCE(t.nom_ordre, ' Sans ordre dans taxref'::character varying) AS nom_ordre
   FROM ( SELECT DISTINCT t_1.cd_ref,
            t_1.nom_latin,
            t_1.nom_francais,
            ( SELECT DISTINCT r.cd_nom
                   FROM cd_regne r
                  WHERE ((r.regne)::text = (t_1.regne)::text)) AS id_regne,
            t_1.regne AS nom_regne,
            ph.cd_nom AS id_embranchement,
            t_1.phylum AS nom_embranchement,
            t_1.phylum AS desc_embranchement,
            cl.cd_nom AS id_classe,
            t_1.classe AS nom_classe,
            t_1.classe AS desc_classe,
            ord.cd_nom AS id_ordre,
            t_1.ordre AS nom_ordre
           FROM (((cd_famille t_1
             LEFT JOIN taxonomie.taxref ph ON ((((ph.id_rang)::text = 'PH'::text) AND (ph.cd_nom = ph.cd_ref) AND ((ph.lb_nom)::text = (t_1.phylum)::text) AND (NOT (t_1.phylum IS NULL)))))
             LEFT JOIN taxonomie.taxref cl ON ((((cl.id_rang)::text = 'CL'::text) AND (cl.cd_nom = cl.cd_ref) AND ((cl.lb_nom)::text = (t_1.classe)::text) AND (NOT (t_1.classe IS NULL)))))
             LEFT JOIN taxonomie.taxref ord ON ((((ord.id_rang)::text = 'OR'::text) AND (ord.cd_nom = ord.cd_ref) AND ((ord.lb_nom)::text = (t_1.ordre)::text) AND (NOT (t_1.ordre IS NULL)))))) t
  ORDER BY t.id_regne, COALESCE(t.id_embranchement, t.id_regne), COALESCE(t.id_classe, t.id_embranchement), COALESCE(t.id_ordre, t.id_classe);

COMMENT ON VIEW gn_synthese.v_tree_taxons_synthese IS 'Vue destinée à l''arbre taxonomique de la synthese. S''arrête  à la famille pour des questions de performances';


