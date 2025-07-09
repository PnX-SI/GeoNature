
CREATE VIEW gn_synthese.v_synthese_taxon_for_export_view AS
 SELECT DISTINCT ref.nom_valide,
    ref.cd_ref,
    ref.nom_vern,
    ref.group1_inpn,
    ref.group2_inpn,
    ref.group3_inpn,
    ref.regne,
    ref.phylum,
    ref.classe,
    ref.ordre,
    ref.famille,
    ref.id_rang
   FROM ((gn_synthese.synthese s
     JOIN taxonomie.taxref t ON ((s.cd_nom = t.cd_nom)))
     JOIN taxonomie.taxref ref ON ((t.cd_ref = ref.cd_nom)));

