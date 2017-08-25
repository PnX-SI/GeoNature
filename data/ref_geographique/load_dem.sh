#Ebauche de script permettant de changer un nmpt
#@TODO finialisation des commandes
gdalwarp -t_srs EPSG:2154 ~/monmnt.tiffmnt.tif
raster2pgsql -c -C -I -M -t 100x100 mnt.tif|psql -h localhost -U monuser geonature2db
