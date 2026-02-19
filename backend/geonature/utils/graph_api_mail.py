import requests

from geonature.utils.base_mail import BaseMail, Message
from typing import Any, Dict


class GraphAPIMail(BaseMail):

    def __init__(self, app=None):
        self.tenant = None
        self.client_id = None
        self.client_secret = None
        super().__init__(app)

    def init_app(self, app) -> None:
        self.tenant = app.config["GRAPH_API_MAIL_TENANT_ID"]
        self.client_id = app.config["GRAPH_API_MAIL_CLIENT_ID"]
        self.client_secret = app.config["GRAPH_API_MAIL_CLIENT_SECRET"]

    def _get_token(self) -> str:
        url = f"https://login.microsoftonline.com/{self.tenant}/oauth2/v2.0/token"
        data = {
            "client_id": self.client_id,
            "client_secret": self.client_secret,
            "grant_type": "client_credentials",
            "scope": "https://graph.microsoft.com/.default",
        }

        resp = requests.post(
            url,
            data=data,
            headers={"Content-Type": "application/x-www-form-urlencoded"},
            timeout=30,
        )
        if not resp.ok:
            raise RuntimeError(f"Token endpoint error {resp.status_code}: {resp.text}")

        return resp.json()["access_token"]

    def _email_address(self, recipient: Any) -> Dict[str, Dict[str, str]]:
        if isinstance(recipient, (tuple, list)):
            return {"emailAddress": {"address": next((x for x in recipient[:2][::-1] if x), None)}}

        return {"emailAddress": {"address": recipient}}

    def send(self, message: Message) -> None:
        sender = message.sender
        if not sender:
            raise ValueError("No sender defined (message.sender or MAIL_DEFAULT_SENDER).")

        token = self._get_token()

        mail = {
            "message": {
                "subject": message.subject,
                "body": {
                    "contentType": "HTML" if message.html else "Text",
                    "content": message.html if message.html else (message.body or ""),
                },
                "toRecipients": [self._email_address(r) for r in message.recipients],
            },
            "saveToSentItems": True,
        }

        url = f"https://graph.microsoft.com/v1.0/users/{sender}/sendMail"
        resp = requests.post(
            url,
            json=mail,
            headers={"Authorization": f"Bearer {token}"},
            timeout=30,
        )
        if not resp.ok:
            raise RuntimeError(f"Graph API error {resp.status_code}: {resp.text}")
