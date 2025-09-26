

CREATE VIEW ref_nomenclatures.v_technique_obs AS
 SELECT ctn.regne,
    ctn.group2_inpn,
    n.id_nomenclature,
    n.mnemonique,
    n.label_default AS label,
    n.definition_default AS definition,
    n.id_broader,
    n.hierarchy
   FROM (ref_nomenclatures.t_nomenclatures n
     LEFT JOIN ref_nomenclatures.cor_taxref_nomenclature ctn ON ((ctn.id_nomenclature = n.id_nomenclature)))
  WHERE ((n.mnemonique)::text = 'TECHNIQUE_OBS'::text);


