"""
Utility function to manage cruved and all filter of Synthese
Use these functions rather than query.py
Filter the query of synthese using SQLA expression language and 'select' object
https://docs.sqlalchemy.org/en/latest/core/tutorial.html#selecting
much more efficient
"""
import datetime

from flask import current_app, request
from sqlalchemy import func, or_, and_, select, join
from sqlalchemy.sql import text
from sqlalchemy.orm import aliased
from shapely.wkt import loads
from geoalchemy2.shape import from_shape

from utils_flask_sqla_geo.utilsgeometry import circle_from_point

from geonature.utils.env import DB
from geonature.core.taxonomie.models import Taxref, CorTaxonAttribut, TaxrefLR
from geonature.core.gn_synthese.models import (
    Synthese,
    CorObserverSynthese,
    TSources,
    CorAreaSynthese,
)
from geonature.core.gn_meta.models import (
    TAcquisitionFramework,
    CorDatasetActor,
    TDatasets,
)
from geonature.utils.errors import GeonatureApiError



class SyntheseQuery:
    """
        class for building synthese query and manage join

        Attributes:
            query: SQLA select object
            filters: dict of query string filters
            model: a SQLA model
            _already_joined_table: (private) a list of already joined table. Auto build with 'add_join' method
            query_joins = SQLA Join object
    """

    def __init__(self, 
        model, 
        query, 
        filters, 
        id_synthese_column="id_synthese",
        id_dataset_column="id_dataset",
        observers_column="observers",
        id_digitiser_column="id_digitiser",
        with_generic_table=False
    ):
        self.query = query

        # Passage de l'ensemble des filtres
        #   en array pour des questions de compatibilité
        # TODO voir si ça ne peut pas être modifié
        for k in filters.keys():
            if not isinstance(filters[k], list):
                filters[k] = [filters[k]]

        self.filters = filters
        self.first = True
        self.model = model
        self._already_joined_table = []
        self.query_joins = None

        if with_generic_table:
            model_temp = model.columns
        else:
            model_temp = model

        # get the mandatory column
        try:
            self.model_id_syn_col = getattr(model_temp, id_synthese_column)
            self.model_id_dataset_column = getattr(model_temp, id_dataset_column)
            self.model_observers_column = getattr(model_temp, observers_column)
            self.model_id_digitiser_column = getattr(model_temp, id_digitiser_column)
        except AttributeError as e:
            raise GeonatureApiError(
                """the {model} table     does not have a column {e}
                If you change the {model} table, please edit your synthese config (cf EXPORT_***_COL)
                """.format(
                    e=e, model=model
                )
            )

    def add_join(self, right_table, right_column, left_column, join_type="right"):
        if self.first:
            if join_type == "right":
                self.query_joins = self.model.__table__.join(
                    right_table, left_column == right_column
                )
            else:
                self.query_joins = self.model.__table__.outerjoin(
                    right_table, left_column == right_column
                )
            self.first = False
            self._already_joined_table.append(right_table)
        else:
            # check if the table not already joined
            if right_table not in self._already_joined_table:
                self.query_joins = self.query_joins.join(right_table, left_column == right_column)
                # push the joined table in _already_joined_table list
                self._already_joined_table.append(right_table)

    def add_join_multiple_cond(self, right_table, conditions):
        if self.first:
            self.query_joins = self.model.__table__.join(right_table, and_(*conditions))
            self.first = False
        else:
            # check if the table not already joined
            if right_table not in self._already_joined_table:
                self.query_joins = self.query_joins.join(right_table, and_(*conditions))
                # push the joined table in _already_joined_table list
                self._already_joined_table.append(right_table)

    def filter_query_with_cruved(self, user):
        """
        Filter the query with the cruved authorization of a user
        """
        if user.value_filter in ("1", "2"):
            # get id synthese where user is observer
            subquery_observers = (
                select([CorObserverSynthese.id_synthese])
                .select_from(CorObserverSynthese)
                .where(CorObserverSynthese.id_role == user.id_role)
            )
            ors_filters = [
                self.model_id_syn_col.in_(subquery_observers),
                self.model_id_digitiser_column == user.id_role,
            ]
            if current_app.config["SYNTHESE"]["CRUVED_SEARCH_WITH_OBSERVER_AS_TXT"]:
                user_fullname1 = user.nom_role + " " + user.prenom_role + "%"
                user_fullname2 = user.prenom_role + " " + user.nom_role + "%"
                ors_filters.append(self.model_observers_column.ilike(user_fullname1))
                ors_filters.append(self.model_observers_column.ilike(user_fullname2))

            if user.value_filter == "1":
                allowed_datasets = TDatasets.get_user_datasets(user, only_user=True)
                ors_filters.append(self.model_id_dataset_column.in_(allowed_datasets))
                self.query = self.query.where(or_(*ors_filters))
            elif user.value_filter == "2":
                allowed_datasets = TDatasets.get_user_datasets(user)
                ors_filters.append(self.model_id_dataset_column.in_(allowed_datasets))
                self.query = self.query.where(or_(*ors_filters))

    def filter_taxonomy(self):
        """
        Filters the query with taxonomic attributes
        Parameters:
            - q (SQLAchemyQuery): an SQLAchemy query
            - filters (dict): a dict of filter
        Returns:
            -Tuple: the SQLAlchemy query and the filter dictionnary
        """
        cd_ref_childs = []
        if "cd_ref_parent" in self.filters:
            # find all taxon child from cd_ref parent
            cd_ref_parent_int = list(map(lambda x: int(x), self.filters.pop("cd_ref_parent")))
            sql = text(
                """SELECT DISTINCT cd_ref FROM taxonomie.find_all_taxons_children(:id_parent)"""
            )
            result = DB.engine.execute(sql, id_parent=cd_ref_parent_int)
            if result:
                cd_ref_childs = [r[0] for r in result]

        cd_ref_selected = []
        if "cd_ref" in self.filters:
            cd_ref_selected = self.filters.pop("cd_ref")

        # concat cd_ref child and just selected cd_ref
        cd_ref_childs.extend(cd_ref_selected)

        if len(cd_ref_childs) > 0:
            sub_query_synonym = select([Taxref.cd_nom]).where(Taxref.cd_ref.in_(cd_ref_childs))
            self.query = self.query.where(self.model.cd_nom.in_(sub_query_synonym))
        if "taxonomy_group2_inpn" in self.filters:
            self.add_join(Taxref, Taxref.cd_nom, self.model.cd_nom)
            self.query = self.query.where(
                Taxref.group2_inpn.in_(self.filters.pop("taxonomy_group2_inpn"))
            )

        if "taxonomy_id_hab" in self.filters:
            self.add_join(Taxref, Taxref.cd_nom, self.model.cd_nom)
            self.query = self.query.where(
                Taxref.id_habitat.in_(self.filters.pop("taxonomy_id_hab"))
            )

        if "taxonomy_lr" in self.filters:
            sub_query_lr = select([TaxrefLR.cd_nom]).where(
                TaxrefLR.id_categorie_france.in_(self.filters.pop("taxonomy_lr"))
            )
            # TODO est-ce qu'il faut pas filtrer sur le cd_ ref ?
            # quid des protection définit à rang superieur de la saisie ?
            self.query = self.query.where(self.model.cd_nom.in_(sub_query_lr))

        aliased_cor_taxon_attr = {}
        for colname, value in self.filters.items():
            if colname.startswith("taxhub_attribut"):
                self.add_join(Taxref, Taxref.cd_nom, self.model.cd_nom)
                taxhub_id_attr = colname[16:]
                aliased_cor_taxon_attr[taxhub_id_attr] = aliased(CorTaxonAttribut)
                self.add_join_multiple_cond(
                    aliased_cor_taxon_attr[taxhub_id_attr],
                    [
                        aliased_cor_taxon_attr[taxhub_id_attr].id_attribut == taxhub_id_attr,
                        aliased_cor_taxon_attr[taxhub_id_attr].cd_ref
                        == func.taxonomie.find_cdref(self.model.cd_nom),
                    ],
                )
                self.query = self.query.where(
                    aliased_cor_taxon_attr[taxhub_id_attr].valeur_attribut.in_(value)
                )

        # remove attributes taxhub from filters
        self.filters = {
            colname: value
            for colname, value in self.filters.items()
            if not colname.startswith("taxhub_attribut")
        }

    def filter_other_filters(self):
        """
            Other filters
        """

        if "has_medias" in self.filters:
            self.query = self.query.where(
                self.model.has_medias
            )

        if "id_dataset" in self.filters:
            self.query = self.query.where(
                self.model.id_dataset.in_(self.filters.pop("id_dataset"))
            )
        if "observers" in self.filters:
            # découpe des éléments saisies par les espaces
            observers = (self.filters.pop("observers")[0]).split()
            self.query = self.query.where(
                and_(*[self.model.observers.ilike("%" + observer + "%") for observer in observers])
            )

        if "observers_list" in self.filters:
            self.query = self.query.where(
                and_(
                    *[
                        self.model.observers.ilike("%" + observer.get("nom_complet") + "%")
                        for observer in self.filters.pop("observers_list")
                    ]
                )
            )

        if "id_organism" in self.filters:
            datasets = (
                DB.session.query(CorDatasetActor.id_dataset)
                .filter(CorDatasetActor.id_organism.in_(self.filters.pop("id_organism")))
                .all()
            )
            formated_datasets = [d[0] for d in datasets]
            self.query = self.query.where(self.model.id_dataset.in_(formated_datasets))
        if "date_min" in self.filters:
            self.query = self.query.where(self.model.date_min >= self.filters.pop("date_min")[0])

        if "date_max" in self.filters:
            # set the date_max at 23h59 because a hour can be set in timestamp
            date_max = datetime.datetime.strptime(self.filters.pop("date_max")[0], "%Y-%m-%d")
            date_max = date_max.replace(hour=23, minute=59, second=59)
            self.query = self.query.where(self.model.date_max <= date_max)

        if "id_acquisition_framework" in self.filters:
            self.query = self.query.where(
                self.model.id_acquisition_framework.in_(
                    self.filters.pop("id_acquisition_framework")
                )
            )

        if "geoIntersection" in self.filters:
            # Insersect with the geom send from the map
            ors = []

            for str_wkt in self.filters["geoIntersection"]:
                # if the geom is a circle
                if "radius" in self.filters:
                    radius = self.filters.pop("radius")[0]
                    wkt = loads(str_wkt)
                    wkt = circle_from_point(wkt, float(radius))
                else:
                    wkt = loads(str_wkt)
                geom_wkb = from_shape(wkt, srid=4326)
                ors.append(self.model.the_geom_4326.ST_Intersects(geom_wkb))

            self.query = self.query.where(or_(*ors))
            self.filters.pop("geoIntersection")

        if "period_start" in self.filters and "period_end" in self.filters:
            period_start = self.filters.pop("period_start")[0]
            period_end = self.filters.pop("period_end")[0]
            self.query = self.query.where(
                or_(
                    func.gn_commons.is_in_period(
                        func.date(self.model.date_min),
                        func.to_date(period_start, "DD-MM"),
                        func.to_date(period_end, "DD-MM"),
                    ),
                    func.gn_commons.is_in_period(
                        func.date(self.model.date_max),
                        func.to_date(period_start, "DD-MM"),
                        func.to_date(period_end, "DD-MM"),
                    ),
                )
            )
        #  use for validation module since the class is factorized
        if "modif_since_validation" in self.filters:
            self.query = self.query.where(self.model.meta_update_date > self.model.validation_date)
            self.filters.pop("modif_since_validation")

        # generic filters
        for colname, value in self.filters.items():
            if colname.startswith("area"):
                self.add_join(CorAreaSynthese, CorAreaSynthese.id_synthese, self.model.id_synthese)
                self.query = self.query.where(CorAreaSynthese.id_area.in_(value))
            elif colname.startswith("id_"):
                col = getattr(self.model.__table__.columns, colname)
                self.query = self.query.where(col.in_(value))
            elif hasattr(self.model.__table__.columns, colname):
                col = getattr(self.model.__table__.columns, colname)
                self.query = self.query.where(col.ilike("%{}%".format(value[0])))

    def filter_query_all_filters(self, user):
        """High level function to manage query with all filters.

        Apply CRUVED, toxonomy and other filters.

        Parameters
        ----------
        user: str
            User filtered by CRUVED.

        Returns
        -------
        sqlalchemy.orm.query.Query.filter
            Combined filter to apply.

        """

        self.filter_query_with_cruved(user)

        self.filter_taxonomy()
        self.filter_other_filters()

        if self.query_joins is not None:
            self.query = self.query.select_from(self.query_joins)
        return self.query
