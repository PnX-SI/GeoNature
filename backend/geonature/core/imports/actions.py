import math
import typing

from flask import current_app
from sqlalchemy.inspection import inspect
from werkzeug.exceptions import Conflict

from sqlalchemy import (
    Integer,
    cast,
    delete,
    desc,
    func,
    insert,
    join,
    literal_column,
    select,
    case,
    true,
    update,
)
from sqlalchemy.dialects.postgresql import JSONB
from geonature.utils.config import config

from geonature.utils.env import db
from geonature.core.imports.models import Entity, TImports
from geonature.core.imports.checks.dataframe import check_types
from geonature.core.imports.checks.sql import check_orphan_rows, init_rows_validity
from geonature.core.imports.utils import (
    get_mapping_data,
    load_transient_data_in_dataframe,
    update_transient_data_from_dataframe,
)
from pypnusershub.db.models import User


def get_update_task_progress_callback(task, to_global_progress: typing.Callable[[float], float]):
    """
    Return the ``update_progress(v)`` callable given to a hook.

    ``v`` is clamped to [0, 1], converted to the real progress of the import
    (``to_global_progress``) and sent to celery if a task is given.
    """

    def update_task_progress(v: float) -> None:
        v = min(max(float(v), 0.0), 1.0)
        if task is not None:
            task.update_state(state="PROGRESS", meta={"progress": to_global_progress(v)})

    return update_task_progress


def import_hook(progress: float):
    """
    Decorator for the import check hooks (see ``ImportActions.check_transient_data``).

    Attaches the weight ``progress`` of the hook to the decorated function. The weights
    of the three hooks (``pre``, ``df_batch``, ``post``) must sum to 1.

    Usage: place it under ``@staticmethod`` so that the weight is reachable through the class::

        @staticmethod
        @import_hook(progress=0.1)
        def check_transient_data_pre(task, logger, imprt, update_progress): ...
    """

    def decorator(func):
        func.progress = progress
        return func

    return decorator


class ImportStatisticsLabels(typing.TypedDict):
    """Label of an import statistic, as displayed in the import report."""

    key: str
    value: str


class ImportInputUrl(typing.TypedDict):
    """Link to the page displaying the data imported in a destination."""

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
    def get_source_cols(imprt: TImports, entity: Entity) -> typing.List[str]:
        """
        Source columns of the transient table loaded in the dataframe of ``entity``.

        By default: the columns given by ``get_mapping_data``. A destination needing other
        columns (for example all the fields, because CEL conditions may use any field)
        overrides it.
        """
        _, _, source_cols = get_mapping_data(imprt, entity)
        return source_cols

    @staticmethod
    @import_hook(progress=0.1)
    def check_transient_data_pre(task, logger, imprt: TImports, update_progress) -> None:
        """
        Global checks (typically SQL), run once before the dataframe batches.

        By default: initialise the rows validity and mark the orphan rows. A destination
        overriding it should call ``ImportActions.check_transient_data_pre`` first, then its
        own global checks (consistency, nomenclature mapping...).

        Parameters
        ----------
        task : Any
            The celery task (may be None).
        logger : Any
            Logger instance.
        imprt : TImports
            The import being checked.
        update_progress : Callable[[float], None]
            Reports the progress of this hook, ``v`` in [0, 1].
        """
        init_rows_validity(imprt)
        check_orphan_rows(imprt)

    @staticmethod
    @import_hook(progress=0.8)
    def check_transient_data_df_batch(
        task, logger, imprt: TImports, entity: Entity, df, update_progress
    ) -> typing.Optional[set]:
        """
        Dataframe checks, called once per entity and per batch of lines.

        By default: check the types of the columns (``check_types``). A destination overriding
        it should call ``ImportActions.check_transient_data_df_batch`` (or ``check_types``)
        and add its own checks.

        Parameters
        ----------
        task : Any
            The celery task (may be None).
        logger : Any
            Logger instance.
        imprt : TImports
            The import being checked.
        entity : Entity
            The entity checked.
        df : pandas.DataFrame
            The transient data of this entity for this batch (valid rows only, ordered by
            ``line_no``). It may be empty.
        update_progress : Callable[[float], None]
            Reports the progress of the current batch, ``v`` in [0, 1].

        Returns
        -------
        set or None
            Names of the columns modified in ``df``: they are written back to the transient
            table. None if nothing was modified.
        """
        fields, _, _ = get_mapping_data(imprt, entity)
        return check_types(imprt, entity, df, fields)

    @staticmethod
    @import_hook(progress=0.1)
    def check_transient_data_post(task, logger, imprt: TImports, update_progress) -> None:
        """
        Global checks (typically SQL), run once after all the dataframe batches.

        Does nothing by default. Override it in destinations which need it.

        Parameters
        ----------
        task : Any
            The celery task (may be None).
        logger : Any
            Logger instance.
        imprt : TImports
            The import being checked.
        update_progress : Callable[[float], None]
            Reports the progress of this hook, ``v`` in [0, 1].
        """
        pass

    @classmethod
    def check_transient_data(cls, task, logger, imprt: TImports) -> None:
        """
        Validate and process the transient data for the given import.

        By default, the check is composed of three hooks, run in this order:

        1. ``check_transient_data_pre``, once;
        2. ``check_transient_data_df_batch``, once per entity present in the import
           (ordered by ``Entity.order``) and per batch of lines;
        3. ``check_transient_data_post``, once.

        A batch covers a range of ``line_no`` identical for all entities. Batches are made
        of ``IMPORT.DATAFRAME_BATCH_SIZE`` consecutive lines of the import (all lines, valid
        or not for a given entity), so that a batch can be empty for an entity.

        Subclasses overriding this method keep their own behaviour.

        Parameters
        ----------
        task : Any
            The task object associated with the import process. Used by celery.
        logger : Any
            Logger instance for logging information during validation. Used by celery.
        imprt : TImports
            The import object containing metadata about the import process.
        """
        pre = cls.check_transient_data_pre
        batch = cls.check_transient_data_df_batch
        post = cls.check_transient_data_post
        w_pre, w_batch, w_post = pre.progress, batch.progress, post.progress
        assert math.isclose(w_pre + w_batch + w_post, 1), "Hook progress weights must sum to 1"

        ### PRE hook
        update_pre = get_update_task_progress_callback(task, lambda v: w_pre * v)
        pre(task, logger, imprt, update_pre)
        update_pre(1)  # the hook may not report its end, the composer does

        ### DF BATCH hook
        entities = [
            entity
            for entity in sorted(
                imprt.destination.entities, key=lambda e: (e.order is None, e.order or 0)
            )
            if entity.validity_column is not None
        ]
        # Batches are offset/limit slices of the rows valid for each entity, computed after
        # the pre hook (which may invalidate rows). T = sum of the batch counts of all entities.
        batch_size = current_app.config["IMPORT"]["DATAFRAME_BATCH_SIZE"]
        batch_counts = [
            math.ceil(cls.count_valid_rows(imprt, entity) / batch_size) for entity in entities
        ]
        total_batches = sum(batch_counts)

        first_batch_index = 0  # k - 1 for the first batch of the current entity
        for entity_index, (entity, n_batches) in enumerate(zip(entities, batch_counts)):
            source_cols = cls.get_source_cols(imprt, entity)
            for batch_index in range(n_batches):
                # k is the global index of the batch, from 1 to T
                k = first_batch_index + batch_index + 1
                update_progress = get_update_task_progress_callback(
                    task,
                    lambda v, k=k: w_pre + w_batch * ((k - 1 + v) / total_batches),
                )
                # Log prefix: entity k/p (entity name), then batch n/m of this entity
                prefix = (
                    f"[entité {entity_index + 1}/{len(entities)} ({entity.code})] "
                    f"[batch {batch_index + 1}/{n_batches}]"
                )
                logger.info(f"{prefix} Loading import data in dataframe…")
                df = load_transient_data_in_dataframe(
                    imprt,
                    entity,
                    source_cols,
                    offset=batch_index * batch_size,
                    limit=batch_size,
                )
                updated_cols = batch(task, logger, imprt, entity, df, update_progress)
                logger.info(f"{prefix} Updating import data from dataframe…")
                update_transient_data_from_dataframe(imprt, entity, updated_cols, df)
                # Empty batches still count for progress
                update_progress(1)
            first_batch_index += n_batches

        ### POST hook
        update_post = get_update_task_progress_callback(
            task, lambda v: w_pre + w_batch + w_post * v
        )
        post(task, logger, imprt, update_post)
        update_post(1)

    @staticmethod
    def count_valid_rows(imprt: TImports, entity: Entity) -> int:
        """
        Number of rows loaded for ``entity`` by ``load_transient_data_in_dataframe``
        (validity not NULL), i.e. the rows its batches cover.
        """
        transient_table = imprt.destination.get_transient_table()
        return db.session.scalar(
            select(func.count())
            .select_from(transient_table)
            .where(
                transient_table.c.id_import == imprt.id_import,
                transient_table.c[entity.validity_column].isnot(None),
            )
        )

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
    def get_dataset_transient_column_name() -> str:
        """
        Retrieves the name of the transient column associated with the dataset.

        Returns
        -------
        str
            Always returns "id_dataset" unless overridden.
        """
        return "id_dataset"

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
            select(Entity)
            .where(Entity.destination == imprt.destination)
            .order_by(desc(Entity.order))
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
                        select(parent_pk, func.array_agg(child_pk))
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
                delete(parent_table).where(parent_table.c.id_import == imprt.id_import)
            )

    @staticmethod
    def report_plot(imprt: TImports):
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
    def is_observer_mapping_enabled() -> bool:
        """
        Check if observer mapping is a allowed for the current destination.

        If not overridden, is_observer_mapping_enabled returns the value
        of ALLOW_USER_MAPPING in the configuration file, which is True by default.

        Returns
        -------
        bool
            True if observer mapping is enabled
        """
        return config["IMPORT"]["ALLOW_USER_MAPPING"]

    @staticmethod
    def bind_matched_observers(
        imprt: TImports,
        model,
        model_user_column: str,
        model_id_column: str,
        correspondence_model,
        correspondence_model_columns: typing.List[str],
    ) -> None:

        def gettattr_(obj, attr):
            if hasattr(obj, "c"):
                return getattr(obj.c, attr)
            return getattr(obj, attr)

        observers_jsonb = (
            func.jsonb_each(TImports.observermapping.cast(JSONB))
            .table_valued("key", "value")
            .alias("observer_jsonb")
        )

        observer_mapping = (
            select(
                literal_column("observer_jsonb.key").label("observer_string"),
                cast(literal_column("(observer_jsonb.value->>'id_role')"), Integer).label(
                    "id_role"
                ),
            )
            .select_from(join(TImports, observers_jsonb, true()))
            .where(TImports.id_import == imprt.id_import)
            .cte("observer_mapping")
        )
        separators = config["IMPORT"]["OBSERVER_FIELD_SEPARATORS"]
        field_separators_as_regexp = rf"[{''.join(separators)}]+"
        model_observers = (
            select(
                gettattr_(model, model_id_column).label(model_id_column),
                func.trim(
                    func.regexp_split_to_table(
                        gettattr_(model, model_user_column), field_separators_as_regexp
                    )
                ).label("observer_string"),
            )
            .where(gettattr_(model, "id_import") == imprt.id_import)
            .cte("model_observers")
        )

        matched_observers = (
            select(
                model_observers.c[model_id_column],
                observer_mapping.c.id_role,
                case(
                    (
                        User.nom_complet != "",
                        User.nom_complet,
                    ),  # Null is associated to "" since it's a string...
                    else_=model_observers.c.observer_string,
                ).label("observer_display_name"),
            )
            .select_from(model_observers)
            .join(
                observer_mapping,
                observer_mapping.c.observer_string == model_observers.c.observer_string,
                isouter=True,
            )
            .join(User, User.id_role == observer_mapping.c.id_role, isouter=True)
            .where(model_observers.c[model_id_column] != None)
            .subquery("matched_observers")
        )

        aggregated_observers = db.session.execute(
            select(
                matched_observers.c[model_id_column],
                func.string_agg(matched_observers.c.observer_display_name, ", "),
            )
            .select_from(matched_observers)
            .group_by(matched_observers.c[model_id_column])
        ).all()

        ## Insert into corresponding table
        insert_stmt = insert(correspondence_model).from_select(
            names=correspondence_model_columns,
            select=select(
                *[getattr(matched_observers.c, col) for col in correspondence_model_columns]
            )
            .select_from(matched_observers)
            .where(matched_observers.c.id_role != None)
            .distinct(),
        )

        db.session.execute(insert_stmt)
        # Correct observers_txt column if non mapped observers still exists

        for model_id, observers_text in aggregated_observers:
            db.session.execute(
                update(model)
                .where(gettattr_(model, model_id_column) == model_id)
                .values({model_user_column: observers_text})
            )
