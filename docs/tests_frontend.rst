Tests frontend
--------------

Cette documentation a pour objectif d'expliquer comment écrire des tests pour 
le frontend de GeoNature.

L'écriture de tests frontend dans GeoNature se base sur l'outil `Cypress <https://www.cypress.io/>`_ dont il est necessaire de maitriser et comprendre le fonctionnement.

Le lancement des tests cypress nécessite la présence de données en base. Les branches alembic suivantes doivent être montées : `occtax-samples-test`, `occhab-samples`. Le contenu du fichier `config/test_config.toml` doit également être utilisé.



Principe de base ; Un test doit être concis. 
Il vaut mieux écrire plusieurs tests pour tester différentes configurations plutôt qu'un seul les testant toutes d'un coup. 
Cela permet d'identifier plus précisément le test qui n'a pas fonctionné.

Rédaction
*********

La rédaction des fichiers de tests se fait dans le dossier frontend/cypress/e2e.

Structure
"""""""""

La nomenclature des fichiers de test est XXXXXXX-spec.js (XXXX correspondant au nom du module testé). 

Afin d'améliorer la lisibilité des fichiers de test si un module contient beaucoup de tests il est nécessaire de séparer les tests end to end en plusieurs fichiers et les placer dans un dossier portant le nom du module.

Exemple
"""""""

.. code:: bash

    e2e
    ├── import
    │   ├── all-steps-spec.js
    │   └── list-search-spec.js

Dans chaque fichier la structure des tests est de la forme

- une description
    - test
    - test
    - ...  
    
Exemple
"""""""

.. code-block:: javascript

    describe("description général de la partie testée", () => {

        it('description du test 1', () => {
            //contenu du test 1
        })

        it('description du test 2', () => {
            //contenu du test 2
        })

    })

Afin d'homogénéiser les descriptions des tests il est établi que l'on nomme un test en anglais en commençant par should. 

Exemple
"""""""

.. code:: javascript

    it('should change the state',() => ... 

Implémentation 
""""""""""""""

La réalisation des tests frontend passe par la sélection des objets HTML du DOM.
A fin de rendre ces sélections plus propres, on peut ajouter des tags HTML dans le dom.
Angular et Cypress suggèrent l'ajout de tags de ce type:

- data-qa
- test-qa
- data-test

Il est recommandé d'utiliser un nom explicite pour éviter toutes confusions.

Exemple
"""""""

.. code:: HTML

    <button data-qa="import-list-new">New</button>

Voir https://docs.cypress.io/guides/references/best-practices#Selecting-Elements pour les bonnes pratique de sélection d'éléments.


Lancement
*********

Pour lancer Cypress et executer les tests à la main il faut exécuter la commande (nécessite qu'une instance GeoNature fonctionne (backend+frontend)):

.. code:: bash

    npm run cypress:open

Pour lancer les test en mode automatique, il faut exécuter la commande (utilisée dans l'intégration continue (GitHub Action)):

.. code:: bash

    npm run e2e:ci && npm run e2e:coverage
