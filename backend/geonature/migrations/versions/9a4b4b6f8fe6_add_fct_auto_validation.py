"""add_fct_auto_validation

Revision ID: 9a4b4b6f8fe6
Revises: 446e902a14e7
Create Date: 2023-10-25 17:18:04.438706

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "9a4b4b6f8fe6"
down_revision = "446e902a14e7"
branch_labels = None
depends_on = None

schema = "gn_profiles"
fct_name = "fct_auto_validation"


def upgrade():
    op.execute(
        f"""
create or replace function {schema}.{fct_name} (
        new_validation_status varchar default 'Probable',
        score int default 3
    ) returns integer [] language plpgsql as $function$
declare old_validation_status text := 'En attente de validation';
new_id_status_validation int := (
    select tn.id_nomenclature
    from ref_nomenclatures.t_nomenclatures tn
    where tn.mnemonique = new_validation_status
);
old_id_status_validation int := (
    select tn.id_nomenclature
    from ref_nomenclatures.t_nomenclatures tn
    where tn.mnemonique = old_validation_status
);
list_uuid_obs_status_updatable uuid [] := (
    select array_agg(vlv.uuid_attached_row)
    from gn_commons.v_latest_validation vlv
        join gn_profiles.v_consistancy_data vcd on vlv.uuid_attached_row = vcd.id_sinp
        and (
            (
                vcd.valid_phenology::int + vcd.valid_altitude::int + vcd.valid_distribution::int
            ) = score
        )
    where vlv.id_nomenclature_valid_status = old_id_status_validation
        and validation_auto = true
        and id_validator is null
);
list_uuid_validation_to_update uuid [] := array (
    select t.uuid_attached_row
    from (
            select distinct on (uuid_attached_row) uuid_attached_row,
                id_validation,
                validation_date
            from gn_commons.t_validations tv
            where uuid_attached_row = any (list_uuid_obs_status_updatable)
            order by uuid_attached_row,
                validation_date desc
        ) as t
);
list_id_sythese_updated int [] := array (
    select s.id_synthese
    from gn_synthese.synthese s
    where s.unique_id_sinp = any (list_uuid_validation_to_update)
);
_schema_name text = 'gn_commons';
_table_name text = 't_validations';
indx int;
begin if array_length(list_uuid_validation_to_update, 1) > 0 then for indx in 1..array_length(list_uuid_validation_to_update, 1) loop raise notice 'Mise à jour du status  % --> %,  pour l''uuid_attached_row : % dans la table %.% ( id_synthese = % )',
old_validation_status,
new_validation_status,
list_uuid_validation_to_update [indx],
_schema_name,
_table_name,
list_id_sythese_updated [indx];
execute format(
    '
    INSERT INTO %I.%I (uuid_attached_row, id_nomenclature_valid_status, validation_auto, id_validator, validation_comment, validation_date)
    VALUES  ($1, $2 ,false, null,''auto = default value'',CURRENT_TIMESTAMP)',
    _schema_name,
    _table_name
) using list_uuid_validation_to_update [indx],
new_id_status_validation;
end loop;
end if;
return list_id_sythese_updated;
end;
$function$;
    """
    )


def downgrade():
    op.execute(
        f"""
            DROP FUNCTION {schema}.{fct_name}
        """
    )
