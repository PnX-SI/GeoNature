"""
    functions to insert update or delete data in table gn_synthese.synthese
"""
from sqlalchemy.exc import IntegrityError, ProgrammingError
from geonature.utils.env import DB
from geonature.utils.errors import GeonatureApiError


def import_from_table(schema_name, table_name, field_name, value, limit=50):
    """
    insert and/or update data in table gn_synthese.synthese
    from table <schema_name>.<table_name>
    for all rows satisfying the condition : <field_name> = <value>
    """
    try:

        # TODO get nb
        txt = """SELECT COUNT(*) FROM {}.{} WHERE {}::varchar = '{}'""".format(
            schema_name, table_name, field_name, value
        )

        nb_data = DB.engine.execute(txt).first()[0]

        # request : call of function gn_synthese.import_row_from_table
        i = 0

        # on procède ici par boucle pour traiter un nombre raisonnable de donnée à la fois
        while limit * i < nb_data:

            txt = """SELECT gn_synthese.import_row_from_table(
                    '{}',
                    '{}',
                    '{}.{}',
                    {},
                    {});""".format(
                field_name, value, schema_name, table_name, limit, i * limit  # offset
            )
            DB.engine.execution_options(autocommit=True).execute(txt)

            i = i + 1

            print("process synthese {} / {} ".format(min(i * limit, nb_data), nb_data))

    except (IntegrityError, ProgrammingError) as e:
        if e.orig.pgcode == "42703":
            raise ValueError("Undefined table : '{}.{}'".format(schema_name, table_name))
        elif e.orig.pgcode == "42P01":
            raise ValueError(
                "Undefined column {} in table '{}.{}'".format(field_name, schema_name, table_name)
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
            """.format(
                schema_name, table_name, field_name, value, e
            )
        )
