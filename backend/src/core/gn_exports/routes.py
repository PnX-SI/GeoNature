# coding: utf8
from __future__ import (unicode_literals, print_function,
                        absolute_import, division)

from flask import Blueprint, request
from flask_sqlalchemy import SQLAlchemy

from sqlalchemy import or_

from ...utils.utilssqlalchemy import json_resp
from ...utils import filemanager 

db = SQLAlchemy()

routes = Blueprint('gn_exports', __name__)


# @routes.route('/exportcsv/<int:idView>', methods=['GET'])
# @csv_resp
# def genericExport():
""" Routes générique pour l'export en CSV des vues des différents protocoles
TODO: faire la table et le modele TViewExports qui liste tous les exports disponibles
Paramètres: 
    idView: int
        id de la vue dans la table TViewExports
    organism: id
        id de l'organisme
    dataset: int
        id du dataset """
#     params = request.args
#     view = db.session.query(TViewExport).get(idView)
#     cleanViewName = filemanager.removeDisallowedFilenameChars(view.table_name)
#     viewTable = GenericTable(view.table_name, view.schema_name)

#     dataSetColumnName = view.dataSetColumnName

#     q = db.session.query(viewTable)

#     if 'organism' in params:
#         q = q.join(
#             TDatasets,
#             TDatasets.id_dataset == getattr(viewTable, dataSetColumnName)
#         ).filter(
#             or_(
#                 TDatasets.id_organism_owner == int(params.get('organism')),
#                 TDatasets.id_organism_producer == int(params.get('organism')),
#                 TDatasets.id_organism_administrator == int(params.get('organism')),
#                 TDatasets.id_organism_funder == int(params.get('organism'))
#               )
#         )
#     if 'dataset' in params:
#         q.filter(getattr(viewTable, dataSetColumnName) == params.get('dataset'))
    
#     data = q.all()
#     data = serializeQueryTest(data, q.column_descriptions)
#     return (cleanViewName, data, viewSINP.columns, ';')