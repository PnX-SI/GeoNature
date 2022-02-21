"""Add table to link bdc_status and ref_geo

Revision ID: f350e23bee07
Revises: 1eb624249f2b
Create Date: 2021-09-24 17:39:42.062506

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = 'f350e23bee07'
down_revision = '1dbc45309d6e'
branch_labels = None
depends_on = None


def upgrade():
    op.execute("""
    CREATE TABLE ref_geo.cor_area_status (
        cd_sig varchar(25) NOT NULL,
        id_area int4 NOT NULL,
        CONSTRAINT pk_cor_area_status PRIMARY KEY (cd_sig, id_area),
        CONSTRAINT fk_cor_area_status_id_area FOREIGN KEY (id_area) REFERENCES ref_geo.l_areas(id_area) ON UPDATE CASCADE
    )
    """)
    op.execute("""
    INSERT INTO ref_geo.cor_area_status (
        WITH old_regions AS (
                SELECT
                    '11' AS code, -- Île-de-France
                    id_area
                FROM ref_geo.l_areas
                WHERE id_type = ref_geo.get_id_area_type('DEP')
                    AND area_code IN ('75','77','78','91','92','93','94','95')
            UNION
                SELECT
                    '21' AS code, -- Champagne-Ardenne
                    id_area
                FROM ref_geo.l_areas
                WHERE id_type = ref_geo.get_id_area_type('DEP')
                    AND area_code IN ('08','10','51','52')
            UNION
                SELECT
                    '22' AS code, -- Picardie
                    id_area
                FROM ref_geo.l_areas
                WHERE id_type = ref_geo.get_id_area_type('DEP')
                    AND area_code IN ('02','60','80')
            UNION
                SELECT
                    '23' AS code, -- Haute-Normandie
                    id_area
                FROM ref_geo.l_areas
                WHERE id_type = ref_geo.get_id_area_type('DEP')
                    AND area_code IN ('27', '76')
            UNION
                SELECT
                    '24' AS code, -- Centre
                    id_area
                FROM ref_geo.l_areas
                WHERE id_type = ref_geo.get_id_area_type('DEP')
                    AND area_code IN ('18','28','36','37','41','45')
            UNION
                SELECT
                    '25' AS code, -- Basse-Normandie
                    id_area
                FROM ref_geo.l_areas
                WHERE id_type = ref_geo.get_id_area_type('DEP')
                    AND area_code IN ('14','50','61')
            UNION
                SELECT
                    '26' AS code, -- Bourgogne
                    id_area
                FROM ref_geo.l_areas
                WHERE id_type = ref_geo.get_id_area_type('DEP')
                    AND area_code IN ('21','58','71','89')
            UNION
                SELECT
                    '31' AS code, -- Nord-Pas-de-Calais
                    id_area
                FROM ref_geo.l_areas
                WHERE id_type = ref_geo.get_id_area_type('DEP')
                    AND area_code IN ('59', '62')
            UNION
                SELECT
                    '41' AS code, -- Lorraine
                    id_area
                FROM ref_geo.l_areas
                WHERE id_type = ref_geo.get_id_area_type('DEP')
                    AND area_code IN ('54','55','57','88')
            UNION
                SELECT
                    '42' AS code, -- Alsace
                    id_area
                FROM ref_geo.l_areas
                WHERE id_type = ref_geo.get_id_area_type('DEP')
                    AND area_code IN ('67', '68')
            UNION
                SELECT
                    '43' AS code, -- Franche-Comté
                    id_area
                FROM ref_geo.l_areas
                WHERE id_type = ref_geo.get_id_area_type('DEP')
                    AND area_code IN ('25','39','70','90')
            UNION
                SELECT
                    '52' AS code, -- Pays de la Loire
                    id_area
                FROM ref_geo.l_areas
                WHERE id_type = ref_geo.get_id_area_type('DEP')
                    AND area_code IN ('44','49','53','72','85')
            UNION
                SELECT
                    '53' AS code, -- Bretagne
                    id_area
                FROM ref_geo.l_areas
                WHERE id_type = ref_geo.get_id_area_type('DEP')
                    AND area_code IN ('22','29','35','56')
            UNION
                SELECT
                    '54' AS code, -- Poitou-Charentes
                    id_area
                FROM ref_geo.l_areas
                WHERE id_type = ref_geo.get_id_area_type('DEP')
                    AND area_code IN ('16','17','79','86')
            UNION
                SELECT
                    '72' AS code, -- Aquitaine
                    id_area
                FROM ref_geo.l_areas
                WHERE id_type = ref_geo.get_id_area_type('DEP')
                    AND area_code IN ('24','33','40','47','64')
            UNION
                SELECT
                    '73' AS code, -- Midi-Pyrénées
                    id_area
                FROM ref_geo.l_areas
                WHERE id_type = ref_geo.get_id_area_type('DEP')
                    AND area_code IN ('9','12','31','32','46','65','81','82')
            UNION
                SELECT
                    '74' AS code, -- Limousin
                    id_area
                FROM ref_geo.l_areas
                WHERE id_type = ref_geo.get_id_area_type('DEP')
                    AND area_code IN ('19','23','87')
            UNION
                SELECT
                    '82' AS code, -- Rhône-Alpes
                    id_area
                FROM ref_geo.l_areas
                WHERE id_type = ref_geo.get_id_area_type('DEP')
                    AND area_code IN ('01','07','26','38','42','69','73','74')
            UNION
                SELECT
                    '83' AS code, -- Auvergne
                    id_area
                FROM ref_geo.l_areas
                WHERE id_type = ref_geo.get_id_area_type('DEP')
                    AND area_code IN ('03', '15', '43', '63')
            UNION
                SELECT
                    '91' AS code, -- Languedoc-Roussillon
                    id_area
                FROM ref_geo.l_areas
                WHERE id_type = ref_geo.get_id_area_type('DEP')
                    AND area_code IN ('11','30','34','48','66')
            UNION
                SELECT
                    '93' AS code, -- Provence-Alpes-Côte d’Azur
                    id_area
                FROM ref_geo.l_areas
                WHERE id_type = ref_geo.get_id_area_type('DEP')
                    AND area_code IN ('04', '05', '06', '13', '83', '84')
            UNION
                SELECT
                    '94' AS code, -- Corse
                    id_area
                FROM ref_geo.l_areas
                WHERE id_type = ref_geo.get_id_area_type('DEP')
                    AND area_code IN ('2A', '2B')
        ),
        new_regions AS (
                SELECT
                    '11' AS code, -- Île-de-France
                    id_area
                FROM ref_geo.l_areas
                WHERE id_type = ref_geo.get_id_area_type('DEP')
                    AND area_code IN ('75','77','78','91','92','93','94','95')
            UNION
                SELECT
                    '24' AS code, -- Centre-Val de Loire
                    id_area
                FROM ref_geo.l_areas
                WHERE id_type = ref_geo.get_id_area_type('DEP')
                    AND area_code IN ('18','28','36','37','41','45')
            UNION
                SELECT
                    '27' AS code, -- Bourgogne-Franche-Comté
                    id_area
                FROM ref_geo.l_areas
                WHERE id_type = ref_geo.get_id_area_type('DEP')
                    AND area_code IN ('21','25','39','58','70','71','89','90')
            UNION
                SELECT
                    '28' AS code, -- Normandie
                    id_area
                FROM ref_geo.l_areas
                WHERE id_type = ref_geo.get_id_area_type('DEP')
                    AND area_code IN ('14','27','50','61','76')
            UNION
                SELECT
                    '32' AS code, -- Hauts-de-France
                    id_area
                FROM ref_geo.l_areas
                WHERE id_type = ref_geo.get_id_area_type('DEP')
                    AND area_code IN ('02', '59', '60', '62', '80')
            UNION
                SELECT
                    '44' AS code, -- Grand Est
                    id_area
                FROM ref_geo.l_areas
                WHERE id_type = ref_geo.get_id_area_type('DEP')
                    AND area_code IN ('08','10','51','52','54','55','57','67','68','88')
            UNION
                SELECT
                    '52' AS code, -- Pays de la Loire
                    id_area
                FROM ref_geo.l_areas
                WHERE id_type = ref_geo.get_id_area_type('DEP')
                    AND area_code IN ('44','49','53','72','85')
            UNION
                SELECT
                    '53' AS code, -- Bretagne
                    id_area
                FROM ref_geo.l_areas
                WHERE id_type = ref_geo.get_id_area_type('DEP')
                    AND area_code IN ('22','29','35','56')
            UNION
                SELECT
                    '75' AS code, -- Nouvelle-Aquitaine
                    id_area
                FROM ref_geo.l_areas
                WHERE id_type = ref_geo.get_id_area_type('DEP')
                    AND area_code IN ('16','17','19','23','24','33','40','47','64','79','86','87')
            UNION
                SELECT
                    '76' AS code, -- Occitanie
                    id_area
                FROM ref_geo.l_areas
                WHERE id_type = ref_geo.get_id_area_type('DEP')
                    AND area_code IN ('09', '11', '12', '30', '31', '32', '34', '46', '48', '65', '66', '81', '82')
            UNION
                SELECT
                    '84' AS code, -- Auvergne-Rhône-Alpes
                    id_area
                FROM ref_geo.l_areas
                WHERE id_type = ref_geo.get_id_area_type('DEP')
                    AND area_code IN ('01', '03', '07', '15', '26', '38', '42', '43', '63', '69', '73', '74')
            UNION
                SELECT
                    '93' AS code, -- Provence-Alpes-Côte d’Azur
                    id_area
                FROM ref_geo.l_areas
                WHERE id_type = ref_geo.get_id_area_type('DEP')
                    AND area_code IN ('04', '05', '06', '13', '83', '84')
            UNION
                SELECT
                    '94' AS code, -- Corse
                    id_area
                FROM ref_geo.l_areas
                WHERE id_type = ref_geo.get_id_area_type('DEP')
                    AND area_code IN ('2A', '2B')
        ),
        sig AS (
                SELECT
                    'ETATFRA' AS cd_sig,
                    la.id_area
                FROM ref_geo.l_areas AS la
                WHERE la.id_type = ref_geo.get_id_area_type('DEP')
            UNION
                SELECT DISTINCT
                    cd_sig,
                    (
                        SELECT id_area
                        FROM ref_geo.l_areas
                        WHERE area_code = REPLACE(cd_sig, 'INSEED', '')
                            AND id_type = ref_geo.get_id_area_type('DEP')
                    )
                FROM taxonomie.bdc_statut_text AS bst
                WHERE cd_sig ILIKE 'INSEED%'
            UNION
                SELECT DISTINCT
                    cd_sig,
                    nrs.id_area
                FROM taxonomie.bdc_statut_text AS bst
                    JOIN new_regions AS nrs ON (REPLACE(cd_sig, 'INSEENR', '') = nrs.code)
                WHERE cd_sig ILIKE 'INSEENR%'
            UNION
                SELECT DISTINCT
                    cd_sig,
                    ors.id_area
                FROM taxonomie.bdc_statut_text AS bst
                    JOIN old_regions AS ors ON (REPLACE(cd_sig, 'INSEER', '') = ors.code)
                WHERE cd_sig ILIKE 'INSEER%'
            UNION
                SELECT
                    'TERFXFR' AS cd_sig,
                    la.id_area
                FROM ref_geo.l_areas AS la
                WHERE la.id_type = ref_geo.get_id_area_type('DEP')
        )
        SELECT s.*
        FROM sig AS s
        WHERE s.id_area IS NOT NULL
        ORDER BY s.cd_sig, s.id_area ASC
    )""")
    op.execute("CREATE INDEX idx_cabs_cd_sig ON ref_geo.cor_area_status(cd_sig);")


def downgrade():
    op.execute("DROP TABLE ref_geo.cor_area_status")
