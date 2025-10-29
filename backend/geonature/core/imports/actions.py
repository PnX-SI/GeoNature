from geonature.core.imports.models import Entity, TImports

from bokeh.embed.standalone import StandaloneEmbedJson
from geonature.utils.env import db
import sqlalchemy as sa
from sqlalchemy.inspection import inspect
from werkzeug.exceptions import Conflict

from sqlalchemy import func, select
from sqlalchemy.dialects.postgresql import JSONB


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
        """
        Return a list of key-value pairs describing the statistics of the import process.

        Returns
        -------
        list[ImportStatisticsLabels]
            A list of key-value pairs. Each key-value pair is a dictionary with two keys:
            'key' and 'value'. The 'key' key contains the label of the metric, the 'value'
            key contains the value of the metric.

        Raises
        ------
        NotImplementedError
            If the method is not implemented in the child class.
        """
        raise NotImplementedError

    @staticmethod
    def process_fields(destination, fields):
        """
        Process the given fields for the specified destination.

        Used for monitoring to replace monitoring configuration variables (e.g. __MODULE.ID_LIST_TAXONOMY) in field parameters.

        Parameters
        ----------
        destination : Any
            The destination object where fields are to be processed.
        fields : List[BibFields]
            A list of fields to be processed, originating from `bib_fields`.

        """

        pass  # because optional

    # NOTE The output of this method is NEVER used
    @staticmethod
    def preprocess_transient_data(imprt: TImports, df) -> None:
        """
        Preprocess the transient data for the given import.

        Parameters
        ----------
        imprt : TImports
            The import object containing metadata about the import process.
        df : pandas.DataFrame
            The DataFrame containing the transient data.

        Notes
        -----
        This method is responsible for performing any necessary data
        transformation on the transient data before it is controlled by `check_transient_data`
        imported into the destination database.

        The method is optional and can be omitted if no preprocessing is needed.
        """
        pass

    @staticmethod
    def check_transient_data(task, logger, imprt: TImports) -> None:
        """
        Validate and process the transient data for the given import.

        Parameters
        ----------
        task : Any
            The task object associated with the import process. Used by celery.
        logger : Any
            Logger instance for logging information during validation. Used by celery.
        imprt : TImports
            The import object containing metadata about the import process.

        Raises
        ------
        NotImplementedError
            If the method is not implemented.
        """

        raise NotImplementedError

    @staticmethod
    def import_data_to_destination(imprt: TImports) -> None:
        """
        Import data to the destination database for a given import.

        Parameters
        ----------
        imprt : TImports
            The import object containing information about the data to be imported.

        Notes
        -----
        The data to be imported is initially available in a transient table. This method
        processes and transfers the data from the transient table to the destination
        database.
        """

        raise NotImplementedError

    @staticmethod
    def remove_data_from_destination(imprt: TImports) -> None:
        """
        Remove data from destination database for a given import.

        Parameters
        ----------
        imprt : TImports
            The import to remove data from.

        Notes
        -----
        This method is called when an import is deleted.
        It removes from the destination database all data that was created
        by the import.

        If a child entity (e.g. Habitat) was created later on an imported
        parent entity (e.g. Station), deleting the imported entity will
        be refused !
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
        """
        Generate the report plot for the given import. The plot must be realized using the Bokeh library.
        Plot must be return as JSON using the Bokeh `json_item` function.

        Parameters
        ----------
        imprt : TImports
            The import object containing information about the import process.

        Returns
        -------
        plot : StandaloneEmbedJson
            The standalone embed json data for the report plot.

        Notes
        -----
        The report plot is a visualization of the imported data. It is used
        to provide a quick overview of the import data to the user.
        """
        raise NotImplementedError

    @staticmethod
    def compute_bounding_box(imprt: TImports) -> None:
        """
        Calculate the bounding box for the imported data.

        Parameters
        ----------
        imprt : TImports
            The import object containing information about the import process.

        Notes
        -----
        This method calculates the smallest polygon (bounding box) that contains all the
        geographic data imported. The bounding box is to be displayed in the import report
        once all data has been validated.
        """

        raise NotImplementedError

    @staticmethod
    def bind_matched_observers(
        imprt: TImports,
        model,
        model_user_column: str,
        model_id_column: str,
        correspondence_model,
        correspondence_model_columns: typing.List[str],
    ) -> None:

        observers_jsonb = (
            func.jsonb_each(TImports.observermapping.cast(JSONB))
            .table_valued("key", "value")
            .alias("observer_jsonb")
        )

        observer_string_id_role = (
            select(
                sa.literal_column("observer_jsonb.key").label("observer_string"),
                sa.cast(sa.literal_column("(observer_jsonb.value->>'id_role')"), sa.Integer).label(
                    "id_role"
                ),
            )
            .select_from(
                TImports,
                observers_jsonb,
            )
            .where(TImports.id_import == imprt.id_import)
            .cte("observer_string_id_role")
        )

        model_observers = (
            select(
                getattr(model, model_id_column),
                func.unnest(func.string_to_array(getattr(model, model_user_column), ",")).label(
                    "observer"
                ),
            )
            .where(model.id_import == imprt.id_import)
            .cte("model_observers")
        )

        stmt = (
            select(
                model_observers.c[model_id_column],
                observer_string_id_role.c.id_role,
            )
            .select_from(model_observers)
            .distinct()
            .join(
                observer_string_id_role,
                observer_string_id_role.c.observer_string == model_observers.c.observer,
            )
            .where(observer_string_id_role.c.id_role != None)
        )

        insert_stmt = sa.insert(correspondence_model).from_select(
            names=correspondence_model_columns,
            select=stmt,
        )
        db.session.execute(insert_stmt)
