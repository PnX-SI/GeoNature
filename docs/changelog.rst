=========
CHANGELOG
=========

1.6.0 dev (2015-12-21)
------------------

**Note de version**

* Pour les changements dans la base de données vous devez exécuter le fichier ``data/update_1.5to1.6.sql``
* ajouter le paramètre ``$id_application`` dans ``lib/sfGeonatureConfig.php.php`` (voir la valeur utilisée pour GeoNature dans les tables "utilisateurs.t_applications" et "utilisateurs.cor_role_droit_application")


**Changements**

* Correction d'une erreur lors de l'enregistrement de la saisie invertébrés. - Fix #104
* Mise en paramètre du id_application dans ``lib/sfGeonatureConfig.php.php`` - Fix #105
* Recharger la synthese après suppression d'un enregistrement - Fix #94 
* Correction d'une erreur de redirection si on choisi "quitter" après la saisie de l'enregistrement (contact faune, mortalité et invertébrés) - Fix #102
* Correction et adaptation faune-flore des exports shape 


1.5.0 (2015-11-26)
------------------

**Note de version**

* Pour les changements dans la base de données vous pouvez exécuter le fichier ``data/update_1.4to1.5.sql``
* Le bandeau de la page d'accueil ``web/images/bandeau_faune.jpg`` a été renommé en ``bandeau_geonature.jpg``. Renommez le votre si vous aviez personnalisé ce bandeau.
* Si vous souhaitez désactiver certains programmes dans le "Comment ?" de la synthèse vous devez utiliser le champs ``actif`` de la table ``meta.bib_programmes``.
* Compléter si nécessaire les champs ``url``, ``target``, ``picto``, ``groupe`` et ``actif`` dans la table ``synthese.bib_sources``.
* Nouvelle répartition des paramètres de configuration javascript en 2 fichiers (``config.js`` et ``configmap.js``). Vous devez reprendre vos paramètres de configuration du fichier ``web/js/config.js`` et les ventiler dans ces deux fichiers.
* Ajouter le paramètre ``id_source_mortalite = 2;`` au fichier ``web/js/config.js``;
* Retirer le paramètre ``fuseauUTM;`` du fichier ``web/js/config.js``;
* Bien définir le système de coordonnées à utiliser pour les pointages par coordonnées fournies en renseignant le paramètre ``gps_user_projection`` dans le fichier ``web/js/config.js``;
* Ajouter le paramètre ``public static $id_source_mortalite = 2;`` au fichier ``lib/sfGeonatureConfig.php``;
* Ajouter le paramètre ``public static $srid_ol_map = 3857;`` au fichier ``lib/sfGeonatureConfig.php``;
* L'altitude est calculée automatiquement à partir du service "Alticodage" de l'API GeoPortail de l'IGN et non pluas à partir de la couche ``layers.l_isolines20``. Ajoutez ce service dans votre contrat API Geoportail. Il n'est donc plus nécessaire de remplir la couche ``layers.l_isolines20``. Cette couche peut toutefois encore être utile si l'utilisateur supprime l'altitude calculée par l'API Geoportail dans les formulaires de saisie.
* Le loup et le lynx sont retirés par défaut de la saisie (saisie recommandée dans le protocole national du réseau grands prédateurs)
* Le cerf, chamois et le bouquetin doivent être saisis selon 6 critères de sexe et age et non 5 comme les autres taxons. Comportement peut-être changé en modifiant la vue ``contactfaune.v_nomade_taxons_faune``.
* Mortailité est désormais une source à part entière alors qu'elles étaient mélangées avec la source ContactFaune précédemment. Si vous avez déjà des données de mortalité enregistrées, vous devez adapter la requête SQL ci-dessous avec votre ``id_source`` pour Mortalité et l'exécuter :
    
    ::
    
        UPDATE synthese.syntheseff SET id_source = 2 WHERE id_source = 1 AND id_critere_synthese = 2;

**Changements**

* Optimisation des vues aux chargement des listes de taxons. Fixes #64
* Généricité des champs dans ``meta.bib_programmes`` (champs ``sitpn`` renommé en ``public``). Fixes #68
* Ajout d'un champ ``actif`` à la table ``meta.bib_programmes`` permettant de masquer certains programmes dans le "Comment ?" de la synthèse. Fixes #66
* Ajout d'un champ ``url``, ``target``, ``picto``, ``groupe`` et ``actif`` dans la table ``synthese.bib_sources`` pour générer la page d'accueil dynamiquement et de manière générique. Fixes #69
* Construire dynamiquement la liste des liens vers la saisie des différents protocoles à partir de la table ``synthese.bib_sources``. Fixes #69
* Tous les styles des éléments de la page d'accueil ont été passés en CSS. Fixes #57
* Amélioration de l'interface pendant le chargement des différentes applications (synthèse, flore station, formualires de saisie...). Fixes #65
* Recentrage sur la position de l'utilisation en utilisant le protocole de géolocalisation intégré au navigateur de l'utilisateur. Fixes #65
* Un message automatique conseille les utilisateurs d'Internet Explorer de plutôt utiliser Firefox ou Chrome. Fixes #65
* Tri par défaut par date décroissante des 50 dernières observations affichées à l'ouverture de la Synthèse. Fixes #51
* Vocabulaire. "Dessiner un point" remplacé par "Localiser l'observation". Fixes #66
* Mise à jour des copyrights dans les pieds de page de toutes les applications.
* Refonte du CSS du formulaire de login avec bootstrap et une image de fond différente.
* Refonte Bootstrap de la page d'accueil.
* Homogénéisation du pied de page.
* FloreStation et Bryophytes - Homogénéiser interaction carte liste - ajout d'un popup au survol. Fixes #74
* Suppression d'images non utilisées dans le répertoire ``web/images``.
* Mise en cohérence des vues taxonomiques faune. Fixes #81
* Calcul de l'altitude à partir du service "Alticodage" de l'API GeoPortail de l'IGN.
* Factorisation et généralisation du module permettant un positionnement des pointages par saisie de coordonnées selon projection et bbox fournies en paramètres de config.
* Création d'une configuration javascript carto dédiée (``configmap.js``).
 
 **Corrections de bug**
 
 * Correction des problèmes de saisie de la version 1.4.0 liés à la migration de la taxonomie.
 * Correction de bugs dans Flore Station et Bryophytes (Zoom, recherche
 
1.4.0 (2015-10-16)
------------------

**Note de version**

* La gestion de la taxonomie a été mis en conformité avec le schéma ``taxonomie`` de la base de données de TaxHub (https://github.com/PnX-SI/TaxHub). Ainsi le schéma ``taxonomie`` intégré à GeoNature 1.3.0 doit être globalement revu. L'ensemble des modifications peuvent être réalisées en éxecutant la partie correspondante dans le fichier ``data/update_1.3to1.4.sql`` (https://github.com/PnEcrins/GeoNature/blob/master/data/update_1.3to1.4.sql).
* De nouveaux paramètres ont potentiellement été ajoutés à l'application. Après avoir récupéré le fichier de configuration de votre version 1.3.0, vérifiez les changements éventuels des différents fichiers de configuration.
* Modification du nom de l'host host hébergeant la base de données. databases --> geonatdbhost. A changer ou ajouter dans le ``/etc/hosts`` si vous avez déjà installé GeoNature.
* Suivez la procédure de mise à jour : http://geonature.readthedocs.org/fr/latest/installation.html#mise-a-jour-de-l-application

**Changements**

* A l'installation initiale, chargement en base des zones à statuts juridiques pour toute la France métropolitaine à partir des sources de l'INPN
* A l'installation initiale, chargement en base de toutes les communes de France
* Mise en place de la compatibilité de la base avec le schema de TaxHub


1.3.0 (2015-02-11)
------------------

Pré-Version de GeoNature - Faune ET Flore. Le fonctionnement de l'ensemble n'a pas été totalement testé, des bugs sont identifiés, d'autres subsistent certainement.

**Changements**

* Grosse évolution de la base de données
* Ajout de deux applications de saisie flore (flore station et bryophytes)
* Intégration de la flore en sythese
* Ajouter un id_lot, id_organisme, id_protocole dans toutes les tables pour que ces id soit ajoutés vers la synthese en trigger depuis les tables et pas avec des valeurs en dur dans les triggers. Ceci permet d'utiliser les paramètres de conf de GeoNature
* Ajout d'une fonction à la base pour correction du dysfonctionnement du wms avec mapserver
* Suppression du champ id_taxon en synthese et lien direct de la synthese avecle taxref. ceci permet d'ajouter des données en synthese directement dans la base sans ajouter tous les taxons manquants dans la table bib_taxons
* Suppression de la notion de coeur dans les critère de recherche en synthese
* Ajout d'un filtre faune flore fonge dans la synthese
* Ajout de l'embranchement et du regne dans les exports
* Permettre à des partenaires de saisir mais d'exporter uniquement leurs données perso
* Ajout du déterminateur dans les formulaires invertébrés et contactfaune + en synthese
* Ajout du référentiel géographique de toutes les communes de France métropolitaine
* Ajout des zones à statuts juridiques de la région sud-est (national à venir)
* Bugs fix
 
**BUG à identifier**

Installation :

* corriger l'insertion de données flore station qui ne fonctionne pas

Bryophythes :

* Corriger la recherche avancée par date sans années

Synthèse :

* la construction de l'arbre pour choisir plusieurs taxons ne tient pas compte des filtres
* le fonctionnement des unités geographiques n'a pas été testé (initialement conçu uniquement pour la faune)


1.2.0 (2015-02-11)
------------------

Version stabilisée de GeoNature - Faune uniquement (Synthèse Faune + Saisie ContactFauneVertebre, ContactFauneInvertebre et Mortalité).

**Changements**

* Modification du nom de l'application de FF-synthese en GeoNature
* Changement du nom des utilisateurs PostgreSQL
* Changement du nom de la base de données
* Mise à jour de la documentation (http://geonature.readthedocs.org/)
* Automatisation de l'installation de la BDD
* Renommer les tables pour plus de généricité
* Supprimer les tables inutiles ou trop spécifiques
* Gestion des utilisateurs externalisée et centralisée avec UsersHub (https://github.com/PnEcrins/UsersHub)
* Correction de bugs
* Préparation de l'intégration de la Flore pour passer de GeoNature Faune à GeoNature Faune-Flore


1.1.0 (2014-12-11)
------------------

**Changements**

* Modification du schéma de la base pour être compatible taxref v7
* Import automatisé de taxref v7
* Suppression des tables de hiérarchie taxonomique (famille, ordre, ...) afin de simplifier l'utilisation de la taxonomie.
* Création de la notion de groupe (para-taxonomique) à la place de l'utilisation des classes.
* Ajout de données pour pouvoir tester de façon complète l'application (invertébrés, vertébrés)
* Ajout de données exemples
* Bugs fix


1.0.0 (2014-12-10)
------------------

Version fonctionnelle des applications : visualisation de la synthèse faune, saisie d'une donnée de contact (vertébrés, invertébrés, mortalité)

**Changements**

* Documentation de l'installation d'un serveur Debian wheezy pas à pas
* Documentation de la mise en place de la base de données
* Documentation de la mise en place de l'application et de son paramétrage
* Script d'insertion d'un jeu de données test
* Passage à PostGIS v2
* Mise en paramètre de la notion de lot, protocole et source

**Prochaines évolutions**

* Script d'import de taxref v7
* Utilisation préférentielle de la taxonomie de taxref plutôt que les tables de hiérarchie taxonomique


0.1.0 (2014-12-01)
------------------

* Création du projet et de la documentation
