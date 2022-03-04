# Référentiel géographique

Prérequis : vous devez installer l’extension postgis sur votre base de donnée.

Création et remplissage du référentiel géographique :

    python3 -m venv venv
    source venv/bin/activate
    pip install -e .
    pip install psycopg2  # for postgresql database
    export SQLALCHEMY_DATABASE_URI="postgresql://user:password@localhost:5432/database"
    alembic -x local-srid=2154 upgrade ref_geo@head
    alembic upgrade ref_geo_fr_municipalities@head  # Insertion des communes françaises
    alembic upgrade ref_geo_fr_departments@head  # Insertion des départements français
    alembic upgrade ref_geo_fr_regions@head  # Insertion des régions françaises
    alembic upgrade ref_geo_fr_regions_1970@head  # Insertion des anciennes régions françaises
    alembic upgrade ref_geo_inpn_grids_1@head  # Insertion du maillage 1×1km de l’hexagone fourni par l’INPN
    alembic upgrade ref_geo_inpn_grids_5@head  # Insertion du maillage 5×5km de l’hexagone fourni par l’INPN
    alembic upgrade ref_geo_inpn_grids_10@head  # Insertion du maillage 10×10km de l’hexagone fourni par l’INPN
