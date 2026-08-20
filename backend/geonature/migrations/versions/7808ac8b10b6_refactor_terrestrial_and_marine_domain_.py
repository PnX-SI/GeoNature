"""refactor terrestrial and marine domain fields for metadata

Revision ID: 7808ac8b10b6
Revises: 05960b6c6292
Create Date: 2026-07-07 15:06:00.564143

"""

from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision = "7808ac8b10b6"
down_revision = "05960b6c6292"
branch_labels = None
depends_on = None


def upgrade():
    op.execute("""
        ALTER TABLE gn_meta.t_acquisition_frameworks 
        ADD COLUMN terrestrial_domain BOOLEAN NOT NULL DEFAULT False;
    """)
    op.execute("""
        ALTER TABLE gn_meta.t_acquisition_frameworks 
        ADD COLUMN marine_domain BOOLEAN NOT NULL DEFAULT False;
    """)

    op.execute(
        "COMMENT ON COLUMN gn_meta.t_acquisition_frameworks.marine_domain IS 'Indique si le cadre d''acquisition concerne le domaine marin';"
    )
    op.execute(
        "COMMENT ON COLUMN gn_meta.t_acquisition_frameworks.terrestrial_domain IS 'Indique si le cadre d''acquisition concerne le domaine terrestre';"
    )

    op.execute("""
        UPDATE gn_meta.t_acquisition_frameworks taf
        SET terrestrial_domain = True
        WHERE taf.id_acquisition_framework IN (
            SELECT cafv.id_acquisition_framework FROM gn_meta.cor_acquisition_framework_voletsinp cafv
            WHERE cafv.id_nomenclature_voletsinp = (
                SELECT tn.id_nomenclature FROM ref_nomenclatures.t_nomenclatures tn
                WHERE tn.mnemonique = 'Terre'
            )
        );
    """)
    op.execute("""
        UPDATE gn_meta.t_acquisition_frameworks taf
        SET marine_domain = True
        WHERE taf.id_acquisition_framework IN (
            SELECT cafv.id_acquisition_framework FROM gn_meta.cor_acquisition_framework_voletsinp cafv
            WHERE cafv.id_nomenclature_voletsinp = (
                SELECT tn.id_nomenclature FROM ref_nomenclatures.t_nomenclatures tn
                WHERE tn.mnemonique = 'Mer'
            )
        );
    """)
    op.execute("""
        DROP TABLE gn_meta.cor_acquisition_framework_voletsinp;
    """)

    op.execute("""
        UPDATE gn_meta.t_acquisition_frameworks taf
        SET terrestrial_domain = True
        WHERE taf.id_acquisition_framework IN (
            SELECT td.id_acquisition_framework FROM gn_meta.t_datasets td
            WHERE td.terrestrial_domain = True
        );
    """)
    op.execute("""
        UPDATE gn_meta.t_acquisition_frameworks taf
        SET marine_domain = True
        WHERE taf.id_acquisition_framework IN (
            SELECT td.id_acquisition_framework FROM gn_meta.t_datasets td
            WHERE td.marine_domain = True
        );
    """)
    op.execute("""
        ALTER TABLE gn_meta.t_datasets 
        DROP COLUMN terrestrial_domain;
    """)
    op.execute("""
        ALTER TABLE gn_meta.t_datasets 
        DROP COLUMN marine_domain;
    """)


def downgrade():
    op.execute("""
        ALTER TABLE gn_meta.t_datasets 
        ADD COLUMN terrestrial_domain BOOLEAN NOT NULL DEFAULT False;
    """)
    op.execute("""
        ALTER TABLE gn_meta.t_datasets 
        ADD COLUMN marine_domain BOOLEAN NOT NULL DEFAULT False;
    """)

    op.execute("""
        UPDATE gn_meta.t_datasets
        SET terrestrial_domain = af.terrestrial_domain
        from gn_meta.t_acquisition_frameworks as af
        where gn_meta.t_datasets.id_acquisition_framework = af.id_acquisition_framework
    """)

    op.execute("""
            UPDATE gn_meta.t_datasets
            SET marine_domain = af.marine_domain
            from gn_meta.t_acquisition_frameworks as af
            where gn_meta.t_datasets.id_acquisition_framework = af.id_acquisition_framework
        """)

    op.execute("""
        CREATE TABLE gn_meta.cor_acquisition_framework_voletsinp (
            id_acquisition_framework integer NOT NULL,
            id_nomenclature_voletsinp integer NOT NULL
        );
    """)
    op.execute("""
        COMMENT ON TABLE gn_meta.cor_acquisition_framework_voletsinp IS 'A acquisition framework can have 0 or n "voletSINP". Implement 1.3.10 SINP metadata standard : Volet du SINP concerné par le dispositif de collecte, tel que défini dans la nomenclature voletSINPValue - FACULTATIF';
    """)
    op.execute("""
       INSERT INTO gn_meta.cor_acquisition_framework_voletsinp
       SELECT 
            taf.id_acquisition_framework, 
            (
                SELECT tn.id_nomenclature FROM ref_nomenclatures.t_nomenclatures tn
                WHERE tn.mnemonique = 'Terre'
            )
        FROM gn_meta.t_acquisition_frameworks taf
        WHERE taf.terrestrial_domain = True;
    """)
    op.execute("""
        ALTER TABLE gn_meta.t_acquisition_frameworks 
        DROP COLUMN terrestrial_domain;
    """)
    op.execute("""
        ALTER TABLE gn_meta.t_acquisition_frameworks 
        DROP COLUMN marine_domain;
    """)
