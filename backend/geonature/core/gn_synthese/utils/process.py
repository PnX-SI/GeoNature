'''
    functions to insert update or delete data in table gn_synthese.synthese
'''
from sqlalchemy.exc import IntegrityError, ProgrammingError
from geonature.utils.env import DB
from geonature.utils.errors import GeonatureApiError

def import_from_table(schema_name, table_name, field_name, value):
    '''
        insert and/or update data in table gn_synthese.synthese
        from table <schema_name>.<table_name>
        for all rows satisfying the condition : <field_name> = <value>
    '''
    try:
        # request : call of function gn_synthese.import_row_from_table
        txt = (
                '''SELECT gn_synthese.import_row_from_table(
                    '{}',
                    '{}',
                    '{}.{}');'''
                .format(
                    field_name,
                    value,
                    schema_name,
                    table_name
                )
        )

        DB.engine.execution_options(autocommit=True).execute(txt)

    except (IntegrityError, ProgrammingError) as e:
        if e.orig.pgcode == "42703":
            raise ValueError(
                "Undefined table : '{}.{}'".format(
                    schema_name,
                    table_name
                )
            )
        elif e.orig.pgcode == "42P01":
            raise ValueError(
                "Undefined column {} in table '{}.{}'".format(
                    field_name,
                    schema_name,
                    table_name
                )
            )
        else:
            raise e
    except Exception as e:
        raise GeonatureApiError(
            """ Error while executing import_from_table with parameters :
                schema_name : {}
                table_name : {}
                field_name : {}
                value : {}.
                {}
            """
            .format(
                schema_name,
                table_name,
                field_name,
                value,
                e
            )
        )
