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
        for f in files:
            res.append(root + '/' + f)
    return res

def directory_last_modif(dir_path):
    res=[0]
    for root, dir_ ,files in os.walk(dir_path):
        for f in files:
            res.append(os.path.getmtime(root + '/' + f))
    return max(res)

def directories_last_modif(dir_paths):
    return max([ directory_last_modif(dir_path) for dir_path in dir_paths])


def process_manage_frontend_assets(app):
    '''
        install/assets.sh
    '''

    start_time = datetime.datetime.now()
    with app.app_context() :
        subprocess.call(['./assets.sh'], cwd=str(ROOT_DIR / 'install'))
    
    end_time = datetime.datetime.now()
    time_diff = (end_time - start_time)
    execution_time = time_diff.total_seconds() * 1000
    print(execution_time)
