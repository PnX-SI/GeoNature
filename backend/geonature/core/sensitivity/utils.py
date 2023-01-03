import csv
from functools import lru_cache

import sqlalchemy as sa

from geonature.utils.env import db

from pypnnomenclature.models import (
    TNomenclatures as Nomenclature,
    BibNomenclaturesTypes as NomenclatureType,
)

from .models import CorSensitivityCriteria, SensitivityRule


@lru_cache(maxsize=64)
def get_nomenclature(type_mnemonique, code):
    # Retro-compatibility with freezed nomenclatures
    if type_mnemonique == "STATUT_BIO" and code in ["6", "7", "8", "10", "11", "12"]:
        type_mnemonique = "OCC_COMPORTEMENT"
    return Nomenclature.query.filter(
        Nomenclature.active == True,  # noqa: E712
        Nomenclature.nomenclature_type.has(NomenclatureType.mnemonique == type_mnemonique),
        Nomenclature.cd_nomenclature == code,
    ).one()


def insert_sensitivity_referential(source, csvfile):
    statut_biologique_nomenclature_type = NomenclatureType.query.filter_by(
        mnemonique="STATUT_BIO"
    ).one()
    behaviour_nomenclature_type = NomenclatureType.query.filter_by(
        mnemonique="OCC_COMPORTEMENT"
    ).one()
    defaults_nomenclatures = {
        statut_biologique_nomenclature_type: set(
            Nomenclature.query.filter(
                Nomenclature.nomenclature_type == statut_biologique_nomenclature_type,
                Nomenclature.mnemonique.in_(["Inconnu", "Non renseigné", "Non Déterminé"]),
            )
        ),
        behaviour_nomenclature_type: set(
            Nomenclature.query.filter(
                Nomenclature.nomenclature_type == behaviour_nomenclature_type,
                Nomenclature.mnemonique.in_(["NSP", "1"]),
            )
        ),
    }

    rules = []
    criterias = set()
    reader = csv.DictReader(csvfile, delimiter=";")
    for row in reader:
        sensi_nomenclature = get_nomenclature("SENSIBILITE", code=row["CD_SENSIBILITE"])
        if row["CD_DEP"] == "D3":
            cd_dep = "973"
        elif row["CD_DEP"] == "D4":
            cd_dep = "974"
        else:
            cd_dep = row["CD_DEP"]
        if row["DUREE"]:
            duration = int(row["DUREE"])
        else:
            duration = 10000
        rule = {
            "cd_nom": int(row["CD_NOM"]),
            "nom_cite": row["NOM_CITE"],
            "id_nomenclature_sensitivity": sensi_nomenclature.id_nomenclature,
            "sensitivity_duration": duration,
            "sensitivity_territory": "Département",
            "id_territory": cd_dep,
            "source": f"{source}",
            "comments": row["AUTRE"],
            "active": True,
        }
        _criterias = set()
        if row["STATUT_BIOLOGIQUE"]:
            criteria = get_nomenclature("STATUT_BIO", code=row["STATUT_BIOLOGIQUE"])
            _criterias |= {criteria} | defaults_nomenclatures[criteria.nomenclature_type]
        if row["COMPORTEMENT"]:
            criteria = get_nomenclature("OCC_COMPORTEMENT", code=row["STATUT_BIOLOGIQUE"])
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
        sa.text(
            """
    INSERT INTO gn_sensitivity.cor_sensitivity_area
        SELECT DISTINCT id_sensitivity, id_area
        FROM gn_sensitivity.t_sensitivity_rules s
        JOIN ref_geo.l_areas a
        ON
                s.sensitivity_territory = 'Département'
            AND a.id_type = (SELECT id_type FROM ref_geo.bib_areas_types WHERE type_code ='DEP')
            AND regexp_replace(s.id_territory, '^([0-9])$', '0\\1') = a.area_code
        WHERE s.source = :source
    """
        ),
        source=source,
    )

    return len(rules)


def remove_sensitivity_referential(source):
    return SensitivityRule.query.filter_by(source=source).delete()
