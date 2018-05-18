from flask import Blueprint, request

from geonature.utils.env import DB

from geonature.core.gn_monitoring.models import (
    TBaseSites
)
from geonature.utils.utilssqlalchemy import json_resp


routes = Blueprint('gn_monitoring', __name__)


@routes.route('/siteslist', methods=['GET'])
@json_resp
def get_list_sites():
    '''
        Retourne la liste des sites pour une application au format :
            {id_base_site, nom site}

        Parameters
        ----------
         - id_site : identifiant de la base site
    '''
    q = DB.session.query(
        TBaseSites.id_base_site,
        TBaseSites.base_site_name,
        TBaseSites.base_site_code
    )
    parameters = request.args

    if parameters.get('id_app'):
        q = q.filter(
            TBaseSites.applications.any(id_application=parameters.get('id_app'))
        )

    if parameters.get('id_base_site'):
        q = q.filter(
            TBaseSites.id_base_site == parameters.get('id_base_site')
        )

    if parameters.get('base_site_name'):
        q = q.filter(
            TBaseSites.base_site_name.ilike("%{}%".format(parameters.get('base_site_name')))
        )

    data = q.all()
    return [
        {
            'id_base_site': n.id_base_site,
            'base_site_name': n.base_site_name
        } for n in data]


@routes.route('/siteslist/<int:id_site>', methods=['GET'])
@json_resp
def get_onelist_site(id_site):
    '''
        Retourne les informations minimal pour un site:
            {id_base_site, nom site}

        Parameters
        ----------
         - id_site : identifiant de la base site
    '''
    q = DB.session.query(
        TBaseSites.id_base_site,
        TBaseSites.base_site_name,
        TBaseSites.base_site_code
    ).filter(
        TBaseSites.id_base_site == id_site
    )

    data = q.one()
    return {
        'id_base_site': data.id_base_site,
        'base_site_name': data.base_site_name
    }

