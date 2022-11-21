CHANGELOG
=========

1.2.1 (2022-11-21)
------------------

**🐛 Corrections**

* Marquage du champs géométrique ``ref_geo.l_areas.geojson_4326`` comme différé afin de ne pas le renvoyer en raison de son poids sauf si demandé explicitement.


1.2.0 (2022-10-20)
------------------

**🚀 Nouveautés**

* Ajout de tables et de modèles pour un référentiel geographique de linéaires
    * Peut être organisé en tronçons (stockés dans ``ref_geo.l_linears``) qui peuvent appartenir à un groupe de linéaires (``ref_geo.t_linear_groups``)
    * Par exemple les tronçons d'autoroute ``A7_40727085`` et ``A7_40819117`` appartiennent au groupe ``Autoroute A7``
* Ajout d'une fonction ``get_local_srid`` pour récupérer le SRID local automatiquement à partir des données, à partir de la fonction ``FIND_SRID``


1.1.1 (2022-08-31)
------------------

**🚀 Nouveautés**

* Ajout de la sous-commande ``ref_geo info`` permettant de lister les zones par types.
* Mise-à-jour des dépendances :
    * Utils-Flask-SQLAlchemy 0.3.0
    * Utils-Flask-SQLAlchemy-Geo 0.2.4

**🐛 Corrections**

* Ajout des champs manquants au modèle ``LAreas``.


1.1.0 (2022-06-03)
------------------

**🚀 Nouveautés**

* Ajout des modèles SQLAlchemy géographiques

**🐛 Corrections**

* Auto-détection du SRID local sans accéder aux paramètres de GeoNature


1.0.1 (2022-03-04)
------------------

**🐛 Corrections**

* Correction du trigger de calcule de l’altitude min / max.


1.0.0 (2022-03-04)
------------------

Externalisation du référentiel géographique de GeoNature 2.9.2.

**🚀 Nouveautés**

* Le SRID local est déterminé automatiquement à partir du SRID de la colonne ``ref_geo.l_areas.geom``.
