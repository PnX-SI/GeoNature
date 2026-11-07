Scripts de deploiement GeoNature sur un serveur
===============================================

Script de test de deploiement, n'utiliser qu'en developpement

- Utilise la librairie Fabric pour deployer un GeoNature sur un serveur distant
- Le serveur doit autoriser la connexion en SSH en clé privé/clé publique (renseigne le fichier .ssh/authorized_key) sur le serveur distant 
- Désampler et remplir le fichier config.py

Fonctionnement
--------------

``python3 run.py deploy`` lance ``install/get-geonature.sh`` sur le serveur (version ``GN_VERSION``, clone superficiel, sans question), écrit un ``install/install.toml`` à partir de ``DOMAIN``, ``DB_NAME`` et ``DROP_DB``, puis lance ``install/install.py``. Le serveur doit autoriser ``sudo`` sans mot de passe.

``python3 run.py clean`` exécute ``install.py uninstall --yes`` (services systemd et Apache) puis supprime le dossier. La base de données n'est jamais supprimée par cette commande.
