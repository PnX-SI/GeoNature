"""fix defaults nomenc for organism ALL

Revision ID: f305718b81d3
Revises: 9c46f11f8caf
Create Date: 2024-01-08 19:11:25.673073

"""

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "f305718b81d3"
down_revision = "85efc9bb5a47"
branch_labels = None
depends_on = None


def upgrade():
    op.execute(
        """
        CREATE OR REPLACE FUNCTION pr_occhab.get_default_nomenclature_value(mytype character varying, myidorganism integer DEFAULT 0)
         RETURNS integer
         LANGUAGE plpgsql
         IMMUTABLE
        AS $function$
        --Function that return the default nomenclature id with wanteds nomenclature type, organism id
        --Return -1 if nothing matche with given parameters
          DECLARE
            thenomenclatureid integer;
          BEGIN
              SELECT INTO thenomenclatureid id_nomenclature
              FROM (
              	SELECT
              	  n.id_nomenclature,
              	  CASE
        	        WHEN n.id_organism = myidorganism THEN 1
                    ELSE 0
                  END prio_organisme
                FROM
                  pr_occhab.defaults_nomenclatures_value n
                JOIN
                  utilisateurs.bib_organismes o ON o.id_organisme = n.id_organism
                WHERE
                  mnemonique_type = mytype
                  AND (n.id_organism = myidorganism OR o.nom_organisme = 'ALL')
              ) AS defaults_nomenclatures_value
              ORDER BY prio_organisme DESC LIMIT 1;
             
            RETURN thenomenclatureid;
          END;
        $function$
        ;
        """
    )


def downgrade():
    # This implementation wrongly assume that organism 'ALL' has id_organism = 0
    op.execute(
        """
        CREATE OR REPLACE FUNCTION pr_occhab.get_default_nomenclature_value(mytype character varying, myidorganism integer DEFAULT 0) RETURNS integer
        IMMUTABLE
        LANGUAGE plpgsql
        AS $$
        --Function that return the default nomenclature id with wanteds nomenclature type, organism id
        --Return -1 if nothing matche with given parameters
          DECLARE
            thenomenclatureid integer;
          BEGIN
              SELECT INTO thenomenclatureid id_nomenclature
              FROM pr_occhab.defaults_nomenclatures_value
              WHERE mnemonique_type = mytype
              AND (id_organism = 0 OR id_organism = myidorganism)
              ORDER BY id_organism DESC LIMIT 1;
            IF (thenomenclatureid IS NOT NULL) THEN
              RETURN thenomenclatureid;
            END IF;
            RETURN NULL;
          END;
        $$;
        """
    )
