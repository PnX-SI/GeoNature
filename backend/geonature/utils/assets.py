import os
import time
import subprocess
import datetime
from geonature.utils.env import (
    ROOT_DIR,
)

def extra_files():
    res=[]
    for root, dir_ ,files in os.walk(ROOT_DIR / 'config'):
        for f in filter(lambda f: f.endswith('.toml'), files):
            res.append(root + '/' + f)
    return res
