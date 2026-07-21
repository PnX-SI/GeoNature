import csv
from functools import lru_cache

import sqlalchemy as sa
from geonature.utils.env import db
from pypnnomenclature.models import BibNomenclaturesTypes as NomenclatureType
from pypnnomenclature.models import TNomenclatures as Nomenclature

from .models import CorSensitivityCriteria, SensitivityRule


@lru_cache(maxsize=64)
def get_nomenclature(type_mnemonique, code):
    # Retro-compatibility with freezed nomenclatures
    if type_mnemonique == "STATUT_BIO" and code in ["6", "7", "8", "10", "11", "12"]:
        type_mnemonique = "OCC_COMPORTEMENT"
    return db.session.execute(
        sa.select(Nomenclature).where(
            Nomenclature.active == True,  # noqa: E712
            Nomenclature.nomenclature_type.has(NomenclatureType.mnemonique == type_mnemonique),
            Nomenclature.cd_nomenclature == code,
        )
    ).scalar_one()


def insert_sensitivity_referential(source, csvfile):
    statut_biologique_nomenclature_type = db.session.execute(
        sa.select(NomenclatureType).filter_by(mnemonique="STATUT_BIO")
    ).scalar_one()
    behaviour_nomenclature_type = db.session.execute(
        sa.select(NomenclatureType).filter_by(mnemonique="OCC_COMPORTEMENT")
    ).scalar_one()
    observation_method_type = db.session.execute(
        sa.select(NomenclatureType).filter_by(mnemonique="METH_OBS")
    ).scalar_one()
    life_stage_nomenclature_type = db.session.execute(
        sa.select(NomenclatureType).filter_by(mnemonique="STADE_VIE")
    ).scalar_one()
    defaults_nomenclatures = {
        statut_biologique_nomenclature_type: set(
            db.session.scalars(
                sa.select(Nomenclature).where(
                    Nomenclature.nomenclature_type == statut_biologique_nomenclature_type,
                    Nomenclature.mnemonique.in_(["Inconnu", "Non renseigné", "Non Déterminé"]),
                )
            ).all()
        ),
        behaviour_nomenclature_type: set(
            db.session.scalars(
                sa.select(Nomenclature).where(
                    Nomenclature.nomenclature_type == behaviour_nomenclature_type,
                    Nomenclature.mnemonique.in_(["NSP", "1"]),
                )
            ).all()
        ),
        observation_method_type: set(
            db.session.scalars(
                sa.select(Nomenclature).where(
                    Nomenclature.nomenclature_type == observation_method_type,
                    Nomenclature.mnemonique.in_(["Inconnu"]),
                )
            ).all()
        ),
        life_stage_nomenclature_type: set(
            db.session.scalars(
                sa.select(Nomenclature).where(
                    Nomenclature.nomenclature_type == life_stage_nomenclature_type,
                    Nomenclature.mnemonique.in_(["Inconnu", "Indéterminé"]),
                )
            ).all()
        ),
    }

    rules = []
    criterias = set()
    reader = csv.DictReader(csvfile, delimiter=";")
    dep_col = next(
        fieldname for fieldname in reader.fieldnames if fieldname in ["CD_DEP", "CD_DEPT"]
    )
    for row in reader:
        sensi_nomenclature = get_nomenclature("SENSIBILITE", code=row["CD_SENSIBILITE"])
        if row[dep_col] == "D3":
            cd_dep = "973"
        elif row[dep_col] == "D4":
            cd_dep = "974"
        else:
            cd_dep = row[dep_col]

        if row[dep_col].startswith("hab"):
            territory = "Habitat"
        else:
            territory = "Département"

        if row["DUREE"]:
            duration = int(row["DUREE"])
        else:
            duration = 10000

        if row["DATE_MIN"]:
            date_min = row["DATE_MIN"]
        else:
            date_min = None

        if row["DATE_MAX"]:
            date_max = row["DATE_MAX"]
        else:
            date_max = None

        rule = {
            "cd_nom": int(row["CD_NOM"]),
            "nom_cite": row["NOM_CITE"],
            "id_nomenclature_sensitivity": sensi_nomenclature.id_nomenclature,
            "sensitivity_duration": duration,
            "sensitivity_territory": territory,
            "id_territory": cd_dep,
            "date_min": date_min,
            "date_max": date_max,
            "source": f"{source}",
            "comments": row["AUTRE"],
            "active": True,
        }
        _criterias = set()
        if row["STATUT_BIOLOGIQUE"]:
            criteria = get_nomenclature("STATUT_BIO", code=row["STATUT_BIOLOGIQUE"])
            _criterias |= {criteria} | defaults_nomenclatures[criteria.nomenclature_type]

        if row["COMPORTEMENT"]:
            criteria = get_nomenclature("OCC_COMPORTEMENT", code=row["COMPORTEMENT"])
            _criterias |= {criteria} | defaults_nomenclatures[criteria.nomenclature_type]

        if row["METH_OBS"]:
            criteria = get_nomenclature("METH_OBS", code=row["METH_OBS"])
            _criterias |= {criteria} | defaults_nomenclatures[criteria.nomenclature_type]

        if row["STADE_VIE"]:
            criteria = get_nomenclature("STADE_VIE", code=row["STADE_VIE"])
            _criterias |= {criteria} | defaults_nomenclatures[criteria.nomenclature_type]

        for criteria in _criterias:
            criterias.add((len(rules), criteria))
        rules.append(rule)
    results = db.session.execute(
        sa.insert(SensitivityRule).values(rules).returning(SensitivityRule.id)
    )
    rules_indexes = [rule_index for rule_index, in results]  # flattening singleton results
    db.session.execute(
        sa.insert(CorSensitivityCriteria).values(
            [
                {
                    "id_sensitivity": rules_indexes[rule_idx],
                    "id_type_nomenclature": nomenclature.id_type,
                    "id_criteria": nomenclature.id_nomenclature,
                }
                for rule_idx, nomenclature in criterias
            ]
        )
    )

    # Populate cor_sensitivity_area
    db.session.connection().execute(
        sa.text("""
            INSERT INTO gn_sensitivity.cor_sensitivity_area
            SELECT DISTINCT id_sensitivity,
                            id_area
            FROM gn_sensitivity.t_sensitivity_rules s
            JOIN ref_geo.l_areas a ON s.sensitivity_territory IN ('Département',
                                                                  'Habitat')
            AND a.id_type =
              (SELECT id_type
               FROM ref_geo.bib_areas_types
               WHERE type_code ='DEP')
            AND regexp_replace(s.id_territory, '^([0-9])$', '0\\1') = a.area_code
            OR s.id_territory = a.area_code
            WHERE s.source = :source
            """),
        source=source,
    )

    return len(rules)


def remove_sensitivity_referential(source):
    whereclause = SensitivityRule.source == source
    return db.session.execute(sa.delete(SensitivityRule).where(whereclause)).rowcount
