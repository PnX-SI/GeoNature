"""multidest

Revision ID: 2b0b3bd0248c
Revises: 2896cf965dd6
Create Date: 2023-10-20 09:05:49.973738

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.schema import Table, MetaData
from sqlalchemy.dialects.postgresql import JSON


# revision identifiers, used by Alembic.
revision = "2b0b3bd0248c"
down_revision = "2896cf965dd6"
branch_labels = None
depends_on = None


def upgrade():
    meta = MetaData(bind=op.get_bind())
    # Rename synthese_field → dest_field
    op.alter_column(
        schema="gn_imports",
        table_name="bib_fields",
        column_name="synthese_field",
        new_column_name="dest_field",
    )
    # Set valid column nullable
    op.alter_column(
        schema="gn_imports",
        table_name="t_imports_synthese",
        column_name="valid",
        nullable=True,
        server_default=None,
    )
    ### Destination
    module = Table("t_modules", meta, autoload=True, schema="gn_commons")
    id_module_synthese = (
        op.get_bind()
        .execute(sa.select([module.c.id_module]).where(module.c.module_code == "SYNTHESE"))
        .scalar()
    )
    destination = op.create_table(
        "bib_destinations",
        sa.Column("id_destination", sa.Integer, primary_key=True),
        sa.Column(
            "id_module",
            sa.Integer,
            sa.ForeignKey("gn_commons.t_modules.id_module", ondelete="CASCADE"),
        ),
        sa.Column("code", sa.String(64), unique=True),
        sa.Column("label", sa.String(128)),
        sa.Column("table_name", sa.String(64)),
        schema="gn_imports",
    )
    id_dest_synthese = (
        op.get_bind()
        .execute(
            sa.insert(destination)
            .values(
                id_module=id_module_synthese,
                code="synthese",
                label="Synthèse",
                table_name="t_imports_synthese",
            )
            .returning(destination.c.id_destination)
        )
        .scalar()
    )
    # Add reference from fields
    op.add_column(
        "bib_fields",
        sa.Column(
            "id_destination",
            sa.Integer,
            sa.ForeignKey("gn_imports.bib_destinations.id_destination", ondelete="CASCADE"),
            nullable=True,
        ),
        schema="gn_imports",
    )
    field = Table("bib_fields", meta, autoload=True, schema="gn_imports")
    op.execute(field.update().values({"id_destination": id_dest_synthese}))
    op.alter_column(
        table_name="bib_fields", column_name="id_destination", nullable=False, schema="gn_imports"
    )
    # Change unique constraint to include destination
    op.drop_constraint(
        schema="gn_imports",
        table_name="bib_fields",
        constraint_name="unicity_t_mappings_fields_name_field",
    )
    op.create_unique_constraint(
        schema="gn_imports",
        table_name="bib_fields",
        columns=["id_destination", "name_field"],
        constraint_name="unicity_bib_fields_dest_name_field",
    )
    # Add reference from imports
    op.add_column(
        "t_imports",
        sa.Column(
            "id_destination",
            sa.Integer,
            sa.ForeignKey("gn_imports.bib_destinations.id_destination", ondelete="RESTRICT"),
            nullable=True,
        ),
        schema="gn_imports",
    )
    imprt = Table("t_imports", meta, autoload=True, schema="gn_imports")
    op.execute(imprt.update().values({"id_destination": id_dest_synthese}))
    op.alter_column(
        table_name="t_imports", column_name="id_destination", nullable=False, schema="gn_imports"
    )
    # Add reference from mappings
    op.add_column(
        "t_mappings",
        sa.Column(
            "id_destination",
            sa.Integer,
            sa.ForeignKey("gn_imports.bib_destinations.id_destination", ondelete="CASCADE"),
            nullable=True,
        ),
        schema="gn_imports",
    )
    mapping = Table("t_mappings", meta, autoload=True, schema="gn_imports")
    op.execute(mapping.update().values({"id_destination": id_dest_synthese}))
    op.alter_column(
        table_name="t_mappings", column_name="id_destination", nullable=False, schema="gn_imports"
    )
    ### Entities
    entity = op.create_table(
        "bib_entities",
        sa.Column("id_entity", sa.Integer, primary_key=True),
        sa.Column(
            "id_destination",
            sa.Integer,
            sa.ForeignKey(destination.c.id_destination, ondelete="CASCADE"),
        ),
        sa.Column("code", sa.String(16)),
        sa.Column("label", sa.String(64)),
        sa.Column("order", sa.Integer),
        sa.Column("validity_column", sa.String(64)),
        sa.Column("destination_table_schema", sa.String(63)),
        sa.Column("destination_table_name", sa.String(63)),
        schema="gn_imports",
    )
    id_entity_obs = (
        op.get_bind()
        .execute(
            sa.insert(entity)
            .values(
                id_destination=id_dest_synthese,
                code="observation",
                label="Observation",
                order=1,
                validity_column="valid",
                destination_table_schema="gn_synthese",
                destination_table_name="synthese",
            )
            .returning(entity.c.id_entity)
        )
        .scalar()
    )
    # Association fields ↔ entities
    cor_entity_field = op.create_table(
        "cor_entity_field",
        sa.Column(
            "id_entity",
            sa.Integer,
            sa.ForeignKey("gn_imports.bib_entities.id_entity", ondelete="CASCADE"),
            primary_key=True,
        ),
        sa.Column(
            "id_field",
            sa.Integer,
            sa.ForeignKey("gn_imports.bib_fields.id_field", ondelete="CASCADE"),
            primary_key=True,
        ),
        sa.Column("desc_field", sa.String(1000)),
        sa.Column(
            "id_theme", sa.Integer, sa.ForeignKey("gn_imports.bib_themes.id_theme"), nullable=False
        ),
        sa.Column("order_field", sa.Integer, nullable=False),
        sa.Column("comment", sa.String),
        schema="gn_imports",
    )
    op.execute(
        sa.insert(cor_entity_field).from_select(
            [
                "id_entity",
                "id_field",
                "desc_field",
                "id_theme",
                "order_field",
                "comment",
            ],
            sa.select(
                [
                    id_entity_obs,
                    field.c.id_field,
                    field.c.desc_field,
                    field.c.id_theme,
                    field.c.order_field,
                    field.c.comment,
                ]
            ),
        )
    )
    # Remove from bib_fields columns moved to cor_entity_field
    for column_name in ["desc_field", "id_theme", "order_field", "comment"]:
        op.drop_column(schema="gn_imports", table_name="bib_fields", column_name=column_name)
    ### Permissions
    op.execute(
        """
        INSERT INTO
            gn_permissions.t_permissions_available (id_module, id_object, id_action, label, scope_filter)
        SELECT
            m.id_module, o.id_object, a.id_action, 'Importer des observations', TRUE
        FROM
            gn_commons.t_modules m,
            gn_permissions.t_objects o,
            gn_permissions.bib_actions a
        WHERE
            m.module_code = 'SYNTHESE'
            AND
            o.code_object = 'ALL'
            AND
            a.code_action = 'C'
        """
    )
    op.execute(
        """
        INSERT INTO
            gn_permissions.t_permissions (id_role, id_module, id_object, id_action, scope_value)
        SELECT
            p.id_role, new_module.id_module, new_object.id_object, p.id_action, p.scope_value
        FROM
            gn_permissions.t_permissions p
                JOIN gn_permissions.bib_actions a USING(id_action)
                JOIN gn_commons.t_modules m USING(id_module)
                JOIN gn_permissions.t_objects o USING(id_object)
                JOIN utilisateurs.t_roles r USING(id_role),
            gn_commons.t_modules new_module,
            gn_permissions.t_objects new_object
        WHERE
            a.code_action = 'C' AND m.module_code = 'IMPORT' AND o.code_object = 'IMPORT'
            AND
            new_module.module_code = 'SYNTHESE' AND new_object.code_object = 'ALL';
        """
    )
    # TODO constraint entity_field.entity.id_destination == entity_field.field.id_destination
    ### Remove synthese specific 'id_source' column
    op.drop_column(schema="gn_imports", table_name="t_imports", column_name="id_source_synthese")
    ### Put synthese specific 'taxa_count' field in generic 'statistics' field
    op.add_column(
        schema="gn_imports",
        table_name="t_imports",
        column=sa.Column(
            "statistics",
            JSON,
            nullable=False,
            server_default=sa.text("'{}'::jsonb"),
        ),
    )
    op.execute(
        """
        UPDATE
            gn_imports.t_imports
        SET
            statistics = json_build_object('taxa_count', taxa_count)
        WHERE
            taxa_count IS NOT NULL
        """
    )
    op.drop_column(schema="gn_imports", table_name="t_imports", column_name="taxa_count")
    # Add new error types
    error_type = Table("bib_errors_types", meta, autoload=True, schema="gn_imports")
    op.execute(
        sa.insert(error_type).values(
            [
                {
                    "error_type": "Ligne orpheline",
                    "name": "ORPHAN_ROW",
                    "description": "La ligne du fichier n’a pû être rattaché à aucune entité.",
                    "error_level": "WARNING",
                },
                {
                    "error_type": "Erreur de référentiel",
                    "name": "DATASET_NOT_FOUND",
                    "description": "La référence du jeu de données n’a pas été trouvé",
                    "error_level": "ERROR",
                },
                {
                    "error_type": "Erreur de référentiel",
                    "name": "DATASET_NOT_AUTHORIZED",
                    "description": "Vous n’avez pas les permissions nécessaire sur le jeu de données.",
                    "error_level": "ERROR",
                },
                {
                    "error_type": "Entités",
                    "name": "NO_PARENT_ENTITY",
                    "description": "Aucune entité parente identifiée.",
                    "error_level": "ERROR",
                },
                {
                    "error_type": "Entités",
                    "name": "ERRONEOUS_PARENT_ENTITY",
                    "description": "L’entité parente est en erreur.",
                    "error_level": "ERROR",
                },
            ]
        )
    )
    # Remove ng_module from import
    op.execute(
        """
        UPDATE
            gn_commons.t_modules
        SET
            ng_module = NULL
        WHERE
            module_code = 'IMPORT'
        """
    )


def downgrade():
    meta = MetaData(bind=op.get_bind())
    # Remove new error types
    error_type = Table("bib_errors_types", meta, autoload=True, schema="gn_imports")
    op.execute(
        sa.delete(error_type).where(
            error_type.c.name.in_(
                [
                    "ORPHAN_ROW",
                    "DATASET_NOT_FOUND",
                    "DATASET_NOT_AUTHORIZED",
                    "NO_PARENT_ENTITY",
                    "ERRONEOUS_PARENT_ENTITY",
                ]
            )
        )
    )
    # Restore 'taxa_count'
    op.add_column(
        schema="gn_imports",
        table_name="t_imports",
        column=sa.Column(
            "taxa_count",
            sa.Integer,
            nullable=True,
        ),
    )
    op.execute(
        """
        UPDATE
            gn_imports.t_imports
        SET
            taxa_count = (statistics ->> 'taxa_count')::integer
        WHERE
            to_jsonb(statistics) ? 'taxa_count'
        """
    )
    op.drop_column(schema="gn_imports", table_name="t_imports", column_name="statistics")
    # Restore 'id_source_synthese'
    op.add_column(
        schema="gn_imports",
        table_name="t_imports",
        column=sa.Column(
            "id_source_synthese",
            sa.Integer,
            sa.ForeignKey("gn_synthese.t_sources.id_source"),
            nullable=True,
        ),
    )
    op.execute(
        """
        UPDATE
            gn_imports.t_imports i
        SET
            id_source_synthese = s.id_source
        FROM
            gn_synthese.t_sources s
        WHERE
            s.id_module = (SELECT id_module FROM gn_commons.t_modules WHERE module_code = 'IMPORT')
            AND
            s.name_source = 'Import(id=' || i.id_import || ')'
        """
    )
    op.execute(
        """
        DELETE FROM
            gn_permissions.t_permissions p
        USING
            gn_permissions.bib_actions a,
            gn_commons.t_modules m,
            gn_permissions.t_objects o
        WHERE
            p.id_action = a.id_action AND a.code_action = 'C'
            AND
            p.id_module = m.id_module AND m.module_code = 'SYNTHESE'
            AND
            p.id_object = o.id_object AND o.code_object = 'ALL';
        """
    )
    op.execute(
        """
        DELETE FROM
            gn_permissions.t_permissions_available pa
        USING
            gn_permissions.bib_actions a,
            gn_commons.t_modules m,
            gn_permissions.t_objects o
        WHERE
            pa.id_action = a.id_action AND a.code_action = 'C'
            AND
            pa.id_module = m.id_module AND m.module_code = 'SYNTHESE'
            AND
            pa.id_object = o.id_object AND o.code_object = 'ALL';
        """
    )
    with op.batch_alter_table(schema="gn_imports", table_name="bib_fields") as batch:
        batch.add_column(sa.Column("desc_field", sa.String(1000)))
        batch.add_column(
            sa.Column("id_theme", sa.Integer, sa.ForeignKey("gn_imports.bib_themes.id_theme"))
        )
        batch.add_column(sa.Column("order_field", sa.Integer))
        batch.add_column(sa.Column("comment", sa.String))
    # Note: there should be only synthese observations fields
    op.execute(
        """
        UPDATE
            gn_imports.bib_fields f
        SET
            desc_field = cef.desc_field,
            id_theme = cef.id_theme,
            order_field = cef.order_field,
            comment = cef.comment
        FROM
            gn_imports.cor_entity_field cef,
            gn_imports.bib_entities e,
            gn_imports.bib_destinations d
        WHERE
            cef.id_field = f.id_field
            AND
            e.id_entity = cef.id_entity
            AND
            d.id_destination = e.id_destination
            AND
            d.code = 'synthese'
            AND
            e.code = 'observation'
        """
    )
    with op.batch_alter_table(schema="gn_imports", table_name="bib_fields") as batch:
        batch.alter_column(column_name="id_theme", nullable=False)
        batch.alter_column(column_name="order_field", nullable=False)
    op.drop_table("cor_entity_field", schema="gn_imports")
    op.drop_table("bib_entities", schema="gn_imports")
    op.drop_column(schema="gn_imports", table_name="t_imports", column_name="id_destination")
    op.drop_column(schema="gn_imports", table_name="t_mappings", column_name="id_destination")
    op.drop_constraint(
        schema="gn_imports",
        table_name="bib_fields",
        constraint_name="unicity_bib_fields_dest_name_field",
    )
    op.create_unique_constraint(
        schema="gn_imports",
        table_name="bib_fields",
        columns=["name_field"],
        constraint_name="unicity_t_mappings_fields_name_field",
    )
    op.drop_column(schema="gn_imports", table_name="bib_fields", column_name="id_destination")
    op.drop_table("bib_destinations", schema="gn_imports")
    op.alter_column(
        schema="gn_imports",
        table_name="t_imports_synthese",
        column_name="valid",
        nullable=False,
        server_default=sa.false(),
    )
    op.alter_column(
        schema="gn_imports",
        table_name="bib_fields",
        column_name="dest_field",
        new_column_name="synthese_field",
    )
