# coding: utf8
from __future__ import (unicode_literals, print_function,
                        absolute_import, division)

from flask import Blueprint, request
from flask_sqlalchemy import SQLAlchemy
from sqlalchemy import exc, or_
from sqlalchemy.sql import text


from .models import TRelevesContact, TOccurrencesContact, CorCountingContact, \
    VReleveContact, VReleveList, corRoleRelevesContact, DefaultNomenclaturesValue
from .repositories import ReleveRepository
from ...utils.utilssqlalchemy import json_resp, testDataType, csv_resp, GenericTable, serializeQueryTest

from ...utils import filemanager 
from ...core.users.models import TRoles
from ...core.ref_geo.models import LAreasWithoutGeom
from ...core.gn_meta.models import TDatasets, CorDatasetsActor

from pypnusershub import routes as fnauth

from geojson import Feature, FeatureCollection, dumps
from shapely.geometry import asShape
from geoalchemy2.shape import to_shape, from_shape

routes = Blueprint('pr_contact', __name__)

db = SQLAlchemy()


@routes.route('/releves', methods=['GET'])
@json_resp
def getReleves():

    q = db.session.query(TRelevesContact)

    try:
        data = q.all()
    except Exception as e:
        db.session.rollback()
        raise

    if data:
        return FeatureCollection([n.get_geofeature() for n in data])
    return {'message': 'not found'}, 404


@routes.route('/occurrences', methods=['GET'])
@json_resp
def getOccurrences():
    q = db.session.query(TOccurrencesContact)

    try:
        data = q.all()
    except Exception as e:
        db.session.rollback()
        raise

    if data:
        return ([n.as_dict() for n in data])
    return {'message': 'not found'}, 404

@routes.route('/releve/<int:id_releve>', methods=['GET'])
@fnauth.check_auth_cruved('R', True)
@json_resp
def getOneReleve(id_releve):
    q = db.session.query(TRelevesContact)

    try:
        data = q.get(id_releve)
    except Exception as e:
        db.session.rollback()
        raise
    if data:
        return data.get_geofeature()
    return {'message': 'not found'}, 404


@routes.route('/vrelevecontact', methods=['GET'])
@json_resp
def getViewReleveContact():
    q = db.session.query(VReleveContact)

    parameters = request.args

    nbResultsWithoutFilter = db.session.query(VReleveContact).count()

    limit = int(parameters.get('limit')) if parameters.get('limit') else 100
    page = int(parameters.get('offset')) if parameters.get('offset') else 0

    # Filters
    for param in parameters:
        if param in VReleveContact.__table__.columns:
            col = getattr(VReleveContact.__table__.columns, param)
            q = q.filter(col == parameters[param])

    # Order by
    if 'orderby' in parameters:
        if parameters.get('orderby') in VReleveContact.__table__.columns:
            orderCol = getattr(
                VReleveContact.__table__.columns,
                parameters['orderby']
            )
        else:
            orderCol = getattr(
                VReleveContact.__table__.columns,
                'occ_meta_create_date'
            )

        if 'order' in parameters:
            if (parameters['order'] == 'desc'):
                orderCol = orderCol.desc()

        q = q.order_by(orderCol)

    try:
        data = q.limit(limit).offset(page*limit).all()
    except Exception as e:
        db.session.rollback()
        raise
    if data:
        return {
            'items': FeatureCollection([n.get_geofeature() for n in data]),
            'total': nbResultsWithoutFilter
        }
    return {'message': 'not found'}, 404


@routes.route('/vreleve', methods=['GET'])
@fnauth.check_auth_cruved('R')
@json_resp
def getViewReleveList():
    """
        Retour la liste résumé des relevés avec occurrences


        Parameters
        ----------
        limit: int
            Nombre max de résulats à retourner
        offset: int
            Numéro de la page à retourner
        cd_nom: int
            Filtrer les relevés avec des occurrences avec le taxon x
        observer: int
        date_up: date
            Date minimum des relevés à retourner
        date_low: date
            Date maximum des relevés à retourner
        date_eq: date
            Date exacte des relevés à retourner
        orderby: char
            Nom du champ sur lequel baser l'ordonnancement
        order: char (asc|desc)
            Sens de l'ordonnancement
        organism: int
            id de l'organisme
        [NomChampTableVReleveList]
            Filtre sur le champ NomChampTableVReleveList

        Returns
        -------
        json
        {
            'total': Nombre total de résultat,
            'total_filtered': Nombre total de résultat après filtration ,
            'page': Numéro de la page retournée,
            'limit': Nombre de résultats,
            'items': données au format GeoJson
        }


    """
    q = db.session.query(VReleveList)

    params = request.args

    try:
        nbResultsWithoutFilter = VReleveList.query.count()
    except Exception as e:
        db.session.rollback()

    limit = int(params.get('limit')) if params.get('limit') else 100
    page = int(params.get('offset')) if params.get('offset') else 0

    # Specific Filters
    if 'cd_nom' in params:
        testT = testDataType(params.get('cd_nom'), db.Integer, 'cd_nom')
        if testT:
            return {'error': testT}, 500
        q = q.join(
                TOccurrencesContact,
                TOccurrencesContact.id_releve_contact ==
                VReleveList.id_releve_contact
            ).join(
                TOccurrencesContact.cd_nom == int(params.get('cd_nom'))
            )

    if 'observer' in params:
        q = q.join(
            corRoleRelevesContact,
            corRoleRelevesContact.columns.id_releve_contact ==
            VReleveList.id_releve_contact
        ).filter(corRoleRelevesContact.columns.id_role.in_(
                params.getlist('observer')
            )
        )

    if 'date_up' in params:
        testT = testDataType(params.get('date_up'), db.DateTime, 'date_up')
        if testT:
            return {'error': testT}, 500
        q = q.filter(VReleveList.date_min >= params.get('date_up'))
    if 'date_low' in params:
        testT = testDataType(
            params.get('date_low'),
            db.DateTime,
            'date_low'
        )
        if testT:
            return {'error': testT}, 500
        q = q.filter(VReleveList.date_max <= params.get('date_low'))
    if 'date_eq' in params:
        testT = testDataType(
            params.get('date_eq'),
            db.DateTime,
            'date_eq'
        )
        if testT:
            return {'error': testT}, 500
        q = q.filter(VReleveList.date_min == params.get('date_eq'))

    if 'organism' in params:
        q = q.join(CorDatasetsActor,
        CorDatasetsActor.id_dataset == VReleveList.id_dataset
        ).filter(
            CorDatasetsActor.id_actor == int(params.get('organism'))
        )
    # Generic Filters
    for param in params:
        if param in VReleveList.__table__.columns:
            col = getattr(VReleveList.__table__.columns, param)
            testT = testDataType(params[param], col.type, param)
            if testT:
                return {'error': testT}, 500
            q = q.filter(col == params[param])
    try:
        nbResults = q.count()
    except Exception as e:
        db.session.rollback()
        raise

    # Order by
    if 'orderby' in params:
        if params.get('orderby') in VReleveList.__table__.columns:
            orderCol = getattr(
                VReleveList.__table__.columns,
                params['orderby']
            )
        else:
            orderCol = getattr(
                VReleveList.__table__.columns,
                'occ_meta_create_date'
            )

        if 'order' in params:
            if (params['order'] == 'desc'):
                orderCol = orderCol.desc()

        q = q.order_by(orderCol)

    try:
        data = q.limit(limit).offset(page*limit).all()
    except exc.IntegrityError as e:
        db.session.rollback()
    except Exception as e:
        print('roollback')
        db.session.rollback()
        raise

    return {
        'total': nbResultsWithoutFilter,
        'total_filtered': nbResults,
        'page': page,
        'limit': limit,
        'items': FeatureCollection([n.get_geofeature() for n in data])
    }


@routes.route('/releve', methods=['POST'])
@json_resp
def insertOrUpdateOneReleve():
    try:
        data = dict(request.get_json())

        if 't_occurrences_contact' in data['properties']:
            occurrences_contact = data['properties']['t_occurrences_contact']
            data['properties'].pop('t_occurrences_contact')

        if 'observers' in data['properties']:
            observersList = data['properties']['observers']
            data['properties'].pop('observers')

        # Test et suppression des propriétés inexistantes de TRelevesContact
        attliste = [k for k in data['properties']]
        for att in attliste:
            if not getattr(TRelevesContact, att, False):
                data['properties'].pop(att)

        releve = TRelevesContact(**data['properties'])
        shape = asShape(data['geometry'])
        releve.geom_4326 = from_shape(shape, srid=4326)

        if observersList is not None:
            observers = db.session.query(TRoles).\
                filter(TRoles.id_role.in_(observersList)).all()
            for o in observers:
                releve.observers.append(o)

        for occ in occurrences_contact:
            if occ['cor_counting_contact']:
                cor_counting_contact = occ['cor_counting_contact']
                occ.pop('cor_counting_contact')

            # Test et suppression des propriétés inexistantes de TOccurrencesContact
            attliste = [k for k in occ]
            for att in attliste:
                if not getattr(TOccurrencesContact, att, False):
                    occ.pop(att)

            contact = TOccurrencesContact(**occ)
            for cnt in cor_counting_contact:
                # Test et suppression des propriétés inexistantes de CorCountingContact
                attliste = [k for k in cnt]
                for att in attliste:
                    if not getattr(CorCountingContact, att, False):
                        cnt.pop(att)

                countingContact = CorCountingContact(**cnt)
                contact.cor_counting_contact.append(countingContact)
            releve.t_occurrences_contact.append(contact)

        try:
            if releve.id_releve_contact:
                db.session.merge(releve)
            else:
                db.session.add(releve)
            db.session.commit()
            db.session.flush()
        except Exception as e:
            raise

        return releve.get_geofeature()

    except Exception as e:
        db.session.rollback()
        raise


@routes.route('/releve/<int:id_releve>', methods=['DELETE'])
@json_resp
def deleteOneReleve(id_releve):
    """Suppression d'une données d'un relevé et des occurences associés
      c-a-d un enregistrement de la table t_releves_contact

    Parameters
    ----------
        id_releve: int
            identifiant de l'enregistrement à supprimer

    """
    q = db.session.query(TRelevesContact)
    try:
        data = q.get(id_releve)
    except Exception as e:
        db.session.rollback()
        raise

    if not data:
        return {'message': 'not found'}, 404

    try:
        db.session.delete(data)
        db.session.commit()
    except Exception as e:
        db.session.rollback()
        raise

    return {'message': 'delete with success'}


@routes.route('/releve/occurrence/<int:id_occ>', methods=['DELETE'])
@json_resp
def deleteOneOccurence(id_occ):
    """Suppression d'une données d'occurrence et des dénombrements associés
      c-a-d un enregistrement de la table t_occurrences_contact

    Parameters
    ----------
        id_occ: int
            identifiant de l'enregistrement à supprimer

    """
    q = db.session.query(TOccurrencesContact)

    try:
        data = q.get(id_occ)
    except Exception as e:
        db.session.rollback()
        raise

    if not data:
        return {'message': 'not found'}, 404

    try:
        db.session.delete(data)
        db.session.commit()
    except Exception as e:
        db.session.rollback()
        raise

    return {'message': 'delete with success'}


@routes.route('/releve/occurrence_counting/<int:id_count>', methods=['DELETE'])
@json_resp
def deleteOneOccurenceCounting(id_count):
    """Suppression d'une données de dénombrement
      c-a-d un enregistrement de la table cor_counting_contact


    Parameters
    ----------
        id_count: int
            identifiant de l'enregistrement à supprimer

    """
    q = db.session.query(CorCountingContact)

    try:
        data = q.get(id_count)
    except Exception as e:
        db.session.rollback()
        raise

    if not data:
        return {'message': 'not found'}, 404

    try:
        db.session.delete(data)
        db.session.commit()
    except Exception as e:
        db.session.rollback()
        raise

    return {'message': 'delete with success'}



@routes.route('/defaultNomenclatures', methods=['GET'])
@json_resp
def getDefaultNomenclatures():
    params = request.args
    group2_inpn = '0'
    regne = '0'
    organism = 0
    if 'group2_inpn' in params:
        group2_inpn = params['group2_inpn']
    if 'regne' in params:
        regne = params['regne']
    if 'organism' in params:
        organism = params['organism']
    types = request.args.getlist('id_type')
    query = """SELECT DISTINCT id_type, pr_contact.get_default_nomenclature_value(id_type, :idOrg, :regne, :group2_inpn) AS id_nomenclature
    FROM pr_contact.defaults_nomenclatures_value """
    if len(types) > 0:
        query += " WHERE id_type IN :types"
        result = db.engine.execute(text(query), idOrg=organism, regne=regne, group2_inpn=group2_inpn, types=tuple(types))
    else:
        result = db.engine.execute(text(query), idOrg=organism, regne=regne, group2_inpn=group2_inpn)
    return {r.id_type: r.id_nomenclature for r in result}

    
@routes.route('/exportProvisoire', methods=['GET'])
@csv_resp
def export():
    viewSINP = GenericTable('pr_contact.export_occtax_sinp', 'pr_contact')
    q = db.session.query(viewSINP.tableDef)
    data = q.all()
    data = serializeQueryTest(data, q.column_descriptions)
    return (filemanager.removeDisallowedFilenameChars('export_sinp'), data, viewSINP.columns, ';')

@routes.route('/test', methods=['GET'])
@json_resp
def test():
    from flask import g
    user = db.session.query(TRoles).get(1)
    g.user = user
    releveRepository = ReleveRepository(TRelevesContact)
    print(releveRepository)
    data = releveRepository.get_all(1)
    print(data)

    return FeatureCollection([n.get_geofeature() for n in data])

