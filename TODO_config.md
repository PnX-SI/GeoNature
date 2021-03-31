# Changement config

- l'idée est de ne plus avoir besoin de refaire le build de l'application 

- reprise de travaux effectués sous feat/ngx-config
- ajout d'une gestion de la config par api
  - pour une mise à jour effective sans relancer l'application  

## I - Changer emprise de la carte dans `geonature_config.toml` et voir les effets

### Installation / commandes

- création d'un fichier api.config.json à partir de geonature_toml.ini
  - qui contient l'api de geonature pour accéder à la config 

### Frontend

- configModule
  - charge le fichier avec url API GeoNature
  - appelle l'api de config
  - changer APIConfig avec le service

### Backend

- api config
  - config générale (comme app.config.ts)
  - configuration des modules (module.config.ts)
  - recharge les config depuis les fichiers à l'appel de l'api
    - avantage par rapport à la creation de fichiers

## II - Passez à la nouvelle config partout

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
