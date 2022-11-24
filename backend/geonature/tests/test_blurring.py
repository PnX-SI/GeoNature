import pytest

from flask import testing, url_for, current_app

from geonature.utils.env import db

from .fixtures import *
from .utils import set_logged_user_cookie


@pytest.fixture(scope="class")
def blurring_config(app):
    from geonature.utils.config_schema import DataBlurringManagement

    app.config.update(
        {
            "DATA_BLURRING": DataBlurringManagement().load(
                {
                    "ENABLE_DATA_BLURRING": True,
                    "AREA_TYPE_FOR_DIFFUSION_LEVELS": [
                        {"level": "0", "area": "M5"},
                        {"level": "1", "area": "COM"},
                        {"level": "2", "area": "M10"},
                        {"level": "3", "area": "DEP"},
                    ],
                    "AREA_TYPE_FOR_SENSITIVITY_LEVELS": [
                        {"level": "1", "area": "COM"},
                        {"level": "2", "area": "M10"},
                        {"level": "3", "area": "DEP"},
                    ],
                }
            ),
        }
    )


@pytest.fixture(scope="class")
def blurred_users():
    from geonature.core.gn_permissions.models import (
        TActions,
        BibFiltersType,
        CorRoleActionFilterModuleObject,
    )
    from geonature.core.gn_commons.models import TModules, TObjects
    from pypnusershub.db.models import User, Application, Profils as Profil, UserApplicationRight

    app = Application.query.filter(Application.code_application == "GN").one()
    profil = Profil.query.filter(Profil.nom_profil == "Lecteur").one()
    read_action = TActions.query.filter_by(code_action="R").one()
    scope = BibFiltersType.query.filter_by(code_filter_type="SCOPE").one()
    synthese_module = TModules.query.filter_by(module_code="SYNTHESE").one()
    precision = BibFiltersType.query.filter_by(code_filter_type="PRECISION").one()
    sensitivite_observation = TObjects.query.filter_by(code_object="SENSITIVE_OBSERVATION").one()
    private_observation = TObjects.query.filter_by(code_object="PRIVATE_OBSERVATION").one()

    with db.session.begin_nested():
        user = User(groupe=False, active=True, identifiant="blurred_user")
        db.session.add(user)
    with db.session.begin_nested():
        right = UserApplicationRight(
            id_role=user.id_role, id_application=app.id_application, id_profil=profil.id_profil
        )
        db.session.add(right)
    with db.session.begin_nested():
        scope_perm = CorRoleActionFilterModuleObject(
            role=user,
            action=read_action,
            filter_type=scope,
            value_filter="3",
            module=synthese_module,
        )
        db.session.add(scope_perm)
    with db.session.begin_nested():
        precision_perm = CorRoleActionFilterModuleObject(
            gathering=scope_perm.gathering,
            role=user,
            action=read_action,
            filter_type=precision,
            value_filter="fuzzy",
            module=synthese_module,
        )
        db.session.add(precision_perm)

    return {
        "blurred_user": user,
    }


@pytest.fixture
def sensitivity_rule(synthese_data):
    from geonature.core.sensitivity.models import (
        SensitivityRule,
        cor_sensitivity_area,
        CorSensitivityCriteria,
    )
    from apptax.taxonomie.models import Taxref
    from pypnnomenclature.models import TNomenclatures, BibNomenclaturesTypes

    sensitivity_nomenc_type = BibNomenclaturesTypes.query.filter_by(mnemonique="SENSIBILITE").one()
    department_diffusion = TNomenclatures.query.filter_by(
        id_type=sensitivity_nomenc_type.id_type, mnemonique="3"
    ).one()
    s = synthese_data[0]
    with db.session.begin_nested():
        rule = SensitivityRule(
            cd_nom=s.cd_nom,
            nomenclature_sensitivity=department_diffusion,
            sensitivity_duration=1000,
        )
        db.session.add(rule)
    with db.session.begin_nested():
        db.session.execute("REFRESH MATERIALIZED VIEW gn_sensitivity.t_sensitivity_rules_cd_ref")
    from sqlalchemy import update
    from geonature.core.gn_synthese.models import Synthese

    # force activation of trigger to recompute sensitivity
    with db.session.begin_nested():
        db.session.execute(
            update(Synthese).where(Synthese.id_synthese == s.id_synthese).values(cd_nom=s.cd_nom)
        )
    return rule


@pytest.mark.usefixtures("client_class", "temporary_transaction")
class TestBlurring:
    def test_get_one_synthese_record(
        self, blurring_config, blurred_users, synthese_data, sensitivity_rule
    ):
        set_logged_user_cookie(self.client, blurred_users["blurred_user"])
        nomenc_sensitivity = sensitivity_rule.nomenclature_sensitivity
        response = self.client.get(
            url_for("gn_synthese.get_one_synthese", id_synthese=synthese_data[0].id_synthese),
        )
        assert response.status_code == 200

        assert "properties" in response.json
        geoproperties = response.json["properties"]

        assert "nomenclature_sensitivity" in geoproperties
        sensitivity_nomenclature = geoproperties["nomenclature_sensitivity"]
        assert "mnemonique" in sensitivity_nomenclature
        sensitivity_mnemonic = sensitivity_nomenclature["mnemonique"]
        assert sensitivity_mnemonic == nomenc_sensitivity.mnemonique

        assert "areas" in geoproperties
        area_type_codes = {area["area_type"]["type_code"] for area in geoproperties["areas"]}
        from ref_geo.models import BibAreasTypes

        for la in current_app.config["DATA_BLURRING"]["AREA_TYPE_FOR_SENSITIVITY_LEVELS"]:
            if la["level"] == nomenc_sensitivity.mnemonique:
                sensitivity_area_type = BibAreasTypes.query.filter_by(type_code=la["area"]).one()
                break
        assert sensitivity_area_type.type_code in area_type_codes
        for type_code in area_type_codes:
            area_type = BibAreasTypes.query.filter_by(type_code=type_code).one()
            assert area_type.size_hierarchy >= sensitivity_area_type.size_hierarchy
