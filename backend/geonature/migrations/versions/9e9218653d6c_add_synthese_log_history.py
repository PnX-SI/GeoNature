"""add synthese log history

Revision ID: 9e9218653d6c
Revises: 0cae32a010ea
Create Date: 2022-04-06 15:39:37.428357

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "9e9218653d6c"
down_revision = "0cae32a010ea"
branch_labels = None
depends_on = None


def upgrade():
    op.create_table(
        "t_log_synthese",
        sa.Column("id_synthese", sa.Integer, primary_key=True),
        sa.Column("last_action", sa.CHAR(1), nullable=False),
        sa.Column("meta_last_action_date", sa.TIMESTAMP, server_default=sa.func.now()),
        schema="gn_synthese",
    )
    op.execute(
        """
    CREATE FUNCTION gn_synthese.fct_tri_log_delete_on_synthese() RETURNS TRIGGER AS
    $BODY$
    DECLARE
    BEGIN
        -- log id/uuid of deleted datas into specific log table
        IF (TG_OP = 'DELETE') THEN
            INSERT INTO gn_synthese.t_log_synthese
            SELECT
                o.id_synthese    AS id_synthese
                , 'D'                AS last_action
                , now()              AS meta_last_action_date
            from old_table o
            ON CONFLICT (id_synthese)
            DO UPDATE SET last_action = 'D', meta_last_action_date = now();
        END IF;
        RETURN NULL;
    END;
    $BODY$ LANGUAGE plpgsql COST 100
    ;
    CREATE TRIGGER tri_log_delete_synthese
        AFTER DELETE
        ON gn_synthese.synthese
        REFERENCING OLD TABLE AS old_table
        FOR EACH STATEMENT
        EXECUTE FUNCTION gn_synthese.fct_tri_log_delete_on_synthese()
    ;
    """
    )


def downgrade():
    op.drop_table("t_log_synthese", schema="gn_synthese")
    op.execute(
        """
    DROP TRIGGER IF EXISTS tri_log_delete_synthese ON gn_synthese.synthese;
    DROP FUNCTION gn_synthese.fct_tri_log_delete_on_synthese();    
    """
    )
