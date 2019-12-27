import subprocess
from pathlib import Path
from sqlalchemy.sql import text
ROOT_DIR = Path(__file__).absolute().parent


def gnmodule_install_app(gn_db, gn_app):
    '''
        Fonction principale permettant de réaliser les opérations d'installation du module
    '''
    with gn_app.app_context():
        script_install = str(ROOT_DIR / 'data/occhab.sql')
        script_data = str(ROOT_DIR / 'data/sample_data.sql')
        try:
            gn_db.engine.execute(
                text(open(script_install, 'r').read()),
                MYLOCALSRID=gn_app.config['LOCAL_SRID']
            )
            gn_db.session.commit()
        except Exception:
            raise "Erreur lors de l'installation du schéma pr_occhab"
        try:
            gn_db.engine.execute(
                text(open(script_data, 'r').read()).execution_options(autocommit=True))
        except Exception as e:
            print(e)
            print("Erreur lors de l'insertion des données exemples")
