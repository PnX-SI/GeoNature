"""Refactoring of database structure

Revision ID: 3a65de65b697
Revises: 4b137deaf201
Create Date: 2021-03-29 23:02:14.880716

"""

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "3a65de65b697"
down_revision = "4b137deaf201"
branch_labels = None
depends_on = None


schema = "gn_imports"


def upgrade():
    # Remove duplicates
    op.execute(
        """
        DELETE FROM gn_imports.t_mappings_fields WHERE id_match_fields IN (
            SELECT id_match_fields FROM gn_imports.t_mappings_fields tmf1
            LEFT OUTER JOIN (
                SELECT COUNT(*) AS c, MAX(id_match_fields) AS m, id_mapping, target_field
                FROM gn_imports.t_mappings_fields
                GROUP BY (id_mapping, target_field)
            ) AS tmf2 ON tmf1.id_match_fields = tmf2.m
            WHERE tmf2.m IS NULL
        )
    """
    )
    op.execute(
        """
        WITH unq AS (
            SELECT DISTINCT ON (tmv.id_mapping, df.name_field, tmv.source_value) tmv.id_match_values
            FROM gn_imports.t_mappings_values tmv
            INNER JOIN ref_nomenclatures.t_nomenclatures tn ON tn.id_nomenclature = tmv.id_target_value
            INNER JOIN ref_nomenclatures.bib_nomenclatures_types bnt ON bnt.id_type = tn.id_type
            INNER JOIN gn_imports.cor_synthese_nomenclature csn ON csn.mnemonique = bnt.mnemonique
            INNER JOIN gn_imports.dict_fields df ON df.name_field = csn.synthese_col
        )
        DELETE FROM gn_imports.t_mappings_values tmv
        WHERE tmv.id_match_values NOT IN (SELECT unq.id_match_values FROM unq);
    """
    )
    # Add unique constraint
    op.execute(
        """
        ALTER TABLE gn_imports.t_mappings_fields
        ADD CONSTRAINT un_t_mappings_fields
        UNIQUE (id_mapping, target_field)
    """
    )
    # Add mnemonique directly on dict_fields and drop table cor_synthese_nomenclature
    op.execute("ALTER TABLE gn_imports.dict_fields ADD mnemonique VARCHAR NULL")
    op.execute(
        """
        ALTER TABLE gn_imports.dict_fields
        ADD CONSTRAINT fk_gn_imports_dict_fields_nomenclature
        FOREIGN KEY (mnemonique)
        REFERENCES ref_nomenclatures.bib_nomenclatures_types(mnemonique)
        ON UPDATE SET NULL ON DELETE SET NULL
    """
    )
    op.execute(
        """
        UPDATE gn_imports.dict_fields df
        SET mnemonique = csn.mnemonique
        FROM gn_imports.cor_synthese_nomenclature csn
        WHERE csn.synthese_col = df.name_field
    """
    )
    op.execute("DROP TABLE gn_imports.cor_synthese_nomenclature")
    # Set source_value NULL as it is used to map empty cell from source csv file
    op.execute("ALTER TABLE gn_imports.t_mappings_values ALTER COLUMN source_value DROP NOT NULL")
    # Add target_field column in gn_imports.t_mappings_values, allowing null values for now
    op.execute("ALTER TABLE gn_imports.t_mappings_values ADD target_field VARCHAR NULL")
    # Set target_field as foreign key referencing dict_fields
    op.execute(
        """
        ALTER TABLE gn_imports.t_mappings_values
        ADD CONSTRAINT fk_gn_imports_t_mappings_values_target_field
        FOREIGN KEY (target_field)
        REFERENCES gn_imports.dict_fields(name_field)
        ON UPDATE CASCADE ON DELETE CASCADE
    """
    )
    # Populating target_field from id_target_value through t_nomenclatures and bib_nomenclatures_type
    op.execute(
        """
        UPDATE
            gn_imports.t_mappings_values tmv
        SET
            target_field = df.name_field
        FROM
            gn_imports.dict_fields df
            INNER JOIN ref_nomenclatures.bib_nomenclatures_types bnt ON bnt.mnemonique = df.mnemonique
            INNER JOIN ref_nomenclatures.t_nomenclatures tn ON tn.id_type = bnt.id_type
        WHERE
            tmv.id_target_value = tn.id_nomenclature
    """
    )
    # Set target_field as not null as it is now populated
    op.execute("ALTER TABLE gn_imports.t_mappings_values ALTER COLUMN target_field SET NOT NULL")
    # Create a function to check the consistency between target_field and id_target_value (same way we calculate it previously)
    op.execute(
        """
        CREATE OR REPLACE FUNCTION gn_imports.check_nomenclature_type_consistency(_target_field varchar, _id_target_value integer)
            RETURNS BOOLEAN
        AS $$
        BEGIN
            RETURN EXISTS (
                SELECT 1
                FROM gn_imports.dict_fields df
                INNER JOIN ref_nomenclatures.bib_nomenclatures_types bnt ON bnt.mnemonique = df.mnemonique
                INNER JOIN ref_nomenclatures.t_nomenclatures tn ON tn.id_type = bnt.id_type
                WHERE df.name_field = _target_field AND tn.id_nomenclature = _id_target_value
            );
        END
        $$ LANGUAGE plpgsql;
    """
    )
    # Add a constraint calling the created function
    op.execute(
        """
        ALTER TABLE gn_imports.t_mappings_values
        ADD CONSTRAINT check_nomenclature_type_consistency
        CHECK (gn_imports.check_nomenclature_type_consistency(target_field, id_target_value));
    """
    )
    # Set a constraint making (id_mapping, target_field, source_value) unique
    op.execute(
        """
        ALTER TABLE gn_imports.t_mappings_values
        ADD CONSTRAINT un_t_mappings_values
        UNIQUE (id_mapping, target_field, source_value)
    """
    )
    # Set nullable mapping_label and remove temporary column
    op.execute("ALTER TABLE gn_imports.t_mappings ALTER COLUMN mapping_label DROP NOT NULL")
    op.execute("UPDATE gn_imports.t_mappings SET mapping_label = NULL WHERE temporary = TRUE")
    op.execute("ALTER TABLE gn_imports.t_mappings DROP COLUMN temporary")
    op.execute("ALTER TABLE gn_imports.t_mappings ALTER COLUMN active SET DEFAULT TRUE")
    # Add constraint to ensure mapping label unicity
    op.execute(
        "ALTER TABLE gn_imports.t_mappings ADD CONSTRAINT t_mappings_un UNIQUE (mapping_label)"
    )
    # Remove errors view as we use the ORM instead
    op.execute("DROP VIEW gn_imports.v_imports_errors")


def downgrade():
    pass
