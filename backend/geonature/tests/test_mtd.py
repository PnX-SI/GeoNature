import pytest

from sqlalchemy import select, exists

from geonature.core.gn_meta.mtd import sync_af_and_ds_by_user, MTDInstanceApi
from pypnusershub.db.models import Organisme as BibOrganismes
from geonature.core.gn_meta.models import TAcquisitionFramework
from geonature.utils.config import config

from geonature.utils.env import db


@pytest.fixture(scope="function")
def instances():
    instances = {
        "af": MTDInstanceApi(
            "https://inpn.mnhn.fr",
            "26",
        ),
        "dataset": MTDInstanceApi(
            "https://inpn.mnhn.fr",
            "26",
        ),
    }
    return instances


@pytest.mark.usefixtures("client_class", "temporary_transaction", "instances")
class TestMTD:
    @pytest.mark.skip(reason="must fix CI on http request")
    def test_get_xml(self, instances):
        xml = instances["af"]._get_xml(MTDInstanceApi.af_path)
        xml = instances["dataset"]._get_xml(MTDInstanceApi.ds_path)

    @pytest.mark.skip(reason="must fix CI on http request")  # FIXME
    def test_mtd(self, instances):
        # mtd_api = MTDInstanceApi(config["MTD_API_ENDPOINT"], config["MTD"]["ID_INSTANCE_FILTER"])
        config["MTD_API_ENDPOINT"] = instances["af"].api_endpoint
        config["MTD"]["ID_INSTANCE_FILTER"] = instances["af"].instance_id
        af_list = instances["af"].get_af_list()
        af = af_list[0]
        if not af:
            return
        af_digitizer_id = af["id_digitizer"]
        af_actors = af["actors"]
        org_uuid = af_actors[0]["uuid_organism"]
        if af_digitizer_id:
            assert af_digitizer_id == "922"

            sync_af_and_ds_by_user(af_digitizer_id)
            jdds = db.session.scalars(
                select(TAcquisitionFramework).filter_by(id_digitizer=af_digitizer_id)
            ).all()
            # TODO Need Fix when INPN protocol is known
            assert len(jdds) >= 1
            assert db.session.scalar(
                exists().where(BibOrganismes.uuid_organisme == org_uuid).select()
            )
