CREATE SCHEMA gn_synchronomade IF NOT EXISTS;

CREATE TABLE gn_synchronomade.erreurs_occtax
(
  id serial NOT NULL,
  json text,
  date_import date,
  CONSTRAINT erreurs_occtax_pkey PRIMARY KEY (id)
);

CREATE TABLE gn_synchronomade.erreurs_flora
(
  id serial NOT NULL,
  json text,
  date_import date,
  CONSTRAINT erreurs_florapkey PRIMARY KEY (id)
)


-- vue des corespondance entre taxon et unité geo
-- on reprend l'id_nom car le mobile utilise ce code
-- on ne prend que les aires qui correspondent aux unité géo (id_type = 24)
CREATE OR REPLACE VIEW gn_synchronomade.v_nomade_cor_area_taxon AS 
 SELECT cor.id_area,
    b.id_nom,
    cor.nb_obs,
    cor.last_date AS last_obs,
    cor.color
   FROM gn_synthese.cor_area_taxon cor
    JOIN taxonomie.bib_noms b ON cor.cd_nom = b.cd_nom
    JOIN ref_geo.l_areas l ON l.id_area = cor.id_area
    WHERE l.id_type = (SELECT id_type FROM ref_geo.bib_areas_types WHERE type_code = 'UG');


-- TODO: import de la table public.v_mobile_recherche dans gn_synchronomade.v_mobile_recherche