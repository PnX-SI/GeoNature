import os
import time
import shutil
from geonature.utils.config import config_frontend, config
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


def process_manage_frontend_assets():
    '''
        Ici on cherche à rendre le build du frontend 'indépendant' de la config
        Pour cela on crée directement des fichiers dans les assets du frontend, 
        dans les repertoires 'frontend/dist' et 'frontend/src'
        Les fichiers concernés:
            - pour fournir API_ENDPOINT au frontend :
                - config/api.config.json
                - custom ??
    '''

    path_test = ROOT_DIR / 'frontend/assets_test.txt'

    t_test = os.path.exists(path_test) and os.path.getmtime(path_test) or 0

    # test sur le fichier pour faire en sorte qu'un seul worker n'execute cet action
    if (
        (os.path.exists(path_test)) 
        and 
        # si le fichier a été modifié depuis moins de  5 seconde
        (int(time.time()) - t_test) < 5
    ): 
        return

    # touch
    with open(path_test, "w+") as outputfile:
        outputfile.write('')

    config_dir = str(ROOT_DIR / "config/")

    src_assets_dir = str(ROOT_DIR / "frontend/src/assets")
    src_custom_dir = config_dir + "/" + "custom"
    src_assets_config_dir = src_assets_dir + "/config"

    dist_assets_dir = str(ROOT_DIR / "frontend/dist/assets")
    dist_assets_config_dir = dist_assets_dir + "/config"
    dist_custom_dir = str(ROOT_DIR / "frontend/dist/custom")

    # test sur les dossiers concernés
    t_in = directories_last_modif([config_dir])
    t_out = directories_last_modif([dist_assets_config_dir, dist_custom_dir])

    # si rien n'a été modifié depuis la dernière fois on ne fait rien

    if t_in < t_out:
        return 

    print('processing frontend assets')

    if not os.path.exists(src_assets_dir):
        os.makedirs(src_assets_dir)

    if not os.path.exists(dist_assets_dir):
        os.makedirs(dist_assets_dir)

    if not os.path.exists(src_assets_config_dir):
        os.makedirs(src_assets_config_dir)

    path_api_config = src_assets_config_dir + "/api.config.json"
    with open(path_api_config, "w") as outputfile:
        outputfile.write('"{}"'.format(config['API_ENDPOINT']))

    # (re)copy 
    # - assets/config/api.config 
    # - assets/custom 

    if os.path.exists(dist_assets_config_dir):
        shutil.rmtree(dist_assets_config_dir)
    shutil.copytree(src_assets_config_dir, dist_assets_config_dir)


    if os.path.exists(dist_custom_dir):
        shutil.rmtree(dist_custom_dir)
    shutil.copytree(src_custom_dir, dist_custom_dir)


