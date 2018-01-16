import pytest
from pathlib import Path
import sys

# BASE_DIR = Path(__file__).parent.parent
# sys.path.append(str(BASE_DIR))
import server



@pytest.fixture
def geonature_app():
    """ set the application context """
    app = server.get_app()
    ctx = app.app_context()
    ctx.push()
    yield app
    ctx.pop()
