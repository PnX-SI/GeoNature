from flask import Blueprint, request, current_app
from sqlalchemy import exc, or_, func, distinct

from geonature.utils.env import DB
from .models import (
    TRelevesContact,
    TOccurrencesContact,
    CorCountingContact,
    VReleveContact,
    VReleveList,
    corRoleRelevesContact,
    DefaultNomenclaturesValue
)
from .repositories import ReleveRepository
from geonature.utils.utilssqlalchemy import (
    json_resp,
    testDataType,
    csv_resp,
    GenericTable,
    serializeQueryTest
)

from geonature.utils import filemanager
from geonature.core.users.models import TRoles, UserRigth
from geonature.core.gn_meta.models import TDatasets, CorDatasetsActor
from pypnusershub.db.tools import InsufficientRightsError

from pypnusershub import routes as fnauth

from geojson import FeatureCollection
from shapely.geometry import asShape
from geoalchemy2.shape import from_shape

routes = Blueprint('pr_contact', __name__)


@routes.route('/releves', methods=['GET'])
@fnauth.check_auth_cruved('R', True)
@json_resp
def getReleves(info_role):
    releve_repository = ReleveRepository(TRelevesContact)
    data = releve_repository.get_all(info_role)
    return FeatureCollection([n.get_geofeature() for n in data])


@routes.route('/occurrences', methods=['GET'])
@fnauth.check_auth_cruved('R')
@json_resp
def getOccurrences():
    q = DB.session.query(TOccurrencesContact)

    try:
        data = q.all()
    except Exception as e:
        DB.session.rollback()
        raise

    if data:
        return ([n.as_dict() for n in data])
    return {'message': 'not found'}, 404


@routes.route('/releve/<int:id_releve>', methods=['GET'])
@fnauth.check_auth_cruved('R', True)
@json_resp
def getOneReleve(id_releve, info_role):
    releve_repository = ReleveRepository(TRelevesContact)
    data = releve_repository.get_one(id_releve, info_role)
    return data.get_geofeature()


@routes.route('/vrelevecontact', methods=['GET'])
@fnauth.check_auth_cruved('R', True)
@json_resp
def getViewReleveContact(info_role):
    releve_repository = ReleveRepository(VReleveContact)
    q = releve_repository.get_filtered_query(info_role)

    parameters = request.args

    nbResultsWithoutFilter = DB.session.query(VReleveContact).count()

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
        data = q.limit(limit).offset(page * limit).all()
    except Exception as e:
        DB.session.rollback()
        raise

    user = info_role
    user_cruved = fnauth.get_cruved(
        user.id_role,
        current_app.config['ID_APPLICATION_GEONATURE']
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


@routes.route('/vreleve', methods=['GET'])
@fnauth.check_auth_cruved('R', True)
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

    releveRepository = ReleveRepository(VReleveList)
    q = releveRepository.get_filtered_query(info_role)

    params = request.args

    try:
        nbResultsWithoutFilter = VReleveList.query.count()
    except Exception as e:
        DB.session.rollback()

    limit = int(params.get('limit')) if params.get('limit') else 100
    page = int(params.get('offset')) if params.get('offset') else 0

    # Specific Filters
    if 'cd_nom' in params:
        testT = testDataType(params.get('cd_nom'), DB.Integer, 'cd_nom')
        if testT:
            return {'error': testT}, 500
        q = q.join(
            TOccurrencesContact,
            TOccurrencesContact.id_releve_contact ==
            VReleveList.id_releve_contact
        ).filter(
            TOccurrencesContact.cd_nom == int(params.get('cd_nom'))
        )
    if 'observer' in params:
        q = q.join(
            corRoleRelevesContact,
            corRoleRelevesContact.columns.id_releve_contact ==
            VReleveList.id_releve_contact
        ).filter(
            corRoleRelevesContact.columns.id_role.in_(
                params.getlist('observer')
            )
        )

    if 'date_up' in params:
        testT = testDataType(params.get('date_up'), DB.DateTime, 'date_up')
        if testT:
            return {'error': testT}, 500
        q = q.filter(VReleveList.date_min >= params.get('date_up'))
    if 'date_low' in params:
        testT = testDataType(
            params.get('date_low'),
            DB.DateTime,
            'date_low'
        )
        if testT:
            return {'error': testT}, 500
        q = q.filter(VReleveList.date_max <= params.get('date_low'))
    if 'date_eq' in params:
        testT = testDataType(
            params.get('date_eq'),
            DB.DateTime,
            'date_eq'
        )
        if testT:
            return {'error': testT}, 500
        q = q.filter(VReleveList.date_min == params.get('date_eq'))

    if 'organism' in params:
        q = q.join(
            CorDatasetsActor,
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
        DB.session.rollback()
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
        data = q.limit(limit).offset(page * limit).all()
    except exc.IntegrityError as e:
        DB.session.rollback()
    except Exception as e:
        print('roollback')
        DB.session.rollback()

    user = info_role
    user_cruved = fnauth.get_cruved(
        user.id_role,
        current_app.config['ID_APPLICATION_GEONATURE']
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


@routes.route('/releve', methods=['POST'])
@fnauth.check_auth_cruved('C', True)
@json_resp
def insertOrUpdateOneReleve(info_role):
    releveRepository = ReleveRepository(TRelevesContact)
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
        observers = DB.session.query(TRoles).\
            filter(TRoles.id_role.in_(observersList)).all()
        for o in observers:
            releve.observers.append(o)

    for occ in occurrences_contact:
        if occ['cor_counting_contact']:
            cor_counting_contact = occ['cor_counting_contact']
            occ.pop('cor_counting_contact')

        # Test et suppression
        #   des propriétés inexistantes de TOccurrencesContact
        attliste = [k for k in occ]
        for att in attliste:
            if not getattr(TOccurrencesContact, att, False):
                occ.pop(att)

        contact = TOccurrencesContact(**occ)
        for cnt in cor_counting_contact:
            # Test et suppression
            #   des propriétés inexistantes de CorCountingContact
            attliste = [k for k in cnt]
            for att in attliste:
                if not getattr(CorCountingContact, att, False):
                    cnt.pop(att)

            countingContact = CorCountingContact(**cnt)
            contact.cor_counting_contact.append(countingContact)
        releve.t_occurrences_contact.append(contact)

    try:
        if releve.id_releve_contact:
            # get update right of the user
            user_cruved = fnauth.get_cruved(
                info_role.id_role,
                current_app.config['ID_APPLICATION_GEONATURE']
            )
            update_data_scope = next(
                (u['level'] for u in user_cruved if u['action'] == 'U'),
                None
            )
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
    except Exception as e:
        raise

    return releve.get_geofeature()


@routes.route('/releve/<int:id_releve>', methods=['DELETE'])
@fnauth.check_auth_cruved('D', True)
@json_resp
def deleteOneReleve(id_releve, info_role):
    """Suppression d'une données d'un relevé et des occurences associés
      c-a-d un enregistrement de la table t_releves_contact

    Parameters
    ----------
        id_releve: int
            identifiant de l'enregistrement à supprimer

    """
    releveRepository = ReleveRepository(TRelevesContact)
    data = releveRepository.delete(id_releve, info_role)

    return {'message': 'delete with success'}, 200


@routes.route('/releve/occurrence/<int:id_occ>', methods=['DELETE'])
@fnauth.check_auth_cruved('D')
@json_resp
def deleteOneOccurence(id_occ):
    """Suppression d'une données d'occurrence et des dénombrements associés
      c-a-d un enregistrement de la table t_occurrences_contact

    Parameters
    ----------
        id_occ: int
            identifiant de l'enregistrement à supprimer

    """
    q = DB.session.query(TOccurrencesContact)

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


@routes.route('/releve/occurrence_counting/<int:id_count>', methods=['DELETE'])
@fnauth.check_auth_cruved('D')
@json_resp
def deleteOneOccurenceCounting(id_count):
    """Suppression d'une données de dénombrement
      c-a-d un enregistrement de la table cor_counting_contact


    Parameters
    ----------
        id_count: int
            identifiant de l'enregistrement à supprimer

    """
    q = DB.session.query(CorCountingContact)

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

    q = DB.session.query(
        distinct(DefaultNomenclaturesValue.id_type),
        func.pr_contact.get_default_nomenclature_value(
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


@routes.route('/export/sinp', methods=['GET'])
@fnauth.check_auth_cruved('E', True)
@csv_resp
def export_sinp(info_role):
    """ Return the data (CSV) at SINP format
        from pr_contact.export_occtax_sinp view
    If no paramater return all the dataset allowed of the user
    params:
        - id_dataset : integer
        - uuid_dataset: uuid
    """
    viewSINP = GenericTable('pr_contact.export_occtax_dlb', 'pr_contact')
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
                # join on TCounting, TOccurrence, Treleve and corRoleContact
                #   to get users
                q = q.join(
                    CorCountingContact,
                    viewSINP.tableDef.columns.identifiantPermanent == CorCountingContact.unique_id_sinp_occtax
                ).join(
                    TOccurrencesContact,
                    CorCountingContact.id_occurrence_contact == TOccurrencesContact.id_occurrence_contact
                ).join(
                    TRelevesContact,
                    TOccurrencesContact.id_releve_contact == TRelevesContact.id_releve_contact
                ).join(
                    corRoleRelevesContact,
                    TRelevesContact.id_releve_contact == corRoleRelevesContact.columns.id_releve_contact
                )
                q = q.filter(
                    or_(
                        corRoleRelevesContact.columns.id_role == info_role.id_role,
                        TRelevesContact.id_digitiser == info_role.id_role
                    )
                )
        q = q.filter(viewSINP.tableDef.columns.jddId == str(uuid_dataset))
    data = q.all()
    data = serializeQueryTest(data, q.column_descriptions)
    viewSINP.columns.remove('jddId')
    return (
        filemanager.removeDisallowedFilenameChars('export_sinp'),
        data,
        viewSINP.columns,
        ';'
    )


@routes.route('/test', methods=['GET'])
@json_resp
def test(id_dataset=None, uuid_dataset=None):
    info_role = UserRigth(
        id_role=2,
        id_organisme=-1,
        tag_object_code="2",
        tag_action_code="R"
    )
    return 'la'
