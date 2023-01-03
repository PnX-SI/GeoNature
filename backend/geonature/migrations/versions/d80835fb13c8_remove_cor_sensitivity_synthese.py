"""Remove gn_sensitivity.cor_sensitivity_synthese

Revision ID: d80835fb13c8
Revises: 77a3bc6628d2
Create Date: 2022-02-15 12:16:38.003591

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "d80835fb13c8"
down_revision = "77a3bc6628d2"
branch_labels = None
depends_on = None


def upgrade():
    op.drop_table("cor_sensitivity_synthese", schema="gn_sensitivity")


def downgrade():
    op.execute(
        """
    CREATE TABLE gn_sensitivity.cor_sensitivity_synthese  (
        uuid_attached_row uuid NOT NULL,
        id_nomenclature_sensitivity int NOT NULL,
        computation_auto BOOLEAN NOT NULL DEFAULT (TRUE),
        id_digitizer integer,
        sensitivity_comment text,
        meta_create_date timestamp,
        meta_update_date timestamp,
        CONSTRAINT cor_sensitivity_synthese_pk PRIMARY KEY (uuid_attached_row, id_nomenclature_sensitivity),
        CONSTRAINT cor_sensitivity_synthese_id_nomenclature_sensitivity_fkey FOREIGN KEY (id_nomenclature_sensitivity)
          REFERENCES ref_nomenclatures.t_nomenclatures (id_nomenclature) MATCH SIMPLE
          ON UPDATE NO ACTION ON DELETE NO ACTION
    );

    ALTER TABLE gn_sensitivity.cor_sensitivity_synthese
      ADD CONSTRAINT check_synthese_sensitivity CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_sensitivity, 'SENSIBILITE'::character varying)) NOT VALID;

    CREATE TRIGGER tri_insert_id_sensitivity_synthese
      AFTER INSERT ON gn_sensitivity.cor_sensitivity_synthese
      REFERENCING NEW TABLE AS NEW
      FOR EACH STATEMENT
      EXECUTE PROCEDURE gn_sensitivity.fct_tri_maj_id_sensitivity_synthese();

    CREATE TRIGGER tri_maj_id_sensitivity_synthese
      AFTER UPDATE ON gn_sensitivity.cor_sensitivity_synthese
      REFERENCING NEW TABLE AS NEW
      FOR EACH STATEMENT
      EXECUTE PROCEDURE gn_sensitivity.fct_tri_maj_id_sensitivity_synthese();

    CREATE TRIGGER tri_delete_id_sensitivity_synthese
      AFTER DELETE ON gn_sensitivity.cor_sensitivity_synthese
      REFERENCING OLD TABLE AS OLD
      FOR EACH STATEMENT
      EXECUTE PROCEDURE gn_sensitivity.fct_tri_delete_id_sensitivity_synthese();

    CREATE TRIGGER tri_meta_dates_change_cor_sensitivity_synthese
      BEFORE INSERT OR UPDATE
      ON  gn_sensitivity.cor_sensitivity_synthese
      FOR EACH ROW
      EXECUTE PROCEDURE public.fct_trg_meta_dates_change();
    """
    )
