
from datetime import date, datetime, timedelta
from random import randint
from geonature.core.gn_meta.models import TDatasets

import pytest
from flask import g, url_for, current_app
import sqlalchemy as sa
from sqlalchemy.sql.expression import func
from geoalchemy2.types import Geometry
from geoalchemy2.elements import WKTElement
from pyproj import Proj, transform

from geonature.utils.env import db
from geonature.core.gn_profiles.models import (
    VConsistancyData, VmCorTaxonPhenology, VmValidProfiles
)
from geonature.core.gn_synthese.models import Synthese
from geonature.core.taxonomie.models import Taxref

from . import temporary_transaction


def create_synthese_record(
    cd_nom=None,
    date_min=datetime.now(),
    date_max=datetime.now(),
    x=6.12,
    y=44.85,
    altitude_min=None,
    altitude_max=None,
    id_dataset=None,
    nom_cite="blah",
    id_nomenclature_valid_status=None,
    id_nomenclature_life_stage=None
):
    if not cd_nom:
        cd_nom = Taxref.query.first().cd_nom
    if not id_dataset:
        id_dataset = TDatasets.query.first().id_dataset
        
    geom_4326 = WKTElement(f'POINT({str(x)} {str(y)})', srid=4326)
    p4326 = Proj('epsg:4326')
    local_srid = current_app.config["LOCAL_SRID"]
    p_local = Proj(f'epsg:{local_srid}')
    x_local, y_local = transform(p4326, p_local, x, y)
    geom_local = WKTElement(f'POINT({str(x_local)} {str(y_local)})', srid=local_srid)
    
    return Synthese(
        id_synthese=randint(1, 1000000),#TODO: make the sequence work automaticly ?
        cd_nom=cd_nom,
        date_min=date_min,
        date_max=date_max,
        the_geom_local=geom_local,
        the_geom_4326=geom_4326,
        altitude_min=altitude_min,
        altitude_max=altitude_max,
        id_dataset=id_dataset,
        nom_cite=nom_cite,
        id_nomenclature_valid_status=id_nomenclature_valid_status,
        id_nomenclature_life_stage=id_nomenclature_life_stage
    )


@pytest.fixture(scope='class')
def sample_synthese_records_for_profile(app):
        Synthese.query.delete()  # clear all synthese entries
        # set a profile for taxon 212 (sonneur)
        synthese_record_for_profile = create_synthese_record(
            cd_nom=212,
            x=6.12,
            y=44.85,
            altitude_min=1000,
            altitude_max=1200,
            id_nomenclature_valid_status=func.ref_nomenclatures.get_id_nomenclature(
                "STATUT_VALID",
                "1"
            ),
            id_nomenclature_life_stage=func.ref_nomenclatures.get_id_nomenclature(
                "STADE_VIE",
                "10"
            )
        )
        # set life stage active for animalia
        # with db.session.begin_nested():
        with db.session.begin_nested():
            db.session.add(synthese_record_for_profile)
            db.session.execute("UPDATE gn_profiles.cor_taxons_parameters SET active_life_stage = TRUE WHERE cd_nom = 183716")

        db.session.execute('REFRESH MATERIALIZED VIEW gn_profiles.vm_valid_profiles')
        db.session.execute('REFRESH MATERIALIZED VIEW gn_profiles.vm_cor_taxon_phenology')

@pytest.mark.usefixtures("client_class", 
"temporary_transaction", "sample_synthese_records_for_profile"
)
class TestGnProfiles:
    def test_checks(self, app):
        """
        Call of view VConsistancyData which process to the tree checks:
            - check altitude
            - check phenology
            - check distribution
        """
        valid_new_obs = create_synthese_record(
            cd_nom=212,
            x=6.12,
            y=44.85,
            altitude_min=1100,
            altitude_max=1100,
            id_nomenclature_life_stage=func.ref_nomenclatures.get_id_nomenclature(
                "STADE_VIE",
                "10"
            )
        )
        with db.session.begin_nested():
            db.session.add(valid_new_obs)
        
        # check altitude
        consitancy_data = VConsistancyData.query.filter(VConsistancyData.id_synthese == valid_new_obs.id_synthese).one()
        cor = VmCorTaxonPhenology.query.first()
        print(cor.cd_ref)
        print(cor.doy_min)
        print(cor.doy_max)
        print(cor.calculated_altitude_min)
        print(cor.calculated_altitude_max)
        assert consitancy_data.valid_distribution is True
        assert consitancy_data.valid_altitude is True
        assert consitancy_data.valid_phenology is True

        

        wrong_new_obs = create_synthese_record(
            cd_nom=212,
            x=20.12,
            y=55.85,
            altitude_min=10,
            altitude_max=20,
            id_nomenclature_life_stage=func.ref_nomenclatures.get_id_nomenclature(
                "STADE_VIE",
                "11"
            )
        )
        with db.session.begin_nested():
            db.session.add(wrong_new_obs)
        consitancy_data = VConsistancyData.query.filter(
            VConsistancyData.id_synthese == wrong_new_obs.id_synthese
        ).one()
        cor = VmCorTaxonPhenology.query.first()
        assert consitancy_data.valid_distribution is False
        assert consitancy_data.valid_altitude is False
        # assert consitancy_data.valid_phenology is False


    # def test_get_phenology(self, app):
    #     response = self.client.get(
    #         url_for("gn_profiles.get_phenology", cd_ref=212),
    #         query_string={
    #             "id_nomenclature_life_stage" : db.session.query(func.ref_nomenclatures.get_id_nomenclature("STADE_VIE","10")).first()[0]
    #         }
    #     )
    #     re = VmCorTaxonPhenology.query.all()
    #     print('LAAAAAAAAA')
    #     for r in re: 
    #         print("oHHHHHHHHH", r)
    #     assert response.status_code == 200
