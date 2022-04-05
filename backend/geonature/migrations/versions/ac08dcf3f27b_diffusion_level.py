"""Do not auto-compute diffusion_level

Revision ID: ac08dcf3f27b
Revises: dfec5f64ac73
Create Date: 2022-02-10 12:45:05.472204

"""
from distutils.util import strtobool

from alembic import op, context
import sqlalchemy as sa

from utils_flask_sqla.migrations.utils import logger


# revision identifiers, used by Alembic.
revision = "ac08dcf3f27b"
down_revision = "dfec5f64ac73"
branch_labels = None
depends_on = None


"""
- Lors de l’insertion de données dans la synthèse, seule la sensibilité est calculé,
  le niveau de diffusion est maintenant intouché.
- Le calcul de la sensibilité prend en compte le critère OCC_COMPORTEMENT en plus du
  critère STATUT_BIO existant.
- Le trigger d’update de la synthèse est passé de AFTER à BEFORE, évitant d’effectuer
  un deuxième UPDATE pour mettre à jour la sensibilité.
- Met NULL dans synthese.id_nomenclature_diffusion_level quand le niveau de diffusion
  actuel correspond au niveau de sensibilité (laissé tel quel s’il ne correspond pas).
"""


def upgrade():
    clear_diffusion_level = context.get_x_argument(as_dictionary=True).get("clear-diffusion-level")
    if clear_diffusion_level is not None:
        clear_diffusion_level = bool(strtobool(clear_diffusion_level))
    else:
        clear_diffusion_level = True

    op.execute(
        """
        DROP TRIGGER tri_insert_calculate_sensitivity ON gn_synthese.synthese
    """
    )
    op.execute(
        """
        DROP TRIGGER tri_update_calculate_sensitivity ON gn_synthese.synthese
    """
    )
    op.execute(
        """
        DROP FUNCTION gn_synthese.fct_tri_cal_sensi_diff_level_on_each_statement
    """
    )
    op.execute(
        """
        DROP FUNCTION gn_synthese.fct_tri_cal_sensi_diff_level_on_each_row
    """
    )
    op.execute(
        """
        CREATE FUNCTION gn_synthese.fct_tri_calculate_sensitivity_on_each_statement()
         RETURNS trigger
         LANGUAGE plpgsql
        AS $function$ 
            -- Calculate sensitivity on insert in synthese
            BEGIN
            WITH cte AS (
              SELECT 
                id_synthese,
                gn_sensitivity.get_id_nomenclature_sensitivity(
                  new_row.date_min::date, 
                  taxonomie.find_cdref(new_row.cd_nom), 
                  new_row.the_geom_local,
                  jsonb_build_object(
                    'STATUT_BIO', new_row.id_nomenclature_bio_status,
                    'OCC_COMPORTEMENT', new_row.id_nomenclature_behaviour
                  )
                ) AS id_nomenclature_sensitivity
              FROM
                NEW AS new_row
            )
            UPDATE
              gn_synthese.synthese AS s
            SET 
              id_nomenclature_sensitivity = c.id_nomenclature_sensitivity
            FROM
              cte AS c
            WHERE
              c.id_synthese = s.id_synthese
            ;
            RETURN NULL;
            END;
          $function$
        ;
    """
    )
    op.execute(
        """
        CREATE FUNCTION gn_synthese.fct_tri_update_sensitivity_on_each_row()
         RETURNS trigger
         LANGUAGE plpgsql
        AS $function$ 
            -- Calculate sensitivity on update in synthese
            BEGIN
            NEW.id_nomenclature_sensitivity = gn_sensitivity.get_id_nomenclature_sensitivity(
                NEW.date_min::date, 
                taxonomie.find_cdref(NEW.cd_nom), 
                NEW.the_geom_local,
                jsonb_build_object(
                  'STATUT_BIO', NEW.id_nomenclature_bio_status,
                  'OCC_COMPORTEMENT', NEW.id_nomenclature_behaviour
                )
            );
            RETURN NEW;
            END;
          $function$
        ;
    """
    )
    op.execute(
        """
        CREATE TRIGGER
            tri_insert_calculate_sensitivity
        AFTER
            INSERT
        ON
            gn_synthese.synthese
        REFERENCING
            NEW TABLE AS NEW
        FOR EACH
            STATEMENT
        EXECUTE PROCEDURE
            gn_synthese.fct_tri_calculate_sensitivity_on_each_statement()
    """
    )
    op.execute(
        """
        CREATE TRIGGER
            tri_update_calculate_sensitivity
        BEFORE UPDATE OF
            date_min,
            date_max,
            cd_nom,
            the_geom_local,
            id_nomenclature_bio_status,
            id_nomenclature_behaviour
        ON
            gn_synthese.synthese
        FOR EACH
            ROW
        EXECUTE PROCEDURE
            gn_synthese.fct_tri_update_sensitivity_on_each_row()
    """
    )

    if clear_diffusion_level:
        logger.info("Clearing diffusion level…")
        count = (
            op.get_bind()
            .execute(
                """
            WITH cleared_rows AS (
                UPDATE
                    gn_synthese.synthese s
                SET
                    id_nomenclature_diffusion_level = NULL
                FROM
                    ref_nomenclatures.t_nomenclatures nomenc_sensitivity,
                    ref_nomenclatures.t_nomenclatures nomenc_diff_level
                WHERE
                    nomenc_sensitivity.id_nomenclature = s.id_nomenclature_sensitivity
                    AND nomenc_diff_level.id_nomenclature = s.id_nomenclature_diffusion_level
                AND nomenc_diff_level.cd_nomenclature = gn_sensitivity.calculate_cd_diffusion_level(NULL, nomenc_sensitivity.cd_nomenclature)
                RETURNING s.id_synthese
            )
            SELECT
                count(*)
            FROM
                cleared_rows;
        """
            )
            .scalar()
        )
        logger.info("Cleared diffusion level on {} rows.".format(count))


def downgrade():
    restore_diffusion_level = context.get_x_argument(as_dictionary=True).get(
        "restore-diffusion-level"
    )
    if restore_diffusion_level is not None:
        restore_diffusion_level = bool(strtobool(restore_diffusion_level))
    else:
        restore_diffusion_level = True

    if restore_diffusion_level:
        logger.info("Restore diffusion level…")
        count = (
            op.get_bind()
            .execute(
                """
            WITH restored_rows AS (
                UPDATE 
                    gn_synthese.synthese s
                SET
                    id_nomenclature_diffusion_level = ref_nomenclatures.get_id_nomenclature(
                        'NIV_PRECIS',
                        gn_sensitivity.calculate_cd_diffusion_level(
                            NULL,
                            nomenc_sensitivity.cd_nomenclature
                        )
                    )
                FROM
                    ref_nomenclatures.t_nomenclatures nomenc_sensitivity
                WHERE
                    nomenc_sensitivity.id_nomenclature = s.id_nomenclature_sensitivity
                    AND s.id_nomenclature_diffusion_level IS NULL
                RETURNING s.id_synthese
            )
            SELECT
                count(*)
            FROM
                restored_rows
        """
            )
            .scalar()
        )
        logger.info("Restored diffusion level on {} rows.".format(count))

    op.execute(
        """
        DROP TRIGGER tri_insert_calculate_sensitivity ON gn_synthese.synthese
    """
    )
    op.execute(
        """
        DROP TRIGGER tri_update_calculate_sensitivity ON gn_synthese.synthese
    """
    )
    op.execute(
        """
        DROP FUNCTION gn_synthese.fct_tri_calculate_sensitivity_on_each_statement
    """
    )
    op.execute(
        """
        DROP FUNCTION gn_synthese.fct_tri_update_sensitivity_on_each_row
    """
    )
    op.execute(
        """
        CREATE FUNCTION gn_synthese.fct_tri_cal_sensi_diff_level_on_each_statement()
         RETURNS trigger
         LANGUAGE plpgsql
        AS $function$
          -- Calculate sensitivity and diffusion level on insert in synthese
            BEGIN
            WITH cte AS (
                SELECT
                gn_sensitivity.get_id_nomenclature_sensitivity(
                  updated_rows.date_min::date,
                  taxonomie.find_cdref(updated_rows.cd_nom),
                  updated_rows.the_geom_local,
                  ('{"STATUT_BIO": ' || updated_rows.id_nomenclature_bio_status::text || '}')::jsonb
                ) AS id_nomenclature_sensitivity,
                id_synthese,
                t_diff.cd_nomenclature as cd_nomenclature_diffusion_level
              FROM NEW AS updated_rows
              LEFT JOIN ref_nomenclatures.t_nomenclatures t_diff ON t_diff.id_nomenclature = updated_rows.id_nomenclature_diffusion_level
              WHERE updated_rows.id_nomenclature_sensitivity IS NULL
            )
            UPDATE gn_synthese.synthese AS s
            SET
              id_nomenclature_sensitivity = c.id_nomenclature_sensitivity,
              id_nomenclature_diffusion_level = ref_nomenclatures.get_id_nomenclature(
                'NIV_PRECIS',
                gn_sensitivity.calculate_cd_diffusion_level(
                  c.cd_nomenclature_diffusion_level,
                  t_sensi.cd_nomenclature
                )

              )
            FROM cte AS c
            LEFT JOIN ref_nomenclatures.t_nomenclatures t_sensi ON t_sensi.id_nomenclature = c.id_nomenclature_sensitivity
            WHERE c.id_synthese = s.id_synthese
          ;
            RETURN NULL;
            END;
          $function$
        ;
    """
    )
    op.execute(
        """
        CREATE TRIGGER tri_insert_calculate_sensitivity AFTER
        INSERT
            ON
            gn_synthese.synthese REFERENCING NEW TABLE AS NEW FOR EACH STATEMENT EXECUTE PROCEDURE gn_synthese.fct_tri_cal_sensi_diff_level_on_each_statement()
    """
    )
    op.execute(
        """
        CREATE FUNCTION gn_synthese.fct_tri_cal_sensi_diff_level_on_each_row()
         RETURNS trigger
         LANGUAGE plpgsql
        AS $function$ 
          -- Calculate sensitivity and diffusion level on update in synthese
          DECLARE calculated_id_sensi integer;
            BEGIN
                SELECT 
                gn_sensitivity.get_id_nomenclature_sensitivity(
                  NEW.date_min::date, 
                  taxonomie.find_cdref(NEW.cd_nom), 
                  NEW.the_geom_local,
                  ('{"STATUT_BIO": ' || NEW.id_nomenclature_bio_status::text || '}')::jsonb
                ) INTO calculated_id_sensi;
              UPDATE gn_synthese.synthese 
              SET 
              id_nomenclature_sensitivity = calculated_id_sensi,
              -- On ne met pas à jour le niveau de diffusion s'il a déjà une valeur
              id_nomenclature_diffusion_level = CASE WHEN OLD.id_nomenclature_diffusion_level IS NULL THEN (
                SELECT ref_nomenclatures.get_id_nomenclature(
                    'NIV_PRECIS',
                    gn_sensitivity.calculate_cd_diffusion_level(
                      ref_nomenclatures.get_cd_nomenclature(OLD.id_nomenclature_diffusion_level),
                      ref_nomenclatures.get_cd_nomenclature(calculated_id_sensi)
                  )
                )
              )
              ELSE OLD.id_nomenclature_diffusion_level
              END
              WHERE id_synthese = OLD.id_synthese
              ;
              RETURN NULL;
            END;
          $function$
        ;
    """
    )
    op.execute(
        """
        CREATE TRIGGER tri_update_calculate_sensitivity AFTER
        UPDATE
            OF date_min,
            date_max,
            cd_nom,
            the_geom_local,
            id_nomenclature_bio_status ON
            gn_synthese.synthese FOR EACH ROW EXECUTE PROCEDURE gn_synthese.fct_tri_cal_sensi_diff_level_on_each_row()
    """
    )
