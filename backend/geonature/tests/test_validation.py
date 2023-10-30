import pytest
from datetime import datetime, timedelta
import sqlalchemy as sa
from flask import url_for
from werkzeug.exceptions import Unauthorized, BadRequest

from geonature.core.gn_synthese.models import Synthese
from geonature.core.gn_commons.models import TValidations, VLatestValidations
from geonature.core.gn_profiles.models import VConsistancyData
from gn_module_validation.tasks import set_auto_validation
from geonature.utils.env import db
from geonature.utils.config import config

from pypnnomenclature.models import TNomenclatures

from .fixtures import *
from .utils import set_logged_user


gn_module_validation = pytest.importorskip("gn_module_validation")
pytestmark = pytest.mark.skipif(
    "VALIDATION" in config["DISABLED_MODULES"], reason="Validation is disabled"
)


@pytest.fixture()
def validation_with_max_score_and_wait_validation_status():
    id_nomenclature_attente_validation = db.session.execute(
        """ select tn.id_nomenclature from ref_nomenclatures.t_nomenclatures tn where tn.mnemonique = 'En attente de validation' """
    ).scalar()

    validations_to_update = (
        db.session.query(
            TValidations.id_validation,
            VLatestValidations.uuid_attached_row,
            VConsistancyData.id_synthese,
        )
        .join(TValidations, TValidations.id_validation == VLatestValidations.id_validation)
        .join(VConsistancyData, VConsistancyData.id_sinp == VLatestValidations.uuid_attached_row)
        .filter(
            TValidations.validation_auto == True,
            VLatestValidations.id_nomenclature_valid_status == id_nomenclature_attente_validation,
            VLatestValidations.id_validator == None,
            VConsistancyData.valid_phenology == True,
            VConsistancyData.valid_altitude == True,
            VConsistancyData.valid_distribution == True,
        )
        .all()
    )
    return validations_to_update


@pytest.mark.usefixtures("client_class", "temporary_transaction", "app")
class TestValidation:
    def test_get_synthese_data(self, users, synthese_data):
        response = self.client.get(url_for("validation.get_synthese_data"))
        assert response.status_code == Unauthorized.code
        set_logged_user(self.client, users["self_user"])
        response = self.client.get(url_for("validation.get_synthese_data"))
        assert response.status_code == 200
        assert len(response.json["features"]) >= len(synthese_data)

    def test_get_status_names(self, users, synthese_data):
        response = self.client.get(url_for("validation.get_statusNames"))
        assert response.status_code == Unauthorized.code
        set_logged_user(self.client, users["user"])
        response = self.client.get(url_for("validation.get_statusNames"))
        assert response.status_code == 200

    def test_add_validation_status(self, users, synthese_data):
        set_logged_user(self.client, users["user"])
        synthese = synthese_data["obs1"]
        id_nomenclature_valid_status = db.session.execute(
            sa.select(TNomenclatures).where(
                sa.and_(
                    TNomenclatures.cd_nomenclature == "1",
                    TNomenclatures.nomenclature_type.has(mnemonique="STATUT_VALID"),
                )
            )
        ).scalar_one()
        validation_date = datetime.now()

        response = self.client.get(
            url_for("validation.get_validation_date", uuid=synthese.unique_id_sinp)
        )
        assert response.status_code == 204  # No content

        data = {
            "statut": id_nomenclature_valid_status.id_nomenclature,
            "comment": "lala",
        }
        response = self.client.post(
            url_for("validation.post_status", id_synthese=synthese.id_synthese), data=data
        )
        assert response.status_code == 200

        response = self.client.get(
            url_for("validation.get_validation_date", uuid=synthese.unique_id_sinp)
        )
        assert response.status_code == 200
        assert abs(datetime.fromisoformat(response.json) - validation_date) < timedelta(seconds=2)

    def test_get_validation_history(self, users, synthese_data):
        set_logged_user(self.client, users["user"])
        response = self.client.get(url_for("gn_commons.get_hist", uuid_attached_row="invalid"))
        assert response.status_code == BadRequest.code

        # Test the entirety of the route (including the history return)
        synthese = synthese_data["obs1"]

        id_nomenclature_valid_status = db.session.execute(
            sa.select(TNomenclatures).where(
                sa.and_(
                    TNomenclatures.cd_nomenclature == "1",
                    TNomenclatures.nomenclature_type.has(mnemonique="STATUT_VALID"),
                )
            )
        ).scalar_one()
        # add a validation item to fill the history variable in the get_hist() route
        response = self.client.post(
            url_for("validation.post_status", id_synthese=synthese_data["obs1"].id_synthese),
            data={
                "statut": id_nomenclature_valid_status.id_nomenclature,
                "comment": "lala",
            },
        )
        # check the insert status
        assert response.status_code == 200

        response = self.client.get(
            url_for("gn_commons.get_hist", uuid_attached_row=synthese.unique_id_sinp)
        )
        assert response.status_code == 200
        assert len(response.data) > 0
        assert response.json[0]["id_status"] == str(id_nomenclature_valid_status.id_nomenclature)

    def test_auto_validation(
        self,
        users,
        app,
        auto_validation_enabled,
        validation_with_max_score_and_wait_validation_status,
    ):
        fct_auto_validation_name = app.config["VALIDATION"][
            "AUTO_VALIDATION_SQL_FUNCTION"
        ]  # config["VALIDATION"]["AUTO_VALIDATION_SQL_FUNCTION"]
        set_logged_user(self.client, users["user"])

        id_nomenclature_probable = db.session.execute(
            """ select tn.id_nomenclature from ref_nomenclatures.t_nomenclatures tn where tn.mnemonique = 'Probable' """
        ).scalar()
        id_nomenclature_attente_validation = db.session.execute(
            """ select tn.id_nomenclature from ref_nomenclatures.t_nomenclatures tn where tn.mnemonique = 'En attente de validation' """
        ).scalar()

        list_synthese_to_update = []
        for row in validation_with_max_score_and_wait_validation_status:
            list_synthese_to_update.append(row[2])

        synthese_valid_statut_before_update = (
            db.session.query(Synthese.id_nomenclature_valid_status)
            .filter(Synthese.id_synthese.in_(list_synthese_to_update))
            .all()
        )
        assert all(
            synthese_valid_statut[0] == id_nomenclature_attente_validation
            for synthese_valid_statut in synthese_valid_statut_before_update
        )

        # On applique la fonction
        set_auto_validation()  # list_synthese_updated = TValidations.auto_validation(fct_auto_validation_name)
        synthese_valid_statut_after_update = (
            db.session.query(Synthese.id_nomenclature_valid_status)
            .filter(Synthese.id_synthese.in_(list_synthese_to_update))
            .all()
        )
        assert all(
            synthese_valid_statut[0] == id_nomenclature_probable
            for synthese_valid_statut in synthese_valid_statut_after_update
        )
