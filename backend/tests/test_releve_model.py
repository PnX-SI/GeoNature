import sys
import os
import datetime


import pytest
import requests

from flask import session

from geonature.core.users.models import UserRigth
from pypnusershub.db.tools import InsufficientRightsError
from geonature.core.gn_permissions.tools import cruved_scope_for_user_in_module

from .bootstrap_test import app

d = os.path.join(os.path.abspath(__file__ + "/../../../"), 'contrib')
sys.path.append(d)


valide_occ_tax_releve = {
    'id_releve_occtax': 1,
    'id_dataset': 1,
    'id_digitiser': 1,
    'date_min': datetime.datetime.now(),
    'date_max': datetime.datetime.now(),
    'altitude_min': 1100,
    'altitude_max': 1200,
    'meta_device_entry': 'web',
    'comment': 'test',
    'geom_4326': 'test',
    'taxons': 'ablette, lynx',
    'leaflet_popup': 'test',
    'observateurs': 'admin',
    'observers': []
}

user_admin = {
    'id_role': 1,
    'id_organisme': 1,
    'code_action': 'R',
    'value_filter': '3',
}

# has only right on dataset 2
user_agent = {
    'id_role': 2,
    'id_organisme': -1,
    'code_action': 'R',
    'value_filter': '2',
}

# can see only its data
user_low = {
    'id_role': 125,
    'id_organisme': -1,
    'code_action': 'R',
    'value_filter': '1',
}


@pytest.mark.usefixtures('client_class')
class TestReleveModel:
    #  Test on abstract class ReleveModel and its methods
    def test_user_is_observers(self):
        """
            user is observer of the releve
            Must be True
        """

        from occtax.backend.models import ReleveModel, VReleveList

        user_hight = UserRigth(**user_admin)
        valide_occ_tax_releve['observers'].append(user_hight)
        releveInstance = VReleveList(**valide_occ_tax_releve)
        releve = releveInstance.get_releve_if_allowed(user_hight)
        assert isinstance(releve, VReleveList)

    def test_user_is_in_dataset(self):
        """
            user is not observer but can see its organism data
            via rigth in dataset number 1
            Must be True
        """
        from occtax.backend.models import ReleveModel, VReleveList

        user_hight = UserRigth(**user_admin)
        valide_occ_tax_releve['id_digitiser'] = None
        releveInstance = VReleveList(**valide_occ_tax_releve)
        releve = releveInstance.get_releve_if_allowed(user_hight)
        assert isinstance(releve, VReleveList)

    def test_user_not_in_dataset(self):
        """
            user is not observer of the releve cannot see dataset
            number 1
            Must return an InsufficientRightsError
        """
        from occtax.backend.models import ReleveModel, VReleveList

        _user_agent = UserRigth(**user_agent)
        releveInstance = VReleveList(**valide_occ_tax_releve)
        with pytest.raises(InsufficientRightsError):
            releveInstance.get_releve_if_allowed(_user_agent)

    def test_user_not_observer(self):
        """
            user is not observer of the releve and have low right
            Must return an InsufficientRightsError
        """
        from occtax.backend.models import ReleveModel, VReleveList

        user_2 = UserRigth(**user_low)
        releveInstance = VReleveList(**valide_occ_tax_releve)
        with pytest.raises(InsufficientRightsError):
            releveInstance.get_releve_if_allowed(user_2)

    def test_user_low_digitiser(self):
        """
            user is digitiser of the releve and have low right
            Must return true
        """
        from occtax.backend.models import ReleveModel, VReleveList

        user_2 = UserRigth(**user_low)
        valide_occ_tax_releve['id_digitiser'] = 125
        releveInstance = VReleveList(**valide_occ_tax_releve)
        releve = releveInstance.get_releve_if_allowed(user_2)
        assert isinstance(releve, VReleveList)

    def test_get_releve_cruved(self):
        from occtax.backend.models import ReleveModel, VReleveList

        user_hight = UserRigth(**user_admin)
        releveInstance = VReleveList(**valide_occ_tax_releve)

        user_cruved, herited = cruved_scope_for_user_in_module(
           id_role=user_hight.id_role,
            module_code='OCCTAX'
        )
        cruved = {'R': '3', 'E': '3', 'C': '3', 'V': '3', 'D': '3', 'U': '3'}

        assert cruved == user_cruved
        assert herited == True

        releve_cruved = releveInstance.get_releve_cruved(user_hight, cruved)

        user_releve_cruved = {'E': True, 'V': True, 'R': True, 'D': True, 'C': True, 'U': True}
        assert releve_cruved == user_releve_cruved
