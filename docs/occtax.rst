Le module Occtax 
*****************

Le module Occtax est un module de saisie basé sur le standard d'Occurrences de Taxons du MNHN (http://standards-sinp.mnhn.fr/occurrences-de-taxon-v2-0/). Il permet de saisir et de standardiser les données dans un format attendu par les SINP pour l'échange de données de biodiversité.

Le module se divise en deux pages :

- Une page de visualisation, de recherche et d'exports des données saisies
.. image :: http://geonature.fr/docs/img/user-manual/02-occtax.jpg

- Une page de formulaire pour la saisie des données :

.. image :: http://geonature.fr/docs/img/user-manual/05-occtax-add.jpg


Installer le module
--------------------

Le module est fourni par défaut avec l'instalation de GeoNature.

Si vous l'avez supprimé, lancer les commandes suivantes depuis le repertoire ``backend`` de GeoNature

::

    source venv/bin/activate
    geonature install_gn_module /home/<mon_user>/geonature/contrib/occtax occtax


Configuration du module
------------------------

Le fichier de configuration du module se trouve ici :

``/etc/geonature/mods-enabled/occtax/conf_gn_module.toml``

Pour voir l'ensemble des variables de configuration du module ainsi qu leurs valeurs par défaut, ouvrir le fichier `/home/<mon_user>/geonature/contrib/occtax/conf_gn_module.toml`


Afficher/masquer des champs du formaulaire
""""""""""""""""""""""""""""""""""""""""""
La quasi-totalité des champs du standard d'occurrences de taxons sont présents dans la base de données, et peuvent donc être saisis à partir du formulaire.

Pour plus de souplesse et afin de répondre aux besoins de chacun, l'ensemble des champs sont masquables (sauf les champs primoridaux: observateur, taxon ...)

En modifiant les variables des champs ci-dessous, vous pouvez donc personnaliser le formulaire:

::

  [form_fields]
	[form_fields.releve]
		date_min = true
		date_max = true
		hour_min = true
		hour_max = true
		altitude_min = true
		altitude_max = true
		obs_technique = true
		group_type = true
		comment = true
	[form_fields.occurrence]
		obs_method = true
		bio_condition = true
		bio_status = true
		naturalness = true
		exist_proof = true
		observation_status = true
		diffusion_level = false
		blurring = false
		determiner = true
		determination_method = true
		sample_number_proof = true
		digital_proof = true
		non_digital_proof = true
		source_status = false
		comment = true
	[form_fields.counting]
		life_stage = true
		sex = true
		obj_count = true
		type_count = true
		count_min = true
		count_max = true
		validation_status = false

Si le champ est masqué, une valeur par défaut est inscrite en base (voir plus loin pour définir ces valeurs)

Modifier le champ observateur
"""""""""""""""""""""""""""""
Par défaut le champ observateur est une liste déroulante qui pointe vers une liste du schéma utilisateur.
Il est possible de passer ce champ en texte libre en mettant à "true" la variable `observers_txt`

TODO: personaliser la liste des observateurs.

Par défaut, l'ensemble des observateurs de la liste 9 (observateur faune/flore) sont affichés. Pour remplir cette liste, ajouter des utilisateurs dans la table ``utilisateurs.cor_role_menu``

Personnaliser la liste des taxons saisissables dans le module
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
Le module est fournit avec une liste restreinte de taxon (3 seulements !). C'est à l'administrateur de changer ou de remplir cette liste.

Le paramètre ``id_taxon_list = 500 `` correspont à un ID de liste de la table ``taxonomie.bib_liste`` (L'ID 500 corespond à la liste "Saisie possible"). Vous pouvez changer ce paramètre avec l'ID de liste que vous souhaitez où garder cet ID et changer le contenu de cette liste.

Voici les requêtes SQL pour remplir la liste 500 avec tous les taxons de Taxref à partir du genre : 

Il faut d'abord remplir la table ``taxonomie.bib_noms`` (table des taxons de sa structure), puis remplir la liste 500, avec l'ensemble des taxons de ``bib_noms``

:: 


    DELETE FROM taxonomie.cor_nom_liste;
    DELETE FROM taxonomie.bib_noms;

    INSERT INTO taxonomie.bib_noms(cd_nom,cd_ref,nom_francais)
    SELECT cd_nom, cd_ref, nom_vern
    FROM taxonomie.taxref
    WHERE id_rang NOT IN ('Dumm','SPRG','KD','SSRG','IFRG','PH','SBPH','IFPH','DV','SBDV','SPCL','CLAD','CL',
      'SBCL','IFCL','LEG','SPOR','COH','OR','SBOR','IFOR','SPFM','FM','SBFM','TR','SSTR')



    INSERT INTO taxonomie.cor_nom_liste (id_liste,id_nom)
    SELECT 500,n.id_nom FROM taxonomie.bib_noms n


Il est également possible d'éditer des listes à partir de l'application TaxHub.

Gérer les valeurs par défaut des nomenclatures
"""""""""""""""""""""""""""""""""""""""""""""""

Le formulaire de saisie pré-rempli des valeurs par défaut pour simplifier la saisie. Ce sont également ces valeurs qui sont prise en compte pour remplir dans la BDD les champs du formulaire qui sont masqués.

La table ``pr_occtax.defaults_nomenclatures_value`` définit les valeurs par défaut pour chaque nomenclature du standard.

La table contient les deux colonnes suivantes :

- l'id_type de nomenclature (voir table ``ref_nomenclature.bib_nomenclatures_types``)
- l'id_nomenclature (voir table ``ref_nomenclature.t_nomenclatures``

Pour chaque type de nomenclature, on associe l'ID de la nomenclature que l'on souhaite voir apparaitre par défaut.

Le mécanisme peut être poussé plus loin en associé une nomenclature par défaut par organisme, règne et group2_inpn.
La valeur 0 pour ses champs revient à mettre la valeur par défaut pour tous les organisme, tous les règne et tout les group2_inpn.


Une interface de gestion des nomenclatures est prévu d'être réalisé pour simplifier cette configuration.

TODO: valeur par défaut de la validation

Personaliser l'inteface map-list
""""""""""""""""""""""""""""""""

La liste des champs affiché par défaut sur le tableau peut être modifié avec le paramètre ``default_maplist_columns``

Par défaut:

default_maplist_columns = [
    { prop = "taxons", name = "Taxon" },
    { prop = "date_min", name = "Date début" },
    { prop = "observateurs", name = "Observateurs" },
    { prop = "dataset_name", name = "Jeu de données" }
]

Voir la vue ``occtax.v_releve_list`` pour voir les champs disponibles.

Gestion des exports
"""""""""""""""""""
Les exports du module sont basés sur une vue (par défaut ``pr_occtax.export_occtax_dlb``)

Il est possible de définir une autre vue pour avoir des exports personnalisés.
Pour cela, créer votre vue, et modifier les paramètres suivants:

::

    # Name of the view based export
    export_view_name = 'ViewExportDLB'

    # Name of the geometry columns of the view
    export_geom_columns_name = 'geom_4326'

    # Name of the primary key column of the view
    export_id_column_name = 'permId'

La vue doit cependant contenir les champs suivant pour que les filtres de recherche fonctionnent

::

    date_min,
    date_max,
    id_releve_occtax,
    id_dataset,
    id_occurrence_occtax,
    id_digitiser,
    geom_4326,
    dataset_name

Attribuer des droits
"""""""""""""""""""""

La gestion des droits (CRUVED: voir doc administrateur) se fait module par module. Cependant si on ne redéfinit pas de droit pour un module,ce sont les droits de l'application mère (GeoNature elle même) qui seront attribués à l'utilisateur pour l'ensemble de ses sous-modules.

Pour ne pas afficher le module Occtax à un utilisateur où à un groupe, il faut lui mettre l'action Read (R) à 0 par exemple.

Cette manipulation se fait dans la table (``utilisateurs.cor_ap_privileges``), où ``id_tag_action`` corespond à l'id du tag d'une action (CRUVED), et ``id_tag_object``, à l'id du tag de la portée pour chaque action (0,1,2,3). Voir la table ``utilisateurs.t_tags`` pour voir la corespondant entre les tags et les actions, ainsi que les portées.
La corespondance entre id_tag_action, id_tag_object, id_application, id_role, donnera les droits d'une personne où d'un groupe pour une application (ou module) donnée.

L'administration des droits des utilisateurs se fera bientôt dans une nouvelle version de UsersHub qui prendra en compte ce nouveau mécanisme du CRUVED.


