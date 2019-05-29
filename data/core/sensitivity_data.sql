
CREATE EXTENSION IF NOT EXISTS unaccent;



DROP TABLE IF EXISTS gn_sensitivity.liste_taxons_sensibles;
CREATE TABLE gn_sensitivity.liste_taxons_sensibles
(
    cd_sens int,
    cd_nom int,
    nom_cite varchar(500),
    grain varchar(250),
    duree int, 
    perimetre varchar(250), 
    autre  varchar(500),
    codage char(1),
    cd_sl int,
    cd_sig varchar(50),
    cd_occ_statut_biologique varchar(2),
    date_min date,
    date_max date
);

COPY gn_sensitivity.liste_taxons_sensibles 
FROM '/tmp/geonature/181201_referentiel_donnes_sensibles.csv' DELIMITER ',' CSV HEADER;



-- #################################################
-- ## Import des données dans le modèle 

INSERT INTO gn_sensitivity.t_sensitivity_rules(
    id_sensitivity, cd_nom,nom_cite, id_nomenclature_sensitivity, sensitivity_duration,
    sensitivity_territory, id_territory, source, comments, date_min, date_max
)
SELECT 
   cd_sens, cd_nom, nom_cite, ref_nomenclatures.get_id_nomenclature('SENSIBILITE', codage), COALESCE(duree, 10000), 
    perimetre, cd_sig, 'Compilation national',
    autre, date_min, date_max
FROM gn_sensitivity.liste_taxons_sensibles;


-- ## import des critères
INSERT INTO  gn_sensitivity.cor_sensitivity_criteria
SELECT cd_sens as  id_sensitivity, ref_nomenclatures.get_id_nomenclature('STATUT_BIO', cd_occ_statut_biologique) as id_criteria, (SELECT id_type FROM ref_nomenclatures.bib_nomenclatures_types  WHERE mnemonique= 'STATUT_BIO')
FROM  gn_sensitivity.liste_taxons_sensibles
WHERE NOT cd_occ_statut_biologique IS NULL;

-- ## import lien avec l_areas

-- Import des régions
INSERT INTO gn_sensitivity.cor_sensitivity_area
SELECT DISTINCT id_sensitivity, id_area
FROM gn_sensitivity.t_sensitivity_rules   s
JOIN ref_geo.l_areas
ON REPLACE(id_territory, 'INSEER', '') = area_code AND  id_type = (SELECT id_type FROM ref_geo.bib_areas_types  WHERE type_code ='REG')
WHERE id_territory LIKE 'INSEER%' ;


-- Import des départements
INSERT INTO gn_sensitivity.cor_sensitivity_area
SELECT DISTINCT id_sensitivity, id_area
FROM gn_sensitivity.t_sensitivity_rules   s
JOIN ref_geo.l_areas
ON REPLACE(id_territory, 'INSEED', '') = area_code AND  id_type = (SELECT id_type FROM ref_geo.bib_areas_types  WHERE type_code ='DEP')
WHERE id_territory LIKE 'INSEED%' ;



-- Activation des règles

UPDATE  gn_sensitivity.t_sensitivity_rules SET active = FALSE;
UPDATE  gn_sensitivity.t_sensitivity_rules SET active = TRUE 
WHERE id_territory='TERFXFR';


DROP TABLE gn_sensitivity.liste_taxons_sensibles;