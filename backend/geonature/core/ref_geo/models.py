
from sqlalchemy import ForeignKey

from utils_flask_sqla.serializers import serializable

from geonature.utils.env import DB
from geonature.utils.config import config

from sqlalchemy.ext.hybrid import hybrid_property
