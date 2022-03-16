Écrire des tests
================

Cette documentation a pour objectif d'expliquer comment écrire des tests pour 
le backend de GeoNature.

Un test se décompose en général en 3 étapes :

- **Arrange** : prépare tous les éléments avant l'exécution de la portion de 
  code à tester (en général une fonction)
- **Act** : exécute cette portion de code
- **Assert** : vérifie que l'exécution s'est bien déroulée

Il est toujours utile de distinguer dans le code ces 3 étapes en ajoutant un 
commentaire ou une séparation entre elles.

Enfin un test doit être concis, il vaut mieux écrire plusieurs tests pour 
tester différentes configurations plutôt qu'un seul les testant toutes d'un 
coup. Cela permet d'identifier plus précisément le test qui n'a pas fonctionné.

Backend
-------

Introduction
^^^^^^^^^^^^

Comme spécifié dans la partie Développement, la librairie Python PyTest est 
utilisée pour rédiger des tests. Elle permet de : 

- disposer d'un framework de redaction de tests en se basant notamment sur 
  l'instruction ``assert``
- écrire des objets ou des portions de code réutilisables : les ``fixtures``
- lancer un même test avec des configurations différentes
- faire de nombreuses autres choses décrites dans la 
  `documentation PyTest <https://docs.pytest.org/>`_ 

Utilisation
^^^^^^^^^^^

Les tests sont des fonctions pouvant être regroupées dans des classes. La 
nomenclature est la suivante : 

- Les tests doivent être situées dans un dossier nommé tests (dans 
  GeoNature, ils sont situés dans ``backend/geonature/tests``)
- Le nom de chaque fichier Python contenant des tests doit commencer par 
  ``test_``
- Chaque classe comprenant des tests doit commencer par ``Test`` (pas de 
  underscore car la norme PEP8 impose un nom de classe en CamelCase)
- Chaque nom de test (donc de fonction) doit commencer par ``test_`` pour 
  pouvoir être détecté automatiquement par PyTest

Fixtures
^^^^^^^^

Les fixtures de PyTest peuvent permettre de nombreuses choses comme expliqué 
dans la documentation PyTest sur `les fixtures <https://docs.pytest.org/explanation/fixtures.html#about-fixtures>`_.

Dans GeoNature elles sont, en général, utilisées pour définir des objets 
réutilisables comme des utilisateurs en base de données pour tester les droits, des observations fictives de taxon pour tester des routes de la synthèse ou 
encore des éléments non présents en base pour tester que le code voulant les 
récupérer ne plante pas etc.

Elles sont aussi utilisées pour fournir un contexte à un test. Par exemple, la 
fixture ``temporary_transaction`` permet de ne pas sauvegarder ce qui sera 
inséré/supprimé/modifié dans la base de données pendant le test.

.. note ::

  La plupart des fixtures sont rassemblées dans 
  ``backend/geonature/tests/fixtures.py``, il est important de regarder 
  lesquelles y sont définies avant d'en écrire d'autres !

Enfin, les fixtures peuvent aussi être définies directement dans le fichier
Python du test. Elles sont définies comme suit :

.. code-block:: python

    # Obligatoire pour accéder au décorateur
    import pytest

    # Définit une fixture qui renverra 2
    @pytest.fixture()
    def my_fixture():
      return 2

Et s'utilisent comme suit :

.. code-block:: python

    # On passe directement la fixture en argument du test. Il est
    # nécessaire de l'importer si elle n'est pas définie dans le même fichier
    # Ce test n'est pas dans une classe (donc pas de self)
    def test_ma_fonction_a_tester(my_fixture):
      result = my_fixture

      # On vérifie que la fixture retourne la bonne valeur
      assert result == 2

Il est aussi possible de définir un ``scope`` d'une fixture comme ceci :

.. code-block:: python

    # Définit une fixture qui renverra 2 mais qui sera exécutée qu'une
    # seule fois par classe (une classe regroupe plusieurs tests) au
    # lieu d'une fois par test. Il est possible aussi de définir ce 
    # scope au module ou à la function
    @pytest.fixture(scope="class")
    def my_fixture():
      return 2

Exemple
^^^^^^^

Voici un exemple de test qui a été fait dans GeoNature

.. code-block:: python

    def test_get_consistancy_data(self):
        synthese_record = Synthese.query.first()

        response = self.client.get(
            url_for("gn_profiles.get_consistancy_data", 
                    id_synthese=synthese_record.id_synthese))

        assert response.status_code == 200

Ce test est situé dans une classe (le ``self`` est donc obligatoire). Ce test 
vérifie que la route ``gn_profiles.get_consistancy_data`` fonctionne bien avec 
un ``id_synthese`` pris dans la base de données. Le ``assert`` est directement 
interprété par PyTest et le test sera en erreur si la condition n'est pas 
respectée. Il est possible d'écrire plusieurs ``assert`` pour un même test !

Enfin, une fixture a été utilisée au niveau de la classe pour rendre accessible 
l'attribut ``client`` de la classe, utile pour faire des requêtes http 
notamment. 

Dans GitHub
^^^^^^^^^^^

Dans le dépôt de GeoNature sur GitHub, tous ces tests sont exécutés 
automatiquement pour chaque commit d'une pull request grâce à PyTest et à 
GitHub Actions. Ils permettent donc de vérifier que les modifications apportées 
par les développeurs ne changent pas le statut des tests et permettent donc aux 
mainteneurs du projet de disposer d'une meilleure confiance dans la pull 
request. Un coverage est aussi exécuté pour s'assurer que les nouveaux 
développements sont bien testés.

Coverage
^^^^^^^^

Le coverage est un système permettant de quantifier les lignes de code 
exécutées par le test. Exemple rapide :

.. code-block:: python
    
    # Définition d'une fonction quelconque
    def ma_fonction_a_tester(verbose=False):
        if verbose:
            return "blablabla"
        return "blabla"

    # Définition d'un possible test associé
    def test_ma_fonction_a_tester():
        # Arrange
        verbose = True

        # Act
        message = ma_fonction_a_tester(verbose=verbose)

        # Assert 
        assert message == "blablabla"

Dans cet exemple, un seul test a été écrit où ``verbose = True`` donc la 
ligne ``return "blabla"`` ne sera jamais exécutée par un test. Donc sur les 3 
lignes de la fonction, seules 67% des lignes ont été exécutées donc le 
coverage serait d'environ (le calcul est plus complexe) 67%. Il faudrait 
donc écrire un nouveau test avec ``verbose = False`` dans ``Arrange`` pour 
obtenir 100% de coverage sur la fonction ``ma_fonction_a_tester()``.

.. warning::

    Un coverage de 100% ne garantit pas un code sans bug ! Il permet plutôt 
    d'être plus confiant dans la modification/refactorisation de lignes de code et dans le développement de nouvelles fonctionnalités.


Dans VSCode
^^^^^^^^^^^

Il est possible d'installer `l'extension Python <https://marketplace.visualstudio.com/items?itemName=ms-python.python>`_ pour facilement lancer et 
debugger un ou plusieurs tests directement depuis VSCode. Il suffit juste de 
changer le fichier ``settings.json`` dans le dossier ``.vscode`` de votre 
projet avec le code suivant pour qu'il soit compatible avec GeoNature : 

.. code-block:: json

    {
      "python.testing.pytestArgs": [
        "/chemin/vers/geonature/backend/geonature/tests"
      ],
      "python.testing.unittestEnabled": false,
      "python.testing.pytestEnabled": true
    }

Exécuter un ou plusieurs test(s) en ligne de commande
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Pour exécuter les tests de GeoNature placez vous à la racine du dossier où est 
installé GeoNature et exécutez la commande suivante : 

.. code-block::

    pytest backend/geonature/tests/.

Assurez vous d'avoir bien installé les librairies de développement avant 
(en étant toujours placé à la racine de l'installation de GeoNature) :

.. code-block::

    pip install -e .[tests]

Pour exécuter un seul test l'option ``-k`` est très utile : 

.. code-block::

    pytest backend/geonature/tests/test_gn_meta.py -k 'test_uuid_report_with_dataset_id'

Ici, elle exécutera uniquement le test ``test_uuid_report_with_dataset_id`` du 
ficher ``test_gn_meta.py``.

Enfin, pour générer le coverage en même temps que les tests :

.. code-block::

    pytest backend/geonature/tests/. --cov --cov-report xml


Le format ``xml`` est interprété par l'extension VSCode `Coverage Gutters <https://marketplace.visualstudio.com/items?itemName=ryanluker.vscode-coverage-gutters>`_ qui fournie directement dans le code les lignes couvertes et celles non parcourues par le test.

Si vous souhaitez voir le coverage directement depuis le navigateur, il est 
possible de générer le coverage au format html en remplaçant ``xml`` par 
``html``.
