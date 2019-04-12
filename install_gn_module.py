import subprocess
from pathlib import Path

ROOT_DIR = Path(__file__).absolute().parent



def gnmodule_install_app(gn_db, gn_app):
    '''
        Fonction principale permettant de réaliser les opérations d'installation du module
    '''
    with gn_app.app_context() :
        # To run a SQL script use the gn_db parameter
        #gn_db.session.execute(open(<my_sql_data.sql>, 'r').read())
        #gn_db.session.commit()
        pass
