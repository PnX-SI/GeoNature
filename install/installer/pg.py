"""Création du rôle et de la base PostgreSQL.

Les valeurs (mot de passe compris) passent par des variables psql (`:'var'` / `:"var"`) lues sur
l'entrée standard : elles sont échappées par psql, jamais interpolées dans une commande shell.
"""

PG_EXTENSIONS_SQL = "assets/db/add_pg_extensions.sql"


class DatabaseExistsError(RuntimeError):
    pass


def set_command(name, value):
    """`\\set` psql sur stdin : la valeur (ex. mot de passe) n'apparaît jamais dans `ps`."""
    value = str(value)
    if "\n" in value or "\r" in value or "\0" in value:
        raise ValueError(f"valeur invalide pour {name} : saut de ligne ou caractère nul")
    return f"\\set {name} '" + value.replace("\\", "\\\\").replace("'", "''") + "'\n"


def psql(runner, sql, dbname="postgres", variables=None, capture=False):
    """Exécute `sql` (lu sur stdin) en tant que postgres via sudo."""
    cmd = ["sudo", "-u", "postgres", "psql", "-X", "-v", "ON_ERROR_STOP=1", "-d", dbname]
    if capture:
        cmd += ["-At"]
    sql = "".join(set_command(k, v) for k, v in (variables or {}).items()) + sql
    if capture:
        return runner.capture(cmd, input=sql).stdout.strip()
    return runner.run(cmd, input=sql)


def database_exists(runner, name):
    out = psql(
        runner,
        "SELECT 1 FROM pg_database WHERE datname = :'db'",
        variables={"db": name},
        capture=True,
    )
    return out == "1"


def role_exists(runner, name):
    return (
        psql(
            runner,
            "SELECT 1 FROM pg_roles WHERE rolname = :'u'",
            variables={"u": name},
            capture=True,
        )
        == "1"
    )


def drop_database(runner, name, confirm_drop=None):
    """Supprime la base seulement si l'utilisateur a confirmé son nom (`--confirm-drop <nom>`)."""
    if confirm_drop != name:
        raise DatabaseExistsError(
            f"La base '{name}' existe déjà. Pour la supprimer, relancez avec --confirm-drop {name}."
        )
    psql(
        runner,
        "SELECT pg_terminate_backend(pid) FROM pg_stat_activity "
        "WHERE datname = :'db' AND pid <> pg_backend_pid();\nDROP DATABASE :\"db\";",
        variables={"db": name},
    )


def create_role(runner, user, password):
    if role_exists(runner, user):
        return False
    psql(
        runner, "CREATE ROLE :\"u\" WITH LOGIN PASSWORD :'p';", variables={"u": user, "p": password}
    )
    return True


def create_database(runner, name, owner, locale):
    psql(
        runner,
        'CREATE DATABASE :"db" OWNER :"u" TEMPLATE template0 ENCODING \'UTF8\' '
        "LC_COLLATE :'loc' LC_CTYPE :'loc';",
        variables={"db": name, "u": owner, "loc": locale},
    )


def add_extensions(runner, name, install_dir):
    psql(runner, (install_dir / PG_EXTENSIONS_SQL).read_text(), dbname=name)


def grant_reference_tables(runner, name, user):
    psql(
        runner,
        'GRANT SELECT ON TABLE geometry_columns, geography_columns, spatial_ref_sys TO :"u";',
        dbname=name,
        variables={"u": user},
    )
