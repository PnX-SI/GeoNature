. /home/theo/workspace/GN2/GeoNature/config/settings.ini


if [ ! -f /home/theo/workspace/GN2/GeoNature/var/log/color_taxons.log] 
then
  touch /home/theo/workspace/GN2/GeoNature/var/log/color_taxons.log
fi

export PGPASSWORD=$user_pg_pass;psql -h $db_host -U $user_pg -d $db_name -c "PERFORM gn_synthese.recalculate_taxon_color()"  & /home/theo/workspace/GN2/GeoNature/var/log/install_db.log
