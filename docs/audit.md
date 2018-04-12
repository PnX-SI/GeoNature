# Priorités pour le référenciel

HTTPS

HttpOnly cookies + Match cookie session avec adresse IP ou un certif ssl

Sanitize

Log 500 and send email

Verifier:

    Est-ce que la connection au CAS se fait en HTTPS ?

    Les id sont ils séquentiels ? Peut ont y accéder de sans avoir les droits ?

Backup

Installation et configuration de référence

Definition d'une procédure de connexion à UsersHub pour une mise en oeuvre sécurisée

Documentation des ports et permissions recommandés pour l'application

Ajout de linters (pylint, mypy, mccabe...)

Ajouts de tests unitaires et suite de test (tox + pytest)

- Déclaration à la CNIL;
- Fichier de LICENCE
- Dossier de licence des dépendances

# Sécurité:

HTTPS

HttpOnly cookies + Match cookie session avec adresse IP ou un certif ssl

Sanitize ticket in routes.py :

    urlValidate = "%s?ticket=%s&service=%s"%(configCas['URL_VALIDATION'], params['ticket'], base_url)

    Au cas ou l'autre service ne soit pas sécurisé

Log 500 and send email

Verifier:

    Est-ce que la connection au CAS se fait en HTTPS ?

    Les id sont ils séquentiels ? Peut ont y accéder de sans avoir les droits ?

remove_file, upload_file et rename_file doivent vérifier le chemin absolu avant de faire l'opération. Un 3eme paramètre doit contenir une liste noire en dur de chemin de dossiers interdits. On doit aussi vérifier que les fichiers du projets en lui même ne sont pas sur ce chemin.

Throttle

Backup

Utilisation de JWT pour l'authentification

API OAUTH pour UsersHub

Definition d'une procédure de connexion à UsersHub pour une mise en oeuvre sécurisée

Documentation des ports et permissions recommandés pour l'application

# Modularité:

Définir les objectifs de la modularisation

Versionner l'API et le schéma de base de donnée

Fournir un processus, des conventions et outils de migration pour la base

Créer une API de backend d'authentification et d'identification.

Comment un module s'attache-t-il au projet ? A quoi peut il réagir ? Que peut il overrider (template, config, vues, urls, etc) ?

Comment creer son propre point d'entrée qui utilise l'outils de manière composée

Comment gérér la configuration par defaut et celle custo ?

Comment gérer les mises à jour ? Notamment les migrations de schéma.

D'après les objectifs de http://geonature.fr/documents/2017-04-Presentation-projet-1.0.pdf:

- 1 modèle de données par protocole
- 1 schéma de base de données par protocole
- 1 synthèse automatique de l'ensemble des données Faune/flore/fonge issues des
différents protocoles
- 1 schéma de métadonnées permettant d'identifier le protocole, le programme, le jeu de
données et la source de chaque donnée
- Des méthodes standards d'alimentation de la synthèse (API, triggers ou ETL)

=> Comment attacher le modèle à l'administration ? Aux formulaires ?
=> Comment s'intégrer dans le processus d'installation. Intéragir avec les autres protocols ?
=> Comment se déclarer pour faire partie de la synthèse ?

- Des bonnes pratiques et guides techniques pour le développement de nouveaux
modules et protocoles

=> Doc ?

Utilisation d'uuid à la place de d'id incrémentaux. Particulièrement pour : les données utilisateurs et les taxons.


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
    user_cruved = cruved_for_user_in_app(user.id_role,current_app.config['ID_APPLICATION_GEONATURE'] )
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

Le projet doit-il supporter Python 2.7 ? Si oui, créer l'insfrastructure pour cela. Si non, retirer les artefacts tels que # coding et les imports __future__

Pinpoint dependancies

Faire l'introspection du serializableModel une seule fois à la création de la classe, soit à l'aide d'une lib tierce partie existante (ex: marshmallow) ou à l'aide d'une metaclass.

Choisir un standard de notation pour les selecteurs SCSS. Documenter les variables.

Gestion des erreurs réseau sur les appels Ajax

# Aspect légal:

- Déclaration à la CNIL;
- Fichier de LICENCE
- Dossier de licence des dépendances

# Ergonomie:

- Faire bilan ergonomique
- Le menu pour changer la langue ne doit pas changer de langue lui-même.
- Retirer le '#' des Urls
- Restaurer le click milieu sur certains menus

# Configuration:

- Une grande partie des valeurs devraient être centralisées, et overridable par variables d'environnement. E.G: conf.ts et conf.py doivent hériter du même fichier de conf.
- En mode dev, le make file pour runner gunicorn doit utiliser ces configs et env var.

# Temps de chargement

Retirer les polyfills pour les ever greens browsers dans le production build

Vérifier que l'import de rxj ne tue pas le tree shaking

Préciser d'utiliser ng build --prod pour la mise en production pour profiter de l'AOT

# Documentation

- Fournir un graphique du modele general de donnée
- Fournir une list des enpoints de l'API
- Founrir un schéma général de l'organisations des différents éléments de la stack déployées
- Fournir un schéma général de l'organisation des différents
- Ces schémas doivent être mis à jour une fois par mois à une date fixe.

# Bons points

Peu de requêts SQL pures. Lesquelles ont un échapement corrects des paramétres.

Autoescape n'est pas désactivé

Vérification de l'appartenance des relevés.

Lazy loading bien pensé dans le routing frontend

Polyfill minimalist

Utilisation des modules Angular les plus à jour (ex: HttpClient)

Gestion des utilisateurs et permissions standardisée, fournies par un service séparé

Indice de MacAbe 5, à l'exception de 14 méthodes

Questions
==========

Ou est le backoffice dont on parle dans https://github.com/PnX-SI/GeoNature/wiki/V2-:-Backoffice

