
\restrict ke1DzwFYF6rhNwB1j8pkXoJJZwfeRWx3KZNWMQqgP3JirGWjYmFedvaeV4069qa

CREATE VIEW ref_nomenclatures.v_data_typ AS
 SELECT n.id_nomenclature,
    n.mnemonique,
    n.label_default AS label,
    n.definition_default AS definition,
    n.id_broader,
    n.hierarchy
   FROM (ref_nomenclatures.t_nomenclatures n
     LEFT JOIN ref_nomenclatures.bib_nomenclatures_types t ON ((t.id_type = n.id_type)))
  WHERE (((t.mnemonique)::text = 'DATA_TYP'::text) AND (n.active = true));

\unrestrict ke1DzwFYF6rhNwB1j8pkXoJJZwfeRWx3KZNWMQqgP3JirGWjYmFedvaeV4069qa

