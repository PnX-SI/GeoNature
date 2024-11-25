"""declare module TAXHUB

Revision ID: ebbe0f7ed866
Revises: 9f4db1786c22
Create Date: 2023-08-02 13:15:38.542530

"""

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "ebbe0f7ed866"
down_revision = "9f4db1786c22"
branch_labels = None
depends_on = None

from geonature.utils.config import config


def upgrade():
    op.get_bind().execute(
        sa.text(
            """
            INSERT INTO gn_commons.t_modules
            (module_code, module_label, module_picto, module_desc, module_target, active_frontend, active_backend)
            VALUES('TAXHUB', 'TaxHub', 'fa-sitemap', 'Module TaxHub', '_blank', false, false);

            INSERT INTO gn_permissions.t_objects
            (code_object, description_object)
            VALUES
            ('TAXONS', 'Gestion des taxons dans TaxHub'),
            ('THEMES', 'Gestion des thèmes d''attributs dans TaxHub'),
            ('LISTES', 'Gestion des listes dans TaxHub'),
            ('ATTRIBUTS', 'Gestion des types d''attributs dans TaxHub')
            ;

            INSERT INTO gn_permissions.cor_object_module
            (id_object, id_module)
            SELECT _to.id_object, (SELECT id_module FROM gn_commons.t_modules WHERE module_code = 'TAXHUB')
            FROM (
                VALUES 
                    ('TAXONS'), 
                    ('THEMES'), 
                    ('LISTES'), 
                    ('ATTRIBUTS')
                ) AS o (object_code)
            JOIN gn_permissions.t_objects _to ON _to.code_object = o.object_code;
            


            INSERT INTO
                gn_permissions.t_permissions_available (
                    id_module,
                    id_object,
                    id_action,
                    scope_filter,
                    label
                )
            SELECT
                m.id_module,
                o.id_object,
                a.id_action,
                v.scope_filter,
                v.label
            FROM (
                    VALUES
                    ('TAXHUB', 'TAXONS', 'R', False, 'Voir les taxons')
                    ,('TAXHUB', 'TAXONS', 'U', False, 'Modifier les taxons (médias - listes - attributs)')
                    ,('TAXHUB', 'THEMES', 'C', False, 'Créer des thèmes')
                    ,('TAXHUB', 'THEMES', 'R', False, 'Voir les thèmes')
                    ,('TAXHUB', 'THEMES', 'U', False, 'Modifier les thèmes')
                    ,('TAXHUB', 'THEMES', 'D', False, 'Supprimer des thèmes')
                    ,('TAXHUB', 'LISTES', 'C', False, 'Creer des listes')
                    ,('TAXHUB', 'LISTES', 'R', False, 'Voir les listes')
                    ,('TAXHUB', 'LISTES', 'U', False, 'Modifier les listes')
                    ,('TAXHUB', 'LISTES', 'D', False, 'Supprimer des listes')
                    ,('TAXHUB', 'ATTRIBUTS', 'C', False, 'Créer des types d''attributs')
                    ,('TAXHUB', 'ATTRIBUTS', 'R', False, 'Voir les types d''attributs')
                    ,('TAXHUB', 'ATTRIBUTS', 'U', False, 'Modfier les types d''attributs')
                    ,('TAXHUB', 'ATTRIBUTS', 'D', False, 'Supprimer des types d''attributs')
                ) AS v (module_code, object_code, action_code, scope_filter, label)
            JOIN
                gn_commons.t_modules m ON m.module_code = v.module_code
            JOIN
                gn_permissions.t_objects o ON o.code_object = v.object_code
            JOIN
                gn_permissions.bib_actions a ON a.code_action = v.action_code
            WHERE m.module_code = 'TAXHUB'
        """
        )
    )
    # rapatriement des permissions de l'application TaxHub

    op.execute(
        """
        INSERT INTO gn_permissions.t_permissions
        (id_role, id_action, id_module, id_object)
        SELECT crap.id_role, t.id_action, t.id_module, t.id_object
        FROM 
            ( values ('TH', 'TAXHUB')) as v (code_appli, code_module)
        JOIN gn_commons.t_modules m ON m.module_code  = v.code_module 
        JOIN gn_permissions.t_permissions_available t on t.id_module = m.id_module 
        JOIN utilisateurs.t_applications app on app.code_application = v.code_appli
        JOIN utilisateurs.cor_role_app_profil crap on crap.id_application = app.id_application 
        WHERE m.module_code = 'TAXHUB' and app.code_application = 'TH' and crap.id_profil = 6;

        INSERT INTO gn_permissions.t_permissions
        (id_role, id_action, id_module, id_object)
        SELECT crap.id_role, t.id_action, t.id_module, t.id_object
        FROM 
            ( values ('TH', 'TAXHUB')) as v (code_appli, code_module)
        JOIN gn_commons.t_modules m ON m.module_code  = v.code_module 
        JOIN gn_permissions.t_permissions_available t on t.id_module = m.id_module 
        JOIN gn_permissions.t_objects obj on t.id_object = obj.id_object 
        JOIN utilisateurs.t_applications app on app.code_application = v.code_appli
        JOIN utilisateurs.cor_role_app_profil crap on crap.id_application = app.id_application 
        WHERE 
            m.module_code = 'TAXHUB'
            AND  app.code_application = 'TH'
            AND crap.id_profil in (1,2,3,4,5) 
            AND obj.code_object = 'TAXON';
        """
    )

    op.execute(
        """
        DELETE FROM utilisateurs.cor_role_app_profil  where id_application = (select id_application from utilisateurs.t_applications  t where t.code_application = 'TH' );
        DELETE FROM utilisateurs.cor_profil_for_app  where id_application = (select id_application from utilisateurs.t_applications  t where t.code_application = 'TH' );
        DELETE FROM utilisateurs.t_applications where code_application = 'TH';
        """
    )


def downgrade():
    op.execute(
        """
        DELETE FROM gn_permissions.t_permissions  WHERE id_module  = (SELECT id_module FROM gn_commons.t_modules WHERE module_code = 'TAXHUB');
        DELETE FROM gn_permissions.t_permissions_available WHERE id_module = (SELECT id_module FROM gn_commons.t_modules WHERE module_code = 'TAXHUB');
        DELETE FROM gn_commons.t_modules where module_code = 'TAXHUB';
        DELETE FROM gn_permissions.t_objects where code_object in ('TAXON', 'ATTRIBUT', 'THEME', 'LISTE');
        """
    )
