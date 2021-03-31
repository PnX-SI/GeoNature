Cette section de la documentation concerne l'implémentation d'un utilisateur-lecteur pour votre instance GeoNature. 

Etapes :

Dans UsersHub :
   - Aller dans la section `Utilisateurs` 
   - Créer un utilisateur 
   - Définir un identifiant et un mot de passe (par défaut utilisateur 'public' et mot de passe 'public')

Dans GeoNature : 
   - Reporter identifiant et mot de passe dans le fichier de configuration de GeoNature 
``` 
$ cd config
$ nano geonature_config.toml
```
`PUBLIC_LOGIN = 'public'`  
`PUBLIC_PASSWORD = 'public'`  

   - Mettre à jour la configuration de GeoNature 
```
$ source backend/venv/bin/activate
$ geonature update_configuration
```

A ce moment là, cet utilisateur a tous les droits sur GeoNature.
Il s'agit donc de gérer ses permissions dans GeoNature même. 

Pour ce faire, connectez vous à GeoNature : 
