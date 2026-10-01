"""Replace t_habitats.id_nomenclature_community_interest with a boolean community_interest

Revision ID: 92ad888fa031
Revises: f45176d77944
Create Date: 2026-10-01 00:00:00.000000

"""

from alembic import op
import sqlalchemy as sa
from sqlalchemy.schema import MetaData
from sqlalchemy.orm.session import Session

# revision identifiers, used by Alembic.
revision = "92ad888fa031"
down_revision = "f45176d77944"
branch_labels = None
depends_on = None


def upgrade():
    conn = op.get_bind()
    metadata = MetaData()
    session = Session(bind=conn)

    ## pr_occhab.t_habitats
    op.add_column(
        "t_habitats",
        sa.Column("community_interest", sa.Boolean(), nullable=True, server_default=sa.false()),
        schema="pr_occhab",
    )
    # HAB_INTERET_COM: '1' = Oui, '2' = Non, '3' = Oui, prioritaire
    op.execute("""
        UPDATE pr_occhab.t_habitats h
        SET community_interest = true
        FROM ref_nomenclatures.t_nomenclatures n
        JOIN ref_nomenclatures.bib_nomenclatures_types t ON t.id_type = n.id_type
        WHERE n.id_nomenclature = h.id_nomenclature_community_interest
            AND t.mnemonique = 'HAB_INTERET_COM'
            AND n.cd_nomenclature IN ('1', '3')
        """)
    op.drop_constraint("check_t_habitats_community_interest", "t_habitats", schema="pr_occhab")
    op.drop_column("t_habitats", "id_nomenclature_community_interest", schema="pr_occhab")

    ## IMPORT
    op.drop_column("t_imports_occhab", "id_nomenclature_community_interest", schema="gn_imports")
    op.drop_column(
        "t_imports_occhab", "src_id_nomenclature_community_interest", schema="gn_imports"
    )
    op.add_column(
        "t_imports_occhab",
        sa.Column("src_community_interest", sa.String, nullable=True),
        schema="gn_imports",
    )
    op.add_column(
        "t_imports_occhab",
        sa.Column("community_interest", sa.Boolean, nullable=True),
        schema="gn_imports",
    )

    destination = sa.Table("bib_destinations", metadata, schema="gn_imports", autoload_with=conn)
    field = sa.Table("bib_fields", metadata, schema="gn_imports", autoload_with=conn)
    id_dest_occhab = session.scalar(
        sa.select(destination.c.id_destination).where(destination.c.code == "occhab")
    )
    session.execute(
        sa.update(field)
        .where(
            field.c.id_destination == id_dest_occhab,
            field.c.name_field == "id_nomenclature_community_interest",
        )
        .values(
            name_field="community_interest",
            fr_label="Habitat d'intérêt communautaire",
            mnemonique=None,
            source_field="src_community_interest",
            dest_field="community_interest",
            type_field="bool_checkbox",
        )
    )
    session.commit()

    op.execute("""
        UPDATE gn_imports.t_fieldmappings fm
        SET values = (
            (fm.values::jsonb - 'id_nomenclature_community_interest')
            || jsonb_build_object('community_interest', fm.values::jsonb -> 'id_nomenclature_community_interest')
        )::json
        FROM gn_imports.t_mappings m
        JOIN gn_imports.bib_destinations d ON d.id_destination = m.id_destination
        WHERE m.id = fm.id
            AND d.code = 'occhab'
            AND fm.values::jsonb ? 'id_nomenclature_community_interest'
        """)
    op.execute("""
        UPDATE gn_imports.t_contentmappings cm
        SET values = (cm.values::jsonb - 'HAB_INTERET_COM')::json
        FROM gn_imports.t_mappings m
        JOIN gn_imports.bib_destinations d ON d.id_destination = m.id_destination
        WHERE m.id = cm.id
            AND d.code = 'occhab'
            AND cm.values::jsonb ? 'HAB_INTERET_COM'
        """)


def downgrade():
    # Lossy: "Oui" and "Oui, prioritaire" can't be told apart anymore, true becomes "Oui"
    conn = op.get_bind()
    metadata = MetaData()
    session = Session(bind=conn)

    ## gn_imports mappings
    op.execute("""
        UPDATE gn_imports.t_fieldmappings fm
        SET values = (
            (fm.values::jsonb - 'community_interest')
            || jsonb_build_object('id_nomenclature_community_interest', fm.values::jsonb -> 'community_interest')
        )::json
        FROM gn_imports.t_mappings m
        JOIN gn_imports.bib_destinations d ON d.id_destination = m.id_destination
        WHERE m.id = fm.id
            AND d.code = 'occhab'
            AND fm.values::jsonb ? 'community_interest'
        """)

    ## gn_imports.bib_fields
    destination = sa.Table("bib_destinations", metadata, schema="gn_imports", autoload_with=conn)
    field = sa.Table("bib_fields", metadata, schema="gn_imports", autoload_with=conn)
    id_dest_occhab = session.scalar(
        sa.select(destination.c.id_destination).where(destination.c.code == "occhab")
    )
    session.execute(
        sa.update(field)
        .where(field.c.id_destination == id_dest_occhab, field.c.name_field == "community_interest")
        .values(
            name_field="id_nomenclature_community_interest",
            fr_label="Intérêt communautaire",
            mnemonique="HAB_INTERET_COM",
            source_field="src_id_nomenclature_community_interest",
            dest_field="id_nomenclature_community_interest",
            type_field="nomenclature",
        )
    )
    session.commit()

    ## gn_imports.t_imports_occhab (transient table)
    op.drop_column("t_imports_occhab", "community_interest", schema="gn_imports")
    op.drop_column("t_imports_occhab", "src_community_interest", schema="gn_imports")
    op.add_column(
        "t_imports_occhab",
        sa.Column("src_id_nomenclature_community_interest", sa.String, nullable=True),
        schema="gn_imports",
    )
    op.add_column(
        "t_imports_occhab",
        sa.Column(
            "id_nomenclature_community_interest",
            sa.Integer,
            sa.ForeignKey("ref_nomenclatures.t_nomenclatures.id_nomenclature"),
            nullable=True,
        ),
        schema="gn_imports",
    )

    ## pr_occhab.t_habitats
    op.add_column(
        "t_habitats",
        sa.Column(
            "id_nomenclature_community_interest",
            sa.Integer,
            sa.ForeignKey(
                "ref_nomenclatures.t_nomenclatures.id_nomenclature",
                name="fk_t_habitats_id_nomenclature_community_interest",
                onupdate="CASCADE",
            ),
            nullable=True,
        ),
        schema="pr_occhab",
    )
    op.execute("""
        UPDATE pr_occhab.t_habitats h
        SET id_nomenclature_community_interest = ref_nomenclatures.get_id_nomenclature(
            'HAB_INTERET_COM',
            CASE WHEN h.community_interest THEN '1' ELSE '2' END
        )
        """)
    op.execute("""
        ALTER TABLE pr_occhab.t_habitats ADD CONSTRAINT check_t_habitats_community_interest
        CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_community_interest, 'HAB_INTERET_COM'::character varying)) NOT VALID
        """)
    op.drop_column("t_habitats", "community_interest", schema="pr_occhab")
