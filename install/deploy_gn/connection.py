from fabric import Connection

from config import *


def connect():
    con = Connection(host=HOST)
    return con
