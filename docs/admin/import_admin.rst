
Module d’import
---------------
Ce module permet d’importer des données depuis un fichier CSV dans [GeoNature](https://github.com/PnX-SI/GeoNature).


Concept
"""""""

**Destination.** Une destination est déterminée par le module dans lequel on souhaite importer (e.g. Occhab, Synthèse, etc.)

**Entités.** Une entité correspond est un objet dans une destination (e.g. station est une entité de la destination Occhab)


Faire un import, le minimum requis
""""""""""""""""""""""""""""""""""

Pour qu’un utilisateur puisse mener au bout un import, il doit posséder a minima les permissions suivantes : 

* Création d’un import (C) 
* Voir les imports (R)
* Voir des mappings (R)
* Droit de créer/saisir dans le module de destination (C dans OccHab par ex.)

Jeu de données
Un import s’effectue dans un jeu de données, par conséquent, ce dernier doit 
- être associé aux modules de destination de l’import (Voir champ dans l’édition/création d’un JDD : Module(s) GeoNature associé(s) au jeu de données)
- être actif


Déroulement d’un import
"""""""""""""""""""""""

Dans le module d’import, deux actions sont possibles : la création d’un import, la modification de ce dernier et la suppression d’un import.
Lors du lancement de la création d’un import, il vous est demandé en premier lieu de sélectionner la destination. Une fois la destination choisi, on entre dans la phase de préparation de l’import avec les étapes suivantes :

1. Téléverser le fichier contenant les données et sélection du jeu de données
2. Définition des paramètres de lecture du fichier téléversé
3. Faire correspondre les colonnes de votre fichier avec les champs du modèle de données définit dans le module de destination
4. Si des champs de données correspondent à des nomenclatures, une mise en correspondance des valeurs
5. Contrôles des données du fichier source sélectionnées

Une fois, cette phase de préparation terminée, l’utilisateur se voit présenter les données jugées comme valide (resp. les données invalides). A cette étape, l’utilisateur à la choix de modifier les données invalides dans son fichier source et recommencer le processus de préparation de l’import OU lancer l’import des données dans la destination.
Une fois l’import de données terminée, l’utilisateur est redirigé vers un rapport récapitulant les paramètres de l’import et un affichage de quelques statistiques spécifiques aux type de données importées.


.. image:: _static/import/importderoulement.png

Configuration du module d’import
""""""""""""""""""""""""""""""""

Ajouter les variables directement dans le fichier de GeoNature principale.

 ============================================== ============================================================================================================================================================================ 
  Variable                                       Description                                                                                                                                                                 
 ============================================== ============================================================================================================================================================================ 
  ENCODAGE                                       Liste des encodages 
  acceptés                                                                                                                                                
  INSTANCE_BOUNDING_BOX                          Zone rectangulaire dans lequel les données doivent appartenir                                                                                                               
  ENABLE_BOUNDING_BOX_CHECK                      Activer la vérification de l'appartenance des données importées à la bounding box définie dans INSTANCE_BOUNDING_BOX                                                        
  ENABLE_SYNTHESE_UUID_CHECK                     Activer la vérification des UUID dans les données importées avec ceux présent dans la Synthèse                                                                              
  MAX_FILE_SIZE                                  Taille maximale du fichier chargé (en Mo)                                                                                                                                   
  SRID                                           SRID autorisés pour les fichiers en entrée                                                                                                                                  
  ALLOWED_EXTENSIONS                             Extensions autorisées (seul le csv est accepté actuellement)                                                                                                                
  ALLOW_VALUE_MAPPING                            Activer ou non l'étape du mapping des valeurs                                                                                                                               
  DEFAULT_VALUE_MAPPING_ID                       Si le mapping des valeurs est désactivé, specifier l'identifiant du mapping qui doit être utilisé                                                                           
  FILL_MISSING_NOMENCLATURE_WITH_DEFAULT_VALUE   Rempli les valeurs de nomenclature erroné par la valeur par defaut                                                                                                          
  DISPLAY_CHECK_BOX_MAPPED_FIELD                 Afficher le bouton pour afficher/masquer les champs déjà mappés                                                                                                             
  CHECK_PRIVATE_JDD_BLURING                      Active la vérification de l'existence du champs "floutage" si le JDD est privé                                                                                              
  CHECK_REF_BIBLIO_LITTERATURE                   Active la vérification qu'une ref biblio est fournie si la valeur du champs source = "litterature"                                                                          
  CHECK_EXIST_PROOF                              Active la vérification qu'une preuve d'existance est fournie si preuve existance = "oui"                                                                                    
  EXPORT_REPORT_PDF_FILENAME                     Customiser le nom du fichier de rapport de l'import                                                                                                                         
  DEFAULT_RANK                                   Paramètre pour définir le rang utilisé pour le diagramme camembert du rapport d'import.                                                                                     
  DEFAULT_GENERATE_MISSING_UUID                   L'UUID d'une entité importée sera généré s'il n'est pas indiqué dans les données du fichier d'entée,                                                                       
  ID_AREA_RESTRICTION                            Identifiant d'une géométrie présente dans RefGeo. Si différent de -1, vérifie si les géométries des entités importées sont bien dans l'emprise spatiale de cette dernière.  
  ID_LIST_TAXA_RESTRICTION                       Id d'une liste de taxons permettant de restreindre l'import d'observations de taxons comprises dans cette dernière                                                          
  MODULE_URL                                     URL d'accès au module d'import                                                                                                                                              
  DATAFRAME_BATCH_SIZE                           Taille des `batch` de données importées en même temps                                                                                                                       
 ============================================== ============================================================================================================================================================================ 


Permissions de l’import
"""""""""""""""""""""""

Dans le module d’import, il existe le jeu de permissions suivant :

* Création d’un import – C
* Voir les imports – R
* Modifier des imports – U (nécessaire d’avoir le C)
* Supprimer des imports – D
* Créer des mappings - C
* Voir des mappings - R
* Modifier des mappings - U
* Supprimer des mappings - D

**Scope.** Similaire à d’autres permissions dans GeoNature, il est possible de limiter l’accès à l’utilisateur sur les données sur lesquelles il peut agir. L’ ajout de scope sur une permission de l’import limite ce dernier sur la visibilité des imports dans l’interface « Liste des Imports » ainsi que la possibilité (resp. impossbilité) de modifier ou supprimer un import. Par exemple,  un R2 sur « IMPORT » permet uniquement de voir les imports effectués par soi-même ou un utilisateur de son organisme.
A noter que les jeux de données disponibles lors de la préparation de l’import s’appuie bien sur les permissions de l’utilisateur dans ce dernier ! 


Contrôles de données
""""""""""""""""""""

**Erreurs**

 =================================== ============================================================================================================================================================================================================================================================================================================== 
  Code Erreur                         Description                                                                                                                                                                                                                                                                                                   
 =================================== ============================================================================================================================================================================================================================================================================================================== 
  DATASET_NOT_FOUND                   L’identifiant ne correspond à aucun jeu de données existant.                                                                                                                                                                                                                                                  
  DATASET_NOT_AUTHORIZED              L’utilisateur ne peut pas importé de nouvelles entités dans le jeu de données.                                                                                                                                                                                                                                
  DATASET_NOT_ACTIVE                  Aucune donnée ne peut être importé dans le JDD indiqué car celui-ci n’est plus actif.                                                                                                                                                                                                                         
  MULTIPLE_ATTACHMENT_TYPE_CODE       Plusieurs géoréférencements sont indiquées dans les colonnes  codeCommune, codeMaille, codeDépartement (Erreur Synthèse)                                                                                                                                                                                      
  MULTIPLE_CODE_ATTACHMENT            Plusieurs codes de rattachement fournis pour une même ligne. Une ligne doit avoir un seul code rattachement (code commune OU code maille OU code département)                                                                                                                                                 
  INVALID_DATE                        Format de date invalide (Voir format de date autorisé)                                                                                                                                                                                                                                                        
  INVALID_UUID                        Format de l’identifiant donnée ne respecte pas le format UUID (https://fr.wikipedia.org/wiki/Universally_unique_identifier)                                                                                                                                                                                   
  INVALID_INTEGER                     La donnée indiquée ne correspond pas un nombre entier.                                                                                                                                                                                                                                                        
  INVALID_NUMERIC                     La donnée indiquée ne correspond pas à un nombre réel (float)                                                                                                                                                                                                                                                 
  INVALID_WKT                         La donnée fournie ne respecte pas le format WKT https://fr.wikipedia.org/wiki/Well-known_text                                                                                                                                                                                                                 
  INVALID_GEOMETRY                    La géométrie de la donnée renseignée est invalide (c.f  ST_VALID)                                                                                                                                                                                                                                             
  INVALID_BOOL                        La donnée fournie n’est pas un booléen                                                                                                                                                                                                                                                                        
  INVALID_ATTACHMENT_CODE             Le code commune/maille/département indiqué ne fait pas partie du référentiel des géographique.                                                                                                                                                                                                                
  INVALID_CHAR_LENGTH                 La chaine de caractère de la donnée est trop longue                                                                                                                                                                                                                                                           
  DATE_MIN_TOO_HIGH                   La date de début est dans le futur                                                                                                                                                                                                                                                                            
  DATE_MAX_TOO_LOW                    La date de fin est inférieure à 1900                                                                                                                                                                                                                                                                          
  DATE_MAX_TOO_HIGH                   La date de fin est dans le futur                                                                                                                                                                                                                                                                              
  DATE_MIN_TOO_LOW                    La date de début est inférieure à 1900                                                                                                                                                                                                                                                                        
  DATE_MIN_SUP_DATE_MAX               La date de début est supérieur la date de fin                                                                                                                                                                                                                                                                 
  DEPTH_MIN_SUP_ALTI_MAX              La profondeur minimum est supérieur à la profondeur maximale                                                                                                                                                                                                                                                  
  ALTI_MIN_SUP_ALTI_MAX               L’altitude minimum est supérieur à l’altitude maximale                                                                                                                                                                                                                                                        
  ORPHAN_ROW                          La ligne du fichier n’a pû être rattaché à aucune entité.                                                                                                                                                                                                                                                     
  DUPLICATE_ROWS                      Deux lignes du fichier sont identiques ; les lignes ne peuvent pas être dupliquées.                                                                                                                                                                                                                           
  DUPLICATE_UUID                      L'identifiant UUID d’une entité n'est pas unique dans le fichier fournis                                                                                                                                                                                                                                      
  EXISTING_UUID                       L'identifiant UUID d’une entité fournie existe déjà dans la base de données. Il faut en fournir une autre ou laisser la valeur vide pour une attribution automatique.                                                                                                                                         
  SKIP_EXISTING_UUID                  Les entités existantes selon UUID sont ignorées.                                                                                                                                                                                                                                                              
  MISSING_VALUE                       Valeur manquante dans un champs obligatoire                                                                                                                                                                                                                                                                   
  MISSING_GEOM                        Géoréférencement manquant ; un géoréférencement doit être fourni, c’est à dire qu’il faut livrer : soit une géométrie, soit une ou plusieurs commune(s), ou département(s), ou maille(s), dont le champ “typeInfoGeo” est indiqué à 1.                                                                        
  GEOMETRY_OUTSIDE                    La géométrie se trouve à l'extérieur du territoire renseigné                                                                                                                                                                                                                                                  
  NO-GEOM                             Aucune géometrie fournie (ni X/Y, WKT ou code)                                                                                                                                                                                                                                                                
  GEOMETRY_OUT_OF_BOX                 Coordonnées géographiques en dehors du périmètre géographique de l'instance                                                                                                                                                                                                                                   
  ERRONEOUS_PARENT_ENTITY             L’entité parente est en erreur.                                                                                                                                                                                                                                                                               
  NO_PARENT_ENTITY                    Aucune entité parente identifiée.                                                                                                                                                                                                                                                                             
  DUPLICATE_ENTITY_SOURCE_PK          Deux lignes du fichier ont la même clé primaire d’origine ; les clés primaires du fichier source ne peuvent pas être dupliquées.                                                                                                                                                                              
  COUNT_MIN_SUP_COUNT_MAX             Incohérence entre les champs dénombrement. La valeur de denombrement_min est supérieure à celle de denombrement _max ou la valeur de denombrement _max est inférieur à denombrement_min.                                                                                                                      
  INVALID_NOMENCLATURE                Code nomenclature erroné ; La valeur du champ n’est pas dans la liste des codes attendus pour ce champ. Pour connaître la liste des codes autorisés, reportez-vous au Standard en cours.                                                                                                                      
  INVALID_EXISTING_PROOF_VALUE        Incohérence entre les champs de preuve ; si le champ “preuveExistante” vaut oui, alors l’un des deux champs “preuveNumérique” ou “preuveNonNumérique” doit être rempli. A l’inverse, si l’un de ces deux champs est rempli, alors “preuveExistante” ne doit pas prendre une autre valeur que “oui” (code 1).  
  INVALID_NOMENCLATURE_WARNING        (Non bloquant) Code nomenclature erroné et remplacé par sa valeur par défaut ; La valeur du champ n’est pas dans la liste des codes attendus pour ce champ. Pour connaître la liste des codes autorisés, reportez-vous au Standard en cours.                                                                  
  CONDITIONAL_MANDATORY_FIELD_ERROR   Champs obligatoires conditionnels manquants. Il existe des ensembles de champs liés à un concept qui sont “obligatoires conditionnels”, c’est à dire que si l'un des champs du concept est utilisé, alors d'autres champs du concept deviennent obligatoires.                                                 
  UNKNOWN_ERROR                       Erreur inconnue                                                                                                                                                                                                                                                                                               
  INVALID_STATUT_SOURCE_VALUE         Référence bibliographique manquante ; si le champ “statutSource” a la valeur “Li” (Littérature), alors une référence bibliographique doit être indiquée.                                                                                                                                                      
  CONDITIONAL_INVALID_DATA            Erreur de valeur                                                                                                                                                                                                                                                                                              
  INVALID_URL_PROOF                   PreuveNumerique n’est pas une url ; le champ “preuveNumérique” indique l’adresse web à laquelle on pourra trouver la preuve numérique ou l’archive contenant toutes les preuves numériques. Il doit commencer par “http://”, “https://”, ou “ftp://”.                                                         
  ROW_HAVE_TOO_MUCH_COLUMN            Une ligne du fichier source a plus de colonnes que l'en-tête.                                                                                                                                                                                                                                                 
  ROW_HAVE_LESS_COLUMN                Une ligne du fichier source a moins de colonnes que l'en-tête.                                                                                                                                                                                                                                                
  EMPTY_ROW                           Une ligne dans le fichier source est vide                                                                                                                                                                                                                                                                     
  HEADER_SAME_COLUMN_NAME             Au moins deux colonnes du fichier source possèdent des noms identiques                                                                                                                                                                                                                                        
  EMPTY_FILE                          Le fichier source est vide                                                                                                                                                                                                                                                                                    
  NO_FILE_SENDED                      Aucun fichier source n’a été téléversé.                                                                                                                                                                                                                                                                       
  ERROR_WHILE_LOADING_FILE            Une erreur s’est produite lors du chargement du fichier.                                                                                                                                                                                                                                                      
  FILE_FORMAT_ERROR                   Le format du fichier est incorrect.                                                                                                                                                                                                                                                                           
  FILE_EXTENSION_ERROR                L'extension de fichier source est incorrect                                                                                                                                                                                                                                                                   
  FILE_OVERSIZE                       Volume du fichier source est trop important                                                                                                                                                                                                                                                                   
  FILE_NAME_TOO_LONG                  Nom du fichier de données trop long                                                                                                                                                                                                                                                                           
  FILE_WITH_NO_DATA                   Pas de données dans le fichier source                                                                                                                                                                                                                                                                         
  INCOHERENT_DATA                     Une même entité est déclaré avec différents attributs dans le fichier source                                                                                                                                                                                                                                  
  CD_HAB_NOT_FOUND                    CdHab n’existe pas dans le référentiel Habref installé                                                                                                                                                                                                                                                        
  CD_NOM_NOT_FOUND                    CdNom n’existe pas dans le référentiel TaxRef installé                                                                                                                                                                                                                                                        
 =================================== ============================================================================================================================================================================================================================================================================================================== 


**Format de dates autorisées**

Date :

- YYYY-MM-DD,
- DD-MM-YYYY

Heure : 
    • %H
    • %H-%M
    • %H-%M-%S
    • %H-%M-%S-%f
    • %Hh
    • %Hh%M
    • %Hh%Mm
    • %Hh%Mm%Ss

Contrôle de données dans les destinations venant avec GeoNature
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

Dans cette section, nous présentons les contrôles de données effectuées pour les destinations embarquées dans GeoNature : Synthèse, Occhab.
L’ordre des contrôles dans ces listes correspond bien à celui du processus définit dans le code de GeoNature.
De manière générale, nous séparons les contrôles de données en deux catégories, ceux effectués en BDD avec PostgreSQL et ceux effectuée en Python à l’aide des DataFrame (donnée tableau) 


**Listes des contrôles pour Occhab**


1. [SQL][Station] 

   1. Vérification de la cohérence des données des stations déclarées

2. [DataFrame][Station]

   1. Vérification de l’existence de données pour les champs obligatoires
   2. Vérification de la concordance entre le type d’un champ et la données
   3. Vérification du jeu de données
   4. Vérification des géométries présentes dans les données (WKT ou latitude/longitude)

3. [DataFrame][Habitat]
   
   1. Vérification de l’existence de données pour les champs obligatoires
   2. Vérification de la concordance entre le type d’un champ et la données

4. [SQL][Station]
    
   1. Mapping des valeurs de nomenclatures
   2. Conversion des données de géométrie dans le SRID de la BDD
   3. Vérification de la cohérence des données altitudinale, de profondeur et les dates
   4. Vérification de la validité des géométries

5. [SQL][Habitat]
 
   1. Mapping des valeurs de nomenclatures
   2. Vérification des cdHab
   3. Vérification des UUID (doublons dans le fichier, existence dans la destination)
   4. Générer les UUID si manquante
   5.  Dans le cas d’habitat importé sur une station existante, vérifier les droits de l’utilisateur sur cette dernière.


**Listes des contrôles pour la Synthèse**

1. [DataFrame]
   
   1. Vérification de l’existence de données pour les champs obligatoires
   2. Vérification de la concordance entre le type d’un champ et la données

2. [SQL]
   
   1. Vérification du jeu de données
   2. Vérification des géométries présentes dans les données (WKT ou latitude/longitude)
   3. Vérification des données de dénombrement
   4. Mapping des nomenclatures
   5. Vérification de l’existence des identifiants cdNom dans Taxref local
   6. Vérification de l’existence des identifiants cdHab dans Habref local
   7.  Vérification de la cohérence des données altitudinale, de profondeur et les dates
   8.  Vérification des preuves numériques
   9.  Vérification de l’intersection entre chaque géométrie et la géométrie de la zone autorisée.



