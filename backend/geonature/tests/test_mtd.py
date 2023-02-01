import pytest

from geonature.core.gn_meta.mtd import sync_af_and_ds_by_user, MTDInstanceApi
from pypnusershub.db.models import Organisme as BibOrganismes
from geonature.core.gn_meta.models import TAcquisitionFramework
from geonature.utils.config import config

from geonature.utils.env import db


@pytest.mark.usefixtures("client_class", "temporary_transaction")
class TestMTD:
    @pytest.mark.skip(reason="must fix CI on http request")  # FIXME
    def test_mtd(self):
        mtd_api = MTDInstanceApi(
            config["MTD_API_ENDPOINT"], config["MTD"]["ID_INSTANCE_FILTER"]
        )
        af_list = mtd_api.get_af_list()
        af = af_list[0]
        if not af:
            return
        af_digitizer_id = af["id_digitizer"]
        af_actors = af["actors"]
        org_uuid = af_actors[0]["uuid_organism"]
        if af_digitizer_id:
            sync_af_and_ds_by_user(af_digitizer_id)
            jdds = TAcquisitionFramework.query.filter_by(id_digitizer=af_digitizer_id).all()
            assert len(jdds) >= 1
            assert db.session.query(
                BibOrganismes.query.filter_by(uuid_organisme=org_uuid).exists()
            ).scalar()
