"""
    Configuration du logger racine
"""
import logging
from logging.handlers import RotatingFileHandler
from geonature.utils.env import load_config, DEFAULT_CONFIG_FILE

conf = load_config(DEFAULT_CONFIG_FILE)

root_logger = logging.getLogger()
root_logger.setLevel(conf["API_LOG_LEVEL"])
root_logger.addHandler(logging.StreamHandler())

# INIT all logger with the level pass in config
for name in logging.root.manager.loggerDict:
    cur_logger = logging.getLogger(name)
    cur_logger.setLevel(conf["API_LOG_LEVEL"])
    # print(cur_logger)

# Handler Stream

