# Sécurité:

HTTPS

HttpOnly cookies + Match cookie session avec adresse IP ou un certif ssl

Sanitize ticker in routes.py :

    urlValidate = "%s?ticket=%s&service=%s"%(configCas['URL_VALIDATION'], params['ticket'], base_url)

    Au cas ou l'autre service ne soit pas sécurisé

Log 500 and send email

Verifier:

    Est-ce que la connection au CAS se fait en HTTPS ?

    Les id sont ils séquentiels ? Peut ont y accéder de sans avoir les droits ?

remove_file, upload_file et rename_file doivent vérifier le chemin absolu avant de faire l'opération. Un 3eme paramètre doit contenir une liste noire en dur de chemin de dossiers interdits. On doit aussi vérifier que les fichiers du projets en lui même ne sont pas sur ce chemin.

# Modularité:

Créer une API de backend d'authentification et d'identification.

Système de plugin: hook, entry points et configuration

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

Imports inutilisés, fichiers vides (utils.py), reste de python 2 (/home/user/Work/dev_pro/ecrins/GeoNature/backend/src/core/gn_exports/routes.py)

Créer un décorateur pour rollback automatiquement en cas d'exception dans les vues

Et get_or_404

Retirer les mettres et remplacer par logging

Gérer les valeurs aberrantes en entrée:

E.g: mettre un try et une limite de taille et interdire les valeurs négatives sur:

    limit = int(parameters.get('limit')) if parameters.get('limit') else 100
    page = int(parameters.get('offset')) if parameters.get('offset') else 0

Ne pas retourner -1 en cas d'erreur mais lever une exception. E.G:

    def get_releve_if_allowed(self, user, data_scope):
        """Return the releve if the user is allowed
          -params:
          user: object from TRole
          data_scope: string: level of rigth for an action
        """
        if data_scope == '2':
            if self.user_is_observer_or_digitiser(user) or self.user_is_in_dataset_actor(user):
                return self
        elif data_scope == '1':
            if self.user_is_observer_or_digitiser(user):
                return self
        else:
            return self
        return -1

Eviter d'attrapper les exceptions très larges si on ne reraise pas. E.G:

    try:
        nbResultsWithoutFilter = VReleveList.query.count()
    except Exception as e:
        db.session.rollback()

OU:

    def remove_file(filepath):
        try :
            os.remove(os.path.join(current_app.config['BASE_DIR'], filepath))
        except :
            pass

Ou:
        try:
            int(value)
        except Exception as e:
            return '{0} must be an integer'.format(paramName)

Verifier la taille du dataset pour:

    try:
        data = q.limit(limit).offset(page*limit).all()
    except Exception as e:
        db.session.rollback()
        raise

    user = info_role[0]
    user_cruved = fnauth.get_cruved(user.id_role,current_app.config['ID_APPLICATION_GEONATURE'] )
    featureCollection = []
    for n in data:
        releve_cruved = n.get_releve_cruved(user, user_cruved)
        feature = n.get_geofeature()
        feature['properties']['rights'] = releve_cruved
        featureCollection.append(feature)

Utiliser extend:

            for o in observers:
                releve.observers.append(o)

Reecrire removeDisallowedFilenameChars: secure_filename fait déjà unicodedata.normalize, utliser split(), autoriser les caracteres chinois, mettre un nombre de lettres minimales complétées par un hash du nom original si les lettres manquent:

    def removeDisallowedFilenameChars(uncleanString):
        cleanedString = secure_filename(uncleanString)
        cleanedString = unicodedata.normalize('NFKD', uncleanString)
        cleanedString = re.sub('[ ]+', '_', cleanedString)
        cleanedString = re.sub('[^0-9a-zA-Z_-]', '', cleanedString)
        return cleanedString

Render le code générique avec un mapping:

    def testDataType(value, sqlType, paramName):
        if sqlType == db.Integer or isinstance(sqlType, (db.Integer)):
            try:
                int(value)
            except Exception as e:
                return '{0} must be an integer'.format(paramName)
        if sqlType == db.Numeric or isinstance(sqlType, (db.Numeric)):
            try:
                float(value)
            except Exception as e:
                return '{0} must be an float (decimal separator .)'\
                    .format(paramName)
        elif sqlType == db.DateTime or isinstance(sqlType, (db.Date, db.DateTime)):
            try:
                from dateutil import parser
                dt = parser.parse(value)
            except Exception as e:
                return '{0} must be an date (yyyy-mm-dd)'.format(paramName)
        return None


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

# Bons points

Peu de requêts SQL pures. Lesquelles ont un échapement corrects des paramétres.

Autoescape n'est pas désactivé

Vérification de l'appartenance des relevés.
