
\restrict XadlbnQ77v4qU5tWm7uigEAPFkx4y9BkaYVFPfLKVnbscyMVYa1bb8p20O2dgnD

CREATE VIEW ref_nomenclatures.v_eta_bio AS
 SELECT n.id_nomenclature,
    n.mnemonique,
    n.label_default AS label,
    n.definition_default AS definition,
    n.id_broader,
    n.hierarchy
   FROM (ref_nomenclatures.t_nomenclatures n
     LEFT JOIN ref_nomenclatures.bib_nomenclatures_types t ON ((t.id_type = n.id_type)))
  WHERE (((t.mnemonique)::text = 'ETA_BIO'::text) AND (n.active = true));

\unrestrict XadlbnQ77v4qU5tWm7uigEAPFkx4y9BkaYVFPfLKVnbscyMVYa1bb8p20O2dgnD

