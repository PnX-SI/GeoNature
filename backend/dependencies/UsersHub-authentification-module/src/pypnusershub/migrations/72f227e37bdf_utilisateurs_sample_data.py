"""utilisateurs sample data

Revision ID: 72f227e37bdf
Revises: 
Create Date: 2021-08-24 15:39:57.784074

"""
import importlib.resources

from alembic import op
import sqlalchemy as sa
from sqlalchemy.sql import table, column

from pypnusershub.db.models import Organisme


# revision identifiers, used by Alembic.
revision = '72f227e37bdf'
down_revision = None
branch_labels = ('utilisateurs-samples',)
depends_on = ('fa35dfe5ff27',)


def upgrade():
    op.execute(importlib.resources.read_text('pypnusershub.migrations.data', 'utilisateurs-samples.sql'))


def downgrade():
    op.execute("""
    DELETE FROM utilisateurs.t_roles
    WHERE identifiant
    IN ('admin', 'agent', 'partenaire', 'pierre.paul', 'validateur')
    """)
    op.execute("""
    DELETE FROM utilisateurs.t_roles
    WHERE nom_role
    IN ('Grp_en_poste', 'Grp_admin')
    """)
    op.execute("""
    DELETE FROM utilisateurs.bib_organismes
    WHERE nom_organisme
    IN ('Autre', 'ma structure test')
    """)
