"""data type to data category

Revision ID: 83572524f062
Revises: ae0b6362fb22
Create Date: 2026-07-20 10:27:35.383337

"""

from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision = "83572524f062"
down_revision = "ae0b6362fb22"
branch_labels = None
depends_on = None


def upgrade():
    add_precision_data_category()
    add_new_nomenclature()
    delete_default_values()
    use_new_nomenclature()
    rename_id_nomenclature_data_type("id_nomenclature_data_category", "id_nomenclature_data_type")
    rename_nomenclature("DATA_CATEGORY", "DATA_TYP", "Type de données")
    deactivate_old_nomenclature()
    update_check_constraint("DATA_CATEGORY")


def downgrade():
    update_check_constraint("DATA_TYP")
    rename_nomenclature("DATA_TYP", "DATA_CATEGORY", "Catégorie de données")
    rename_id_nomenclature_data_type("id_nomenclature_data_type", "id_nomenclature_data_category")
    reactivate_old_nomenclature()
    restore_old_nomenclature()
    remove_new_nomenclature()
    remove_precision_data_category()


def update_check_constraint(mnemonique):
    """
    Update check constraint, that verify the mnémonique type of nomenclature
    """
    op.execute("""
        ALTER TABLE gn_meta.t_datasets
        DROP CONSTRAINT IF EXISTS check_t_datasets_data_type
        """)
    op.execute(f"""
        ALTER TABLE gn_meta.t_datasets 
        ADD CONSTRAINT check_t_datasets_data_type 
        CHECK (ref_nomenclatures.check_nomenclature_type_by_mnemonique(id_nomenclature_data_category, '{mnemonique}'::character varying)) 
        NOT VALID
        """)


def select_id_type(mnemonique):
    """
    Select to get the id_type of nomenclature
    """
    return f"(SELECT id_type FROM ref_nomenclatures.bib_nomenclatures_types WHERE mnemonique = '{mnemonique}')"


def add_precision_data_category():
    """
    Add the precision_data_category field to the t_datasets table
    """
    op.add_column(
        "t_datasets",
        sa.Column("precision_data_category", sa.String(length=250), nullable=True),
        schema="gn_meta",
    )


def remove_precision_data_category():
    """
    Delete the precision_data_category field from the t_datasets table
    """
    op.drop_column("t_datasets", "precision_data_category", schema="gn_meta")


def add_new_nomenclature():
    """
    Insert or update the new nomenclatures : taxon, habitat, géologique, autre
    """

    def insert_new_nomenclature(cd_nomenclature, mnemonique, label, definition):
        op.execute(
            sa.text("""
                INSERT INTO ref_nomenclatures.t_nomenclatures (id_type,
                                                   cd_nomenclature,
                                                   mnemonique,
                                                   label_default,
                                                   label_fr,
                                                   definition_default,
                                                   definition_fr,
                                                   source,
                                                   statut,
                                                   active)
                SELECT id_type,
                       :cd_nomenclature,
                       :mnemonique,
                       :label,
                       :label,
                       :definition,
                       :definition,
                       'GeoNature',
                       'Validé',
                       true
                FROM ref_nomenclatures.bib_nomenclatures_types
                WHERE mnemonique = 'DATA_TYP'
                ON CONFLICT (cd_nomenclature, id_type) DO UPDATE SET
                    mnemonique = :mnemonique,
                    label_default = :label,
                    label_fr = :label,
                    definition_default = :definition,
                    definition_fr = :definition,
                    source = 'GeoNature',
                    statut = 'Validé',
                    active = true
                """).bindparams(
                cd_nomenclature=cd_nomenclature,
                label=label,
                mnemonique=mnemonique,
                definition=definition,
            )
        )

    insert_new_nomenclature("1.", "taxon", "Taxon", "Données d'occurrence de taxons")
    insert_new_nomenclature("2.", "habitat", "Habitat", "Données d'occurrence d'habitats")
    insert_new_nomenclature("3.", "géologique", "Géologique", "Données géologiques")
    insert_new_nomenclature("4.", "autre", "Autres (à préciser)", "Autres types de données")


def remove_new_nomenclature():
    """
    Delete the new nomenclatures : taxon, habitat, géologique, autre
    """
    op.execute(f"""
        DELETE
        FROM ref_nomenclatures.t_nomenclatures
        WHERE cd_nomenclature IN ('1.', '2.', '3.', '4.')
          AND id_type = {select_id_type("DATA_CATEGORY")}
        """)


def delete_default_values():
    """
    We can't undo this
    """
    op.execute("""
        DELETE FROM ref_nomenclatures.defaults_nomenclatures_value
        WHERE mnemonique_type = 'DATA_TYP'
        """)


def rename_nomenclature(mnemonique, old_mnemonique, label):
    """
    Rename the nomenclature type
    """
    op.execute(f"""
        UPDATE ref_nomenclatures.bib_nomenclatures_types
        SET mnemonique    = '{mnemonique}',
            label_default = '{label}',
            label_fr      = '{label}'
        WHERE mnemonique = '{old_mnemonique}'
        """)


def deactivate_old_nomenclature():
    """
    Deactivate the old nomenclatures and "géologique"
    """
    op.execute(f"""
        UPDATE ref_nomenclatures.t_nomenclatures
        SET active = false
        WHERE cd_nomenclature IN ('1', '2', '3', '4', '5')
          AND id_type = {select_id_type("DATA_CATEGORY")}
        """)

    op.execute(f"""
        UPDATE ref_nomenclatures.t_nomenclatures
        SET active = false
        WHERE cd_nomenclature = '3.'
          AND id_type = {select_id_type("DATA_CATEGORY")}
        """)


def reactivate_old_nomenclature():
    """
    Reactivate the old nomenclatures and deactivate new one
    """
    op.execute(f"""
        UPDATE ref_nomenclatures.t_nomenclatures
        SET active = true
        WHERE cd_nomenclature IN ('1', '2', '3', '4', '5')
          AND id_type = {select_id_type("DATA_CATEGORY")}
        """)
    op.execute(f"""
        UPDATE ref_nomenclatures.t_nomenclatures
        SET active = false
        WHERE cd_nomenclature IN ('1.', '2.', '3.', '4.')
          AND id_type = {select_id_type("DATA_CATEGORY")}
        """)


def use_new_nomenclature():
    """
    Migrate existing data to the new nomenclatures. Warning, some values are lost (Syntax become taxon and Synhab
     becomes habitat)
    """
    # Occurence de taxons and SynTax becomes taxon
    op.execute(f"""
        UPDATE gn_meta.t_datasets
        SET id_nomenclature_data_type = (SELECT id_nomenclature
                                             FROM ref_nomenclatures.t_nomenclatures
                                             WHERE cd_nomenclature = '1.'
                                               AND id_type = {select_id_type("DATA_TYP")})
        WHERE id_nomenclature_data_type in (SELECT id_nomenclature
                                               FROM ref_nomenclatures.t_nomenclatures
                                               WHERE (cd_nomenclature = '1' OR cd_nomenclature = '3')
                                                 AND id_type = {select_id_type("DATA_TYP")})
        """)

    # Occurence d'habitat and SynHab becomes habitat
    op.execute(f"""
        UPDATE gn_meta.t_datasets
        SET id_nomenclature_data_type = (SELECT id_nomenclature
                                             FROM ref_nomenclatures.t_nomenclatures
                                             WHERE cd_nomenclature = '2.'
                                               AND id_type = {select_id_type("DATA_TYP")})
        WHERE id_nomenclature_data_type in (SELECT id_nomenclature
                                               FROM ref_nomenclatures.t_nomenclatures
                                               WHERE (cd_nomenclature = '2' OR cd_nomenclature= '4')
                                                 AND id_type = {select_id_type("DATA_TYP")})
        """)

    op.execute(f"""
        UPDATE gn_meta.t_datasets
        SET id_nomenclature_data_type = (SELECT id_nomenclature
                                             FROM ref_nomenclatures.t_nomenclatures
                                             WHERE cd_nomenclature = '4.'
                                               AND id_type = {select_id_type("DATA_TYP")}),
            precision_data_category = NULL
        WHERE id_nomenclature_data_type = (SELECT id_nomenclature
                                               FROM ref_nomenclatures.t_nomenclatures
                                               WHERE cd_nomenclature = '5'
                                                 AND id_type = {select_id_type("DATA_TYP")})
        """)


def restore_old_nomenclature():
    """
    Restore the old nomenclature values from the new ones. Warning, some values are lost (Syntax become taxon and
     Synhab becomes habitats)
    """
    op.execute(f"""
        UPDATE gn_meta.t_datasets
        SET id_nomenclature_data_type = (SELECT id_nomenclature
                                         FROM ref_nomenclatures.t_nomenclatures
                                         WHERE cd_nomenclature = '1'
                                           AND id_type = {select_id_type("DATA_TYP")}),
            precision_data_category   = NULL
        WHERE id_nomenclature_data_type = (SELECT id_nomenclature
                                           FROM ref_nomenclatures.t_nomenclatures
                                           WHERE cd_nomenclature = '1.'
                                             AND id_type = {select_id_type("DATA_TYP")})
        """)

    op.execute(f"""
        UPDATE gn_meta.t_datasets
        SET id_nomenclature_data_type = (SELECT id_nomenclature
                                         FROM ref_nomenclatures.t_nomenclatures
                                         WHERE cd_nomenclature = '2'
                                           AND id_type = {select_id_type("DATA_TYP")})
        WHERE id_nomenclature_data_type = (SELECT id_nomenclature
                                           FROM ref_nomenclatures.t_nomenclatures
                                           WHERE cd_nomenclature = '2.'
                                             AND id_type = {select_id_type("DATA_TYP")})
        """)

    op.execute(f"""
        UPDATE gn_meta.t_datasets
        SET id_nomenclature_data_type = (SELECT id_nomenclature
                                         FROM ref_nomenclatures.t_nomenclatures
                                         WHERE cd_nomenclature = '5'
                                           AND id_type = {select_id_type("DATA_TYP")})
        WHERE id_nomenclature_data_type = (SELECT id_nomenclature
                                           FROM ref_nomenclatures.t_nomenclatures
                                           WHERE cd_nomenclature = '4.'
                                             AND id_type = {select_id_type("DATA_TYP")})
        """)


def rename_id_nomenclature_data_type(new_name, old_name):
    op.execute(f"""
        ALTER TABLE gn_meta.t_datasets
            RENAME COLUMN {old_name} TO {new_name}
        """)
