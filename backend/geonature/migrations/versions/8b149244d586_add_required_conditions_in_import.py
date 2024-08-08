"""add required conditions in import

Revision ID: 8b149244d586
Revises: fe3d0b49ee14
Create Date: 2024-03-20 11:17:57.360785

"""

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "8b149244d586"
down_revision = "fe3d0b49ee14"
branch_labels = None
depends_on = None


def upgrade():
    op.add_column(
        table_name="bib_fields",
        schema="gn_imports",
        column=sa.Column(
            "mandatory_conditions",
            sa.ARRAY(sa.Unicode),
            comment="Contient la liste de champs qui rendent le champ obligatoire.",
        ),
    )
    op.add_column(
        table_name="bib_fields",
        schema="gn_imports",
        column=sa.Column(
            "optional_conditions",
            sa.ARRAY(sa.Unicode),
            comment="Contient la liste de champs qui rendent le champ optionnel.",
        ),
    )

    op.execute(
        """
        CREATE OR REPLACE FUNCTION gn_imports.isInNameFields (
            fields TEXT[],destination_id INTEGER
        )
        RETURNS BOOLEAN
        AS $$
        DECLARE
            name_field_other TEXT;
        BEGIN
            IF fields IS DISTINCT FROM NULL THEN
                FOREACH name_field_other IN ARRAY fields LOOP
                    IF NOT EXISTS (
                        SELECT * 
                        FROM gn_imports.bib_fields 
                        WHERE name_field = name_field_other AND id_destination = destination_id
                        ) then
                        return FALSE;
                    END IF;
                END LOOP;
            END IF;
            return TRUE;
        END;
        $$ LANGUAGE plpgsql;
        """
    )

    op.execute(
        """
        alter table gn_imports.bib_fields
        ADD CONSTRAINT mandatory_conditions_field_exists CHECK (gn_imports.isInNameFields(mandatory_conditions,id_destination));
        """
    )
    op.execute(
        """
        alter table gn_imports.bib_fields
        ADD CONSTRAINT optional_conditions_field_exists CHECK (gn_imports.isInNameFields(optional_conditions,id_destination));
        """
    )
    conn = op.get_bind()
    metadata = sa.MetaData(bind=conn)
    destination = sa.Table("bib_destinations", metadata, schema="gn_imports", autoload_with=conn)
    synthese_dest_id = conn.scalar(
        sa.select(destination.c.id_destination).where(destination.c.code == "synthese")
    )
    field = sa.Table("bib_fields", metadata, schema="gn_imports", autoload_with=conn)
    op.execute(
        sa.update(field)
        .where(field.c.name_field == "WKT", field.c.id_destination == synthese_dest_id)
        .values(
            optional_conditions=[
                "latitude",
                "longitude",
                "codecommune",
                "codedepartement",
                "codemaille",
            ],
            mandatory=True,
        )
    )
    op.execute(
        sa.update(field)
        .where(field.c.name_field == "longitude", field.c.id_destination == synthese_dest_id)
        .values(
            optional_conditions=["WKT", "codecommune", "codedepartement", "codemaille"],
            mandatory_conditions=["latitude"],
            mandatory=True,
        )
    )
    op.execute(
        sa.update(field)
        .where(field.c.name_field == "latitude", field.c.id_destination == synthese_dest_id)
        .values(
            optional_conditions=["WKT", "codecommune", "codedepartement", "codemaille"],
            mandatory_conditions=["longitude"],
            mandatory=True,
        )
    )


def downgrade():
    op.drop_constraint("mandatory_conditions_field_exists", "bib_fields", schema="gn_imports")
    op.drop_constraint("optional_conditions_field_exists", "bib_fields", schema="gn_imports")
    op.execute("DROP FUNCTION IF EXISTS gn_imports.isInNameFields")
    op.drop_column(table_name="bib_fields", schema="gn_imports", column_name="mandatory_conditions")
    op.drop_column(table_name="bib_fields", schema="gn_imports", column_name="optional_conditions")

    conn = op.get_bind()
    metadata = sa.MetaData(bind=conn)
    destination = sa.Table("bib_destinations", metadata, schema="gn_imports", autoload_with=conn)
    synthese_dest_id = conn.scalar(
        sa.select(destination.c.id_destination).where(destination.c.code == "synthese")
    )
    field = sa.Table("bib_fields", metadata, schema="gn_imports", autoload_with=conn)
    op.execute(
        sa.update(field)
        .where(field.c.name_field == "WKT", field.c.id_destination == synthese_dest_id)
        .values(mandatory=False)
    )
    op.execute(
        sa.update(field)
        .where(field.c.name_field == "longitude", field.c.id_destination == synthese_dest_id)
        .values(mandatory=False)
    )
    op.execute(
        sa.update(field)
        .where(field.c.name_field == "latitude", field.c.id_destination == synthese_dest_id)
        .values(mandatory=False)
    )
