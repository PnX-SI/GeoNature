Instalation
------------

Configuration
-------------
Un certain nombre de paramètre permettre de customiser le module en modifiant le fichier `conf/conf_gn_module.toml``(vous pouvez vous inspirer du fichier `conf/conf_gn_module.toml`` qui liste l'ensemble des paramètres dispobinibles et leurs valeurs par défaut):

- Paramétrage les aires affichable sur la carte "Synthese par entité géographique": ``AREA_TYPE``. Passer un tableau de type_code (table ``ref_geo.bib_areas_types``)
- Paramétrage du nombre de classe sur la cartographie "Synthese par entité géographique". Voir ``BORNE_TAXON`` et ``BORNE_OBS`` pour changer respectivement l'affichage en mode 'nombre d'observation et 'nombre de taxon'.