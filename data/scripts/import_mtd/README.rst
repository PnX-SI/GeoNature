**Ces scripts permetttent d'importer les métadonnées à partir de leurs uuid en utilisant le webservice mtd de l'INPN.**
Ils permettent de rappatrier dans une instance GeoNature les métadonnées correspondant à des données INPN qui 
déjà importées dans la BDD GeoNature depuis un export INPN.  


* Le script ``run_import_mtd.py`` retrouve les informations des métadonnées à partir des UUID des JDD et des UUID des CA déjà présent dans la base GN2
* Le script ``import_jdd_and_ca`` effectue les mêmes manipulation en s'appuyant uniquement sur les UUID JDD et retrouve les CA correspondants.
Fonctionnement général du script
--------------------------------

Les données exportées par l'INPN comprennent un certain nombre d'informations élémentaires d'échange. L'ensemble des métadonnées ne sont pas transmises pour des questions de simplicité des exports : seuls quelques champs de base dont les identifiants (uuid) des cadres d'acquisition et jeux de données sont communiqués. 

Selon l'utilisation qui est faite des données naturalistes (analyse, rediffusion etc), il peut être nécessaire de posséder les métadonnées dans leur ensemble. Le but de ce script est donc de rapatrier dans une instance de GeoNature l'ensemble des métadonnées **correspondant à des données préalablement importées depuis l'INPN**. 

Afin de récupérer ces informations, **le script s'appuie sur les UUID des cadres d'acquisition et jeux de données** auxquelles sont rattachées les différentes données naturalistes importées depuis l'INPN. Il collecte ensuite les fichiers XML correspondants sur le site de l'INPN, les découpe, et en extrait les informations nécessaires pour les intégrer à l'instance GeoNature locale. 

**Le script permet, de cette manière** : 

- *De créer et mettre à jour des cadres d'acquisition et jeux de données (libellé, description etc)*

- *De créer et mettre à jour les publications et protocoles liés aux métadonées en question (voir référentiel)*

- *De créer et mettre à jour, sur la base des UUID, les organismes acteurs des cadres d'acquisition et jeux de données importés*

- *De créer et mettre à jour, sur la base de leurs noms+Prénom, les personnes acteurs des cadres et jeux de données importés*

- *D'établir toutes les correspondances nécessaires pour GeoNature (objectifs, territoires, volet SINP, publications, protocoles, acteurs etc qui sont multiples pour un jeu de données ou un cadre donné).*


Le script va créer, mais aussi supprimer et mettre à jour des données dans toutes les tables du schéma gn_meta, et dans les tables t_roles et bib_organismes du schéma utilisateurs. Il s'appuie également sur le schéma ref_nomenclatures (mais en simple lecture). 
**Il est donc recommandé de faire une sauvegarde avant tout import de métadonnées** en cas de dysfonctionnement. 


Installation de l'environnement Python
--------------------------------------

- Pour être plus propre il est conseillé de créer un nouveau virtualenv et d'y installer les paquets Python

::
    
    cd /home/'whoami'/geonature/data/scripts/import_mtd
    virtualenv -p /usr/bin/python3 venv #Python 3 n'est pas requis
    source venv/bin/activate
    pip install psycopg2 requests
    deactivate


Configuration du script
-----------------------

- Créez un fichier config.py à partir du fichier config.py.sample

- Récupérer le paramètre de ''SQLALCHEMY_DATABASE_URI'' dans le fichier geonature/config/geonature_config.toml
  et renseignez le dans le fichier config.py que vous avez créé

- Renseignez le nom de la table comprenant les données INPN que vous avez importées, et les noms des champs comprenant les uuid
  des cadres d'acquisitions et des jeux de données

- Vous pouvez définir l'id_organisme auquel vous souhaitez rattacher les personnes mentionnées dans les acteurs des métadonnées rappatriées. 
  Elles ne sont pas rattachées aux organismes associés dans un premier temps, afin d'éviter les conflits lorsqu'un acteur est associé à plusieurs organismes.

- Vous pouvez également choisir de conserver ou non les fichiers émis par le webservice de l'INPN sur votre serveur (dossier du script)



Execution du script
-------------------

- Activer le virtualenv :

::
    
    source venv/bin/activate

- lancer le script : 

::
    
    python run_import_mtd.py > import_mtd.log
    ou
    python import_jdd_and_ca.py > import_mtd.log




Rattachement des données importées à leurs métadonnées nouvellement créées
--------------------------------------------------------------------------

Les données sont rattachées à un jeu de données dans GeoNature par l'identifiant id_dataset, propre à chaque instance de GeoNature, et non pas l'uuid du jeu de données. 
Après avoir récupéré les métadonnées de l'INPN qui correspondent à vos données, devrez réattribuer les données naturalistes à leur identifiant de jeu de données (id_dataset de GeoNature). En utilisant à la fois l'identifiant source de la donnée, et l'UUID de son jeu de données de rattachement fourni dans les exports de l'INPN, vous pourrez facilement réattribuer les données à l'id_dataset de leur jeu de données nouvellement créé dans votre instance. Le script suivant (à adapter à votre contexte) peut servir d'exemple :

::
     
     UPDATE gn_synthese.synthese s
     SET id_dataset=m.id_dataset
     FROM gn_meta.t_datasets m, gn_imports.import_inpn i 
     WHERE m.unique_dataset_id=i."IDENTIFIANT_SINP_JDD"::uuid AND s.id_source=4 AND s.entity_source_pk_value=i."IDENTIFIANT_INPN"


N.B
---

Script rédigé par un novice... n'hésitez pas à contribuer et le nettoyer!
# TODO : ajouter un paramètre pour choisir la date de début par défaut des cadres et jdd lorsque l'information n'est pas renseignée à la source. 
