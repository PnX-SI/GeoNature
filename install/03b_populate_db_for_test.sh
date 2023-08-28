geonature db upgrade geonature@head -x local-srid=2154
geonature db autoupgrade -x local-srid=2154
geonature db upgrade ref_geo_fr_departments@head
geonature db upgrade taxhub@head
geonature taxref import-v16
geonature db upgrade geonature-samples@head
geonature db upgrade nomenclatures_taxonomie_data@head
geonature db upgrade ref_geo_fr_municipalities@head
geonature db upgrade ref_geo_fr_departments@head
geonature db upgrade ref_geo_inpn_grids_5@head
geonature sensitivity add-referential \
    --source-name "Référentiel sensibilité TAXREF v16 20230203" \
    --url https://geonature.fr/data/inpn/sensitivity/RefSensibiliteV16_20230203.zip \
    --zipfile RefSensibiliteV16_20230203.zip \
    --csvfile RefSensibiliteV16_20230203/RefSensibilite_16.csv \
    --encoding=iso-8859-15
