#!/usr/bin/env bash

# Script remplaçant les règles de sensibilité nationales et régionales intégrées dans GeoNature, par les règles départementales.
# Utilisé pour DEPOBIO pour disposer des règles de sensibilité à jour, au niveau départemantal.

rootdir=`pwd`/../../../
. $rootdir/config/settings.ini 
export PGPASSWORD=$user_pg_pass
rm /tmp/sensibles_to_inpn_20201218.csv
wget --cache=off https://geonature.fr/data/inpn/sensitivity/ref_sensibilite_21122020.csv -P /tmp
psql -h $db_host -U $user_pg -d $db_name -c " DROP TABLE IF EXISTS gn_sensitivity.tmp_rules"

# Creation d'une table temporaire pour stocker les règles de sensibilité départementales
psql -h $db_host -U $user_pg -d $db_name -c "
CREATE TABLE gn_sensitivity.tmp_rules (
  id_sensitivity serial primary key,
  cd_dept varchar,
  cd_nom integer,
  nom_cite varchar,
  duree integer,
  codage integer,
  autre text,
  cd_sl integer,
  cd_occ_statut_biologique integer,
  cd_ref_v13 integer
)
"

# Copie du contenu du fichier CSV dans la table temporaire
sudo -u postgres -s psql -d $db_name -c "
COPY gn_sensitivity.tmp_rules(cd_dept, cd_nom, nom_cite, duree, codage, autre, cd_sl, cd_occ_statut_biologique, cd_ref_v13) 
FROM '/tmp/ref_sensibilite_21122020.csv' DELIMITER ';' CSV HEADER;
"

# Vider les tables existantes de GeoNature, puis les remplir avec le contenu de la table temporaire
psql -h $db_host -U $user_pg -d $db_name -c "
delete from gn_sensitivity.cor_sensitivity_area ;
delete from gn_sensitivity.cor_sensitivity_criteria;
delete from gn_sensitivity.t_sensitivity_rules;

insert into gn_sensitivity.t_sensitivity_rules (
id_sensitivity, cd_nom , nom_cite ,  id_nomenclature_sensitivity,  sensitivity_duration , sensitivity_territory, id_territory , date_min , date_max , "source" , active , "comments"
)
select t.id_sensitivity, t.cd_ref_v13, t.nom_cite , ref_nomenclatures.get_id_nomenclature('SENSIBILITE', codage::varchar)  , coalesce(t.duree, 10000) , 'Département', t.cd_dept, null, null, 'Fichier Solene issu BDC', true, null
from gn_sensitivity.tmp_rules t;

-- insertion dans cor_sensitivity_area

INSERT INTO gn_sensitivity.cor_sensitivity_area
SELECT DISTINCT id_sensitivity, id_area
FROM gn_sensitivity.t_sensitivity_rules   s
JOIN ref_geo.l_areas
ON id_territory = area_code AND  id_type = (SELECT id_type FROM ref_geo.bib_areas_types  WHERE type_code ='DEP')
;
INSERT INTO  gn_sensitivity.cor_sensitivity_criteria
SELECT id_sensitivity, ref_nomenclatures.get_id_nomenclature('STATUT_BIO', cd_occ_statut_biologique::varchar) as id_criteria, (SELECT id_type FROM ref_nomenclatures.bib_nomenclatures_types  WHERE mnemonique= 'STATUT_BIO')
FROM  gn_sensitivity.tmp_rules
WHERE NOT cd_occ_statut_biologique IS NULL and NOT ref_nomenclatures.get_id_nomenclature('STATUT_BIO', cd_occ_statut_biologique::varchar) IS NULL;

refresh materialized view gn_sensitivity.t_sensitivity_rules_cd_ref;
"


