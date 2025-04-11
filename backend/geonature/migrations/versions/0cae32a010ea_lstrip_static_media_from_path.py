"""lstrip static/medias/ from t_medias.media_path

Revision ID: 0cae32a010ea
Revises: 497f52d996dd
Create Date: 2023-01-25 18:01:06.482391

"""

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "0cae32a010ea"
down_revision = "497f52d996dd"
branch_labels = None
depends_on = None


def upgrade():
    op.execute(
        """
        UPDATE
            gn_commons.t_medias
        SET
            media_path = regexp_replace(media_path, '^static/medias/', '')
        WHERE
            media_path IS NOT NULL
        """
    )
    op.execute(
        """
        UPDATE
            gn_commons.t_mobile_apps
        SET
            relative_path_apk = regexp_replace(relative_path_apk, '^static/mobile/', '')
        WHERE
            relative_path_apk IS NOT NULL
        """
    )


def downgrade():
    op.execute(
        """
        UPDATE
            gn_commons.t_medias
        SET
            media_path = 'static/medias/' || media_path
        WHERE
            media_path IS NOT NULL
        """
    )
    op.execute(
        """
        UPDATE
            gn_commons.t_mobile_apps
        SET
            relative_path_apk = 'static/mobile/' || relative_path_apk
        WHERE
            relative_path_apk IS NOT NULL
        """
    )
