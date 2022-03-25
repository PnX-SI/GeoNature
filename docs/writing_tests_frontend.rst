Ecrire des tests
================

Cette documentation a pour objectif d'expliquer comment écrire des tests pour 
le frontend de GeoNature.

L'écriture de tests frontend dans GeoNature se base sur l'outil `Cypress <https://www.cypress.io/>`.
Il est necessaire de maitriser et comprendre le fonctionnement de Cypress pour pouvoir écrire les tests.

La rédaction des fichiers de tests se fait dans le dossier frontend/cypress/integration.

Pour lancer Cypress est executer les tests à la main il faut exécuter la commande:

.. code-block:: bash
    npm run cypress:open

pour lancer les test en mode automatique, il faut exécuter la commande:

.. code-block:: bash
    e2e:ci && e2e:coverage