# Script to generate SQL for geographical referential (town, departments and grid) from their shp2pgsql
# Create 3 zip in /tmp folder

set -e

. settings.ini 
rootdir=`pwd`/../../../

. $rootdir/config/settings.ini 

export PGPASSWORD=$user_pg_pass;

rm -f /tmp/$dep_zip_name.zip
rm -f /tmp/$town_zip_name.zip
rm -f /tmp/$grid_zip_name.zip

echo " START" &> ref.log
if [ "$town" = true ];
then
    echo "create town table"
    shp2pgsql -d -s $srid $path_town ref_geo.temp_fr_municipalities | psql -h $db_host -U $user_pg -d $db_name &>> ref.log
    echo "add geojson column"
    psql -h $db_host -U $user_pg -d $db_name -c "
    ALTER table ref_geo.temp_fr_municipalities
    ADD column geojson character varying; 
    UPDATE ref_geo.temp_fr_municipalities
    SET geojson = public.ST_asgeojson(public.st_transform(geom, 4326));
    "&>> ref.log
    echo "export the table"
    pg_dump --format=plain --no-owner -h $db_host -U $user_pg -d $db_name -t ref_geo.temp_fr_municipalities > /tmp/fr_municipalities.sql
    cd /tmp
    zip $town_zip_name fr_municipalities.sql &>> ref.log
fi

if [ "$dep" = true ];
then
    echo "create department table"
    cd `pwd`
    shp2pgsql -d -s $srid $path_department ref_geo.temp_fr_departements | psql -h $db_host -U $user_pg -d $db_name &>> ref.log
    echo "add geojson column"
    psql -h $db_host -U $user_pg -d $db_name -c "
    ALTER table ref_geo.temp_fr_departements
    ADD column geojson character varying; 
    UPDATE ref_geo.temp_fr_departements
    SET geojson = public.ST_asgeojson(public.st_transform(geom, 4326)); 
    "&>> ref.log
    pg_dump --format=plain --no-owner -h $db_host -U $user_pg -d $db_name -t ref_geo.temp_fr_departements > /tmp/fr_departements.sql
    cd /tmp
    zip $dep_zip_name fr_departements.sql &>> ref.log
fi

if [ "$grid" = true ];
then
    echo "create grid tables"
    cd `pwd`
    shp2pgsql -d -s $srid $path_grid_10 ref_geo.temp_grids_10 | psql -h $db_host -U $user_pg -d $db_name &>> ref.log

    shp2pgsql -d -s $srid $path_grid_5 ref_geo.temp_grids_5 | psql -h $db_host -U $user_pg -d $db_name &>> ref.log

    shp2pgsql -d -s $srid  $path_grid_1 ref_geo.temp_grids_1 | psql -h $db_host -U $user_pg -d $db_name &>> ref.log

    echo "add geojson column"
    psql -h $db_host -U $user_pg -d $db_name -c "
    ALTER table ref_geo.temp_grids_10
    ADD column geojson character varying; 
    UPDATE ref_geo.temp_grids_10
    SET geojson = public.ST_asgeojson(public.st_transform(geom, 4326)); 
    "&>> ref.log
        psql -h $db_host -U $user_pg -d $db_name -c "
    ALTER table ref_geo.temp_grids_5
    ADD column geojson character varying; 
    UPDATE ref_geo.temp_grids_5
    SET geojson = public.ST_asgeojson(public.st_transform(geom, 4326)); 
    "&>> ref.log
        psql -h $db_host -U $user_pg -d $db_name -c "
    ALTER table ref_geo.temp_grids_1
    ADD column geojson character varying; 
    UPDATE ref_geo.temp_grids_1
    SET geojson = public.ST_asgeojson(public.st_transform(geom, 4326)); 
    "&>> ref.log
    pg_dump \
    --format=plain \
    --no-owner \
    -h $db_host \
    -U $user_pg \
    -d $db_name \
    -t ref_geo.temp_grids_10 \
    -t ref_geo.temp_grids_5 \
    -t ref_geo.temp_grids_1 \
    > /tmp/inpn_grids.sql
    cd /tmp
    zip $grid_zip_name inpn_grids.sql &>> ref.log
fi

# inpn_grids.sql

rm /tmp/fr_departements.sql
rm /tmp/fr_municipalities.sql
# rm /tmp/inpn_grids.sql

echo "DONE"