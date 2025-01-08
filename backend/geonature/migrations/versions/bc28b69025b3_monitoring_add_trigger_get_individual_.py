"""[monitoring] Add trigger get individual cd_nom

Revision ID: bc28b69025b3
Revises: 5b61bcaa18da
Create Date: 2025-01-07 14:50:55.877316

"""

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "bc28b69025b3"
down_revision = "5b61bcaa18da"
branch_labels = None
depends_on = None


def upgrade():
    # Création trigger mise à jour du cd_nom de la table des observations
    #   lors d'une modification d'un cd_nom d'un individu
    op.execute(
        """
    CREATE OR REPLACE FUNCTION gn_monitoring.fct_trg_t_individuals_t_observations_cd_nom()
    RETURNS trigger
    LANGUAGE plpgsql
    AS $function$
    BEGIN

        -- Mise à jour du cd_nom de la table observation
        IF
            NEW.id_individual = OLD.id_individual
        THEN
            UPDATE gn_monitoring.t_observations SET cd_nom = NEW.cd_nom WHERE id_individual = NEW.id_individual;
        END IF;

    RETURN NEW;
    END;
    $function$
    ;

    CREATE TRIGGER trg_update_t_observations_cd_nom
        AFTER   UPDATE
        ON gn_monitoring.t_individuals 
        FOR EACH ROW
        EXECUTE PROCEDURE gn_monitoring.fct_trg_t_individuals_t_observations_cd_nom();
    """
    )

    # Création d'un trigger qui peuple le champ cd_nom de la table t_observation à partir
    #   des données de l'individus selectionné
    op.execute(
        """

    CREATE OR REPLACE FUNCTION gn_monitoring.fct_trg_t_observations_cd_nom()
    RETURNS trigger
    LANGUAGE plpgsql
    AS $function$
    BEGIN

        -- Récupération du cd_nom depuis la table des individus
        IF
            NOT NEW.id_individual IS NULL
        THEN
        NEW.cd_nom := (SELECT cd_nom FROM gn_monitoring.t_individuals ti WHERE id_individual = NEW.id_individual);
        END IF;

    RETURN NEW;
    END;
    $function$
    ;


    CREATE TRIGGER trg_update_cd_nom
        BEFORE INSERT OR UPDATE
        ON gn_monitoring.t_observations
        FOR EACH ROW
        EXECUTE PROCEDURE gn_monitoring.fct_trg_t_observations_cd_nom();
"""
    )


def downgrade():
    op.execute(
        """
        DROP TRIGGER trg_update_t_observations_cd_nom ON gn_monitoring.t_individuals;
        DROP FUNCTION gn_monitoring.fct_trg_t_individuals_t_observations_cd_nom();
    """
    )
    op.execute(
        """
        DROP TRIGGER trg_update_cd_nom ON gn_monitoring.t_observations;
        DROP FUNCTION gn_monitoring.fct_trg_t_observations_cd_nom();
    """
    )
