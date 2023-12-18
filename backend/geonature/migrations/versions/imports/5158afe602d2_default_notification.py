"""default notification

Revision ID: 5158afe602d2
Revises: 485a659efdcd
Create Date: 2023-03-22 16:17:51.354279

"""

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "5158afe602d2"
down_revision = "485a659efdcd"
branch_labels = None
depends_on = ("09a637f06b96",)


def upgrade():
    op.execute(
        """
        INSERT INTO
            gn_notifications.t_notifications_rules (code_category, code_method)
        VALUES
            ('IMPORT-DONE', 'DB'),
            ('IMPORT-DONE', 'EMAIL')
        """
    )


def downgrade():
    op.execute(
        """
        DELETE FROM
            gn_notifications.t_notifications_rules
        WHERE
            code_category = 'IMPORT-DONE'
        AND
            id_role IS NULL
        """
    )
