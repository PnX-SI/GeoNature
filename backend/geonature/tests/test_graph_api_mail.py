from types import SimpleNamespace
from unittest.mock import MagicMock, patch

import pytest
from flask import Flask

from geonature.utils.mail import utilsmails
from geonature.utils.mail.base_mail import Message
from geonature.utils.mail.graph_api_mail import GraphAPIMail


def make_mailer():
    mailer = GraphAPIMail()
    mailer.init_app(
        SimpleNamespace(
            config={
                "GRAPH_API_MAIL_TENANT_ID": "tenant-id",
                "GRAPH_API_MAIL_CLIENT_ID": "client-id",
                "GRAPH_API_MAIL_CLIENT_SECRET": "client-secret",
            }
        )
    )
    return mailer


def make_response(ok=True, status_code=200, json_data=None, text=""):
    resp = MagicMock()
    resp.ok = ok
    resp.status_code = status_code
    resp.text = text
    resp.json.return_value = json_data or {}
    return resp


class TestGraphAPIMailInitApp:
    def test_init_app_reads_config(self):
        mailer = make_mailer()
        assert mailer.tenant == "tenant-id"
        assert mailer.client_id == "client-id"
        assert mailer.client_secret == "client-secret"

    def test_init_app_missing_key_raises(self):
        mailer = GraphAPIMail()
        with pytest.raises(KeyError):
            mailer.init_app(SimpleNamespace(config={}))


class TestGraphAPIMailGetToken:
    @patch("geonature.utils.mail.graph_api_mail.requests.post")
    def test_get_token_success(self, mock_post):
        mock_post.return_value = make_response(json_data={"access_token": "abc123"})
        mailer = make_mailer()

        token = mailer._get_token()

        assert token == "abc123"
        url, kwargs = mock_post.call_args
        assert url[0] == "https://login.microsoftonline.com/tenant-id/oauth2/v2.0/token"
        assert kwargs["data"] == {
            "client_id": "client-id",
            "client_secret": "client-secret",
            "grant_type": "client_credentials",
            "scope": "https://graph.microsoft.com/.default",
        }

    @patch("geonature.utils.mail.graph_api_mail.requests.post")
    def test_get_token_error_raises(self, mock_post):
        mock_post.return_value = make_response(ok=False, status_code=401, text="invalid_client")
        mailer = make_mailer()

        with pytest.raises(RuntimeError, match="401"):
            mailer._get_token()


class TestGraphAPIMailEmailAddress:
    def test_plain_string(self):
        mailer = GraphAPIMail()
        assert mailer._email_address("a@b.com") == {"emailAddress": {"address": "a@b.com"}}

    def test_name_email_tuple(self):
        mailer = GraphAPIMail()
        result = mailer._email_address(("Carl von LINNÉ", "c.linnaeus@linnaeus.se"))
        assert result == {"emailAddress": {"address": "c.linnaeus@linnaeus.se"}}

    def test_tuple_with_empty_name(self):
        mailer = GraphAPIMail()
        result = mailer._email_address(("", "a@b.com"))
        assert result == {"emailAddress": {"address": "a@b.com"}}

    def test_tuple_with_empty_email_falls_back_to_first_element(self):
        mailer = GraphAPIMail()
        result = mailer._email_address(("a@b.com", ""))
        assert result == {"emailAddress": {"address": "a@b.com"}}

    def test_empty_tuple_yields_none(self):
        mailer = GraphAPIMail()
        result = mailer._email_address(("", ""))
        assert result == {"emailAddress": {"address": None}}


class TestGraphAPIMailSend:
    def test_send_without_sender_raises(self):
        mailer = make_mailer()
        message = Message(subject="hello", recipients=["a@b.com"], html="<p>hi</p>", sender=None)

        with pytest.raises(ValueError):
            mailer.send(message)

    @patch("geonature.utils.mail.graph_api_mail.requests.post")
    def test_send_html_message(self, mock_post):
        mailer = make_mailer()
        mailer._get_token = MagicMock(return_value="tok123")
        mock_post.return_value = make_response()
        message = Message(
            subject="hello",
            recipients=["a@b.com", ("Carl von LINNÉ", "c.linnaeus@linnaeus.se")],
            html="<p>hi</p>",
            sender="sender@geonature.fr",
        )

        mailer.send(message)

        url, kwargs = mock_post.call_args
        assert url[0] == "https://graph.microsoft.com/v1.0/users/sender@geonature.fr/sendMail"
        assert kwargs["headers"] == {"Authorization": "Bearer tok123"}
        payload = kwargs["json"]
        assert payload["message"]["subject"] == "hello"
        assert payload["message"]["body"] == {"contentType": "HTML", "content": "<p>hi</p>"}
        assert payload["message"]["toRecipients"] == [
            {"emailAddress": {"address": "a@b.com"}},
            {"emailAddress": {"address": "c.linnaeus@linnaeus.se"}},
        ]
        assert payload["saveToSentItems"] is True

    @patch("geonature.utils.mail.graph_api_mail.requests.post")
    def test_send_text_only_message(self, mock_post):
        mailer = make_mailer()
        mailer._get_token = MagicMock(return_value="tok123")
        mock_post.return_value = make_response()
        message = Message(
            subject="hello",
            recipients=["a@b.com"],
            body="plain text",
            sender="sender@geonature.fr",
        )

        mailer.send(message)

        payload = mock_post.call_args.kwargs["json"]
        assert payload["message"]["body"] == {"contentType": "Text", "content": "plain text"}

    @patch("geonature.utils.mail.graph_api_mail.requests.post")
    def test_send_error_raises(self, mock_post):
        mailer = make_mailer()
        mailer._get_token = MagicMock(return_value="tok123")
        mock_post.return_value = make_response(ok=False, status_code=500, text="boom")
        message = Message(
            subject="hello", recipients=["a@b.com"], html="<p>hi</p>", sender="sender@geonature.fr"
        )

        with pytest.raises(RuntimeError, match="500"):
            mailer.send(message)


class TestInitMailer:
    def test_init_mailer_selects_graph_api_mail_when_configured(self):
        app = Flask(__name__)
        app.config["GRAPH_API_MAIL_TENANT_ID"] = "tenant-id"
        app.config["GRAPH_API_MAIL_CLIENT_ID"] = "client-id"
        app.config["GRAPH_API_MAIL_CLIENT_SECRET"] = "client-secret"

        utilsmails.init_mailer(app)

        assert isinstance(utilsmails.MAIL, GraphAPIMail)

    def test_init_mailer_selects_flask_mail_by_default(self):
        from flask_mail import Mail

        app = Flask(__name__)

        utilsmails.init_mailer(app)

        assert isinstance(utilsmails.MAIL, Mail)
