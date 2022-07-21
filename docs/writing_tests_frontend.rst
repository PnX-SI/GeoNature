Ecrire des tests
================

Cette documentation a pour objectif d'expliquer comment écrire des tests pour 
le frontend de GeoNature.

L'écriture de tests frontend dans GeoNature se base sur l'outil `Cypress <https://www.cypress.io/>`_ dont il est necessaire de maitriser et comprendre le fonctionnement.

Principe de base ; Un test doit être concis. 
Il vaut mieux écrire plusieurs tests pour tester différentes configurations plutôt qu'un seul les testant toutes d'un coup. 
Cela permet d'identifier plus précisément le test qui n'a pas fonctionné.

Rédaction
*********

La rédaction des fichiers de tests se fait dans le dossier frontend/cypress/integration.

Structure
^^^^^^^^^

La nomenclature des fichiers de test est XXXXXXX-spec.js (XXXX correspondant au nom du module testé). 

Dans chaque fichier la structure des tests est de la forme

- une description
    - test
    - test
    ...  
    
Exemple
^^^^^^^

.. code-block:: js

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
^^^^^^^ 
.. code-block:: js

    it('should change the state',() => ... 

Implémentation 
^^^^^^^^^^^^^^

La réalisation des tests frontend passe par la sélection des objets HTML du DOM.
A fin de rendre ces sélections plus propres, on peut ajouter des tags HTML dans le dom.
Angular suggère l'ajout de tags de ce type:

- data-qa
- test-qa
- data-test

Exemple
^^^^^^^

.. code-block:: HTML

    <div data-qa="text_de_selection">

Lancement
*********

Pour lancer Cypress et executer les tests à la main il faut exécuter la commande (nécessite qu'une instance GeoNature fonctionne (backend+frontend)):

.. code-block:: bash

    $ npm run cypress:open

Pour lancer les test en mode automatique, il faut exécuter la commande (utilisée dans l'intégration continue (GitHub Action)):

.. code-block:: bash

    $ npm run e2e:ci && npm run e2e:coverage
