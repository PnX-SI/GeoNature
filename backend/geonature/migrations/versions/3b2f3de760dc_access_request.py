"""access request

Revision ID: 3b2f3de760dc
Revises: ca052245c6ec
Create Date: 2021-10-07 12:39:39.834674

"""
import importlib

from alembic import op, context
import sqlalchemy as sa
from sqlalchemy.sql import text


# revision identifiers, used by Alembic.
revision = "3b2f3de760dc"
down_revision = "ca052245c6ec"
branch_labels = None
depends_on = ("10e87bc144cd",)  # utilisateurs.get_id_role_by_name()


def upgrade():
    bindparams = {
        "admin_role": context.get_x_argument(as_dictionary=True).get("admin-role", "Grp_admin"),
    }
    package = "geonature.migrations.data.migrations"
    resource = "access_request.sql"
    op.get_bind().execute(text(importlib.resources.read_text(package, resource)), bindparams)


def downgrade():
    op.execute(
        """
    CREATE TABLE gn_permissions.cor_filter_type_module (
        id_filter_type int4 NOT NULL,
        id_module int4 NOT NULL,
        CONSTRAINT pk_cor_filter_module PRIMARY KEY (id_filter_type, id_module),
        CONSTRAINT fk_cor_filter_module_id_filter FOREIGN KEY (id_filter_type) REFERENCES gn_permissions.bib_filters_type(id_filter_type) ON UPDATE CASCADE,
        CONSTRAINT fk_cor_filter_module_id_module FOREIGN KEY (id_module) REFERENCES gn_commons.t_modules(id_module) ON UPDATE CASCADE
    )
    """
    )
    # FIXME Necessary? Does this table was used?
    op.execute(
        """
    INSERT INTO gn_permissions.cor_filter_type_module
        (id_filter_type, id_module)
    SELECT DISTINCT id_filter_type, id_module
        FROM gn_permissions.cor_module_action_object_filter
        ORDER BY id_filter_type, id_module;
    """
    )
    op.execute(
        """
    CREATE TABLE gn_permissions.cor_object_module (
        id_cor_object_module serial NOT NULL,
        id_object int4 NOT NULL,
        id_module int4 NOT NULL,
        CONSTRAINT pk_cor_object_module PRIMARY KEY (id_cor_object_module),
        CONSTRAINT unique_cor_object_module UNIQUE (id_object, id_module),
        CONSTRAINT fk_cor_object_module_id_module FOREIGN KEY (id_module) REFERENCES gn_commons.t_modules(id_module) ON UPDATE CASCADE ON DELETE CASCADE,
        CONSTRAINT fk_cor_object_module_id_object FOREIGN KEY (id_object) REFERENCES gn_permissions.t_objects(id_object) ON UPDATE CASCADE ON DELETE CASCADE
    )
    """
    )
    op.execute(
        """
    INSERT INTO gn_permissions.cor_object_module
        (id_object, id_module)
    SELECT DISTINCT c.id_object, c.id_module
        FROM gn_permissions.cor_module_action_object_filter c
        JOIN gn_permissions.t_objects o
        ON o.id_object = c.id_object
        WHERE o.code_object != 'ALL'
        ORDER BY id_object, id_module;
    """
    )
    op.execute(
        """
    CREATE TABLE gn_permissions.t_filters (
        id_filter serial NOT NULL,
        label_filter varchar(255) NOT NULL,
        value_filter text NOT NULL,
        description_filter text NULL,
        id_filter_type int4 NOT NULL,
        CONSTRAINT pk_t_filters PRIMARY KEY (id_filter),
        CONSTRAINT fk_t_filters_id_filter_type FOREIGN KEY (id_filter_type) REFERENCES gn_permissions.bib_filters_type(id_filter_type) ON UPDATE CASCADE
    )
    """
    )
    # FIXME: get these values from new tables????
    op.execute(
        """
    INSERT INTO gn_permissions.t_filters (label_filter, value_filter, description_filter, id_filter_type)
    VALUES
        ('Aucune donnée', '0', 'Aucune donnée',
            (SELECT id_filter_type FROM gn_permissions.bib_filters_type WHERE code_filter_type='SCOPE')),
        ('Mes données', '1', 'Mes données',
            (SELECT id_filter_type FROM gn_permissions.bib_filters_type WHERE code_filter_type='SCOPE')),
        ('Les données de mon organisme', '2', 'Les données de mon organisme',
            (SELECT id_filter_type FROM gn_permissions.bib_filters_type WHERE code_filter_type='SCOPE')),
        ('Toutes les données', '3', 'Toutes les données',
            (SELECT id_filter_type FROM gn_permissions.bib_filters_type WHERE code_filter_type='SCOPE')),
        ('Les bouquetins', '61098', 'Filtre taxonomique sur les bouquetins',
            (SELECT id_filter_type FROM gn_permissions.bib_filters_type WHERE code_filter_type='TAXONOMIC')),
        ('Les oiseaux', '185961', 'Filtre taxonomique sur les oiseaux - classe Aves',
            (SELECT id_filter_type FROM gn_permissions.bib_filters_type WHERE code_filter_type='TAXONOMIC')),
        ('Données dégradées', 'DONNEES_DEGRADEES', 'Filtre pour afficher les données sensibles dégradées/floutées à l''utilisateur',
            (SELECT id_filter_type FROM gn_permissions.bib_filters_type WHERE code_filter_type='PRECISION')),
        ('Données précises', 'DONNEES_PRECISES', 'Filtre qui affiche les données sensibles  précises à l''utilisateur',
            (SELECT id_filter_type FROM gn_permissions.bib_filters_type WHERE code_filter_type='PRECISION'))
    """
    )
    op.execute("DROP VIEW gn_permissions.v_roles_permissions")
    op.execute("DROP INDEX gn_permissions.unique_t_objects_code")
    op.execute("DROP INDEX gn_permissions.unique_t_actions_code")
    op.execute("DROP INDEX gn_permissions.unique_cor_m_a_o_f_code")
    op.execute("DROP INDEX gn_permissions.unique_cor_m_a_o_f_ids")
    op.execute("DROP INDEX gn_permissions.unique_bib_filters_values")
    op.execute("DROP INDEX gn_permissions.unique_bib_filters_type_code")
    op.execute(
        """
    ALTER TABLE gn_permissions.cor_module_action_object_filter
        DROP CONSTRAINT fk_cor_module_action_object_filter_id_filter_type
    """
    )
    op.execute(
        """
    ALTER TABLE gn_permissions.cor_module_action_object_filter
        DROP CONSTRAINT fk_cor_module_action_object_filter_id_object
    """
    )
    op.execute(
        """
    ALTER TABLE gn_permissions.cor_module_action_object_filter
        DROP CONSTRAINT fk_cor_module_action_object_filter_id_action
    """
    )
    op.execute(
        """
    ALTER TABLE gn_permissions.cor_module_action_object_filter
        DROP CONSTRAINT fk_cor_module_action_object_filter_id_module
    """
    )
    op.execute("DROP TABLE gn_permissions.cor_module_action_object_filter")
    op.execute(
        """
    DELETE FROM gn_permissions.cor_role_action_filter_module_object
        WHERE id_object = gn_permissions.get_id_object('ACCESS_REQUESTS')
    """
    )
    op.execute(
        """
    CREATE FUNCTION gn_permissions.fct_tri_does_user_have_already_scope_filter()
     RETURNS trigger
     LANGUAGE plpgsql
    AS $function$
    -- Check if a role has already a SCOPE permission for an action/module/object
    -- use in constraint to force not set multiple scope permission on the same action/module/object
    DECLARE
    the_code_filter_type character varying;
    the_nb_permission integer;
    BEGIN
     SELECT INTO the_code_filter_type bib.code_filter_type
     FROM gn_permissions.t_filters f
     JOIN gn_permissions.bib_filters_type bib ON bib.id_filter_type = f.id_filter_type
     WHERE f.id_filter = NEW.id_filter
    ;
    -- if the filter type is NOT SCOPE, its OK to set multiple permissions
    IF the_code_filter_type != 'SCOPE' THEN
    RETURN NEW;
    -- if the new filter is 'SCOPE TYPE', check if there is not already a permission for this
    -- action/module/object/role
    ELSE
        SELECT INTO the_nb_permission count(perm.id_permission)
        FROM gn_permissions.cor_role_action_filter_module_object perm
        JOIN gn_permissions.t_filters f ON f.id_filter = perm.id_filter
        JOIN gn_permissions.bib_filters_type bib ON bib.id_filter_type = f.id_filter_type AND bib.code_filter_type = 'SCOPE'
        WHERE id_role=NEW.id_role AND id_action=NEW.id_action AND id_module=NEW.id_module AND id_object=NEW.id_object;

     -- if its an insert 0 row must be present, if its an update 1 row must be present
      IF(TG_OP = 'INSERT' AND the_nb_permission = 0) OR (TG_OP = 'UPDATE' AND the_nb_permission <= 1) THEN
            RETURN NEW;
        END IF;
        BEGIN
            RAISE EXCEPTION 'ATTENTION: il existe déjà un enregistrement de type SCOPE pour le role % l''action % sur le module % et l''objet % . Il est interdit de définir plusieurs portées à un role pour le même action sur un module et un objet', NEW.id_role, NEW.id_action, NEW.id_module, NEW.id_object ;
        END;


    END IF;

    END;

    $function$
    ;
    """
    )
    op.execute(
        """
    CREATE TRIGGER tri_check_no_multiple_scope_perm BEFORE
    INSERT
        OR
    UPDATE
        ON
        gn_permissions.cor_role_action_filter_module_object FOR EACH ROW EXECUTE PROCEDURE gn_permissions.fct_tri_does_user_have_already_scope_filter()
    """
    )
    op.execute(
        """
    DROP TRIGGER tri_check_no_multiple_filter_type
        ON gn_permissions.cor_role_action_filter_module_object
    """
    )
    op.execute("DROP FUNCTION gn_permissions.fct_tri_only_one_filter_type_by_permission")
    op.execute(
        """
    ALTER TABLE gn_permissions.cor_role_action_filter_module_object
        ADD COLUMN id_filter integer
    """
    )
    op.execute(
        """
    ALTER TABLE ONLY gn_permissions.cor_role_action_filter_module_object
        ADD CONSTRAINT  fk_cor_r_a_f_m_o_id_filter
        FOREIGN KEY (id_filter) REFERENCES gn_permissions.t_filters (id_filter) ON UPDATE CASCADE
    """
    )
    op.execute(
        """
    UPDATE gn_permissions.cor_role_action_filter_module_object AS c
        SET id_filter = f.id_filter
        FROM gn_permissions.t_filters AS f
        WHERE c.id_filter_type = f.id_filter_type
        AND c.value_filter = f.value_filter
    """
    )
    op.execute(
        """
    ALTER TABLE gn_permissions.cor_role_action_filter_module_object
        ALTER COLUMN id_filter SET NOT NULL
    """
    )
    op.execute(
        """
    ALTER TABLE gn_permissions.cor_role_action_filter_module_object
        DROP CONSTRAINT fk_cor_r_a_f_m_o_id_request
    """
    )
    op.execute(
        """
    ALTER TABLE gn_permissions.cor_role_action_filter_module_object
        DROP CONSTRAINT fk_cor_r_a_f_m_o_id_filter_type
    """
    )
    op.execute(
        """
    ALTER TABLE gn_permissions.cor_role_action_filter_module_object
        DROP COLUMN gathering,
        DROP COLUMN end_date,
        DROP COLUMN id_filter_type,
        DROP COLUMN value_filter,
        DROP COLUMN id_request
    """
    )
    ###### Create trigger tri_check_no_multiple_filter_type???? FIXME
    op.execute(
        """
    CREATE VIEW gn_permissions.v_roles_permissions
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
    for old_code_type, new_code_type, label, description in [
        (
            "SCOPE",
            "SCOPE",
            "Permissions de type Portée",
            "Filtre de type Portée",
        ),
        (
            "PRECISION",
            "SENSITIVITY",
            "Permissions de type Sensibilité",
            "Permission de type Sensibilité",
        ),
        (
            "GEOGRAPHIC",
            "GEOGRAPHIC",
            "Permissions de type Géographique",
            "Ajouter des id_area séparés par des virgules",
        ),
        (
            "TAXONOMIC",
            "TAXONOMIC",
            "Permissions de type Taxonomique",
            "Ajouter des cd_nom séparés par des virgules",
        ),
    ]:
        stmt = sa.text(
            """
        UPDATE gn_permissions.bib_filters_type
        SET
            code_filter_type = :new_code_type,
            label_filter_type = :label,
            description_filter_type = :description
        WHERE code_filter_type = :old_code_type ;
        """
        )
        bindparams = {
            "old_code_type": old_code_type,
            "new_code_type": new_code_type,
            "label": label,
            "description": description,
        }
        op.get_bind().execute(stmt, bindparams)
    op.execute(
        """
    DELETE FROM gn_permissions.t_objects
        WHERE code_object in ('ACCESS_REQUESTS', 'PRIVATE_OBSERVATION', 'SENSITIVE_OBSERVATION')
    """
    )
    op.execute(
        """
    DROP TRIGGER tri_modify_meta_update_date_t_requests
        ON gn_permissions.t_requests
    """
    )
    op.execute("DROP FUNCTION gn_permissions.tri_func_modify_meta_update_date")
    op.execute(
        """
    ALTER TABLE gn_permissions.t_requests
        DROP CONSTRAINT fk_t_requests_processed_by
    """
    )
    op.execute(
        """
    ALTER TABLE gn_permissions.t_requests
        DROP CONSTRAINT fk_t_requests_id_role
    """
    )
    op.execute("DROP TABLE gn_permissions.t_requests")
    op.execute("DROP TYPE gn_permissions.request_states")
    op.execute("DROP SEQUENCE gn_permissions.t_requests_id_request_seq")
    # truncate gn_permissions.bib_filters_values
    op.execute(
        """
    ALTER TABLE gn_permissions.bib_filters_values
        DROP CONSTRAINT fk_bib_filters_values_id_filter_type
    """
    )
    op.execute("DROP TABLE gn_permissions.bib_filters_values")
    op.execute("DROP TYPE gn_permissions.filter_value_formats")
    op.execute("DROP SEQUENCE gn_permissions.bib_filters_values_id_filter_value_seq")
    op.execute(
        """
    ALTER TABLE gn_permissions.cor_role_action_filter_module_object
        DROP CONSTRAINT fk_cor_r_a_f_m_o_id_module
    """
    )
    op.execute("DROP FUNCTION gn_permissions.get_id_filter_type")
    op.execute("DROP FUNCTION gn_permissions.get_id_action")
