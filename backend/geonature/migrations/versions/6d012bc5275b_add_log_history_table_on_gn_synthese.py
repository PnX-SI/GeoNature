"""add log history table on gn_synthese

Revision ID: 6d012bc5275b
Revises: f06cc80cc8ba
Create Date: 2021-09-06 08:42:03.702116

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.sql.expression import null
import sqlalchemy.types as types




# revision identifiers, used by Alembic.
revision = '6d012bc5275b'
down_revision = 'f06cc80cc8ba'
branch_labels = None
depends_on = None


def upgrade():
    op.execute("set search_path to gn_synthese")
    op.create_table(
        't_log_synthese',
        sa.Column('id_synthese', sa.Integer, primary_key=True),
        sa.Column('unique_id_sinp', UUID(as_uuid=True), nullable=False),
        sa.Column('last_action', sa.CHAR(1), nullable=False),
        sa.Column('meta_last_action_date', sa.TIMESTAMP, server_default=sa.func.now())
        )
    op.execute("""
    CREATE OR REPLACE FUNCTION gn_synthese.fct_trig_log_delete_on_synthese() RETURNS TRIGGER AS
$BODY$
DECLARE
BEGIN
    -- log id/uuid of deleted datas into specific log table
    INSERT INTO gn_synthese.t_log_synthese
    SELECT
        old.id_synthese    AS id_synthese
      , old.unique_id_sinp AS unique_id_sinp
      , 'D'                AS last_action
      , now()              AS meta_last_action_date
      ON CONFLICT (id_synthese)
      DO UPDATE SET last_action = 'D', meta_action_date = now();
    RETURN NULL;
END;
$BODY$ LANGUAGE plpgsql COST 100
;

CREATE TRIGGER tri_log_delete_synthese
    AFTER DELETE
    ON gn_synthese.synthese
    FOR EACH ROW
EXECUTE PROCEDURE gn_synthese.fct_trig_log_delete_on_synthese()
;

CREATE VIEW gn_synthese.v_log_synthese AS
(
WITH
    t1 AS (SELECT
               id_synthese
             , unique_id_sinp
             , last_action
             , meta_last_action_date
               FROM
                   gn_synthese.t_log_synthese
           UNION
           SELECT
               id_synthese
             , unique_id_sinp
             , last_action
             , coalesce(meta_update_date, meta_create_date)
               FROM
                   gn_synthese.synthese)
SELECT *
    FROM
        t1
    ORDER BY
        meta_last_action_date DESC)
;
    """)
    op.execute("reset search_path;")


def downgrade():
    op.execute("set search_path to gn_synthese;")
    op.drop_table('testlog')
    op.execute("""
    DROP VIEW IF EXISTS gn_synthese.v_log_synthese;
    DROP TRIGGER tri_log_delete_synthese on table gn_synthese.synthese;
    DROP FUNCTION gn_synthese.fct_trig_log_delete_on_synthese() ;    
    """)
    op.execute("reset search_path;")


