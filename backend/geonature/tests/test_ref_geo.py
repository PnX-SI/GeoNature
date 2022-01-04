import pytest
import json

from flask import url_for, current_app
from werkzeug.exceptions import Unauthorized, BadRequest
from jsonschema import validate as validate_json
from alembic.migration import MigrationContext
from alembic.script import ScriptDirectory

from geonature.utils.env import db
from geonature.core.gn_meta.models import TDatasets, TAcquisitionFramework
from geonature.core.ref_geo.models import BibAreasTypes
from geonature.utils.env import migrate

from pypnusershub.db.tools import user_to_token

from .fixtures import acquisition_frameworks, datasets
from .utils import set_logged_user_cookie


polygon = {
  "type": "Polygon",
  "coordinates": [
    [
      [
        6.058788299560547,
        44.740515073054915
      ],
      [
        6.039562225341797,
        44.7189291865304
      ],
      [
        6.075954437255859,
        44.70270398212803
      ],
      [
        6.119728088378906,
        44.70392408044993
      ],
      [
        6.13861083984375,
        44.73429623703402
      ],
      [
        6.099643707275391,
        44.75770484489134
      ],
      [
        6.058788299560547,
        44.740515073054915
      ]
    ]
  ]
}


def has_french_dem():
    config = migrate.get_config()
    script = ScriptDirectory.from_config(config)
    migration_context = MigrationContext.configure(db.session.connection())
    current_heads = migration_context.get_current_heads()
    current_heads = set(map(lambda rev: rev.revision, script.get_all_current(current_heads)))
    return '1715cf31a75d' in current_heads  # ign bd alti


@pytest.mark.usefixtures("client_class", "temporary_transaction")
class TestRefGeo:
    expected_altitude = pytest.approx({'altitude_min': 984, 'altitude_max': 2335}, rel=1e-2)
    expected_communes = { 'La Motte-en-Champsaur', 'Saint-Bonnet-en-Champsaur', 'Aubessagne' }

    def test_get_geo_info(self):
        response = self.client.post(url_for("ref_geo.getGeoInfo"), json={
            'geometry': polygon,
            'area_type': 'COM',
        })
        assert response.status_code == 200
        communes = { area['area_name'] for area in response.json['areas'] }
        assert communes == self.expected_communes
        if not has_french_dem():
            pytest.xfail('No French DEM')
        assert response.json['altitude'] == self.expected_altitude

    def test_get_altitude(self):
        if not has_french_dem():
            pytest.xfail('No French DEM')
        response = self.client.post(url_for("ref_geo.getAltitude"), json={
            'geometry': polygon,
        })
        assert response.status_code == 200
        assert response.json == self.expected_altitude

    def test_get_area_intersection(self):
        response = self.client.post(url_for("ref_geo.getAreasIntersection"), json={
            'geometry': polygon,
        })
        assert response.status_code == 200
        validate_json(instance=response.json, schema={
            'type': 'object',
            'patternProperties': {
                '[0-9]*': {
                    'type': 'object',
                    'properties': {
                        'type_code': { 'type': 'string', },
                        'type_name': { 'type': 'string', },
                        'areas': {
                            'type': 'array',
                            'items': {
                                'type': 'object',
                                'properties': {
                                    'area_code': { 'type': 'string', },
                                    'area_name': { 'type': 'string', },
                                    'id_area': { 'type': 'integer', },
                                    'id_type': { 'type': 'integer', },
                                },
                                'additionalProperties': False,
                            }
                        },
                    },
                    'additionalProperties': False,
                },
            },
            'additionalProperties': False,
        })
        communes_type = BibAreasTypes.query.filter_by(type_code='COM').one()
        communes = { area['area_name'] for area in response.json[str(communes_type.id_type)]['areas'] }
        assert communes == self.expected_communes

    def test_get_municipalities(self):
        response = self.client.get(url_for("ref_geo.get_municipalities"))
        assert response.status_code == 200

    def test_get_areas(self):
        response = self.client.get(url_for("ref_geo.get_areas"))
        assert response.status_code == 200

    def test_get_area_size(self):
        response = self.client.post(url_for("ref_geo.get_area_size"), json={
            'geometry': polygon,
        })
        assert response.status_code == 200
        assert response.json == pytest.approx(30526916, rel=1e-3)
