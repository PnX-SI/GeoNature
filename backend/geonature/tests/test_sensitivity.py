from datetime import date, datetime, timedelta

import pytest
from flask import g, url_for, current_app
import sqlalchemy as sa
from sqlalchemy.sql.expression import func
from geoalchemy2.types import Geometry
from geoalchemy2.elements import WKTElement

from geonature.utils.env import db
from geonature.core.sensitivity.models import (
    SensitivityRule,
    cor_sensitivity_area,
    CorSensitivityCriteria,
)
from geonature.core.gn_synthese.models import Synthese
from geonature.tests.fixtures import source

from ref_geo.models import LAreas, BibAreasTypes
from apptax.taxonomie.models import Taxref
from pypnnomenclature.models import TNomenclatures, BibNomenclaturesTypes


@pytest.fixture(scope="class")
def clean_all_sensitivity_rules():
    db.session.execute(sa.delete(CorSensitivityCriteria))
    db.session.execute(sa.delete(cor_sensitivity_area))
    SensitivityRule.query.delete()  # clear all sensitivity rules


@pytest.mark.usefixtures("client_class", "temporary_transaction", "clean_all_sensitivity_rules")
class TestSensitivity:
    def test_get_id_nomenclature_sensitivity(self, app):
        taxon = Taxref.query.first()
        geom = WKTElement("POINT(6.15 44.85)", srid=4326)
        local_geom = func.ST_Transform(geom, func.Find_SRID("ref_geo", "l_areas", "geom"))
        date_obs = datetime.now() - timedelta(days=365 * 10)
        date_obs = date_obs.replace(month=3)
        statut_bio_type = BibNomenclaturesTypes.query.filter_by(mnemonique="STATUT_BIO").one()
        statut_bio_hibernation = TNomenclatures.query.filter_by(
            id_type=statut_bio_type.id_type, mnemonique="Hibernation"
        ).one()
        statut_bio_reproduction = TNomenclatures.query.filter_by(
            id_type=statut_bio_type.id_type, mnemonique="Reproduction"
        ).one()
        life_stage_type = BibNomenclaturesTypes.query.filter_by(mnemonique="STADE_VIE").one()
        # We choose a life stage with the same cd_nomenclature than tested status bio
        life_stage_conflict = TNomenclatures.query.filter_by(
            id_type=life_stage_type.id_type, cd_nomenclature=statut_bio_hibernation.cd_nomenclature
        ).one()
        comportement_type = BibNomenclaturesTypes.query.filter_by(
            mnemonique="OCC_COMPORTEMENT"
        ).one()
        comportement_halte = TNomenclatures.query.filter_by(
            id_type=comportement_type.id_type, mnemonique="6"
        ).one()
        comportement_hivernage = TNomenclatures.query.filter_by(
            id_type=comportement_type.id_type, mnemonique="Hivernage"
        ).one()

        query = sa.select([TNomenclatures.mnemonique]).where(
            TNomenclatures.id_nomenclature
            == func.gn_sensitivity.get_id_nomenclature_sensitivity(
                sa.cast(date_obs, sa.types.Date),
                taxon.cd_ref,
                local_geom,
                sa.cast(
                    {
                        "STATUS_BIO": statut_bio_hibernation.id_nomenclature,
                        "OCC_COMPORTEMENT": comportement_halte.id_nomenclature,
                    },
                    sa.dialects.postgresql.JSONB,
                ),
            )
        )
        assert db.session.execute(query).scalar() == "0"

        sensitivity_nomenc_type = BibNomenclaturesTypes.query.filter_by(
            mnemonique="SENSIBILITE"
        ).one()
        not_sensitive = TNomenclatures.query.filter_by(
            id_type=sensitivity_nomenc_type.id_type, mnemonique="0"
        ).one()
        diffusion_maille = TNomenclatures.query.filter_by(
            id_type=sensitivity_nomenc_type.id_type, mnemonique="2"
        ).one()
        no_diffusion = TNomenclatures.query.filter_by(
            id_type=sensitivity_nomenc_type.id_type, mnemonique="4"
        ).one()

        st_intersects = func.ST_Intersects(LAreas.geom, local_geom)
        deps = LAreas.query.join(BibAreasTypes).filter(BibAreasTypes.type_code == "DEP")
        area_in = deps.filter(st_intersects).first()
        area_out = deps.filter(sa.not_(st_intersects)).first()

        with db.session.begin_nested():
            rule = SensitivityRule(
                cd_nom=taxon.cd_nom,
                nomenclature_sensitivity=diffusion_maille,
                sensitivity_duration=100,
            )
            db.session.add(rule)
        with db.session.begin_nested():
            db.session.execute(
                "REFRESH MATERIALIZED VIEW gn_sensitivity.t_sensitivity_rules_cd_ref"
            )

        # Check the rule apply correctly
        assert db.session.execute(query).scalar() == diffusion_maille.mnemonique

        # Reduce rule duration and check rule does not apply anymore
        transaction = db.session.begin_nested()
        with db.session.begin_nested():
            rule.sensitivity_duration = 1
        with db.session.begin_nested():
            db.session.execute(
                "REFRESH MATERIALIZED VIEW gn_sensitivity.t_sensitivity_rules_cd_ref"
            )
        assert db.session.execute(query).scalar() == not_sensitive.mnemonique
        transaction.rollback()  # restore rule duration

        # Change sensitivity to no diffusion
        transaction = db.session.begin_nested()
        with db.session.begin_nested():
            rule.nomenclature_sensitivity = no_diffusion
        with db.session.begin_nested():
            db.session.execute(
                "REFRESH MATERIALIZED VIEW gn_sensitivity.t_sensitivity_rules_cd_ref"
            )
        assert db.session.execute(query).scalar() == no_diffusion.mnemonique
        transaction.rollback()  # restore rule sensitivity

        # Set rule validity period excluding observation date
        transaction = db.session.begin_nested()
        with db.session.begin_nested():
            rule.date_min = date(1900, 4, 1)
            rule.date_max = date(1900, 6, 30)
        with db.session.begin_nested():
            db.session.execute(
                "REFRESH MATERIALIZED VIEW gn_sensitivity.t_sensitivity_rules_cd_ref"
            )
        assert db.session.execute(query).scalar() == not_sensitive.mnemonique
        transaction.rollback()

        # Set rule validity period including observation date
        transaction = db.session.begin_nested()
        with db.session.begin_nested():
            rule.date_min = date(1900, 2, 1)
            rule.date_max = date(1900, 4, 30)
        with db.session.begin_nested():
            db.session.execute(
                "REFRESH MATERIALIZED VIEW gn_sensitivity.t_sensitivity_rules_cd_ref"
            )
        assert db.session.execute(query).scalar() == diffusion_maille.mnemonique
        transaction.rollback()

        # Disable the rule
        transaction = db.session.begin_nested()
        with db.session.begin_nested():
            rule.active = False
        with db.session.begin_nested():
            db.session.execute(
                "REFRESH MATERIALIZED VIEW gn_sensitivity.t_sensitivity_rules_cd_ref"
            )
        assert db.session.execute(query).scalar() == not_sensitive.mnemonique
        transaction.rollback()

        # Add a not matching bio status
        transaction = db.session.begin_nested()
        with db.session.begin_nested():
            rule.criterias.append(statut_bio_reproduction)
        assert db.session.execute(query).scalar() == not_sensitive.mnemonique
        transaction.rollback()

        # Add a matching bio status
        transaction = db.session.begin_nested()
        with db.session.begin_nested():
            rule.criterias.append(statut_bio_hibernation)
        assert db.session.execute(query).scalar() == diffusion_maille.mnemonique
        transaction.rollback()

        # Add a matching and a not matching bio status
        # The rule should match as soon as as least one bio status match
        transaction = db.session.begin_nested()
        with db.session.begin_nested():
            rule.criterias.append(statut_bio_reproduction)
            rule.criterias.append(statut_bio_hibernation)
        assert db.session.execute(query).scalar() == diffusion_maille.mnemonique
        transaction.rollback()

        # Add a matching behaviour
        transaction = db.session.begin_nested()
        with db.session.begin_nested():
            rule.criterias.append(comportement_halte)
        assert db.session.execute(query).scalar() == diffusion_maille.mnemonique
        transaction.rollback()

        # Add a matching behaviour and not matching bio status
        # The rule should match as soon as any criterias match
        transaction = db.session.begin_nested()
        with db.session.begin_nested():
            rule.criterias.append(comportement_halte)
            rule.criterias.append(statut_bio_reproduction)
        assert db.session.execute(query).scalar() == diffusion_maille.mnemonique
        transaction.rollback()

        # Add a not matching behaviour and not matching bio status
        transaction = db.session.begin_nested()
        with db.session.begin_nested():
            rule.criterias.append(comportement_hivernage)
            rule.criterias.append(statut_bio_reproduction)
        assert db.session.execute(query).scalar() == not_sensitive.mnemonique
        transaction.rollback()

        # We add a not matching life stage, but with the same cd_nomenclature than
        # status bio of the observation, and check that the rule does not apply even so.
        transaction = db.session.begin_nested()
        with db.session.begin_nested():
            rule.criterias.append(life_stage_conflict)
        assert db.session.execute(query).scalar() == not_sensitive.mnemonique
        transaction.rollback()

        # Add a matching area to the rule → the rule still applies
        transaction = db.session.begin_nested()
        with db.session.begin_nested():
            rule.areas.append(area_in)
        assert db.session.execute(query).scalar() == diffusion_maille.mnemonique
        transaction.rollback()

        # Add a not matching area to the rule → the rule does not apply anymore
        transaction = db.session.begin_nested()
        with db.session.begin_nested():
            rule.areas.append(area_out)
        assert db.session.execute(query).scalar() == not_sensitive.mnemonique
        transaction.rollback()

        # Add a matching and a not matching area to the rule
        # The rule should apply as soon as at least one area match
        transaction = db.session.begin_nested()
        with db.session.begin_nested():
            rule.areas.append(area_in)
            rule.areas.append(area_out)
        assert db.session.execute(query).scalar() == diffusion_maille.mnemonique
        transaction.rollback()

        # Add a matching area but a not matching status bio
        transaction = db.session.begin_nested()
        with db.session.begin_nested():
            rule.areas.append(area_in)
            rule.criterias.append(statut_bio_reproduction)
        assert db.session.execute(query).scalar() == not_sensitive.mnemonique
        transaction.rollback()

        # Add a second more restrictive rule
        with db.session.begin_nested():
            rule2 = SensitivityRule(
                cd_nom=taxon.cd_nom,
                nomenclature_sensitivity=no_diffusion,
                sensitivity_duration=100,
            )
            db.session.add(rule2)
        with db.session.begin_nested():
            db.session.execute(
                "REFRESH MATERIALIZED VIEW gn_sensitivity.t_sensitivity_rules_cd_ref"
            )
        rule1 = rule

        # Verify that the more restrictive rule match
        assert db.session.execute(query).scalar() == no_diffusion.mnemonique

        # Add not matching bio status criteria on rule 2, but rule 1 should still apply
        transaction = db.session.begin_nested()
        with db.session.begin_nested():
            rule2.criterias.append(statut_bio_reproduction)  # not matching
        assert db.session.execute(query).scalar() == diffusion_maille.mnemonique
        transaction.rollback()

        # Add not matching area on rule 2, but rule 1 should apply
        transaction = db.session.begin_nested()
        with db.session.begin_nested():
            rule2.areas.append(area_out)
        assert db.session.execute(query).scalar() == diffusion_maille.mnemonique
        transaction.rollback()

        # Add not matching area on rule 1, but rule 2 should apply
        transaction = db.session.begin_nested()
        with db.session.begin_nested():
            rule1.areas.append(area_out)
        assert db.session.execute(query).scalar() == no_diffusion.mnemonique
        transaction.rollback()

        # Add not matching area on rule 1, and not matching bio status on rule 2
        transaction = db.session.begin_nested()
        with db.session.begin_nested():
            rule1.areas.append(area_out)
            rule2.criterias.append(statut_bio_reproduction)  # not matching
        assert db.session.execute(query).scalar() == not_sensitive.mnemonique
        transaction.rollback()

    def test_synthese_sensitivity(self, app, source):
        taxon = Taxref.query.first()
        sensitivity_nomenc_type = BibNomenclaturesTypes.query.filter_by(
            mnemonique="SENSIBILITE"
        ).one()
        nomenc_not_sensitive = TNomenclatures.query.filter_by(
            id_type=sensitivity_nomenc_type.id_type, mnemonique="0"
        ).one()
        nomenc_no_diff = TNomenclatures.query.filter_by(
            id_type=sensitivity_nomenc_type.id_type, mnemonique="4"
        ).one()
        with db.session.begin_nested():
            rule = SensitivityRule(
                cd_nom=taxon.cd_nom,
                nomenclature_sensitivity=nomenc_no_diff,
                sensitivity_duration=5,
            )
            db.session.add(rule)
        with db.session.begin_nested():
            db.session.execute(
                "REFRESH MATERIALIZED VIEW gn_sensitivity.t_sensitivity_rules_cd_ref"
            )

        date_obs = datetime.now()
        with db.session.begin_nested():
            s = Synthese(
                source=source,
                cd_nom=taxon.cd_nom,
                nom_cite="Sensitive taxon",
                date_min=date_obs,
                date_max=date_obs,
            )
            db.session.add(s)
        db.session.refresh(s)
        assert s.id_nomenclature_sensitivity == nomenc_no_diff.id_nomenclature

        date_obs -= timedelta(days=365 * 10)
        with db.session.begin_nested():
            s.date_min = date_obs
            s.date_max = date_obs
        db.session.refresh(s)
        assert s.id_nomenclature_sensitivity == nomenc_not_sensitive.id_nomenclature
