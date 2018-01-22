"""
    Give a unique entry point for gunicorn
"""

from geonature.utils.env import load_config, get_config_file_path
from server import get_app

# get the app config file
config_path = get_config_file_path()
config = load_config(config_path)

#give the app context from server.py in a app object
app = get_app(config)
