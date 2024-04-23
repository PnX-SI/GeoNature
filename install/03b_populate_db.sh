#!/bin/bash
geonature db upgrade geonature@head -x local-srid=$srid_local
geonature db autoupgrade -x local-srid=$srid_local

geonature db exec "DO 'BEGIN ASSERT EXISTS (SELECT 1 FROM taxonomie.taxref); END'" 2>/dev/null \
|| if [ "$install_bdc_statuts" = true ];
then
    geonature db upgrade ref_geo_fr_departments@head
    geonature taxref import-v17
else
    geonature taxref import-v17 --skip-bdc-statuts
fi
geonature db upgrade nomenclatures_taxonomie_data@head

# Installation des données exemples
if [ "$add_sample_data" = true ];
then
    geonature db upgrade geonature-samples@head
fi

if [ "$install_sig_layers" = true ];
then
    geonature db upgrade ref_geo_fr_departments@head
    geonature db upgrade ref_geo_fr_municipalities@head
    geonature db upgrade ref_geo_fr_regions@head
fi

if [ "$install_grid_layer" = true ] || [ "$install_grid_layer_1" = true ];
then
    geonature db upgrade ref_geo_inpn_grids_1@head
fi
if [ "$install_grid_layer" = true ] || [ "$install_grid_layer_5" = true ];
then
    geonature db upgrade ref_geo_inpn_grids_5@head
fi
if [ "$install_grid_layer" = true ] || [ "$install_grid_layer_10" = true ];
then
    geonature db upgrade ref_geo_inpn_grids_10@head
fi

geonature db exec "DO 'BEGIN ASSERT EXISTS (SELECT 1 FROM gn_sensitivity.t_sensitivity_rules); END'" 2>/dev/null \
|| if [ "$install_ref_sensitivity" = true ];
then
    geonature db upgrade ref_geo_fr_departments@head
    geonature sensitivity add-referential \
    --source-name "Référentiel sensibilité TAXREF v17 20240325" \
    --url https://geonature.fr/data/inpn/sensitivity/RefSensibiliteV17_20240325.zip \
    --zipfile RefSensibiliteV17_20240325.zip \
    --csvfile RefSensibiliteV17_20240325/RefSensibilite_17.csv  \
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
