. settings.ini

function write_log() {
    echo $1
    echo "" &>> log/insert_data.log
    echo "" &>> log/insert_data.log
    echo "--------------------" &>> log/insert_data.log
    echo $1 &>> log/insert_data.log
    echo "--------------------" &>> log/insert_data.log
}
export PGPASSWORD=$geonature_user_pg_pass;
# fonctions utilitaires pour modifier des champs qui ont des dépendances
psql -h $db_host -U $geonature_pg_user -d $geonature_db_name -f utils_drop_dependencies.sql  &> log/insert_data.log

write_log "SCHEMA UTILISATEURS"
psql -h $db_host -U $geonature_pg_user -d $geonature_db_name -f utilisateurs.sql  &>> log/insert_data.log

write_log "INSERTION GN_META"

psql -h $db_host -U $geonature_pg_user -d $geonature_db_name -f meta.sql  &>> log/insert_data.log


write_log "UPDATE REF_GEO"
psql -h $db_host -U $geonature_pg_user -d $geonature_db_name -v CODE_INSEE_REG=$code_insee_reg -f ref_geo.sql  &>> log/insert_data.log

write_log "INSERT IN SYNTHESE...cela peut être long"
psql -h $db_host -U $geonature_pg_user -d $geonature_db_name -f synthese_before_insert.sql  &>> log/insert_data.log

psql -h $db_host -U $geonature_pg_user -d $geonature_db_name -v GINCO_TABLE=$ginco_data_table_name -v GINCO_TABLE_QUOTED="'$ginco_data_table_name'" -f synthese.sql  &>> log/insert_data.log


psql -h $db_host -U $geonature_pg_user -d $geonature_db_name -f synthese_after_insert.sql  &>> log/insert_data.log

write_log "Occtax"
psql -h $db_host -U $geonature_pg_user -d $geonature_db_name -f occtax.sql  &>> log/insert_data.log

echo "OK"

write_log "PERMISSIONS"
psql -h $db_host -U $geonature_pg_user -d $geonature_db_name -f permissions.sql  &>> log/insert_data.log

echo "Terminé"