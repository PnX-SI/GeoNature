from sqlalchemy import or_
from werkzeug.exceptions import NotFound

from geonature.utils.env import DB
from geonature.core.gn_meta.models import TDatasets

from geonature.utils.utilssqlalchemy import testDataType
from geonature.utils.errors import GeonatureApiError
from .utils import get_nomenclature_filters

from .models import (
    TRelevesOccurrence,
    TOccurrencesOccurrence,
    CorCountingOccurrence,
    corRoleRelevesOccurrence,
)
from geonature.core.gn_meta.models import TDatasets, CorDatasetActor


class ReleveRepository():
    """
        Repository: classe permettant l'acces au données
        d'un modèle de type 'releve'
        """

    def __init__(self, model):
        self.model = model

    def get_one(self, id_releve, info_user):
        """Return one releve
        params:
         - id_releve: integer
         - info_user: TRole object model
        """
        releve = DB.session.query(self.model).get(id_releve)
        if not releve:
            raise NotFound(
                'The releve "{}" does not exist'.format(id_releve)
            )
        return releve.get_releve_if_allowed(info_user)

    def update(self, releve, info_user, geom):
        """ Update the current releve if allowed
        params:
        - releve: a Releve object model
        - info_user: Trole object model
        """
        releve = releve.get_releve_if_allowed(info_user)
        DB.session.merge(releve)
        DB.session.commit()
        return releve

    def delete(self, id_releve, info_user):
        """Delete a releve
        params:
         - id_releve: integer
         - info_user: TRole object model"""

        releve = DB.session.query(self.model).get(id_releve)
        if releve:
            releve = releve.get_releve_if_allowed(info_user)
            DB.session.delete(releve)
            DB.session.commit()
            return releve
        raise NotFound('The releve "{}" does not exist'.format(id_releve))

    def filter_query_with_autorization(self, user):
        q = DB.session.query(self.model)
        if user.tag_object_code == '2':
            allowed_datasets = TDatasets.get_user_datasets(user)
            q = q.filter(
                or_(
                    self.model.id_dataset.in_(tuple(allowed_datasets)),
                    self.model.observers.any(id_role=user.id_role),
                    self.model.id_digitiser == user.id_role
                )
            )
        elif user.tag_object_code == '1':
            q = q.filter(
                or_(
                    self.model.observers.any(id_role=user.id_role),
                    self.model.id_digitiser == user.id_role
                )
            )
        return q

    def filter_query_generic_table(self, user):
        """
        Return a prepared query filter with cruved authorization
        from a generic_table (a view)
        """
        q = DB.session.query(self.model.tableDef)
        if user.tag_object_code in ('1', '2'):
            q = q.outerjoin(corRoleRelevesOccurrence, self.model.tableDef.columns.id_releve_occtax ==
                            corRoleRelevesOccurrence.columns.id_releve_occtax)
            if user.tag_object_code == '2':
                allowed_datasets = TDatasets.get_user_datasets(user)
                q = q.filter(
                    or_(
                        self.model.tableDef.columns.id_dataset.in_(tuple(allowed_datasets)),
                        corRoleRelevesOccurrence.columns.id_role == user.id_role,
                        self.model.tableDef.columns.id_digitiser == user.id_role
                    )
                )
            elif user.tag_object_code == '1':
                q = q.filter(
                    or_(
                        corRoleRelevesOccurrence.columns.id_role == user.id_role,
                        self.model.tableDef.columns.id_digitiser == user.id_role
                    )
                )
        return q

    def get_all(self, info_user):
        """
            Return all the data from Releve model filtered with
            the cruved authorization
        """
        q = self.filter_query_with_autorization(info_user)
        data = q.all()
        if data:
            return data
        raise NotFound('No releve found')

    def get_filtered_query(self, info_user, from_generic_table=False):
        """
            Return a query object already filtered with
            the cruved authorization
        """
        if not from_generic_table:
            return self.filter_query_with_autorization(info_user)
        else:
            return self.filter_query_generic_table(info_user)


def get_query_occtax_filters(args, mappedView, q, from_generic_table=False):
    if from_generic_table:
        mappedView = mappedView.tableDef.columns
    params = args.to_dict()
    testT = None
    if 'cd_nom' in params:
        testT = testDataType(params.get('cd_nom'), DB.Integer, 'cd_nom')
        if testT:
            raise GeonatureApiError(message=testT)
        q = q.join(
            TOccurrencesOccurrence,
            TOccurrencesOccurrence.id_releve_occtax ==
            mappedView.id_releve_occtax
        ).filter(
            TOccurrencesOccurrence.cd_nom == int(params.pop('cd_nom'))
        )
    if 'observers' in params:
        q = q.join(
            corRoleRelevesOccurrence,
            corRoleRelevesOccurrence.columns.id_releve_occtax ==
            mappedView.id_releve_occtax
        ).filter(
            corRoleRelevesOccurrence.columns.id_role.in_(
                args.getlist('observers')
            )
        )
        params.pop('observers')

    if 'date_up' in params:
        testT = testDataType(params.get('date_up'), DB.DateTime, 'date_up')
        if testT:
            raise GeonatureApiError(message=testT)
        q = q.filter(mappedView.date_max <= params.pop('date_up'))
    if 'date_low' in params:
        testT = testDataType(
            params.get('date_low'),
            DB.DateTime,
            'date_low'
        )
        if testT:
            raise GeonatureApiError(message=testT)
        q = q.filter(mappedView.date_min >= params.pop('date_low'))
    if 'date_eq' in params:
        testT = testDataType(
            params.get('date_eq'),
            DB.DateTime,
            'date_eq'
        )
        if testT:
            raise GeonatureApiError(message=testT)
        q = q.filter(mappedView.date_min == params.pop('date_eq'))
    if 'altitude_max' in params:
        testT = testDataType(
            params.get('altitude_max'),
            DB.Integer,
            'altitude_max'
        )
        if testT:
            raise GeonatureApiError(message=testT)
        q = q.filter(mappedView.altitude_max <= params.pop('altitude_max'))

    if 'altitude_min' in params:
        testT = testDataType(
            params.get('altitude_min'),
            DB.Integer,
            'altitude_min'
        )
        if testT:
            raise GeonatureApiError(message=testT)
        q = q.filter(mappedView.altitude_min >= params.pop('altitude_min'))

    if 'organism' in params:
        q = q.join(
            CorDatasetActor,
            CorDatasetActor.id_dataset == mappedView.id_dataset
        ).filter(
            CorDatasetActor.id_actor == int(params.pop('organism'))
        )

    if 'observateurs' in params:
        observers_query = "%{}%".format(params.pop('observateurs'))
        q = q.filter(mappedView.observateurs.ilike(observers_query))

    if from_generic_table:
        table_columns = mappedView
    else:
        table_columns = mappedView.__table__.columns

    # Generic Filters
    for param in params:
        if param in table_columns:
            col = getattr(table_columns, param)
            testT = testDataType(params[param], col.type, param)
            if testT:
                raise GeonatureApiError(message=testT)
            q = q.filter(col == params[param])

    releve_filters, occurrence_filters, counting_filters = get_nomenclature_filters(params)
    if len(releve_filters) > 0:
        q = q.join(
            TRelevesOccurrence,
            mappedView.id_releve_occtax ==
            TRelevesOccurrence.id_releve_occtax
        )
        for nomenclature in releve_filters:
            col = getattr(TRelevesOccurrence.__table__.columns, nomenclature)
            q = q.filter(col == params.pop(nomenclature))

    if len(occurrence_filters) > 0:
        q = q.join(
            TOccurrencesOccurrence,
            mappedView.id_releve_occtax ==
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
                mappedView.id_releve_occtax
            ).join(
                CorCountingOccurrence,
                TOccurrencesOccurrence.id_occurrence_occtax ==
                CorCountingOccurrence.id_occurrence_occtax

            )
        for nomenclature in counting_filters:
            col = getattr(CorCountingOccurrence.__table__.columns, nomenclature)
            q = q.filter(col == params.pop(nomenclature))

    # Order by
    if 'orderby' in params:
        if params.get('orderby') in mappedView.__table__.columns:
            orderCol = getattr(
                mappedView.__table__.columns,
                params['orderby']
            )
        # else:
        #     orderCol = getattr(
        #         mappedView.__table__.columns,
        #         'occ_meta_create_date'
        #     )

        if 'order' in params:
            if (params['order'] == 'desc'):
                orderCol = orderCol.desc()

        q = q.order_by(orderCol)

    return q
