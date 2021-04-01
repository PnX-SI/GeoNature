# Changement config

- l'idée est de ne plus avoir besoin de refaire le build de l'application 

- reprise de travaux effectués sous feat/ngx-config
- ajout d'une gestion de la config par api
  - pour une mise à jour effective sans relancer l'application  

## I - Changer emprise de la carte dans `geonature_config.toml` et voir les effets - (Fait)

### Installation / commandes

- [x] création d'un fichier `api.config.json` à partir de `geonature_config.toml`
  - [x] fonction manage_frontend 
  - [x] qui contient l'api de geonature pour accéder à la config 
  - [x] au démarrage de l'application
  - [x] copie du fichier dans `frontend/src/assets/config/` **et** `frontend/dist/assets/config/` 

- Exemple de `frontend/src/assets/config/api.config.json` :
```
"http://localhost/geonature/api"

```

### Frontend

- [x] configModule
  - [x] charge le fichier avec url API GeoNature
  - [x] appelle l'api de config
  - [x] toute la config (application et modules (indexés par module_code)) est disponible depuis le service config

### Backend

- [x] api config
  - [x] config générale (comme app.config.ts)
  - [x] configuration des modules (module.config.ts)
  - [x]recharge les config depuis les fichiers à l'appel de l'api
    - [x] avantage par rapport à la creation de fichiers

## II - Passez à la nouvelle config partout (A faire)

- Geonature
- Modules coeur de geonature
- autres modules ...
- éditer les fichiers de config depuis le site ??
  - comment sécuriser / cacher les données sensibles ? 

# III - fichiers custom

- supprimer scss ??
- frontend/src/custom/components/footer/footer.component.ts
- frontend/src/custom/components/introduction/introduction.component.ts
- frontend/src/custom/custom.scss
- autres
  - logo ?? 
