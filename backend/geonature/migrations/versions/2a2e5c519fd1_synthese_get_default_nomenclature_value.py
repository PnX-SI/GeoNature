"""fix gn_synthese.get_default_nomenclature_value

Revision ID: 2a2e5c519fd1
Revises: 7077aa76da3d
Create Date: 2021-10-06 15:55:37.365073

"""

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "2a2e5c519fd1"
down_revision = "7077aa76da3d"
branch_labels = None
depends_on = None


def upgrade():
    op.execute(
        """
    CREATE OR REPLACE FUNCTION gn_synthese.get_default_nomenclature_value(myidtype character varying, myidorganism integer DEFAULT NULL, myregne character varying DEFAULT '0'::character varying, mygroup2inpn character varying DEFAULT '0'::character varying)
     RETURNS integer
     LANGUAGE plpgsql
     IMMUTABLE
    AS $function$
    --Function that return the default nomenclature id with wanteds nomenclature type, organism id, regne, group2_inpn
    --Return -1 if nothing matche with given parameters
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
            FROM gn_synthese.defaults_nomenclatures_value n
            JOIN utilisateurs.bib_organismes o
            ON o.id_organisme = n.id_organism
            WHERE mnemonique_type = myidtype
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
    CREATE OR REPLACE FUNCTION gn_synthese.get_default_nomenclature_value(myidtype character varying, myidorganism integer DEFAULT 0, myregne character varying DEFAULT '0'::character varying, mygroup2inpn character varying DEFAULT '0'::character varying)
     RETURNS integer
     LANGUAGE plpgsql
     IMMUTABLE
    AS $function$
    --Function that return the default nomenclature id with wanteds nomenclature type, organism id, regne, group2_inpn
    --Return -1 if nothing matche with given parameters
      DECLARE
        theidnomenclature integer;
      BEGIN
          SELECT INTO theidnomenclature id_nomenclature
          FROM gn_synthese.defaults_nomenclatures_value
          WHERE mnemonique_type = myidtype
          AND (id_organism = 0 OR id_organism = myidorganism)
          AND (regne = '0' OR regne = myregne)
          AND (group2_inpn = '0' OR group2_inpn = mygroup2inpn)
          ORDER BY group2_inpn DESC, regne DESC, id_organism DESC LIMIT 1;
        IF (theidnomenclature IS NOT NULL) THEN
          RETURN theidnomenclature;
        END IF;
        RETURN NULL;
      END;
    $function$
    ;
    """
    )
