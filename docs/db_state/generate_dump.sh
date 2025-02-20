#!/bin/bash

# Update depending on the database
PG_DATABASE="geonature2db"
PG_USER="geonatadmin"
PG_PASSWORD="geonatadmin"
HOST=localhost
PORT=5432

clean_sql_file() {
    local file=$1
    sed -i '/^--/d' $file
    sed -i '/^$/N;/\n$/D' $file
}

# Use to update schemas.txt
# PG_PASSWORD=$PG_PASSWORD psql -t -h $HOST -p $PORT -U $PG_USER $PG_DATABASE -c "select nspname
# from pg_catalog.pg_namespace where nspname NOT IN ('public', 'information_schema') and nspname NOT ILIKE 'pg%' ;" -o schemas.txt

cat schemas.txt | while read schema || [[ -n $schema ]];
do
  cmd="PG_PASSWORD=$PG_PASSWORD psql -t -h $HOST -p $PORT -U $PG_USER $PG_DATABASE -c \"SELECT tablename FROM pg_catalog.pg_tables WHERE schemaname='$schema'\""
  res=$(eval "$cmd")
  if [[ ! -d $schema ]];then
    mkdir $schema;
  fi
  PG_PASSWORD=$PG_PASSWORD pg_dump -U $PG_USER  -n $schema -s -h $HOST  -p $PORT $PG_DATABASE  |  awk '/CREATE FUNCTION/,/^\$/' >  ${schema}/functions.sql
  clean_sql_file ${schema}/functions.sql

  for table in $res;
  do
    echo "Dumping ${schema}.${table}..."
    PG_PASSWORD=$PG_PASSWORD pg_dump -O -x -s -t "${schema}.${table}" -U $PG_USER -h $HOST -p $PORT $PG_DATABASE > $schema/$table.sql
    
    sed -i '/^--/d' $schema/$table.sql
    sed -i '/^SELECT pg_catalog/d' $schema/$table.sql
    sed -i '/SET/d' $schema/$table.sql
    # Remove consecutive empty lines
    sed -i '/^$/N;/\n$/D' $schema/$table.sql

  done


#   cmd="PG_PASSWORD=geonatadmin pg_dump -n '${schema}.${}' -U geonatadmin -h localhost geonature2>${schema}.sql"
  
#   eval "$cmd"
done
