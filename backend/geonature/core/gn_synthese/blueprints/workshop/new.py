from flask import request, g
from geonature.core.gn_synthese.models import Synthese
from apptax.taxonomie.models import Taxref
from geonature.utils.env import db
from werkzeug.exceptions import NotFound, BadRequest
from sqlalchemy.exc import IntegrityError
from flask import request, jsonify
from werkzeug.exceptions import BadRequest
from sqlalchemy import inspect, select, func
from geonature.core.gn_permissions.decorators import permissions_required
from shapely import wkt
from shapely.ops import transform
from pyproj import Transformer
from geoalchemy2.shape import from_shape
from uuid import uuid4


@permissions_required("C", module_code="SYNTHESE")
def new(permissions):
    data = request.json or {}

    for attr in data:
        if not hasattr(Synthese, attr):
            raise BadRequest(f"Le champ '{attr}' n'existe pas dans le modèle Synthese.")

    required_field = [
        "id_source",
        "id_dataset",
        "cd_nom",
        "the_geom_local",
        "date_min",
        "observers",
    ]

    missing_fields = [col for col in required_field if not col in data]
    if len(missing_fields) > 0:
        conc = ", ".join(missing_fields)
        raise BadRequest(f"Les champs suivants sont requis: {conc}")

    local_srid = db.session.scalar(select(func.Find_SRID("ref_geo", "l_areas", "geom")))
    local_crs = f"EPSG:{local_srid}"

    obs = Synthese(**data)
    obs.id_digitiser = g.current_user.id_role
    if not data.get("nom_cite"):
        taxon = db.session.get(Taxref, data["cd_nom"])
        obs.nom_cite = taxon.nom_valide
    if not data.get("date_max"):
        obs.date_max = data["date_min"]

    count_min = data.get("count_min")
    count_max = data.get("count_max")

    if count_min is None and count_max is None:
        obs.count_min = obs.count_max = 1
    elif count_min is not None and count_max is None:
        obs.count_min = count_min
        obs.count_max = count_min
    elif count_min is None and count_max is not None:
        obs.count_min = count_max
        obs.count_max = count_max
    else:
        obs.count_min = count_min
        obs.count_max = count_max
    if obs.count_min > obs.count_max:
        raise BadRequest("count_min ne peut pas être supérieur à count_max.")

    if not data.get("unique_id_sinp"):
        obs.unique_id_sinp = uuid4()

    if not data.get("id_nomenclature_geo_object_nature"):
        obs.id_nomenclature_geo_object_nature = 170
        # par défaut 170 = Ne sait pas, mais n'est pas valeur par défaut dans GN

    if not data.get("the_geom_4326"):
        geom_local = wkt.loads(data["the_geom_local"])
        transformer = Transformer.from_crs(local_crs, "EPSG:4326", always_xy=True)
        geom_4326 = transform(transformer.transform, geom_local)
        obs.the_geom_4326 = from_shape(geom_4326, srid=4326)
        obs.the_geom_point = from_shape(geom_4326.centroid, srid=4326)
        # on considère que the_geom_4326 et the_geom_point sont liés, mais il faut peut être rajouter des conditions

    db.session.add(obs)
    db.session.commit()

    return jsonify({"id_synthese": obs.id_synthese}), 201
