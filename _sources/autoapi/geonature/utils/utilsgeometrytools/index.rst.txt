geonature.utils.utilsgeometrytools
==================================

.. py:module:: geonature.utils.utilsgeometrytools

.. autoapi-nested-parse::

   Fonctions permettant de manipuler de façon génériques
   les fonctions de flask_sqla_geo



Functions
---------

.. autoapisummary::

   geonature.utils.utilsgeometrytools.export_as_geo_file


Module Contents
---------------

.. py:function:: export_as_geo_file(export_format, export_view, db_cols, geojson_col, data, file_name)

   Fonction générant un fixhier export au format shp ou gpkg

   .. :quickref: Utils;

   Fonction générant un fixhier export au format shp ou gpkg


   :param export_format: format d'export
   :type export_format: str() gpkg ou shapefile

   :param export_view: Table correspondant aux données à exporter
   :type export_view: GenericTableGeo

   :param db_cols: Liste des colonnes
   :type db_cols: list

   :param geojson_col: Nom de la colonne contenant le geojson
   :type geojson_col: str

   :param data: Résulats
   :type data: list

   :param file_name: Résulats
   :type file_name: str

   :returns: Répertoire où sont stockées les données et nom du fichier avec son extension


