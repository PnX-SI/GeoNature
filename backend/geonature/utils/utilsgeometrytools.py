"""
    Fonctions permettant de manipuler de façon génériques
    les fonctions de flask_sqla_geo
"""

from pathlib import Path

from flask import current_app

from geonature.utils import filemanager


def export_as_geo_file(export_format, export_view, db_cols, geojson_col, data, file_name):
    """Fonction générant un fixhier export au format shp ou gpkg

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
    """
    if export_format == "gpkg":
        geo_format = "gpkg"
        dir_path = Path(current_app.config["MEDIA_FOLDER"]) / "geopackages"
        dwn_extension = "gpkg"
    elif export_format == "shapefile":
        geo_format = "shp"
        dir_path = Path(current_app.config["MEDIA_FOLDER"]) / "shapefiles"
        dwn_extension = "zip"
    dir_path.mkdir(parents=True, exist_ok=True)
    dir_path = str(dir_path)

    filemanager.delete_recursively(dir_path, excluded_files=[".gitkeep"])
    export_view.as_geofile(
        export_format=geo_format,
        db_cols=db_cols,
        geojson_col=geojson_col,
        data=data,
        dir_path=dir_path,
        file_name=file_name,
    )
    return dir_path, file_name + "." + dwn_extension
