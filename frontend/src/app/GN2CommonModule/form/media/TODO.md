
# BUGS
- ~~bug cancel change form values~~
- ~~**Error DOM exception??????**~~
- ~~**pas de bug fake_path securite du navigateur** file component + css~~
- dynamicForm File 2* update ????

# ~~SQL~~
- ~~media_temp~~
- ~~besoin de media temp ????~~

# Python

## ~~Model~~
- ~~ajouter media taxon~~

## Media
- *repo / routes PATCH POST (compatibilité chiro????) ???*
- cohérence url / path type de media
- sync media temp (supprimer si media temp > 24h)
- sync medias (si objet associé n'existe plus => supprimer le media)
- si fichier associé n'est plus présent -> supprimer le media
- sync medias qui fait les deux ?
  - SQL
    - ~~ajouter la date pour les medias~~
    - ~~ajouter trigger sur la date~~
    - fonction test UUID
    - requete pour savoir si UUID existe plus
    - delete
    - trigger sur toute action sur les médias ??? 
- requete (sql text pour l'instant) pour avoir la liste de medias (dans les deux cas)
- delete a partir de cette liste  

# Table location
- ~~route pour obtenir id_table_location depuis shema_name.table_name~~

## OccTax
- gerer medias apres le commit


# Front

# Forms
- translate !!

# Media
- service:
  - ~~cache pour idTableLocation !! impt~~
- prendre en compte les type media, adapter le formulaire (condition+++++)
- ~~passer bouttons etc dans media.component~~
- ~~cohérence avec OccTax~~
  - ~~croix à droite~~
  - ~~mat-expension-panel~~
  - ~~valider quand upload à faire et freezer le reste ??? upload au choix du fichier (non bloquant et possibilité annulation)~~ 

## Test Media

### ~~Medias temps~~
- ~~creer media temps~~
  - ~~media service~~
  - ~~report progress~~

## Occtax
-ajout composant médias
