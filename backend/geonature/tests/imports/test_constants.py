from unittest.mock import Mock
from geonature.core.imports.utils import preprocess_value
import pytest
from sqlalchemy.dialects.postgresql import ARRAY, JSONB
from sqlalchemy import JSON, Integer, String
import pandas as pd


@pytest.fixture(params=[ARRAY(Integer), JSONB(), JSON(), Integer(), String()])
def mock_column_type(request):
    return request.param


@pytest.fixture
def mock_import_with_column_type(mock_column_type):
    mock_column = Mock()
    mock_column.type = mock_column_type

    mock_transient_table = Mock()
    mock_transient_table.c = {"dest_column": mock_column}

    mock_import = Mock()
    mock_import.destination.get_transient_table.return_value = mock_transient_table

    return mock_import, mock_column_type


def test_preprocess_value_all_types(mock_import_with_column_type):
    mock_import, column_type = mock_import_with_column_type

    # Préparer les données
    dataframe = pd.DataFrame({"col": [1, 2, 3]})
    field = Mock(
        multi=False, type_field="observers", dest_column="dest_column", dest_field="dest_field"
    )

    constant_value = [{"id_role": 1, "nom_complet": "Test"}]

    # Appeler
    col_name, col_value = preprocess_value(mock_import, dataframe, field, None, constant_value)

    # Vérifications selon le type
    if isinstance(column_type, ARRAY):
        assert col_value.iloc[0] == [1]
    elif isinstance(column_type, (JSONB, JSON)):
        assert col_value.iloc[0] == {"id_role": 1, "nom_complet": "Test"}
    elif isinstance(column_type, Integer):
        assert col_value.iloc[0] == 1
    else:
        assert col_value.iloc[0] == "Test"
