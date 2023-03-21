"""Trigger log on each statement

Revision ID: 9b7b5cbd7931
Revises: 1dbc45309d6e
Create Date: 2022-02-16 16:07:06.781270

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '9b7b5cbd7931'
down_revision = '1dbc45309d6e'
branch_labels = None
depends_on = None


def upgrade():
    op.execute(
        """
        CREATE OR REPLACE FUNCTION gn_commons.fct_trg_log_changes_on_each_statement()
        RETURNS trigger
        LANGUAGE plpgsql
        AS $function$
        DECLARE
            theschema text := quote_ident(TG_TABLE_SCHEMA);
            thetable text := quote_ident(TG_TABLE_NAME);
            theidtablelocation int;
            theuuidfieldname character varying(50);
            theuuid uuid;
            theoperation character(1);
            thecontent json;
        BEGIN
            --Retrouver l'id de la table source stockant l'enregistrement à tracer
            SELECT INTO theidtablelocation gn_commons.get_table_location_id(theschema,thetable);
            --Retouver le nom du champ stockant l'uuid de l'enregistrement à tracer
            SELECT INTO theuuidfieldname gn_commons.get_uuid_field_name(theschema,thetable);
            --Retrouver la première lettre du type d'opération (C, U, ou D)
            SELECT INTO theoperation LEFT(TG_OP,1);
            --Construction du JSON du contenu de l'enregistrement tracé
            IF(TG_OP = 'INSERT' OR TG_OP = 'UPDATE') THEN
                EXECUTE format(
                'INSERT INTO gn_commons.t_history_actions (id_table_location, operation_type, uuid_attached_row, operation_date, table_content)
                    SELECT $1, $2 , %I,  NOW(), row_to_json(NEW.*)
                    FROM NEW;', theuuidfieldname 
                ) USING theidtablelocation, theoperation;
            ELSIF (TG_OP = 'DELETE') THEN
                EXECUTE format(
                'INSERT INTO gn_commons.t_history_actions (id_table_location, operation_type, uuid_attached_row, operation_date, table_content)
                    SELECT $1, $2 , %I,  NOW(), row_to_json(OLD.*)
                    FROM OLD;', theuuidfieldname 
                ) USING theidtablelocation, theoperation;

            END IF;
        RETURN NULL;
        END;
        $function$
        ;
        """
    )


def downgrade():
    op.execute(
        """
        DROP FUNCTION gn_commons.fct_trg_log_changes_on_each_statement();
        """
    )
