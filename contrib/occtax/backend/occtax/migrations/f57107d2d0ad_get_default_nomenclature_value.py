"""fix get_default_nomenclature_value

Revision ID: f57107d2d0ad
Revises: addb71d8efad
Create Date: 2021-10-06 16:36:13.566702

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "f57107d2d0ad"
down_revision = "addb71d8efad"
branch_labels = None
depends_on = None


def upgrade():
    op.execute(
        """
    CREATE OR REPLACE FUNCTION pr_occtax.get_default_nomenclature_value(mytype character varying, myidorganism integer DEFAULT NULL, myregne character varying DEFAULT '0'::character varying, mygroup2inpn character varying DEFAULT '0'::character varying)
     RETURNS integer
     LANGUAGE plpgsql
     IMMUTABLE
    AS $function$
    --Function that return the default nomenclature id with wanteds nomenclature type, organism id, regne, group2_inpn
    --Return NULL if nothing matche with given parameters
      DECLARE
        thenomenclatureid integer;
      BEGIN
          SELECT INTO thenomenclatureid id_nomenclature FROM (
                SELECT
                    id_nomenclature,
                    regne,
                    group2_inpn,
                    CASE
                        WHEN n.id_organism = myidorganism THEN 1
                        ELSE 0
                    END prio_organisme
                FROM pr_occtax.defaults_nomenclatures_value n
                JOIN utilisateurs.bib_organismes o
                ON o.id_organisme = n.id_organism
                WHERE mnemonique_type = mytype
                AND (n.id_organism = myidorganism OR n.id_organism = NULL OR o.nom_organisme = 'ALL')
                AND (regne = myregne OR regne = '0')
                AND (group2_inpn = mygroup2inpn OR group2_inpn = '0')
            ) AS defaults_nomenclatures_value
            ORDER BY group2_inpn DESC, regne DESC, prio_organisme DESC LIMIT 1;
            RETURN thenomenclatureid;
      END;
    $function$
    ;
    """
    )


def downgrade():
    op.execute(
        """
    CREATE OR REPLACE FUNCTION get_default_nomenclature_value(mytype character varying, myidorganism integer DEFAULT 0, myregne character varying(20) DEFAULT '0', mygroup2inpn character varying(255) DEFAULT '0') RETURNS integer
    IMMUTABLE
    LANGUAGE plpgsql
    AS $$
    --Function that return the default nomenclature id with wanteds nomenclature type, organism id, regne, group2_inpn
    --Return -1 if nothing matche with given parameters
      DECLARE
        thenomenclatureid integer;
      BEGIN
          SELECT INTO thenomenclatureid id_nomenclature
          FROM pr_occtax.defaults_nomenclatures_value
          WHERE mnemonique_type = mytype
          AND (id_organism = 0 OR id_organism = myidorganism)
          AND (regne = '0' OR regne = myregne)
          AND (group2_inpn = '0' OR group2_inpn = mygroup2inpn)
          ORDER BY group2_inpn DESC, regne DESC, id_organism DESC LIMIT 1;
        IF (thenomenclatureid IS NOT NULL) THEN
          RETURN thenomenclatureid;
        END IF;
        RETURN NULL;
      END;
    $$;
    """
    )
