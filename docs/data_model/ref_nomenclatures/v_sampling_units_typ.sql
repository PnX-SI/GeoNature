
\restrict R8s26tpBB35krVy0VSZV1wIPWrDNxaydn7We2LcmpdR3pTD9mAogAQ8b3HzTJ9m

CREATE VIEW ref_nomenclatures.v_sampling_units_typ AS
 SELECT n.id_nomenclature,
    n.mnemonique,
    n.label_default AS label,
    n.definition_default AS definition,
    n.id_broader,
    n.hierarchy
   FROM (ref_nomenclatures.t_nomenclatures n
     LEFT JOIN ref_nomenclatures.bib_nomenclatures_types t ON ((t.id_type = n.id_type)))
  WHERE (((t.mnemonique)::text = 'SAMPLING_UNITS_TYP'::text) AND (n.active = true));

\unrestrict R8s26tpBB35krVy0VSZV1wIPWrDNxaydn7We2LcmpdR3pTD9mAogAQ8b3HzTJ9m

