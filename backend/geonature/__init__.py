"""
    Configuration du logger racine
"""
import logging
from geonature.utils.config import config

root_logger = logging.getLogger()
root_logger.addHandler(logging.StreamHandler())
root_logger.setLevel(config["SERVER"]["LOG_LEVEL"])


from .app import create_app
