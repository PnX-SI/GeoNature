from geonature.core.imports.models import Entity, TImports

from bokeh.embed.standalone import StandaloneEmbedJson
from geonature.utils.env import db
import sqlalchemy as sa
from sqlalchemy.inspection import inspect
from werkzeug.exceptions import Conflict

import typing


class ImportStatisticsLabels(typing.TypedDict):
    key: str
    value: str


class ImportInputUrl(typing.TypedDict):
    url: str
    label: str


class ImportActions:
    @staticmethod
    def statistics_labels() -> typing.List[ImportStatisticsLabels]:
        raise NotImplementedError

    @staticmethod
    def process_fields(destination, fields):
        pass # because optional

    # The output of this method is NEVER used
    @staticmethod
    def preprocess_transient_data(imprt: TImports, df) -> set:
        raise NotImplementedError

    @staticmethod
    def check_transient_data(task, logger, imprt: TImports) -> None:
        raise NotImplementedError

    @staticmethod
    def import_data_to_destination(imprt: TImports) -> None:
        raise NotImplementedError

    @staticmethod
    def remove_data_from_destination(imprt: TImports) -> None:
        """
        This function should be integrated in import core as usable for any
        multi-entities (and mono-entity) destination.
        Note: entities must have a single primary key.
        """
        entities = db.session.scalars(
            sa.select(Entity)
            .where(Entity.destination == imprt.destination)
            .order_by(sa.desc(Entity.order))
        ).all()
        for entity in entities:
            parent_table = entity.get_destination_table()
            if entity.childs:
                for child in entity.childs:
                    child_table = child.get_destination_table()
                    (parent_pk,) = inspect(parent_table).primary_key.columns
                    (child_pk,) = inspect(child_table).primary_key.columns
                    # Looking for parent rows belonging to this import with child rows
                    # not belonging to this import.
                    # We use is_distinct_from to match rows with NULL id_import.
                    query = (
                        sa.select(parent_pk, sa.func.array_agg(child_pk))
                        .select_from(parent_table.join(child_table))
                        .where(
                            parent_table.c.id_import == imprt.id_import,
                            child_table.c.id_import.is_distinct_from(imprt.id_import),
                        )
                        .group_by(parent_pk)
                    )
                    orphans = db.session.execute(query).fetchall()
                    if orphans:
                        description = "L’import ne peut pas être supprimé car cela provoquerai la suppression de données ne provenant pas de cet import :"
                        description += "<ul>"
                        for id_parent, ids_child in orphans:
                            description += f"<li>{entity.label} {id_parent} : {child.label}s {*ids_child, }</li>"
                        description += "</ul>"
                        raise Conflict(description)
            db.session.execute(
                sa.delete(parent_table).where(parent_table.c.id_import == imprt.id_import)
            )

    @staticmethod
    def report_plot(imprt: TImports) -> StandaloneEmbedJson:
        raise NotImplementedError

    @staticmethod
    def compute_bounding_box(imprt: TImports) -> None:
        raise NotImplementedError
