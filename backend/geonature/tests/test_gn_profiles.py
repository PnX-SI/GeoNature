from datetime import date, datetime, timedelta
from random import randint
from geonature.core.gn_meta.models import TDatasets

import pytest
from flask import g, url_for, current_app
import sqlalchemy as sa
from sqlalchemy.sql.expression import func
from geoalchemy2.elements import WKTElement

from geonature.utils.env import db
from geonature.core.gn_profiles.models import (
    VConsistancyData,
    VmCorTaxonPhenology,
    VmValidProfiles,
)
from geonature.core.gn_synthese.models import Synthese
from geonature.core.taxonomie.models import Taxref


from .fixtures import acquisition_frameworks, datasets


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


@pytest.fixture(scope="function")
def sample_synthese_records_for_profile(app, datasets):
    Synthese.query.delete()  # clear all synthese entries
    # set a profile for taxon 212 (sonneur)
    synthese_record_for_profile = create_synthese_record(
        cd_nom=212,
        x=6.12,
        y=44.85,
        date_min=datetime(2021, 1, 1),
        date_max=datetime(2021, 1, 1),
        altitude_min=1000,
        altitude_max=1200,
        id_nomenclature_valid_status=func.ref_nomenclatures.get_id_nomenclature(
            "STATUT_VALID", "1"
        ),
        id_nomenclature_life_stage=func.ref_nomenclatures.get_id_nomenclature("STADE_VIE", "10"),
    )
    # set life stage active for animalia
    # with db.session.begin_nested():
    with db.session.begin_nested():
        db.session.add(synthese_record_for_profile)
        # TODO: remove all present parameters for cd_nom 212
        db.session.execute(
            """
        INSERT INTO
            gn_profiles.cor_taxons_parameters (
                cd_nom,
                spatial_precision,
                temporal_precision_days,
                active_life_stage
            )
        VALUES
            (
                183716,
                2000,
                10,
                TRUE
            )
        """
        )

    db.session.execute("REFRESH MATERIALIZED VIEW gn_profiles.vm_valid_profiles")
    db.session.execute("REFRESH MATERIALIZED VIEW gn_profiles.vm_cor_taxon_phenology")


@pytest.mark.usefixtures(
    "client_class", "temporary_transaction", "sample_synthese_records_for_profile"
)
class TestGnProfiles:
    def test_checks(self, app):
        """
        Call of view VConsistancyData which process to the tree checks:
            - check altitude
            - check phenology
            - check distribution
        -> test the tree sql associated functions
        """
        valid_new_obs = create_synthese_record(
            cd_nom=212,
            x=6.12,
            y=44.85,
            date_min=datetime(2021, 1, 1),
            date_max=datetime(2021, 1, 1),
            altitude_min=1100,
            altitude_max=1100,
            id_nomenclature_life_stage=func.ref_nomenclatures.get_id_nomenclature(
                "STADE_VIE", "10"
            ),
        )
        with db.session.begin_nested():
            db.session.add(valid_new_obs)

        # check altitude
        consitancy_data = VConsistancyData.query.filter(
            VConsistancyData.id_synthese == valid_new_obs.id_synthese
        ).one()
        cor = VmCorTaxonPhenology.query.first()
        assert consitancy_data.valid_distribution is True
        assert consitancy_data.valid_altitude is True
        assert consitancy_data.valid_phenology is True
        profile = VmValidProfiles.query.first()

        wrong_new_obs = create_synthese_record(
            cd_nom=212,
            x=20.12,
            y=55.85,
            altitude_min=10,
            altitude_max=20,
            id_nomenclature_life_stage=func.ref_nomenclatures.get_id_nomenclature(
                "STADE_VIE", "11"
            ),
        )
        with db.session.begin_nested():
            db.session.add(wrong_new_obs)
        consitancy_data = VConsistancyData.query.filter(
            VConsistancyData.id_synthese == wrong_new_obs.id_synthese
        ).one()
        cor = VmCorTaxonPhenology.query.first()

        assert consitancy_data.valid_distribution is False
        assert consitancy_data.valid_altitude is False
        assert consitancy_data.valid_phenology is False

    def test_get_phenology(self, app):
        response = self.client.get(
            url_for("gn_profiles.get_phenology", cd_ref=212),
            query_string={
                "id_nomenclature_life_stage": db.session.query(
                    func.ref_nomenclatures.get_id_nomenclature("STADE_VIE", "10")
                ).first()[0]
            },
        )

        assert response.status_code == 200
        data = response.get_json()
        first_pheno = data[0]
        assert first_pheno["doy_min"] == 0
        assert first_pheno["doy_max"] == 10
        assert first_pheno["extreme_altitude_min"] == 1000
        assert first_pheno["extreme_altitude_max"] == 1200
        assert first_pheno["calculated_altitude_min"] == 1000
        assert first_pheno["calculated_altitude_max"] == 1200

    def test_valid_profile(self, app):
        response = self.client.get(
            url_for("gn_profiles.get_profile", cd_ref=212),
        )
        assert response.status_code == 200
        data = response.get_json()["properties"]
        assert data["altitude_min"] == 1000
        assert data["altitude_max"] == 1200
        assert data["first_valid_data"] == "2021-01-01 00:00:00"
        assert data["last_valid_data"] == "2021-01-01 00:00:00"
        assert data["count_valid_data"] == 1
        assert data["active_life_stage"] == True

    def test_get_consistancy_data(self, app):
        synthese_record = Synthese.query.first()
        response = self.client.get(
            url_for("gn_profiles.get_consistancy_data", id_synthese=synthese_record.id_synthese),
        )
        assert response.status_code == 200

    @pytest.mark.skip()  # FIXME
    def test_get_observation_score(self, app):
        data = {}
        response = self.client.post(url_for("gn_profiles.get_observation_score"), json=data)
        assert response.status_code == 400

        data = {
            "altitude_min": 500,
            "altitude_max": 600,
            "date_min": "2021-01-01",
            "date_max": "2021-01-01",
            "cd_ref": 500,
            "geom": {"coordinates": [6.12, 44.85], "type": "Point"},
        }
        response = self.client.post(url_for("gn_profiles.get_observation_score"), json=data)
        assert response.status_code == 204  # No content

        data.update({"cd_ref": 212})
        response = self.client.post(url_for("gn_profiles.get_observation_score"), json=data)
        assert response.status_code == 200
        result = response.get_json()
        assert result["valid_altitude"] == False
        assert result["valid_phenology"] == False
        assert result["valid_distribution"] == True

        data.update(
            {
                "date_min": "2021-10-01",
                "date_max": "2021-10-01",
                "altitude_min": 1000,
                "altitude_min": 1200,
            }
        )
        response = self.client.post(url_for("gn_profiles.get_observation_score"), json=data)
        assert response.status_code == 200
        result = response.get_json()
        assert result["valid_altitude"] == True
        assert result["valid_phenology"] == False
        assert result["valid_distribution"] == True

        data.update(
            {
                "date_min": "2021-01-01",
                "date_max": "2021-01-10",  # periode de 10 jour
            }
        )
        response = self.client.post(url_for("gn_profiles.get_observation_score"), json=data)
        assert response.status_code == 200
        result = response.get_json()
        assert result["valid_altitude"] == True
        assert result["valid_phenology"] == True
        assert result["valid_distribution"] == True
