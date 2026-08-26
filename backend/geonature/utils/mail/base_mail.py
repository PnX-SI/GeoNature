from abc import ABC, abstractmethod
from dataclasses import dataclass
from typing import List, Optional, Tuple, Union

Recipient = Union[str, Tuple[str, str]]


@dataclass
class Message:
    subject: str = ""
    recipients: List[Recipient] = None
    body: Optional[str] = None
    html: Optional[str] = None
    sender: Optional[str] = None

    def __post_init__(self):
        if self.recipients is None:
            self.recipients = []


class BaseMail(ABC):

    def __init__(self, app=None):
        if app:
            self.init_app(app)

    @abstractmethod
    def init_app(self, app) -> None: ...

    def connect(self):
        return Connection(self)

    @abstractmethod
    def send(self, message: Message) -> None: ...


class Connection:
    """Context manager compatible avec Flask-Mail."""

    def __init__(self, base: BaseMail):
        self.base = base

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc, tb):
        return False

    def send(self, message: Message):
        return self.base.send(message)
