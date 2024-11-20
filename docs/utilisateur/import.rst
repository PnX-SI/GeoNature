Import de données
-----------------

Depuis le 2.15, GeoNature permet aussi d'importer des données depuis un fichier CSV dans deux modules:

- Synthèse
- Occhab

Créer un import
"""""""""""""""
Le module permet de traiter un fichier CSV 
(GeoJSON non disponible dans la v2 pour le moment) sous toute
structure de données, d'établir les correspondances nécessaires entre
le format source et le format de la synthèse, et de traduire le
vocabulaire source vers les nomenclatures SINP. Il stocke et archive les
données sources et intègre les données transformées dans la synthèse de
GeoNature. Il semble préférable de prévoir un serveur disposant à minima
de 4 Go de RAM.

1.  Une fois connecté à GeoNature, accédez au module Imports. L'accueil
    du module affiche une liste des imports en cours ou terminés, selon
    les permissions de l'utilisateur connecté. Vous pouvez alors finir un
    import en cours, ou bien commencer un nouvel import.

    .. image :: https://geonature.fr/docs/img/import/gn_imports-01.jpg


2.  Choisissez à quel JDD les données importées vont être associées. Si
    vous souhaitez les associer à un nouveau JDD, il faut l'avoir créé
    au préalable dans le module Métadonnées.

.. image :: https://geonature.fr/docs/img/import/gn_imports-02.jpg

3.  Chargez le fichier CSV (GeoJSON non disponible dans la v2 pour le moment) à importer.

.. image :: https://geonature.fr/docs/img/import/gn_imports-03.jpg

4.  Mapping des champs. Il s'agit de faire correspondre les champs du
    fichier importé aux champs de la Synthèse (basé sur le standard
    "Occurrences de taxons" du SINP). Vous pouvez utiliser un mapping
    déjà existant ou en créer un nouveau. Le module contient par défaut
    un mapping correspondant à un fichier exporté au format par défaut
    de la synthèse de GeoNature. Si vous créez un nouveau mapping, il
    sera ensuite réutilisable pour les imports suivants. Il est aussi
    possible de choisir si les UUID uniques doivent être générés et si
    les altitudes doivent être calculées automatiquement si elles ne
    sont pas renseignées dans le fichier importé.

.. image :: https://geonature.fr/docs/img/import/gn_imports-04.jpg

5.  Une fois le mapping des champs réalisé, au moins sur les champs
    obligatoires, il faut alors valider le mapping pour lancer le
    contrôle des données. Vous pouvez ensuite consulter les éventuelles
    erreurs. Il est alors possible de corriger les données en erreurs
    directement dans la base de données, dans la table temporaire des
    données en cours d'import, puis de revalider le mapping, ou de
    passer à l'étape suivante. Les données en erreur ne seront pas
    importées et seront téléchargeables dans un fichier dédié à l'issue
    du processus.

.. image :: https://geonature.fr/docs/img/import/gn_imports-05.jpg

7.  Mapping des contenus. Il s'agit de faire correspondre les valeurs
    des champs du fichier importé avec les valeurs disponibles dans les
    champs de la Synthèse de GeoNature (basés par défaut sur les
    nomenclatures du SINP). Par défaut les correspondances avec les
    nomenclatures du SINP sous forme de code ou de libellés sont
    fournies.

.. image :: https://geonature.fr/docs/img/import/gn_imports-06.jpg

8.  La dernière étape permet d'avoir un aperçu des données à importer
    et leur nombre, avant de valider l'import final dans la Synthèse de
    GeoNature.

.. image :: https://geonature.fr/docs/img/import/gn_imports-07.jpg



Modifier un import
""""""""""""""""""


Supprimer un import
"""""""""""""""""""

