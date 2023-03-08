"""fix permissions view

Revision ID: 5d65f9c93a32
Revises: 0cae32a010ea
Create Date: 2023-02-20 17:49:03.156681

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "5d65f9c93a32"
down_revision = "0cae32a010ea"
branch_labels = None
depends_on = None


def upgrade():
    op.execute(
        """
        CREATE OR REPLACE VIEW gn_permissions.v_roles_permissions
        AS WITH direct_permissions AS (
                 -- User and group direct permissions
                 SELECT u.id_role,
                    u.nom_role,
                    u.prenom_role,
                    u.groupe,
                    u.id_organisme,
                    c_1.id_action,
                    c_1.id_filter,
                    c_1.id_module,
                    c_1.id_object,
                    c_1.id_permission
                   FROM utilisateurs.t_roles u
                     JOIN gn_permissions.cor_role_action_filter_module_object c_1 ON c_1.id_role = u.id_role
                ), inherited_permissions AS (
                 -- User permissions inherited from group
                 SELECT u.id_role,
                    u.nom_role,
                    u.prenom_role,
                    u.groupe,
                    u.id_organisme,
                    c_1.id_action,
                    c_1.id_filter,
                    c_1.id_module,
                    c_1.id_object,
                    c_1.id_permission
                   FROM utilisateurs.t_roles u
                     JOIN utilisateurs.cor_roles ug ON ug.id_role_utilisateur = u.id_role
                     JOIN gn_permissions.cor_role_action_filter_module_object c_1 ON c_1.id_role = ug.id_role_groupe
                ), all_permissions AS (
                 SELECT id_role,
                    nom_role,
                    prenom_role,
                    groupe,
                    id_organisme,
                    id_action,
                    id_filter,
                    id_module,
                    id_object,
                    id_permission
                   FROM direct_permissions
                UNION
                 SELECT id_role,
                    nom_role,
                    prenom_role,
                    groupe,
                    id_organisme,
                    id_action,
                    id_filter,
                    id_module,
                    id_object,
                    id_permission
                   FROM inherited_permissions
                )
         SELECT v.id_role,
            v.nom_role,
            v.prenom_role,
            v.id_organisme,
            v.id_module,
            modules.module_code,
            obj.code_object,
            v.id_action,
            v.id_filter,
            actions.code_action,
            actions.description_action,
            filters.value_filter,
            filters.label_filter,
            filter_type.code_filter_type,
            filter_type.id_filter_type,
            v.id_permission
           FROM all_permissions v
             JOIN gn_permissions.t_actions actions ON actions.id_action = v.id_action
             JOIN gn_permissions.t_filters filters ON filters.id_filter = v.id_filter
             JOIN gn_permissions.t_objects obj ON obj.id_object = v.id_object
             JOIN gn_permissions.bib_filters_type filter_type ON filters.id_filter_type = filter_type.id_filter_type
             JOIN gn_commons.t_modules modules ON modules.id_module = v.id_module;
        """
    )


def downgrade():
    op.execute(
        """
        CREATE OR REPLACE VIEW gn_permissions.v_roles_permissions
        AS WITH p_user_permission AS (
                 SELECT u.id_role,
                    u.nom_role,
                    u.prenom_role,
                    u.groupe,
                    u.id_organisme,
                    c_1.id_action,
                    c_1.id_filter,
                    c_1.id_module,
                    c_1.id_object,
                    c_1.id_permission
                   FROM utilisateurs.t_roles u
                     JOIN gn_permissions.cor_role_action_filter_module_object c_1 ON c_1.id_role = u.id_role
                  WHERE u.groupe = false
                ), p_groupe_permission AS (
                 SELECT u.id_role,
                    u.nom_role,
                    u.prenom_role,
                    u.groupe,
                    u.id_organisme,
                    c_1.id_action,
                    c_1.id_filter,
                    c_1.id_module,
                    c_1.id_object,
                    c_1.id_permission
                   FROM utilisateurs.t_roles u
                     JOIN utilisateurs.cor_roles g ON g.id_role_utilisateur = u.id_role OR g.id_role_groupe = u.id_role
                     JOIN gn_permissions.cor_role_action_filter_module_object c_1 ON c_1.id_role = g.id_role_groupe
                ), all_user_permission AS (
                 SELECT p_user_permission.id_role,
                    p_user_permission.nom_role,
                    p_user_permission.prenom_role,
                    p_user_permission.groupe,
                    p_user_permission.id_organisme,
                    p_user_permission.id_action,
                    p_user_permission.id_filter,
                    p_user_permission.id_module,
                    p_user_permission.id_object,
                    p_user_permission.id_permission
                   FROM p_user_permission
                UNION
                 SELECT p_groupe_permission.id_role,
                    p_groupe_permission.nom_role,
                    p_groupe_permission.prenom_role,
                    p_groupe_permission.groupe,
                    p_groupe_permission.id_organisme,
                    p_groupe_permission.id_action,
                    p_groupe_permission.id_filter,
                    p_groupe_permission.id_module,
                    p_groupe_permission.id_object,
                    p_groupe_permission.id_permission
                   FROM p_groupe_permission
                )
         SELECT v.id_role,
            v.nom_role,
            v.prenom_role,
            v.id_organisme,
            v.id_module,
            modules.module_code,
            obj.code_object,
            v.id_action,
            v.id_filter,
            actions.code_action,
            actions.description_action,
            filters.value_filter,
            filters.label_filter,
            filter_type.code_filter_type,
            filter_type.id_filter_type,
            v.id_permission
           FROM all_user_permission v
             JOIN gn_permissions.t_actions actions ON actions.id_action = v.id_action
             JOIN gn_permissions.t_filters filters ON filters.id_filter = v.id_filter
             JOIN gn_permissions.t_objects obj ON obj.id_object = v.id_object
             JOIN gn_permissions.bib_filters_type filter_type ON filters.id_filter_type = filter_type.id_filter_type
             JOIN gn_commons.t_modules modules ON modules.id_module = v.id_module;
        """
    )
