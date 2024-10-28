import numpy as np
import sqlalchemy as sa
from apptax.taxonomie.models import Taxref
from bokeh.embed import json_item
from bokeh.embed.standalone import StandaloneEmbedJson
from bokeh.layouts import column
from bokeh.models import (
    AnnularWedge,
    ColumnDataSource,
    CustomJS,
    Legend,
    LegendItem,
    Range1d,
    Select,
)
from bokeh.palettes import Plasma256, Turbo256, linear_palette
from bokeh.plotting import figure
from geonature.core.gn_synthese.models import Synthese
from geonature.utils.env import db


def taxon_distribution_plot(imprt) -> StandaloneEmbedJson:
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
    taxon_ranks = "regne phylum classe ordre famille sous_famille tribu group1_inpn group2_inpn group3_inpn".split()
    figures = []

    # Generate the plot for each rank
    for rank in taxon_ranks:
        # Generate the query to retrieve the count for each value taken by the rank
        c_rank_taxref = getattr(Taxref, rank)
        query = (
            sa.select(
                sa.func.count(sa.distinct(Synthese.cd_nom)).label("count"),
                c_rank_taxref.label("rank_value"),
            )
            .select_from(Synthese)
            .outerjoin(Taxref, Taxref.cd_nom == Synthese.cd_nom)
            .where(Synthese.id_import == imprt.id_import)
            .group_by(c_rank_taxref)
        )
        data = np.asarray(
            [r if r[1] != "" else (r[0], "Non-assigné") for r in db.session.execute(query).all()]
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
            title=f"Distribution des taxons selon {rank}",
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
        title="Critère",
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
