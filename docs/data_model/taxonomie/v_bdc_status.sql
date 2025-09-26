

CREATE VIEW taxonomie.v_bdc_status AS
 SELECT s.cd_nom,
    s.cd_ref,
    s.rq_statut,
    v.code_statut,
    v.label_statut,
    t.cd_type_statut,
    ty.thematique,
    ty.lb_type_statut,
    ty.regroupement_type,
    t.cd_st_text,
    t.cd_sig,
    t.cd_doc,
    t.niveau_admin,
    t.cd_iso3166_1,
    t.cd_iso3166_2,
    t.full_citation,
    t.doc_url,
    ty.type_value
   FROM ((((taxonomie.bdc_statut_taxons s
     JOIN taxonomie.bdc_statut_cor_text_values c ON ((s.id_value_text = c.id_value_text)))
     JOIN taxonomie.bdc_statut_text t ON ((t.id_text = c.id_text)))
     JOIN taxonomie.bdc_statut_values v ON ((v.id_value = c.id_value)))
     JOIN taxonomie.bdc_statut_type ty ON (((ty.cd_type_statut)::text = (t.cd_type_statut)::text)))
  WHERE (t.enable = true);


