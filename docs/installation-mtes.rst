SPECIFICITES INSTANCE NATIONALE
===============================

Cette documentation mentionne les spécificités et la configuration de l'installation de l'instance nationale du Ministère de la Transition Ecologique et Solidaire (MTES) dans le cadre du projet de Depôt Légal des données de bioldiversité.

Pour l'installation de GeoNature, voir la procédure d'installation de GeoNature et ses dépendances (https://github.com/PnX-SI/GeoNature/blob/develop/docs/installation-all.rst). 

Configuration serveur
---------------------
GeoNature se sert de flux internet externes durant son installation et son fonctionnement. Le serveur acceuillant l'application doit autoriser les flux externes suivants:

- https://pypi.python.org
- http://geonature.fr/
- https://codeload.github.com/
- https://nodejs.org/dist
- https://registry.npmjs.org
- https://www.npmjs.com
- https://raw.githubusercontent.com/
- https://inpn.mnhn.fr/mtd
- https://preprod-inpn.mnhn.fr/mtd
- https://wxs.ign.fr/


Configuration de l'application
------------------------------

Une fois l'installation terminé, il est necessaire d'adapter les fichiers de configuration de l'application pour les besoins spécifiques de l'instance nationale.

Voir le fichier ``/home/<my_user>/<my_geonature_directory>/config/default_config.tomls.example``, qui liste l'ensemble des variables de configuration disponible ainsi que leurs valeurs par défaut. 

Editer le fichier de configuration de GeoNature pour surcoucher ces variables:

``sudo nano /etc/geonoature/geonature_config.toml``


La première variable ``SQLALCHEMY_DATABASE_URI`` corespond aux identifiants de connexion à la BDD, vérifier que les informations corespondent bien à ce que vous avez remplit dans le fichier ``settings.ini`` lors de l'installation.

Configuration des URLS
***********************

Les URLS doivent correspondre aux informations renseignés dans la configuration Apache et au Load Balancer. Elle ne doivent pas contenir de ``/`` final.
Pour la préprod, ajouter le préfixe "pp" avant ``saisie`` et ``taxhub`` (naturefrance.fr/pp-saisie, naturefrance.fr/pp-taxhub/api) et adapter la configuration Apache en conséquence.

::

    # URL d'accès à l'application
    URL_APPLICATION = 'https://depot-legal-biodiversite.naturefrance.fr/saisie'
    # URL de l'API de GeoNature
    API_ENDPOINT = 'https://depot-legal-biodiversite.naturefrance.fr/saisie/api'
    # URL de l'API de Taxhub
    API_TAXHUB = 'https://depot-legal-biodiversite.naturefrance.fr/taxhub/api'


Clé secrète
***********

Mettre un clé secrète personnalisée

::
    
    SECRET_KEY = '<MA_CLE_CRYPTEE>'

Connexion au CAS INPN - gestion centralisé des utilisateurs
***********************************************************

Bien changer les variables ID et PASSWORD avec les bonnes valeurs

NB: pour la préprod, utiliser ``https://preprod-inpn.mnhn.fr``
::

  [CAS]
      CAS_AUTHENTIFICATION = true
      CAS_URL_LOGIN = 'https://inpn.mnhn.fr/auth/login'
      CAS_URL_LOGOUT = 'https://inpn.mnhn.fr/auth/logout'
      CAS_URL_VALIDATION = 'https://inpn.mnhn.fr/auth/serviceValidate'
      USERS_CAN_SEE_ORGANISM_DATA = false
      [CAS.CAS_USER_WS]
          URL = 'https://inpn.mnhn.fr/authentication/information'
          ID = '<THE_INPN_LOGIN>'
          PASSWORD = '<THE_INPN_PASSWORD>'

Configuration du frontend
**************************

(Pour l'instance de préprod, rajouter "instance de démo" à la variable ``appName``
::

  # Nom de l'application sur la page d'acceuil
  appName = 'Depôt légal de biodiviersité - saisie'
  [FRONTEND]
      # Compilation du fronend en mode production
      PROD_MOD = true
      # Affichage du footer sur la page d'acceuil
      DISPLAY_FOOTER = true



Après chaque modification du fichier de configuration, lancez les commandes suivantes pour mettre à jour l'application (l'opération peut être longue: recompilation du frontend).

Depuis le répertoire ``backend`` de GeoNature

::

    source venv/bin/activate
    geonature update_configuration
    deactivate


Configuration de la cartographie
********************************

Pour l'instance nationale, l'application est fournie avec des fonds de carte IGN (Topo, Scan-Express et Orto).

Pour modifier cette configuration par défaut, éditer le fichier de configuration cartographique: ``frontend/src/conf/mam.config.ts``, puis recompiler le frontend (depuis le repertoire ``frontend`` ``npm run build``.



Configuration du module occurrence de taxon: OCCTAX
***************************************************

Le script de configuration spécifique de l'instance nationale remplit ce fichier avec les bonnes configuration.

Le fichier ``/home/<my_user>/<my_geonature_directory>/contrib/occtax/configuration_occtax.toml.example`` liste l'ensemble des variables de configuration du module Occtax ainsi que leurs valeur par défault.

Editez le fichier ``/etc/geonature/mods-enabled/occtax/conf_gn_module``

Après chaque modification du fichier de configuration, lancez les commandes suivantes pour mettre à jour l'application (l'opération peut être longue: recompilation du frontend).

Depuis le répertoire ``backend`` de GeoNature

::

    source venv/bin/activate
    geonature update_module_configuration occtax
    deactivate



*TODO*
Script de collage des modules de customisation et de configuration des listes de taxon



Attention, communes, zonages et MNT national ?

Ajouter les paramètres spécifiques (observers-txt, cas, mtd...)

Taxons saisissables
-------------------

GeoNature n'interroge pas directement la table ``taxonomie.taxref`` pour permettre à l'administrateur de choisir quels taxons sont disponibles à la saisie. 

La table ``taxonomie.bib_noms`` contient tous les noms (noms de référence et synonymes) utilisables dans GeoNature. 
Il faut ensuite les ajouter à la liste ``Saisie possible`` (``id_liste=500`` de ``taxonomie.bib_listes``) pour rendre ces noms saisissables dans le module OCCTAX.

Une fois TaxHub installé, il faut donc remplir la table ``taxonomie.bib_noms`` avec les noms souhaités. Dans cet exemple, on va y insérer tous les taxons de TAXREF des rangs Genre et inférieurs :
 
::  

  DELETE FROM taxonomie.cor_nom_liste;
  DELETE FROM taxonomie.bib_noms;

  INSERT INTO taxonomie.bib_noms(cd_nom,cd_ref,nom_francais)
  SELECT cd_nom, cd_ref, nom_vern
  FROM taxonomie.taxref
  WHERE id_rang NOT IN ('Dumm','SPRG','KD','SSRG','IFRG','PH','SBPH','IFPH','DV','SBDV','SPCL','CLAD','CL',
     'SBCL','IFCL','LEG','SPOR','COH','OR','SBOR','IFOR','SPFM','FM','SBFM','TR','SSTR')

Il faut ensuite ajouter tous ces noms à la liste ``Saisie possible`` : 
 
::  
  
  INSERT INTO taxonomie.cor_nom_liste (id_liste,id_nom)
  SELECT 500,n.id_nom FROM taxonomie.bib_noms n
        
.. image :: http://geonature.fr/docs/img/admin-manual/design-geonature-mtes.png

Authentification CAS INPN
-------------------------

- Code source : https://github.com/PnX-SI/GeoNature/blob/develop/backend/geonature/core/auth/routes.py#L19-L106
- Config : https://github.com/PnX-SI/GeoNature/blob/develop/config/default_config.toml.example#L20-L36


Connexion et droits dans GeoNature
----------------------------------

- A chaque connexion via le CAS INPN on récupère l’ID_Utilisateur. On ajoute cet utilisateur dans la base GeoNature (``utilisateurs.t_roles`` et ``utilisateurs.bib_organisme``).
	 
- Si l’utilisateur a un ID_Organisme, on lui assigne le « socle 2 » (C1-R2-U1-V0-E2-D1) du CRUVED. L’utilisateur pourra donc voir les données saisies par les personnes de son organisme et tous les JDD créés par lui-même ou quelqu’un de son organisme.

- Si l’utilisateur n’a pas d’ID_Organisme, on lui assigne le « socle 1 » (C1-R1-V0-E1-D1). Il pourra voir seulement les données qu’il a saisi lui-même et les JDD qu’il a créé dans MTD.

NB sur la gestion des droits dans GeoNature :

- 6 actions sont possibles dans GeoNature : Create / Read / Update / Validate / Export / Delete (aka CRUVED).
- 3 portées de ces actions sont possibles : Mes données / Les données de mon organisme / Toutes les données.

Récupération des JDD
--------------------

Grâce à la nouvelle API de MTD, il est désormais possible d’ajouter les jeux de données (et des cadres d’acquisition) créés dans MTD dans la BDD GeoNature.

- A chaque connexion à GeoNature, on récupère l’ID_Utilisateur

- On récupère la liste des JDD créés par l’utilisateur grâce à l’API MTD :
https://xxxxx/cadre/jdd/export/xml/GetRecordsByUserId?id=<ID_USER>

- On récupère l’UUID du cadre CA associé au JDD dans le XML renvoyé et on fait appel au l’API MTD pour récupérer le fichier XML du CA :
https://xxxxx/cadre/export/xml/GetRecordById?id=<UUID>
	
- On ajoute le CA dans la table ``gn_meta.t_acquisition_framwork`` et les JDD dans la table ``gn_meta.t_datasets``. Si le CA ou les JDD sont modifiés dans MTD, ils seront également modifiés dans le BDD GeoNature.
	
- Dans la table ``gn_meta.cor_dataset_actor`` on fait le lien entre les acteurs et le JDD. On ajoute l’utilisateur qui a créé le JDD comme "Point de contact principal" du JDD. Si on dispose de l’ID_Organisme de l’utilisateur, on ajoute également l’organisme comme "Point de contact principal" du JDD. Ainsi, deux personnes du même organisme (si le CAS renvoie bien le même ID_Organism) pourront saisir, visualiser et exporter des données de leurs JDD communs.

- Pour remplir cette table on ne prend pas les infos renvoyés par le XML JDD sous l’intitulé « Acteur » puisque l’ID_Organisme ou l’ID_Acteur n’est pas renseigné. (Dans la table ``gn_meta.cor_dataset_actor``, il faut obligatoirement un ID).

- La question de la suppresion de JDD et des CA n’est pas résolue. Si un JDD est supprimé dans MTD, qu’est-ce qu’on fait des données associées a celui-ci dans GeoNature ? 
