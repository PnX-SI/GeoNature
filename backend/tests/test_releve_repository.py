import unittest
import pytest

from .bootstrap_test import geonature_app
import datetime
valide_occ_tax_releve = {
    'id_releve_contact' : 1,
    'id_dataset' : 1,
    'id_digitiser' : 1,
    'date_min' : datetime.datetime.now(),
    'date_max' : datetime.datetime.now(),
    'altitude_min' : 1100,
    'altitude_max' : 1200,
    'meta_device_entry' : 'web',
    'deleted' : False,
    'meta_create_date' : datetime.datetime.now(),
    'meta_update_date' : datetime.datetime.now(),
    'comment' : 'test',
    'geom_4326' : 'test',
    'taxons' : 'ablette, lynx',
    'leaflet_popup' : 'test',
    'observateurs' : 'admin',
    'observers' : []
}

user_admin = {
    'id_role': 1,
    'id_organisme': 1,
    'tag_action_code': 'R',
    'tag_object_code': '3',
    'id_application':14
}

user_low = {
    'id_role': 2,
    'id_organisme': 1,
    'tag_action_code': 'R',
    'tag_object_code': '1',
    'id_application':14
}

def test_user_is_allowed(geonature_app):
    from geonature.modules.pr_contact.models import ReleveModel, VReleveList
    from geonature.core.users.models import UserRigth
    user_hight = UserRigth(**user_admin)
    valide_occ_tax_releve['observers'].append(user_hight)
    releveInstance = VReleveList(**valide_occ_tax_releve)
    releve = releveInstance.get_releve_if_allowed(user_hight)
    assert isinstance(releve, VReleveList)


def test_user_cannot_see_releve(geonature_app):
    from geonature.modules.pr_contact.models import ReleveModel, VReleveList
    from geonature.core.users.models import UserRigth
    from geonature.utils.errors import InsufficientRightsError
    user_2 = UserRigth(**user_low)
    releveInstance = VReleveList(**valide_occ_tax_releve)
    with pytest.raises(InsufficientRightsError):
        releveInstance.get_releve_if_allowed(user_2)
