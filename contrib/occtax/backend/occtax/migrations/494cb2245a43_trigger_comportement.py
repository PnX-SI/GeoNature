"""trigger comportement

Revision ID: 494cb2245a43
Revises: f57107d2d0ad
Create Date: 2021-10-07 16:01:31.763465

"""

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "494cb2245a43"
down_revision = "f57107d2d0ad"
branch_labels = None
depends_on = None


def upgrade():
    op.execute(
        """
        CREATE OR REPLACE FUNCTION pr_occtax.fct_tri_synthese_update_occ()
            RETURNS trigger
            LANGUAGE plpgsql
            AS $function$  declare
                counting RECORD;
                releve_add_fields jsonb;
            begin
                select * into counting from pr_occtax.cor_counting_occtax c where id_occurrence_occtax = new.id_occurrence_occtax;
                select r.additional_fields into releve_add_fields from pr_occtax.t_releves_occtax r where id_releve_occtax = new.id_releve_occtax;
                UPDATE gn_synthese.synthese SET
                id_nomenclature_obs_technique = NEW.id_nomenclature_obs_technique,
                id_nomenclature_bio_condition = NEW.id_nomenclature_bio_condition,
                id_nomenclature_bio_status = NEW.id_nomenclature_bio_status,
                id_nomenclature_naturalness = NEW.id_nomenclature_naturalness,
                id_nomenclature_exist_proof = NEW.id_nomenclature_exist_proof,
                id_nomenclature_diffusion_level = NEW.id_nomenclature_diffusion_level,
                id_nomenclature_observation_status = NEW.id_nomenclature_observation_status,
                id_nomenclature_blurring = NEW.id_nomenclature_blurring,
                id_nomenclature_source_status = NEW.id_nomenclature_source_status,
                determiner = NEW.determiner,
                id_nomenclature_determination_method = NEW.id_nomenclature_determination_method,
                id_nomenclature_behaviour = NEW.id_nomenclature_behaviour,
                cd_nom = NEW.cd_nom,
                nom_cite = NEW.nom_cite,
                meta_v_taxref = NEW.meta_v_taxref,
                sample_number_proof = NEW.sample_number_proof,
                digital_proof = NEW.digital_proof,
                non_digital_proof = NEW.non_digital_proof,
                comment_description = NEW.comment,
                last_action = 'U',
                --CHAMPS ADDITIONNELS OCCTAX
                additional_data =  releve_add_fields || NEW.additional_fields || counting.additional_fields
                WHERE unique_id_sinp = counting.unique_id_sinp_occtax;
                
                RETURN NULL;
        END;
        $function$
        ;
        """
    )


def downgrade():
    op.execute(
        """
        CREATE OR REPLACE FUNCTION pr_occtax.fct_tri_synthese_update_occ()
            RETURNS trigger
            LANGUAGE plpgsql
            AS $function$  declare
                counting RECORD;
                releve_add_fields jsonb;
            begin
                select * into counting from pr_occtax.cor_counting_occtax c where id_occurrence_occtax = new.id_occurrence_occtax;
                select r.additional_fields into releve_add_fields from pr_occtax.t_releves_occtax r where id_releve_occtax = new.id_releve_occtax;
                UPDATE gn_synthese.synthese SET
                id_nomenclature_obs_technique = NEW.id_nomenclature_obs_technique,
                id_nomenclature_bio_condition = NEW.id_nomenclature_bio_condition,
                id_nomenclature_bio_status = NEW.id_nomenclature_bio_status,
                id_nomenclature_naturalness = NEW.id_nomenclature_naturalness,
                id_nomenclature_exist_proof = NEW.id_nomenclature_exist_proof,
                id_nomenclature_diffusion_level = NEW.id_nomenclature_diffusion_level,
                id_nomenclature_observation_status = NEW.id_nomenclature_observation_status,
                id_nomenclature_blurring = NEW.id_nomenclature_blurring,
                id_nomenclature_source_status = NEW.id_nomenclature_source_status,
                determiner = NEW.determiner,
                id_nomenclature_determination_method = NEW.id_nomenclature_determination_method,
                id_nomenclature_behaviour = id_nomenclature_behaviour,
                cd_nom = NEW.cd_nom,
                nom_cite = NEW.nom_cite,
                meta_v_taxref = NEW.meta_v_taxref,
                sample_number_proof = NEW.sample_number_proof,
                digital_proof = NEW.digital_proof,
                non_digital_proof = NEW.non_digital_proof,
                comment_description = NEW.comment,
                last_action = 'U',
                --CHAMPS ADDITIONNELS OCCTAX
                additional_data =  releve_add_fields || NEW.additional_fields || counting.additional_fields
                WHERE unique_id_sinp = counting.unique_id_sinp_occtax;
                
                RETURN NULL;
        END;
        $function$
        ;
        """
    )
