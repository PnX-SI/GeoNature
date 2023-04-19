"""
Utility function to manage permissions and all filter of Synthese
Use these functions rather than query.py
Filter the query of synthese using SQLA expression language and 'select' object
https://docs.sqlalchemy.org/en/latest/core/tutorial.html#selecting
much more efficient
"""
import datetime
import uuid

from flask import current_app

import sqlalchemy as sa
from sqlalchemy import func, or_, and_, select, distinct
from sqlalchemy.sql import text
from sqlalchemy.orm import aliased
from shapely.wkt import loads
from werkzeug.exceptions import BadRequest
from geoalchemy2.shape import from_shape

from geonature.utils.env import DB
from geonature.core.gn_synthese.models import (
    CorObserverSynthese,
    CorAreaSynthese,
    BibReportsTypes,
    TReport,
)
from geonature.core.gn_meta.models import (
    CorDatasetActor,
    TDatasets,
)
from geonature.utils.errors import GeonatureApiError
from apptax.taxonomie.models import (
    Taxref,
    CorTaxonAttribut,
    TaxrefBdcStatutTaxon,
    bdc_statut_cor_text_area,
    TaxrefBdcStatutCorTextValues,
    TaxrefBdcStatutText,
    TaxrefBdcStatutValues,
)
from ref_geo.models import LAreas, BibAreasTypes


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

    def __init__(
        self,
        model,
        query,
        filters,
        id_synthese_column="id_synthese",
        id_dataset_column="id_dataset",
        observers_column="observers",
        id_digitiser_column="id_digitiser",
        with_generic_table=False,
        query_joins=None,
    ):
        self.query = query

        self.filters = filters
        self.first = query_joins is None
        self.model = model
        self._already_joined_table = []
        self.query_joins = query_joins

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

    def filter_query_with_permissions(self, user, permissions):
        """
        Filter the query with the permissions of a user
        """
        subquery_observers = (
            select([CorObserverSynthese.id_synthese])
            .select_from(CorObserverSynthese)
            .where(CorObserverSynthese.id_role == user.id_role)
        )
        datasets_by_scope = {}  # to avoid fetching datasets several time for same scope
        permissions_filters = []
        for perm in permissions:
            if perm.has_other_filters_than("SCOPE"):
                continue
            perm_filters = []
            if perm.scope_value:
                if perm.scope_value not in datasets_by_scope:
                    datasets_by_scope[perm.scope_value] = [
                        d.id_dataset
                        for d in TDatasets.query.filter_by_scope(perm.scope_value).all()
                    ]
                datasets = datasets_by_scope[perm.scope_value]
                scope_filters = [
                    self.model_id_syn_col.in_(subquery_observers),  # user is observer
                    self.model_id_digitiser_column == user.id_role,  # user id digitizer
                    self.model_id_dataset_column.in_(
                        datasets
                    ),  # user is dataset (or parent af) actor
                ]
                perm_filters.append(or_(*scope_filters))
            if perm_filters:
                permissions_filters.append(and_(*perm_filters))
            else:
                permissions_filters.append(sa.true())
        if permissions_filters:
            self.query = self.query.where(or_(*permissions_filters))
        else:
            self.query = self.query.where(sa.false())

    def filter_query_with_cruved(self, user, scope):
        """
        Filter the query with the cruved authorization of a user
        """
        if scope in (1, 2):
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

            allowed_datasets = [d.id_dataset for d in TDatasets.query.filter_by_scope(scope).all()]
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
            self.add_join(Taxref, Taxref.cd_nom, self.model.cd_nom)
            self.query = self.query.where(Taxref.cd_ref.in_(cd_ref_childs))
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

        aliased_cor_taxon_attr = {}
        protection_status_value = []
        red_list_filters = {}

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
            elif colname.endswith("_red_lists"):
                red_list_id = colname.replace("_red_lists", "")
                all_red_lists_cfg = current_app.config["SYNTHESE"]["RED_LISTS_FILTERS"]
                red_list_cfg = next(
                    (item for item in all_red_lists_cfg if item["id"] == red_list_id), None
                )
                red_list_filters[red_list_cfg["status_type"]] = value

            elif colname.endswith("_protection_status"):
                status_id = colname.replace("_protection_status", "")
                all_status_cfg = current_app.config["SYNTHESE"]["STATUS_FILTERS"]
                status_cfg = next(
                    (item for item in all_status_cfg if item["id"] == status_id), None
                )
                # Check if a checkbox was used.
                if (
                    isinstance(value, bool)
                    and value == True
                    and len(status_cfg["status_types"]) == 1
                ):
                    value = status_cfg["status_types"]

                protection_status_value += value

        if protection_status_value or red_list_filters:
            self.build_bdc_status_pr_nb_lateral_join(protection_status_value, red_list_filters)
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
            media_filter = self.model.medias.any()
            if self.filters["has_medias"] is False:
                media_filter = ~media_filter
            self.query = self.query.where(media_filter)

        if "has_alert" in self.filters:
            alert_filter = self.model.reports.any(
                TReport.report_type.has(BibReportsTypes.type == "alert")
            )
            if self.filters["has_alert"] is False:
                alert_filter = ~alert_filter
            self.query = self.query.where(alert_filter)

        if "has_pin" in self.filters:
            pin_filter = self.model.reports.any(
                TReport.report_type.has(BibReportsTypes.type == "pin")
            )
            if self.filters["has_pin"] is False:
                pin_filter = ~pin_filter
            self.query = self.query.where(pin_filter)
        if "has_comment" in self.filters:
            comment_filter = self.model.reports.any(
                TReport.report_type.has(BibReportsTypes.type == "discussion")
            )
            if self.filters["has_comment"] is False:
                comment_filter = ~comment_filter
            self.query = self.query.where(comment_filter)
        if "id_dataset" in self.filters:
            self.query = self.query.where(
                self.model.id_dataset.in_(self.filters.pop("id_dataset"))
            )
        if "observers" in self.filters:
            # découpe des éléments saisies par les espaces
            observers = self.filters.pop("observers").split()
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
            self.query = self.query.where(self.model.date_min >= self.filters.pop("date_min"))

        if "date_max" in self.filters:
            # set the date_max at 23h59 because a hour can be set in timestamp
            date_max = datetime.datetime.strptime(self.filters.pop("date_max"), "%Y-%m-%d")
            date_max = date_max.replace(hour=23, minute=59, second=59)
            self.query = self.query.where(self.model.date_max <= date_max)

        if "id_acquisition_framework" in self.filters:
            if hasattr(self.model, "id_acquisition_framework"):
                self.query = self.query.where(
                    self.model.id_acquisition_framework.in_(
                        self.filters.pop("id_acquisition_framework")
                    )
                )
            else:
                self.add_join(TDatasets, self.model.id_dataset, TDatasets.id_dataset)
                self.query = self.query.where(
                    TDatasets.id_acquisition_framework.in_(
                        self.filters.pop("id_acquisition_framework")
                    )
                )

        if "geoIntersection" in self.filters:
            # Insersect with the geom send from the map
            str_wkt = self.filters["geoIntersection"]
            # if the geom is a circle
            if "radius" in self.filters:
                radius = self.filters.pop("radius")
                wkt = loads(str_wkt)
                geom_wkb = from_shape(wkt, srid=4326)
                geo_filter = func.ST_DWithin(
                    func.ST_GeogFromWKB(self.model.the_geom_4326),
                    func.ST_GeogFromWKB(geom_wkb),
                    radius,
                )
            else:
                wkt = loads(str_wkt)
                geom_wkb = from_shape(wkt, srid=4326)
                geo_filter = self.model.the_geom_4326.ST_Intersects(geom_wkb)

            self.query = self.query.where(geo_filter)
            self.filters.pop("geoIntersection")

        if "period_start" in self.filters and "period_end" in self.filters:
            period_start = self.filters.pop("period_start")
            period_end = self.filters.pop("period_end")
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
        if "unique_id_sinp" in self.filters:
            try:
                uuid_filter = uuid.UUID(self.filters.pop("unique_id_sinp"))
            except ValueError as e:
                raise BadRequest(str(e))
            self.query = self.query.where(self.model.unique_id_sinp == uuid_filter)
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
                if str(col.type) == "INTEGER":
                    if colname in ["precision"]:
                        self.query = self.query.where(col <= value)
                    else:
                        self.query = self.query.where(col == value)
                else:
                    self.query = self.query.where(col.ilike("%{}%".format(value)))

    def apply_all_filters(self, user, permissions):
        if type(permissions) == int:  # scope
            self.filter_query_with_cruved(user, scope=permissions)
        else:
            self.filter_query_with_permissions(user, permissions)
        self.filter_taxonomy()
        self.filter_other_filters()

    def build_query(self):
        if self.query_joins is not None:
            self.query = self.query.select_from(self.query_joins)
        return self.query

    def filter_query_all_filters(self, user, permissions):
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
        self.apply_all_filters(user, permissions)
        return self.build_query()

    def build_bdc_status_pr_nb_lateral_join(self, protection_status_value, red_list_filters):
        """
        Create subquery for bdc_status filters

        Objectif : filtrer les données ayant :
          - les statuts du type demandé par l'utilisateur
          - les status s'appliquent bien sur la zone géographique de la donnée (c-a-d le département)

        Idée de façon à limiter le nombre de sous reqêtes,
            la liste des status selectionnés par l'utilisateur s'appliquant à l'observation est
            aggrégée de façon à tester le nombre puis jointé sur le département de la donnée
        """
        # Ajout de la table taxref si non ajouté
        self.add_join(Taxref, Taxref.cd_nom, self.model.cd_nom)

        # Ajout jointure permettant d'avoir le département pour chaque donnée
        cas_dep = aliased(CorAreaSynthese)
        lareas_dep = aliased(LAreas)
        bib_area_dep = aliased(BibAreasTypes)
        self.add_join(cas_dep, cas_dep.id_synthese, self.model.id_synthese)
        self.add_join(lareas_dep, lareas_dep.id_area, cas_dep.id_area)
        self.add_join_multiple_cond(
            bib_area_dep,
            [bib_area_dep.id_type == lareas_dep.id_type, bib_area_dep.type_code == "DEP"],
        )

        # Creation requête CTE : taxon, zone d'application départementale des textes
        #   pour les taxons répondant aux critères de selection
        bdc_status_cte = (
            select(
                [
                    TaxrefBdcStatutTaxon.cd_ref,
                    func.array_agg(bdc_statut_cor_text_area.c.id_area).label("ids_area"),
                ]
            )
            .select_from(
                TaxrefBdcStatutTaxon.__table__.join(
                    TaxrefBdcStatutCorTextValues,
                    TaxrefBdcStatutCorTextValues.id_value_text
                    == TaxrefBdcStatutTaxon.id_value_text,
                )
                .join(
                    TaxrefBdcStatutText,
                    TaxrefBdcStatutText.id_text == TaxrefBdcStatutCorTextValues.id_text,
                )
                .join(
                    TaxrefBdcStatutValues,
                    TaxrefBdcStatutValues.id_value == TaxrefBdcStatutCorTextValues.id_value,
                )
                .join(
                    bdc_statut_cor_text_area,
                    bdc_statut_cor_text_area.c.id_text == TaxrefBdcStatutText.id_text,
                )
            )
            .where(TaxrefBdcStatutText.enable == True)
        )

        # ajout des filtres de selection des textes
        bdc_status_filters = []
        if red_list_filters:
            bdc_status_filters = [
                and_(
                    TaxrefBdcStatutValues.code_statut.in_(v),
                    TaxrefBdcStatutText.cd_type_statut == k,
                )
                for k, v in red_list_filters.items()
            ]
        if protection_status_value:
            bdc_status_filters.append(
                TaxrefBdcStatutText.cd_type_statut.in_(protection_status_value)
            )

        bdc_status_cte = bdc_status_cte.where(or_(*bdc_status_filters))

        # group by de façon à ne selectionner que les taxons
        #   qui ont les textes selectionnés par l'utilisateurs
        bdc_status_cte = bdc_status_cte.group_by(TaxrefBdcStatutTaxon.cd_ref).having(
            func.count(distinct(TaxrefBdcStatutText.cd_type_statut))
            == (len(protection_status_value) + len(red_list_filters))
        )

        bdc_status_cte = bdc_status_cte.cte(name="status")

        # Jointure sur le taxon
        # et vérification que l'ensemble des textes
        # soit sur bien sur le département de l'observation
        self.add_join_multiple_cond(
            bdc_status_cte,
            [
                bdc_status_cte.c.cd_ref == Taxref.cd_ref,
                func.array_length(
                    func.array_positions(bdc_status_cte.c.ids_area, cas_dep.id_area), 1
                )
                == (len(protection_status_value) + len(red_list_filters)),
            ],
        )
