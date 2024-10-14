"""update synthese for import

Revision ID: c49474d2f1f7
Revises: a8a17e29f69c
Create Date: 2024-10-01 10:09:10.937073

"""

from alembic import op
from sqlalchemy.orm import Session
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "c49474d2f1f7"
down_revision = "a8a17e29f69c"
branch_labels = None
depends_on = None


def upgrade():
    # modifier la suppression de l'import synthese
    # modifier la création de la synthese depuis l'import
    # ajouter un filtre pour filtrer sur l'id_import
    # le mettre par default quand dans l'url
    op.add_column(
        schema="gn_synthese",
        table_name="synthese",
        column=sa.Column("id_import", sa.Integer()),
    )
    conn = op.get_bind()
    metadata = sa.MetaData(bind=conn)
    t_sources = sa.Table("t_sources", metadata, schema="gn_synthese", autoload_with=conn)
    t_modules = sa.Table("t_modules", metadata, schema="gn_commons", autoload_with=conn)
    t_synthese = sa.Table("synthese", metadata, schema="gn_synthese", autoload_with=conn)
    id_import_module = conn.execute(
        sa.select(t_modules.c.id_module).where(t_modules.c.module_code == "IMPORT")
    ).scalar_one()
    results = conn.execute(
        t_sources.insert()
        .values(
            name_source="Import",
            desc_source="Données issues du module Import",
            entity_source_pk_field="entity_source_pk_value",
            id_module=id_import_module,
        )
        .returning(t_sources.c.id_source)
    )
    id_source = [id_source for id_source, in results][0]
    op.execute(
        sa.update(t_synthese)
        .where(t_synthese.c.id_source == t_sources.c.id_source)
        .where(t_sources.c.id_module == id_import_module)
        .values(
            id_source=id_source,
            id_import=sa.func.cast(
                sa.func.regexp_replace(
                    t_sources.c.name_source,
                    r"^Import\(id=(\d+)\)$",
                    r"\1",
                    flags="g",
                ),
                sa.INT,
            ),
        )
    )
    conn.execute(
        t_sources.delete()
        .where(t_sources.c.id_module == id_import_module)
        .where(t_sources.c.id_source != id_source)
    )


def downgrade():
    conn = op.get_bind()
    metadata = sa.MetaData(bind=conn)
    t_sources = sa.Table("t_sources", metadata, schema="gn_synthese", autoload_with=conn)
    t_modules = sa.Table("t_modules", metadata, schema="gn_commons", autoload_with=conn)
    t_synthese = sa.Table("synthese", metadata, schema="gn_synthese", autoload_with=conn)
    query = (
        sa.select(
            (sa.func.concat("Import(id=", t_synthese.c.id_import, ")")).label("name_source"),
            (
                sa.func.concat("Imported data from import module (id=", t_synthese.c.id_import, ")")
            ).label("desc_source"),
            (sa.literal("entity_source_pk_value")).label("entity_source_pk_field"),
            ((sa.select(t_modules.c.id_module).where(t_modules.c.module_code == "IMPORT"))).label(
                "id_module"
            ),
        )
        .where(t_synthese.c.id_import != None)
        .distinct(t_synthese.c.id_import)
    )
    conn.execute(
        t_sources.insert().from_select(
            ["name_source", "desc_source", "entity_source_pk_field", "id_module"], query
        )
    )
    conn.execute(
        sa.update(t_synthese)
        .where(t_synthese.c.id_import != None)
        .where(t_sources.c.name_source == sa.func.concat("Import(id=", t_synthese.c.id_import, ")"))
        .values(id_import=None, id_source=t_sources.c.id_source)
    )
    op.execute(t_sources.delete().where(t_sources.c.name_source == "Import"))
    op.drop_column(
        schema="gn_synthese",
        table_name="synthese",
        column_name="id_import",
    )
