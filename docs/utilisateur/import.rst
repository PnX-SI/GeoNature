.. raw:: html

    <style> .red {color:red;font-weight:bold}img{margin-bottom:10px}</style>

.. role:: red

Import
------

Depuis le 2.15, GeoNature permet aussi d'importer des données depuis un fichier CSV dans deux modules:

- Synthèse
- Occhab

Créer un import
"""""""""""""""

Pour réaliser un import dans une des destinations de GeoNature, vous devez :

1.  Une fois connecté à GeoNature, accédez au module Import. L'accueil
    du module affiche la "liste des imports" en cours ou terminés, selon
    les permissions de l'utilisateur connecté. Vous pouvez alors finir un
    import en cours, ou bien commencer un nouvel import.

.. image:: images/import/import_steps/00_imports_list.png

2. Pour commencer un nouvel import, cliquez sur le bouton "+" en bas de la liste des imports. Dans la fenêtre qui s'affiche, il vous est demandé de sélectionner la destination de votre import.

.. image:: images/import/import_steps/01_destination_choice.png

3.  Une fois la destination choisie, vous serez redirigé vers une nouvelle page. 
    Dans ce nouveau formulaire, choisissez le jeu de données qui sera associés aux données importées.  
    Puis, téléverser le fichier CSV contenant les données que vous souhaitez importer. Une fois, les 
    champs remplis, cliquez sur le bouton "Suivant". 

.. image:: images/import/import_steps/02_upload_file.png

4.  Dans ce nouveau formulaire, indiquez les paramètres de lecture de votre fichier. Plusieurs
paramètres seront automatiquement détectés par GeoNature. Une fois, les champs remplis, cliquez sur le bouton "Suivant". 

.. image:: images/import/import_steps/03_parameter_selection.png

5.  Maintenant que le fichier est téleversé et chargé, il s'agit de faire 
    correspondre les champs du fichier importé aux champs du modèle des entités (e.g. Station).
    Pour vous aider dans la saisie, vous pouvez utiliser un mapping
    déjà existant ou en créer un nouveau pour l'utiliser dans de futur import. 
    Le module contient par défaut un mapping correspondant à un fichier exporté au format par défaut
    des modules Synthèse et Occhab. Si vous créez un nouveau mapping, il
    sera réutilisable pour les imports suivants. Une fois, la mise en correspondance terminée, 
    cliquez sur le bouton "Suivant".

.. image:: images/import/import_steps/04_01_mapping_cols.png

    **Notes.** A la fin du formulaire, vous pouvez visualiser le nombre de correspondances effectuées
    et les colonnes du fichier source qui n'ont pas été utilisées.

.. image:: images/import/import_steps/04_02_mapping_cols_validate.png

6.  La correspondance entre le fichier source et le modèle effectué, il faut maintenant faire
    correspondre des valeurs des colonnes contenant des données de nomenclatures (e.g. Etat Biologique de l'observation)
    avec les nomenclatures disponibles dans la base. Une fois, la correspondance terminée, 
    cliquez sur le bouton "Suivant".

.. image:: images/import/import_steps/05_mapping_value.png


7. Pour pouvoir importer les données présentes dans le fichier source, il est nécessaire d'
effectuer des contrôles sur les données : vérification des types, vérification des formats de données (dates),
vérification de cohérence de données (date début < date fin), etc. Pour lancer, le contrôle de données cliquez
sur le bouton "Lancer la vérification".

.. image:: images/import/import_steps/06_01_control_data.png

8. Une fois la vérification des données effectuée, un aperçu des données valides ainsi que leur emprise spatiale (*bounding box*) sont affichés. Si des erreurs sont présentes dans les données, un bouton "Rapport d'import/erreurs/avertissement" permet d'afficher les erreurs et d'ajuster votre fichier source ou paramètre de l'import. Si l'aperçu des données qui seront importées vous convient, cliquez sur le bouton "Importer les n entités valides".

.. image:: images/import/import_steps/06_02_import_part1.png

9.  Une fois l'import terminée, un rapport récapitulatif est affiché avec les différents paramètres
de l'import mais aussi plusieurs indicateurs statistiques sous forme de tableau et de graphique(s).
Il est aussi possible d'exporter une version PDF de ce rapport.

.. image:: images/import/import_steps/07_report_part1.png

Modifier un import
""""""""""""""""""

Pour modifier un import, rendez-vous dans la "Liste des imports", cliquez sur l'icone en forme de "crayon" dans la colonne "Actions".

:red:`!! Attention !! La modification d'un import terminé provoquera la suppression des 
données importées dans la table temporaire et dans la destination.`


Supprimer un import
"""""""""""""""""""

Pour supprimer un import, il suffit de cliquer sur l'icone en forme de poubelle dans la colonne "Actions".

:red:`!! Attention !!La suppression d'un import terminé implique la suppression des données dans la destination.`
