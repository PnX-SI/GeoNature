.. raw:: html

    <style> .red {color:red;font-weight:bold}img{margin-bottom:10px}</style>

.. role:: red

Import
------

Depuis sa version 2.15, le module Import a été intégré à GeoNature et il permet d'importer des données depuis un fichier CSV dans deux modules :

- Synthèse
- Occhab

Créer un import
"""""""""""""""

Pour réaliser un import dans une des destinations de GeoNature, vous devez :

1.  Une fois connecté à GeoNature, accédez au module Import. L'accueil
    du module affiche la "liste des imports" en cours ou terminés, selon
    les permissions de l'utilisateur connecté. Vous pouvez alors finir un
    import en cours, commencer un nouvel import ou supprimer un import.

    .. image:: images/import/import_steps/00_imports_list.png

2. Pour commencer un nouvel import, cliquez sur le bouton "+" en bas de la liste des imports. Dans la fenêtre qui s'affiche, sélectionner la destination (e.g. Occhab, Synthèse) de votre import.
   
    .. image:: images/import/import_steps/01_destination_choice.png

3.  Une fois la destination choisie, vous serez redirigé vers une nouvelle page. 
    Dans ce nouveau formulaire, choisissez le jeu de données qui sera associé aux données importées.  
    Puis, téléverser le fichier contenant les données que vous souhaitez importer. À ce jour, seul le format de fichier CSV est accepté par GeoNature. Une fois les 
    champs remplis, cliquez sur le bouton "Suivant". 

    .. note:: 
            Si aucun jeu de données n'apparait dans la liste déroulante, vérifier que le jeu de données souhaité est bien activé et associé à la destination souhaitée.

    .. image:: images/import/import_steps/02_upload_file.png

4.  Dans ce nouveau formulaire, indiquez les paramètres de lecture de votre fichier. Plusieurs
paramètres seront automatiquement détectés par GeoNature. Une fois, les champs remplis, cliquez sur le bouton "Suivant". 

  .. note::
    
    A partir de cette étape, il est possible d'enregistrer votre import et le reprendre plus tard depuis la liste d'import.
    
  .. image:: images/import/import_steps/03_parameter_selection.png

5.  Maintenant que le fichier est téléversé, il s'agit de faire correspondre les champs du fichier importé aux champs accessibles d'une (ou plusieurs) entité.s (e.g. Station).
    Pour vous aider dans la saisie, vous pouvez utiliser un mapping existant ou créer un nouveau. Lors de la validation du formulaire, il sera possible d'enregistrer votre mapping pour pouvoir le réutiliser plus tard. 
    Une fois, la mise en correspondance terminée, cliquez sur le bouton "Suivant".

    .. warning::
        Dans le cas où la destination comporte plusieurs entités, les champs requis pour une entité ne seront affichés uniquement si un des champs de l'entité est remplie (hors identifiant UUID).

    .. image:: images/import/import_steps/04_01_mapping_cols.png

    .. note::
        Chaque destination contient un mapping par défaut. Ce dernier s'appuie sur les fichiers exportés par le module depuis l'interface de saisie.

        À la fin du formulaire, vous pouvez visualiser le nombre de correspondances effectuées
        et les colonnes du fichier source qui n'ont pas été utilisées.
    
    .. image:: images/import/import_steps/04_02_mapping_cols_validate.png

6.  Si des champs de nomenclatures ont été mappés, chaque valeur distincte présente dans le fichier doit être mise en correspondance avec une nomenclature présente dans la base de données.
    Tout comme le mapping des colonnes, vous pouvez utiliser un mapping de valeur existant ou créer un nouveau.
    Une fois la correspondance terminée, cliquez sur le bouton "Suivant".

    .. image:: images/import/import_steps/05_mapping_value.png


7. Pour pouvoir importer les données présentes dans le fichier source, il est nécessaire d'
effectuer des contrôles sur les données : vérification des types, vérification des formats de données (dates),
vérification de cohérence de données (date début < date fin), etc. Pour lancer, le contrôle de données cliquez
sur le bouton "Lancer la vérification".

    .. image:: images/import/import_steps/06_01_control_data.png

8. Une fois la vérification des données effectuée, un aperçu des données valides ainsi que leur emprise spatiale (*bounding box*) sont affichés.
   Si des erreurs sont présentes dans les données, un bouton "Rapport d'import/erreurs/avertissement" permet d'afficher les erreurs et d'ajuster votre fichier source ou les paramètres de l'import.
   De plus, il est possible de télécharge un fichier contenant unique les lignes contenant des erreurs.
   Si l'aperçu des données qui seront importées vous convient, cliquez sur le bouton "Importer les [n] entités valides".

    .. image:: images/import/import_steps/06_02_import_part1.png

9.  Une fois l'import terminé, un rapport récapitulatif est affiché avec les différents paramètres
de l'import mais aussi plusieurs indicateurs statistiques sous forme de tableau et de graphique(s).
Il est aussi possible d'exporter une version PDF de ce rapport.

    .. image:: images/import/import_steps/07_report_part1.png

Modifier un import
""""""""""""""""""

Pour modifier un import, rendez-vous dans la "Liste des imports", cliquez sur l'icone en forme de "crayon" dans la colonne "Actions".

.. danger::
    La modification d'un import terminé provoquera la suppression des données importées dans la table temporaire et dans la table de destination.

Supprimer un import
"""""""""""""""""""

Pour supprimer un import, il suffit de cliquer sur l'icone en forme de poubelle dans la colonne "Actions".

.. danger:: 
    La suppression d'un import terminé entrainera la suppression des données dans la table de destination.

Exemple de fichier CSV pour l'import Occhab
"""""""""""""""""""""""""""""""""""""""""""

Ci-dessous un exemple de fichier CSV avec les colonnes et le contenu attendu dans l'import de données vers Occhab.

Le fichier CSV pour un import Occhab représente un tableau à plat des données des stations et de leurs habitats. Par conséquent, les données d'une station doivent être répétées autant de fois que son nombre d'habitats.

.. csv-table:: 
   :file: ../table/occhab-exemple.csv
   :header-rows: 1

Plus d'exemples sont disponibles dans le fichier ``valid_file.csv`` dans le dossier ``backend/geonature/tests/imports/files/occhab/valid_file.csv``.
