
\restrict KSQIx2hNgaAmjDOAR2ckehdIDo9qxyGduZ1DDk5tuSx0DN52kC64rfqZ8eQgdw3

CREATE VIEW ref_nomenclatures.v_statut_bio AS
 SELECT ctn.regne,
    ctn.group2_inpn,
    n.id_nomenclature,
    n.mnemonique,
    n.label_default AS label,
    n.definition_default AS definition,
    n.id_broader,
    n.hierarchy
   FROM ((ref_nomenclatures.t_nomenclatures n
     LEFT JOIN ref_nomenclatures.cor_taxref_nomenclature ctn ON ((ctn.id_nomenclature = n.id_nomenclature)))
     LEFT JOIN ref_nomenclatures.bib_nomenclatures_types t ON ((t.id_type = n.id_type)))
  WHERE (((t.mnemonique)::text = 'STATUT_BIO'::text) AND (n.active = true));

\unrestrict KSQIx2hNgaAmjDOAR2ckehdIDo9qxyGduZ1DDk5tuSx0DN52kC64rfqZ8eQgdw3

