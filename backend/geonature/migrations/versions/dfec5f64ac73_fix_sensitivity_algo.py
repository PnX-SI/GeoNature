"""Fix sensitivity algorithm

Revision ID: dfec5f64ac73
Revises: dde31e76ce45
Create Date: 2022-01-28 14:06:38.748133

"""

from distutils.util import strtobool

from alembic import op, context
import sqlalchemy as sa

from utils_flask_sqla.migrations.utils import logger


# revision identifiers, used by Alembic.
revision = "dfec5f64ac73"
down_revision = "61e46813d621"
branch_labels = None
depends_on = None


def upgrade():
    recompute_sensitivity = context.get_x_argument(as_dictionary=True).get("recompute-sensitivity")
    if recompute_sensitivity is not None:
        recompute_sensitivity = bool(strtobool(recompute_sensitivity))
    else:
        recompute_sensitivity = True

    op.execute(
        """
    CREATE OR REPLACE FUNCTION gn_sensitivity.get_id_nomenclature_sensitivity(my_date_obs date, my_cd_ref integer, my_geom geometry, my_criterias jsonb)
     RETURNS integer
     LANGUAGE plpgsql
     IMMUTABLE
    AS $function$
        DECLARE
            sensitivity integer;
        BEGIN
            -- Paramètres durée, zone géographique, période de l'observation et critères biologique
            SELECT INTO sensitivity r.id_nomenclature_sensitivity
            FROM gn_sensitivity.t_sensitivity_rules_cd_ref r
            JOIN ref_nomenclatures.t_nomenclatures n ON n.id_nomenclature = r.id_nomenclature_sensitivity
            LEFT OUTER JOIN gn_sensitivity.cor_sensitivity_area USING(id_sensitivity)
            LEFT OUTER JOIN ref_geo.l_areas a USING(id_area)
            LEFT OUTER JOIN gn_sensitivity.cor_sensitivity_criteria c USING(id_sensitivity)
            WHERE
                ( -- taxon
                    my_cd_ref = r.cd_ref
                ) AND ( -- zone géographique de validité
                    a.geom IS NULL -- pas de restriction géographique à la validité de la règle
                    OR
                    st_intersects(my_geom, a.geom)
                ) AND ( -- période de validité
                    to_char(my_date_obs, 'MMDD') between to_char(r.date_min, 'MMDD') and to_char(r.date_max, 'MMDD')
                ) AND ( -- durée de validité
                    (date_part('year', CURRENT_TIMESTAMP) - r.sensitivity_duration) <= date_part('year', my_date_obs)
                ) AND ( -- critère
                    c.id_criteria IS NULL -- règle sans restriction de critère
                    OR
                    -- Note: no need to check criteria type, as we use id_nomenclature which can not conflict
                    c.id_criteria IN (SELECT value::int FROM jsonb_each_text(my_criterias))
                )
            ORDER BY n.cd_nomenclature DESC;

            IF sensitivity IS NULL THEN
                sensitivity := (SELECT ref_nomenclatures.get_id_nomenclature('SENSIBILITE'::text, '0'::text));
            END IF;

            return sensitivity;
        END;
        $function$
    """
    )

    if recompute_sensitivity:
        logger.info("Recompute sensitivity…")
        count = op.get_bind().execute("SELECT gn_synthese.update_sensitivity()").scalar()
        logger.info(f"Sensitivity updated for {count} rows")


def downgrade():
    op.execute(
        """
    CREATE OR REPLACE FUNCTION gn_sensitivity.get_id_nomenclature_sensitivity(my_date_obs date, my_cd_ref integer, my_geom geometry, my_criterias jsonb)
     RETURNS integer
     LANGUAGE plpgsql
     IMMUTABLE
    AS $function$
    DECLARE
        niv_precis integer;
        niv_precis_null integer;
    BEGIN

        niv_precis_null := (SELECT ref_nomenclatures.get_id_nomenclature('SENSIBILITE'::text, '0'::text));

        -- ##########################################
        -- TESTS unicritère
        --    => Permet de voir si un critère est remplis ou non de façon à limiter au maximum
        --      la requete globale qui croise l'ensemble des critères
        -- ##########################################

        -- Paramètres cd_ref
         IF NOT EXISTS (
            SELECT 1
            FROM gn_sensitivity.t_sensitivity_rules_cd_ref s
            WHERE s.cd_ref = my_cd_ref
        ) THEN
            return niv_precis_null;
        END IF;

        -- Paramètres durée de validité de la règle
        IF NOT EXISTS (
            SELECT 1
            FROM gn_sensitivity.t_sensitivity_rules_cd_ref s
            WHERE s.cd_ref = my_cd_ref
            AND (date_part('year', CURRENT_TIMESTAMP) - sensitivity_duration) <= date_part('year', my_date_obs)
        ) THEN
            return niv_precis_null;
        END IF;

        -- Paramètres période d'observation
        IF NOT EXISTS (
            SELECT 1
            FROM gn_sensitivity.t_sensitivity_rules_cd_ref s
            WHERE s.cd_ref = my_cd_ref
            AND (to_char(my_date_obs, 'MMDD') between to_char(s.date_min, 'MMDD') and to_char(s.date_max, 'MMDD') )
        ) THEN
            return niv_precis_null;
        END IF;

        -- Paramètres critères biologiques
        -- S'il existe un critère pour ce taxon
        IF EXISTS (
            SELECT 1
            FROM gn_sensitivity.t_sensitivity_rules_cd_ref s
            JOIN gn_sensitivity.cor_sensitivity_criteria c USING(id_sensitivity)
            WHERE s.cd_ref = my_cd_ref
        ) THEN
            -- Si le critère est remplis
            niv_precis := (

                WITH RECURSIVE h_val(KEY, value, id_broader) AS  (
                    SELECT KEY, value::int, id_broader
                    FROM (SELECT * FROM jsonb_each_text(my_criterias)) d
                    JOIN ref_nomenclatures.t_nomenclatures tn
                    ON tn.id_nomenclature = d.value::int
                    UNION
                    SELECT KEY, id_nomenclature , tn.id_broader
                    FROM ref_nomenclatures.t_nomenclatures tn
                    JOIN h_val
                    ON tn.id_nomenclature = h_val.id_broader
                    WHERE NOT id_nomenclature = 0
                )
                SELECT DISTINCT id_nomenclature_sensitivity
                FROM gn_sensitivity.t_sensitivity_rules_cd_ref s
                JOIN gn_sensitivity.cor_sensitivity_criteria c USING(id_sensitivity)
                JOIN h_val a
                ON c.id_criteria = a.value
                WHERE s.cd_ref = my_cd_ref
                LIMIT 1
            );
            IF niv_precis IS NULL THEN
                niv_precis := (SELECT ref_nomenclatures.get_id_nomenclature('SENSIBILITE'::text, '0'::text));
                return niv_precis;
            END IF;
        END IF;



        -- ##########################################
        -- TESTS multicritères
        --    => Permet de voir si l'ensemble des critères sont remplis
        -- ##########################################

        -- Paramètres durée, zone géographique, période de l'observation et critères biologique
        SELECT INTO niv_precis s.id_nomenclature_sensitivity
        FROM (
            SELECT s.*, l.geom, c.id_criteria, c.id_type_nomenclature
            FROM gn_sensitivity.t_sensitivity_rules_cd_ref s
            LEFT OUTER JOIN gn_sensitivity.cor_sensitivity_area  USING(id_sensitivity)
            LEFT OUTER JOIN gn_sensitivity.cor_sensitivity_criteria c USING(id_sensitivity)
            LEFT OUTER JOIN ref_geo.l_areas l USING(id_area)
        ) s
        WHERE my_cd_ref = s.cd_ref
            AND (st_intersects(my_geom, s.geom) OR s.geom IS NULL) -- paramètre géographique
            AND (-- paramètre période
                (to_char(my_date_obs, 'MMDD') between to_char(s.date_min, 'MMDD') and to_char(s.date_max, 'MMDD') )
            )
            AND ( -- paramètre duré de validité de la règle
                (date_part('year', CURRENT_TIMESTAMP) - sensitivity_duration) <= date_part('year', my_date_obs)
            )
            AND ( -- paramètre critères
                s.id_criteria IN (SELECT  value::int FROM jsonb_each_text(my_criterias)) OR s.id_criteria IS NULL
            );

        IF niv_precis IS NULL THEN
            niv_precis := niv_precis_null;
        END IF;


        return niv_precis;

    END;
    $function$
    """
    )
