"""
    Configuration du logger racine
"""
import logging
from logging.handlers import RotatingFileHandler
from geonature.utils.env import load_config, DEFAULT_CONFIG_FILE

conf = load_config(DEFAULT_CONFIG_FILE)

root_logger = logging.getLogger()
root_logger.addHandler(logging.StreamHandler())

