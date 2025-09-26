

CREATE VIEW gn_synthese.v_area_taxon AS
 SELECT s.cd_nom,
    c.id_area,
    count(s.id_synthese) AS nb_obs,
    max(s.date_min) AS last_date
   FROM ((((gn_synthese.synthese s
     JOIN gn_synthese.cor_area_synthese c ON ((s.id_synthese = c.id_synthese)))
     JOIN ref_geo.l_areas la ON ((la.id_area = c.id_area)))
     JOIN ref_geo.bib_areas_types bat ON ((bat.id_type = la.id_type)))
     JOIN gn_commons.t_parameters tp ON ((((tp.parameter_name)::text = 'occtaxmobile_area_type'::text) AND (tp.parameter_value = (bat.type_code)::text))))
  GROUP BY c.id_area, s.cd_nom;


