# Remarques sur les tests au niveau de l'import

## Notifications

- pas de tests autour des notifications
- suppression d'un import --> pas de notification
- si import supprimé, le lien de la notification mène à une erreur pas compréhensible

## Liste Import

- Le test sur le tri de la colonne "id" ne fonctionne pas (mis sur skip) --> à résoudre coté backend
- la lib de tableau utilisé est obsolète, non maintenue.
- le statut de l'import n'apparait pas sur la liste

## Import

### LocalStorage

La persistence d'une saisie à l'autre de certain paramètres (JDD, CRS, mappings) de l'import pourrait être une idée.

### Seulement "Annuler et supprimer" ou "Enregistrer et quitter"

- Manque "Annuler et quitter" (reviens à la liste sans sauver les changements, et sans supprimer l'import)
- Manque "Annuler les modifications" (reste sur la page, en rechageant les paramètres par défault)
- Annuler et supprimer: il manque une modal d'avertissement / confirmation: (attention, ça va supprimer l'import et les données importées). En l'état, ça se supprime trop immédiatement.

### Permissions

Si on le droit de créer un import, mais pas de la supprimer, on a quand même le bouton de suppression.
Combinaison des permissions gérée un peu au cas par cas.

### Stepper

- MAE un peu alembiquée. complexe à manipuler, source d'erreur d'état.

### Step 0 (destinations)

- le menu déroulant pourrait être remplacé par des boutons sélectionables en exclusion mutuelle
  --> Sélection en 1 click plutôt que deux
  --> plus joli visuellement (avec logo de la destination, etc.)

### Step 0 (destinations) and Step 1 (upload)

- ça donne envie de fusionner ces deux étapes, avec une dépendance entre le choix de la destination et la liste des JDD.

## Import - Step 1 - upload du fichier

### Champs JDD

Si cette étape n'est pas validée, l'import n'est pas créé --> pas de sauvegarde des champs.
Ca ne saute pas aux yeux comme fonctionnement.

### **vide** vs **invalide**

Les deux cas "fichier vide" et "fichier invalide" ne se comportent pas de la même façon:

- fichier vide: toast d'erreur + "Suivant" activé
- fichier invalide: pas de toast d'erreur + "Suivant" désactivé

> A confirmer: les chemins apparents de gestions d'erreur backend ne reflètent pas la gestion réelle de l'erreur.

### Autre type de fichier

Il n'y a pas de check sur l'extension du fichier

Le seul control est réalisé par la valeur de l'attribut **accept** de la balise **input**.
Pas de check à l'envoi, pas de check à réception. On peut envoyer un PDF, ça passe.

## Import - step 2 - configuration du fichier

- Pas de test de cette étape.

### Sauvegarde des champs

L'import est créé. Quand on revient à la liste, on le retrouve bien.
Cependant, les champs saisis ne sont jamais saisis.

## Import - step 3 - mapping des champs

### Gestion des models utilisés

Mapping associé à un import en y copiant le contenu. Permet de s'affranchir de la complexité de l'historisation d'un mapping. Mais, impossible de remonter le nom du mapping utilisé. Ca devrait être largement améliorable. Avec du versioning des mapping par exemple.
En tout cas, l'info disparait dès qu'on quitte la page.

Au minimum du minimum: ajout de metadonnées au mapping "nom du mapping, date et heure"

### Etat du code "work in progress"

Tentative de fusion visible entre mapping des champs et mapping des nomenclatures (front et back).
Non terminée. Résulte en beaucoup de duplication entre ces pages, et un manque de lisibilité.

## Import - step 4 - mapping des nomenclatures

Voir step 3 mapping des nomenclatures

- état initial: le modèle "Nomenclatures SINP (labels)" semble être chargé par défault, mais non indiqué dans le menu.
  Pas clair. Et en plusça propose de sauver le mapping, alors qu'il est chargé par défault.

## Import - rapport

- Manque de nuances "En cours" --> en création, en cours, etc.
- Si en cours de paramétrisation--> envie d'avoir un chemin de navigation vers l'édition de l'import
