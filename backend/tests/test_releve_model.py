import pytest
import requests

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
    'id_organisme': 2,
    'tag_action_code': 'R',
    'tag_object_code': '3',
    'id_application':14
}

# has only right on dataset 2
user_agent = {
    'id_role': 2,
    'id_organisme': -1,
    'tag_action_code': 'R',
    'tag_object_code': '2',
    'id_application':14
}

# can see only its data
user_low = {
    'id_role': 125,
    'id_organisme': -1,
    'tag_action_code': 'R',
    'tag_object_code': '1',
    'id_application':14
}

### Test on abstract class ReleveModel and its methods

import sys
import os
d = os.path.join(os.path.dirname('.'), '../../contrib')
sys.path.append(d)

class TestGetReleveIfAllowed:
    # Test of the releve model
    def test_user_is_observers(self, geonature_app):
        """
            user is observer of the releve
            Must be True
        """

        from occtax.backend.models import ReleveModel, VReleveList
        from geonature.core.users.models import UserRigth
        user_hight = UserRigth(**user_admin)
        valide_occ_tax_releve['observers'].append(user_hight)
        releveInstance = VReleveList(**valide_occ_tax_releve)
        releve = releveInstance.get_releve_if_allowed(user_hight)
        assert isinstance(releve, VReleveList)

    def test_user_is_in_dataset(self, geonature_app):
        """
            user is not observer but can see its organism data
            via rigth in dataset number 1
            Must be True
        """
        from occtax.backend.models import ReleveModel, VReleveList
        from geonature.core.users.models import UserRigth

        user_hight = UserRigth(**user_admin)
        valide_occ_tax_releve['id_digitiser'] = None
        releveInstance = VReleveList(**valide_occ_tax_releve)
        releve = releveInstance.get_releve_if_allowed(user_hight)
        assert isinstance(releve, VReleveList)

    def test_user_not_in_dataset(self, geonature_app):
        """
            user is not observer of the releve cannot see dataset
            number 1
            Must return an InsufficientRightsError
        """
        from occtax.backend.models import ReleveModel, VReleveList
        from geonature.core.users.models import UserRigth
        from geonature.utils.errors import InsufficientRightsError

        _user_agent = UserRigth(**user_agent)
        releveInstance = VReleveList(**valide_occ_tax_releve)
        with pytest.raises(InsufficientRightsError):
            releveInstance.get_releve_if_allowed(_user_agent)


    def test_user_not_observer(self, geonature_app):
        """
            user is not observer of the releve and have low right
            Must return an InsufficientRightsError
        """
        from occtax.backend.models import ReleveModel, VReleveList
        from geonature.core.users.models import UserRigth
        from geonature.utils.errors import InsufficientRightsError

        user_2 = UserRigth(**user_low)
        releveInstance = VReleveList(**valide_occ_tax_releve)
        with pytest.raises(InsufficientRightsError):
            releveInstance.get_releve_if_allowed(user_2)

    def test_user_low_digitiser(self, geonature_app):
        """
            user is digitiser of the releve and have low right
            Must return true
        """
        from occtax.backend.models import ReleveModel, VReleveList
        from geonature.core.users.models import UserRigth
        from geonature.utils.errors import InsufficientRightsError

        user_2 = UserRigth(**user_low)
        valide_occ_tax_releve['id_digitiser'] = 125
        releveInstance = VReleveList(**valide_occ_tax_releve)
        releve = releveInstance.get_releve_if_allowed(user_2)
        assert isinstance(releve, VReleveList)




# TODO test on get_cruved






