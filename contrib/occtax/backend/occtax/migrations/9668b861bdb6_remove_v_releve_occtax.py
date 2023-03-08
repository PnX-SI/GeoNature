"""remove v_releve_occtax

Revision ID: 9668b861bdb6
Revises: 4c97453a2d1a
Create Date: 2023-02-08 16:11:52.634937

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "9668b861bdb6"
down_revision = "4c97453a2d1a"
branch_labels = None
depends_on = None


def upgrade():
    op.execute("""DROP VIEW pr_occtax.v_releve_occtax""")


def downgrade():
    op.execute(
        """
        CREATE OR REPLACE VIEW pr_occtax.v_releve_occtax
        AS SELECT rel.id_releve_occtax,
            rel.id_dataset,
            rel.id_digitiser,
            rel.date_min,
            rel.date_max,
            rel.altitude_min,
            rel.altitude_max,
            rel.depth_min,
            rel.depth_max,
            rel.place_name,
            rel.meta_device_entry,
            rel.comment,
            rel.geom_4326,
            rel."precision",
            occ.id_occurrence_occtax,
            occ.cd_nom,
            occ.nom_cite,
            t.lb_nom,
            t.nom_valide,
            t.nom_vern,
            (((t.nom_complet_html::text || ' '::text) || rel.date_min::date) || '<br/>'::text) || string_agg(DISTINCT (obs.nom_role::text || ' '::text) || obs.prenom_role::text, ', '::text) AS leaflet_popup,
            COALESCE(string_agg(DISTINCT (obs.nom_role::text || ' '::text) || obs.prenom_role::text, ', '::text), rel.observers_txt::text) AS observateurs
           FROM pr_occtax.t_releves_occtax rel
             LEFT JOIN pr_occtax.t_occurrences_occtax occ ON rel.id_releve_occtax = occ.id_releve_occtax
             LEFT JOIN taxonomie.taxref t ON occ.cd_nom = t.cd_nom
             LEFT JOIN pr_occtax.cor_role_releves_occtax cor_role ON cor_role.id_releve_occtax = rel.id_releve_occtax
             LEFT JOIN utilisateurs.t_roles obs ON cor_role.id_role = obs.id_role
          GROUP BY rel.id_releve_occtax, rel.id_dataset, rel.id_digitiser, rel.date_min, rel.date_max, rel.altitude_min, rel.altitude_max, rel.depth_min, rel.depth_max, rel.place_name, rel.meta_device_entry, rel.comment, rel.geom_4326, rel."precision", t.cd_nom, occ.nom_cite, occ.id_occurrence_occtax, t.lb_nom, t.nom_valide, t.nom_complet_html, t.nom_vern;
        """
    )
