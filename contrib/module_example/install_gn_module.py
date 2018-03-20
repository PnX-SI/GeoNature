import subprocess
from pathlib import Path

ROOT_DIR = Path(__file__).absolute().parent



def gnmodule_install_app(gn_db, gn_app):
    '''
        Fonction principale permettant de réaliser les opérations d'installation du module : 
            - Base de données
            - Module (pour le moment rien)
    '''
    with gn_app.app_context() :
        pass
