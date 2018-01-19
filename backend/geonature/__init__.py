'''
    Configuration du logger racine
'''
import logging
from logging.handlers import RotatingFileHandler

root_logger = logging.getLogger()
root_logger.setLevel(logging.INFO)

# Handler Stream
root_logger.addHandler(logging.StreamHandler())
