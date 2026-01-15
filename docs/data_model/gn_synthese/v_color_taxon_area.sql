

CREATE VIEW gn_synthese.v_color_taxon_area AS
 SELECT v_area_taxon.cd_nom,
    v_area_taxon.id_area,
    v_area_taxon.nb_obs,
    v_area_taxon.last_date,
        CASE
            WHEN (date_part('day'::text, (now() - (v_area_taxon.last_date)::timestamp with time zone)) < (365)::double precision) THEN 'grey'::text
            ELSE 'red'::text
        END AS color
   FROM gn_synthese.v_area_taxon;


