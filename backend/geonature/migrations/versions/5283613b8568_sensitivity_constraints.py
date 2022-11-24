"""improve sensitivity constraints

Revision ID: 5283613b8568
Revises: c9854947fa23
Create Date: 2021-11-03 12:29:57.558220

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.sql import func, column


# revision identifiers, used by Alembic.
revision = "5283613b8568"
down_revision = "c9854947fa23"
branch_labels = None
depends_on = None

foreign_keys = {
    "fk_cor_sensitivity_area_id_sensitivity_fkey": {
        "source_schema": "gn_sensitivity",
        "source_table": "cor_sensitivity_area",
        "local_cols": ["id_sensitivity"],
        "referent_schema": "gn_sensitivity",
        "referent_table": "t_sensitivity_rules",
        "remote_cols": ["id_sensitivity"],
    },
    "criteria_id_sensitivity_fkey": {
        "source_schema": "gn_sensitivity",
        "source_table": "cor_sensitivity_criteria",
        "local_cols": ["id_sensitivity"],
        "referent_schema": "gn_sensitivity",
        "referent_table": "t_sensitivity_rules",
        "remote_cols": ["id_sensitivity"],
    },
}


def upgrade():
    # add CASCADE on existing foreign keys
    for fk, props in foreign_keys.items():
        op.drop_constraint(fk, table_name=props["source_table"], schema=props["source_schema"])
        op.create_foreign_key(fk, **props, onupdate="CASCADE", ondelete="CASCADE")

    # add missing primary key
    op.create_primary_key(
        "cor_sensitivity_criteria_pk",
        table_name="cor_sensitivity_criteria",
        columns=["id_sensitivity", "id_criteria"],
        schema="gn_sensitivity",
    )

    # add constraint to check nomenclature type coherence
    op.create_check_constraint(
        "ck_id_type_nomenclature",
        condition=func.ref_nomenclatures.check_nomenclature_type_by_id(
            column("id_criteria"), column("id_type_nomenclature")
        ),
        table_name="cor_sensitivity_criteria",
        schema="gn_sensitivity",
    )


def downgrade():
    op.drop_constraint(
        "ck_id_type_nomenclature", table_name="cor_sensitivity_criteria", schema="gn_sensitivity"
    )

    op.drop_constraint(
        "cor_sensitivity_criteria_pk",
        table_name="cor_sensitivity_criteria",
        schema="gn_sensitivity",
    )

    for fk, props in foreign_keys.items():
        op.drop_constraint(fk, table_name=props["source_table"], schema=props["source_schema"])
        op.create_foreign_key(fk, **props)
