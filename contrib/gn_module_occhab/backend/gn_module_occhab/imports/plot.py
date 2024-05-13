import json

from flask import jsonify
from marshmallow import EXCLUDE
import numpy as np


from bokeh.layouts import column
from bokeh.plotting import figure
from bokeh.models import CustomJS, Select
from bokeh.embed import json_item
from pypnnomenclature.models import BibNomenclaturesTypes, TNomenclatures
import sqlalchemy as sa
from sqlalchemy import func, distinct

from gn_module_occhab.schemas import OccurenceHabitatSchema, StationSchema, db
from gn_module_occhab.models import OccurenceHabitat, Station
from geonature.core.imports.models import Entity
from bokeh.palettes import linear_palette, Turbo256, Plasma256
from sqlalchemy.orm import joinedload
from bokeh.models import Range1d, AnnularWedge, ColumnDataSource, Legend, LegendItem


def distribution_plot(imprt):
    categories = [
        "nom_cite",
        "nomenclature_determination_type",
        "nomenclature_collection_technique",
    ]
    figures = []
    final_cat = []
    # Generate the plot for each categorie
    for categorie in categories:
        # Generate the query to retrieve the count for each value taken by the categorie
        c_categorie = getattr(OccurenceHabitat, categorie)
        if categorie in OccurenceHabitat.__nomenclatures__:
            query = (
                sa.select(
                    func.count(distinct(OccurenceHabitat.id_habitat)),
                    TNomenclatures.label_default,
                    BibNomenclaturesTypes.label_default,
                )
                .join(
                    c_categorie,
                )
                .join(TNomenclatures.nomenclature_type)
                .where(OccurenceHabitat.id_import == imprt.id_import)
                .group_by(TNomenclatures.label_default, BibNomenclaturesTypes.label_default)
            )
        else:
            query = (
                sa.select(
                    func.count(distinct(OccurenceHabitat.id_habitat)),
                    c_categorie,
                    sa.literal(categorie),
                )
                .where(OccurenceHabitat.id_import == imprt.id_import)
                .group_by(c_categorie)
            )

        data = np.asarray(
            [
                r if r[1] != "" else (r[0], "Non-assigné")
                for r in db.session.execute(query).unique().all()
            ]
        )
        if data.size == 0:
            continue

        # Extract the rank values and counts
        rank_values, counts = data[:, 1], data[:, 0].astype(int)
        rank = data[0, 2]

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
            tooltips=[("Number", "@countvalue"), (f"{rank}", "@rankvalue")],
            width=600,
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
        if rank != categories[0]:
            fig.visible = False

        # Add the plot to the list of figures
        figures.append(fig)
        final_cat.append(categorie)

    plot_area = column(figures)
    select_plot = Select(
        title="Rang",
        value=0,  # Default is "regne"
        options=[(ix, rank) for ix, rank in enumerate(final_cat)],
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
