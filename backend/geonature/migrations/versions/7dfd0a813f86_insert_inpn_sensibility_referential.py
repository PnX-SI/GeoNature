"""Insert INPN national rules in sensitivity referential

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


lzmaopen = partial(lzmaopen, mode='rt')


# revision identifiers, used by Alembic.
revision = '7dfd0a813f86'
down_revision = None
branch_labels = ('inpn_ref_sensitivity_national',)
depends_on = 'f06cc80cc8ba'  # geonature


source = 'Référentiel sensibilité TAXREF v13 2020'
base_url = 'https://geonature.fr/data/inpn/sensitivity/'
filename = 'referentiel_donnees_sensibles_national_v13.csv.xz'


@lru_cache(maxsize=32)
def get_id_from_cd(cd_nomenc):
    return op.get_bind().execute(sa.func.ref_nomenclatures.get_id_nomenclature('SENSIBILITE', cd_nomenc)).scalar()


def upgrade():
    active = context.get_x_argument(as_dictionary=True).get('active')
    if active is not None:
        active = bool(strtobool(active))
    else:
        active = True
    conn = op.get_bind()
    metadata = sa.MetaData(bind=conn)
    sensitivity_rule = sa.Table('t_sensitivity_rules', metadata, schema='gn_sensitivity', autoload_with=conn)
    cor_sensitivity_criteria = sa.Table('cor_sensitivity_criteria', metadata, schema='gn_sensitivity', autoload_with=conn)
    nomenclature = sa.Table('t_nomenclatures', metadata, schema='ref_nomenclatures', autoload_with=conn)
    nomenclature_type = sa.Table('bib_nomenclatures_types', metadata, schema='ref_nomenclatures', autoload_with=conn)
    statut_biologique_nomenclature_type_id = conn.execute(func.ref_nomenclatures.get_id_nomenclature_type('STATUT_BIO')).scalar()
    statut_biologique_nomenclatures = list(chain.from_iterable(conn.execute(
            sa.select([nomenclature.c.cd_nomenclature]) \
            .select_from(
                nomenclature.join(nomenclature_type, nomenclature.c.id_type==nomenclature_type.c.id_type)
            ) \
            .where(nomenclature_type.c.mnemonique=='STATUT_BIO'))))
    rules = []
    criterias = []
    with open_remote_file(base_url, filename, open_fct=lzmaopen) as csvfile:
        reader = csv.DictReader(csvfile, delimiter=',')
        for row in reader:
            assert(row['perimetre'] == 'France métropolitaine')
            id_nomenc = get_id_from_cd(row['codage'])
            if row['duree']:
                duration = int(row['duree'])
            else:
                duration = 10000
            rule = {
                'cd_nom': int(row['cd_nom']),
                'nom_cite': row['nom_cite'],
                'id_nomenclature_sensitivity': id_nomenc,
                'sensitivity_duration': duration,
                'sensitivity_territory': row['perimetre'],
                'id_territory': row['cd_sig'],
                'source': f'{source}',
                'comments': row['autre'],
                'date_min': row['date_min'] if row['date_min'] else None,
                'date_max': row['date_max'] if row['date_max'] else None,
                'active': active,
            }
            if row['cd_occ_statut_biologique']:
                if row['cd_occ_statut_biologique'] in statut_biologique_nomenclatures:
                    criterias.append((len(rules), row['cd_occ_statut_biologique']))
                    rules.append(rule)
                else:
                    # We ignore this rule with outdated nomenclature
                    logger.warn("Ignore rule {} with unknown nomenclature {}".format(row['cd_sens'], row['cd_occ_statut_biologique']))
            else:
                rules.append(rule)
    results = conn.execute(sensitivity_rule \
                                .insert() \
                                .values(rules) \
                                .returning(sensitivity_rule.c.id_sensitivity))
    rules_indexes = [ rule_index for rule_index, in results ]
    conn.execute(cor_sensitivity_criteria.insert().values([
                            {
                                'id_sensitivity': rules_indexes[rule_idx],
                                'id_criteria': func.ref_nomenclatures.get_id_nomenclature('STATUT_BIO', occ),
                                'id_type_nomenclature': statut_biologique_nomenclature_type_id,
                            } for rule_idx, occ in criterias ]))

    op.execute("REFRESH MATERIALIZED VIEW gn_sensitivity.t_sensitivity_rules_cd_ref")


def downgrade():
    op.execute(f"""
    DELETE FROM gn_sensitivity.cor_sensitivity_criteria sc
    USING gn_sensitivity.t_sensitivity_rules s
    WHERE sc.id_sensitivity = s.id_sensitivity
          AND s.source = '{source}'
    """)
    op.execute(f"""
    DELETE FROM gn_sensitivity.cor_sensitivity_area sa
    USING gn_sensitivity.t_sensitivity_rules s
    WHERE sa.id_sensitivity = s.id_sensitivity
          AND s.source = '{source}'
    """)
    op.execute(f"""
    DELETE FROM gn_sensitivity.t_sensitivity_rules WHERE source = '{source}'
    """)

    op.execute("REFRESH MATERIALIZED VIEW gn_sensitivity.t_sensitivity_rules_cd_ref")
