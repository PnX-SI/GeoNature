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
