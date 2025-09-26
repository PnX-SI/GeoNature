
\restrict IDibfF6je5yJrHHdMhLnk8r8eDoUCU0YLmb0ylj1mHSTO8Oa5i3Vk2nrcDgvKnh

CREATE VIEW taxonomie.v_taxref_all_listes AS
 SELECT t.regne,
    t.phylum,
    t.classe,
    t.ordre,
    t.famille,
    t.group1_inpn,
    t.group2_inpn,
    t.cd_nom,
    t.cd_ref,
    t.nom_complet,
    t.nom_valide,
    t.nom_vern,
    t.lb_nom,
    d.id_liste
   FROM (taxonomie.taxref t
     JOIN taxonomie.cor_nom_liste d ON ((t.cd_nom = d.cd_nom)));

\unrestrict IDibfF6je5yJrHHdMhLnk8r8eDoUCU0YLmb0ylj1mHSTO8Oa5i3Vk2nrcDgvKnh

