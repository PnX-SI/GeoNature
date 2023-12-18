"""remove_archive_schema

Revision ID: 0ff8fc0b4233
Revises: 699c25251384
Create Date: 2022-05-12 09:39:45.951064

"""
import sqlalchemy as sa
from sqlalchemy.schema import Table, MetaData
from sqlalchemy.exc import NoReferenceError
from alembic import op
import pandas as pd

# revision identifiers, used by Alembic.
revision = "0ff8fc0b4233"
down_revision = "6f60b0b934b1"
branch_labels = None
depends_on = None

archive_schema = "gn_import_archives"


def upgrade():
    conn = op.get_bind()
    inspector = sa.inspect(conn.engine)
    archive_tables = inspector.get_table_names(schema="gn_import_archives")
    metadata = MetaData(bind=op.get_bind())
    imprt = Table("t_imports", metadata, autoload=True, schema="gn_imports")

    for archive_table in list(filter(lambda x: x != "cor_import_archives", archive_tables)):
        # Read table with pandas
        op.drop_column(archive_table, "gn_pk", schema="gn_import_archives")
        arch_df = pd.read_sql_table(archive_table, con=conn, schema="gn_import_archives")
        update_id = conn.execute(
            imprt.update()
            .where(imprt.c.import_table == archive_table)
            .values(
                {
                    "source_file": arch_df.to_csv(index=False).encode(),
                    "encoding": "utf-8",
                    "separator": ",",
                }
            )
            .returning(imprt.c.id_import)  # To raise error if not exists
        )
        if not update_id.rowcount:
            raise NoReferenceError(
                f"No import linked with archive table '{archive_table}'."
                " Please backup (if wanted) and delete this archive table manually."
            )
        op.drop_table(table_name=archive_table, schema=archive_schema)
        op.execute(f"DROP SEQUENCE IF EXISTS {archive_schema}.{archive_table}_gn_pk_seq")
    # Drop cor table
    op.drop_table(table_name="cor_import_archives", schema=archive_schema)
    op.execute(f"DROP SCHEMA {archive_schema}")

    tables = inspector.get_table_names(schema="gn_imports")
    for table_name in list(filter(lambda x: x.startswith("i_"), tables)):
        id_import = int(table_name.rsplit("_", 1)[-1])
        op.execute(
            f"""
        WITH cte AS (
            SELECT
                array_agg(gn_pk::int ORDER BY gn_pk::int) erroneous_rows
            FROM
                gn_imports.{table_name}
            WHERE
                gn_is_valid = 'False'
                OR
                gn_invalid_reason IS NOT NULL
        )
        UPDATE
            gn_imports.t_imports
        SET
            erroneous_rows = cte.erroneous_rows
        FROM
            cte
        WHERE
            id_import = {id_import}
        """
        )
        op.execute(
            f"""
        WITH cte AS (
            SELECT EXISTS(
                SELECT
                    1
                FROM
                    gn_imports.{table_name}
                WHERE
                    gn_is_valid IS NOT NULL
                    OR
                    gn_invalid_reason IS NOT NULL
            )
        )
        UPDATE
            gn_imports.t_imports
        SET
            processing = cte.exists
        FROM
            cte
        WHERE
            id_import = {id_import}
        """
        )
        op.drop_table(table_name=table_name, schema="gn_imports")
    op.drop_column(
        schema="gn_imports",
        table_name="t_imports",
        column_name="import_table",
    )


def downgrade():
    op.execute(f"CREATE SCHEMA {archive_schema}")
    op.execute(
        """
        CREATE TABLE gn_import_archives.cor_import_archives(
          id_import integer NOT NULL,
          table_archive character varying(255) NOT NULL
        );
    """
    )
    op.execute(
        """
            ALTER TABLE gn_imports.t_imports
            ADD COLUMN import_table character varying(255)
        """
    )
