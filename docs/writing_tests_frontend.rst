Ecrire des tests
================

Cette documentation a pour objectif d'expliquer comment écrire des tests pour 
le frontend de GeoNature.

L'écriture de tests frontend dans GeoNature se base sur l'outil `Cypress <https://www.cypress.io/>`.
Il est necessaire de maitriser et comprendre le fonctionnement de Cypress pour pouvoir écrire les tests.

Rédaction
*********

La rédaction des fichiers de tests se fait dans le dossier frontend/cypress/integration.

La réalisation des tests frontend passe par la sélection des objets HTML du DOM.
A fin de rendre ces sélections plus propres, on peut ajouter des tags HTML dans le dom.
Angular suggère l'ajout de tags de ce type:

- data-qa
- test-qa
- data-test

Lancement
*********

Pour lancer Cypress est executer les tests à la main il faut exécuter la commande:

.. code-block::

    $ npm run cypress:open

Pour lancer les test en mode automatique, il faut exécuter la commande:

.. code-block::

    $ e2e:ci && e2e:coverage