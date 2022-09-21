"""Update synthese sensitivity, including previously NULL rows

Revision ID: 4b5478df71cb
Revises: 42040535a20e
Create Date: 2022-09-21 18:11:27.597095

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "4b5478df71cb"
down_revision = "42040535a20e"
branch_labels = None
depends_on = None


def upgrade():
    op.execute(
        """
    CREATE OR REPLACE FUNCTION gn_synthese.update_sensitivity()
     RETURNS integer
     LANGUAGE plpgsql
    AS $function$
            DECLARE
                affected_rows_count int;
            BEGIN
                WITH cte AS (
                    SELECT
                        id_synthese,
                        id_nomenclature_sensitivity AS old_sensitivity,
                        gn_sensitivity.get_id_nomenclature_sensitivity(
                          date_min::date,
                          taxonomie.find_cdref(cd_nom),
                          the_geom_local,
                          jsonb_build_object(
                            'STATUT_BIO', id_nomenclature_bio_status,
                            'OCC_COMPORTEMENT', id_nomenclature_behaviour
                          )
                        ) AS new_sensitivity
                    FROM
                        gn_synthese.synthese
                    WHERE
                        id_nomenclature_sensitivity IS NULL
                    OR
                        id_nomenclature_sensitivity != ref_nomenclatures.get_id_nomenclature('SENSIBILITE', '0') -- non sensible
                    OR
                        taxonomie.find_cdref(cd_nom) IN (SELECT DISTINCT cd_ref FROM gn_sensitivity.t_sensitivity_rules_cd_ref)
                )
                UPDATE
                    gn_synthese.synthese s
                SET
                    id_nomenclature_sensitivity = new_sensitivity
                FROM
                    cte
                WHERE
                        s.id_synthese = cte.id_synthese
                    AND (
                        old_sensitivity IS NULL
                        OR
                        old_sensitivity != new_sensitivity
                    );
                GET DIAGNOSTICS affected_rows_count = ROW_COUNT;
                RETURN affected_rows_count;
            END;
        $function$
    ;
    """
    )


def downgrade():
    op.execute(
        """
    CREATE OR REPLACE FUNCTION gn_synthese.update_sensitivity()
        RETURNS int4
        LANGUAGE plpgsql
    AS $function$
        DECLARE
            affected_rows_count int;
        BEGIN
            WITH cte AS (
                SELECT 
                    id_synthese,
                    id_nomenclature_sensitivity AS old_sensitivity,
                    gn_sensitivity.get_id_nomenclature_sensitivity(
                      date_min::date,
                      taxonomie.find_cdref(cd_nom),
                      the_geom_local,
                      jsonb_build_object(
                        'STATUT_BIO', id_nomenclature_bio_status,
                        'OCC_COMPORTEMENT', id_nomenclature_behaviour
                      )
                    ) AS new_sensitivity
                FROM
                    gn_synthese.synthese
                WHERE
                    id_nomenclature_sensitivity != ref_nomenclatures.get_id_nomenclature('SENSIBILITE', '0') -- non sensible
                OR
                    taxonomie.find_cdref(cd_nom) IN (SELECT DISTINCT cd_ref FROM gn_sensitivity.t_sensitivity_rules_cd_ref)
            )
            UPDATE
                gn_synthese.synthese s
            SET
                id_nomenclature_sensitivity = new_sensitivity
            FROM
                cte
            WHERE
                    s.id_synthese = cte.id_synthese
                AND
                    old_sensitivity != new_sensitivity;
            GET DIAGNOSTICS affected_rows_count = ROW_COUNT;
            RETURN affected_rows_count;
        END;
    $function$
    ;
    """
    )
