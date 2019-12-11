from sqlalchemy import literal, or_
from sqlalchemy.sql import exists

from geonature.core.gn_meta.models import TDatasets
from geonature.utils.env import DB
from geonature.utils.errors import GeonatureApiError

from .models import CorStationObserverOccHab


def filter_query_with_cruved(
    model,
    q,
    user,
    id_station_col="id_station",
    id_dataset_column="id_dataset",
    observers_column="observers_txt",
    id_digitiser_column="id_digitiser",
    filter_on_obs_txt=True,
    with_generic_table=False,
):
    """
    Filter the query with the cruved authorization of a user

    Returns:
        - A SQLA Query object
    """
    # if with geniric table , the column are located in model.columns, else in model
    if with_generic_table:
        model_temp = model.columns
    else:
        model_temp = model
    # get the mandatory column
    try:
        model_id_station_col = getattr(model_temp, id_station_col)
        model_id_dataset_column = getattr(model_temp, id_dataset_column)
        model_observers_column = getattr(model_temp, observers_column)
        model_id_digitiser_column = getattr(model_temp, id_digitiser_column)
    except AttributeError as e:
        raise GeonatureApiError(
            """the {model} table     does not have a column {e}
             If you change the {model} table, please edit your synthese config (cf EXPORT_***_COL)
            """.format(
                e=e, model=model
            )
        )

    if user.value_filter in ("1", "2"):

        sub_query_id_role = DB.session.query(CorStationObserverOccHab).filter(
            CorStationObserverOccHab.id_role == user.id_role).exists()
        ors_filters = [
            sub_query_id_role,
            model_id_digitiser_column == user.id_role,
        ]
        q = q.filter(or_(*ors_filters))
        if filter_on_obs_txt:
            user_fullname1 = user.nom_role + " " + user.prenom_role + "%"
            user_fullname2 = user.prenom_role + " " + user.nom_role + "%"
            ors_filters.append(model_observers_column.ilike(user_fullname1))
            ors_filters.append(model_observers_column.ilike(user_fullname2))
        if user.value_filter == "1":
            q = q.filter(or_(*ors_filters))
        elif user.value_filter == "2":
            allowed_datasets = TDatasets.get_user_datasets(
                user, only_query=True).exists()
            ors_filters.append(allowed_datasets)
            q = q.filter(or_(*ors_filters))
    return q
