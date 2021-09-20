from datetime import date, datetime, timedelta

import pytest
from flask import g, url_for, current_app
import sqlalchemy as sa
from sqlalchemy.sql.expression import func
from geoalchemy2.types import Geometry
from geoalchemy2.elements import WKTElement

from geonature.utils.env import db
from geonature.core.sensitivity.models import SensitivityRule
from geonature.core.gn_synthese.models import Synthese, CorSensitivitySynthese
from apptax.taxonomie.models import Taxref
from pypnnomenclature.models import TNomenclatures, BibNomenclaturesTypes

from . import temporary_transaction


@pytest.mark.usefixtures("client_class", "temporary_transaction")
class TestSensitivity:
    def test_get_id_nomenclature_sensitivity(self, app):
        SensitivityRule.query.delete()  # clear all sensitivity rules
        taxon = Taxref.query.first()
        geom = WKTElement('POINT(6.12 44.85)', srid=4326)
        date_obs = datetime.now() - timedelta(days=365 *  10)
        date_obs = date_obs.replace(month=3)
        query = func.gn_sensitivity.get_id_nomenclature_sensitivity(
                        sa.cast(date_obs, sa.types.Date),
                        taxon.cd_ref,
                        geom,
                        #sa.cast({'STATUS_BIO': 30}, sa.dialects.postgresql.JSONB),
                        sa.cast({}, sa.dialects.postgresql.JSONB),
                    )
        id_nomenc = db.session.execute(query).scalar()
        nomenc = TNomenclatures.query.get(id_nomenc)
        assert(nomenc.mnemonique == '0')

        sensitivity_nomenc_type = BibNomenclaturesTypes.query.filter_by(mnemonique='SENSIBILITE').one()
        sensitivity_nomenc = TNomenclatures.query.filter_by(id_type=sensitivity_nomenc_type.id_type,
                                                            mnemonique='4').one()  # aucune diffusion
        with db.session.begin_nested():
            rule = SensitivityRule(cd_nom=taxon.cd_nom, nomenclature_sensitivity=sensitivity_nomenc,
                                   sensitivity_duration=100)
            db.session.add(rule)
        with db.session.begin_nested():
            db.session.execute('REFRESH MATERIALIZED VIEW gn_sensitivity.t_sensitivity_rules_cd_ref')
        id_nomenc = db.session.execute(query).scalar()
        nomenc = TNomenclatures.query.get(id_nomenc)
        assert(nomenc.mnemonique == '4')

        with db.session.begin_nested():
            rule.sensitivity_duration = 1
        with db.session.begin_nested():
            db.session.execute('REFRESH MATERIALIZED VIEW gn_sensitivity.t_sensitivity_rules_cd_ref')
        id_nomenc = db.session.execute(query).scalar()
        nomenc = TNomenclatures.query.get(id_nomenc)
        assert(nomenc.mnemonique == '0')

        sensitivity_nomenc = TNomenclatures.query.filter_by(id_type=sensitivity_nomenc_type.id_type,
                                                            mnemonique='2').one()  # diffusion maille
        with db.session.begin_nested():
            rule.sensitivity_duration = 10
            rule.nomenclature_sensitivity = sensitivity_nomenc
        with db.session.begin_nested():
            db.session.execute('REFRESH MATERIALIZED VIEW gn_sensitivity.t_sensitivity_rules_cd_ref')
        id_nomenc = db.session.execute(query).scalar()
        nomenc = TNomenclatures.query.get(id_nomenc)
        assert(nomenc.mnemonique == '2')

        with db.session.begin_nested():
            rule.date_min = date(1900, 4, 1)
            rule.date_max = date(1900, 6, 30)
        with db.session.begin_nested():
            db.session.execute('REFRESH MATERIALIZED VIEW gn_sensitivity.t_sensitivity_rules_cd_ref')
        id_nomenc = db.session.execute(query).scalar()
        nomenc = TNomenclatures.query.get(id_nomenc)
        assert(nomenc.mnemonique == '0')

        with db.session.begin_nested():
            rule.date_min = date(1900, 2, 1)
            rule.date_max = date(1900, 4, 30)
        with db.session.begin_nested():
            db.session.execute('REFRESH MATERIALIZED VIEW gn_sensitivity.t_sensitivity_rules_cd_ref')
        id_nomenc = db.session.execute(query).scalar()
        nomenc = TNomenclatures.query.get(id_nomenc)
        assert(nomenc.mnemonique == '2')

        with db.session.begin_nested():
            rule.active = False
        with db.session.begin_nested():
            db.session.execute('REFRESH MATERIALIZED VIEW gn_sensitivity.t_sensitivity_rules_cd_ref')
        id_nomenc = db.session.execute(query).scalar()
        nomenc = TNomenclatures.query.get(id_nomenc)
        assert(nomenc.mnemonique == '0')

        # TODO: test geom, test criteria
        with db.session.begin_nested():
            rule.active = True
        with db.session.begin_nested():
            db.session.execute('REFRESH MATERIALIZED VIEW gn_sensitivity.t_sensitivity_rules_cd_ref')
        id_nomenc = db.session.execute(query).scalar()
        nomenc = TNomenclatures.query.get(id_nomenc)
        assert(nomenc.mnemonique == '2')


    def test_synthese_sensitivity(self, app):
        SensitivityRule.query.delete()  # clear all sensitivity rules
        taxon = Taxref.query.first()
        sensitivity_nomenc_type = BibNomenclaturesTypes.query.filter_by(mnemonique='SENSIBILITE').one()
        nomenc_maille = TNomenclatures.query.filter_by(id_type=sensitivity_nomenc_type.id_type,
                                                       mnemonique='2').one()
        nomenc_no_diff = TNomenclatures.query.filter_by(id_type=sensitivity_nomenc_type.id_type,
                                                        mnemonique='4').one()
        with db.session.begin_nested():
            rule = SensitivityRule(cd_nom=taxon.cd_nom, nomenclature_sensitivity=nomenc_no_diff,
                                   sensitivity_duration=100)
            db.session.add(rule)
        with db.session.begin_nested():
            db.session.execute('REFRESH MATERIALIZED VIEW gn_sensitivity.t_sensitivity_rules_cd_ref')
        date_obs = datetime.now()
        geom = WKTElement('POINT(6.12 44.85)', srid=4326)

        query = func.gn_sensitivity.get_id_nomenclature_sensitivity(
                        sa.cast(date_obs, sa.types.Date),
                        taxon.cd_ref,
                        geom,
                        sa.cast({}, sa.dialects.postgresql.JSONB),
                    )
        id_nomenc = db.session.execute(query).scalar()
        nomenc = TNomenclatures.query.get(id_nomenc)
        assert(nomenc.mnemonique == nomenc_no_diff.mnemonique)

        # FIXME: why id_synthese is not automatically set?
        next_id = db.session.query(func.max(Synthese.__table__.c.id_synthese) + 1)

        with db.session.begin_nested():
            s = Synthese(id_synthese=next_id, cd_nom=taxon.cd_nom, nom_cite='Sensitive taxon',
                         date_min=date_obs, date_max=date_obs)#, the_geom_4326=geom)
            db.session.add(s)
        db.session.refresh(s)
        assert(s.id_nomenclature_sensitivity == nomenc_no_diff.id_nomenclature)

        # verify setting id_nomenclature_sensitivity manually have precedence other sensitivity trigger
        with db.session.begin_nested():
            s = Synthese(id_synthese=next_id, cd_nom=taxon.cd_nom, nom_cite='Sensitive taxon',
                         date_min=date_obs, date_max=date_obs,
                         id_nomenclature_sensitivity=nomenc_maille.id_nomenclature)
            db.session.add(s)
        db.session.refresh(s)
        assert(s.id_nomenclature_sensitivity == nomenc_maille.id_nomenclature)
