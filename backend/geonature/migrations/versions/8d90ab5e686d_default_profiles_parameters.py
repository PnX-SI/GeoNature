"""Add profiles default parameters

Revision ID: 8d90ab5e686d
Revises: f4ffdc68072c
Create Date: 2022-08-10 14:07:35.234716

"""

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "8d90ab5e686d"
down_revision = "f4ffdc68072c"
branch_labels = None
depends_on = None


def upgrade():
    op.execute(
        """
    DELETE FROM
        gn_profiles.cor_taxons_parameters
    WHERE
        cd_nom IN (SELECT DISTINCT cd_nom FROM taxonomie.taxref WHERE id_rang='KD')
        AND
        spatial_precision = 2000
        AND
        temporal_precision_days = 10
        AND
        active_life_stage = FALSE
    """
    )
    op.execute(
        """
    INSERT INTO gn_profiles.t_parameters ("name", "desc", "value") VALUES
        ('default_spatial_precision', 'Précision spatiale par défaut en l’absence de paramètre pour le taxon considéré.', '2000'),
        ('default_temporal_precision_days', 'Précision temporelle par défaut en l’absence de paramètre pour le taxon considéré.', '10'),
        ('default_active_life_stage', 'Valeur par défaut pour la prise en compte du stade de vie en l’absence de paramètre pour le taxon considéré.', 'false')
    """
    )
    op.execute(
        """
    CREATE OR REPLACE FUNCTION gn_profiles.get_parameters(my_cd_nom integer)
     RETURNS TABLE(cd_ref integer, spatial_precision integer, temporal_precision_days integer, active_life_stage boolean, distance smallint)
     LANGUAGE plpgsql
     IMMUTABLE
    AS $function$
    -- fonction permettant de récupérer les paramètres les plus adaptés
    -- (définis au plus proche du taxon) pour calculer le profil d'un taxon donné
    -- par exemple, s'il existe des paramètres pour les "Animalia" des paramètres pour le renard,
    -- les paramètres du renard surcoucheront les paramètres Animalia pour cette espèce
      DECLARE
      BEGIN
       RETURN QUERY
       SELECT
            t.cd_ref,
            parameters.*
        FROM (
            SELECT
                param.spatial_precision,
                param.temporal_precision_days,
                param.active_life_stage,
                parents.distance
            FROM
                gn_profiles.cor_taxons_parameters param
            JOIN
                taxonomie.find_all_taxons_parents(my_cd_nom) parents ON parents.cd_nom=param.cd_nom
        UNION
            SELECT
                (SELECT value::int4 FROM gn_profiles.t_parameters WHERE name = 'default_spatial_precision') AS spatial_precision,
                (SELECT value::int4 FROM gn_profiles.t_parameters WHERE name = 'default_temporal_precision_days') AS temporal_precision_days,
                (SELECT value::boolean FROM gn_profiles.t_parameters WHERE name = 'default_active_life_stage') AS active_life_stage,
                NULL AS distance
        ) AS parameters
        JOIN
            taxonomie.taxref t ON t.cd_nom = my_cd_nom
        ORDER BY
            distance
        LIMIT 1
       ;
      END;
    $function$
    """
    )


def downgrade():
    op.execute(
        """
    CREATE OR REPLACE FUNCTION gn_profiles.get_parameters(my_cd_nom integer)
     RETURNS TABLE(cd_ref integer, spatial_precision integer, temporal_precision_days integer, active_life_stage boolean, distance smallint)
     LANGUAGE plpgsql
     IMMUTABLE
    AS $function$
    -- fonction permettant de récupérer les paramètres les plus adaptés
    -- (définis au plus proche du taxon) pour calculer le profil d'un taxon donné
    -- par exemple, s'il existe des paramètres pour les "Animalia" des paramètres pour le renard,
    -- les paramètres du renard surcoucheront les paramètres Animalia pour cette espèce
      DECLARE
       my_cd_ref integer := t.cd_ref FROM taxonomie.taxref t WHERE t.cd_nom=my_cd_nom;
      BEGIN
       RETURN QUERY
        WITH all_parameters AS (
         SELECT my_cd_ref, param.spatial_precision, param.temporal_precision_days,
         param.active_life_stage, parents.distance
         FROM gn_profiles.cor_taxons_parameters param
       JOIN taxonomie.find_all_taxons_parents(my_cd_ref) parents ON parents.cd_nom=param.cd_nom)
      SELECT * FROM all_parameters all_param WHERE all_param.distance=(
       SELECT min(all_param2.distance) FROM all_parameters all_param2
      )
       ;
      END;
    $function$
    """
    )
    op.execute(
        """
    DELETE FROM
        gn_profiles.t_parameters
    WHERE
        name IN (
            'default_spatial_precision',
            'default_temporal_precision_days',
            'default_active_life_stage'
        )
    """
    )
    op.execute(
        """
    INSERT INTO gn_profiles.cor_taxons_parameters(
        cd_nom, spatial_precision, temporal_precision_days, active_life_stage
    )
    SELECT
        DISTINCT t.cd_nom,
        2000,
        10,
        false
    FROM taxonomie.taxref t
    WHERE id_rang='KD'
    """
    )
