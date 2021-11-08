A partir de la version 2.8.0 de GeoNature, sa BDD et ses évolutions sont gérés par Alembic dans ``backend/geonature/migrations/``.

Les fichiers de création initiale de la BDD n'évoluent plus directement, car ce sont les migrations Alembic qui se chargent des modifications de la BDD.
