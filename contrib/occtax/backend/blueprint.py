import os
import datetime
import json
import psycopg2

from flask import(
    Blueprint,
    request,
    current_app,
    session,
    send_from_directory,
    redirect,
    make_response,
    Response,
    render_template
)
from sqlalchemy import exc, or_, func, distinct
from geojson import FeatureCollection


from geonature.utils.env import DB, ROOT_DIR
from geonature.utils import filemanager
from .models import (
    TRelevesOccurrence,
    TOccurrencesOccurrence,
    CorCountingOccurrence,
    VReleveOccurrence,
    VReleveList,
    corRoleRelevesOccurrence,
    DefaultNomenclaturesValue,
    ViewExportDLB
)
from .repositories import ReleveRepository, get_query_occtax_filters
from .utils import get_nomenclature_filters
from geonature.utils.utilssqlalchemy import (
    json_resp,
    testDataType,
    csv_resp,
    GenericTable,
    to_json_resp,
    to_csv_resp,
    serializeQueryTest
)

from geonature.utils.errors import GeonatureApiError
from geonature.core.users.models import TRoles, UserRigth
from geonature.core.gn_meta.models import TDatasets, CorDatasetsActor
from pypnusershub.db.tools import (
    InsufficientRightsError,
    get_or_fetch_user_cruved,
)
from pypnusershub import routes as fnauth


from geojson import FeatureCollection
from shapely.geometry import asShape
from geoalchemy2.shape import from_shape

blueprint = Blueprint('pr_occtax', __name__)


@blueprint.route('/releves', methods=['GET'])
@fnauth.check_auth_cruved('R', True, id_app=current_app.config.get('occtax'))
@json_resp
def getReleves(info_role):
    releve_repository = ReleveRepository(TRelevesOccurrence)
    data = releve_repository.get_all(info_role)
    return FeatureCollection([n.get_geofeature() for n in data])


@blueprint.route('/occurrences', methods=['GET'])
@fnauth.check_auth_cruved('R', id_app=current_app.config.get('occtax'))
@json_resp
def getOccurrences():
    q = DB.session.query(TOccurrencesOccurrence)
    data = q.all()

    return ([n.as_dict() for n in data])


@blueprint.route('/releve/<int:id_releve>', methods=['GET'])
@fnauth.check_auth_cruved('R', True, id_app=current_app.config.get('occtax'))
@json_resp
def getOneReleve(id_releve, info_role):
    releve_repository = ReleveRepository(TRelevesOccurrence)
    data = releve_repository.get_one(id_releve, info_role)
    user_cruved = get_or_fetch_user_cruved(
        session=session,
        id_role=info_role.id_role,
        id_application=blueprint.config['id_application'],
        id_application_parent=current_app.config['ID_APPLICATION_GEONATURE']
    )
    releve_cruved = data.get_releve_cruved(info_role, user_cruved)
    return {
        'releve': data.get_geofeature(),
        'cruved': releve_cruved
        }


@blueprint.route('/vreleveocctax', methods=['GET'])
@fnauth.check_auth_cruved(
    'R',
    True,
    id_app=current_app.config.get('occtax')
)
@json_resp
def getViewReleveOccurrence(info_role):
    releve_repository = ReleveRepository(VReleveOccurrence)
    q = releve_repository.get_filtered_query(info_role)

    parameters = request.args

    nbResultsWithoutFilter = DB.session.query(VReleveOccurrence).count()

    limit = int(parameters.get('limit')) if parameters.get('limit') else 100
    page = int(parameters.get('offset')) if parameters.get('offset') else 0

    # Filters
    for param in parameters:
        if param in VReleveOccurrence.__table__.columns:
            col = getattr(VReleveOccurrence.__table__.columns, param)
            q = q.filter(col == parameters[param])

    # Order by
    if 'orderby' in parameters:
        if parameters.get('orderby') in VReleveOccurrence.__table__.columns:
            orderCol = getattr(
                VReleveOccurrence.__table__.columns,
                parameters['orderby']
            )
        # else:
        #     orderCol = getattr(
        #         VReleveOccurrence.__table__.columns,
        #         'occ_meta_create_date'
        #     )

        if 'order' in parameters:
            if (parameters['order'] == 'desc'):
                orderCol = orderCol.desc()

        q = q.order_by(orderCol)

    try:
        data = q.limit(limit).offset(page * limit).all()
    except Exception as e:
        DB.session.rollback()
        raise

    user = info_role
    user_cruved = get_or_fetch_user_cruved(
        session=session,
        id_role=info_role.id_role,
        id_application=blueprint.config['id_application'],
        id_application_parent=current_app.config['ID_APPLICATION_GEONATURE']
    )
    featureCollection = []

    for n in data:
        releve_cruved = n.get_releve_cruved(user, user_cruved)
        feature = n.get_geofeature()
        feature['properties']['rights'] = releve_cruved
        featureCollection.append(feature)

    if data:
        return {
            'items': FeatureCollection(featureCollection),
            'total': nbResultsWithoutFilter
        }
    return {'message': 'not found'}, 404


    
@blueprint.route('/vreleve', methods=['GET'])
@fnauth.check_auth_cruved(
    'R',
    True,
    id_app=current_app.config.get('occtax')
)
@json_resp
def getViewReleveList(info_role):
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
        observers: int
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
    releveRepository = ReleveRepository(VReleveList)
    q = releveRepository.get_filtered_query(info_role)

    params = request.args.to_dict()

    nbResultsWithoutFilter = VReleveList.query.count()

    limit = int(params.get('limit')) if params.get('limit') else 100
    page = int(params.get('offset')) if params.get('offset') else 0
    # Specific Filters
    if 'cd_nom' in params:
        testT = testDataType(params.get('cd_nom'), DB.Integer, 'cd_nom')
        if testT:
            raise GeonatureApiError(message=testT)
        q = q.join(
            TOccurrencesOccurrence,
            TOccurrencesOccurrence.id_releve_occtax ==
            VReleveList.id_releve_occtax
        ).filter(
            TOccurrencesOccurrence.cd_nom == int(params.pop('cd_nom'))
        )
    if 'observers' in params:
        q = q.join(
            corRoleRelevesOccurrence,
            corRoleRelevesOccurrence.columns.id_releve_occtax ==
            VReleveList.id_releve_occtax
        ).filter(
            corRoleRelevesOccurrence.columns.id_role.in_(
                request.args.getlist('observers')
            )
        )
        params.pop('observers')

    if 'date_up' in params:
        testT = testDataType(params.get('date_up'), DB.DateTime, 'date_up')
        if testT:
            raise GeonatureApiError(message=testT)
        q = q.filter(VReleveList.date_min >= params.pop('date_up'))
    if 'date_low' in params:
        testT = testDataType(
            params.get('date_low'),
            DB.DateTime,
            'date_low'
        )
        if testT:
            raise GeonatureApiError(message=testT)
        q = q.filter(VReleveList.date_max <= params.pop('date_low'))
    if 'date_eq' in params:
        testT = testDataType(
            params.get('date_eq'),
            DB.DateTime,
            'date_eq'
        )
        if testT:
            raise GeonatureApiError(message=testT)
        q = q.filter(VReleveList.date_min == params.pop('date_eq'))
    if 'altitude_max' in params:
        testT = testDataType(
            params.get('altitude_max'),
            DB.Integer,
            'altitude_max'
        )
        if testT:
            raise GeonatureApiError(message=testT)
        q = q.filter(VReleveList.altitude_max <= params.pop('altitude_max'))

    if 'altitude_min' in params:
        testT = testDataType(
            params.get('altitude_min'),
            DB.Integer,
            'altitude_min'
        )
        if testT:
            raise GeonatureApiError(message=testT)
        q = q.filter(VReleveList.altitude_min >= params.pop('altitude_min'))

    if 'organism' in params:
        q = q.join(
            CorDatasetsActor,
            CorDatasetsActor.id_dataset == VReleveList.id_dataset
        ).filter(
            CorDatasetsActor.id_actor == int(params.pop('organism'))
        )

    if 'observateurs' in params:
        observers_query = "%{}%".format(params.pop('observateurs'))
        q = q.filter(VReleveList.observateurs.ilike(observers_query))


    # Generic Filters
    for param in params:
        if param in VReleveList.__table__.columns:
            col = getattr(VReleveList.__table__.columns, param)
            testT = testDataType(params[param], col.type, param)
            if testT:
                raise GeonatureApiError(message=testT)
            q = q.filter(col == params[param])
    
    releve_filters, occurrence_filters, counting_filters = get_nomenclature_filters(params)
    if len(releve_filters) > 0:
        q = q.join(
            TRelevesOccurrence,
            VReleveList.id_releve_occtax ==
            TRelevesOccurrence.id_releve_occtax
        )
        for nomenclature in releve_filters:
            col = getattr(TRelevesOccurrence.__table__.columns, nomenclature)            
            q = q.filter(col == params.pop(nomenclature))

    if len(occurrence_filters) > 0:
        q = q.join(
            TOccurrencesOccurrence,
            VReleveList.id_releve_occtax ==
            TOccurrencesOccurrence.id_releve_occtax
        )
        for nomenclature in occurrence_filters:
            col = getattr(TOccurrencesOccurrence.__table__.columns, nomenclature)
            q = q.filter(col == params.pop(nomenclature))
            
    if len(counting_filters) > 0:
        if len(occurrence_filters) > 0:
            q = q.join(
                CorCountingOccurrence,
                TOccurrencesOccurrence.id_occurrence_occtax ==
                CorCountingOccurrence.id_occurrence_occtax
            )
        else:
            q = q.join(
                TOccurrencesOccurrence,
                TOccurrencesOccurrence.id_releve_occtax ==
                VReleveList.id_releve_occtax
            ).join(
                CorCountingOccurrence,
                TOccurrencesOccurrence.id_occurrence_occtax ==
                CorCountingOccurrence.id_occurrence_occtax

            )
        for nomenclature in counting_filters:
            col = getattr(CorCountingOccurrence.__table__.columns, nomenclature)
            q = q.filter(col == params.pop(nomenclature))

    nbResults = q.count()

    # Order by
    if 'orderby' in params:
        if params.get('orderby') in VReleveList.__table__.columns:
            orderCol = getattr(
                VReleveList.__table__.columns,
                params['orderby']
            )

        if 'order' in params:
            if (params['order'] == 'desc'):
                orderCol = orderCol.desc()

        q = q.order_by(orderCol)

    data = q.limit(limit).offset(page * limit).all()

    user = info_role
    user_cruved = get_or_fetch_user_cruved(
        session=session,
        id_role=info_role.id_role,
        id_application=blueprint.config['id_application'],
        id_application_parent=current_app.config['ID_APPLICATION_GEONATURE']
    )
    featureCollection = []
    for n in data:
        releve_cruved = n.get_releve_cruved(user, user_cruved)
        feature = n.get_geofeature()
        feature['properties']['rights'] = releve_cruved
        featureCollection.append(feature)
    return {
        'total': nbResultsWithoutFilter,
        'total_filtered': nbResults,
        'page': page,
        'limit': limit,
        'items': FeatureCollection(featureCollection)
    }


@blueprint.route('/releve', methods=['POST'])
@fnauth.check_auth_cruved('C', True, id_app=current_app.config.get('occtax'))
@json_resp
def insertOrUpdateOneReleve(info_role):
    releveRepository = ReleveRepository(TRelevesOccurrence)
    data = dict(request.get_json())

    if 't_occurrences_occtax' in data['properties']:
        occurrences_occtax = data['properties']['t_occurrences_occtax']
        data['properties'].pop('t_occurrences_occtax')

    if 'observers' in data['properties']:
        observersList = data['properties']['observers']
        data['properties'].pop('observers')

    # Test et suppression des propriétés inexistantes de TRelevesOccurrence
    attliste = [k for k in data['properties']]
    for att in attliste:
        if not getattr(TRelevesOccurrence, att, False):
            data['properties'].pop(att)
    # set id_digitiser
    data['properties']['id_digitiser'] = info_role.id_role
    releve = TRelevesOccurrence(**data['properties'])

    shape = asShape(data['geometry'])
    releve.geom_4326 = from_shape(shape, srid=4326)

    if observersList is not None:
        observers = DB.session.query(TRoles).\
            filter(TRoles.id_role.in_(observersList)).all()
        for o in observers:
            releve.observers.append(o)

    for occ in occurrences_occtax:
        if occ['cor_counting_occtax']:
            cor_counting_occtax = occ['cor_counting_occtax']
            occ.pop('cor_counting_occtax')

        # Test et suppression
        #   des propriétés inexistantes de TOccurrencesOccurrence
        attliste = [k for k in occ]
        for att in attliste:
            if not getattr(TOccurrencesOccurrence, att, False):
                occ.pop(att)

        occtax = TOccurrencesOccurrence(**occ)
        for cnt in cor_counting_occtax:
            # Test et suppression
            #   des propriétés inexistantes de CorCountingOccurrence
            attliste = [k for k in cnt]
            for att in attliste:
                if not getattr(CorCountingOccurrence, att, False):
                    cnt.pop(att)

            countingOccurrence = CorCountingOccurrence(**cnt)
            occtax.cor_counting_occtax.append(countingOccurrence)
        releve.t_occurrences_occtax.append(occtax)

    if releve.id_releve_occtax:
        # get update right of the user
        user_cruved = get_or_fetch_user_cruved(
            session=session,
            id_role=info_role.id_role,
            id_application=blueprint.config['id_application'],
            id_application_parent=current_app.config['ID_APPLICATION_GEONATURE']
        )
        update_data_scope = user_cruved['U']
        # info_role.tag_object_code = update_data_scope
        user = UserRigth(
            id_role=info_role.id_role,
            tag_object_code=update_data_scope,
            tag_action_code="U",
            id_organisme=info_role.id_organisme
        )
        releve = releveRepository.update(releve, user)
    else:
            DB.session.add(releve)

    DB.session.commit()
    DB.session.flush()

    return releve.get_geofeature()


@blueprint.route('/releve/<int:id_releve>', methods=['DELETE'])
@fnauth.check_auth_cruved('D', True, id_app=current_app.config.get('occtax'))
@json_resp
def deleteOneReleve(id_releve, info_role):
    """Suppression d'une données d'un relevé et des occurences associés
      c-a-d un enregistrement de la table t_releves_occtax

    Parameters
    ----------
        id_releve: int
            identifiant de l'enregistrement à supprimer

    """
    releveRepository = ReleveRepository(TRelevesOccurrence)
    releveRepository.delete(id_releve, info_role)

    return {'message': 'delete with success'}, 200


@blueprint.route('/releve/occurrence/<int:id_occ>', methods=['DELETE'])
@fnauth.check_auth_cruved('D', id_app=current_app.config.get('occtax'))
@json_resp
def deleteOneOccurence(id_occ):
    """Suppression d'une données d'occurrence et des dénombrements associés
      c-a-d un enregistrement de la table t_occurrences_occtax

    Parameters
    ----------
        id_occ: int
            identifiant de l'enregistrement à supprimer

    """
    q = DB.session.query(TOccurrencesOccurrence)

    try:
        data = q.get(id_occ)
    except Exception as e:
        DB.session.rollback()
        raise

    if not data:
        return {'message': 'not found'}, 404

    try:
        DB.session.delete(data)
        DB.session.commit()
    except Exception as e:
        DB.session.rollback()
        raise

    return {'message': 'delete with success'}


@blueprint.route('/releve/occurrence_counting/<int:id_count>', methods=['DELETE'])
@fnauth.check_auth_cruved('D', id_app=current_app.config.get('occtax'))
@json_resp
def deleteOneOccurenceCounting(id_count):
    """Suppression d'une données de dénombrement
      c-a-d un enregistrement de la table cor_counting_occtax


    Parameters
    ----------
        id_count: int
            identifiant de l'enregistrement à supprimer

    """
    q = DB.session.query(CorCountingOccurrence)

    try:
        data = q.get(id_count)
    except Exception as e:
        DB.session.rollback()
        raise

    if not data:
        return {'message': 'not found'}, 404

    try:
        DB.session.delete(data)
        DB.session.commit()
    except Exception as e:
        DB.session.rollback()
        raise

    return {'message': 'delete with success'}


@blueprint.route('/defaultNomenclatures', methods=['GET'])
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

    q = DB.session.query(
        distinct(DefaultNomenclaturesValue.id_type),
        func.pr_occtax.get_default_nomenclature_value(
            DefaultNomenclaturesValue.id_type,
            organism,
            regne,
            group2_inpn
        )
    )
    if len(types) > 0:
        q = q.filter(DefaultNomenclaturesValue.id_type.in_(tuple(types)))
    try:
        data = q.all()
    except Exception:
        DB.session.rollback()
        raise
    if not data:
        return {'message': 'not found'}, 404
    return {d[0]: d[1] for d in data}



@blueprint.route('/export', methods=['GET'])
@fnauth.check_auth_cruved('E', True, id_app=current_app.config.get('occtax'))
def export(info_role):
    from . import models
    
    export_view_name = blueprint.config['export_view_name']
    export_geom_column = blueprint.config['export_geom_columns_name']
    export_id_column_name = blueprint.config['export_id_column_name']
    export_columns = blueprint.config['export_columns']
    
    mapped_class = getattr(models, export_view_name)

    

    releve_repository = ReleveRepository(mapped_class)
    q = releve_repository.get_filtered_query(info_role)    

    q = get_query_occtax_filters(request.args, mapped_class, q)

    data = q.all()

    file_name = datetime.datetime.now().strftime('%Y_%m_%d_%Hh%Mm%S')
    file_name = filemanager.removeDisallowedFilenameChars(file_name)
    
    export_format = request.args['format'] if 'format' in request.args else 'geojson'
    if export_format == 'csv':
        columns = export_columns if len(export_columns) > 0 else mapped_class.__table__.columns.keys()
        return to_csv_resp(
            file_name,
            [d.as_dict() for d in data],
            columns,
            ';'
        )
    elif export_format == 'geojson':
        results = FeatureCollection(
            [d.as_geofeature(
                export_geom_column,
                export_id_column_name,
                recursif=False,
                columns=export_columns
            ) for d in data]
        )
        return to_json_resp(
            results,
            as_file=True,
            filename=file_name,
            indent=4
        )
        
    else:
        try:
            assert hasattr(mapped_class, 'as_shape')
            dir_path = str(ROOT_DIR / 'backend/static/shapefiles')
            mapped_class.as_shape(
                geom_col='geom_4326',
                data=data,
                dir_path=dir_path,
                file_name=file_name,
                columns=export_columns,
                srid=blueprint.config['export_srid']
            )
            return send_from_directory(
                dir_path,
                file_name+'.zip',
                as_attachment=True
            )
        except AssertionError:
            message  = 'The mapped class is not shapeserializable'
            
        except GeonatureApiError as e:
            message = str(e)
        
        return render_template(
            'error.html',
            error=message,
            redirect=current_app.config['URL_APPLICATION']+"/#/occtax"
        )


@blueprint.route('/export/sinp', methods=['GET'])
@fnauth.check_auth_cruved('E', True, id_app=current_app.config.get('occtax'))
@csv_resp
def export_sinp(info_role):
    """ Return the data (CSV) at SINP   
        from pr_occtax.export_occtax_sinp view
        If no paramater return all the dataset allowed of the user
        params:	
        - id_dataset : integer	
        - uuid_dataset: uuid	
    """	
    viewSINP = GenericTable('export_occtax_dlb', 'pr_occtax', None)	
    q = DB.session.query(viewSINP.tableDef)	
    params = request.args	
    allowed_datasets = TDatasets.get_user_datasets(info_role)	
    # if params in empty and user not admin,	
    #    get the data off all dataset allowed	
    if not params.get('id_dataset') and not params.get('uuid_dataset'):	
        if info_role.tag_object_code != '3':	
            allowed_uuid = (	
                str(TDatasets.get_uuid(id_dataset))	
                for id_dataset in allowed_datasets	
            )	
            q = q.filter(viewSINP.tableDef.columns.jddId.in_(allowed_uuid))	
    # filter by dataset id or uuid	
    else:	
        if 'id_dataset' in params:	
            id_dataset = int(params['id_dataset'])	
            uuid_dataset = TDatasets.get_uuid(id_dataset)	
        elif 'uuid_dataset' in params:	
            id_dataset = TDatasets.get_id(params['uuid_dataset'])	
            uuid_dataset = params['uuid_dataset']	
        # if data_scope 1 or 2, check if the dataset requested is allorws	
        if (	
            info_role.tag_object_code == '1' or	
            info_role.tag_object_code == '2'	
        ):	
            if id_dataset not in allowed_datasets:	
                raise InsufficientRightsError(	
                    (	
                        'User "{}" cannot export dataset no "{}'	
                    ).format(info_role.id_role, id_dataset),	
                    403	
                )	
            elif info_role.tag_object_code == '1':	
                # join on TCounting, TOccurrence, Treleve and corRoleOccurrence	
                #   to get users	
                q = q.outerjoin(	
                    CorCountingOccurrence,	
                    viewSINP.tableDef.columns.permId ==	
                    CorCountingOccurrence.unique_id_sinp_occtax	
                ).join(	
                    TOccurrencesOccurrence,	
                    CorCountingOccurrence.id_occurrence_occtax ==	
                    TOccurrencesOccurrence.id_occurrence_occtax	
                ).join(	
                    TRelevesOccurrence,	
                    TOccurrencesOccurrence.id_releve_occtax ==	
                    TRelevesOccurrence.id_releve_occtax	
                ).outerjoin(	
                    corRoleRelevesOccurrence,	
                    TRelevesOccurrence.id_releve_occtax ==	
                    corRoleRelevesOccurrence.columns.id_releve_occtax	
                )	
                q = q.filter(	
                    or_(	
                        corRoleRelevesOccurrence.columns.id_role == info_role.id_role,	
                        TRelevesOccurrence.id_digitiser == info_role.id_role	
                    )	
                )	
        q = q.filter(viewSINP.tableDef.columns.jddId == str(uuid_dataset))	
    data = q.all()	

    export_columns = blueprint.config['export_columns']
    
    file_name = datetime.datetime.now().strftime('%Y-%m-%d-%Hh%Mm%S')	
    return (	
        filemanager.removeDisallowedFilenameChars(file_name),	
        [d.as_dict() for d in data],
        export_columns,	
        ';'	
    )
