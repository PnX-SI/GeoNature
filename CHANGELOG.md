CHANGELOG
=========

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
