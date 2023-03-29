#!/bin/bash


echo "Create extensions…"
geonature db exec --json 'CREATE EXTENSION IF NOT EXISTS "hstore";'
geonature db exec --json 'CREATE EXTENSION IF NOT EXISTS "plpgsql";'
geonature db exec --json 'CREATE EXTENSION IF NOT EXISTS "uuid-ossp";'
geonature db exec --json 'CREATE EXTENSION IF NOT EXISTS "pg_trgm";'
geonature db exec --json 'CREATE EXTENSION IF NOT EXISTS "unaccent";'


geonature db upgrade geonature@head -x local-srid=$srid_local
geonature db autoupgrade -x local-srid=$srid_local

geonature db exec "DO 'BEGIN ASSERT EXISTS (SELECT 1 FROM taxonomie.taxref); END'" 2>/dev/null || if [ "$install_bdc_statuts" = true ];
then
    geonature db upgrade ref_geo_fr_departments@head
    geonature taxref import-v16
else
    geonature taxref import-v16 --skip-bdc-statuts
fi
geonature db upgrade nomenclatures_taxonomie_data@head

# Installation des données exemples
if [ "$add_sample_data" = true ];
then
    write_log "Inserting sample datasets..."
    geonature db upgrade geonature-samples@head
fi

if [ "$install_sig_layers" = true ];
then
    geonature db upgrade ref_geo_fr_departments@head
    geonature db upgrade ref_geo_fr_municipalities@head
    geonature db upgrade ref_geo_fr_regions@head
fi

if [ "$install_grid_layer" = true ];
then
    geonature db upgrade ref_geo_inpn_grids_1@head
    geonature db upgrade ref_geo_inpn_grids_5@head
    geonature db upgrade ref_geo_inpn_grids_10@head
fi

if [ "$install_ref_sensitivity" = true ];
then
    geonature db upgrade ref_geo_fr_departments@head
    geonature sensitivity add-referential \
            --source-name "Référentiel sensibilité TAXREF v16 20230203" \
            --url https://geonature.fr/data/inpn/sensitivity/RefSensibiliteV16_20230203.zip \
            --zipfile RefSensibiliteV16_20230203.zip \
            --csvfile RefSensibiliteV16_20230203/RefSensibilite_16.csv  \
            --encoding=iso-8859-15
    geonature sensitivity refresh-rules-cache
fi

if  [ "$install_default_dem" = true ];
then
    geonature db upgrade ign_bd_alti@head -x local-srid=$srid_local
    if [ "$vectorise_dem" = true ];
    then
        geonature db upgrade ign_bd_alti_vector@head
    fi
fi

geonature db autoupgrade -x local-srid=$srid_local
