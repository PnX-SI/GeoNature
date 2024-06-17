# Remarques sur les tests au niveau de l'import

## Upload

### **vide** vs **invalide**
Les deux cas "fichier vide" et "fichier invalide" ne se comportent pas de la même façon:

- fichier vide: toast d'erreur + "Suivant" activé
- fichier invalide: pas de toast d'erreur + "Suivant" désactivé

### Autre type de fichier

Il n'y a pas de check sur l'extension du fichier

Le seul control est réalisé par la valeur de l'attribut **accept** de la balise **input**.
Pas de check à l'envoi, pas de check à réception. On peut envoyer un PDF, ça passe. 

### Type de fichier filtré par la config

Il s'agirait ici de tester le bon comportement de la balise **input**, avec son attribut **accept**. 

Ce n'est pas trivial, et peut être considéré ok.
