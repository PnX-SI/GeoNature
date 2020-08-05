DROP TABLE IF EXISTS ginco_migration.cd_nom_invalid;
CREATE TABLE ginco_migration.cd_nom_invalid AS (
  select m.identifiantpermanent, m.id cdnom
  from ginco_migration.vm_data_model_source m
  left join taxonomie.taxref t on t.cd_nom = m.cdnom::integer 
  where cd_nom is null
);

DROP TABLE IF EXISTS ginco_migration.cd_nom_null;
CREATE TABLE ginco_migration.cd_nom_null AS (
  SELECT identifiantpermanent
  FROM ginco_migration.vm_data_model_source
  WHERE cdnom IS NULL
);

DROP TABLE IF EXISTS ginco_migration.date_invalid;
CREATE TABLE ginco_migration.date_invalid AS (
  SELECT unique_id_sinp
  FROM gn_synthese.synthese
  WHERE date_max < date_min
);

DROP TABLE IF EXISTS ginco_migration.count_invalid;
CREATE TABLE ginco_migration.count_invalid AS (
  SELECT unique_id_sinp
  FROM gn_synthese.synthese
  WHERE count_max < count_min
);

DROP TABLE IF EXISTS ginco_migration.doublons;
CREATE TABLE ginco_migration.doublons(
  nb_doublons integer,
  uuid_doublon character varying
);
-- repérer les doublons:
INSERT INTO ginco_migration.doublons
SELECT count(*) as nb_doubl, identifiantpermanent
FROM ginco_migration.vm_data_model_source
GROUP BY identifiantpermanent
HAVING count(*) > 1;
