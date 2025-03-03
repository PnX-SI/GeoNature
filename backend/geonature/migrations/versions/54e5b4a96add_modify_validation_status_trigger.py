"""modify validation status trigger

Revision ID: 54e5b4a96add
Revises: 5cf0ce9e669c
Create Date: 2025-02-24 11:53:22.915133

"""

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "54e5b4a96add"
down_revision = "5cf0ce9e669c"
branch_labels = None
depends_on = None


def upgrade():
    op.execute(
        """
    CREATE OR REPLACE FUNCTION gn_commons.fct_trg_update_synthese_validation_status()
    RETURNS trigger AS
    $BODY$
    -- This trigger function update validation informations in corresponding row in synthese table
    BEGIN
        UPDATE gn_synthese.synthese 
        SET id_nomenclature_valid_status = NEW.id_nomenclature_valid_status,
        validation_comment = NEW.validation_comment,
        meta_validation_date = NEW.validation_date,
        validator = (SELECT nom_role || ' ' || prenom_role FROM utilisateurs.t_roles WHERE id_role = NEW.id_validator)::text
        WHERE unique_id_sinp = NEW.uuid_attached_row;
        RETURN NEW;
    END;
    $BODY$
        LANGUAGE plpgsql VOLATILE
        COST 100;
    """
    )

    op.execute(
        """
        WITH cte_max_date AS (
            SELECT
                uuid_attached_row,
                MAX(validation_date) AS validation_date
            FROM
                gn_commons.t_validations
            GROUP BY
                uuid_attached_row
        )
        UPDATE
            gn_synthese.synthese
        SET
            meta_validation_date = cte_max_date.validation_date
        FROM
            cte_max_date
        WHERE
            gn_synthese.synthese.unique_id_sinp = cte_max_date.uuid_attached_row;
        """
    )

    op.alter_column(
        table_name="t_validations",
        column_name="validation_date",
        server_default=sa.func.now(),
        schema="gn_commons",
    )


def downgrade():
    op.alter_column(
        table_name="t_validations",
        column_name="validation_date",
        server_default=sa.null(),
        schema="gn_commons",
    )

    op.execute(
        """
    CREATE OR REPLACE FUNCTION fct_trg_update_synthese_validation_status()
    RETURNS trigger AS
    $BODY$
    -- This trigger function update validation informations in corresponding row in synthese table
    BEGIN
        UPDATE gn_synthese.synthese 
        SET id_nomenclature_valid_status = NEW.id_nomenclature_valid_status,
        validation_comment = NEW.validation_comment,
        validator = (SELECT nom_role || ' ' || prenom_role FROM utilisateurs.t_roles WHERE id_role = NEW.id_validator)::text
        WHERE unique_id_sinp = NEW.uuid_attached_row;
        RETURN NEW;
    END;
    $BODY$
        LANGUAGE plpgsql VOLATILE
        COST 100;
    """
    )
