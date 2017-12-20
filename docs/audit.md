# Sécurité:

HttpOnly cookies + Match cookie session avec adresse IP ou un certif ssl

Sanitize ticker in routes.py :

    urlValidate = "%s?ticket=%s&service=%s"%(configCas['URL_VALIDATION'], params['ticket'], base_url)

    Au cas ou l'autre service ne soit pas sécurisé

Log 500 and send email

Verifier:

    Est-ce que la connection au CAS se fait en HTTPS ?

    Les id sont ils séquentiels ? Peut ont y accéder de sans avoir les droits ?

# Modularité:

Créer une API de backend d'authentification et d'identification.

# Qualité du code:

Ajout de linters (pylint, mypy, mccabe...)

Ajouts de tests unitaires et suite de test (tox + pytest)

.gitignore plus complet

Mettre des __init__.py dans les dossiers pour les compter comme des packages et non des namespaces

Log 404

Log Exceptions

Mettre des doc string, exemple:

    route.py : def insert_in_cor_role(id_group, id_user):

Utiliser Pipfile et lock files pour locker les dépendences et inclure les dépendences de dev

Workflow git:
    Déplacer le projet dans un repo séparé
    Utiliser des features branches

# Aspect légal:

- Déclaration à la CNIL;
- Fichier de LICENCE
- Dosser de licence des dépendances

# Ergonomie:

- Le menu pour changer la langue ne doit pas changer de langue lui-même.
- Retirer le '#' des Urls

# Configuration:

- Une grande partie des valeurs devraient être centralisées, et overridable par variables d'environnement. E.G: conf.ts et conf.py doivent hériter du même fichier de conf.
- En mode dev, le make file pour runner gunicorn doit utiliser ces configs et env var.
