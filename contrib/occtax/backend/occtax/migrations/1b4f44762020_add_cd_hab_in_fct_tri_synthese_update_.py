"""update cd_hab in fct_tri_synthese_update_releve

Revision ID: 1b4f44762020
Revises: 0ff94776a962
Create Date: 2023-04-04 00:26:12.030884

"""

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "1b4f44762020"
down_revision = "0ff94776a962"
branch_labels = None
depends_on = None


def upgrade():
    op.execute(
        """
        CREATE OR REPLACE FUNCTION pr_occtax.fct_tri_synthese_update_releve()
         RETURNS trigger
         LANGUAGE plpgsql
        AS $function$
                DECLARE
                myobservers text;
                BEGIN

                --mise à jour en synthese des informations correspondant au relevé uniquement
                UPDATE gn_synthese.synthese s SET
                    id_dataset = NEW.id_dataset,
                    observers = COALESCE(NEW.observers_txt, observers),
                    id_digitiser = NEW.id_digitiser,
                    id_module = NEW.id_module,
                    id_source = (SELECT id_source FROM gn_synthese.t_sources WHERE id_module = NEW.id_module),
                    grp_method = NEW.grp_method,
                    id_nomenclature_grp_typ = NEW.id_nomenclature_grp_typ,
                    date_min = date_trunc('day',NEW.date_min)+COALESCE(NEW.hour_min,'00:00:00'::time),
                    date_max = date_trunc('day',NEW.date_max)+COALESCE(NEW.hour_max,'00:00:00'::time),
                    altitude_min = NEW.altitude_min,
                    altitude_max = NEW.altitude_max,
                    depth_min = NEW.depth_min,
                    depth_max = NEW.depth_max,
                    place_name = NEW.place_name,
                    precision = NEW.precision,
                    the_geom_local = NEW.geom_local,
                    the_geom_4326 = NEW.geom_4326,
                    the_geom_point = ST_CENTROID(NEW.geom_4326),
                    id_nomenclature_geo_object_nature = NEW.id_nomenclature_geo_object_nature,
                    last_action = 'U',
                    comment_context = NEW.comment,
                    additional_data = COALESCE(NEW.additional_fields, '{}'::jsonb) || COALESCE(o.additional_fields, '{}'::jsonb) || COALESCE(c.additional_fields, '{}'::jsonb),
                    cd_hab = NEW.cd_hab
                    FROM pr_occtax.cor_counting_occtax c
                    INNER JOIN pr_occtax.t_occurrences_occtax o ON c.id_occurrence_occtax = o.id_occurrence_occtax
                    WHERE c.unique_id_sinp_occtax = s.unique_id_sinp
                        AND s.unique_id_sinp IN (SELECT unnest(pr_occtax.get_unique_id_sinp_from_id_releve(NEW.id_releve_occtax::integer)));

                RETURN NULL;
                END;
                $function$
        ;
        """
    )
    op.execute(
        """
        UPDATE
            gn_synthese.synthese s
        SET
            cd_hab = releve.cd_hab
        FROM (
            SELECT s.id_synthese, r.cd_hab
            FROM gn_synthese.synthese s
            JOIN pr_occtax.t_releves_occtax r USING (unique_id_sinp_grp)
            WHERE s.cd_hab IS DISTINCT FROM r.cd_hab
        ) releve
        WHERE
            s.id_synthese = releve.id_synthese;
        """
    )


def downgrade():
    op.execute(
        """
        CREATE OR REPLACE FUNCTION pr_occtax.fct_tri_synthese_update_releve()
         RETURNS trigger
         LANGUAGE plpgsql
        AS $function$
                DECLARE
                myobservers text;
                BEGIN

                --mise à jour en synthese des informations correspondant au relevé uniquement
                UPDATE gn_synthese.synthese s SET
                    id_dataset = NEW.id_dataset,
                    observers = COALESCE(NEW.observers_txt, observers),
                    id_digitiser = NEW.id_digitiser,
                    id_module = NEW.id_module,
                    id_source = (SELECT id_source FROM gn_synthese.t_sources WHERE id_module = NEW.id_module),
                    grp_method = NEW.grp_method,
                    id_nomenclature_grp_typ = NEW.id_nomenclature_grp_typ,
                    date_min = date_trunc('day',NEW.date_min)+COALESCE(NEW.hour_min,'00:00:00'::time),
                    date_max = date_trunc('day',NEW.date_max)+COALESCE(NEW.hour_max,'00:00:00'::time),
                    altitude_min = NEW.altitude_min,
                    altitude_max = NEW.altitude_max,
                    depth_min = NEW.depth_min,
                    depth_max = NEW.depth_max,
                    place_name = NEW.place_name,
                    precision = NEW.precision,
                    the_geom_local = NEW.geom_local,
                    the_geom_4326 = NEW.geom_4326,
                    the_geom_point = ST_CENTROID(NEW.geom_4326),
                    id_nomenclature_geo_object_nature = NEW.id_nomenclature_geo_object_nature,
                    last_action = 'U',
                    comment_context = NEW.comment,
                    additional_data = COALESCE(NEW.additional_fields, '{}'::jsonb) || COALESCE(o.additional_fields, '{}'::jsonb) || COALESCE(c.additional_fields, '{}'::jsonb)
                    FROM pr_occtax.cor_counting_occtax c
                    INNER JOIN pr_occtax.t_occurrences_occtax o ON c.id_occurrence_occtax = o.id_occurrence_occtax
                    WHERE c.unique_id_sinp_occtax = s.unique_id_sinp
                        AND s.unique_id_sinp IN (SELECT unnest(pr_occtax.get_unique_id_sinp_from_id_releve(NEW.id_releve_occtax::integer)));

                RETURN NULL;
                END;
                $function$
        ;
        """
    )
