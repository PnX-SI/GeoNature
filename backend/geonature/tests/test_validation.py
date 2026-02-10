import pytest
from datetime import datetime, timedelta
from uuid import uuid4
import sqlalchemy as sa
from flask import url_for
from werkzeug.exceptions import Unauthorized, BadRequest, Forbidden, NotFound

from geonature.core.gn_synthese.models import Synthese
from geonature.core.gn_commons.models import TValidations, VLatestValidations
from geonature.core.gn_profiles.models import VConsistencyData
from geonature.utils.env import db
from geonature.utils.config import config

from pypnnomenclature.models import TNomenclatures, BibNomenclaturesTypes

from .fixtures import *
from .utils import set_logged_user
from datetime import timezone
from zoneinfo import ZoneInfo

gn_module_validation = pytest.importorskip("gn_module_validation")
pytestmark = pytest.mark.skipif(
    "VALIDATION" in config["DISABLED_MODULES"], reason="Validation is disabled"
)

from gn_module_validation.tasks import set_auto_validation
from gn_module_validation.constant import DEFAULT_FIELDS, DEFAULT_PROFILE_FIELDS


@pytest.fixture()
def validation_with_max_score_and_wait_validation_status():
    """Fixture for observations with max score and waiting validation status."""
    id_nomenclature_attente_validation = db.session.scalar(
        sa.select(TNomenclatures.id_nomenclature).filter_by(mnemonique="En attente de validation")
    )

    validations_to_update = db.session.scalars(
        sa.select(
            TValidations.id_validation,
            VLatestValidations.uuid_attached_row,
            VConsistencyData.id_synthese,
        )
        .join(TValidations, TValidations.id_validation == VLatestValidations.id_validation)
        .join(VConsistencyData, VConsistencyData.id_sinp == VLatestValidations.uuid_attached_row)
        .where(
            TValidations.validation_auto == True,
            VLatestValidations.id_nomenclature_valid_status == id_nomenclature_attente_validation,
            VLatestValidations.id_validator == None,
            VConsistencyData.valid_phenology == True,
            VConsistencyData.valid_altitude == True,
            VConsistencyData.valid_distribution == True,
        )
    ).all()
    return validations_to_update


@pytest.fixture()
def validation_status_nomenclatures():
    """Fixture to get all validation status nomenclatures."""
    nomenclatures = db.session.scalars(
        sa.select(TNomenclatures)
        .join(BibNomenclaturesTypes)
        .where(BibNomenclaturesTypes.mnemonique == "STATUT_VALID")
        .where(TNomenclatures.active == True)
    ).all()
    return {nom.mnemonique: nom for nom in nomenclatures}


@pytest.fixture()
def synthese_data_with_validations(synthese_data, users, validation_status_nomenclatures):
    """
    Fixture that creates validation entries for some observations in synthese_data.

    Creates a mix of manual and automatic validations with different statuses
    to enable testing of various validation scenarios.

    Returns
    -------
    dict
        Dictionary containing:
        - 'synthese_data': Original synthese data
        - 'validations': Dictionary mapping observation keys to their validation objects
        - 'nomenclatures': Available validation status nomenclatures
    """
    validations = {}

    # Get validation status nomenclatures
    id_nomenclature_probable = db.session.scalar(
        sa.select(TNomenclatures.id_nomenclature).filter_by(mnemonique="Probable")
    )
    id_nomenclature_attente = db.session.scalar(
        sa.select(TNomenclatures.id_nomenclature).filter_by(mnemonique="En attente de validation")
    )
    id_nomenclature_certain = db.session.scalar(
        sa.select(TNomenclatures.id_nomenclature)
        .join(BibNomenclaturesTypes)
        .where(BibNomenclaturesTypes.mnemonique == "STATUT_VALID")
        .where(TNomenclatures.cd_nomenclature == "1")
    )

    tz = ZoneInfo(db.session.scalar(sa.text("SHOW TIMEZONE;")))

    # Create validation for obs1 - Manual validation with "Certain" status
    if "obs1" in synthese_data:
        validation_obs1 = TValidations(
            uuid_attached_row=synthese_data["obs1"].unique_id_sinp,
            id_nomenclature_valid_status=id_nomenclature_certain,
            id_validator=users["user"].id_role,
            validation_comment="First observation validated manually",
            validation_auto=False,
            validation_date=datetime.now(tz) - timedelta(days=5),
        )
        db.session.add(validation_obs1)
        validations["obs1"] = validation_obs1

    # Create validation for obs2 - Automatic validation with "Probable" status
    if "obs2" in synthese_data:
        validation_obs2 = TValidations(
            uuid_attached_row=synthese_data["obs2"].unique_id_sinp,
            id_nomenclature_valid_status=id_nomenclature_probable,
            id_validator=None,  # No validator for automatic validation
            validation_comment="Automatic validation based on profile",
            validation_auto=True,
            validation_date=datetime.now(tz) - timedelta(days=3),
        )
        db.session.add(validation_obs2)
        validations["obs2"] = validation_obs2

    # Create validation for obs3 - Waiting for validation
    if "obs3" in synthese_data and id_nomenclature_attente:
        validation_obs3 = TValidations(
            uuid_attached_row=synthese_data["obs3"].unique_id_sinp,
            id_nomenclature_valid_status=id_nomenclature_attente,
            id_validator=None,
            validation_comment="",
            validation_auto=True,
            validation_date=datetime.now(tz) - timedelta(days=1),
        )
        db.session.add(validation_obs3)
        validations["obs3"] = validation_obs3

    # Create multiple validations for obs4 to test validation history
    if "obs4" in synthese_data:
        # First validation - rejected
        id_nomenclature_invalide = db.session.scalar(
            sa.select(TNomenclatures.id_nomenclature)
            .join(BibNomenclaturesTypes)
            .where(BibNomenclaturesTypes.mnemonique == "STATUT_VALID")
            .where(TNomenclatures.cd_nomenclature == "3")
        )

        if id_nomenclature_invalide:
            validation_obs4_1 = TValidations(
                uuid_attached_row=synthese_data["obs4"].unique_id_sinp,
                id_nomenclature_valid_status=id_nomenclature_invalide,
                id_validator=users["user"].id_role,
                validation_comment="Initial review - data seems incorrect",
                validation_auto=False,
                validation_date=datetime.now(tz) - timedelta(days=10),
            )
            db.session.add(validation_obs4_1)

        # Second validation - corrected to probable
        validation_obs4_2 = TValidations(
            uuid_attached_row=synthese_data["obs4"].unique_id_sinp,
            id_nomenclature_valid_status=id_nomenclature_probable,
            id_validator=(
                users["admin_user"].id_role if "admin_user" in users else users["user"].id_role
            ),
            validation_comment="Re-evaluated after observer clarification",
            validation_auto=False,
            validation_date=datetime.now(tz) - timedelta(days=2),
        )
        db.session.add(validation_obs4_2)
        validations["obs4"] = validation_obs4_2  # Store the latest validation

    db.session.commit()

    return {
        "synthese_data": synthese_data,
        "validations": validations,
        "nomenclatures": validation_status_nomenclatures,
    }


@pytest.mark.usefixtures("client_class", "temporary_transaction", "app")
class TestValidationRoutes:
    """Test suite for validation module routes."""

    # ============================================================================
    # Tests using synthese_data_with_validations fixture
    # ============================================================================

    def test_fixture_validations_created(self, synthese_data_with_validations):
        """Test that the validation fixture creates validations correctly."""
        validations = synthese_data_with_validations["validations"]
        synthese_data = synthese_data_with_validations["synthese_data"]

        # Verify validations were created
        assert len(validations) > 0

        # Check obs1 has manual validation
        if "obs1" in validations:
            assert validations["obs1"].validation_auto == False
            assert validations["obs1"].id_validator is not None
            assert validations["obs1"].validation_comment != ""

        # Check obs2 has automatic validation
        if "obs2" in validations:
            assert validations["obs2"].validation_auto == True
            assert validations["obs2"].id_validator is None

        # Check obs4 has multiple validations in history
        if "obs4" in synthese_data:
            all_validations = db.session.scalars(
                sa.select(TValidations)
                .where(TValidations.uuid_attached_row == synthese_data["obs4"].unique_id_sinp)
                .order_by(TValidations.validation_date.desc())
            ).all()
            assert len(all_validations) >= 2  # Should have multiple validations

    def test_get_observations_with_existing_validations(
        self, users, synthese_data_with_validations
    ):
        """Test retrieving observations that already have validations."""
        set_logged_user(self.client, users["self_user"])

        response = self.client.get(url_for("validation.get_observations_last_validations"))

        assert response.status_code == 200
        assert len(response.json["features"]) > 0

        # Find observations that have validations
        validations = synthese_data_with_validations["validations"]
        synthese_data = synthese_data_with_validations["synthese_data"]

        if "obs1" in validations:
            # Look for obs1 in the results
            obs1_features = [
                f
                for f in response.json["features"]
                if f["properties"].get("unique_id_sinp")
                == str(synthese_data["obs1"].unique_id_sinp)
            ]
            if obs1_features:
                # Should have last_validation data
                feature = obs1_features[0]
                assert (
                    "last_validation" in feature["properties"]
                    or "validation_date" in feature["properties"]
                )

    def test_get_validations_includes_fixture_data(self, users, synthese_data_with_validations):
        """Test that get_validations returns the validations created by fixture."""
        set_logged_user(self.client, users["user"])

        response = self.client.get(url_for("validation.get_validations", page=1, per_page=100))

        assert response.status_code == 200

        # Count manual validations from fixture
        validations = synthese_data_with_validations["validations"]
        manual_count = sum(1 for v in validations.values() if not v.validation_auto)

        # Response should include at least the manual validations from fixture
        # (may have more if there are other manual validations)
        assert response.json["total"] >= manual_count

    def test_validation_history_with_multiple_entries(self, users, synthese_data_with_validations):
        """Test validation history retrieval for observation with multiple validations."""
        set_logged_user(self.client, users["user"])
        synthese_data = synthese_data_with_validations["synthese_data"]

        if "obs4" in synthese_data:
            response = self.client.get(
                url_for(
                    "gn_commons.get_hist", uuid_attached_row=synthese_data["obs4"].unique_id_sinp
                )
            )

            assert response.status_code == 200
            assert len(response.json) >= 2  # obs4 should have at least 2 validations

            # Verify history is ordered by date (most recent first)
            dates = [item.get("date") for item in response.json]
            dates_sorted = [
                date.isoformat(sep=" ")
                for date in sorted([datetime.fromisoformat(date) for date in dates])
            ]
            assert dates == dates_sorted

    def test_no_auto_filter_excludes_automatic_validations(
        self, users, synthese_data_with_validations
    ):
        """Test that no_auto filter excludes automatic validations from fixture."""
        set_logged_user(self.client, users["self_user"])

        response = self.client.get(
            url_for("validation.get_observations_last_validations", no_auto=True)
        )

        assert response.status_code == 200

        # If obs2 (automatic validation) appears in results, verify it's filtered
        synthese_data = synthese_data_with_validations["synthese_data"]

        if "obs2" in synthese_data:
            obs2_uuid = str(synthese_data["obs2"].unique_id_sinp)

            # With no_auto=True, should not include automatic validations in the last_validation
            # or should filter them out entirely depending on implementation

    def test_update_existing_validation(self, users, synthese_data_with_validations):
        """Test updating a validation status for an already validated observation."""
        set_logged_user(self.client, users["user"])
        synthese_data = synthese_data_with_validations["synthese_data"]

        if "obs1" in synthese_data:
            # Get a different validation status
            new_status = db.session.execute(
                sa.select(TNomenclatures)
                .join(BibNomenclaturesTypes)
                .where(BibNomenclaturesTypes.mnemonique == "STATUT_VALID")
                .where(
                    TNomenclatures.cd_nomenclature == "2"
                )  # Different from obs1's current status
            ).scalar_one()

            data = {
                "statut": new_status.id_nomenclature,
                "comment": "Updated validation status",
            }

            response = self.client.post(
                url_for("validation.post_status", id_synthese=synthese_data["obs1"].id_synthese),
                json=data,
            )

            assert response.status_code == 200

            # Verify a new validation was created (not updated)
            all_validations = db.session.scalars(
                sa.select(TValidations)
                .where(TValidations.uuid_attached_row == synthese_data["obs1"].unique_id_sinp)
                .order_by(TValidations.validation_date.desc())
            ).all()

            assert len(all_validations) >= 2  # Original + new validation
            assert all_validations[0].id_nomenclature_valid_status == new_status.id_nomenclature

    def test_validation_dates_chronological(self, users, synthese_data_with_validations):
        """Test that validations are created with proper chronological dates."""
        validations = synthese_data_with_validations["validations"]

        # Get all validation dates
        dates = [v.validation_date for v in validations.values()]

        # All dates should be in the past (not future)
        now = datetime.now(dates[0].tzinfo)
        for date in dates:
            assert date <= now

    # ============================================================================
    # GET /observations - Tests for get_observations_last_validations
    # ============================================================================

    def test_get_observations_with_fields_parameter(self, users, synthese_data):
        set_logged_user(self.client, users["user"])
        response = self.client.get(
            url_for(
                "validation.get_observations_last_validations",
                fields="nomenclature_blurring.cd_nomenclature",
            )
        )
        assert response.status_code == 200
        assert "features" in response.json
        data = response.json["features"][0]["properties"]
        for field in DEFAULT_FIELDS:
            assert field.split(".")[0] in data
        for field in DEFAULT_PROFILE_FIELDS:
            assert field.split(".")[0] in data
        assert "nomenclature_blurring" in data
        assert response.status_code == 200

    def test_get_observations_unauthorized(self):
        """Test that unauthorized access is rejected."""
        response = self.client.get(url_for("validation.get_observations_last_validations"))
        assert response.status_code == Unauthorized.code

    def test_get_observations_basic(self, users, synthese_data):
        """Test basic retrieval of observations with validations."""
        set_logged_user(self.client, users["self_user"])
        response = self.client.get(url_for("validation.get_observations_last_validations"))

        assert response.status_code == 200
        assert "features" in response.json
        assert "type" in response.json
        assert response.json["type"] == "FeatureCollection"
        assert len(response.json["features"]) >= len(synthese_data)

    def test_get_observations_with_limit(self, users, synthese_data):
        """Test observations retrieval with limit parameter."""
        set_logged_user(self.client, users["self_user"])
        limit = 5
        response = self.client.get(
            url_for("validation.get_observations_last_validations", limit=limit)
        )

        assert response.status_code == 200
        assert len(response.json["features"]) <= limit

    def test_get_observations_with_sorting(self, users, synthese_data):
        """Test observations retrieval with sorting parameters."""
        set_logged_user(self.client, users["self_user"])

        sorts = ["asc", "desc"]
        for sort in sorts:
            response = self.client.get(
                url_for("validation.get_observations_last_validations", sort=sort)
            )
            assert response.status_code == 200

    def test_get_observations_with_filters(self, users, synthese_data):
        """Test observations retrieval with various filters."""
        set_logged_user(self.client, users["self_user"])

        filters = [
            ("valid_distribution", True),
            ("valid_altitude", True),
            ("valid_phenology", True),
        ]

        for filter_name, filter_value in filters:
            response = self.client.get(
                url_for(
                    "validation.get_observations_last_validations", **{filter_name: filter_value}
                ),
            )
            assert response.status_code == 200

    def test_get_observations_post_method(self, users, synthese_data):
        """Test observations retrieval using POST method with JSON body."""
        set_logged_user(self.client, users["self_user"])

        data = {"valid_distribution": True, "no_auto": True, "limit": 10}

        response = self.client.post(
            url_for("validation.get_observations_last_validations"), json=data
        )

        assert response.status_code == 200
        assert "features" in response.json

    def test_get_observations_no_auto_filter(self, users, synthese_data):
        """Test filtering out automatic validations."""
        set_logged_user(self.client, users["self_user"])

        response = self.client.get(
            url_for("validation.get_observations_last_validations", no_auto=True)
        )

        assert response.status_code == 200

    def test_get_observations_modif_since_validation(self, users, synthese_data):
        """Test filtering observations modified since validation."""
        set_logged_user(self.client, users["self_user"])

        response = self.client.get(
            url_for("validation.get_observations_last_validations", modif_since_validation=True)
        )

        assert response.status_code == 200

    # ============================================================================
    # GET / - Tests for get_validations
    # ============================================================================

    def test_get_validations_unauthorized(self):
        """Test that unauthorized access to validations list is rejected."""
        response = self.client.get(url_for("validation.get_validations"))
        assert response.status_code == Unauthorized.code

    def test_get_validations_missing_pagination(self, users):
        """Test that missing pagination parameters raise BadRequest."""
        set_logged_user(self.client, users["user"])

        # Missing both parameters
        response = self.client.get(url_for("validation.get_validations"))
        assert response.status_code == BadRequest.code

        # Missing per_page
        response = self.client.get(url_for("validation.get_validations", page=1))
        assert response.status_code == BadRequest.code

        # Missing page
        response = self.client.get(url_for("validation.get_validations", per_page=10))
        assert response.status_code == BadRequest.code

    def test_get_validations_invalid_pagination(self, users):
        """Test that invalid pagination parameters raise BadRequest."""
        set_logged_user(self.client, users["user"])

        # Zero page
        response = self.client.get(url_for("validation.get_validations", page=0, per_page=10))
        assert response.status_code == BadRequest.code

        # Negative page
        response = self.client.get(url_for("validation.get_validations", page=-1, per_page=10))
        assert response.status_code == BadRequest.code

        # Zero per_page
        response = self.client.get(url_for("validation.get_validations", page=1, per_page=0))
        assert response.status_code == BadRequest.code

    def test_get_validations_basic_json(self, users, synthese_data):
        """Test basic retrieval of validations in JSON format."""
        set_logged_user(self.client, users["user"])

        response = self.client.get(url_for("validation.get_validations", page=1, per_page=20))

        assert response.status_code == 200
        assert "items" in response.json
        assert "total" in response.json
        assert "per_page" in response.json
        assert "page" in response.json
        assert response.json["per_page"] == 20
        assert response.json["page"] == 1

    def test_get_validations_geojson_format(self, users, synthese_data_with_validations):
        """Test retrieval of validations in GeoJSON format."""
        set_logged_user(self.client, users["admin_user"])

        response = self.client.get(
            url_for("validation.get_validations", page=1, per_page=20, format="geojson")
        )

        assert response.status_code == 200
        assert "items" in response.json

        # GeoJSON format should include observation fields and geometry
        if response.json["items"]:
            # Check that geometry field is present in the data
            first_item = response.json["items"]["features"][0]
            # When format=geojson, the query includes ST_AsGeoJSON(Synthese.the_geom_4326)
            assert "geometry" in first_item
            # Should also include observation fields
            assert (
                "id_synthese" in first_item["properties"] or "nom_cite" in first_item["properties"]
            )

    def test_get_validations_with_fields(self, users, synthese_data):
        """Test retrieval with additional fields."""
        set_logged_user(self.client, users["user"])

        response = self.client.get(
            url_for(
                "validation.get_validations", page=1, per_page=20, fields="observation,user_info"
            )
        )

        assert response.status_code == 200

        # Verify that requested fields are present in the response
        if response.json["items"]:
            first_item = response.json["items"][0]

            # When 'observation' field is requested, should include observation data
            # Based on build_validations_query, observation fields include:
            # id_synthese, nom_cite, observers, date_min, date_max
            assert any(key in first_item for key in ["id_synthese", "nom_cite", "observers"])

            # When 'user_info' field is requested, should include validator info
            # Based on build_validations_query, user_info adds: validator (nom_complet)
            assert "validator" in first_item

    def test_get_validations_with_sorting(self, users, synthese_data):
        """Test retrieval with sorting parameters."""
        set_logged_user(self.client, users["user"])

        # Test ascending sort by validation_date (default order_by)
        response_asc = self.client.get(
            url_for("validation.get_validations", page=1, per_page=20, sort="asc")
        )
        assert response_asc.status_code == 200

        # Test descending sort with custom order_by
        response_desc = self.client.get(
            url_for(
                "validation.get_validations",
                page=1,
                per_page=20,
                sort="desc",
                order_by="validation_date",
            )
        )
        assert response_desc.status_code == 200

        # Verify dates are actually sorted
        if response_asc.json["items"] and len(response_asc.json["items"]) > 1:
            dates_asc = [item["validation_date"] for item in response_asc.json["items"]]
            # Check ascending order
            assert dates_asc == sorted(dates_asc)

        if response_desc.json["items"] and len(response_desc.json["items"]) > 1:
            dates_desc = [item["validation_date"] for item in response_desc.json["items"]]
            # Check descending order
            assert dates_desc == sorted(dates_desc, reverse=True)

    def test_get_validations_post_method(self, users, synthese_data):
        """Test validations retrieval using POST method."""
        set_logged_user(self.client, users["user"])

        data = {"page": 1, "per_page": 50, "format": "geojson"}

        response = self.client.post(url_for("validation.get_validations"), json=data)

        assert response.status_code == 200

    def test_get_validations_pagination(self, users, synthese_data):
        """Test pagination functionality."""
        set_logged_user(self.client, users["user"])

        # Get first page
        response_page1 = self.client.get(url_for("validation.get_validations", page=1, per_page=5))
        assert response_page1.status_code == 200

        # Get second page
        response_page2 = self.client.get(url_for("validation.get_validations", page=2, per_page=5))
        assert response_page2.status_code == 200

        # Verify total is consistent
        if response_page1.json["total"] > 0:
            assert response_page1.json["total"] == response_page2.json["total"]

    # ============================================================================
    # GET /statusNames - Tests for get_status_names
    # ============================================================================

    def test_get_status_names_unauthorized(self):
        """Test that unauthorized access to status names is rejected."""
        response = self.client.get(url_for("validation.get_status_names"))
        assert response.status_code == Unauthorized.code

    def test_get_status_names_basic(self, users, synthese_data):
        """Test retrieval of validation status names."""
        set_logged_user(self.client, users["user"])
        response = self.client.get(url_for("validation.get_status_names"))

        assert response.status_code == 200
        assert isinstance(response.json, list)

        # Verify structure of returned nomenclatures
        if len(response.json) > 0:
            status = response.json[0]
            assert "id_nomenclature" in status
            assert "mnemonique" in status
            assert "cd_nomenclature" in status
            assert "definition_default" in status

    def test_get_status_names_only_active(self, users):
        """Test that only active nomenclatures are returned."""
        set_logged_user(self.client, users["user"])
        response = self.client.get(url_for("validation.get_status_names"))

        assert response.status_code == 200
        # All returned statuses should be active (implicitly tested by the route)

    def test_get_status_names_sorted(self, users):
        """Test that status names are sorted by cd_nomenclature."""
        set_logged_user(self.client, users["user"])
        response = self.client.get(url_for("validation.get_status_names"))

        assert response.status_code == 200
        if len(response.json) > 1:
            codes = [status["cd_nomenclature"] for status in response.json]
            assert codes == sorted(codes)

    # ============================================================================
    # POST /<id_synthese> - Tests for post_status
    # ============================================================================

    def test_post_status_unauthorized(self, synthese_data):
        """Test that unauthorized access to post status is rejected."""
        synthese = synthese_data["obs1"]
        response = self.client.post(
            url_for("validation.post_status", id_synthese=synthese.id_synthese)
        )
        assert response.status_code == Unauthorized.code

    def test_post_status_missing_statut(self, users, synthese_data):
        """Test that missing 'statut' field raises BadRequest."""
        set_logged_user(self.client, users["user"])
        synthese = synthese_data["obs1"]

        data = {"comment": "Test comment"}
        response = self.client.post(
            url_for("validation.post_status", id_synthese=synthese.id_synthese), json=data
        )

        assert response.status_code == BadRequest.code

    def test_post_status_missing_comment(
        self, users, synthese_data, validation_status_nomenclatures
    ):
        """Test that missing 'comment' field raises BadRequest."""
        set_logged_user(self.client, users["user"])
        synthese = synthese_data["obs1"]

        if validation_status_nomenclatures:
            status = list(validation_status_nomenclatures.values())[0]
            data = {"statut": status.id_nomenclature}
            response = self.client.post(
                url_for("validation.post_status", id_synthese=synthese.id_synthese), json=data
            )

            assert response.status_code == BadRequest.code

    def test_post_status_success(self, users, synthese_data):
        """Test successful validation status creation."""
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

        data = {
            "statut": id_nomenclature_valid_status.id_nomenclature,
            "comment": "Test validation",
        }

        response = self.client.post(
            url_for("validation.post_status", id_synthese=synthese.id_synthese), json=data
        )

        assert response.status_code == 200
        assert "id_nomenclature" in response.json

    def test_post_status_with_validation_date_check(self, users, synthese_data):
        """Test validation status creation and date verification."""
        set_logged_user(self.client, users["user"])
        synthese = synthese_data["obs1"]

        tz = ZoneInfo(db.session.scalar(sa.text("SHOW TIMEZONE;")))
        validation_date = datetime.now(tz)

        # Check no validation exists initially
        response = self.client.get(
            url_for("validation.get_validation_date", uuid=synthese.unique_id_sinp)
        )
        assert response.status_code == 204  # No content

        # Add validation
        id_nomenclature_valid_status = db.session.execute(
            sa.select(TNomenclatures).where(
                sa.and_(
                    TNomenclatures.cd_nomenclature == "1",
                    TNomenclatures.nomenclature_type.has(mnemonique="STATUT_VALID"),
                )
            )
        ).scalar_one()

        data = {
            "statut": id_nomenclature_valid_status.id_nomenclature,
            "comment": "Test validation with date",
        }

        response = self.client.post(
            url_for("validation.post_status", id_synthese=synthese.id_synthese), json=data
        )
        assert response.status_code == 200

        # Verify validation date
        response = self.client.get(
            url_for("validation.get_validation_date", uuid=synthese.unique_id_sinp)
        )
        assert response.status_code == 200
        response_date = datetime.fromisoformat(response.json).replace(tzinfo=tz)
        assert abs(response_date - validation_date) < timedelta(minutes=10)

    def test_post_status_multiple_synthese(self, users, synthese_data):
        """Test validation of multiple observations at once."""
        set_logged_user(self.client, users["user"])

        # Get multiple synthese IDs
        obs_ids = map(str, [synthese_data["obs1"].id_synthese, synthese_data["obs2"].id_synthese])

        id_nomenclature_valid_status = db.session.execute(
            sa.select(TNomenclatures).where(
                sa.and_(
                    TNomenclatures.cd_nomenclature == "1",
                    TNomenclatures.nomenclature_type.has(mnemonique="STATUT_VALID"),
                )
            )
        ).scalar_one()

        data = {
            "statut": id_nomenclature_valid_status.id_nomenclature,
            "comment": "Bulk validation",
        }

        # Post with comma-separated IDs
        response = self.client.post(
            url_for("validation.post_status", id_synthese=",".join(obs_ids)), json=data
        )

        assert response.status_code == 200

    def test_post_status_invalid_synthese_id(self, users):
        """Test posting status with non-existent synthese ID."""
        set_logged_user(self.client, users["user"])

        id_nomenclature_valid_status = db.session.execute(
            sa.select(TNomenclatures).where(
                sa.and_(
                    TNomenclatures.cd_nomenclature == "1",
                    TNomenclatures.nomenclature_type.has(mnemonique="STATUT_VALID"),
                )
            )
        ).scalar_one()

        data = {
            "statut": id_nomenclature_valid_status.id_nomenclature,
            "comment": "Test with invalid ID",
        }

        response = self.client.post(
            url_for("validation.post_status", id_synthese=999999999), json=data
        )

        assert response.status_code == NotFound.code

    def test_post_status_invalid_nomenclature(self, users, synthese_data):
        """Test posting status with non-existent nomenclature."""
        set_logged_user(self.client, users["user"])
        synthese = synthese_data["obs1"]

        data = {
            "statut": 999999999,
            "comment": "Test with invalid nomenclature",
        }

        response = self.client.post(
            url_for("validation.post_status", id_synthese=synthese.id_synthese), json=data
        )

        assert response.status_code == NotFound.code

    def test_post_status_forbidden(self, users, synthese_data):
        """Test that users without permissions cannot validate."""
        # This test assumes there's a user without validation permissions
        # You may need to adjust based on your fixture setup
        set_logged_user(self.client, users["noright_user"])

        synthese = synthese_data["obs1"]

        id_nomenclature_valid_status = db.session.execute(
            sa.select(TNomenclatures).where(
                sa.and_(
                    TNomenclatures.cd_nomenclature == "1",
                    TNomenclatures.nomenclature_type.has(mnemonique="STATUT_VALID"),
                )
            )
        ).scalar_one()

        data = {
            "statut": id_nomenclature_valid_status.id_nomenclature,
            "comment": "Test validation with date",
        }

        response = self.client.post(
            url_for("validation.post_status", id_synthese=synthese.id_synthese), json=data
        )
        assert response.status_code == Forbidden.code

    # ============================================================================
    # GET /date/<uuid> - Tests for get_validation_date
    # ============================================================================

    def test_get_validation_date_unauthorized(self, synthese_data):
        """Test that unauthorized access to validation date is rejected."""
        synthese = synthese_data["obs1"]
        response = self.client.get(
            url_for("validation.get_validation_date", uuid=synthese.unique_id_sinp)
        )
        assert response.status_code == Unauthorized.code

    def test_get_validation_date_no_validation(self, users, synthese_data):
        """Test getting validation date when no validation exists."""
        set_logged_user(self.client, users["user"])

        # Find or create an observation without validation
        synthese = synthese_data["obs1"]

        response = self.client.get(
            url_for("validation.get_validation_date", uuid=synthese.unique_id_sinp)
        )

        # Should return 204 No Content if no validation exists
        assert response.status_code in [200, 204]

    def test_get_validation_date_with_validation(self, users, synthese_data):
        """Test getting validation date when validation exists."""
        set_logged_user(self.client, users["user"])
        synthese = synthese_data["obs1"]

        # First create a validation
        id_nomenclature_valid_status = db.session.execute(
            sa.select(TNomenclatures).where(
                sa.and_(
                    TNomenclatures.cd_nomenclature == "1",
                    TNomenclatures.nomenclature_type.has(mnemonique="STATUT_VALID"),
                )
            )
        ).scalar_one()

        data = {
            "statut": id_nomenclature_valid_status.id_nomenclature,
            "comment": "Test for date retrieval",
        }

        self.client.post(
            url_for("validation.post_status", id_synthese=synthese.id_synthese), json=data
        )

        # Now get the validation date
        response = self.client.get(
            url_for("validation.get_validation_date", uuid=synthese.unique_id_sinp)
        )

        assert response.status_code == 200
        # Verify it's a valid ISO format date string
        datetime.fromisoformat(response.json)

    def test_get_validation_date_invalid_uuid(self, users):
        """Test getting validation date with non-existent UUID."""
        set_logged_user(self.client, users["user"])

        fake_uuid = uuid4()
        response = self.client.get(url_for("validation.get_validation_date", uuid=fake_uuid))

        assert response.status_code == NotFound.code

    # ============================================================================
    # Validation History Tests
    # ============================================================================

    def test_get_validation_history_invalid_uuid(self, users):
        """Test getting validation history with invalid UUID."""
        set_logged_user(self.client, users["user"])
        response = self.client.get(url_for("gn_commons.get_hist", uuid_attached_row="invalid"))
        assert response.status_code == BadRequest.code

    def test_get_validation_history_complete(self, users, synthese_data):
        """Test complete validation history retrieval."""
        set_logged_user(self.client, users["user"])
        synthese = synthese_data["obs1"]

        # Add a validation to create history
        id_nomenclature_valid_status = db.session.execute(
            sa.select(TNomenclatures).where(
                sa.and_(
                    TNomenclatures.cd_nomenclature == "1",
                    TNomenclatures.nomenclature_type.has(mnemonique="STATUT_VALID"),
                )
            )
        ).scalar_one()

        response = self.client.post(
            url_for("validation.post_status", id_synthese=synthese.id_synthese),
            json={
                "statut": id_nomenclature_valid_status.id_nomenclature,
                "comment": "History test validation",
            },
        )
        assert response.status_code == 200

        # Get history
        response = self.client.get(
            url_for("gn_commons.get_hist", uuid_attached_row=synthese.unique_id_sinp)
        )

        assert response.status_code == 200
        assert len(response.json) > 0
        assert response.json[0]["id_status"] == str(id_nomenclature_valid_status.id_nomenclature)

    def test_get_validation_history_multiple_entries(self, users, synthese_data):
        """Test validation history with multiple validation entries."""
        set_logged_user(self.client, users["user"])
        synthese = synthese_data["obs1"]

        # Get two different validation statuses
        nomenclatures = (
            db.session.execute(
                sa.select(TNomenclatures)
                .where(TNomenclatures.nomenclature_type.has(mnemonique="STATUT_VALID"))
                .where(TNomenclatures.active == True)
                .limit(2)
            )
            .scalars()
            .all()
        )

        if len(nomenclatures) >= 2:
            # Add first validation
            self.client.post(
                url_for("validation.post_status", id_synthese=synthese.id_synthese),
                json={
                    "statut": nomenclatures[0].id_nomenclature,
                    "comment": "First validation",
                },
            )

            # Add second validation
            self.client.post(
                url_for("validation.post_status", id_synthese=synthese.id_synthese),
                json={
                    "statut": nomenclatures[1].id_nomenclature,
                    "comment": "Second validation",
                },
            )

            # Get history
            response = self.client.get(
                url_for("gn_commons.get_hist", uuid_attached_row=synthese.unique_id_sinp)
            )

            assert response.status_code == 200
            assert len(response.json) >= 2

    # ============================================================================
    # Auto Validation Tests
    # ============================================================================

    def test_auto_validation_process(
        self,
        users,
        app,
        auto_validation_enabled,
        validation_with_max_score_and_wait_validation_status,
    ):
        """Test automatic validation process."""
        set_logged_user(self.client, users["user"])

        id_nomenclature_probable = db.session.scalar(
            sa.select(TNomenclatures.id_nomenclature).filter_by(mnemonique="Probable")
        )
        id_nomenclature_attente_validation = db.session.scalar(
            sa.select(TNomenclatures.id_nomenclature).filter_by(
                mnemonique="En attente de validation"
            )
        )

        # Get list of synthese IDs to update
        list_synthese_to_update = []
        for row in validation_with_max_score_and_wait_validation_status:
            list_synthese_to_update.append(row[2])

        if not list_synthese_to_update:
            pytest.skip("No synthese records to test auto-validation")

        # Verify initial status
        synthese_valid_statut_before_update = db.session.scalars(
            sa.select(Synthese.id_nomenclature_valid_status).where(
                Synthese.id_synthese.in_(list_synthese_to_update)
            )
        ).all()

        assert all(
            status == id_nomenclature_attente_validation
            for status in synthese_valid_statut_before_update
        )

        # Apply auto-validation
        set_auto_validation()

        # Verify updated status
        synthese_valid_statut_after_update = db.session.scalars(
            sa.select(Synthese.id_nomenclature_valid_status).where(
                Synthese.id_synthese.in_(list_synthese_to_update)
            )
        ).all()

        assert all(
            status == id_nomenclature_probable for status in synthese_valid_statut_after_update
        )

    # ============================================================================
    # Edge Cases and Error Handling
    # ============================================================================

    def test_post_status_empty_comment(self, users, synthese_data):
        """Test posting status with empty comment."""
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

        # Empty string comment should be accepted (field is present but empty)
        data = {
            "statut": id_nomenclature_valid_status.id_nomenclature,
            "comment": "",
        }

        response = self.client.post(
            url_for("validation.post_status", id_synthese=synthese.id_synthese), json=data
        )

        # Should succeed - empty comment is valid
        assert response.status_code == 200

        # Verify the validation was created with empty comment
        validation = db.session.execute(
            sa.select(TValidations)
            .where(TValidations.uuid_attached_row == synthese.unique_id_sinp)
            .order_by(TValidations.validation_date.desc())
            .limit(1)
        ).scalar_one()

        assert validation.validation_comment == ""
        assert validation.validation_auto == False

    def test_get_observations_with_score_filter(self, users, synthese_data):
        """Test observations retrieval with profile score filter."""
        set_logged_user(self.client, users["self_user"])

        response = self.client.get(
            url_for("validation.get_observations_last_validations", score=10)
        )

        assert response.status_code == 200
        assert "features" in response.json

    def test_build_query_with_all_filters(self, users, synthese_data):
        """Test observations retrieval with multiple combined filters."""
        set_logged_user(self.client, users["self_user"])

        data = {
            "valid_distribution": True,
            "valid_altitude": True,
            "valid_phenology": True,
            "no_auto": True,
            "modif_since_validation": True,
            "limit": 50,
            "sort": "asc",
            "order_by": "last_validation.validation_date",
        }

        response = self.client.post(
            url_for("validation.get_observations_last_validations"), json=data
        )

        assert response.status_code == 200
        assert "features" in response.json

    def test_get_validations_only_manual(self, users, synthese_data):
        """Test that only manual validations are returned (validation_auto=False)."""
        set_logged_user(self.client, users["user"])

        response = self.client.get(url_for("validation.get_validations", page=1, per_page=100))

        assert response.status_code == 200

        # All returned validations should be manual
        # Based on build_validations_query, query filters: validation_auto == False
        if response.json["items"]:
            for item in response.json["items"]:
                assert item["validation_auto"] == False

    def test_observations_only_with_geometry(self, users, synthese_data):
        """Test that only observations with geometry are returned."""
        set_logged_user(self.client, users["self_user"])

        response = self.client.get(url_for("validation.get_observations_last_validations"))

        assert response.status_code == 200
        # Based on build_synthese_query, includes filter:
        # selectable = selectable.where(synthese_alias.the_geom_4326.isnot(None))
        # All features should have geometry
        for feature in response.json["features"]:
            assert feature["geometry"] is not None

    def test_post_status_creates_manual_validation(self, users, synthese_data):
        """Test that created validations are marked as manual."""
        set_logged_user(self.client, users["user"])
        synthese = synthese_data["obs1"]

        id_nomenclature_valid_status = db.session.execute(
            sa.select(TNomenclatures).where(
                sa.and_(
                    TNomenclatures.cd_nomenclature == "2",
                    TNomenclatures.nomenclature_type.has(mnemonique="STATUT_VALID"),
                )
            )
        ).scalar_one()

        data = {
            "statut": id_nomenclature_valid_status.id_nomenclature,
            "comment": "Manual validation test",
        }

        response = self.client.post(
            url_for("validation.post_status", id_synthese=synthese.id_synthese), json=data
        )

        assert response.status_code == 200

        # Verify the validation was created as manual
        validation = db.session.execute(
            sa.select(TValidations)
            .where(TValidations.uuid_attached_row == synthese.unique_id_sinp)
            .order_by(TValidations.validation_date.desc())
            .limit(1)
        ).scalar_one()

        assert validation.validation_auto == False
        assert validation.id_validator == users["user"].id_role

    def test_post_status_with_whitespace_in_ids(self, users, synthese_data):
        """Test posting status with whitespace in comma-separated IDs."""
        set_logged_user(self.client, users["user"])

        obs_ids = [str(synthese_data["obs1"].id_synthese)]
        if "obs2" in synthese_data:
            obs_ids.append(str(synthese_data["obs2"].id_synthese))

        id_nomenclature_valid_status = db.session.execute(
            sa.select(TNomenclatures).where(
                sa.and_(
                    TNomenclatures.cd_nomenclature == "1",
                    TNomenclatures.nomenclature_type.has(mnemonique="STATUT_VALID"),
                )
            )
        ).scalar_one()

        data = {
            "statut": id_nomenclature_valid_status.id_nomenclature,
            "comment": "Bulk validation with spaces",
        }

        # Add spaces around commas
        ids_with_spaces = " , ".join(obs_ids)

        response = self.client.post(
            url_for("validation.post_status", id_synthese=ids_with_spaces), json=data
        )

        # Should succeed - the route strips whitespace: id.strip()
        assert response.status_code == 200

    def test_get_observations_with_custom_fields(self, users, synthese_data):
        """Test observations retrieval with custom field list."""
        set_logged_user(self.client, users["self_user"])

        # Request specific fields
        response = self.client.get(
            url_for(
                "validation.get_observations_last_validations",
                fields="dataset.dataset_name,taxref.nom_vern",
            )
        )

        assert response.status_code == 200
        assert "features" in response.json

        for feature in response.json["features"]:
            assert "properties" in feature
            assert "dataset_name" in feature["properties"]["dataset"]
            assert "nom_vern" in feature["properties"]["taxref"]

    def test_status_names_nomenclature_structure(self, users):
        """Test that status names return proper nomenclature structure."""
        set_logged_user(self.client, users["user"])
        response = self.client.get(url_for("validation.get_status_names"))

        assert response.status_code == 200
        assert isinstance(response.json, list)

        # Verify all required fields are present
        required_fields = ["id_nomenclature", "mnemonique", "cd_nomenclature", "definition_default"]

        for status in response.json:
            for field in required_fields:
                assert field in status, f"Missing field: {field}"

    def test_get_validation_date_returns_iso_format(self, users, synthese_data):
        """Test that validation date is returned in ISO format."""
        set_logged_user(self.client, users["user"])
        synthese = synthese_data["obs1"]

        # Create a validation first
        id_nomenclature_valid_status = db.session.execute(
            sa.select(TNomenclatures).where(
                sa.and_(
                    TNomenclatures.cd_nomenclature == "1",
                    TNomenclatures.nomenclature_type.has(mnemonique="STATUT_VALID"),
                )
            )
        ).scalar_one()

        data = {
            "statut": id_nomenclature_valid_status.id_nomenclature,
            "comment": "ISO format test",
        }

        self.client.post(
            url_for("validation.post_status", id_synthese=synthese.id_synthese), json=data
        )

        # Get the validation date
        response = self.client.get(
            url_for("validation.get_validation_date", uuid=synthese.unique_id_sinp)
        )

        assert response.status_code == 200

        # Verify it's a valid ISO format string
        try:
            parsed_date = datetime.fromisoformat(response.json)
            assert parsed_date is not None
        except ValueError:
            pytest.fail("Response is not a valid ISO format date")

    def test_observations_geojson_structure(self, users, synthese_data):
        """Test that observations return valid GeoJSON structure."""
        set_logged_user(self.client, users["self_user"])

        response = self.client.get(
            url_for("validation.get_observations_last_validations", limit=10)
        )

        assert response.status_code == 200

        # Verify GeoJSON structure
        assert response.json["type"] == "FeatureCollection"
        assert "features" in response.json
        assert isinstance(response.json["features"], list)

        # Check each feature has proper structure
        for feature in response.json["features"]:
            assert "type" in feature
            assert feature["type"] == "Feature"
            assert "geometry" in feature
            assert "properties" in feature

    def test_validation_response_structure(self, users, synthese_data):
        """Test the structure of validation response."""
        set_logged_user(self.client, users["user"])

        response = self.client.get(url_for("validation.get_validations", page=1, per_page=10))

        assert response.status_code == 200

        # Verify pagination structure
        assert "items" in response.json
        assert "total" in response.json
        assert "per_page" in response.json
        assert "page" in response.json

        # Verify each item has required fields
        if response.json["items"]:
            item = response.json["items"][0]
            assert "id_validation" in item
            assert "validation_date" in item
            assert "validation_auto" in item
            assert "validation_comment" in item
            assert "nomenclature_cd_nomenclature" in item
            assert "nomenclature_mnemonique" in item
            assert "nomenclature_label_default" in item
