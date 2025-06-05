import pytest
from flask import url_for
from sqlalchemy import select

from apptax.taxonomie.models import Taxref
from geonature.utils.env import db
from pypnusershub.tests.utils import set_logged_user
from .fixtures import *  # noqa


@pytest.mark.usefixtures("client_class", "temporary_transaction")
class TestSyntheseObservationsTaxa:
    def test_get_observations_taxons(self, users, synthese_data):
        set_expected_cd_refs = set(
            db.session.scalars(
                select(Taxref).where(Taxref.cd_nom == synthese_data[name_obs].cd_nom)
            )
            .one()
            .cd_ref
            for name_obs in [
                "obs1",
                "obs2",
                "obs3",
                "p1_af1",
                "p1_af1_2",
                "p1_af2",
                "p2_af2",
                "p2_af1",
                "p3_af3",
            ]
        )
        set_logged_user(self.client, users["self_user"])

        response = self.client.post(
            url_for("gn_synthese.observations.taxa"),
            json={},
        )

        assert response.status_code == 200
        cd_refs = {taxon["cd_ref"] for taxon in response.json}
        assert cd_refs == set_expected_cd_refs
