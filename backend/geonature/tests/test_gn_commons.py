from pathlib import Path
import tempfile

import pytest
import json
from flask import url_for
from geoalchemy2.elements import WKTElement
from PIL import Image
from pypnnomenclature.models import BibNomenclaturesTypes, TNomenclatures
from sqlalchemy import func
from werkzeug.exceptions import Conflict, Forbidden, NotFound, Unauthorized

from geonature.core.gn_commons.admin import BibFieldAdmin
from geonature.core.gn_commons.models import TAdditionalFields, TMedias, TPlaces, BibTablesLocation
from geonature.core.gn_commons.models.base import TModules, TParameters, BibWidgets
from geonature.core.gn_commons.repositories import TMediaRepository
from geonature.core.gn_commons.tasks import clean_attachments
from geonature.core.gn_permissions.models import PermObject
from geonature.utils.env import db
from geonature.utils.errors import GeoNatureError

from .fixtures import *
from .utils import set_logged_user


@pytest.fixture(scope="function")
def place(users):
    place = TPlaces(place_name="test", role=users["user"])
    with db.session.begin_nested():
        db.session.add(place)
    return place


@pytest.fixture(scope="function")
def additional_field(app, datasets):
    module = TModules.query.filter(TModules.module_code == "SYNTHESE").one()
    obj = PermObject.query.filter(PermObject.code_object == "ALL").one()
    datasets = list(datasets.values())
    additional_field = TAdditionalFields(
        field_name="test",
        field_label="Un label",
        required=True,
        description="une descrption",
        quantitative=False,
        unity="degré C",
        field_values=["la", "li"],
        id_widget=1,
        modules=[module],
        objects=[obj],
        datasets=datasets,
    )
    with db.session.begin_nested():
        db.session.add(additional_field)
    return additional_field


@pytest.fixture(scope="function")
def parameter(users):
    param = TParameters(
        id_organism=users["self_user"].organisme.id_organisme,
        parameter_name="MyTestParameter",
        parameter_desc="TestDesc",
        parameter_value=4,
        parameter_extra_value=12,
    )

    with db.session.begin_nested():
        db.session.add(param)
    return param


@pytest.fixture(scope="function")
def nonexistent_media():
    # media can be None
    return (db.session.query(func.max(TMedias.id_media)).scalar() or 0) + 1


@pytest.fixture(scope="function")
def media_repository(medium):
    return TMediaRepository(id_media=medium.id_media)


@pytest.mark.usefixtures("client_class", "temporary_transaction")
class TestMedia:
    def test_get_medias(self, medium):
        response = self.client.get(
            url_for("gn_commons.get_medias", uuid_attached_row=str(medium.uuid_attached_row))
        )

        assert response.status_code == 200
        assert response.json[0]["id_media"] == medium.id_media

    def test_get_media(self, medium):
        response = self.client.get(url_for("gn_commons.get_media", id_media=medium.id_media))

        assert response.status_code == 200
        resp_json = response.json
        assert resp_json["id_media"] == medium.id_media
        assert resp_json["title_fr"] == medium.title_fr
        assert resp_json["unique_id_media"] == str(medium.unique_id_media)

    def test_delete_media(self, app, medium):
        id_media = int(medium.id_media)

        response = self.client.delete(url_for("gn_commons.delete_media", id_media=id_media))

        assert response.status_code == 200
        assert response.json["resp"] == f"media {id_media} deleted"

        # Re-move file in other side to does not break TemporaryFile context manager
        media_path = medium.base_dir() / medium.media_path
        media_path.rename(media_path.parent / media_path.name[len("deleted_") :])

    def test_create_media(self, medium):
        title_fr = "test_test"
        image = Image.new("RGBA", size=(1, 1), color=(155, 0, 0))
        with tempfile.NamedTemporaryFile() as f:
            image.save(f, "png")
            payload = {
                "title_fr": title_fr,
                "media_path": f.name,
                "id_nomenclature_media_type": medium.id_nomenclature_media_type,
                "id_table_location": medium.id_table_location,
            }

            response = self.client.post(url_for("gn_commons.insert_or_update_media"), json=payload)

        assert response.status_code == 200
        assert response.json["title_fr"] == title_fr

    def test_update_media(self, medium):
        title_fr = "New title"
        author = "New author"
        payload = {
            "title_fr": title_fr,
            "author": author,
            "media_path": medium.media_path,
            "id_nomenclature_media_type": medium.id_nomenclature_media_type,
        }

        response = self.client.put(
            url_for("gn_commons.delete_media", id_media=medium.id_media), json=payload
        )
        assert response.status_code == 200
        resp_json = response.json
        assert resp_json["title_fr"] == title_fr
        assert resp_json["author"] == author

    def test_update_media_error(self, medium):
        payload = {
            "media_path": "",
        }

        response = self.client.put(
            url_for("gn_commons.delete_media", id_media=medium.id_media), json=payload
        )
        # FIXME: should not return 500
        assert response.status_code == 500

    def test_get_media_thumb(self, medium):
        response = self.client.get(
            url_for("gn_commons.get_media_thumb", id_media=medium.id_media, size=300)
        )

        # Redirection
        assert response.status_code == 302

    def test_get_media_thumb_not_found(self, nonexistent_media):
        response = self.client.get(
            url_for("gn_commons.get_media_thumb", id_media=nonexistent_media, size=300)
        )

        assert response.status_code == 404
        assert response.json["description"] == "Media introuvable"


@pytest.mark.usefixtures("client_class", "temporary_transaction")
class TestTMediaRepository:
    def test__init__(self, medium, media_repository):
        assert media_repository.media.id_media == medium.id_media

    def test_persist_media_db_error_not_null(self):
        media = TMediaRepository()

        with pytest.raises(Exception) as e:
            media._persist_media_db()

        assert "NotNullViolation" in str(e.value)

    def test_persist_media_error_exists(self, media_repository):
        media_repository.media.id_nomenclature_media_type = 0

        with pytest.raises(Exception) as e:
            media_repository._persist_media_db()

        assert "type didn't match" in str(e.value)

    def test_header_content_type(self, medium, media_repository):
        media_repository.data["id_nomenclature_media_type"] = medium.id_nomenclature_media_type

        test = media_repository.test_header_content_type("image")

        assert test

    def test_test_url_none(self, media_repository):
        media_repository.data["media_url"] = None
        test = media_repository.test_url()

        assert test is None

    @pytest.mark.skip(reason="TODO: mock external request")
    def test_test_url(self, medium, media_repository):
        media_repository.data["media_url"] = "https://google.com/"
        media_repository.data["id_nomenclature_media_type"] = medium.id_nomenclature_media_type

        with pytest.raises(GeoNatureError) as e:
            media_repository.test_url()

        assert "Il y a un problème avec l'URL renseignée" in str(e.value)

    @pytest.mark.skip(reason="TODO: mock external request")
    def test_test_url_wrong_url(self, media_repository):
        media_repository.data["media_url"] = "https://google.com/notfound"

        with pytest.raises(GeoNatureError) as e:
            media_repository.test_url()

        assert "la réponse est différente de 200" in str(e.value)

    @pytest.mark.skip(reason="TODO: mock external request")
    def test_test_url_wrong_image_url(self, medium, media_repository):
        media_repository.data["media_url"] = "https://www.youtube.com/watch?v=vRfl0ies5GY"
        media_repository.data["id_nomenclature_media_type"] = medium.id_nomenclature_media_type

        with pytest.raises(GeoNatureError) as e:
            media_repository.test_url()

        assert "le format du lien" in str(e.value)

    @pytest.mark.skip(reason="TODO: mock external request")
    def test_test_url_wrong_video(self, media_repository):
        media_repository.data["media_url"] = "https://www.google.com/"
        photo_type = TNomenclatures.query.filter(
            BibNomenclaturesTypes.mnemonique == "TYPE_MEDIA",
            TNomenclatures.mnemonique == "Vidéo Youtube",
        ).one()
        media_repository.data["id_nomenclature_media_type"] = photo_type.id_nomenclature

        with pytest.raises(GeoNatureError) as e:
            media_repository.test_url()

        assert "l'URL n est pas valide pour le type de média choisi" in str(e.value)


@pytest.mark.parametrize(
    "test_media_type,test_media_url,test_wrong_url",
    [
        ("Vidéo Youtube", "http://youtube.com/", "http://you.com/"),
        ("Vidéo Dailymotion", "http://dailymotion.com/", "http://daily.com/"),
        ("Vidéo Vimeo", "http://vimeo.com/", "http://vim.org/"),
    ],
)
class TestTMediaRepositoryVideoLink:
    def test_test_video_link(self, medium, test_media_type, test_media_url, test_wrong_url):
        # Need to create a video link
        photo_type = TNomenclatures.query.filter(
            BibNomenclaturesTypes.mnemonique == "TYPE_MEDIA",
            TNomenclatures.mnemonique == test_media_type,
        ).one()
        media = TMediaRepository(id_media=medium.id_media)
        media.data["id_nomenclature_media_type"] = photo_type.id_nomenclature
        media.data["media_url"] = test_media_url

        test = media.test_video_link()

        assert test

    def test_test_video_link_wrong(self, medium, test_media_type, test_media_url, test_wrong_url):
        # Need to create a video link
        photo_type = TNomenclatures.query.filter(
            BibNomenclaturesTypes.mnemonique == "TYPE_MEDIA",
            TNomenclatures.mnemonique == test_media_type,
        ).one()
        media = TMediaRepository(id_media=medium.id_media)
        media.data["id_nomenclature_media_type"] = photo_type.id_nomenclature
        # WRONG URL:
        media.data["media_url"] = test_wrong_url

        test = media.test_video_link()

        assert not test


@pytest.mark.parametrize(
    "test_media_type,test_content_type",
    [
        ("Photo", "wrong"),
        ("Audio", "wrong"),
        ("Vidéo (fichier)", "wrong"),
        ("PDF", "wrong"),
        ("Page web", "wrong"),
    ],
)
class TestTMediaRepositoryHeader:
    def test_header_content_type_wrong(self, medium, test_media_type, test_content_type):
        photo_type = TNomenclatures.query.filter(
            BibNomenclaturesTypes.mnemonique == "TYPE_MEDIA",
            TNomenclatures.mnemonique == test_media_type,
        ).one()
        media = TMediaRepository(id_media=medium.id_media)
        media.data["id_nomenclature_media_type"] = photo_type.id_nomenclature

        test = media.test_header_content_type(test_content_type)

        assert not test


@pytest.mark.usefixtures("client_class", "temporary_transaction")
class TestCommons:
    def test_list_modules(self, users):
        response = self.client.get(url_for("gn_commons.list_modules", exclude="GEONATURE"))
        assert response.status_code == Unauthorized.code

        set_logged_user(self.client, users["noright_user"])
        response = self.client.get(url_for("gn_commons.list_modules", exclude="GEONATURE"))
        assert response.status_code == 200
        assert len(response.json) == 0

        set_logged_user(self.client, users["admin_user"])
        response = self.client.get(url_for("gn_commons.list_modules", exclude="GEONATURE"))
        assert response.status_code == 200
        assert len(response.json) > 0

    def test_list_module_exclude(self, users):
        excluded_module = "GEONATURE"

        set_logged_user(self.client, users["admin_user"])

        response = self.client.get(
            url_for("gn_commons.list_modules"), query_string={"exclude": [excluded_module]}
        )

        assert response.status_code == 200
        assert excluded_module not in [module["module_code"] for module in response.json]

    def test_get_module(self):
        module_code = "GEONATURE"

        response = self.client.get(url_for("gn_commons.get_module", module_code=module_code))

        assert response.status_code == 200
        assert response.json["module_code"] == module_code

    def test_get_parameters_list(self, parameter):
        response = self.client.get(url_for("gn_commons.get_parameters_list"))

        assert response.status_code == 200
        assert isinstance(response.json, list)
        assert parameter.id_parameter in [resp["id_parameter"] for resp in response.json]

    def test_get_parameter(self, parameter):
        response = self.client.get(
            url_for("gn_commons.get_one_parameter", param_name=parameter.parameter_name)
        )

        assert response.status_code == 200
        assert response.json[0]["id_parameter"] == parameter.id_parameter

    def test_list_places(self, place, users):
        response = self.client.get(url_for("gn_commons.list_places"))
        print(response)
        assert response.status_code == Unauthorized.code

        set_logged_user(self.client, users["user"])
        response = self.client.get(url_for("gn_commons.list_places"))
        assert response.status_code == 200
        assert place.id_place in [p["properties"]["id_place"] for p in response.json]

        set_logged_user(self.client, users["associate_user"])
        response = self.client.get(url_for("gn_commons.list_places"))
        assert response.status_code == 200
        assert place.id_place not in [p["properties"]["id_place"] for p in response.json]

    def test_add_place(self, users):
        place = TPlaces(
            place_name="test",
            place_geom=WKTElement("POINT (6.058788299560547 44.740515073054915)", srid=4326),
        )
        geofeature = place.as_geofeature()

        response = self.client.post(url_for("gn_commons.add_place"))
        assert response.status_code == Unauthorized.code

        set_logged_user(self.client, users["user"])
        response = self.client.post(url_for("gn_commons.add_place"), data=geofeature)
        assert response.status_code == 200
        assert db.session.query(
            TPlaces.query.filter_by(
                place_name=place.place_name, id_role=users["user"].id_role
            ).exists()
        ).scalar()

        set_logged_user(self.client, users["user"])
        response = self.client.post(url_for("gn_commons.add_place"), data=geofeature)
        assert response.status_code == Conflict.code

    def test_delete_place(self, place, users):
        unexisting_id = db.session.query(func.max(TPlaces.id_place)).scalar() + 1
        response = self.client.delete(url_for("gn_commons.delete_place", id_place=unexisting_id))
        assert response.status_code == Unauthorized.code

        set_logged_user(self.client, users["associate_user"])
        response = self.client.delete(url_for("gn_commons.delete_place", id_place=unexisting_id))
        assert response.status_code == NotFound.code

        response = self.client.delete(url_for("gn_commons.delete_place", id_place=place.id_place))
        assert response.status_code == Forbidden.code

        set_logged_user(self.client, users["user"])
        response = self.client.delete(url_for("gn_commons.delete_place", id_place=place.id_place))
        assert response.status_code == 204
        assert not db.session.query(
            TPlaces.query.filter_by(id_place=place.id_place).exists()
        ).scalar()

    def test_get_additional_fields(self, datasets, additional_field):
        query_string = {"module_code": "SYNTHESE", "object_code": "ALL"}
        response = self.client.get(
            url_for("gn_commons.get_additional_fields"), query_string=query_string
        )

        assert response.status_code == 200
        data = response.get_json()
        for f in data:
            for m in f["modules"]:
                assert m["module_code"] == "SYNTHESE"
            for o in f["objects"]:
                assert o["code_object"] == "ALL"
            assert {d["id_dataset"] for d in f["datasets"]} == {
                d.id_dataset for d in datasets.values()
            }
        # check mandatory column are here
        addi_one = data[0]
        assert "type_widget" in addi_one
        assert "bib_nomenclature_type" in addi_one

    def test_get_additional_fields_multi_module(self, datasets, additional_field):
        response = self.client.get(
            url_for("gn_commons.get_additional_fields"),
            query_string={"module_code": "GEONATURE,SYNTHESE"},
        )

        for f in response.json:
            for m in f["modules"]:
                assert m["module_code"] == "SYNTHESE"

    def test_get_additional_fields_not_exist_in_module(self):
        response = self.client.get(
            url_for("gn_commons.get_additional_fields"), query_string={"module_code": "VALIDATION"}
        )

        data = response.json
        # TODO: Do better than that:
        assert len(data) == 0

    def test_additional_field_admin(self, app, users, module, perm_object):
        set_logged_user(self.client, users["admin_user"])
        app.config["ADDITIONAL_FIELDS"]["IMPLEMENTED_MODULES"] = [module.module_code]
        app.config["ADDITIONAL_FIELDS"]["IMPLEMENTED_OBJECTS"] = [perm_object.code_object]
        form_values = {
            "field_label": "pytest_valid",
            "field_name": "pytest_valid",
            "module": module.id_module,
            "objects": [perm_object.id_object],
            "type_widget": BibWidgets.query.filter_by(widget_name="select").one().id_widget,
            "field_values": json.dumps([{"label": "un", "value": 1}]),
        }

        req = self.client.post(
            "/admin/tadditionalfields/new/?url=/admin/tadditionalfields/",
            data=form_values,
            content_type="multipart/form-data",
        )
        assert req.status_code == 302
        assert db.session.query(
            db.session.query(TAdditionalFields).filter_by(field_name="pytest_valid").exists()
        ).scalar()

        form_values.update(
            {
                "field_label": "pytest_invvalid",
                "field_name": "pytest_invvalid",
                "field_values": json.dumps([{"not_label": "un", "not_value": 1}]),
            }
        )
        req = self.client.post(
            "/admin/tadditionalfields/new/?url=/admin/tadditionalfields/",
            data=form_values,
            content_type="multipart/form-data",
        )
        assert req.status_code != 302
        assert not db.session.query(
            db.session.query(TAdditionalFields).filter_by(field_name="pytest_invvalid").exists()
        ).scalar()

    def test_get_t_mobile_apps(self):
        response = self.client.get(url_for("gn_commons.get_t_mobile_apps"))

        assert response.status_code == 200
        assert type(response.json) == list

    def test_api_get_id_table_location(self):
        schema = "gn_commons"
        table = "t_medias"
        location = (
            db.session.query(BibTablesLocation)
            .filter(BibTablesLocation.schema_name == schema)
            .filter(BibTablesLocation.table_name == table)
            .one()
        )

        response = self.client.get(
            url_for("gn_commons.api_get_id_table_location", schema_dot_table=f"{schema}.{table}")
        )

        assert response.status_code == 200
        assert response.json == location.id_table_location

    def test_api_get_id_table_location_not_found(self):
        schema = "wrongschema"
        table = "wrongtable"

        response = self.client.get(
            url_for("gn_commons.api_get_id_table_location", schema_dot_table=f"{schema}.{table}")
        )

        assert response.status_code == 204  # No content
        assert response.json is None


@pytest.mark.usefixtures("temporary_transaction")
class TestTasks:
    def test_clean_attachements(self, monkeypatch, celery_eager, medium):
        # Monkey patch the __before_commit_delete not to remove file
        # when deleting the medium, so the clean_attachments can work
        def mock_delete_media(self):
            return None

        monkeypatch.setattr(TMedias, "__before_commit_delete__", mock_delete_media)

        # Remove media to trigger the cleaning
        db.session.delete(medium)
        db.session.commit()

        clean_attachments()

        # File should be removed
        assert not Path(medium.media_path).is_file()
