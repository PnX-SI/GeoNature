Cette section de la documentation concerne l'implémentation d'un utilisateur-lecteur pour votre instance GeoNature. 

Etapes :

1/ UsersHub :
   - Aller dans la section `Utilisateurs` 
   - Créer un utilisateur 
   - Définir un identifiant et un mot de passe (par défaut utilisateur 'public' et mot de passe 'public')
   - Aller ensuite dans la section `Applications`
   - Pour GeoNature, cliquer sur le premier icône 'Voir les membres'
   - Cliquer sur ajouter un rôle 
   - Choisir l'utilisateur juste créé
   - Attribuer le rôle 1, 'lecteur' 

2/ Configuration GeoNature : 
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

3/ GeoNature 

   - Se connecter à GeoNature avec un utilisateur administrateur
   - Aller dans le module Admin
   - Cliquer sur 'Gestion des permissions'
   - Choisissez l'utilisateur sélectionné 
   - Editer le CRUVED pour chacun des modules de l'instance. Passer à 0 tous les droits et tous les modules devant être supprimés. Laisser '3' pour les modules d'intérêt. 
