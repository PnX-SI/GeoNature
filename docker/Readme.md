# Docker pour Geonature

## Prérequis
### Installation de docker
Les installations de docker engine et docker compose se font en suivant le guide officiel:
- Docker engine: https://docs.docker.com/engine/install/
- Docker compose: https://docs.docker.com/compose/install/ 

### Infrastructure
Le fonctionnement de GeoNature et des services satellites (TaxHub, UsersHub...) nécessite la mise en place d'un service 
de base de données, ainsi qu'un reverse proxy permettant de cibler les différentes applications.

Ces services sont disponibles sur le repo GitHub: 
https://github.com/PnX-SI/GeoNature-Docker-services


## Installation

### GeoNature sur un environnement local (Développement)

#### Backend
Pour utiliser GeoNature dans un environnement local, il suffit de se rendre à la racine du projet et d'exécuter la ligne
suivante pour lancer le backend de GeoNature: 
```bash
docker-compose --env-file .env.local -f docker-compose.local.yml -p backend up --build
```
L'API est alors servie sur **localhost/geonature/api**

Notes d'attention:
- L'installation des données intitiales de GeoNature est paramétrable via le champ ```INSTALL_DB``` présent dans le 
fichier .env.local. Si passé à true, il sera automatiquement mis à jour lors de l'exécution du script ci-dessus pour 
éviter les ajouts répétés

#### Frontend
Une fois le backend de GeoNature lancé, les fichiers de configuration du frontend auront été mis à jour. 
Il est alors possible de lancer le frontend en exécutant la commande suivante, toujours à la racine du projet:
```bash
docker-compose --env-file .env.local -f docker-compose-front.yml up -p frontend --build
```
Le frontend sera alors disponible sur **localhost:4200**

### Installation en production
Pour une installation en production, il est au prélable nécessaire de construire les images docker.
#### Build
Pour le backend, à la racine du projet:

```bash
docker build -f docker/backend/DockerFile -t ${IMAGE_NAME} . 
```
Pour le frontend, à la racine du projet:

```bash
docker build -f docker/frontend/DockerFile -t ${IMAGE_NAME} . 
```

Ces images pourront ensuite être poussées sur un docker repository.

#### Lancement des services
Pour lancer les deux services, se rendre dans le répertoire des docker-compose.yml.

Les endpoint des différents services sont paramétrables via les variables d'environnement, présentes dans le fichier 
.env (on pourra s'inspirer des fichiers .env.sample pour les construire) 
Parmis elle: 
- HOST qui représente le domaine sur lequel le service sera exposé (.env front et back)
- HOST_FRONT qui permet d'indiquer au backend la position du frontend (.env backend)
- GEONATURE_PATH qui est le chemin d'accès de l'api (.env backend)
- GEONATURE_PREFIX qui est le chemin d'accès du site internet (souvent /geonature .env frontend)

Il suffit ensuite d'exécuter les commandes suivantes: 

Pour le backend, depuis le répertoire du docker-compose correspondant:
```bash
docker-compose --env-file .env -p backend up -d
```

Pour le frontend, depuis le répertoire du docker-compose correspondant:
```bash
docker-compose --env-file .env -p frontend up -d
```
