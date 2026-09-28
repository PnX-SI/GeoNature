from flask import url_for
from pypnnomenclature.models import BibNomenclaturesTypes, TNomenclatures
import sqlalchemy as sa
from geonature.utils.env import db
from pypnusershub.tests.utils import (
    set_logged_user,
    unset_logged_user,
    logged_user,
    logged_user_headers,
)  # Do not remove, used by other test files


def login(client, username="admin", password=None):
    data = {
        "login": username,
        "password": password if password else username,
    }
    response = client.post(url_for("auth.login"), json=data)
    assert response.status_code == 200


def get_id_nomenclature(nomenclature_type_mnemonique, cd_nomenclature):
    return db.session.scalar(
        sa.select(TNomenclatures.id_nomenclature)
        .where(TNomenclatures.cd_nomenclature == cd_nomenclature)
        .where(
            TNomenclatures.nomenclature_type.has(
                BibNomenclaturesTypes.mnemonique == nomenclature_type_mnemonique
            )
        )
    )


def dict2obj(dict_data):

    # checking whether object d is a
    # instance of class list
    if isinstance(dict_data, list):
        dict_data = [dict2obj(x) for x in dict_data]

    # if d is not a instance of dict then
    # directly object is returned
    if not isinstance(dict_data, dict):
        return dict_data

    # declaring a class
    class C:
        def __getitem__(self, item):
            return getattr(self, item)

    # constructor of the class passed to obj
    obj = C()

    for k in dict_data:
        obj.__dict__[k] = dict2obj(dict_data[k])

    return obj


# Keys that must never appear in a user nested in another payload
SENSITIVE_USER_KEYS = frozenset(
    {
        "email",
        "identifiant",
        "remarques",
        "desc_role",
        "api_key",
        "api_secret",
        "champs_addi",
        "pass",
        "pass_plus",
        "_password",
        "_password_plus",
        "password",
    }
)
# Keys that must never appear in an organism nested in another payload
SENSITIVE_ORGANISM_KEYS = frozenset(
    {
        "adresse_organisme",
        "cp_organisme",
        "ville_organisme",
        "tel_organisme",
        "fax_organisme",
        "email_organisme",
        "url_organisme",
        "url_logo",
    }
)


def _is_user_like(obj):
    return isinstance(obj, dict) and ("nom_role" in obj or "prenom_role" in obj)


def _is_organism_like(obj):
    return isinstance(obj, dict) and (
        "nom_organisme" in obj or not SENSITIVE_ORGANISM_KEYS.isdisjoint(obj)
    )


def iter_nested_users_and_organisms(payload, path="$"):
    """
    Walk a JSON payload and yield ``(kind, path, obj)`` for every user-like
    (``kind == "user"``) and organism-like (``kind == "organism"``) dict found.
    """
    if isinstance(payload, dict):
        if _is_user_like(payload):
            yield "user", path, payload
        elif _is_organism_like(payload):
            yield "organism", path, payload
        for key, value in payload.items():
            yield from iter_nested_users_and_organisms(value, f"{path}.{key}")
    elif isinstance(payload, list):
        for i, value in enumerate(payload):
            yield from iter_nested_users_and_organisms(value, f"{path}[{i}]")


def assert_no_user_data_leak(payload, min_users=1):
    """
    Assert that every user nested in ``payload`` only carries minimal user keys
    (``MINIMAL_USER_FIELDS`` + optional ``organisme``), and every organism only carries
    ``MINIMAL_ORGANISM_FIELDS``.

    ``min_users`` guards against the assertion passing vacuously (e.g. if the route stops
    returning users at all).

    Returns the list of ``(kind, path, obj)`` found, for further exact-path assertions.
    """
    from geonature.core.users.schemas import MINIMAL_USER_FIELDS, MINIMAL_ORGANISM_FIELDS

    allowed_user_keys = set(MINIMAL_USER_FIELDS) | {"organisme"}
    found = list(iter_nested_users_and_organisms(payload))
    for kind, path, obj in found:
        if kind == "user":
            assert SENSITIVE_USER_KEYS.isdisjoint(obj), (path, SENSITIVE_USER_KEYS & set(obj))
            assert set(obj) <= allowed_user_keys, (path, set(obj) - allowed_user_keys)
        else:
            assert SENSITIVE_ORGANISM_KEYS.isdisjoint(obj), (
                path,
                SENSITIVE_ORGANISM_KEYS & set(obj),
            )
            assert set(obj) <= set(MINIMAL_ORGANISM_FIELDS), (
                path,
                set(obj) - set(MINIMAL_ORGANISM_FIELDS),
            )
    assert len([f for f in found if f[0] == "user"]) >= min_users, found
    return found
