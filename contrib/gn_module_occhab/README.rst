Module Occhab
=============

Module GeoNature de saisie et de synthese basé sur le standard Occurrence d'habitat du SINP: http://standards-sinp.mnhn.fr/standard-doccurrences-habitats-v1-0/.

Le module offre les fonctionnalité suivantes:

- Consultation (carte-liste) des stations et affichage de leurs habitats
- Recherche (et export) des stations par jeu de données, habitats ou dates
- Saisie d'une station et de ses habitats
- Possibilité de saisir plusieurs habitats par station
- Saisie des habitats basée sur une liste pré-définie à partir d'Habref. Possibilité d'intégrer toutes les typologies d'habitat ou de faire des listes réduites d'habitats
- Possibilité de charger un fichier GeoJson, KML ou GPX sur la carte et d'utiliser un de ses objets comme géométrie de station
- Mise en place d'une API Occhab (Get, Post, Delete, Export stations et habitats et récupérer les valeurs par défaut des nomenclatures)
- Calcul automatique des altitudes (min/max) et de la surface d'une station
- Gestion des droits (en fonction du CRUVED de l'utilisateur connecté)
- Définition des valeurs par défaut dans la BDD (paramétrable par organisme)
- Possibilité de masquer des champs du formulaire
