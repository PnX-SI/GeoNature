"""add table gn_meta.cor_dataset_objectif

Revision ID: ae0b6362fb22
Revises: f6a1feb3f297
Create Date: 2026-04-27 12:58:35.383337

"""

from alembic import op
import psycopg2
import sqlalchemy as sa
import click

# revision identifiers, used by Alembic.
revision = "ae0b6362fb22"
down_revision = "1ebab31227b8"
branch_labels = None
depends_on = None


def upgrade():
    # Create "new" table
    op.execute("""
        CREATE TABLE gn_meta.cor_dataset_objectif (
            id_dataset integer NOT NULL,
            id_nomenclature_objectif integer NOT NULL DEFAULT ref_nomenclatures.get_default_nomenclature_value('JDD_OBJECTIFS')
        );
    """)
    op.execute("""
        ALTER TABLE ONLY gn_meta.cor_dataset_objectif
        ADD CONSTRAINT pk_cor_dataset_objectif 
        PRIMARY KEY (id_dataset, id_nomenclature_objectif);
    """)
    op.create_table_comment(
        "cor_dataset_objectif",
        'A dataset can have 0 or N "objective(s)".',
        schema="gn_meta",
    )
    op.create_foreign_key(
        "fk_cor_dataset_objectif_id_dataset",
        source_schema="gn_meta",
        source_table="cor_dataset_objectif",
        local_cols=["id_dataset"],
        referent_schema="gn_meta",
        referent_table="t_datasets",
        remote_cols=["id_dataset"],
        onupdate="CASCADE",
        ondelete="CASCADE",
    )
    op.create_foreign_key(
        "fk_cor_dataset_objectif_id_nomenclature_objectif",
        source_schema="gn_meta",
        source_table="cor_dataset_objectif",
        local_cols=["id_nomenclature_objectif"],
        referent_schema="ref_nomenclatures",
        referent_table="t_nomenclatures",
        remote_cols=["id_nomenclature"],
        onupdate="CASCADE",
        ondelete="NO ACTION",
    )

    # Add constraint to ensure nomenclature type is "JDD_OBJECTIFS"
    op.execute("""
        ALTER TABLE gn_meta.cor_dataset_objectif 
            ADD CONSTRAINT check_cor_dataset_objectif
            CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_objectif, 'JDD_OBJECTIFS')) NOT VALID;
        """)

    # Insert data from "old" field - i.e. `gn_meta.t_datasets.id_nomenclature_dataset_objectif` - to "new" table
    op.execute("""
        INSERT INTO gn_meta.cor_dataset_objectif (id_dataset, id_nomenclature_objectif)
        SELECT id_dataset, id_nomenclature_dataset_objectif FROM gn_meta.t_datasets;
        """)

    # Remove "old" field
    try:
        op.drop_column("t_datasets", "id_nomenclature_dataset_objectif", schema="gn_meta")
    except (psycopg2.errors.DependentObjectsStillExist, sa.exc.InternalError) as e:
        click.secho(
            """
            Error while dropping column `id_nomenclature_dataset_objectif` from table `t_datasets` in schema `gn_meta`. This is likely due to existing foreign key constraints or dependencies.
            Please ensure that there are no dependent objects (like foreign keys, views, or triggers)
            that reference this column before attempting to drop it again.
            """,
            fg="red",
        )
        click.secho(f"Original error message: {e}", fg="yellow")
        raise

    # Add a trigger that add a new entry in the new table for each new entry in t_datasets
    op.execute("""
        CREATE FUNCTION gn_meta.fct_trg_add_new_entry_in_cor_dataset_objectif()
        RETURNS TRIGGER AS $$
        BEGIN
            INSERT INTO gn_meta.cor_dataset_objectif (id_dataset)
            VALUES (NEW.id_dataset);
            RETURN NEW;
        END;
        $$ LANGUAGE plpgsql;
        """)
    op.execute("""
        CREATE TRIGGER add_new_entry_in_cor_dataset_objectif
        AFTER INSERT ON gn_meta.t_datasets
        FOR EACH ROW
        EXECUTE PROCEDURE gn_meta.fct_trg_add_new_entry_in_cor_dataset_objectif();
        """)


def downgrade():
    # Detect if there is a dataset with strictly more than objectives
    list_id_datasets_with_strictly_more_than_one_objective = op.get_bind().execute("""
        SELECT id_dataset
        FROM gn_meta.cor_dataset_objectif
        GROUP BY id_dataset
        HAVING COUNT(id_nomenclature_objectif) > 1;
        """).scalars().all()
    if list_id_datasets_with_strictly_more_than_one_objective:
        formatted_list_id_datasets = ", \n            - ".join(
            [
                str(id_dataset)
                for id_dataset in list_id_datasets_with_strictly_more_than_one_objective
            ]
        )
        raise Exception(f"""
            Downgrading is not possible because there is some dataset(s) with strictly more than one objective - the following ones (IDs):\n
            - {formatted_list_id_datasets}\n
            Please clean the table `cor_dataset_objectif` to keep at most one objective per dataset.
            """)
    else:
        # Create "old" field back
        op.add_column(
            "t_datasets",
            sa.Column(
                "id_nomenclature_dataset_objectif",
                sa.Integer,
                nullable=False,
                server_default=sa.text(
                    "ref_nomenclatures.get_default_nomenclature_value('JDD_OBJECTIFS')"
                ),
            ),
            schema="gn_meta",
        )
        op.execute("""
            COMMENT ON COLUMN gn_meta.t_datasets.id_nomenclature_dataset_objectif IS
            'Correspondance standard SINP = objectifJdd : Objectif du jeu de données tel que défini par la nomenclature ObjectifJeuDonneesValue - OBLIGATOIRE';
            """)
        op.execute("""
            ALTER TABLE ONLY gn_meta.t_datasets
            ADD CONSTRAINT fk_t_datasets_objectif FOREIGN KEY (id_nomenclature_dataset_objectif)
            REFERENCES ref_nomenclatures.t_nomenclatures(id_nomenclature) ON UPDATE CASCADE;
        """)
        op.execute("""
            ALTER TABLE gn_meta.t_datasets
            ADD CONSTRAINT check_t_datasets_objectif
            CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_dataset_objectif,'JDD_OBJECTIFS')) NOT VALID;
        """)

        # Repopulate `t_datasets.id_nomenclature_dataset_objectif` from single objectives in `cor_dataset_objectif`
        op.execute("""
            UPDATE gn_meta.t_datasets
            SET id_nomenclature_dataset_objectif = (
                SELECT id_nomenclature_objectif
                FROM gn_meta.cor_dataset_objectif
                WHERE id_dataset = gn_meta.t_datasets.id_dataset
                LIMIT 1
            );
        """)

        # Remove the "new" table
        op.drop_table("cor_dataset_objectif", schema="gn_meta")

        # Remove the trigger
        op.execute(
            "DROP FUNCTION IF EXISTS gn_meta.fct_trg_add_new_entry_in_cor_dataset_objectif();"
        )
        op.execute(
            "DROP TRIGGER IF EXISTS add_new_entry_in_cor_dataset_objectif ON gn_meta.t_datasets;"
        )
