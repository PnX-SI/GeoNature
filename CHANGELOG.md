CHANGELOG
=========

1.1.2 (unreleased)
------------------

**🚀 Nouveautés**

* Ajout d'un fonction ``get_local_srid`` pour récupérer le srid local


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
