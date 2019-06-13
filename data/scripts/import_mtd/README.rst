


Ce script permet d'importer les métadonnées à partir de leurs uuid en utilisant le webservice mtd de l'INPN.
Il permet de rappatrier dans une instance GeoNature les métadonnées correspondant à des données INPN qui 
déjà importées dans la BDD GeoNature depuis un export INPN.  


Installation de l'environnement Python
--------------------------------------

- Pour être plus propre il est conseillé de créer un nouveau virtualenv et d'y installer les paquets Python

::
    
    cd /home/'whoami'/geonature/data/scripts/import_mtd
    virtualenv -p /usr/bin/python3 venv #Python 3 n'est pas requis
    source venv/bin/activate
    pip install psycopg2 requests
    deactivate


Configuration du script
-----------------------

- Créez un fichier config.py à partir du fichier config.py.sample

- Récupérer le paramètre de ''SQLALCHEMY_DATABASE_URI'' dans le fichier geonature/config/geonature_config.toml
  et renseignez le dans le fichier config.py que vous avez créé

- Renseignez le nom de la table comprenant les données INPN que vous avez importées, et les noms des champs comprenant les uuid
  des cadres d'acquisitions et des jeux de données

- Vous pouvez définir l'id_organisme auquel vous souhaitez rattacher les personnes mentionnées dans les acteurs des métadonnées rappatriées. 
  Elles ne sont pas rattachées aux organismes associés dans un premier temps, afin d'éviter les conflits lorsqu'un acteur est associé à plusieurs organismes.

- Vous pouvez également choisir de conserver ou non les fichiers émis par le webservice de l'INPN sur votre serveur (dossier du script)

Execution du script
-------------------

- Activer le virtualenv :

::
    
    source venv/bin/activate

- lancer le script : 

::
    
    python run_import_mtd.py > import_mtd.log
