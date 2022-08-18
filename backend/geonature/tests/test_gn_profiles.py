from datetime import datetime
from random import randint

import pytest
from flask import url_for
import sqlalchemy as sa
from sqlalchemy.sql.expression import func
from geoalchemy2.elements import WKTElement

from geonature.utils.env import db
from geonature.core.gn_meta.models import TDatasets
from geonature.core.gn_profiles.models import (
    VConsistancyData,
    VmCorTaxonPhenology,
    VmValidProfiles,
    TParameters,
    CorTaxonParameters,
    VSyntheseForProfiles,
)
from geonature.core.gn_synthese.models import Synthese
from geonature.core.taxonomie.models import Taxref


from .fixtures import acquisition_frameworks, datasets, synthese_data, source

ALT_MIN = 1000
ALT_MAX = 1200
DATE_MIN = "2021-01-01"
DATE_MAX = "2021-01-05"


def create_synthese_record(
    cd_nom=None,
    date_min=datetime.now(),
    date_max=datetime.now(),
    x=6.12,
    y=44.85,
    altitude_min=None,
    altitude_max=None,
    id_dataset=None,
    nom_cite="blah",
    id_nomenclature_valid_status=None,
    id_nomenclature_life_stage=None,
):
    if not cd_nom:
        cd_nom = Taxref.query.first().cd_nom
    if not id_dataset:
        id_dataset = TDatasets.query.first().id_dataset

    geom_4326 = WKTElement(f"POINT({str(x)} {str(y)})", srid=4326)

    return Synthese(
        cd_nom=cd_nom,
        date_min=date_min,
        date_max=date_max,
        the_geom_local=func.st_transform(geom_4326, 2154),
        the_geom_4326=geom_4326,
        altitude_min=altitude_min,
        altitude_max=altitude_max,
        id_dataset=id_dataset,
        nom_cite=nom_cite,
        id_nomenclature_valid_status=id_nomenclature_valid_status,
        id_nomenclature_life_stage=id_nomenclature_life_stage,
    )


@pytest.fixture
def valid_status_for_profiles():
    param = TParameters.query.filter_by(name="id_valid_status_for_profiles").one()
    return param.value.split(",")[0]


@pytest.fixture
def cd_nom_for_profiles():
    param = TParameters.query.filter_by(name="id_rang_for_profiles").one()
    id_rang = param.value.split(",")[0]
    taxref = Taxref.query.filter_by(id_rang=id_rang).first()
    return taxref.cd_nom


@pytest.fixture(scope="function")
def sample_synthese_records_for_profile(datasets, valid_status_for_profiles, cd_nom_for_profiles):
    # set a profile for taxon
    synthese_record_for_profile = create_synthese_record(
        cd_nom=cd_nom_for_profiles,
        x=6.12,
        y=44.85,
        date_min=datetime.strptime(DATE_MIN, "%Y-%m-%d"),
        date_max=datetime.strptime(DATE_MAX, "%Y-%m-%d"),
        altitude_min=ALT_MIN,
        altitude_max=ALT_MAX,
        id_nomenclature_valid_status=valid_status_for_profiles,
        id_nomenclature_life_stage=func.ref_nomenclatures.get_id_nomenclature("STADE_VIE", "10"),
    )
    # set life stage active for this obs
    taxon_param = CorTaxonParameters(
        cd_nom=cd_nom_for_profiles,
        spatial_precision=2000,
        temporal_precision_days=10,
        active_life_stage=True,
    )
    with db.session.begin_nested():
        db.session.add(synthese_record_for_profile)
        db.session.add(taxon_param)

    with db.session.begin_nested():
        db.session.execute("REFRESH MATERIALIZED VIEW gn_profiles.vm_valid_profiles")
        db.session.execute("REFRESH MATERIALIZED VIEW gn_profiles.vm_cor_taxon_phenology")

    return synthese_record_for_profile


@pytest.fixture(scope="function")
def wrong_sample_synthese_records_for_profile(
    datasets,
    cd_nom_for_profiles,
):
    # This obs will be not used for computing profiles as it has no dates
    wrong_new_obs = create_synthese_record(
        cd_nom=cd_nom_for_profiles,
        x=20.12,
        y=55.85,
        altitude_min=10,
        altitude_max=20,
        id_nomenclature_life_stage=func.ref_nomenclatures.get_id_nomenclature("STADE_VIE", "11"),
    )

    with db.session.begin_nested():
        db.session.add(wrong_new_obs)

    with db.session.begin_nested():
        db.session.execute("REFRESH MATERIALIZED VIEW gn_profiles.vm_valid_profiles")
        db.session.execute("REFRESH MATERIALIZED VIEW gn_profiles.vm_cor_taxon_phenology")

    return wrong_new_obs


@pytest.mark.usefixtures("client_class", "temporary_transaction")
class TestGnProfiles:
    def test_checks(self, sample_synthese_records_for_profile):
        """
        Call of view VConsistancyData which process to the tree checks:
            - check altitude
            - check phenology
            - check distribution
        -> test the tree sql associated functions
        """
        valid_new_obs = sample_synthese_records_for_profile

        assert VSyntheseForProfiles.query.get(valid_new_obs.id_synthese) is not None

        profile = VmValidProfiles.query.filter_by(
            cd_ref=func.taxonomie.find_cdref(valid_new_obs.cd_nom)
        ).first()
        assert profile is not None

        consistancy_data = VConsistancyData.query.filter_by(
            id_synthese=valid_new_obs.id_synthese
        ).one()
        assert consistancy_data.valid_distribution is True
        assert consistancy_data.valid_altitude is True
        assert consistancy_data.valid_phenology is True

        cor = VmCorTaxonPhenology.query.filter_by(cd_ref=consistancy_data.cd_ref).first()
        assert cor is not None

    def test_checks_all_false(
        self, sample_synthese_records_for_profile, wrong_sample_synthese_records_for_profile
    ):
        # Need to create the good sample for the taxon parameter and to
        # set the profile correctly
        wrong_new_obs = wrong_sample_synthese_records_for_profile

        assert VSyntheseForProfiles.query.get(wrong_new_obs.id_synthese) is None

        profile = VmValidProfiles.query.filter_by(
            cd_ref=func.taxonomie.find_cdref(wrong_new_obs.cd_nom)
        ).first()
        assert profile is not None

        consistancy_data = VConsistancyData.query.filter(
            VConsistancyData.id_synthese == wrong_new_obs.id_synthese
        ).one()

        assert consistancy_data.valid_distribution is False
        assert consistancy_data.valid_altitude is False
        assert consistancy_data.valid_phenology is False

        cor = VmCorTaxonPhenology.query.filter_by(cd_ref=consistancy_data.cd_ref).first()
        assert cor is not None

    def test_get_phenology(self, sample_synthese_records_for_profile):
        response = self.client.get(
            url_for(
                "gn_profiles.get_phenology", cd_ref=sample_synthese_records_for_profile.cd_nom
            ),
            query_string={
                "id_nomenclature_life_stage": db.session.query(
                    func.ref_nomenclatures.get_id_nomenclature("STADE_VIE", "10")
                ).first()[0]
            },
        )

        assert response.status_code == 200, response.json
        data = response.get_json()
        first_pheno = data[0]
        assert first_pheno["doy_min"] == 0
        assert first_pheno["doy_max"] == 10
        assert first_pheno["extreme_altitude_min"] == 1000
        assert first_pheno["extreme_altitude_max"] == 1200
        assert first_pheno["calculated_altitude_min"] == 1000
        assert first_pheno["calculated_altitude_max"] == 1200

    def test_get_phenology_none(self):
        invalid_cd_nom = 0

        response = self.client.get(
            url_for("gn_profiles.get_phenology", cd_ref=invalid_cd_nom),
        )

        assert response.status_code == 204, response.json  # No content

    def test_valid_profile(self, sample_synthese_records_for_profile):
        response = self.client.get(
            url_for("gn_profiles.get_profile", cd_ref=sample_synthese_records_for_profile.cd_nom),
        )
        assert response.status_code == 200, response.json
        data = response.get_json()["properties"]
        assert data["altitude_min"] == ALT_MIN
        assert data["altitude_max"] == ALT_MAX
        assert DATE_MIN in data["first_valid_data"]
        assert DATE_MAX in data["last_valid_data"]
        assert data["count_valid_data"] == 1
        assert data["active_life_stage"] == True

    def test_valid_profile_404(self):
        invalid_cd_nom = 0

        response = self.client.get(
            url_for("gn_profiles.get_profile", cd_ref=invalid_cd_nom),
        )

        assert response.status_code == 404, response.json

    def test_get_consistancy_data(self, sample_synthese_records_for_profile):
        synthese_record = sample_synthese_records_for_profile

        response = self.client.get(
            url_for("gn_profiles.get_consistancy_data", id_synthese=synthese_record.id_synthese),
        )
        assert response.status_code == 200, response.json

    def test_get_observation_score_no_cd_ref(self):
        data = {}

        response = self.client.post(url_for("gn_profiles.get_observation_score"), json=data)

        assert response.status_code == 400, response.json
        assert response.json.get("description") == "No cd_ref provided"

    def test_get_observation_score_cd_ref_not_found(self):
        data = {"cd_ref": 0}

        response = self.client.post(url_for("gn_profiles.get_observation_score"), json=data)

        assert response.status_code == 404, response.json
        assert response.json.get("description") == "No profile for this cd_ref"

    def test_get_observation_score(self, sample_synthese_records_for_profile):
        data = {
            "altitude_min": ALT_MIN,
            "altitude_max": ALT_MAX,
            "date_min": DATE_MIN,
            "date_max": DATE_MAX,
            "cd_ref": sample_synthese_records_for_profile.cd_nom,
            "geom": {"coordinates": [6.12, 44.85], "type": "Point"},
        }

        response = self.client.post(url_for("gn_profiles.get_observation_score"), json=data)
        resp_json = response.json
        assert response.status_code == 200, response.json
        assert {
            "valid_distribution",
            "valid_altitude",
            "valid_phenology",
            "valid_life_stage",
            "life_stage_accepted",
            "errors",
            "profil",
            "check_life_stage",
        } == set(resp_json.keys())
        assert len(resp_json["errors"]) == 0

    def test_get_observation_score_no_date(self, sample_synthese_records_for_profile):
        data = {
            "altitude_min": ALT_MIN,
            "altitude_max": ALT_MAX,
            "date_min": DATE_MIN,
            "cd_ref": sample_synthese_records_for_profile.cd_nom,
            "geom": {"coordinates": [6.12, 44.85], "type": "Point"},
        }

        response = self.client.post(url_for("gn_profiles.get_observation_score"), json=data)

        assert response.status_code == 400, response.json
        assert response.json["description"] == "Missing date min or date max"

    def test_get_observation_score_no_altitude(self, sample_synthese_records_for_profile):
        data = {
            "altitude_min": ALT_MIN,
            "date_min": DATE_MIN,
            "date_max": DATE_MAX,
            "cd_ref": sample_synthese_records_for_profile.cd_nom,
            "geom": {"coordinates": [6.12, 44.85], "type": "Point"},
        }

        response = self.client.post(url_for("gn_profiles.get_observation_score"), json=data)

        assert response.status_code == 400, response.json
        assert response.json["description"] == "Missing altitude_min or altitude_max"

    def test_get_observation_score_not_observed_altitude(
        self, sample_synthese_records_for_profile
    ):
        alt_min = 500
        alt_max = 600
        data = {
            "altitude_min": alt_min,
            "altitude_max": alt_max,
            "date_min": DATE_MIN,
            "date_max": DATE_MAX,
            "cd_ref": sample_synthese_records_for_profile.cd_nom,
            "geom": {"coordinates": [6.12, 44.85], "type": "Point"},
        }

        response = self.client.post(url_for("gn_profiles.get_observation_score"), json=data)

        assert response.status_code == 200, response.json
        assert f"Le taxon n'a jamais été observé à cette altitude ({alt_min}-{alt_max}m)" in [
            err["value"] for err in response.json["errors"]
        ]

    @pytest.mark.xfail(reason="Test non implémenté")
    def test_get_observation_score_error_not_observed_alt(self):
        # TODO when routes.py is fixed for this
        raise NotImplementedError

    def test_get_observation_score_error_not_observed(self, sample_synthese_records_for_profile):
        # In the date, only the days are relevant not the date. Which means
        # that when 2022-01-20 is entered, the doy is more or less 20.
        data = {
            "altitude_min": ALT_MIN,
            "altitude_max": ALT_MAX,
            "date_min": "2022-01-20",
            "date_max": "2022-01-25",
            "cd_ref": sample_synthese_records_for_profile.cd_nom,
            "geom": {"coordinates": [6.12, 44.85], "type": "Point"},
        }

        response = self.client.post(url_for("gn_profiles.get_observation_score"), json=data)

        assert response.status_code == 200, response.json
        assert "Le taxon n'a jamais été observé à cette periode" in [
            err["value"] for err in response.json["errors"]
        ]

    def test_get_observation_score_error_geom_not_observed(
        self, sample_synthese_records_for_profile
    ):
        data = {
            "altitude_min": ALT_MIN,
            "altitude_max": ALT_MAX,
            "date_min": DATE_MIN,
            "date_max": DATE_MAX,
            "cd_ref": sample_synthese_records_for_profile.cd_nom,
            "geom": {"coordinates": [1000, 2000], "type": "Point"},
        }

        response = self.client.post(url_for("gn_profiles.get_observation_score"), json=data)

        assert response.status_code == 200, response.json
        assert "Le taxon n'a jamais été observé dans cette zone géographique" in [
            err["value"] for err in response.json["errors"]
        ]
