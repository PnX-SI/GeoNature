
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

----- 
-- Import données zonage de sensibilité du languedoc roussillon


-- Au préalable importer les données géographique => scripts SQL


INSERT INTO ref_geo.bib_areas_types(type_name, type_code, type_desc, ref_name)
    VALUES ('Zone sensibilité', 'SENSIBILITY', 'Zone de sensibilité particulière défini par le sipn', 'sensibilité SIPN');
    
INSERT INTO ref_geo.l_areas(id_type, area_name, area_code, geom, centroid, source, comment)
SELECT DISTINCT type.id_type, lib_zone, 'ZONE_SENSIBILITE_' || cd_nom as area_code, z.geom, st_centroid(z.geom) as centroid, source, 
    CONCAT('cd_nom : ' || cd_nom, ' nom_vernac: '|| nom_vernac,' nom_latin: '|| nom_latin) as comment
FROM gn_sensitivity.zonages_sensibilite z, 
(SELECT id_type FROM ref_geo.bib_areas_types WHERE type_code='SENSIBILITY') type;



-- #################################################
-- ## Import des données dans le modèle 

INSERT INTO gn_sensitivity.t_sensitivity_rules(
            id_sensitivity, cd_nom,nom_cite, id_nomenclature_sensitivity, sensitivity_duration,
            sensitivity_territory, id_territory, source, comments, date_min, date_max )
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


-- Import des données LR avec des périmètres spécifiques
DELETE FROM gn_sensitivity.cor_sensitivity_area
WHERE id_sensitivity IN (
SELECT DISTINCT id_sensitivity
FROM ref_geo.l_areas
JOIN   gn_sensitivity.t_sensitivity_rules l
ON taxonomie.find_cdref(REPLACE(area_code, 'ZONE_SENSIBILITE_','')::int) = taxonomie.find_cdref(l.cd_nom)
WHERE  id_type = (SELECT id_type FROM ref_geo.bib_areas_types  WHERE type_code ='SENSIBILITY')
AND  id_territory = 'INSEER91'
);

INSERT INTO gn_sensitivity.cor_sensitivity_area
SELECT DISTINCT id_sensitivity, id_area
FROM ref_geo.l_areas
JOIN   gn_sensitivity.t_sensitivity_rules l
ON taxonomie.find_cdref(REPLACE(area_code, 'ZONE_SENSIBILITE_','')::int) = taxonomie.find_cdref(l.cd_nom)
WHERE  id_type = (SELECT id_type FROM ref_geo.bib_areas_types  WHERE type_code ='SENSIBILITY')
AND  id_territory = 'INSEER91';


-- Activation des règles

UPDATE  gn_sensitivity.t_sensitivity_rules SET enable = FALSE;
UPDATE  gn_sensitivity.t_sensitivity_rules SET enable = TRUE 
WHERE id_territory='TERFXFR';

