from math import ceil

from geonature.core.imports.actions import ImportActions, ImportStatisticsLabels, ImportInputUrl

from apptax.taxonomie.models import Taxref
from flask import current_app
import sqlalchemy as sa
from sqlalchemy import func, distinct, select

from geonature.utils.env import db
from geonature.utils.sentry import start_sentry_child
from geonature.core.gn_commons.models import TModules
from geonature.core.gn_synthese.models import Synthese, TSources

from geonature.core.imports.models import Entity, EntityField, BibFields, TImports
from geonature.core.imports.utils import (
    load_transient_data_in_dataframe,
    update_transient_data_from_dataframe,
    compute_bounding_box,
)
from geonature.core.imports.checks.dataframe import (
    concat_dates,
    check_required_values,
    check_types,
    check_geometry,
    check_counts,
    check_datasets,
)
from geonature.core.imports.checks.sql import (
    do_nomenclatures_mapping,
    check_nomenclature_exist_proof,
    check_nomenclature_blurring,
    check_nomenclature_source_status,
    convert_geom_columns,
    set_geom_point,
    check_cd_nom,
    check_cd_hab,
    generate_altitudes,
    check_duplicate_uuid,
    check_existing_uuid,
    generate_missing_uuid,
    check_duplicate_source_pk,
    check_dates,
    check_altitudes,
    check_depths,
    check_digital_proof_urls,
    check_geometry_outside,
    check_is_valid_geometry,
    init_rows_validity,
    check_orphan_rows,
)

from .geo import set_geom_columns_from_area_codes
from bokeh.plotting import figure
from bokeh.layouts import column
from bokeh.models import CustomJS, Select
from bokeh.embed import json_item
from bokeh.embed.standalone import StandaloneEmbedJson
from bokeh.palettes import linear_palette, Turbo256, Plasma256
from bokeh.models import Range1d, AnnularWedge, ColumnDataSource, Legend, LegendItem

import numpy as np
import typing
import json


class SyntheseImportActions(ImportActions):

    @staticmethod
    def statistics_labels() -> typing.List[ImportStatisticsLabels]:
        return [
            {"key": "import_count", "value": "Nombre d'observations importées"},
            {"key": "taxa_count", "value": "Nombre de taxons"},
        ]

    @staticmethod
    def preprocess_transient_data(imprt: TImports, df) -> set:
        pass

    @staticmethod
    def check_transient_data(task, logger, imprt: TImports):
        entity = db.session.execute(
            select(Entity).where(Entity.destination == imprt.destination)
        ).scalar_one()  # Observation

        entity_bib_fields = db.session.scalars(
            sa.select(BibFields)
            .where(BibFields.destination == imprt.destination)
            .options(sa.orm.selectinload(BibFields.entities).joinedload(EntityField.entity))
        ).all()

        fields = {field.name_field: field for field in entity_bib_fields}
        # Note: multi fields are not selected here, and therefore, will be not loaded in dataframe or checked in SQL.
        # Fix this code (see import function) if you want to operate on multi fields data.
        selected_fields = {
            field_name: fields[field_name]
            for field_name, source_field in imprt.fieldmapping.items()
            if source_field in imprt.columns
        }
        init_rows_validity(imprt)
        task.update_state(state="PROGRESS", meta={"progress": 0.05})
        check_orphan_rows(imprt)
        task.update_state(state="PROGRESS", meta={"progress": 0.1})

        batch_size = current_app.config["IMPORT"]["DATAFRAME_BATCH_SIZE"]
        batch_count = ceil(imprt.source_count / batch_size)

        def update_batch_progress(batch, step):
            start = 0.1
            end = 0.4
            step_count = 8
            progress = start + ((batch + 1) / batch_count) * (step / step_count) * (end - start)
            task.update_state(state="PROGRESS", meta={"progress": progress})

        source_cols = [
            field.source_column
            for field in selected_fields.values()
            if field.mandatory or (field.source_field is not None and field.mnemonique is None)
        ]

        for batch in range(batch_count):
            offset = batch * batch_size
            updated_cols = set()

            logger.info(f"[{batch+1}/{batch_count}] Loading import data in dataframe…")
            with start_sentry_child(op="check.df", description="load dataframe"):
                df = load_transient_data_in_dataframe(
                    imprt, entity, source_cols, offset=offset, limit=batch_size
                )
            update_batch_progress(batch, 1)

            logger.info(f"[{batch+1}/{batch_count}] Concat dates…")
            with start_sentry_child(op="check.df", description="concat dates"):
                updated_cols |= concat_dates(
                    df,
                    fields["datetime_min"].dest_field,
                    fields["datetime_max"].dest_field,
                    fields["date_min"].source_field,
                    fields["date_max"].source_field,
                    fields["hour_min"].source_field,
                    fields["hour_max"].source_field,
                )
            update_batch_progress(batch, 2)

            logger.info(f"[{batch+1}/{batch_count}] Check required values…")
            with start_sentry_child(op="check.df", description="check required values"):
                updated_cols |= check_required_values(imprt, entity, df, fields)
            update_batch_progress(batch, 3)

            logger.info(f"[{batch+1}/{batch_count}] Check types…")
            with start_sentry_child(op="check.df", description="check types"):
                updated_cols |= check_types(imprt, entity, df, fields)
            update_batch_progress(batch, 4)

            logger.info(f"[{batch+1}/{batch_count}] Check dataset rows")
            with start_sentry_child(op="check.df", description="check datasets rows"):
                updated_cols |= check_datasets(
                    imprt,
                    entity,
                    df,
                    uuid_field=fields["unique_dataset_id"],
                    id_field=fields["id_dataset"],
                    module_code="SYNTHESE",
                )
            update_batch_progress(batch, 5)
            logger.info(f"[{batch+1}/{batch_count}] Check geography…")
            with start_sentry_child(op="check.df", description="set geography"):
                updated_cols |= check_geometry(
                    imprt,
                    entity,
                    df,
                    file_srid=imprt.srid,
                    geom_4326_field=fields["the_geom_4326"],
                    geom_local_field=fields["the_geom_local"],
                    wkt_field=fields["WKT"],
                    latitude_field=fields["latitude"],
                    longitude_field=fields["longitude"],
                    codecommune_field=fields["codecommune"],
                    codemaille_field=fields["codemaille"],
                    codedepartement_field=fields["codedepartement"],
                )
            update_batch_progress(batch, 6)

            logger.info(f"[{batch+1}/{batch_count}] Check counts…")
            with start_sentry_child(op="check.df", description="check count"):
                updated_cols |= check_counts(
                    imprt,
                    entity,
                    df,
                    fields["count_min"],
                    fields["count_max"],
                    default_count=current_app.config["IMPORT"]["DEFAULT_COUNT_VALUE"],
                )
            update_batch_progress(batch, 7)

            logger.info(f"[{batch+1}/{batch_count}] Updating import data from dataframe…")
            with start_sentry_child(op="check.df", description="save dataframe"):
                update_transient_data_from_dataframe(imprt, entity, updated_cols, df)
            update_batch_progress(batch, 8)

        # Checks in SQL
        convert_geom_columns(
            imprt,
            entity,
            geom_4326_field=fields["the_geom_4326"],
            geom_local_field=fields["the_geom_local"],
        )
        set_geom_columns_from_area_codes(
            imprt,
            entity,
            geom_4326_field=fields["the_geom_4326"],
            geom_local_field=fields["the_geom_local"],
            codecommune_field=fields["codecommune"],
            codemaille_field=fields["codemaille"],
            codedepartement_field=fields["codedepartement"],
        )
        set_geom_point(
            imprt=imprt,
            entity=entity,
            geom_4326_field=fields["the_geom_4326"],
            geom_point_field=fields["the_geom_point"],
        )
        # All valid rows should have a geom as verified in dataframe check 'check_geometry'

        do_nomenclatures_mapping(
            imprt,
            entity,
            selected_fields,
            fill_with_defaults=current_app.config["IMPORT"][
                "FILL_MISSING_NOMENCLATURE_WITH_DEFAULT_VALUE"
            ],
        )

        if current_app.config["IMPORT"]["CHECK_EXIST_PROOF"]:
            check_nomenclature_exist_proof(
                imprt,
                entity,
                fields["id_nomenclature_exist_proof"],
                selected_fields.get("digital_proof"),
                selected_fields.get("non_digital_proof"),
            )
        if (
            current_app.config["IMPORT"]["CHECK_PRIVATE_JDD_BLURING"]
            # and not current_app.config["IMPORT"]["FILL_MISSING_NOMENCLATURE_WITH_DEFAULT_VALUE"]  # XXX
            and imprt.dataset.nomenclature_data_origin.mnemonique == "Privée"
        ):
            check_nomenclature_blurring(imprt, entity, fields["id_nomenclature_blurring"])
        if current_app.config["IMPORT"]["CHECK_REF_BIBLIO_LITTERATURE"]:
            check_nomenclature_source_status(
                imprt, entity, fields["id_nomenclature_source_status"], fields["reference_biblio"]
            )

        if "cd_nom" in selected_fields:
            check_cd_nom(
                imprt,
                entity,
                selected_fields["cd_nom"],
                list_id=current_app.config["IMPORT"].get("ID_LIST_TAXA_RESTRICTION", None),
            )
        if "cd_hab" in selected_fields:
            check_cd_hab(imprt, entity, selected_fields["cd_hab"])
        if "entity_source_pk_value" in selected_fields:
            check_duplicate_source_pk(imprt, entity, selected_fields["entity_source_pk_value"])

        if imprt.fieldmapping.get("altitudes_generate", False):
            generate_altitudes(
                imprt, fields["the_geom_local"], fields["altitude_min"], fields["altitude_max"]
            )
        check_altitudes(
            imprt, entity, selected_fields.get("altitude_min"), selected_fields.get("altitude_max")
        )

        if "unique_id_sinp" in selected_fields:
            check_duplicate_uuid(imprt, entity, selected_fields["unique_id_sinp"])
            if current_app.config["IMPORT"]["PER_DATASET_UUID_CHECK"]:
                whereclause = Synthese.id_dataset == imprt.id_dataset
            else:
                whereclause = sa.true()
            check_existing_uuid(
                imprt,
                entity,
                selected_fields["unique_id_sinp"],
                whereclause=whereclause,
            )
        if imprt.fieldmapping.get(
            "unique_id_sinp_generate",
            current_app.config["IMPORT"]["DEFAULT_GENERATE_MISSING_UUID"],
        ):
            generate_missing_uuid(imprt, entity, fields["unique_id_sinp"])
        check_dates(imprt, entity, fields["datetime_min"], fields["datetime_max"])
        check_depths(
            imprt, entity, selected_fields.get("depth_min"), selected_fields.get("depth_max")
        )
        if "digital_proof" in selected_fields:
            check_digital_proof_urls(imprt, entity, selected_fields["digital_proof"])

        if "WKT" in selected_fields:
            check_is_valid_geometry(imprt, entity, selected_fields["WKT"], fields["the_geom_4326"])
        if current_app.config["IMPORT"]["ID_AREA_RESTRICTION"]:
            check_geometry_outside(
                imprt,
                entity,
                fields["the_geom_local"],
                id_area=current_app.config["IMPORT"]["ID_AREA_RESTRICTION"],
            )

    @staticmethod
    def import_data_to_destination(imprt: TImports) -> None:
        module = db.session.execute(
            sa.select(TModules).filter_by(module_code="IMPORT")
        ).scalar_one()
        name_source = "Import"
        source = db.session.execute(
            sa.select(TSources).filter_by(module=module, name_source=name_source)
        ).scalar_one_or_none()
        transient_table = imprt.destination.get_transient_table()

        destination_bib_fields = db.session.scalars(
            sa.select(BibFields).where(
                BibFields.destination == imprt.destination, BibFields.dest_field != None
            )
        ).all()
        fields = {field.name_field: field for field in destination_bib_fields}

        # Construct the exact list of required fields to copy from transient table to synthese
        # This list contains generated fields, and selected fields (including multi fields).
        insert_fields = {
            fields["datetime_min"],
            fields["datetime_max"],
            fields["the_geom_4326"],
            fields["the_geom_local"],
            fields["the_geom_point"],
            fields["id_area_attachment"],  # XXX sure?
        }
        if imprt.fieldmapping.get(
            "unique_id_sinp_generate",
            current_app.config["IMPORT"]["DEFAULT_GENERATE_MISSING_UUID"],
        ):
            insert_fields |= {fields["unique_id_sinp"]}
        if imprt.fieldmapping.get("altitudes_generate", False):
            insert_fields |= {fields["altitude_min"], fields["altitude_max"]}

        for field_name, source_field in imprt.fieldmapping.items():
            if field_name not in fields:  # not a destination field
                continue
            field = fields[field_name]
            if field.multi:
                if not set(source_field).isdisjoint(imprt.columns):
                    insert_fields |= {field}
            else:
                if source_field in imprt.columns:
                    insert_fields |= {field}

        insert_fields -= {fields["unique_dataset_id"]}  # Column only used for filling `id_dataset`

        select_stmt = (
            sa.select(
                *[transient_table.c[field.dest_field] for field in insert_fields],
                sa.literal(source.id_source),
                sa.literal(source.module.id_module),
                sa.literal(imprt.id_dataset),
                sa.literal(imprt.id_import),
                sa.literal("I"),
            )
            .where(transient_table.c.id_import == imprt.id_import)
            .where(transient_table.c.valid == True)
        )
        names = [field.dest_field for field in insert_fields] + [
            "id_source",
            "id_module",
            "id_dataset",
            "id_import",
            "last_action",
        ]
        insert_stmt = sa.insert(Synthese).from_select(
            names=names,
            select=select_stmt,
        )
        db.session.execute(insert_stmt)

        # TODO: Improve this
        imprt.statistics = {
            "taxa_count": (
                db.session.scalar(
                    sa.select(func.count(distinct(Synthese.cd_nom))).where(
                        Synthese.id_import == imprt.id_import
                    )
                )
            ),
        }

    @staticmethod
    def remove_data_from_destination(imprt: TImports) -> None:
        with start_sentry_child(op="task", description="clean imported data"):
            db.session.execute(sa.delete(Synthese).where(Synthese.id_import == imprt.id_import))

    @staticmethod
    def report_plot(imprt: TImports) -> StandaloneEmbedJson:
        """
        Generate a plot of the taxonomic distribution (for each rank) based on the import.
        The following ranks are used:
        - group1_inpn
        - group2_inpn
        - group3_inpn
        - sous_famille
        - tribu
        - classe
        - ordre
        - famille
        - phylum
        - regne

        Parameters
        ----------
        imprt : TImports
            The import object to generate the plot from.

        Returns
        -------
        dict
            Returns a dict containing data required to generate the plot
        """

        # Define the taxonomic rank to consider
        taxon_ranks = "regne phylum classe ordre famille sous_famille tribu group1_inpn group2_inpn group3_inpn".split()
        figures = []

        # Generate the plot for each rank
        for rank in taxon_ranks:
            # Generate the query to retrieve the count for each value taken by the rank
            c_rank_taxref = getattr(Taxref, rank)
            query = (
                sa.select(
                    func.count(distinct(Synthese.cd_nom)).label("count"),
                    c_rank_taxref.label("rank_value"),
                )
                .select_from(Synthese)
                .outerjoin(Taxref, Taxref.cd_nom == Synthese.cd_nom)
                .where(Synthese.id_import == imprt.id_import)
                .group_by(c_rank_taxref)
            )
            data = np.asarray(
                [
                    r if r[1] != "" else (r[0], "Non-assigné")
                    for r in db.session.execute(query).all()
                ]
            )

            # if data is empty
            if not data.size:
                continue

            # Extract the rank values and counts
            rank_values, counts = data[:, 1], data[:, 0].astype(int)

            # Get angles (in radians) where start each section of the pie chart
            angles = np.cumsum(
                [2 * np.pi * (count / sum(counts)) for i, count in enumerate(counts)]
            ).tolist()

            # Generate the color palette
            palette = (
                linear_palette(Turbo256, len(rank_values))
                if len(rank_values) > 5
                else linear_palette(Plasma256, len(rank_values))
            )
            colors = {value: palette[ix] for ix, value in enumerate(rank_values)}

            # Store the data in a Bokeh data structure
            browsers_source = ColumnDataSource(
                dict(
                    start=[0] + angles[:-1],
                    end=angles,
                    colors=[colors[rank_value] for rank_value in rank_values],
                    countvalue=counts,
                    rankvalue=rank_values,
                )
            )
            # Create the Figure object
            fig = figure(
                x_range=Range1d(start=-3, end=3),
                y_range=Range1d(start=-3, end=3),
                title=f"Distribution des taxons (selon le rang = {rank})",
                tooltips=[("Number", "@countvalue"), (rank, "@rankvalue")],
                toolbar_location=None,
            )
            # Add the Pie chart
            glyph = AnnularWedge(
                x=0,
                y=0,
                inner_radius=0.9,
                outer_radius=1.8,
                start_angle="start",
                end_angle="end",
                line_color="white",
                line_width=3,
                fill_color="colors",
            )
            r = fig.add_glyph(browsers_source, glyph)

            # Add the legend
            legend = Legend(location="top_center")
            for i, name in enumerate(colors):
                legend.items.append(LegendItem(label=name, renderers=[r], index=i))
            fig.add_layout(legend, "below")
            fig.legend.ncols = 3 if len(colors) < 10 else 5

            # ERASE the grid and axis
            fig.grid.visible = False
            fig.axis.visible = False
            fig.title.text_font_size = "16pt"

            # Hide the unselected rank plot
            if rank != "regne":
                fig.visible = False

            # Add the plot to the list of figures
            figures.append(fig)

        if not figures:
            return {}

        # Generate the layout with the plots and the rank selector
        plot_area = column(figures)

        select_plot = Select(
            title="Rang",
            value=0,  # Default is "regne"
            options=[(ix, rank) for ix, rank in enumerate(taxon_ranks)],
            width=fig.width,
        )

        # Update the visibility of the plots when the taxonomic rank selector changes
        select_plot.js_on_change(
            "value",
            CustomJS(
                args=dict(s=select_plot, col=plot_area),
                code="""
            for (const plot of col.children) {
                plot.visible = false
            }
            col.children[s.value].visible = true
        """,
            ),
        )
        column_fig = column(plot_area, select_plot, sizing_mode="scale_width")
        return json_item(column_fig)

    @staticmethod
    def compute_bounding_box(imprt: TImports):
        # The destination where clause will be called only when the import is finished,
        # avoiding looking for unexisting source when the import is still in progress.

        return compute_bounding_box(imprt, "observation", "the_geom_4326")
