DROP FUNCTION gn_synthese.calcul_cor_area_taxon;

DROP TRIGGER tri_maj_cor_area_taxon ON gn_synthese.cor_area_synthese;
DROP FUNCTION gn_synthese.fct_tri_maj_cor_unite_taxon;

DROP TRIGGER tri_del_area_synt_maj_corarea_tax ON gn_synthese.synthese;
DROP FUNCTION gn_synthese.fct_tri_manage_area_synth_and_taxon;
DROP FUNCTION gn_synthese.delete_and_insert_area_taxon;

DROP TRIGGER tri_update_cor_area_taxon_update_cd_nom on gn_synthese.synthese;
DROP FUNCTION gn_synthese.fct_tri_update_cd_nom;

DROP VIEW gn_synthese.v_color_taxon_area;

DROP TABLE gn_synthese.cor_area_taxon;

INSERT INTO gn_commons.t_parameters (id_organism, parameter_name, parameter_desc, parameter_value)
VALUES (0, 'occtaxmobile_area_type', 'Type de maille pour laquelle la couleur des taxons est calculée', 'M5');

CREATE VIEW gn_synthese.v_area_taxon AS
SELECT s.cd_nom, c.id_area, count(DISTINCT s.id_synthese) as nb_obs, max(s.date_min) as last_date
FROM gn_synthese.synthese s
JOIN gn_synthese.cor_area_synthese c ON s.id_synthese = c.id_synthese
JOIN ref_geo.l_areas la ON la.id_area = c.id_area
JOIN ref_geo.bib_areas_types bat ON bat.id_type = la.id_type
JOIN gn_commons.t_parameters tp ON tp.parameter_name = 'occtaxmobile_area_type' AND tp.parameter_value = bat.type_code
GROUP BY c.id_area, s.cd_nom;

CREATE VIEW gn_synthese.v_color_taxon_area AS
SELECT cd_nom, id_area, nb_obs, last_date,
 CASE
  WHEN date_part('day', (now() - last_date)) < 365 THEN 'grey'
  ELSE 'red'
 END as color
FROM gn_synthese.v_area_taxon;
