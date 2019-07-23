#!/bin/bash
. ../../config/settings.ini
cd ../../

sudo ls

wget  --cache=off https://geonature.fr/data/inpn/layers/2019/maille_manquante_1k.zip -P tmp/geonature

unzip tmp/geonature/maille_manquante_1k.zip -d tmp/geonature

sudo -n -u postgres -s psql -d $db_name -f tmp/geonature/maille_manquante_1k.sql
sudo -n -u postgres -s psql -d $db_name -c "ALTER TABLE ref_geo.temp_grids_1 OWNER TO $user_pg;"

export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -c "INSERT INTO ref_geo.l_areas (id_type, area_code, area_name, geom) SELECT ref_geo.get_id_area_type('M1') AS id_type, cd_sig, code_10km, geom FROM ref_geo.temp_grids_1;"

export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -c "INSERT INTO ref_geo.li_grids(id_grid, id_area, cxmin, cxmax, cymin, cymax) SELECT area_code, id_area, ST_XMin(g.geom), ST_XMax(g.geom), ST_YMin(g.geom), ST_YMax(g.geom) FROM ref_geo.temp_grids_1 g JOIN ref_geo.l_areas l ON l.area_code = cd_sig;"

echo "Réintersection de cor_area_synthese avec les nouvelles mailles intersecté..."
echo "Cela peut prendre un peu de temps..."
export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -c "DELETE FROM gn_synthese.cor_area_synthese WHERE id_area in (SELECT id_area FROM ref_geo.l_areas WHERE id_type = (SELECT ref_geo.get_id_area_type('M1')))"

export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -c " INSERT INTO gn_synthese.cor_area_synthese SELECT s.id_synthese, a.id_area FROM ref_geo.l_areas a JOIN gn_synthese.synthese s ON public.st_intersects(s.the_geom_local, a.geom) WHERE a.enable = true AND id_type =  (SELECT ref_geo.get_id_area_type('M1'));"
