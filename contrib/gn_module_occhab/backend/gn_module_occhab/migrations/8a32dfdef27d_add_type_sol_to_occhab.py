"""Add type sol to occhab

Revision ID: 8a32dfdef27d
Revises: 5fe452b34a79
Create Date: 2025-04-02 10:22:03.398938

"""

from alembic import op
import sqlalchemy as sa
from sqlalchemy.schema import Table, MetaData
from sqlalchemy.orm.session import Session


# revision identifiers, used by Alembic.
revision = "8a32dfdef27d"
down_revision = "5fe452b34a79"
branch_labels = None
depends_on = None


def upgrade():
    metadata = MetaData(bind=op.get_bind())
    session = Session(bind=op.get_bind())
    nomenclature = Table("t_nomenclatures", metadata, schema="ref_nomenclatures", autoload=True)
    nomenclature_type = Table(
        "bib_nomenclatures_types", metadata, schema="ref_nomenclatures", autoload=True
    )
    op.execute(
        sa.insert(nomenclature_type).values(
            dict(
                mnemonique="TYPE_SOL",
                label_fr="Type de sol",
                label_default="Type de sol",
                definition_fr="",
                source="SINP",
                statut="Validé",
            )
        )
    )
    id_type = sa.func.ref_nomenclatures.get_id_nomenclature_type("TYPE_SOL")
    nomenclatures = [
        dict(
            id_type=id_type,
            cd_nomenclature="1",
            mnemonique="Alocrisols",
            label_fr="Alocrisols",
            definition_fr="""""",
            source="SINP",
            statut="Validé",
            id_broader=0,
            hierarchy=None,
            active=True,
            label_default="Alocrisols",
        ),
        dict(
            id_type=id_type,
            cd_nomenclature="2",
            mnemonique="Andosols",
            label_fr="Andosols",
            definition_fr="""""",
            source="SINP",
            statut="Validé",
            id_broader=0,
            hierarchy=None,
            active=True,
            label_default="Andosols",
        ),
        dict(
            id_type=id_type,
            cd_nomenclature="3",
            mnemonique="Anthroposols",
            label_fr="Anthroposols",
            definition_fr="""""",
            source="SINP",
            statut="Validé",
            id_broader=0,
            hierarchy=None,
            active=True,
            label_default="Anthroposols",
        ),
        dict(
            id_type=id_type,
            cd_nomenclature="4",
            mnemonique="Arénosols",
            label_fr="Arénosols",
            definition_fr="""""",
            source="SINP",
            statut="Validé",
            id_broader=0,
            hierarchy=None,
            active=True,
            label_default="Arénosols",
        ),
        dict(
            id_type=id_type,
            cd_nomenclature="5",
            mnemonique="Brunisols",
            label_fr="Brunisols",
            definition_fr="""""",
            source="SINP",
            statut="Validé",
            id_broader=0,
            hierarchy=None,
            active=True,
            label_default="Brunisols",
        ),
        dict(
            id_type=id_type,
            cd_nomenclature="6",
            mnemonique="Solums dont le complexe adsorbant est dominé par le calcium (et/ou le magnésium)",
            label_fr="Solums dont le complexe adsorbant est dominé par le calcium (et/ou le magnésium)",
            definition_fr="""""",
            source="SINP",
            statut="Validé",
            id_broader=0,
            hierarchy=None,
            active=True,
            label_default="Solums dont le complexe adsorbant est dominé par le calcium (et/ou le magnésium)",
        ),
        dict(
            id_type=id_type,
            cd_nomenclature="7",
            mnemonique="Chernosols",
            label_fr="Chernosols",
            definition_fr="""""",
            source="SINP",
            statut="Validé",
            id_broader=0,
            hierarchy=None,
            active=True,
            label_default="Chernosols",
        ),
        dict(
            id_type=id_type,
            cd_nomenclature="8",
            mnemonique="Colluviosols",
            label_fr="Colluviosols",
            definition_fr="""""",
            source="SINP",
            statut="Validé",
            id_broader=0,
            hierarchy=None,
            active=True,
            label_default="Colluviosols",
        ),
        dict(
            id_type=id_type,
            cd_nomenclature="9",
            mnemonique="Cryosols",
            label_fr="Cryosols",
            definition_fr="""""",
            source="SINP",
            statut="Validé",
            id_broader=0,
            hierarchy=None,
            active=True,
            label_default="Cryosols",
        ),
        dict(
            id_type=id_type,
            cd_nomenclature="10",
            mnemonique="Ferrallitisols et oxydisols",
            label_fr="Ferrallitisols et oxydisols",
            definition_fr="""""",
            source="SINP",
            statut="Validé",
            id_broader=0,
            hierarchy=None,
            active=True,
            label_default="Ferrallitisols et oxydisols",
        ),
        dict(
            id_type=id_type,
            cd_nomenclature="11",
            mnemonique="Ferruginosols",
            label_fr="Ferruginosols",
            definition_fr="""""",
            source="SINP",
            statut="Validé",
            id_broader=0,
            hierarchy=None,
            active=True,
            label_default="Ferruginosols",
        ),
        dict(
            id_type=id_type,
            cd_nomenclature="12",
            mnemonique="Fersialsols",
            label_fr="Fersialsols",
            definition_fr="""""",
            source="SINP",
            statut="Validé",
            id_broader=0,
            hierarchy=None,
            active=True,
            label_default="Fersialsols",
        ),
        dict(
            id_type=id_type,
            cd_nomenclature="13",
            mnemonique="Fluviosols",
            label_fr="Fluviosols",
            definition_fr="""""",
            source="SINP",
            statut="Validé",
            id_broader=0,
            hierarchy=None,
            active=True,
            label_default="Fluviosols",
        ),
        dict(
            id_type=id_type,
            cd_nomenclature="14",
            mnemonique="Grisols",
            label_fr="Grisols",
            definition_fr="""""",
            source="SINP",
            statut="Validé",
            id_broader=0,
            hierarchy=None,
            active=True,
            label_default="Grisols",
        ),
        dict(
            id_type=id_type,
            cd_nomenclature="15",
            mnemonique="Gypsosols",
            label_fr="Gypsosols",
            definition_fr="""""",
            source="SINP",
            statut="Validé",
            id_broader=0,
            hierarchy=None,
            active=True,
            label_default="Gypsosols",
        ),
        dict(
            id_type=id_type,
            cd_nomenclature="16",
            mnemonique="Histosols",
            label_fr="Histosols",
            definition_fr="""""",
            source="SINP",
            statut="Validé",
            id_broader=0,
            hierarchy=None,
            active=True,
            label_default="Histosols",
        ),
        dict(
            id_type=id_type,
            cd_nomenclature="17",
            mnemonique="Leptismectisols",
            label_fr="Leptismectisols",
            definition_fr="""""",
            source="SINP",
            statut="Validé",
            id_broader=0,
            hierarchy=None,
            active=True,
            label_default="Leptismectisols",
        ),
        dict(
            id_type=id_type,
            cd_nomenclature="18",
            mnemonique="Lithosols",
            label_fr="Lithosols",
            definition_fr="""""",
            source="SINP",
            statut="Validé",
            id_broader=0,
            hierarchy=None,
            active=True,
            label_default="Lithosols",
        ),
        dict(
            id_type=id_type,
            cd_nomenclature="19",
            mnemonique="Luvisols",
            label_fr="Luvisols",
            definition_fr="""""",
            source="SINP",
            statut="Validé",
            id_broader=0,
            hierarchy=None,
            active=True,
            label_default="Luvisols",
        ),
        dict(
            id_type=id_type,
            cd_nomenclature="20",
            mnemonique="Nitosols",
            label_fr="Nitosols",
            definition_fr="""""",
            source="SINP",
            statut="Validé",
            id_broader=0,
            hierarchy=None,
            active=True,
            label_default="Nitosols",
        ),
        dict(
            id_type=id_type,
            cd_nomenclature="21",
            mnemonique="Organosols",
            label_fr="Organosols",
            definition_fr="""""",
            source="SINP",
            statut="Validé",
            id_broader=0,
            hierarchy=None,
            active=True,
            label_default="Organosols",
        ),
        dict(
            id_type=id_type,
            cd_nomenclature="22",
            mnemonique="Pélosols",
            label_fr="Pélosols",
            definition_fr="""""",
            source="SINP",
            statut="Validé",
            id_broader=0,
            hierarchy=None,
            active=True,
            label_default="Pélosols",
        ),
        dict(
            id_type=id_type,
            cd_nomenclature="23",
            mnemonique="Peyrosols",
            label_fr="Peyrosols",
            definition_fr="""""",
            source="SINP",
            statut="Validé",
            id_broader=0,
            hierarchy=None,
            active=True,
            label_default="Peyrosols",
        ),
        dict(
            id_type=id_type,
            cd_nomenclature="24",
            mnemonique="Phæosols",
            label_fr="Phæosols",
            definition_fr="""""",
            source="SINP",
            statut="Validé",
            id_broader=0,
            hierarchy=None,
            active=True,
            label_default="Phæosols",
        ),
        dict(
            id_type=id_type,
            cd_nomenclature="25",
            mnemonique="Planosols",
            label_fr="Planosols",
            definition_fr="""""",
            source="SINP",
            statut="Validé",
            id_broader=0,
            hierarchy=None,
            active=True,
            label_default="Planosols",
        ),
        dict(
            id_type=id_type,
            cd_nomenclature="26",
            mnemonique="Podzosols",
            label_fr="Podzosols",
            definition_fr="""""",
            source="SINP",
            statut="Validé",
            id_broader=0,
            hierarchy=None,
            active=True,
            label_default="Podzosols",
        ),
        dict(
            id_type=id_type,
            cd_nomenclature="27",
            mnemonique="Rankosols",
            label_fr="Rankosols",
            definition_fr="""""",
            source="SINP",
            statut="Validé",
            id_broader=0,
            hierarchy=None,
            active=True,
            label_default="Rankosols",
        ),
        dict(
            id_type=id_type,
            cd_nomenclature="28",
            mnemonique="Réductisols et rédoxisols",
            label_fr="Réductisols et rédoxisols",
            definition_fr="""""",
            source="SINP",
            statut="Validé",
            id_broader=0,
            hierarchy=None,
            active=True,
            label_default="Réductisols et rédoxisols",
        ),
        dict(
            id_type=id_type,
            cd_nomenclature="29",
            mnemonique="Régosols",
            label_fr="Régosols",
            definition_fr="""""",
            source="SINP",
            statut="Validé",
            id_broader=0,
            hierarchy=None,
            active=True,
            label_default="Régosols",
        ),
        dict(
            id_type=id_type,
            cd_nomenclature="30",
            mnemonique="Salisols et sodisols",
            label_fr="Salisols et sodisols",
            definition_fr="""""",
            source="SINP",
            statut="Validé",
            id_broader=0,
            hierarchy=None,
            active=True,
            label_default="Salisols et sodisols",
        ),
        dict(
            id_type=id_type,
            cd_nomenclature="31",
            mnemonique="Thalassosols",
            label_fr="Thalassosols",
            definition_fr="""""",
            source="SINP",
            statut="Validé",
            id_broader=0,
            hierarchy=None,
            active=True,
            label_default="Thalassosols",
        ),
        dict(
            id_type=id_type,
            cd_nomenclature="32",
            mnemonique="Thiosols et sulfatosols",
            label_fr="Thiosols et sulfatosols",
            definition_fr="""""",
            source="SINP",
            statut="Validé",
            id_broader=0,
            hierarchy=None,
            active=True,
            label_default="Thiosols et sulfatosols",
        ),
        dict(
            id_type=id_type,
            cd_nomenclature="33",
            mnemonique="Veracrisols",
            label_fr="Veracrisols",
            definition_fr="""""",
            source="SINP",
            statut="Validé",
            id_broader=0,
            hierarchy=None,
            active=True,
            label_default="Veracrisols",
        ),
        dict(
            id_type=id_type,
            cd_nomenclature="34",
            mnemonique="Vertisols",
            label_fr="Vertisols",
            definition_fr="""""",
            source="SINP",
            statut="Validé",
            id_broader=0,
            hierarchy=None,
            active=True,
            label_default="Vertisols",
        ),
    ]

    for nom in nomenclatures:
        op.execute(sa.insert(nomenclature).values(**nom))

    op.add_column(
        "t_stations",
        sa.Column(
            "id_nomenclature_type_sol",
            sa.Integer(),
            sa.ForeignKey("ref_nomenclatures.t_nomenclatures.id_nomenclature"),
            nullable=True,
        ),
        schema="pr_occhab",
    )

    op.add_column(
        "t_imports_occhab",
        sa.Column(
            "src_id_nomenclature_type_sol",
            sa.String,
            nullable=True,
        ),
        schema="gn_imports",
    )

    op.add_column(
        "t_imports_occhab",
        sa.Column(
            "id_nomenclature_type_sol",
            sa.Integer(),
            sa.ForeignKey("ref_nomenclatures.t_nomenclatures.id_nomenclature"),
            nullable=True,
        ),
        schema="gn_imports",
    )

    field = sa.Table("bib_fields", metadata, schema="gn_imports", autoload=True)
    cor_entity_field = sa.Table("cor_entity_field", metadata, schema="gn_imports", autoload=True)
    destination = sa.Table("bib_destinations", metadata, schema="gn_imports", autoload=True)
    theme = sa.Table("bib_themes", metadata, schema="gn_imports", autoload=True)
    entity = sa.Table("bib_entities", metadata, schema="gn_imports", autoload=True)

    id_dest_occhab = session.scalar(
        sa.select(destination.c.id_destination).where(destination.c.code == "occhab")
    )

    id_theme = session.scalar(
        sa.select(theme.c.id_theme).where(theme.c.name_theme == "general_info")
    )
    id_entity = session.scalar(sa.select(entity.c.id_entity).where(entity.c.code == "station"))

    id_field = (
        op.get_bind()
        .execute(
            sa.insert(field)
            .values(
                id_destination=id_dest_occhab,
                name_field="id_nomenclature_type_sol",
                fr_label="Type de sol",
                mandatory=False,
                autogenerated=False,
                display=True,
                mnemonique="TYPE_SOL",
                source_field="src_id_nomenclature_type_sol",
                dest_field="id_nomenclature_type_sol",
            )
            .returning(field.c.id_field)
        )
        .first()[0]
    )

    op.execute(
        sa.insert(cor_entity_field).values(
            id_field=id_field,
            id_entity=id_entity,
            id_theme=id_theme,
            order_field=16,
            comment="Correspondance champs standard: TypeSol",
        )
    )


def downgrade():
    metadata = MetaData(bind=op.get_bind())
    session = Session(bind=op.get_bind())

    field = sa.Table("bib_fields", metadata, schema="gn_imports", autoload=True)
    cor_entity_field = sa.Table("cor_entity_field", metadata, schema="gn_imports", autoload=True)
    nomenclature = Table("t_nomenclatures", metadata, schema="ref_nomenclatures", autoload=True)
    nomenclature_type = Table(
        "bib_nomenclatures_types", metadata, schema="ref_nomenclatures", autoload=True
    )

    id_field = session.scalar(
        sa.select(field.c.id_field).where(field.c.name_field == "id_nomenclature_type_sol")
    )
    id_type_nomenclature = session.scalar(
        sa.select(nomenclature_type.c.id_type).where(nomenclature_type.c.mnemonique == "TYPE_SOL")
    )

    op.execute(sa.delete(cor_entity_field).where(cor_entity_field.c.id_field == id_field))
    op.execute(sa.delete(field).where(field.c.name_field == "id_nomenclature_type_sol"))

    op.drop_column(
        schema="pr_occhab",
        table_name="t_stations",
        column_name="id_nomenclature_type_sol",
    )
    op.drop_column(
        schema="gn_imports",
        table_name="t_imports_occhab",
        column_name="src_id_nomenclature_type_sol",
    )
    op.drop_column(
        schema="gn_imports",
        table_name="t_imports_occhab",
        column_name="id_nomenclature_type_sol",
    )

    op.execute(sa.delete(nomenclature).where(nomenclature.c.id_type == id_type_nomenclature))
    op.execute(sa.delete(nomenclature_type).where(nomenclature_type.c.mnemonique == "TYPE_SOL"))
