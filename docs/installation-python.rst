Installation avec l'installateur Python
***************************************

L'installateur ``install/install.py`` remplace l'ancienne installation globale (``install_all.sh``). Il s'exécute avec le Python du système (bibliothèque standard uniquement) et apporte :

- une configuration unique dans un fichier ``install.toml`` (les caractères spéciaux des mots de passe sont pris en charge) ;
- un contrôle des prérequis avant toute modification ;
- des étapes reprenables : une étape terminée est ignorée à la relance, et une installation interrompue reprend où elle s'est arrêtée ;
- une commande de mise à jour sur place, avec sauvegarde et retour arrière.

.. note::

    Cet installateur est récent. Il installe GeoNature (incluant TaxHub) mais pas UsersHub, qui pilote le schéma ``utilisateurs`` : installez-le séparément en suivant sa `documentation <https://usershub.readthedocs.io>`_ pour disposer d'une interface de gestion des utilisateurs.

Installation rapide
-------------------

Connecté avec l'utilisateur dédié (pas en ``root``, mais avec ``sudo``), lancez :

.. code:: console

    curl -LsSf https://raw.githubusercontent.com/PnX-SI/GeoNature/X.Y.Z/install/get-geonature.sh | sh

(``X.Y.Z`` : numéro de la `dernière version stable <https://github.com/PnX-SI/GeoNature/releases>`_). Fixer la version dans l'URL garantit que vous exécutez le script de cette version ; vous pouvez le lire avant de le lancer en le téléchargeant d'abord avec ``curl -LsSfO <url>``.

Pour installer une autre version (tag ou branche) que la dernière version stable, définissez ``GEONATURE_VERSION`` pour ``sh`` (et non pour ``curl``) :

.. code:: console

    curl -LsSf https://raw.githubusercontent.com/PnX-SI/GeoNature/X.Y.Z/install/get-geonature.sh | GEONATURE_VERSION=X.Y.Z sh

Le clone est superficiel (``--depth 1``, sous-modules compris) : seul le commit de la version est téléchargé, et ``install.py update`` reste superficiel lui aussi.

Le script se limite à l'amorçage : il installe ``git`` et ``python3`` s'ils manquent, clone GeoNature dans ``~/geonature`` (version choisie avec la variable ``GEONATURE_VERSION``, par défaut la dernière version stable ; dossier avec ``GEONATURE_DIR``), crée ``install/install.toml`` à partir de l'exemple, vous pose les questions sur les principaux paramètres puis lance le contrôle des prérequis. Il n'installe rien d'autre et refuse de s'exécuter si le dossier existe déjà. Suivez ensuite l'étape qu'il affiche : lancer ``install.py``.

Les questions (mode, URL, préfixe, base et utilisateur PostgreSQL, mot de passe, puis en option les données et modules à installer) sont posées dans le terminal, même avec ``curl | sh``. Entrée garde la valeur proposée, ``-`` donne une valeur vide (par exemple pour servir GeoNature à la racine). Sans terminal, ou avec ``GEONATURE_NO_PROMPT=1``, elles sont ignorées et il faut éditer ``install.toml`` à la main. Elles peuvent être reposées à tout moment :

.. code:: console

    python3 install/install.py --configure --config install/install.toml

Les sections suivantes détaillent ces étapes, qui peuvent aussi être faites à la main.

Récupération du code
--------------------

GeoNature s'installe depuis un clone du dépôt (pas d'archive à télécharger) :

.. code:: console

    cd ~
    git clone https://github.com/PnX-SI/GeoNature geonature
    cd geonature
    git checkout X.Y.Z
    git submodule update --init --recursive

(``X.Y.Z`` : numéro de la `dernière version stable <https://github.com/PnX-SI/GeoNature/releases>`_).

Configuration
-------------

.. code:: console

    cp install/install.sample.toml install/install.toml
    nano install/install.toml

Si vous n'avez pas utilisé ``get-geonature.sh`` ou ``--configure``, renseignez à minima ``my_url`` (avec un ``/`` final), ``url_application_prefix_path`` et ``user_pg``. Laissez ``user_pg_pass`` vide pour qu'un mot de passe aléatoire soit généré : il est conservé dans ``config/settings.ini`` et n'est jamais régénéré aux relances.

Le fichier ``install.toml`` reprend les paramètres de l'ancien fichier ``install_all.ini``. Les clés absentes prennent leur valeur par défaut (``DEFAULTS`` dans ``install/installer/render.py``).

Vérification des prérequis
--------------------------

.. code:: console

    python3 install/install.py --check --config install/install.toml

Sont contrôlés : architecture 64 bits, utilisateur non-root, ``sudo``, disponibilité de ``uv`` (installé avec ``pip --user`` s'il manque) et de Python 3.13, mémoire (4 Go conseillés), espace disque (20 Go), locale, PostgreSQL, port 80 et accès aux sites externes (``--offline`` pour ne pas tester le réseau). Le code de retour est non nul si un contrôle bloquant échoue.

.. note::

    La lecture de ``install.toml`` nécessite Python 3.11 ou plus (Debian 12 et 13). Le Python utilisé par GeoNature lui-même est installé par ``uv``.

Installation
------------

.. code:: console

    python3 install/install.py --config install/install.toml

Les étapes sont, dans l'ordre : ``apt``, ``nvm``, ``backend``, ``systemd``, ``database``, ``modules``, ``frontend``, ``apache`` et ``services``. Le détail des commandes est écrit dans ``install/install.log``.

En cas d'échec, corrigez le problème puis relancez la même commande : les étapes déjà terminées sont ignorées. Options utiles :

- ``--from-step NOM`` : reprend à une étape donnée ;
- ``--only NOM`` : n'exécute qu'une étape ;
- ``--reset-state`` : oublie les étapes terminées (seulement celle de ``--only`` s'il est donné) ;
- ``--render-config`` : génère uniquement ``config/settings.ini`` et ``config/geonature_config.toml`` ;
- ``--render-settings`` : génère uniquement ``config/settings.ini`` (utilisé par ``make init_settings_ini``) ;
- ``--confirm-drop NOM_BASE`` : autorise la suppression d'une base existante lorsque ``drop_apps_db = true``. Sans cette confirmation, la base n'est jamais supprimée ;
- ``--skip-check`` : n'exécute pas le contrôle des prérequis.

Les fichiers de configuration existants ne sont jamais écrasés (sauf avec ``--force``).

Mise à jour
-----------

La mise à jour se fait dans le même dossier, avec ``git`` : aucune archive à télécharger, aucun second dossier.

.. code:: console

    cd ~/geonature
    python3 install/install.py update X.Y.Z --dry-run   # liste les étapes
    python3 install/install.py update X.Y.Z

Avant toute modification, la commande sauvegarde dans ``~/geonature_backups/<date>_<version>/`` la base (``pg_dump``), les fichiers ``config/*.toml`` et ``*.ini``, ``custom/``, ``environ`` et le commit installé. Le dossier ``backend/media`` n'est pas copié : il n'est pas modifié par la mise à jour.

Les fichiers versionnés ne doivent pas avoir été modifiés localement (les fichiers de ``config/`` et ``custom/`` ne sont pas concernés). La mise à jour est réservée aux versions 2.15.0 et supérieures ; pour une version plus ancienne, passez d'abord à la 2.15.0 avec la procédure de cette version.

Si la mise à jour est interrompue, relancez la même commande pour la reprendre.

Retour arrière
^^^^^^^^^^^^^^

.. code:: console

    python3 install/install.py update --rollback

Le code revient au commit enregistré avant la mise à jour et les fichiers de configuration sont restaurés. **La base de données n'est pas modifiée** : après une migration, l'ancienne version peut ne pas démarrer avec le nouveau schéma. Dans ce cas, restaurez aussi la base :

.. code:: console

    python3 install/install.py update --rollback --restore-db --confirm-restore NOM_BASE

Cette restauration remplace la base par la sauvegarde et **perd les données saisies depuis**. Le nom exact de la base est exigé pour la lancer.
