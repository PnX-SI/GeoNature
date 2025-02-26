#!/bin/bash

# Update depending on the database
PG_DATABASE="geonature2db"
PG_USER="geonatadmin"
PG_PASSWORD="geonatpasswd"
HOST=localhost
PORT=5432


# Use to update schemas.txt
# PG_PASSWORD=$PG_PASSWORD psql -t -h $HOST -p $PORT -U $PG_USER $PG_DATABASE -c "select nspname
# from pg_catalog.pg_namespace where nspname NOT IN ('public', 'information_schema') and nspname NOT ILIKE 'pg%' ;" -o schemas.txt

cat schemas.txt | while read schema || [[ -n $schema ]];
do
  # List all tables in the schema
  cmd="PG_PASSWORD=$PG_PASSWORD psql -t -h $HOST -p $PORT -U $PG_USER $PG_DATABASE -c \"SELECT tablename FROM pg_catalog.pg_tables WHERE schemaname='$schema'\""
  tables=$(eval "$cmd")
  if [[ ! -d $schema ]];then
    mkdir $schema;
  fi
  # Dump functions of the schema
  psql -t -A -U $PG_USER -h $HOST -p $PORT $PG_DATABASE -c "
    SELECT pg_get_functiondef(f.oid)
    FROM pg_catalog.pg_proc f
    INNER JOIN pg_catalog.pg_namespace n ON (f.pronamespace = n.oid)
    WHERE n.nspname = '${schema}'
    ORDER BY f.proname
  " > ${schema}/functions.sql

  for table in $tables;
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
