import datetime
import csv
import uuid
from io import StringIO
from unittest.mock import MagicMock

from geonature.core.gn_commons.models.additional_fields import TAdditionalFields
from geonature.core.gn_commons.models.base import TModules, BibWidgets
from geonature.core.gn_permissions.models import PermObject
import pytest
from flask import url_for, Flask
from kombu.asynchronous.http import Response

from geonature.core.gn_meta.models import (
    CorAcquisitionFrameworkActor,
    CorDatasetActor,
    TAcquisitionFramework,
    TDatasets,
)
from geonature.core.gn_meta.repositories import (
    cruved_af_filter,
    cruved_ds_filter,
)
from geonature.core.gn_meta.routes import get_af_from_id
from geonature.core.gn_meta.schemas import AcquisitionFrameworkSchema, DatasetSchema
from geonature.core.gn_synthese.models import Synthese
from geonature.core.schemas import AdditionalDataWithNomenclatureField
from geonature.utils.env import db
from pypnusershub.schemas import UserSafeSchema
from ref_geo.models import BibAreasTypes, LAreas
from sqlalchemy import func, select, exists
from sqlalchemy.sql.selectable import Select
from werkzeug.datastructures import Headers, MultiDict
from werkzeug.exceptions import (
    BadRequest,
    Conflict,
    Forbidden,
    MethodNotAllowed,
    NotFound,
    Unauthorized,
    UnsupportedMediaType,
)

from .utils import logged_user_headers, set_logged_user
from ..utils.errors import GeoNatureError


@pytest.fixture(scope="function")
def commune_without_obs():
    return db.session.scalars(
        select(LAreas)
        .where(
            LAreas.area_type.has(
                BibAreasTypes.type_code == "COM",
            ),
            ~LAreas.synthese_obs.any(),
        )
        .limit(1)
    ).first()


def getCommBySynthese(obs):
    """
    Return area by synthese
    """
    return db.session.scalars(
        select(LAreas)
        .where(
            LAreas.area_type.has(
                BibAreasTypes.type_code == "COM",
            ),
            LAreas.synthese_obs.any(
                Synthese.id_synthese == obs.id_synthese,
            ),
        )
        .limit(1)
    ).first()


# TODO: maybe move it to global fixture
@pytest.fixture()
def unexisted_id():
    return db.session.scalar(select(func.max(TDatasets.id_dataset)).select_from(TDatasets)) + 1


@pytest.fixture
def af_list():
    return [
        {"id_acquisition_framework": 5},
        {"id_acquisition_framework": 2},
        {"id_acquisition_framework": 1},
    ]


@pytest.fixture
def synthese_corr():
    return {
        "identifiant_gn": "id_synthese",
        "identifiantPermanent (SINP)": "unique_id_sinp",
        "nomcite": "nom_cite",
        "jourDateDebut": "date_min",
        "jourDatefin": "date_max",
        "observateurIdentite": "observers",
    }


@pytest.fixture(scope="class")
def additional_fields(app):
    module = db.session.execute(
        select(TModules).where(TModules.module_code == "METADATA")
    ).scalar_one()
    obj_af = db.session.execute(
        select(PermObject).where(PermObject.code_object == "METADATA_CADRE_ACQUISITION")
    ).scalar_one()
    obj_ds = db.session.execute(
        select(PermObject).where(PermObject.code_object == "METADATA_JEU_DE_DONNEES")
    ).scalar_one()

    # Retrieve widget IDs from database
    widget_ids = {}
    for widget_name in ["select", "nomenclature", "text", "date", "number"]:
        widget = db.session.execute(
            select(BibWidgets).where(BibWidgets.widget_name == widget_name)
        ).scalar_one()
        widget_ids[widget_name] = widget.id_widget

    for name, widget_name in [
        ("select_field_used", "select"),
        ("nomenclature_field_used", "nomenclature"),
        ("text_field_used", "text"),
        ("date_field_used", "date"),
        ("number_field_used", "number"),
        ("text_field_not_used", "text"),
    ]:
        for obj in [obj_af, obj_ds]:
            additional_field = TAdditionalFields(
                field_name=name,
                field_label=name,
                required=True,
                id_widget=widget_ids[widget_name],
                modules=[module],
                objects=[obj],
            )
            with db.session.begin_nested():
                db.session.add(additional_field)
    return None


def get_csv_from_response(data):
    csv_data = data.decode("utf8")
    with StringIO(csv_data) as f:
        for i, row in enumerate(csv.DictReader(f, delimiter=";")):
            yield i, row


@pytest.mark.usefixtures("client_class")
def test_dataset_schema_additional_data_field():
    """
    DatasetSchema.additional_data must be an AdditionnalDataDuplicateField
    scoped to METADATA / METADATA_JEU_DE_DONNEES, not a plain Dict field.
    """
    field = DatasetSchema()._declared_fields["additional_data"]
    assert isinstance(field, AdditionalDataWithNomenclatureField)
    assert field.module_code == "METADATA"
    assert field.object_code == "METADATA_JEU_DE_DONNEES"


def test_acquisition_framework_schema_additional_data_field():
    """
    AcquisitionFrameworkSchema.additional_data must be an
    AdditionnalDataDuplicateField scoped to METADATA / METADATA_CADRE_ACQUISITION,
    not a plain Dict field.
    """
    field = AcquisitionFrameworkSchema()._declared_fields["additional_data"]
    assert isinstance(field, AdditionalDataWithNomenclatureField)
    assert field.module_code == "METADATA"
    assert field.object_code == "METADATA_CADRE_ACQUISITION"


@pytest.mark.usefixtures("client_class", "temporary_transaction")
class TestGNMeta:

    class TestGetAcquisitionFrameworkRoute:
        def test_get_acquisition_frameworks(self, users):
            acquisition_frameworks_url = url_for("gn_meta.get_acquisition_frameworks")
            response = self.client.get(acquisition_frameworks_url)
            assert response.status_code == Unauthorized.code

            set_logged_user(self.client, users["admin_user"])
            response = self.client.get(acquisition_frameworks_url)

            assert response.status_code == 200
            response = self.client.get(
                acquisition_frameworks_url,
                query_string={
                    "datasets": "1",
                    "creator": "1",
                    "actors": "1",
                },
            )
            assert response.status_code == 200

        def test_get_acquisition_frameworks_list(self, users):
            acquisition_frameworks_url = url_for("gn_meta.get_acquisition_frameworks")
            response = self.client.get(acquisition_frameworks_url)
            assert response.status_code == Unauthorized.code

            set_logged_user(self.client, users["admin_user"])

            response = self.client.get(acquisition_frameworks_url)
            assert response.status_code == 200

        def test_filter_acquisition_by_geo(self, synthese_data, users, commune_without_obs):
            # security test already passed in previous tests
            set_logged_user(self.client, users["admin_user"])
            acquisition_frameworks_url = url_for("gn_meta.get_acquisition_frameworks")

            # get 2 synthese observations in two differents AF and two differents communes
            s1, s2 = synthese_data["p1_af1"], synthese_data["p3_af3"]
            comm1, comm2 = getCommBySynthese(s1), getCommBySynthese(s2)

            # prerequisite for the test:
            assert (
                s1.dataset.acquisition_framework != s2.dataset.acquisition_framework
            )  # prerequisite for the test
            assert comm1 != comm2

            # search metadata in first commune
            response = self.client.post(
                acquisition_frameworks_url,
                json={"areas": [comm1.id_area]},
            )
            ids = [af["id_acquisition_framework"] for af in response.json["items"]]
            assert s1.dataset.id_acquisition_framework in ids
            assert s2.dataset.id_acquisition_framework not in ids

            # will test if an other CA is correctly return for an other synthese with diff location
            # get commune for this id synthese
            response = self.client.post(
                acquisition_frameworks_url,
                json={"areas": [comm2.id_area]},
            )
            ids = [af["id_acquisition_framework"] for af in response.json["items"]]
            assert s1.dataset.id_acquisition_framework not in ids
            assert s2.dataset.id_acquisition_framework in ids

            # test no response if a commune have observations
            response = self.client.post(
                acquisition_frameworks_url,
                json={"areas": [commune_without_obs.id_area]},
            )
            resp = response.json["items"]
            # will return empty response
            assert len(resp) == 0

        def test_get_acquisition_framework(self, users, acquisition_frameworks):
            af_id = acquisition_frameworks["orphan_af"].id_acquisition_framework
            get_af_url = url_for(
                "gn_meta.get_acquisition_framework", id_acquisition_framework=af_id
            )

            response = self.client.get(get_af_url)
            assert response.status_code == Unauthorized.code

            set_logged_user(self.client, users["self_user"])
            response = self.client.get(get_af_url)
            assert response.status_code == Forbidden.code

            set_logged_user(self.client, users["admin_user"])
            response = self.client.get(get_af_url)
            assert response.status_code == 200

        def test_get_acquisition_framework_user_fields(self, users, acquisition_frameworks):
            af = acquisition_frameworks["own_af"]
            with db.session.begin_nested():
                af.cor_af_actor.append(
                    CorAcquisitionFrameworkActor(
                        role=users["associate_user"],
                        nomenclature_actor_role=af.cor_af_actor[0].nomenclature_actor_role,
                    )
                )

            set_logged_user(self.client, users["admin_user"])
            response = self.client.get(
                url_for(
                    "gn_meta.get_acquisition_framework",
                    id_acquisition_framework=af.id_acquisition_framework,
                )
            )
            assert response.status_code == 200

            # Only minimal user information must be exposed
            expected_keys = {"id_role", "nom_complet"}
            assert set(response.json["creator"].keys()) == expected_keys
            roles = [actor["role"] for actor in response.json["cor_af_actor"] if actor.get("role")]
            assert roles
            assert all(set(role.keys()) == expected_keys for role in roles)

        def test_get_acquisition_framework_add_only(self, users):
            set_logged_user(self.client, users["admin_user"])
            get_af_url = url_for(
                "gn_meta.get_acquisition_frameworks", datasets=1, creator=1, actors=1
            )

            response = self.client.get(get_af_url)
            assert response.status_code == 200
            assert len(response.json) > 1
            data = response.json["items"]
            assert DatasetSchema(many=True).validate(data)
            assert UserSafeSchema().validate(data[0]["creator"])
            assert all(["cor_af_actor" in af for af in data])

        def test_get_acquisition_frameworks_search_af_name(
            self, users, acquisition_frameworks, datasets
        ):
            set_logged_user(self.client, users["admin_user"])
            af1 = acquisition_frameworks["af_1"]
            af2 = acquisition_frameworks["af_2"]

            get_af_url = url_for("gn_meta.get_acquisition_frameworks")

            response = self.client.post(get_af_url, json={"search": af1.acquisition_framework_name})
            print(response.status_code)
            print(response.json)
            af_list = [af["id_acquisition_framework"] for af in response.json["items"]]
            assert af1.id_acquisition_framework in af_list
            assert af2.id_acquisition_framework not in af_list

        def test_get_acquisition_frameworks_search_ds_name(
            self, users, acquisition_frameworks, datasets
        ):
            set_logged_user(self.client, users["admin_user"])
            ds = datasets["belong_af_1"]
            af1 = acquisition_frameworks["af_1"]
            af2 = acquisition_frameworks["af_2"]
            get_af_url = url_for("gn_meta.get_acquisition_frameworks")

            response = self.client.post(get_af_url, json={"search": ds.dataset_name})
            assert response.status_code == 200

            af_list = [af["id_acquisition_framework"] for af in response.json["items"]]
            assert af1.id_acquisition_framework in af_list
            assert af2.id_acquisition_framework not in af_list

        def test_get_acquisition_frameworks_nested_datasets_criteria(
            self, users, acquisition_frameworks, datasets
        ):
            """Criteria nested under `datasets` apply to the datasets, flat ones to the AF"""
            set_logged_user(self.client, users["admin_user"])
            ds = datasets["belong_af_1"]
            af1 = acquisition_frameworks["af_1"]
            get_af_url = url_for("gn_meta.get_acquisition_frameworks")

            response = self.client.post(get_af_url, json={"datasets": {"name": ds.dataset_name}})
            assert response.status_code == 200
            af_list = [af["id_acquisition_framework"] for af in response.json["items"]]
            assert af1.id_acquisition_framework in af_list

            # same criteria applied flat target the AF name, which does not match
            response = self.client.post(get_af_url, json={"name": ds.dataset_name})
            assert response.status_code == 200
            af_list = [af["id_acquisition_framework"] for af in response.json["items"]]
            assert af1.id_acquisition_framework not in af_list

        def test_get_acquisition_frameworks_fulltext_search(self, users, acquisition_frameworks):
            """Search is accent/case insensitive and matches word prefixes"""
            set_logged_user(self.client, users["admin_user"])
            af1 = acquisition_frameworks["af_1"]
            get_af_url = url_for("gn_meta.get_acquisition_frameworks")
            word = af1.acquisition_framework_name.split()[0]
            partial = word[: max(3, len(word) - 1)].upper()

            response = self.client.post(get_af_url, json={"search": partial})
            assert response.status_code == 200
            af_list = [af["id_acquisition_framework"] for af in response.json["items"]]
            assert af1.id_acquisition_framework in af_list

        def test_get_acquisition_frameworks_search_with_criteria(
            self, users, acquisition_frameworks, datasets
        ):
            """The quick search and the criteria are combined: results must match both"""
            set_logged_user(self.client, users["admin_user"])
            ds = datasets["belong_af_1"]
            af1 = acquisition_frameworks["af_1"]
            get_af_url = url_for("gn_meta.get_acquisition_frameworks")

            response = self.client.post(
                get_af_url,
                json={
                    "search": af1.acquisition_framework_name,
                    "datasets": {"name": ds.dataset_name},
                },
            )
            assert response.status_code == 200
            af_list = [af["id_acquisition_framework"] for af in response.json["items"]]
            assert af1.id_acquisition_framework in af_list

            response = self.client.post(
                get_af_url,
                json={
                    "search": af1.acquisition_framework_name,
                    "datasets": {"name": "no dataset has this name"},
                },
            )
            assert response.status_code == 200
            assert response.json["items"] == []

        def test_get_acquisition_frameworks_search_uuid_prefix(self, users, acquisition_frameworks):
            set_logged_user(self.client, users["admin_user"])
            af1 = acquisition_frameworks["af_1"]
            uuid = str(af1.unique_acquisition_framework_id)
            get_af_url = url_for("gn_meta.get_acquisition_frameworks")
            for term in (uuid[:4], uuid[:13].upper()):
                response = self.client.post(get_af_url, json={"search": term})
                assert response.status_code == 200
                af_list = [af["id_acquisition_framework"] for af in response.json["items"]]
                assert af1.id_acquisition_framework in af_list

        def test_get_acquisition_frameworks_search_creator(self, users, acquisition_frameworks):
            set_logged_user(self.client, users["admin_user"])
            af1 = acquisition_frameworks["af_1"]
            creator = users["self_user"]
            af1.creator = creator
            db.session.flush()
            get_af_url = url_for("gn_meta.get_acquisition_frameworks")
            # accent/case insensitive, in any order
            term = f"{creator.prenom_role or ''} {creator.nom_role}".lower()
            response = self.client.post(get_af_url, json={"search": term})
            assert response.status_code == 200
            af_list = [af["id_acquisition_framework"] for af in response.json["items"]]
            assert af1.id_acquisition_framework in af_list

        def test_acquisition_framework_pagination(self, users):
            """Test la pagination de la route acquisition_frameworks"""
            acquisition_frameworks_url = url_for("gn_meta.get_acquisition_frameworks")
            # Créer plusieurs AFs pour tester la pagination
            with db.session.begin_nested():
                for i in range(55):  # Créer 55 AFs pour tester sur plusieurs pages
                    af = TAcquisitionFramework(
                        acquisition_framework_name=f"Test AF {i}",
                        acquisition_framework_desc="Test description",
                        id_digitizer=users["admin_user"].id_role,
                    )
                    db.session.add(af)

            set_logged_user(self.client, users["admin_user"])
            # Test pagination par défaut (50 éléments par page)
            response = self.client.get(acquisition_frameworks_url)
            assert response.status_code == 200
            data = response.get_json()
            assert len(data["items"]) == 50  # Vérifie le nombre d'éléments par défaut
            assert data["page"] == 1
            assert data["has_next"] == True
            assert data["has_prev"] == False
            assert data["per_page"] == 50

            response = self.client.get(f"{acquisition_frameworks_url}?page=2")
            assert response.status_code == 200
            data = response.get_json()
            assert len(data["items"]) >= 5
            assert data["page"] == 2
            assert data["has_next"] == False
            assert data["has_prev"] == True

            # Test personnalisation du nombre d'éléments par page
            response = self.client.get(f"{acquisition_frameworks_url}?per_page=10")
            assert response.status_code == 200
            data = response.get_json()
            assert len(data["items"]) == 10
            assert data["per_page"] == 10
            assert data["has_next"] == True

            # Test récupération de tous les éléments (per_page=-1)
            response = self.client.get(f"{acquisition_frameworks_url}?per_page=-1")
            assert response.status_code == 200
            data = response.get_json()
            assert len(data["items"]) >= 55
            assert data["page"] == 1
            assert data["has_next"] == False
            assert data["has_prev"] == False
            assert data["pages"] == 1

            # Test page inexistante
            response = self.client.get(f"{acquisition_frameworks_url}?page=999")
            assert response.status_code == 404

    def test_acquisition_frameworks_permissions(self, app, acquisition_frameworks, datasets, users):
        af = acquisition_frameworks["own_af"]
        with app.test_request_context(headers=logged_user_headers(users["user"])):
            app.preprocess_request()
            assert af.has_instance_permission(0) == False
            assert af.has_instance_permission(1) == True
            assert af.has_instance_permission(2) == True
            assert af.has_instance_permission(3) == True

        with app.test_request_context(headers=logged_user_headers(users["associate_user"])):
            app.preprocess_request()
            assert af.has_instance_permission(0) == False
            assert af.has_instance_permission(1) == False
            assert af.has_instance_permission(2) == True
            assert af.has_instance_permission(3) == True

        with app.test_request_context(headers=logged_user_headers(users["stranger_user"])):
            app.preprocess_request()
            assert af.has_instance_permission(0) == False
            assert af.has_instance_permission(1) == False
            assert af.has_instance_permission(2) == False
            assert af.has_instance_permission(3) == True

        af = acquisition_frameworks["orphan_af"]  # all DS are attached to this AF
        with app.test_request_context(headers=logged_user_headers(users["user"])):
            app.preprocess_request()
            assert af.has_instance_permission(0) == False
            # The AF has no actors, but the AF has DS on which the user is digitizer!
            assert af.has_instance_permission(1) == True
            assert af.has_instance_permission(2) == True
            assert af.has_instance_permission(3) == True

            nested = db.session.begin_nested()
            af.t_datasets.remove(datasets["own_dataset"])
            af.t_datasets.remove(datasets["private"])
            af.t_datasets.remove(datasets["own_dataset_not_activated"])
            # Now, the AF has no DS on which user is digitizer.
            assert af.has_instance_permission(1) == False
            # But the AF has still DS on which user organism is actor.
            assert af.has_instance_permission(2) == True
            nested.rollback()
            assert datasets["own_dataset"] in af.t_datasets

        with app.test_request_context(headers=logged_user_headers(users["user"])):
            app.preprocess_request()
            af_ids = [af.id_acquisition_framework for af in acquisition_frameworks.values()]
            qs = select(TAcquisitionFramework).where(
                TAcquisitionFramework.id_acquisition_framework.in_(af_ids)
            )
            ta = TAcquisitionFramework
            sc = db.session.scalars

            assert set(sc(ta.filter_by_scope(0, query=qs)).unique().all()) == set([])
            assert set(sc(ta.filter_by_scope(1, query=qs)).unique().all()) == set(
                [
                    acquisition_frameworks["own_af"],
                    acquisition_frameworks["orphan_af"],  # through DS
                    acquisition_frameworks["parent_af"],
                    acquisition_frameworks["child_af"],
                    acquisition_frameworks["parent_wo_children_af"],
                    acquisition_frameworks["delete_parent_wo_children_af"],
                    acquisition_frameworks["delete_af"],
                ]
            )
            assert set(sc(ta.filter_by_scope(2, query=qs)).unique().all()) == set(
                [
                    acquisition_frameworks["own_af"],
                    acquisition_frameworks["associate_af"],
                    acquisition_frameworks["orphan_af"],  # through DS
                    acquisition_frameworks["parent_af"],
                    acquisition_frameworks["child_af"],
                    acquisition_frameworks["parent_wo_children_af"],
                    acquisition_frameworks["delete_parent_wo_children_af"],
                    acquisition_frameworks["delete_af"],
                ]
            )
            assert set(sc(ta.filter_by_scope(3, query=qs)).unique().all()) == set(
                acquisition_frameworks.values()
            )

    @pytest.mark.parametrize(
        "af,has_datasets",
        [
            ("own_af", False),
            ("orphan_af", True),
        ],
    )
    def test_acquisition_framework_has_datasets(
        self, app, acquisition_frameworks, datasets, af, has_datasets
    ):
        assert acquisition_frameworks[af].has_datasets() == has_datasets

    @pytest.mark.parametrize(
        "af,has_child_af",
        [
            ("parent_af", True),
            ("parent_wo_children_af", False),
        ],
    )
    def test_acquisition_framework_has_child_acquisition_framework(
        self, app, acquisition_frameworks, datasets, af, has_child_af
    ):
        assert acquisition_frameworks[af].has_child_acquisition_framework() == has_child_af

    def test_create_acquisition_framework(self, users):
        set_logged_user(self.client, users["user"])

        # Post with only required attributes
        response = self.client.post(
            url_for("gn_meta.create_acquisition_framework"),
            json={
                "acquisition_framework_name": "test",
                "acquisition_framework_desc": "desc",
            },
        )

        assert response.status_code == 200

    def test_create_acquisition_framework_forbidden(self, users):
        set_logged_user(self.client, users["noright_user"])

        response = self.client.post(url_for("gn_meta.create_acquisition_framework"), data={})

        assert response.status_code == Forbidden.code

    def test_duplicate_uuid_returns_conflict(self, users):
        """Le deuxième POST avec le même unique_id doit renvoyer 409."""
        uid = str(uuid.uuid4())

        set_logged_user(self.client, users["user"])

        resp1 = self.client.post(
            url_for("gn_meta.create_acquisition_framework"),
            json={
                "acquisition_framework_name": "premier",
                "acquisition_framework_desc": "desc",
                "unique_acquisition_framework_id": uid,
            },
        )
        assert resp1.status_code in (200, 201)

        resp2 = self.client.post(
            url_for("gn_meta.create_acquisition_framework"),
            json={
                "acquisition_framework_name": "doublon",
                "acquisition_framework_desc": "desc",
                "unique_acquisition_framework_id": uid,
            },
        )

        assert resp2.status_code == 409
        payload = resp2.get_json()
        assert "unique_acquisition_framework_id" in payload["description"]

    @pytest.mark.parametrize(
        "user,dataset,status_code",
        [
            (None, "orphan_af", Unauthorized.code),
            ("noright_user", "orphan_af", Forbidden.code),
            ("self_user", "orphan_af", Forbidden.code),
            ("admin_user", "orphan_af", Conflict.code),
            ("admin_user", "parent_af", Conflict.code),
            ("user", "own_af", 204),
            ("user", "delete_parent_wo_children_af", 204),
            ("user", "delete_af", 204),
        ],
    )
    def test_delete_acquisition_framework(
        self, app, users, acquisition_frameworks, datasets, user, dataset, status_code
    ):
        if user:
            set_logged_user(self.client, users[user])

        response = self.client.delete(
            url_for(
                "gn_meta.delete_acquisition_framework",
                af_id=acquisition_frameworks[dataset].id_acquisition_framework,
            )
        )
        assert response.status_code == status_code

    def test_update_acquisition_framework(self, users, acquisition_frameworks):
        new_name = "thenewname"
        af = acquisition_frameworks["own_af"]
        set_logged_user(self.client, users["user"])

        response = self.client.post(
            url_for(
                "gn_meta.updateAcquisitionFramework",
                id_acquisition_framework=af.id_acquisition_framework,
            ),
            data=dict(acquisition_framework_name=new_name),
        )

        assert response.status_code == 200
        assert response.json.get("acquisition_framework_name") == new_name

    def test_update_acquisition_framework_forbidden(self, users, acquisition_frameworks):
        stranger_user = users["stranger_user"]
        set_logged_user(self.client, stranger_user)
        af = acquisition_frameworks["own_af"]

        response = self.client.post(
            url_for(
                "gn_meta.updateAcquisitionFramework",
                id_acquisition_framework=af.id_acquisition_framework,
            ),
            data=dict(acquisition_framework_name="new_name"),
        )

        assert response.status_code == Forbidden.code
        assert (
            response.json["description"]
            == f"User {stranger_user.identifiant} cannot update acquisition framework {af.id_acquisition_framework}"
        )

    def test_update_acquisition_framework_forbidden_af(self, users, acquisition_frameworks):
        self_user = users["self_user"]
        set_logged_user(self.client, self_user)
        af = acquisition_frameworks["own_af"]

        response = self.client.post(
            url_for(
                "gn_meta.updateAcquisitionFramework",
                id_acquisition_framework=af.id_acquisition_framework,
            ),
            data=dict(acquisition_framework_name="new_name"),
        )

        assert response.status_code == Forbidden.code
        assert (
            response.json["description"]
            == f"User {self_user.identifiant} cannot update acquisition framework {af.id_acquisition_framework}"
        )

    def test_get_export_pdf_acquisition_frameworks(self, users, acquisition_frameworks):
        af_id = acquisition_frameworks["orphan_af"].id_acquisition_framework

        set_logged_user(self.client, users["user"])

        response = self.client.post(
            url_for("gn_meta.get_export_pdf_acquisition_frameworks", id_acquisition_framework=af_id)
        )

        assert response.status_code == 200

    def test_get_export_pdf_acquisition_frameworks_with_data(
        self, users, acquisition_frameworks, datasets, additional_fields
    ):
        af_id = acquisition_frameworks["af_1"].id_acquisition_framework

        set_logged_user(self.client, users["user"])

        response = self.client.post(
            url_for("gn_meta.get_export_pdf_acquisition_frameworks", id_acquisition_framework=af_id)
        )

        assert response.status_code == 200

    def test_get_export_pdf_acquisition_frameworks_unauthorized(self, acquisition_frameworks):
        af_id = acquisition_frameworks["own_af"].id_acquisition_framework

        response = self.client.post(
            url_for("gn_meta.get_export_pdf_acquisition_frameworks", id_acquisition_framework=af_id)
        )

        assert response.status_code == Unauthorized.code

    def test_get_acquisition_framework_stats(
        self, users, acquisition_frameworks, datasets, synthese_data
    ):
        af = synthese_data["obs1"].dataset.acquisition_framework
        set_logged_user(self.client, users["user"])

        response = self.client.get(
            url_for(
                "gn_meta.get_acquisition_framework_stats_route",
                id_acquisition_framework=af.id_acquisition_framework,
            )
        )
        data = response.json
        data_dict_nb_obs = data["dict_nb_obs"]

        assert response.status_code == 200
        assert data["nb_dataset"] == len(af.datasets)
        assert data_dict_nb_obs["OCCHAB"] == 0
        obs = [s for s in synthese_data.values() if s.dataset.acquisition_framework == af]
        assert data_dict_nb_obs["SYNTHESE"] == len(obs)
        # Count of taxa :
        # Loop all the synthese entries, for each synthese
        # For each entry, take the max between count_min and count_max. And if
        # not provided: count_min and/or count_max is 1. Since one entry in
        # synthese is at least 1 taxon
        assert data["nb_taxons"] == len(set([s.cd_nom for s in obs]))

    def test_get_dataset_stats(self, users, datasets, synthese_data, stations):
        ds = datasets["own_dataset"]
        set_logged_user(self.client, users["user"])

        response = self.client.get(
            url_for(
                "gn_meta.get_dataset_stats",
                id_dataset=ds.id_dataset,
            )
        )
        data = response.json
        data_dict_nb_obs = data["dict_nb_obs"]

        assert response.status_code == 200
        expected_nb_observations_habitats = 4
        assert data_dict_nb_obs["OCCHAB"] == expected_nb_observations_habitats
        obs = [s for s in synthese_data.values() if s.dataset == ds]
        expected_nb_observations_synthese = len(obs)
        assert data_dict_nb_obs["SYNTHESE"] == expected_nb_observations_synthese
        expected_nb_observations = (
            expected_nb_observations_synthese + expected_nb_observations_habitats
        )
        assert data["total_nb_obs"] == expected_nb_observations

    def test_dataset_nb_observations_hybrid_property(self, users, datasets, synthese_data):
        ds = datasets["own_dataset"]
        set_logged_user(self.client, users["user"])

        nb_obs = db.session.execute(
            select(TDatasets.nb_observations)
            .select_from(TDatasets)
            .where(TDatasets.id_dataset == ds.id_dataset)
        ).scalar_one()

        expected_nb_obs_habitats = 0
        expected_nb_obs_synthese = len([s for s in synthese_data.values() if s.dataset == ds])
        expected_nb_obs = expected_nb_obs_habitats + expected_nb_obs_synthese

        assert nb_obs == expected_nb_obs

    def test_get_acquisition_framework_bbox(self, users, acquisition_frameworks, synthese_data):
        # this AF contains at least 2 obs at different locations
        af = synthese_data["p1_af1"].dataset.acquisition_framework

        set_logged_user(self.client, users["user"])

        response = self.client.get(
            url_for(
                "gn_meta.get_acquisition_framework_bbox",
                id_acquisition_framework=af.id_acquisition_framework,
            )
        )
        data = response.json

        assert response.status_code == 200
        assert data["type"] == "Polygon"

    def test_datasets_permissions(self, app, datasets, users):
        ds = datasets["own_dataset"]
        with app.test_request_context(headers=logged_user_headers(users["user"])):
            app.preprocess_request()
            assert ds.has_instance_permission(0) == False
            assert ds.has_instance_permission(1) == True
            assert ds.has_instance_permission(2) == True
            assert ds.has_instance_permission(3) == True

        with app.test_request_context(headers=logged_user_headers(users["associate_user"])):
            app.preprocess_request()
            assert ds.has_instance_permission(0) == False
            assert ds.has_instance_permission(1) == False
            assert ds.has_instance_permission(2) == True
            assert ds.has_instance_permission(3) == True

        with app.test_request_context(headers=logged_user_headers(users["stranger_user"])):
            app.preprocess_request()
            assert ds.has_instance_permission(0) == False
            assert ds.has_instance_permission(1) == False
            assert ds.has_instance_permission(2) == False
            assert ds.has_instance_permission(3) == True

        with app.test_request_context(headers=logged_user_headers(users["user"])):
            app.preprocess_request()
            ds_ids = [ds.id_dataset for ds in datasets.values()]
            sc = db.session.scalars
            dsc = TDatasets
            qs = select(TDatasets).where(TDatasets.id_dataset.in_(ds_ids))
            assert set(sc(dsc.filter_by_scope(0, query=qs)).unique().all()) == set([])
            assert set(sc(dsc.filter_by_scope(1, query=qs)).unique().all()) == set(
                [
                    datasets["own_dataset"],
                    datasets["own_dataset_not_activated"],
                    datasets["private"],
                ]
            )
            assert set(sc(dsc.filter_by_scope(2, query=qs)).unique().all()) == set(
                [
                    datasets["own_dataset"],
                    datasets["own_dataset_not_activated"],
                    datasets["associate_dataset"],
                    datasets["associate_2_dataset_sensitive"],
                    datasets["private"],
                ]
            )
            assert set(sc(dsc.filter_by_scope(3, query=qs)).unique().all()) == set(
                datasets.values()
            )

    def test_dataset_is_deletable(self, app, synthese_data, datasets):
        assert (
            datasets["own_dataset"].is_deletable() == False
        )  # there are synthese data attached to this DS
        assert datasets["orphan_dataset"].is_deletable() == True

    def test_delete_dataset(self, app, users, synthese_data, acquisition_frameworks, datasets):
        ds_id = datasets["own_dataset"].id_dataset

        response = self.client.delete(url_for("gn_meta.delete_dataset", ds_id=ds_id))
        assert response.status_code == Unauthorized.code

        set_logged_user(self.client, users["noright_user"])

        # The user has no rights on METADATA module
        response = self.client.delete(url_for("gn_meta.delete_dataset", ds_id=ds_id))
        assert response.status_code == Forbidden.code
        assert "METADATA" in response.json["description"]

        set_logged_user(self.client, users["self_user"])

        # The user has right on METADATA module, but not on this specific DS
        response = self.client.delete(url_for("gn_meta.delete_dataset", ds_id=ds_id))
        assert response.status_code == Forbidden.code
        assert "METADATA" not in response.json["description"]

        set_logged_user(self.client, users["user"])

        # The DS can not be deleted due to attached rows in synthese
        response = self.client.delete(url_for("gn_meta.delete_dataset", ds_id=ds_id))
        assert response.status_code == Conflict.code

        set_logged_user(self.client, users["admin_user"])
        ds_id = datasets["orphan_dataset"].id_dataset

        response = self.client.delete(url_for("gn_meta.delete_dataset", ds_id=ds_id))
        assert response.status_code == 204

    def test_list_datasets(self, users, datasets, acquisition_frameworks):
        response = self.client.get(url_for("gn_meta.get_datasets"))
        assert response.status_code == Unauthorized.code

        set_logged_user(self.client, users["admin_user"])

        response = self.client.get(url_for("gn_meta.get_datasets"))
        assert response.status_code == 200
        expected_ds = {dataset.id_dataset for dataset in datasets.values()}
        resp_ds = {ds["id_dataset"] for ds in response.json}
        assert expected_ds.issubset(resp_ds)

        afs = [acquisition_frameworks["af_1"], acquisition_frameworks["af_2"]]
        filtered_response = self.client.get(
            url_for("gn_meta.get_datasets"),
            json={
                "id_acquisition_frameworks": [af.id_acquisition_framework for af in afs],
            },
        )
        assert filtered_response.status_code == 200
        expected_ds = {
            dataset.id_dataset
            for key, dataset in datasets.items()
            if key in ("belong_af_1", "belong_af_2")
        }
        filtered_ds = {ds["id_dataset"] for ds in filtered_response.json}
        assert expected_ds.issubset(filtered_ds)
        assert all(
            dataset["id_acquisition_framework"] in [af.id_acquisition_framework for af in afs]
            for dataset in filtered_response.json
        )

    def test_list_datasets_mobile(self, users, datasets, acquisition_frameworks):
        set_logged_user(self.client, users["admin_user"])
        headers = Headers()
        headers.add("User-Agent", "okhttp/")

        response = self.client.get(url_for("gn_meta.get_datasets"), headers=headers)

        assert set(response.json.keys()) == {"data"}

    def get_test_dataset_json(self, id_acquisition_framework):
        return {
            "id_acquisition_framework": id_acquisition_framework,
            "dataset_name": "test",
            "dataset_shortname": "test",
            "dataset_desc": "test",
            "terrestrial_domain": True,
            "marine_domain": False,
            "unique_dataset_id": None,
        }

    def test_create_dataset(self, users, datasets):
        response = self.client.post(url_for("gn_meta.create_dataset"))
        assert response.status_code == Unauthorized.code

        set_logged_user(self.client, users["admin_user"])

        response = self.client.post(url_for("gn_meta.create_dataset"))
        assert response.status_code == UnsupportedMediaType.code

        set_logged_user(self.client, users["admin_user"])
        ds = datasets["own_dataset"].as_dict()
        ds["id_dataset"] = "takeonme"
        response = self.client.post(url_for("gn_meta.create_dataset"), json=ds)
        assert response.status_code == BadRequest.code
        ds_json = self.get_test_dataset_json(datasets["own_dataset"].id_acquisition_framework)
        response = self.client.post(
            url_for("gn_meta.create_dataset"),
            json=ds_json,
        )
        assert response.status_code == 200

    def test_dataset_with_closed_af(self, users, datasets):
        set_logged_user(self.client, users["admin_user"])
        datasets["own_dataset"].acquisition_framework.opened = False
        db.session.flush()
        ds_json = self.get_test_dataset_json(datasets["own_dataset"].id_acquisition_framework)
        response = self.client.post(
            url_for("gn_meta.create_dataset"),
            json=ds_json,
        )
        assert response.status_code == 400
        # We check if error is linked to the acquisition framework
        assert response.json["description"].get("id_acquisition_framework")

        # Now post the dataset with af opened, close it and try to update its active status
        datasets["own_dataset"].acquisition_framework.opened = True
        db.session.flush()
        ds_json["active"] = False
        response = self.client.post(url_for("gn_meta.create_dataset"), json=ds_json)
        assert response.status_code == 200
        id_dataset = response.json["id_dataset"]

        datasets["own_dataset"].acquisition_framework.opened = False
        db.session.flush()
        ds_json["active"] = True
        response = self.client.post(
            url_for("gn_meta.update_dataset", id_dataset=id_dataset), json=ds_json
        )
        assert response.status_code == 400
        assert response.json["description"].get("active")

    def test_get_dataset(self, users, datasets, additional_fields, first_nomenclature):
        ds = datasets["own_dataset"]

        response = self.client.get(url_for("gn_meta.get_dataset", id_dataset=ds.id_dataset))
        assert response.status_code == Unauthorized.code

        stranger_user = users["stranger_user"]
        set_logged_user(self.client, stranger_user)
        response = self.client.get(url_for("gn_meta.get_dataset", id_dataset=ds.id_dataset))
        assert response.status_code == Forbidden.code
        assert (
            response.json["description"]
            == f"User {stranger_user.identifiant} cannot read dataset {ds.id_dataset}"
        )

        set_logged_user(self.client, users["associate_user"])
        response = self.client.get(url_for("gn_meta.get_dataset", id_dataset=ds.id_dataset))
        assert response.status_code == 200

        assert DatasetSchema().validate(response.json)
        assert response.json["additional_data"] == {
            "select_field_used": "value1",
            "nomenclature_field_used": first_nomenclature.id_nomenclature,
            "_label_nomenclature_field_used": first_nomenclature.label_default,
            "text_field_used": "test",
            "date_field_used": {"day": 31, "year": 2025, "month": 10},
            "number_field_used": 1,
        }
        assert response.json["id_dataset"] == ds.id_dataset

    def test_get_dataset_user_fields(self, users, datasets):
        ds = datasets["own_dataset"]
        with db.session.begin_nested():
            ds.cor_dataset_actor.append(
                CorDatasetActor(
                    role=users["associate_user"],
                    nomenclature_actor_role=ds.cor_dataset_actor[0].nomenclature_actor_role,
                )
            )

        set_logged_user(self.client, users["admin_user"])
        response = self.client.get(url_for("gn_meta.get_dataset", id_dataset=ds.id_dataset))
        assert response.status_code == 200

        # Only minimal user information must be exposed
        expected_keys = {"id_role", "nom_complet"}
        assert set(response.json["creator"].keys()) == expected_keys
        roles = [actor["role"] for actor in response.json["cor_dataset_actor"] if actor.get("role")]
        assert roles
        assert all(set(role.keys()) == expected_keys for role in roles)

    def test_get_datasets_nb_observations_synthese(self, users):
        # FIXME : verify content
        set_logged_user(self.client, users["admin_user"])
        response = self.client.get(url_for("gn_meta.get_datasets", nb_observations_synthese=1))

        assert response.status_code == 200

    @pytest.mark.skip(reason="Works localy but not on GH actions ! ")
    def test_get_datasets_fields(self, users):
        set_logged_user(self.client, users["admin_user"])
        response = self.client.get(url_for("gn_meta.get_datasets", fields="id_dataset"))
        assert response.status_code == 200

        for dataset in response.json:
            assert not "id_dataset" in dataset or len(dataset.keys()) > 1

        response = self.client.get(url_for("gn_meta.get_datasets", fields="modules"))
        assert response.status_code == 200

        # Test if modules non empty
        resp = response.json
        # FIXME : don't pass the test on GH
        assert len(resp) > 1 and "modules" in resp[0] and len(resp[0]["modules"]) > 0

    def test_get_datasets_order_by(self, users):
        # If added an orderby
        set_logged_user(self.client, users["admin_user"])
        response = self.client.get(url_for("gn_meta.get_datasets", orderby="id_dataset"))
        assert response.status_code == 200
        ids = [dataset["id_dataset"] for dataset in response.json]
        assert ids == sorted(ids)

        # with pytest.raises(BadRequest):
        response = self.client.get(
            url_for("gn_meta.get_datasets", orderby="you_create_unknown_columns?")
        )
        assert response.status_code == BadRequest.code

    def test_get_dataset_filter_active(self, users, datasets, module):
        set_logged_user(self.client, users["admin_user"])

        response = self.client.get(
            url_for("gn_meta.get_datasets"),
            json={"active": True},
        )

        expected_ds = {dataset.id_dataset for dataset in datasets.values() if dataset.active}
        filtered_ds = {ds["id_dataset"] for ds in response.json}
        assert expected_ds.issubset(filtered_ds)

    def test_get_dataset_filter_module_code(self, users, datasets, module):
        set_logged_user(self.client, users["admin_user"])

        response = self.client.get(
            url_for("gn_meta.get_datasets"),
            json={"module_code": module.module_code},
        )

        expected_ds = {datasets["with_module_1"].id_dataset}
        filtered_ds = {ds["id_dataset"] for ds in response.json}
        assert expected_ds.issubset(filtered_ds)
        assert datasets["own_dataset"].id_dataset not in filtered_ds

    def test_get_dataset_filter_create(self, users, datasets, module):
        set_logged_user(self.client, users["admin_user"])

        response = self.client.get(
            url_for("gn_meta.get_datasets"),
            json={"module_code": module.module_code, "create": module.module_code},
        )

        response_with_object = self.client.get(
            url_for("gn_meta.get_datasets"),
            json={"module_code": module.module_code, "create": module.module_code + ".ALL"},
        )

        expected_ds = {datasets["with_module_1"].id_dataset}
        filtered_ds = {ds["id_dataset"] for ds in response.json}
        assert response.json == response_with_object.json
        assert expected_ds.issubset(filtered_ds)
        assert datasets["own_dataset"].id_dataset not in filtered_ds

    def test_get_dataset_search(self, users, datasets, module):
        set_logged_user(self.client, users["admin_user"])
        ds = datasets["with_module_1"]

        response = self.client.get(
            url_for("gn_meta.get_datasets"),
            json={"search": ds.dataset_name},
        )

        expected_ds = {ds.id_dataset}
        filtered_ds = {ds["id_dataset"] for ds in response.json}
        assert expected_ds.issubset(filtered_ds)
        assert datasets["own_dataset"].id_dataset not in filtered_ds

    def test_get_dataset_search_af_matches(self, users, datasets, acquisition_frameworks):
        dataset = datasets["belong_af_1"]
        acquisition_framework = [
            af
            for af in acquisition_frameworks.values()
            if af.id_acquisition_framework == dataset.id_acquisition_framework
        ][0]
        set_logged_user(self.client, users["admin_user"])

        # If Acquisition Framework matches, returns all datasets
        response = self.client.get(
            url_for("gn_meta.get_datasets"),
            json={
                "id_acquisition_frameworks": [dataset.id_acquisition_framework],
                "search": acquisition_framework.acquisition_framework_name,
            },
        )

        assert {ds["id_acquisition_framework"] for ds in response.json} == {
            ds.id_acquisition_framework for ds in acquisition_framework.datasets
        }

    def test_get_dataset_search_ds_matches(self, users, datasets, acquisition_frameworks):
        dataset = datasets["belong_af_1"]
        set_logged_user(self.client, users["admin_user"])

        # If Acquisition Framework matches, returns all datasets
        response = self.client.get(
            url_for("gn_meta.get_datasets"),
            json={
                "id_acquisition_frameworks": [dataset.id_acquisition_framework],
                "search": dataset.dataset_name,
            },
        )

        assert len(response.json) == 1
        assert response.json[0]["dataset_name"] == dataset.dataset_name

    def test_get_dataset_search_ds_and_af_matches(self, users, datasets, acquisition_frameworks):
        dataset = datasets["belong_af_1"]
        acquisition_framework = [
            af
            for af in acquisition_frameworks.values()
            if af.id_acquisition_framework == dataset.id_acquisition_framework
        ][0]
        set_logged_user(self.client, users["admin_user"])

        # If Acquisition Framework matches, returns all datasets
        response = self.client.get(
            url_for("gn_meta.get_datasets"),
            json={
                "id_acquisition_frameworks": [dataset.id_acquisition_framework],
                "search": dataset.dataset_name[-4:],
            },
        )

        assert {ds["id_acquisition_framework"] for ds in response.json} == {
            ds.id_acquisition_framework for ds in acquisition_framework.datasets
        }

    def test_get_dataset_forbidden_ds(self, users, datasets):
        ds = datasets["own_dataset"]
        self_user = users["self_user"]
        set_logged_user(self.client, self_user)

        response = self.client.get(url_for("gn_meta.get_dataset", id_dataset=ds.id_dataset))

        assert response.status_code == Forbidden.code
        assert (
            response.json["description"]
            == f"User {self_user.identifiant} cannot read dataset {ds.id_dataset}"
        )

    def test_update_dataset(self, users, datasets):
        new_name = "thenewname"
        ds = datasets["own_dataset"]
        set_logged_user(self.client, users["user"])

        response = self.client.patch(
            url_for("gn_meta.update_dataset", id_dataset=ds.id_dataset),
            data=dict(dataset_name=new_name),
        )

        assert response.status_code == 200
        assert response.json.get("dataset_name") == new_name

    def test_update_dataset_not_found(self, users, datasets, unexisted_id):
        set_logged_user(self.client, users["user"])

        response = self.client.patch(url_for("gn_meta.update_dataset", id_dataset=unexisted_id))

        assert response.status_code == NotFound.code

    def test_update_dataset_forbidden(self, users, datasets):
        ds = datasets["own_dataset"]
        set_logged_user(self.client, users["stranger_user"])

        response = self.client.patch(url_for("gn_meta.update_dataset", id_dataset=ds.id_dataset))

        assert response.status_code == Forbidden.code

    def test_dataset_pdf_export(self, users, datasets, additional_fields):
        unexisting_id = (
            db.session.scalar(select(func.max(TDatasets.id_dataset)).select_from(TDatasets)) + 1
        )
        ds = datasets["own_dataset"]

        response = self.client.post(
            url_for("gn_meta.get_export_pdf_dataset", id_dataset=ds.id_dataset)
        )
        assert response.status_code == Unauthorized.code

        set_logged_user(self.client, users["self_user"])

        response = self.client.post(
            url_for("gn_meta.get_export_pdf_dataset", id_dataset=unexisting_id)
        )
        assert response.status_code == NotFound.code

        response = self.client.post(
            url_for("gn_meta.get_export_pdf_dataset", id_dataset=ds.id_dataset)
        )
        assert response.status_code == Forbidden.code

        set_logged_user(self.client, users["user"])
        response = self.client.post(
            url_for("gn_meta.get_export_pdf_dataset", id_dataset=ds.id_dataset)
        )
        assert response.status_code == 200

    def test_uuid_report(self, users, synthese_data):
        observations_nbr = db.session.scalar(
            select(func.count(Synthese.id_synthese)).select_from(Synthese)
        )
        if observations_nbr > 1000000:
            pytest.skip("Too much observations in gn_synthese.synthese")

        response = self.client.get(url_for("gn_meta.uuid_report"))
        assert response.status_code == Unauthorized.code

        set_logged_user(self.client, users["user"])
        response = self.client.get(url_for("gn_meta.uuid_report"))
        assert response.status_code == 200

    @pytest.mark.xfail(reason="FIXME")
    def test_uuid_report_with_dataset_id(
        self, synthese_corr, users, datasets, synthese_data, unexisted_id
    ):
        dataset_id = datasets["own_dataset"].id_dataset

        set_logged_user(self.client, users["user"])

        response = self.client.get(
            url_for("gn_meta.uuid_report"), query_string={"id_dataset": dataset_id}
        )
        response_empty = self.client.get(
            url_for("gn_meta.uuid_report"), query_string={"id_dataset": unexisted_id}
        )

        obs = synthese_data.values()
        assert response.status_code == 200
        rows = list(get_csv_from_response(response_empty.data))
        # TODO check result

        assert response_empty.status_code == 200
        rows = list(get_csv_from_response(response_empty.data))
        assert len(rows) == 1  # header only

    def test_sensi_report(self, users, datasets):
        dataset_id = datasets["own_dataset"].id_dataset
        response = self.client.get(
            url_for("gn_meta.sensi_report"), query_string={"id_dataset": dataset_id}
        )
        assert response.status_code == Unauthorized.code

        set_logged_user(self.client, users["user"])

        response = self.client.get(
            url_for("gn_meta.sensi_report"), query_string={"id_dataset": dataset_id}
        )
        assert response.status_code == 200

    def test_sensi_report_fail(self, users):
        set_logged_user(self.client, users["admin_user"])

        response = self.client.get(url_for("gn_meta.sensi_report"))
        # BadRequest because for now id_dataset query is required
        assert response.status_code == BadRequest.code

    def test_uuid_report_scope(self, users, datasets, synthese_data):
        set_logged_user(self.client, users["user"])

        # dataset the user cannot read
        response = self.client.get(
            url_for("gn_meta.uuid_report"),
            query_string={"id_dataset": datasets["belong_af_1"].id_dataset},
        )
        assert response.status_code == Forbidden.code

        # without filter, observations of unreadable datasets must not be returned
        response = self.client.get(url_for("gn_meta.uuid_report"))
        assert response.status_code == 200
        returned_ids = {
            int(row["identifiant_gn"]) for _, row in get_csv_from_response(response.data)
        }
        assert synthese_data["obs1"].id_synthese in returned_ids
        assert synthese_data["p1_af1"].id_synthese not in returned_ids

    def test_sensi_report_scope(self, users, datasets):
        set_logged_user(self.client, users["user"])

        response = self.client.get(
            url_for("gn_meta.sensi_report"),
            query_string={"id_dataset": datasets["belong_af_1"].id_dataset},
        )
        assert response.status_code == Forbidden.code

    def test_get_af_from_id(self, af_list):
        id_af = 1

        found_af = get_af_from_id(id_af=id_af, af_list=af_list)

        assert isinstance(found_af, dict)
        assert found_af.get("id_acquisition_framework") == id_af

    def test_get_af_from_id_not_present(self, af_list):
        id_af = 12

        found_af = get_af_from_id(id_af=id_af, af_list=af_list)

        assert found_af is None

    def test_get_af_from_id_none(self):
        id_af = 1
        af_list = [{"test": 2}]

        with pytest.raises(KeyError):
            get_af_from_id(id_af=id_af, af_list=af_list)

    def test__get_create_scope(self, app, users):
        modcode = "METADATA"

        with app.test_request_context(headers=logged_user_headers(users["user"])):
            app.preprocess_request()
            create = TDatasets._get_create_scope(module_code=modcode)

        usercreate = TDatasets._get_create_scope(module_code=modcode, user=users["user"])
        norightcreate = TDatasets._get_create_scope(module_code=modcode, user=users["noright_user"])
        associatecreate = TDatasets._get_create_scope(
            module_code=modcode, user=users["associate_user"]
        )
        admincreate = TDatasets._get_create_scope(module_code=modcode, user=users["admin_user"])

        assert create == 2
        assert usercreate == 2
        assert norightcreate == 0
        assert associatecreate == 2
        assert admincreate == 3

    def test___str__(self, datasets):
        dataset = datasets["associate_dataset"]

        assert isinstance(dataset.__str__(), str)
        assert dataset.__str__() == dataset.dataset_name

    def test_get_id_dataset(self, datasets):
        dataset = datasets["associate_dataset"]
        uuid_dataset = dataset.unique_dataset_id

        id_dataset = TDatasets.get_id(uuid_dataset)

        assert id_dataset == dataset.id_dataset
        assert TDatasets.get_id(uuid.uuid4()) is None

    def test_get_uuid(self, datasets):
        dataset = datasets["associate_dataset"]
        id_dataset = dataset.id_dataset

        uuid_dataset = TDatasets.get_uuid(id_dataset)

        assert uuid_dataset == dataset.unique_dataset_id
        assert TDatasets.get_uuid(None) is None

    def test_get_id_acquisition_framework(self, acquisition_frameworks):
        af = acquisition_frameworks["associate_af"]

        uuid_af = af.unique_acquisition_framework_id
        id_af = TAcquisitionFramework.get_id(uuid_af)

        assert id_af == af.id_acquisition_framework
        assert TAcquisitionFramework.get_id(uuid.uuid4()) is None

    def test_get_user_af(self, users, acquisition_frameworks):
        # Test to complete
        user = users["user"]

        afquery = TAcquisitionFramework.get_user_af(user=user, only_query=True)
        afuser = TAcquisitionFramework.get_user_af(user=user, only_user=True)
        afdefault = TAcquisitionFramework.get_user_af(user=user)

        assert isinstance(afquery, Select)
        assert isinstance(afuser, list)
        assert len(afuser) == 6
        assert isinstance(afdefault, list)
        assert len(afdefault) >= 1

    def test_actor(self, users):
        user = users["user"]

        empty = CorDatasetActor(role=None, organism=None)
        roleonly = CorDatasetActor(role=user, organism=None)
        organismonly = CorDatasetActor(role=None, organism=user.organisme)
        complete = CorDatasetActor(role=user, organism=user.organisme)

        assert not empty.actor
        assert roleonly.actor == user
        assert organismonly.actor == user.organisme
        assert complete.actor == user

    def test_close_acquisition_framework_no_data(self, users, acquisition_frameworks):
        set_logged_user(self.client, users["user"])

        af = acquisition_frameworks["own_af"]
        response = self.client.post(
            url_for(
                "gn_meta.close_acquisition_framework",
                af_id=af.id_acquisition_framework,
            )
        )
        assert response.status_code == Conflict.code, response.json

    def test_close_acquisition_framework_with_data(
        self, users, acquisition_frameworks, synthese_data
    ):
        set_logged_user(self.client, users["stranger_user"])
        af = acquisition_frameworks["af_1"]
        response = self.client.post(
            url_for(
                "gn_meta.close_acquisition_framework",
                af_id=af.id_acquisition_framework,
            )
        )
        assert response.status_code == 200, response.json

    def test_close_acquisition_frameworks_extended(
        self, app, users, acquisition_frameworks, synthese_data
    ):
        """
        We test if the mechanism of extension of acquisition framework publication works
        """
        # We use mock as extended function so we can keep track wether it's called
        mocked_extended_close = MagicMock()
        route_name = "test.extended_af_close"
        app.config["METADATA"]["EXTENDED_AF_PUBLISH_ROUTE_NAME"] = route_name
        app.view_functions[route_name] = mocked_extended_close
        set_logged_user(self.client, users["stranger_user"])
        af = acquisition_frameworks["af_1"]
        response = self.client.post(
            url_for(
                "gn_meta.close_acquisition_framework",
                af_id=af.id_acquisition_framework,
            )
        )
        mocked_extended_close.assert_called_once()
        assert response.status_code == 200, response.json
        assert af.opened == False

    def test_close_acquisition_frameworks_extended_with_exception(
        self, app, users, acquisition_frameworks, synthese_data
    ):
        """
        We test if when an error occur in the extended af closing, the af stay opened.
        """

        def mocked_close(_=None):
            raise GeoNatureError()

        route_name = "test.extended_af_close"
        app.config["METADATA"]["EXTENDED_AF_PUBLISH_ROUTE_NAME"] = route_name
        app.view_functions[route_name] = mocked_close
        set_logged_user(self.client, users["stranger_user"])
        af = acquisition_frameworks["af_1"]
        response = self.client.post(
            url_for(
                "gn_meta.close_acquisition_framework",
                af_id=af.id_acquisition_framework,
            )
        )
        assert response.status_code == 500, response.json
        assert af.opened == True

    def test_open_acquisition_framework(
        self, app, users, acquisition_frameworks, datasets, monkeypatch
    ):
        """
        Test opening an acquisition framework
        """
        monkeypatch.setitem(app.config["METADATA"], "AF_OPENABLE", True)
        set_logged_user(self.client, users["stranger_user"])
        af = acquisition_frameworks["af_1"]
        af.opened = False
        db.session.commit()

        response = self.client.post(
            url_for(
                "gn_meta.open_acquisition_framework",
                af_id=af.id_acquisition_framework,
            )
        )

        assert response.status_code == 200
        af_updated = db.session.get(TAcquisitionFramework, af.id_acquisition_framework)
        assert af_updated.opened is True

    def test_open_acquisition_framework_not_openable(
        self, app, users, acquisition_frameworks, monkeypatch
    ):
        """
        Test opening an acquisition framework when AF_OPENABLE is False
        """
        set_logged_user(self.client, users["stranger_user"])
        af = acquisition_frameworks["af_1"]
        af.opened = False
        db.session.commit()
        monkeypatch.setitem(app.config["METADATA"], "AF_OPENABLE", False)
        response = self.client.post(
            url_for(
                "gn_meta.open_acquisition_framework",
                af_id=af.id_acquisition_framework,
            )
        )
        assert response.status_code == 500

    def test_close_acquisition_framework_forbidden(
        self, users, acquisition_frameworks, datasets, synthese_data
    ):
        """
        A user without instance permission on the AF cannot close it
        """
        set_logged_user(self.client, users["self_user"])
        af = acquisition_frameworks["af_1"]
        response = self.client.post(
            url_for(
                "gn_meta.close_acquisition_framework",
                af_id=af.id_acquisition_framework,
            )
        )
        assert response.status_code == Forbidden.code, response.json
        assert af.opened == True
        assert datasets["belong_af_1"].active == True

    def test_open_acquisition_framework_forbidden(
        self, app, users, acquisition_frameworks, monkeypatch
    ):
        """
        A user without instance permission on the AF cannot open it
        """
        monkeypatch.setitem(app.config["METADATA"], "AF_OPENABLE", True)
        set_logged_user(self.client, users["self_user"])
        af = acquisition_frameworks["af_1"]
        af.opened = False
        db.session.commit()
        response = self.client.post(
            url_for(
                "gn_meta.open_acquisition_framework",
                af_id=af.id_acquisition_framework,
            )
        )
        assert response.status_code == Forbidden.code, response.json
        assert af.opened == False

    def test_close_open_acquisition_framework_get_not_allowed(self, users, acquisition_frameworks):
        set_logged_user(self.client, users["admin_user"])
        af = acquisition_frameworks["af_1"]
        for endpoint in [
            "gn_meta.close_acquisition_framework",
            "gn_meta.open_acquisition_framework",
        ]:
            response = self.client.get(url_for(endpoint, af_id=af.id_acquisition_framework))
            assert response.status_code == MethodNotAllowed.code


@pytest.mark.usefixtures("client_class", "users", "datasets", "acquisition_frameworks")
class TestRepository:
    def test_cruved_ds_filter(self, users, datasets):
        with pytest.raises(Unauthorized):
            cruved_ds_filter(None, None, 0)

        # Has access to every dataset (scope 3 == superuser)
        assert cruved_ds_filter(None, None, 3)

        # Access to a dataset of its organism
        assert cruved_ds_filter(datasets["associate_dataset"], users["self_user"], 2)
        # Access to its own dataset
        assert cruved_ds_filter(datasets["associate_dataset"], users["associate_user"], 1)

        # Not access to a dataset from an other organism
        assert not cruved_ds_filter(datasets["associate_dataset"], users["stranger_user"], 2)
        # Not access to a dataset of its own
        assert not cruved_ds_filter(datasets["associate_dataset"], users["stranger_user"], 1)

    def test_cruved_af_filter(self, acquisition_frameworks, users):
        with pytest.raises(Unauthorized):
            cruved_af_filter(None, None, 0)
        assert cruved_af_filter(None, None, 3)

        # Has access to every af (scope 3 == superuser)
        assert cruved_af_filter(None, None, 3)

        # Access to a af of its organism
        assert cruved_af_filter(acquisition_frameworks["associate_af"], users["self_user"], 2)
        # Access to its own af
        assert cruved_af_filter(acquisition_frameworks["own_af"], users["user"], 1)

        # Not access to a af from an other organism
        assert not cruved_af_filter(
            acquisition_frameworks["associate_af"], users["stranger_user"], 2
        )
        # Not access to a af of its own
        assert not cruved_af_filter(
            acquisition_frameworks["associate_af"], users["stranger_user"], 1
        )


@pytest.mark.usefixtures(
    "client_class", "temporary_transaction", "users", "acquisition_frameworks", "datasets"
)
class TestMetadataSearchFilters:
    """
    Quick search (`search`) and filters (`name`, `uuid`, `date`, `person`, `organism`), flat when
    they apply to the acquisition frameworks, nested under `datasets` when they apply to datasets.
    """

    AF_NAMES = ("af_1", "af_2", "af_3", "own_af", "stranger_af")
    DS_NAMES = ("belong_af_1", "belong_af_2", "own_dataset", "stranger_dataset")

    @pytest.fixture
    def actors_and_dates(self, users, acquisition_frameworks, datasets):
        from pypnnomenclature.models import BibNomenclaturesTypes, TNomenclatures

        role = db.session.execute(
            select(TNomenclatures)
            .join(BibNomenclaturesTypes, TNomenclatures.id_type == BibNomenclaturesTypes.id_type)
            .where(
                TNomenclatures.mnemonique == "Contact principal",
                BibNomenclaturesTypes.mnemonique == "ROLE_ACTEUR",
            )
        ).scalar_one()
        with db.session.begin_nested():
            acquisition_frameworks["af_2"].acquisition_framework_start_date = datetime.date(
                2001, 2, 3
            )
            acquisition_frameworks["af_3"].cor_af_actor.append(
                CorAcquisitionFrameworkActor(role=users["self_user"], nomenclature_actor_role=role)
            )
            datasets["belong_af_1"].cor_dataset_actor.append(
                CorDatasetActor(role=users["stranger_user"], nomenclature_actor_role=role)
            )
            db.session.flush()

    def search_afs(self, users, acquisition_frameworks, payload):
        """names of the tested AFs returned by the AF list route"""
        set_logged_user(self.client, users["admin_user"])
        response = self.client.post(url_for("gn_meta.get_acquisition_frameworks"), json=payload)
        assert response.status_code == 200
        ids = {af["id_acquisition_framework"] for af in response.json["items"]}
        return {
            name
            for name in self.AF_NAMES
            if acquisition_frameworks[name].id_acquisition_framework in ids
        }

    def search_datasets(self, users, datasets, payload):
        """names of the tested datasets returned by the dataset list route"""
        set_logged_user(self.client, users["admin_user"])
        response = self.client.post(url_for("gn_meta.get_datasets"), json=payload)
        assert response.status_code == 200
        ids = {ds["id_dataset"] for ds in response.json}
        return {name for name in self.DS_NAMES if datasets[name].id_dataset in ids}

    # --- filters applying to the acquisition frameworks (flat)

    def test_af_name(self, users, acquisition_frameworks):
        search = lambda name: self.search_afs(users, acquisition_frameworks, {"name": name})
        assert search("af_1") == {"af_1"}
        assert search("AF_") >= {"af_1", "af_2", "af_3"}
        assert search("no af has this name") == set()

    def test_af_uuid(self, users, acquisition_frameworks):
        uuid = str(acquisition_frameworks["af_2"].unique_acquisition_framework_id)
        assert self.search_afs(users, acquisition_frameworks, {"uuid": uuid}) == {"af_2"}

    def test_af_date(self, users, acquisition_frameworks, actors_and_dates):
        date = {"year": 2001, "month": 2, "day": 3}
        assert self.search_afs(users, acquisition_frameworks, {"date": date}) == {"af_2"}

    def test_af_date_period(self, users, acquisition_frameworks, actors_and_dates):
        search = lambda payload: self.search_afs(users, acquisition_frameworks, payload)
        day = lambda month, day: {"year": 2001, "month": month, "day": day}
        # bounds are inclusive
        assert search({"date_min": day(1, 1), "date_max": day(2, 3)}) == {"af_2"}
        assert search({"date_min": day(2, 3), "date_max": day(12, 31)}) == {"af_2"}
        assert search({"date_min": day(2, 4), "date_max": day(12, 31)}) == set()
        # a single bound is an open period
        assert "af_2" in search({"date_min": day(2, 3)})
        assert "af_2" not in search({"date_min": day(2, 4)})
        assert search({"date_max": day(2, 3)}) == {"af_2"}

    def test_af_date_period_invalid(self, users, acquisition_frameworks):
        set_logged_user(self.client, users["admin_user"])
        payload = {"date_min": {"year": 2001, "month": 13, "day": 1}}
        response = self.client.post(url_for("gn_meta.get_acquisition_frameworks"), json=payload)
        assert response.status_code == 400

    def test_af_person(self, users, acquisition_frameworks, actors_and_dates):
        person = users["self_user"].id_role
        assert self.search_afs(users, acquisition_frameworks, {"person": person}) == {"af_3"}
        # the actor of a dataset is not an actor of its AF
        person = users["stranger_user"].id_role
        assert self.search_afs(users, acquisition_frameworks, {"person": person}) == set()

    def test_af_organism(self, users, acquisition_frameworks):
        organism = users["user"].organisme.id_organisme
        found = self.search_afs(users, acquisition_frameworks, {"organism": organism})
        assert "own_af" in found
        assert not found & {"af_1", "af_2", "af_3", "stranger_af"}

    # --- filters applying to the datasets (nested)

    def test_ds_name(self, users, acquisition_frameworks, datasets):
        search = lambda name: self.search_afs(
            users, acquisition_frameworks, {"datasets": {"name": name}}
        )
        assert search("belong_af_1") == {"af_1"}
        assert search("no dataset has this name") == set()

    def test_ds_uuid(self, users, acquisition_frameworks, datasets):
        uuid = str(datasets["belong_af_2"].unique_dataset_id)
        payload = {"datasets": {"uuid": uuid}}
        assert self.search_afs(users, acquisition_frameworks, payload) == {"af_2"}

    def test_ds_date(self, users, acquisition_frameworks, datasets):
        """The creation date is set by the database, other datasets may share it"""
        created = datasets["belong_af_1"].meta_create_date
        date = {"year": created.year, "month": created.month, "day": created.day}
        found = self.search_afs(users, acquisition_frameworks, {"datasets": {"date": date}})
        assert "af_1" in found
        other = {"year": created.year - 1, "month": created.month, "day": 1}
        assert (
            self.search_afs(users, acquisition_frameworks, {"datasets": {"date": other}}) == set()
        )

    def test_ds_person(self, users, acquisition_frameworks, actors_and_dates):
        person = users["stranger_user"].id_role
        payload = {"datasets": {"person": person}}
        assert self.search_afs(users, acquisition_frameworks, payload) == {"af_1"}
        # the actor of an AF is not an actor of its datasets
        payload = {"datasets": {"person": users["self_user"].id_role}}
        assert self.search_afs(users, acquisition_frameworks, payload) == set()

    def test_ds_organism(self, users, acquisition_frameworks, datasets):
        """own_dataset and its siblings have actors of the users' organism, belong_af_* have none"""
        organism = users["user"].organisme.id_organisme
        payload = {"datasets": {"organism": organism}}
        found = self.search_afs(users, acquisition_frameworks, payload)
        assert not found & {"af_1", "af_2", "af_3"}

    def test_ds_filters_are_combined(self, users, acquisition_frameworks, actors_and_dates):
        person = users["stranger_user"].id_role
        criteria = {"name": "belong_af_1", "person": person}
        payload = {"datasets": criteria}
        assert self.search_afs(users, acquisition_frameworks, payload) == {"af_1"}
        criteria = {"name": "belong_af_2", "person": person}
        assert self.search_afs(users, acquisition_frameworks, {"datasets": criteria}) == set()

    # --- quick search

    def test_quick_search_name(self, users, acquisition_frameworks):
        search = lambda text: self.search_afs(users, acquisition_frameworks, {"search": text})
        assert "af_1" in search("af_1")
        # prefix of the last word, insensitive to the case
        assert "own_af" in search("OWN_a")

    def test_quick_search_dataset_name(self, users, acquisition_frameworks):
        found = self.search_afs(users, acquisition_frameworks, {"search": "belong_af_2"})
        assert "af_2" in found

    def test_quick_search_creator_and_organism(self, users, acquisition_frameworks):
        search = lambda text: self.search_afs(users, acquisition_frameworks, {"search": text})
        assert "own_af" in search("bobby bob")
        assert "own_af" in search(users["user"].organisme.nom_organisme)

    def test_quick_search_uuid_with_dashes(self, users, acquisition_frameworks):
        """Dashes must not split the UUID: here the second group is read as a negative number"""
        af = acquisition_frameworks["af_1"]
        af.unique_acquisition_framework_id = uuid.UUID("9409111b-4783-426f-9c57-1083718292a5")
        db.session.flush()
        for term in (
            "9409",
            "9409111B-4783",
            "9409111b-4783-426f-9c57",
            str(af.unique_acquisition_framework_id),
        ):
            found = self.search_afs(users, acquisition_frameworks, {"search": term})
            assert "af_1" in found, term

    def test_quick_search_name_with_dash(self, users, acquisition_frameworks):
        """ "CA-2020" is read as the words "ca" and "-2020" without care"""
        acquisition_frameworks["af_1"].acquisition_framework_name = "CA-2020 filtertest"
        db.session.flush()
        for term in ("CA", "CA-", "CA-2020", "ca-2020 filter", "2020"):
            found = self.search_afs(users, acquisition_frameworks, {"search": term})
            assert "af_1" in found, term

    def test_quick_search_words_are_not_all_prefixes(self, users, acquisition_frameworks):
        """Only the last word is a prefix: "ca-1" must not match "carto" and a UUID "1..." """
        acquisition_frameworks["af_1"].acquisition_framework_name = "Carto habitats"
        db.session.flush()
        search = lambda text: self.search_afs(users, acquisition_frameworks, {"search": text})
        assert "af_1" not in search("ca-1")
        assert "af_1" in search("carto hab")

    def test_quick_search_and_filters_are_combined(self, users, acquisition_frameworks):
        payload = {"search": "af_", "datasets": {"name": "belong_af_1"}}
        assert "af_1" in self.search_afs(users, acquisition_frameworks, payload)
        payload = {"search": "af_2", "datasets": {"name": "belong_af_1"}}
        assert self.search_afs(users, acquisition_frameworks, payload) == set()
        payload = {"search": "af_1", "name": "af_2"}
        assert self.search_afs(users, acquisition_frameworks, payload) == set()

    # --- dataset route (list of the datasets of an AF)

    def test_dataset_route(self, users, datasets, actors_and_dates):
        search = lambda payload: self.search_datasets(users, datasets, payload)
        ds = datasets["belong_af_1"]
        assert search({"name": "belong_af_1"}) == {"belong_af_1"}
        assert search({"uuid": str(ds.unique_dataset_id)}) == {"belong_af_1"}
        assert search({"person": users["stranger_user"].id_role}) == {"belong_af_1"}
        organism = users["user"].organisme.id_organisme
        found = search({"organism": organism})
        assert "own_dataset" in found and not found & {"belong_af_1", "belong_af_2"}
        created = ds.meta_create_date
        date = {"year": created.year, "month": created.month, "day": created.day}
        assert "belong_af_1" in search({"date": date})
        assert search({"date": {"year": created.year - 1, "month": 1, "day": 1}}) == set()
        today = {"year": created.year, "month": created.month, "day": created.day}
        assert "belong_af_1" in search({"date_min": today, "date_max": today})
        assert search({"date_max": {"year": created.year - 1, "month": 1, "day": 1}}) == set()
        assert "belong_af_1" in search({"search": "belong_af_1"})

    def test_dataset_route_lists_the_datasets_of_an_af_matching_the_search(
        self, users, acquisition_frameworks, datasets
    ):
        """expanding an AF found by its own name still lists its datasets"""
        payload = {
            "search": "af_2",
            "id_acquisition_frameworks": [acquisition_frameworks["af_2"].id_acquisition_framework],
        }
        assert "belong_af_2" in self.search_datasets(users, datasets, payload)
