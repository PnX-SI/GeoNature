"""add_fct_auto_validation

Revision ID: 9a4b4b6f8fe6
Revises: 446e902a14e7
Create Date: 2023-10-25 17:18:04.438706

"""

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "9a4b4b6f8fe6"
down_revision = "df93a68242ee"
branch_labels = None
depends_on = ("f06cc80cc8ba",)  # gn_commons

schema = "gn_profiles"
fct_name = "fct_auto_validation"


def upgrade():
    op.execute(
        sa.text(
            f"""
create or replace function gn_profiles.fct_auto_validation (
        new_validation_status int default 2,
        score int default 3
    ) returns int language plpgsql as $function$
declare old_validation_status int := 0;

validation_id_type int := ref_nomenclatures.get_id_nomenclature_type('STATUT_VALID');

-- Retrieve the new validation status's nomenclature id
new_id_status_validation int := (
    select tn.id_nomenclature
    from ref_nomenclatures.t_nomenclatures tn
    where tn.cd_nomenclature = new_validation_status::varchar
    and id_type = validation_id_type
);

-- Retrieve the old validation status nomenclature id
old_id_status_validation int := (
    select tn.id_nomenclature
    from ref_nomenclatures.t_nomenclatures tn
    where tn.cd_nomenclature = old_validation_status::varchar
    and id_type = validation_id_type
);

-- Retrieve the list of observations tagged with the old validation status
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
        and id_validator is null
);
  
number_of_obs_to_update int := array_length(list_uuid_obs_status_updatable, 1);
begin if  number_of_obs_to_update > 0 then 
	raise notice '% observations seront validées automatiquement',number_of_obs_to_update;
-- Update Validation status 
	insert into gn_commons.t_validations (uuid_attached_row, id_nomenclature_valid_status, validation_auto, id_validator, validation_comment, validation_date) 
		select t_uuid.uuid_attached_row, new_id_status_validation ,true, null,'auto = default value',CURRENT_TIMESTAMP
		from 
		(select distinct on (uuid_attached_row) uuid_attached_row
	            from gn_commons.t_validations tv
	            where uuid_attached_row = any (list_uuid_obs_status_updatable)
	     )  t_uuid;
else
raise notice 'Aucune entrée dans les dernières observations n''est candidate à la validation automatique';
end if;
return 0;
end;
$function$;
    """
        )
    )


def downgrade():
    op.execute(
        sa.text(
            f"""
            DROP FUNCTION {schema}.{fct_name}
        """
        )
    )
