import os
import time
import shutil
from geonature.utils.config import config_frontend, config
from geonature.utils.env import (
    ROOT_DIR,
)


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

    # test sur le fichier pour faire en sorte qu'un seul worker n'execute cet action
    if (
        (os.path.exists(path_test)) 
        and 
        # si le fichier a été modifié depuis moins de  5 seconde
        (int(time.time()) - os.path.getmtime(path_test)) < 5
    ): 
        return


    with open(path_test, "w+") as outputfile:
        outputfile.write(' ')

    src_assets_dir = str(ROOT_DIR / "frontend/src/assets")
    dist_assets_dir = str(ROOT_DIR / "frontend/dist/assets")
    
    src_assets_config_dir = src_assets_dir + "/config"
    dist_assets_config_dir = dist_assets_dir + "/config"

    src_custom_dir = str(ROOT_DIR / "frontend/src/custom")
    dist_custom_dir = str(ROOT_DIR / "frontend/dist/custom")

   
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


