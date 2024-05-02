import json

from flask import jsonify
from marshmallow import EXCLUDE
import numpy as np


from bokeh.layouts import column
from bokeh.plotting import figure
from bokeh.embed import json_item
import sqlalchemy as sa

from gn_module_occhab.schemas import StationSchema, db
from gn_module_occhab.models import OccurenceHabitat, Station
from geonature.core.imports.models import Entity
from sqlalchemy.orm import joinedload


def distribution_plot(imprt):
    id_import = imprt.id_import
    query = Station.filter_by_params(dict(id_import=id_import)).options(
        joinedload(Station.habitats).options(
            joinedload(OccurenceHabitat.habref),
        )
    )
    only = ["habitats", "habitats.habref"]
    only.extend(Station.__nomenclatures__)
    query = query.options(*[joinedload(nomenc) for nomenc in Station.__nomenclatures__])
    data = db.session.scalars(query).unique().all()
    data = jsonify(StationSchema(only=only).dump(data, many=True))
    json.dump(data,open("test.json", "w"))
    x = np.linspace(0, 4 * np.pi, 100)
    sinx = np.sin(x)

    p1 = figure(title="Default legend layout", width=500, height=300)
    [p1.line(x, (1 + i / 20) * sinx, legend_label=f"{1+i/20:.2f}*sin(x)") for i in range(7)]

    p2 = figure(title="Legend layout with 2 columns", width=500, height=300)
    [p2.line(x, (1 + i / 20) * sinx, legend_label=f"{1+i/20:.2f}*sin(x)") for i in range(7)]
    p2.legend.ncols = 2

    p3 = figure(title="Legend layout with 3 rows", width=500, height=300)
    [p3.line(x, (1 + i / 20) * sinx, legend_label=f"{1+i/20:.2f}*sin(x)") for i in range(7)]
    p3.legend.nrows = 3
    return json_item(column(p1, p2, p3))
