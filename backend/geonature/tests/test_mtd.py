import pytest

from geonature.core.gn_meta.mtd.mtd_utils import post_jdd_from_user
from geonature.core.gn_meta.mtd import add_unexisting_digitizer
from geonature.core.gn_meta.models import TDatasets


@pytest.mark.usefixtures("client_class", "temporary_transaction")
class TestMTD:
    @pytest.mark.xfail(reason="must fix CI on http request")  # FIXME
    def test_mtd(self):
        add_unexisting_digitizer(10991)
        post_jdd_from_user(id_user=10991)
        jdds = TDatasets.query.filter_by(id_digitizer=10991).all()
        assert len(jdds) >= 1
        jdd_one = jdds[0]
        assert jdd_one.id_digitizer == 10991
