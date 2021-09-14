"""Insert sensitivity data

Revision ID: c5be12904088
Create Date: 2021-09-14 10:41:56.834432

"""
from alembic import op
from shutil import copyfileobj

from geonature.migrations.utils import (
    logger,
    open_remote_file,
    delete_area_with_type,
)

# revision identifiers, used by Alembic.
revision = 'c5be12904088'
down_revision = None
branch_labels = ('sensitivity_inpn_rules',)
depends_on = ('ref_geo_fr_departments')

filename = 'referentiel_donnees_sensibles_v13.csv.xz'
base_url = 'https://geonature.fr/data/inpn/sensitivity/'
temp_table_name = 'gn_sensitivity.tmp_liste_taxons_sensibles'

def upgrade():
    logger.info("Create {temp_table_name}")
    op.execute(f"""
    CREATE TABLE {temp_table_name}
    (
        cd_sens int,
        cd_nom int,
        nom_cite varchar(500),
        grain varchar(250),
        duree int,
        perimetre varchar(250),
        autre  varchar(500),
        codage char(1),
        cd_sl int,
        cd_sig varchar(50),
        cd_occ_statut_biologique varchar(2),
        date_min date,
        date_max date
    );
    """)
    cursor = op.get_bind().connection.cursor()
    with open_remote_file(base_url, filename) as csvfile:
        logger.info("Inserting sensitivity data in temporary table {table_name}")
        cursor.copy_expert(f"COPY {temp_table_name} FROM STDIN DELIMITER ',' CSV HEADER", csvfile)
    logger.info("Import data in gn_sensitivity.t_sensitivity_rules")
    op.execute(f"""
        -- ## Import des données dans le modèle
        INSERT INTO gn_sensitivity.t_sensitivity_rules(
            id_sensitivity, cd_nom,nom_cite, id_nomenclature_sensitivity, sensitivity_duration,
            sensitivity_territory, id_territory, source, comments, date_min, date_max
        )
        SELECT
            cd_sens, cd_nom, nom_cite,
            ref_nomenclatures.get_id_nomenclature('SENSIBILITE', codage),
            COALESCE(duree, 10000),
            perimetre, cd_sig, 'Compilation national',
            autre, date_min, date_max
            FROM {temp_table_name};
    """)
    logger.info("import criterias")
    op.execute(f"""
        -- ## import des critères
        INSERT INTO  gn_sensitivity.cor_sensitivity_criteria(
            id_sensitivity,
            id_criteria,
            id_type_nomenclature
        )
        SELECT 
            cd_sens as  id_sensitivity,
            ref_nomenclatures.get_id_nomenclature('STATUT_BIO', cd_occ_statut_biologique) as id_criteria,
            (SELECT id_type FROM ref_nomenclatures.bib_nomenclatures_types  WHERE mnemonique= 'STATUT_BIO')
            FROM  {temp_table_name}
            WHERE NOT cd_occ_statut_biologique IS NULL;
    """)
    logger.info("link sensitivity with l_areas(departments")
    op.execute(f"""
        -- Import des départements
        INSERT INTO gn_sensitivity.cor_sensitivity_area(id_sensitivity, id_area)
        SELECT DISTINCT
            id_sensitivity, id_area
            FROM gn_sensitivity.t_sensitivity_rules s
            JOIN ref_geo.l_areas
            ON REPLACE(id_territory, 'INSEED', '') = area_code
                AND id_type = (SELECT id_type FROM ref_geo.bib_areas_types  WHERE type_code ='DEP')
            WHERE id_territory LIKE 'INSEED%' ;
    """)

    op.execute(f'DROP TABLE {temp_table_name}')

def downgrade():
    op.execute(f"""
        DELETE FROM gn_sensitivity.cor_sensitivity_area;
        DELETE FROM gn_sensitivity.cor_sensitivity_criteria;
        DELETE FROM gn_sensitivity.t_sensitivity_rules,
    """)
