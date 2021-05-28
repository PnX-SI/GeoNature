from flask import current_app
from sqlalchemy import or_, case, func
from sqlalchemy.sql import func, and_
from sqlalchemy.orm.exc import NoResultFound
from urllib.parse import urljoin
from werkzeug.exceptions import NotFound


from utils_flask_sqla.generic import testDataType

from geonature.utils.env import DB
from geonature.core.gn_commons.models import TMedias, VLatestValidations
from geonature.utils.errors import GeonatureApiError
from .utils import get_nomenclature_filters, is_already_joined

from .models import (
    TRelevesOccurrence,
    TOccurrencesOccurrence,
    CorCountingOccurrence,
    corRoleRelevesOccurrence,
)
from geonature.core.gn_meta.models import TDatasets, CorDatasetActor
from pypnusershub.db.models import User


class ReleveRepository:
    """
        Repository: classe permettant l'acces au données
        d'un modèle de type 'releve'
        """

    def __init__(self, model):
        self.model = model

    #Ajout de colonne dynamique
    def input(self,row,col,val):
        self.dat[row] = {col:val}
        pass

    def get_one(self, id_releve, info_user):
        """ Get one releve model if allowed
        params:
         - id_releve: integer
         - info_user: TRole object model

        Return: 
            Tuple(the releve model, the releve as geojson)
        """
        releve = DB.session.query(self.model).get(id_releve)
        if not releve:
            raise NotFound('The releve "{}" does not exist'.format(id_releve))
        # check if the user is autorized
        releve = releve.get_releve_if_allowed(info_user)
        rel_as_geojson = releve.get_geofeature()
        # add the last validation status
        for occ in rel_as_geojson.get("properties").get("t_occurrences_occtax", []):
            for count in occ.get("cor_counting_occtax", []):
                try:
                    validation_status = (
                        DB.session.query(VLatestValidations)
                        .filter(
                            VLatestValidations.uuid_attached_row == count["unique_id_sinp_occtax"]
                        )
                        .one()
                    )
                except NoResultFound:
                    return releve, rel_as_geojson
                count["validation_status"] = validation_status.as_dict(
                    fields=["mnemonique", "validation_date"]
                )
        return releve, rel_as_geojson

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
        if user.value_filter == "2":
            allowed_datasets = TDatasets.get_user_datasets(user)
            q = q.filter(
                or_(
                    self.model.id_dataset.in_(tuple(allowed_datasets)),
                    self.model.observers.any(id_role=user.id_role),
                    self.model.id_digitiser == user.id_role,
                )
            )
        elif user.value_filter == "1":
            q = q.filter(
                or_(
                    self.model.observers.any(id_role=user.id_role),
                    self.model.id_digitiser == user.id_role,
                )
            )
        return q

    def filter_query_generic_table(self, user):
        """
        Return a prepared query filter with cruved authorization
        from a generic_table (a view)
        """
        q = DB.session.query(self.model.tableDef)
        if user.value_filter in ("1", "2"):
            q = q.outerjoin(
                corRoleRelevesOccurrence,
                self.model.tableDef.columns.id_releve_occtax
                == corRoleRelevesOccurrence.id_releve_occtax,
            )
            if user.value_filter == "2":
                allowed_datasets = TDatasets.get_user_datasets(user)
                q = q.filter(
                    or_(
                        self.model.tableDef.columns.id_dataset.in_(tuple(allowed_datasets)),
                        corRoleRelevesOccurrence.id_role == user.id_role,
                        self.model.tableDef.columns.id_digitiser == user.id_role,
                    )
                )
            elif user.value_filter == "1":
                q = q.filter(
                    or_(
                        corRoleRelevesOccurrence.id_role == user.id_role,
                        self.model.tableDef.columns.id_digitiser == user.id_role,
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
        raise NotFound("No releve found")

    def get_filtered_query(self, info_user, from_generic_table=False):
        """
            Return a query object already filtered with
            the cruved authorization
        """
        if from_generic_table:
            return self.filter_query_generic_table(info_user)
        else:
            return self.filter_query_with_autorization(info_user)
    
    def add_media_in_export(self, query, columns):
        query = query.outerjoin(
            TMedias,
            TMedias.uuid_attached_row == self.model.tableDef.c.permId
        )
        query = query.add_columns(
            func.string_agg(TMedias.title_fr, " | ").label('titreMedia'),
            func.string_agg(TMedias.description_fr, " | ").label('descMedia'),
            func.string_agg(
                case(
                    [
                        (TMedias.media_url == None, TMedias.media_path)
                    ],
                    else_=TMedias.media_url
                ),
            " | "
            ).label("urlMedia")
        )
        query = query.group_by(
            *self.model.db_cols
        )
        added_medias_cols = ["titreMedia", "descMedia", "urlMedia"]
        columns = columns + added_medias_cols
        return query, columns




def get_query_occtax_filters(
    args, mappedView, q, from_generic_table=False, obs_txt_column="observers_txt"
):
    if from_generic_table:
        mappedView = mappedView.tableDef.columns
    params = args.to_dict()
    testT = None
    if "cd_nom" in params:
        testT = testDataType(params.get("cd_nom"), DB.Integer, "cd_nom")
        if testT:
            raise GeonatureApiError(message=testT)
        q = q.join(
            TOccurrencesOccurrence,
            TOccurrencesOccurrence.id_releve_occtax == mappedView.id_releve_occtax,
        ).filter(TOccurrencesOccurrence.cd_nom == int(params.pop("cd_nom")))
    if "observers" in params:
        if not is_already_joined(corRoleRelevesOccurrence, q):
            q = q.join(
                corRoleRelevesOccurrence,
                corRoleRelevesOccurrence.id_releve_occtax == mappedView.id_releve_occtax,
            )

        q = q.filter(corRoleRelevesOccurrence.id_role.in_(args.getlist("observers")))
        params.pop("observers")

    if "date_up" in params:
        testT = testDataType(params.get("date_up"), DB.DateTime, "date_up")
        if testT:
            raise GeonatureApiError(message=testT)
        q = q.filter(mappedView.date_max <= params.pop("date_up"))
    if "date_low" in params:
        testT = testDataType(params.get("date_low"), DB.DateTime, "date_low")
        if testT:
            raise GeonatureApiError(message=testT)
        q = q.filter(mappedView.date_min >= params.pop("date_low"))
    if "date_eq" in params:
        testT = testDataType(params.get("date_eq"), DB.DateTime, "date_eq")
        if testT:
            raise GeonatureApiError(message=testT)
        q = q.filter(mappedView.date_min == params.pop("date_eq"))
    if "altitude_max" in params:
        testT = testDataType(params.get("altitude_max"), DB.Integer, "altitude_max")
        if testT:
            raise GeonatureApiError(message=testT)
        q = q.filter(mappedView.altitude_max <= params.pop("altitude_max"))

    if "altitude_min" in params:
        testT = testDataType(params.get("altitude_min"), DB.Integer, "altitude_min")
        if testT:
            raise GeonatureApiError(message=testT)
        q = q.filter(mappedView.altitude_min >= params.pop("altitude_min"))

    if "organism" in params:
        q = q.join(
            CorDatasetActor, CorDatasetActor.id_dataset == mappedView.id_dataset
        ).filter(CorDatasetActor.id_actor == int(params.pop("organism")))

    if "observers_txt" in params:
        observers_query = "%{}%".format(params.pop("observers_txt"))
        q = q.filter(getattr(mappedView, obs_txt_column).ilike(observers_query))

    if from_generic_table:
        table_columns = mappedView
    else:
        table_columns = mappedView.__table__.columns

    if "non_digital_proof" in params:
        if not is_already_joined(TOccurrencesOccurrence, q):
            q = q.join(
                TOccurrencesOccurrence,
                mappedView.id_releve_occtax == TOccurrencesOccurrence.id_releve_occtax,
            )
        q = q.filter(
            TOccurrencesOccurrence.non_digital_proof == params.pop("non_digital_proof")
        )
    if "digital_proof" in params:
        if not is_already_joined(TOccurrencesOccurrence, q):
            q = q.join(
                TOccurrencesOccurrence,
                mappedView.id_releve_occtax == TOccurrencesOccurrence.id_releve_occtax,
            )
        q = q.filter(TOccurrencesOccurrence.digital_proof == params.pop("digital_proof"))
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
        # if not from generic table, the FROM clause is already from TRelevesOccurrences
        if from_generic_table:
            q = q.join(
                TRelevesOccurrence,
                mappedView.id_releve_occtax == TRelevesOccurrence.id_releve_occtax,
            )
        for nomenclature in releve_filters:
            col = getattr(TRelevesOccurrence.__table__.columns, nomenclature)
            q = q.filter(col == params.pop(nomenclature))

    if len(occurrence_filters) > 0:
        if not is_already_joined(TOccurrencesOccurrence, q):
            q = q.join(
                TOccurrencesOccurrence,
                mappedView.id_releve_occtax == TOccurrencesOccurrence.id_releve_occtax,
            )

        for nomenclature in occurrence_filters:
            col = getattr(TOccurrencesOccurrence.__table__.columns, nomenclature)
            q = q.filter(col == params.pop(nomenclature))

    if len(counting_filters) > 0:
        if len(occurrence_filters) > 0:
            q = q.join(
                CorCountingOccurrence,
                TOccurrencesOccurrence.id_occurrence_occtax
                == CorCountingOccurrence.id_occurrence_occtax,
            )
        else:
            q = q.join(
                TOccurrencesOccurrence,
                TOccurrencesOccurrence.id_releve_occtax == mappedView.id_releve_occtax,
            ).join(
                CorCountingOccurrence,
                TOccurrencesOccurrence.id_occurrence_occtax
                == CorCountingOccurrence.id_occurrence_occtax,
            )
        for nomenclature in counting_filters:
            col = getattr(CorCountingOccurrence.__table__.columns, nomenclature)
            q = q.filter(col == params.pop(nomenclature))
    return q


def get_query_occtax_order(orderby, mappedView, q, from_generic_table=False):
    """
        Permet de d'ordonner sur un champ d'une table
        Ajout d'elements de tris spécifiques/synthétiques
    """
    if from_generic_table:
        mappedView = mappedView.tableDef.columns

    # Order by
    if "orderby" in orderby:
        if orderby.get("orderby") == "date":
            if "order" in orderby and orderby["order"] == "desc":
                orderCol = getattr(mappedView, "date_max")
            else:
                orderCol = getattr(mappedView, "date_min")
        elif orderby.get("orderby") == "nb_taxons" or orderby.get("orderby") == "taxons":
            sub_query = (
                DB.session.query(
                    TRelevesOccurrence.id_releve_occtax,
                    DB.func.count().label("nb_taxons"),
                )
                .join(
                    TOccurrencesOccurrence,
                    TOccurrencesOccurrence.id_releve_occtax == TRelevesOccurrence.id_releve_occtax,
                )
                .group_by(TRelevesOccurrence.id_releve_occtax)
                .subquery()
            )
            q = q.join(
                sub_query,
                sub_query.c.id_releve_occtax == TRelevesOccurrence.id_releve_occtax,
            )
            orderCol = sub_query.c.nb_taxons
        elif orderby.get("orderby") == "dataset":
            q = q.join(TDatasets, TDatasets.id_dataset == TRelevesOccurrence.id_dataset)
            orderCol = TDatasets.dataset_name
        elif orderby.get("orderby") == "observateurs":
            q = q.join(
                corRoleRelevesOccurrence,
                corRoleRelevesOccurrence.id_releve_occtax == TRelevesOccurrence.id_releve_occtax,
            ).join(User, corRoleRelevesOccurrence.id_role == User.id_role)
            orderCol = User.nom_role
        elif orderby.get("orderby") in mappedView.__table__.columns:
            orderCol = getattr(mappedView, orderby["orderby"])

    if "orderCol" in locals():
        if "order" in orderby:
            if orderby["order"] == "desc":
                orderCol = orderCol.desc()
        q = q.order_by(orderCol)
    # ajout d'un ordre id desc obligatoire pour éviter des relevés qui se mettent sur plusieurs pages
    q = q.order_by(getattr(mappedView, "id_releve_occtax").desc())

    return q
