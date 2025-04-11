"""Insert INPN rules in sensitivity referential

Revision ID: 7dfd0a813f86
Create Date: 2021-11-22

"""

import csv
import importlib.resources
from functools import lru_cache, partial
from itertools import chain
from lzma import open as lzmaopen
from alembic import context
from distutils.util import strtobool


from alembic import op
from sqlalchemy import func
import sqlalchemy as sa

from utils_flask_sqla.migrations.utils import logger, open_remote_file


lzmaopen = partial(lzmaopen, mode="rt")


# revision identifiers, used by Alembic.
revision = "7dfd0a813f86"
down_revision = None
branch_labels = ("ref_sensitivity_inpn",)
depends_on = (
    "05a0ae652c13",  # regions 1970
    "d02f4563bebe",  # regions 2016
)


source = "Référentiel sensibilité TAXREF v13 2020"
base_url = "https://geonature.fr/data/inpn/sensitivity/"
filename = "referentiel_donnees_sensibles_v13.csv.xz"


@lru_cache(maxsize=32)
def get_id_from_cd(cd_nomenc):
    return (
        op.get_bind()
        .execute(sa.func.ref_nomenclatures.get_id_nomenclature("SENSIBILITE", cd_nomenc))
        .scalar()
    )


def upgrade():
    active = context.get_x_argument(as_dictionary=True).get("active")
    if active is not None:
        active = bool(strtobool(active))
    conn = op.get_bind()
    metadata = sa.MetaData(bind=conn)
    sensitivity_rule = sa.Table(
        "t_sensitivity_rules", metadata, schema="gn_sensitivity", autoload_with=conn
    )
    cor_sensitivity_criteria = sa.Table(
        "cor_sensitivity_criteria", metadata, schema="gn_sensitivity", autoload_with=conn
    )
    nomenclature = sa.Table(
        "t_nomenclatures", metadata, schema="ref_nomenclatures", autoload_with=conn
    )
    nomenclature_type = sa.Table(
        "bib_nomenclatures_types", metadata, schema="ref_nomenclatures", autoload_with=conn
    )
    statut_biologique_nomenclatures = list(
        chain.from_iterable(
            conn.execute(
                sa.select(nomenclature.c.cd_nomenclature)
                .select_from(
                    nomenclature.join(
                        nomenclature_type, nomenclature.c.id_type == nomenclature_type.c.id_type
                    )
                )
                .where(nomenclature_type.c.mnemonique == "STATUT_BIO")
            )
        )
    )
    rules = []
    criterias = []
    with open_remote_file(base_url, filename, open_fct=lzmaopen) as csvfile:
        reader = csv.DictReader(csvfile, delimiter=",")
        for row in reader:
            id_nomenc = get_id_from_cd(row["codage"])
            if row["duree"]:
                duration = int(row["duree"])
            else:
                duration = 10000
            if active is not None:
                _active = active
            else:
                _active = row["perimetre"] == "France métropolitaine"
            rule = {
                "cd_nom": int(row["cd_nom"]),
                "nom_cite": row["nom_cite"],
                "id_nomenclature_sensitivity": id_nomenc,
                "sensitivity_duration": duration,
                "sensitivity_territory": row["perimetre"],
                "id_territory": row["cd_sig"],
                "source": f"{source}",
                "comments": row["autre"],
                "date_min": row["date_min"] if row["date_min"] else None,
                "date_max": row["date_max"] if row["date_max"] else None,
                "active": _active,
            }
            if row["cd_occ_statut_biologique"]:
                nomenc_value = row["cd_occ_statut_biologique"]
                if nomenc_value in statut_biologique_nomenclatures:
                    nomenc_type = "STATUT_BIO"
                elif nomenc_value in ("6", "7", "8", "10", "11", "12"):
                    nomenc_type = "OCC_COMPORTEMENT"
                else:
                    raise Exception("Unknown statut biologique '{}'".format(nomenc_value))
                criterias.append((len(rules), nomenc_type, nomenc_value))
            rules.append(rule)
    results = conn.execute(
        sensitivity_rule.insert().values(rules).returning(sensitivity_rule.c.id_sensitivity)
    )
    rules_id = [rule_id for rule_id, in results]
    conn.execute(
        cor_sensitivity_criteria.insert().values(
            [
                {
                    "id_sensitivity": rules_id[rule_index],
                    "id_criteria": func.ref_nomenclatures.get_id_nomenclature(
                        nomenc_type, nomenc_value
                    ),
                    "id_type_nomenclature": func.ref_nomenclatures.get_id_nomenclature_type(
                        nomenc_type
                    ),
                }
                for rule_index, nomenc_type, nomenc_value in criterias
            ]
        )
    )

    # We are looking codes in both actual and old regions but keep only the most recent one
    conn.execute(
        """
    INSERT INTO gn_sensitivity.cor_sensitivity_area
        SELECT DISTINCT ON (id_sensitivity) s.id_sensitivity, a.id_area
        FROM gn_sensitivity.t_sensitivity_rules s
        JOIN ref_geo.l_areas a
            ON REPLACE(s.id_territory, 'INSEER', '') = a.area_code
        JOIN ref_geo.bib_areas_types t
        	ON t.id_type = a.id_type AND t.type_code IN ('REG', 'REG_1970')
        WHERE s.sensitivity_territory = 'Région'
        ORDER BY
        	s.id_sensitivity,
        	array_position(ARRAY['REG','REG_1970'], t.type_code::text)
    """
    )

    conn.execute(
        """
    INSERT INTO gn_sensitivity.cor_sensitivity_area
        SELECT DISTINCT id_sensitivity, id_area
        FROM gn_sensitivity.t_sensitivity_rules   s
        JOIN ref_geo.l_areas
            ON REPLACE(id_territory, 'INSEED', '') = area_code AND  id_type = (SELECT id_type FROM ref_geo.bib_areas_types  WHERE type_code ='DEP')
        WHERE sensitivity_territory = 'Département'
    """
    )

    op.execute("REFRESH MATERIALIZED VIEW gn_sensitivity.t_sensitivity_rules_cd_ref")


def downgrade():
    op.execute(
        f"""
    DELETE FROM gn_sensitivity.cor_sensitivity_criteria sc
    USING gn_sensitivity.t_sensitivity_rules s
    WHERE sc.id_sensitivity = s.id_sensitivity
          AND s.source = '{source}'
    """
    )
    op.execute(
        f"""
    DELETE FROM gn_sensitivity.cor_sensitivity_area sa
    USING gn_sensitivity.t_sensitivity_rules s
    WHERE sa.id_sensitivity = s.id_sensitivity
          AND s.source = '{source}'
    """
    )
    op.execute(
        f"""
    DELETE FROM gn_sensitivity.t_sensitivity_rules WHERE source = '{source}'
    """
    )

    op.execute("REFRESH MATERIALIZED VIEW gn_sensitivity.t_sensitivity_rules_cd_ref")
