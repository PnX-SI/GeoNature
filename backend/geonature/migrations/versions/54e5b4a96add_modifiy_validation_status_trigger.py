"""modifiy validation status trigger

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
        DROP TRIGGER IF EXISTS tri_insert_synthese_update_validation_status ON gn_commons.t_validations
        """
    )
    op.execute(
        """
        create trigger tri_insert_synthese_update_validation_status 
        AFTER INSERT
            on
            gn_commons.t_validations for each row execute function gn_commons.fct_trg_update_synthese_validation_status()
        """
    )
    conn = op.get_bind()
    metadata = sa.MetaData(bind=conn)
    synthese = sa.Table("synthese", metadata, schema="gn_synthese", autoload_with=conn)
    t_validations = sa.Table("t_validations", metadata, schema="gn_commons", autoload_with=conn)
    op.execute(
        sa.update(synthese)
        .where(synthese.c.unique_id_sinp == t_validations.c.uuid_attached_row)
        .values(meta_validation_date=t_validations.c.validation_date)
    )

    op.alter_column(
        table_name="t_validations",
        column_name="validation_date",
        server_default=sa.func.now(),
        schema="gn_commons",
    )


def downgrade():
    op.alter_column(
        table_name="gn_commons.t_validations",
        column_name="validation_date",
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
    op.execute(
        """
        DROP TRIGGER IF EXISTS tri_insert_synthese_update_validation_status ON gn_commons.t_validations
        """
    )
    op.execute(
        """
        create trigger tri_insert_synthese_update_validation_status 
        AFTER INSERT
            on
            gn_commons.t_validations for each row execute function gn_commons.fct_trg_update_synthese_validation_status()
        """
    )
