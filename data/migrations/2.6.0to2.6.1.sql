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

CREATE VIEW gn_synthese.v_area_taxon AS
SELECT s.cd_nom, c.id_area, count(DISTINCT s.id_synthese) as nb_obs, max(s.date_min) as last_date
FROM gn_synthese.synthese s
JOIN gn_synthese.cor_area_synthese c ON s.id_synthese = c.id_synthese
GROUP BY c.id_area, s.cd_nom;

CREATE VIEW gn_synthese.v_color_taxon_area AS
SELECT cd_nom, id_area, nb_obs, last_date,
 CASE
  WHEN date_part('day', (now() - last_date)) < 365 THEN 'grey'
  ELSE 'red'
 END as color
FROM gn_synthese.v_area_taxon;
