'''
    functions to insert update or delete data in table gn_synthese.synthese
'''

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
