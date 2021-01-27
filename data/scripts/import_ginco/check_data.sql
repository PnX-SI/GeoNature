-- Verification des données après la migration

-- Nombre de données total d'occurrences de taxon dans GINCO (table ginco_migration.model_1_observation)
select count(*)
from ginco_migration.model_1_observation

-- Nombre de données dont les JDD sont supprimés

select count(*)
 FROM ginco_migration.model_1_observation m
 WHERE m.jddmetadonneedeeid::text IN ( SELECT f.value_string
 FROM ginco_migration.jdd j
 JOIN ginco_migration.jdd_field f ON f.jdd_id = j.id
 WHERE j.status = 'deleted'::text AND f.key::text = 'metadataId'::text)

-- Nombre de données sans géométrie

select count(*)
 FROM ginco_migration.model_1_observation m
 WHERE m.geometrie is null;

-- Nombre de données actuellement dans la vue materialisée
-- (utilisée pour inserer dans la synthese), ou on a enlevé les données supprimées et les données sans geom

-- Nombre de données en doublon

-- Nombre de cd_nom null

select count(*)
from ginco_migration.cd_nom_null 

-- Nombre de cd_nom invalide

select * from ginco_migration.cd_nom_invalid

-- Dénombrement invalide (nb_min > nb_max)

select * from ginco_migration.count_invalid

-- Nombre de date invalide (date_min > date_max)

select * from ginco_migration.date_invalid

-- Nombre de données dans la synthese

select * from gn_synthese.synthese

-- Nombre de JDD dans la base Ginco

 SELECT count(*)
 FROM ginco_migration.jdd j
 JOIN ginco_migration.jdd_field f ON f.jdd_id = j.id
 WHERE j.status != 'deleted'::text AND f.key::text = 'metadataId'::text

-- Nombre de JDD dans GeoNature

 select count(*)
 from gn_meta.t_datasets
