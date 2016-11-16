#!/bin/bash

# Make sure only root can run our script
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

. config/settings.ini

function database_exists () {
    # /!\ Will return false if psql can't list database. Edit your pg_hba.conf
    # as appropriate.
    if [ -z $1 ]
        then
        # Argument is null
        return 0
    else
        # Grep db name in the list of database
        sudo -n -u postgres -s -- psql -tAl | grep -q "^$1|"
        return $?
    fi
}


if database_exists $db_name
then
        if $drop_apps_db
            then
            echo "Suppression de la base..."
            sudo -n -u postgres -s dropdb $db_name
        else
            echo "La base de données existe et le fichier de settings indique de ne pas la supprimer."
        fi
fi        
if ! database_exists $db_name 
then
    echo "Création de la base..."
    sudo -n -u postgres -s createdb -O $user_pg $db_name
    echo "Ajout de postgis à la base"
    sudo -n -u postgres -s psql -d $db_name -c "CREATE EXTENSION IF NOT EXISTS postgis;"
    sudo -n -u postgres -s psql -d $db_name -c "CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog; COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';"


    # Mise en place de la structure de la base et des données permettant son fonctionnement avec l'application
    echo "Grant..."
    export PGPASSWORD=$admin_pg_pass;psql -h geonatdbhost -U $admin_pg -d $db_name -f data/grant.sql &> log/install_db.log
    
    echo "Récupération et création du schéma utilisateurs..."
    cd data/utilisateurs
    wget https://raw.githubusercontent.com/PnEcrins/UsersHub/master/data/usershub.sql
    cd ../..
    # export PGPASSWORD=$user_pg_pass;psql -h geonatdbhost -U $user_pg -d $db_name -f data/utilisateurs/create_schema_utilisateurs.sql  &>> log/install_db.log
    # export PGPASSWORD=$user_pg_pass;psql -h geonatdbhost -U $user_pg -d $db_name -f data/utilisateurs/data_utilisateurs.sql  &>> log/install_db.log
    export PGPASSWORD=$user_pg_pass;psql -h geonatdbhost -U $user_pg -d $db_name -f data/utilisateurs/usershub.sql  &>> log/install_db.log
    export PGPASSWORD=$user_pg_pass;psql -h geonatdbhost -U $user_pg -d $db_name -f data/utilisateurs/create_view_utilisateurs.sql  &>> log/install_db.log

    
    echo "Création du schéma taxonomie..."
    echo "Téléchargement et décompression des fichiers du taxref..."
    cd data/taxonomie/inpn
    wget https://raw.githubusercontent.com/PnX-SI/TaxHub/master/data/inpn/data_inpn_v9_taxhub.sql
    wget https://github.com/PnX-SI/TaxHub/raw/master/data/inpn/TAXREF_INPN_v9.0.zip
    wget https://github.com/PnX-SI/TaxHub/raw/master/data/inpn/ESPECES_REGLEMENTEES.zip
    wget https://github.com/PnX-SI/TaxHub/raw/master/data/inpn/LR_FRANCE.zip
    unzip TAXREF_INPN_v9.0.zip -d /tmp
  	unzip ESPECES_REGLEMENTEES_v9.zip -d /tmp
    unzip LR_FRANCE.zip -d /tmp
    cd ..
    
    echo "Récupération des scripts de création du schéma taxonomie..."
    wget https://raw.githubusercontent.com/PnX-SI/TaxHub/master/data/taxhubdb.sql
    wget https://raw.githubusercontent.com/PnX-SI/TaxHub/master/data/vm_hierarchie_taxo.sql
    wget https://raw.githubusercontent.com/PnX-SI/TaxHub/master/data/taxhubdata.sql
    cd ../..
    
    echo "Création du schéma taxonomie..."
    export PGPASSWORD=$user_pg_pass;psql -h geonatdbhost -U $user_pg -d $db_name -f data/taxonomie/taxhubdb.sql  &>> log/install_db.log
    
    echo "Insertion  des données taxonomiques de l'inpn... (cette opération peut être longue)"
    export PGPASSWORD=$admin_pg_pass;psql -h geonatdbhost -U $admin_pg -d $db_name  -f data/taxonomie/inpn/data_inpn_v9_taxhub.sql &>> log/install_db.log
    
    echo "Création des données dictionnaires du schéma taxonomie..."
    export PGPASSWORD=$user_pg_pass;psql -h geonatdbhost -U $user_pg -d $db_name -f data/taxonomie/taxhubdata.sql  &>> log/install_db.log
    
    echo "Création de la vue représentant la hierarchie taxonomique..."
    export PGPASSWORD=$user_pg_pass;psql -h geonatdbhost -U $user_pg -d $db_name -f data/taxonomie/vm_hierarchie_taxo.sql  &>> log/install_db.log
    
    echo "Création des autres schémas de la base GeoNature..."
    export PGPASSWORD=$user_pg_pass;psql -h geonatdbhost -U $user_pg -d $db_name -f data/2154/synthese_2154.sql  &>> log/install_db.log
    
    echo "Décompression des fichiers des communes de France métropolitaine..."
    cd data/layers
    tar -xzvf communes_metropole.tar.gz
    cd ../..
    
    echo "Insertion  du référentiel géographique : communes métropolitaines... (cette opération peut être longue)"
    export PGPASSWORD=$user_pg_pass;psql -h geonatdbhost -U $user_pg -d $db_name  -f data/layers/communes_metropole.sql &>> log/install_db.log
    
    echo "Insertion des données des tables dictionnaires de la base..."
    export PGPASSWORD=$user_pg_pass;psql -h geonatdbhost -U $user_pg -d $db_name -f data/2154/data_synthese_2154.sql  &>> log/install_db.log
    
    echo "Création du contact flore..."
    export PGPASSWORD=$user_pg_pass;psql -h geonatdbhost -U $user_pg -d $db_name -f data/2154/contactflore.sql  &>> log/install_db.log
    
    echo "Téléchargement et décompression des fichiers du référentiel géographique..."
    cd data/layers
    wget https://inpn.mnhn.fr/docs/Shape/apb.zip
    unzip apb.zip
    wget https://inpn.mnhn.fr/docs/Shape/bios.zip
    unzip bios.zip
    wget https://inpn.mnhn.fr/docs/Shape/cdl.zip
    unzip cdl.zip
    wget https://inpn.mnhn.fr/docs/Shape/cen.zip
    unzip cen.zip
    wget https://inpn.mnhn.fr/docs/Shape/pn.zip
    unzip pn.zip
    wget https://inpn.mnhn.fr/docs/Shape/pnr.zip
    unzip pnr.zip
    wget https://inpn.mnhn.fr/docs/Shape/pnm.zip
    unzip pnm.zip
    wget https://inpn.mnhn.fr/docs/Shape/ramsar.zip
    unzip ramsar.zip
    wget https://inpn.mnhn.fr/docs/Shape/rb.zip
    unzip rb.zip
    wget https://inpn.mnhn.fr/docs/Shape/rnc.zip
    unzip ripn.zip
    wget https://inpn.mnhn.fr/docs/Shape/cdl.zip
    unzip rnc.zip
    wget https://inpn.mnhn.fr/docs/Shape/rncfs.zip
    unzip rncfs.zip
    wget https://inpn.mnhn.fr/docs/Shape/rnn.zip
    unzip rnn.zip
    wget https://inpn.mnhn.fr/docs/Shape/rnr.zip
    unzip rnr.zip
    wget https://inpn.mnhn.fr/docs/Shape/sic.zip
    unzip sic.zip
    wget https://inpn.mnhn.fr/docs/Shape/zps.zip
    unzip zps.zip
    wget https://inpn.mnhn.fr/docs/Shape/zico.zip
    unzip zico.zip
    wget https://inpn.mnhn.fr/docs/Shape/znieff1.zip
    unzip znieff1.zip
    wget https://inpn.mnhn.fr/docs/Shape/znieff2.zip
    unzip znieff2.zip
    wget https://inpn.mnhn.fr/docs/Shape/znieff1_mer.zip
    unzip znieff1_mer.zip
    wget https://inpn.mnhn.fr/docs/Shape/znieff2_mer.zip
    unzip znieff2_mer.zip
    mkdir sql
    cd ../..
    
    echo "Insertion  du référentiel géographique : zones à statut de france métropolitaine..."
    echo "...Aires de protection de biotope..."
    sudo -n -u postgres -s shp2pgsql -s 2154 -a -g the_geom -W "LATIN1"  data/layers/apb/apb.shp layers.l_zonesstatut > data/layers/sql/apb.sql
    export PGPASSWORD=$user_pg_pass;psql -h geonatdbhost -U $user_pg -d $db_name -f data/layers/sql/apb.sql &>> log/install_db.log
    echo "...Réserves de biosphère"
    sudo -n -u postgres -s shp2pgsql -s 2154 -a -g the_geom -W "LATIN1"  data/layers/bios/bios09_2013.shp layers.l_zonesstatut > data/layers/sql/bios.sql
    export PGPASSWORD=$user_pg_pass;psql -h geonatdbhost -U $user_pg -d $db_name -f data/layers/sql/bios.sql &>> log/install_db.log
    echo "...Sites du Conservatoire du Littoral..."
    sudo -n -u postgres -s shp2pgsql -s 2154 -a -g the_geom -W "LATIN1"  data/layers/cdl/cdl2013.shp layers.l_zonesstatut > data/layers/sql/cdl.sql
    export PGPASSWORD=$user_pg_pass;psql -h geonatdbhost -U $user_pg -d $db_name -f data/layers/sql/cdl.sql &>> log/install_db.log
    echo "...SSites acquis des Conservatoires d'espaces naturels..."
    sudo -n -u postgres -s shp2pgsql -s 2154 -a -g the_geom -W "LATIN1"  data/layers/cen/cen2013_09.shp layers.l_zonesstatut > data/layers/sql/cen.sql
    export PGPASSWORD=$user_pg_pass;psql -h geonatdbhost -U $user_pg -d $db_name -f data/layers/sql/cen.sql &>> log/install_db.log
    echo "...Parcs nationaux..."
    sudo -n -u postgres -s shp2pgsql -s 2154 -a -g the_geom -W "LATIN1"  data/layers/pn/pn.shp layers.l_zonesstatut > data/layers/sql/pn.sql
    export PGPASSWORD=$user_pg_pass;psql -h geonatdbhost -U $user_pg -d $db_name -f data/layers/sql/pn.sql &>> log/install_db.log
    echo "...Parcs naturels marins..."
    sudo -n -u postgres -s shp2pgsql -s 2154 -a -g the_geom -W "LATIN1"  data/layers/pnm/pnm2014_07.shp layers.l_zonesstatut > data/layers/sql/pnm.sql
    export PGPASSWORD=$user_pg_pass;psql -h geonatdbhost -U $user_pg -d $db_name -f data/layers/sql/pnm.sql &>> log/install_db.log
    echo "...Parcs naturels régionaux..."
    sudo -n -u postgres -s shp2pgsql -s 2154 -a -g the_geom -W "UTF8"  data/layers/pnr/pnr2014_10.shp layers.l_zonesstatut > data/layers/sql/pnr.sql
    export PGPASSWORD=$user_pg_pass;psql -h geonatdbhost -U $user_pg -d $db_name -f data/layers/sql/pnr.sql &>> log/install_db.log
    echo "...Sites Ramsar..."
    sudo -n -u postgres -s shp2pgsql -s 2154 -a -g the_geom -W "LATIN1"  data/layers/ramsar/ramsar2013.shp layers.l_zonesstatut > data/layers/sql/ramsar.sql
    export PGPASSWORD=$user_pg_pass;psql -h geonatdbhost -U $user_pg -d $db_name -f data/layers/sql/ramsar.sql &>> log/install_db.log
    echo "...Réserves biologiques..."
    sudo -n -u postgres -s shp2pgsql -s 2154 -a -g the_geom -W "LATIN1"  data/layers/rb/rb.shp layers.l_zonesstatut > data/layers/sql/rb.sql
    export PGPASSWORD=$user_pg_pass;psql -h geonatdbhost -U $user_pg -d $db_name -f data/layers/sql/rb.sql &>> log/install_db.log
    echo "...Réserves intégrales de parc national..."
    sudo -n -u postgres -s shp2pgsql -s 2154 -a -g the_geom -W "LATIN1"  data/layers/ripn/ripn.shp layers.l_zonesstatut > data/layers/sql/ripn.sql
    export PGPASSWORD=$user_pg_pass;psql -h geonatdbhost -U $user_pg -d $db_name -f data/layers/sql/ripn.sql &>> log/install_db.log
    echo "...Réserves naturelles de Corse..."
    sudo -n -u postgres -s shp2pgsql -s 2154 -a -g the_geom -W "LATIN1"  data/layers/rnc/rnc2010.shp layers.l_zonesstatut > data/layers/sql/rnc.sql
    export PGPASSWORD=$user_pg_pass;psql -h geonatdbhost -U $user_pg -d $db_name -f data/layers/sql/rnc.sql &>> log/install_db.log
    echo "...Réserves naturelles de Corse..."
    sudo -n -u postgres -s shp2pgsql -s 2154 -a -g the_geom -W "LATIN1"  data/layers/rncfs/rncfs_2010.shp layers.l_zonesstatut > data/layers/sql/rncfs.sql
    export PGPASSWORD=$user_pg_pass;psql -h geonatdbhost -U $user_pg -d $db_name -f data/layers/sql/rncfs.sql &>> log/install_db.log
    echo "...Réserves naturelles nationales..."
    sudo -n -u postgres -s shp2pgsql -s 2154 -a -g the_geom -W "UTF8"  data/layers/rnn/rnn.shp layers.l_zonesstatut > data/layers/sql/rnn.sql
    export PGPASSWORD=$user_pg_pass;psql -h geonatdbhost -U $user_pg -d $db_name -f data/layers/sql/rnn.sql &>> log/install_db.log
    echo "...Réserves naturelles régionales..."
    sudo -n -u postgres -s shp2pgsql -s 2154 -a -g the_geom -W "LATIN1"  data/layers/rnr/rnr.shp layers.l_zonesstatut > data/layers/sql/rnr.sql
    export PGPASSWORD=$user_pg_pass;psql -h geonatdbhost -U $user_pg -d $db_name -f data/layers/sql/rnr.sql &>> log/install_db.log
    echo "...Natura 2000 Sites d'importance communautaire..."
    sudo -n -u postgres -s shp2pgsql -s 2154 -a -g the_geom -W "LATIN1"  data/layers/sic/sic1409.shp layers.l_zonesstatut > data/layers/sql/sic.sql
    export PGPASSWORD=$user_pg_pass;psql -h geonatdbhost -U $user_pg -d $db_name -f data/layers/sql/sic.sql &>> log/install_db.log
    echo "...Natura 2000 Zones de protection spéciales..."
    sudo -n -u postgres -s shp2pgsql -s 2154 -a -g the_geom -W "LATIN1"  data/layers/zps/zps1409.shp layers.l_zonesstatut > data/layers/sql/zps.sql
    echo "...Zone d'importance pour la conservation des oiseaux..."
    sudo -n -u postgres -s shp2pgsql -s 2154 -a -g the_geom -W "LATIN1"  data/layers/zico/zico.shp layers.l_zonesstatut > data/layers/sql/zico.sql
    export PGPASSWORD=$user_pg_pass;psql -h geonatdbhost -U $user_pg -d $db_name -f data/layers/sql/zico.sql &>> log/install_db.log
    echo "...ZNIEFF 1 continentales..."
    sudo -n -u postgres -s shp2pgsql -s 2154 -a -g the_geom -W "LATIN1"  data/layers/znieff1/znieff1.shp layers.l_zonesstatut > data/layers/sql/znieff1.sql
    export PGPASSWORD=$user_pg_pass;psql -h geonatdbhost -U $user_pg -d $db_name -f data/layers/sql/znieff1.sql &>> log/install_db.log
    echo "...ZNIEFF 2 continentales..."
    sudo -n -u postgres -s shp2pgsql -s 2154 -a -g the_geom -W "LATIN1"  data/layers/znieff2/znieff2.shp layers.l_zonesstatut > data/layers/sql/znieff2.sql
    export PGPASSWORD=$user_pg_pass;psql -h geonatdbhost -U $user_pg -d $db_name -f data/layers/sql/znieff2.sql &>> log/install_db.log
    echo "...ZNIEFF 1 mer..."
    sudo -n -u postgres -s shp2pgsql -s 2154 -a -g the_geom -W "LATIN1"  data/layers/znieff1_mer/znieff1_mer.shp layers.l_zonesstatut > data/layers/sql/znieff1_mer.sql
    export PGPASSWORD=$user_pg_pass;psql -h geonatdbhost -U $user_pg -d $db_name -f data/layers/sql/znieff1_mer.sql &>> log/install_db.log
    echo "...ZNIEFF 2 mer..."
    sudo -n -u postgres -s shp2pgsql -s 2154 -a -g the_geom -W "LATIN1"  data/layers/znieff2_mer/znieff2_mer.shp layers.l_zonesstatut > data/layers/sql/znieff2_mer.sql
    export PGPASSWORD=$user_pg_pass;psql -h geonatdbhost -U $user_pg -d $db_name -f data/layers/sql/znieff2_mer.sql &>> log/install_db.log
    #export PGPASSWORD=$user_pg_pass;psql -h geonatdbhost -U $user_pg -d $db_name  -f data/layers/zonesstatut.sql &>> log/install_db.log
    
    echo "Insertion d'un jeu de données test dans les schémas taxonomie, contactfaune et contactinv de la base"
    export PGPASSWORD=$admin_pg_pass;psql -h geonatdbhost -U $admin_pg -d $db_name -f data/taxonomie/data_set_taxonomie.sql  &>> log/install_db.log
    export PGPASSWORD=$admin_pg_pass;psql -h geonatdbhost -U $admin_pg -d $db_name -f data/2154/data_set_synthese_2154.sql  &>> log/install_db.log

    # suppression des fichiers : on ne conserve que les fichiers compressés
    echo "nettoyage..."
    rm /tmp/*.txt
    rm /tmp/*.csv
    rm data/utilisateurs/usershub.sql
    rm data/taxonomie/taxhubdb.sql
    rm data/taxonomie/vm_hierarchie_taxo.sql
    rm data/taxonomie/taxhubdata.sql
    rm data/layers/communes_metropole.sql
    rm data/taxonomie/inpn/ESPECES_REGLEMENTEES_v9.zip
    rm data/taxonomie/inpn/LR_FRANCE.zip
    rm data/taxonomie/inpn/TAXREF_INPN_v9.0.zip
    rm data/taxonomie/inpn/data_inpn_v9_taxhub.sql
    # rm data/layers/zonesstatut.sql
    rm -R data/layers/apb
    rm -R data/layers/bios
    rm -R data/layers/cdl
    rm -R data/layers/cen
    rm -R data/layers/pn
    rm -R data/layers/pnr
    rm -R data/layers/pnm
    rm -R data/layers/ramsar
    rm -R data/layers/rb
    rm -R data/layers/ripn
    rm -R data/layers/rnc
    rm -R data/layers/rncfs
    rm -R data/layers/rnn
    rm -R data/layers/rnr
    rm -R data/layers/sic
    rm -R data/layers/zps
    rm -R data/layers/zico
    rm -R data/layers/znieff1
    rm -R data/layers/znieff2
    rm -R data/layers/znieff1_mer
    rm -R data/layers/znieff2_mer
    rm -R data/layers/sql
    rm data/layers/*.zip

fi
