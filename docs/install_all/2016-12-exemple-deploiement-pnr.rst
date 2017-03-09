EXEMPLE D'INSTALLATION GLOBALE
==============================

Installation de GeoNature, TaxHub, UsersHub et GeoNature-atlas dans un PNR utilisant SERENA

**Décembre 2016** / Camille Monchicourt (Parc national des Ecrins)

Introduction
------------

Ce document décrit le déploiement de tout l'environnement GeoNature à l'aide du script ``install_all``.

Il décrit aussi comment l'outil a été paramétré et comment les données historiques du PNR saisies dans SERENA ont été intégrées dans GeoNature.

Il se base sur les versions 1.8.0 de `GeoNature <https://github.com/PnEcrins/GeoNature>`_, 1.1.1 de `TaxHub <https://github.com/PnX-SI/TaxHub>`_, 1.2.0 de `UsersHub <https://github.com/PnEcrins/UsersHub>`_ et 1.2.2 de `GeoNature-atlas <https://github.com/PnEcrins/GeoNature-atlas>`_.

Vérifiez les évolutions de ces applications et de leurs procédures si vous utilisez des versions plus récentes. 

Documentation du script de déploiement global : https://github.com/PnEcrins/GeoNature/tree/master/docs/install_all

Voir aussi http://geonature.fr et la documentation de chaque projet pour des informations complémentaires et plus détaillées sur chaque outil.

On travaille ici sur un serveur Debian 8 avec seulement OpenSSH d'installé. Le script se charge d'installer tous les autres éléments sur le serveur. 

Installation
------------

On commence la procédure en se connectant au serveur en SSH avec l'utilisateur linux ROOT.

* Mettre à jour la liste des dépôts Linux
 
  ::  
  
        apt-get update

* Installer sudo
 
  ::  
  
        apt-get install -y sudo ca-certificates

* Créer un utilisateur linux (nommé ``geonatureadmin`` dans notre cas) pour ne pas travailler en ROOT (en lui donnant les droits sudo)
 
  ::  
  
        adduser geonatureadmin sudo

* L'ajouter aussi aux groupes www-data et root
 
  ::  
  
        usermod -g www-data geonatureadmin
        usermod -a -G root geonatureadmin

* Récupérer les scripts d'installation (X.Y.Z à remplacer par le numéro de la `dernière version stable de GeoNature <https://github.com/PnEcrins/GeoNature/releases>`_) :
 
  ::  
  
        wget https://raw.githubusercontent.com/PnEcrins/GeoNature/X.Y.Z/docs/install_all/install_all.ini
        wget https://raw.githubusercontent.com/PnEcrins/GeoNature/X.Y.Z/docs/install_all/install_all.sh

* Changer les droits du fichier d'installation pour pouvoir l'éxecuter
 
  ::  
  
        chmod +x install_all.sh

On se reconnecte avec le nouvel utilisateur pour ne pas faire l'installation en ROOT.

On ne se connectera plus en ROOT. Si besoin d'executer des commandes avec des droits d'administrateur, on les précède de ``sudo``.

On peut d'ailleurs renforcer la sécurité du serveur en bloquant la connexion SSH au serveur avec ROOT.

Voir https://docs.ovh.com/pages/releaseview.action?pageId=18121864 pour plus d'informations sur le sécurisation du serveur. 

Renseigner le fichier de configuration ``install_all.ini`` (avec WinSCP, clic droit puis Editer, puis enregistrer le fichier une fois modifié)

:notes:
    Pour la clé IGN, voir http://geonature.readthedocs.io/fr/latest/installation.html#cle-api-ign-geoportail. 
    Il est conseillé de la créer avant de lancer l'installation. Sinon vous devrez modifier plus tard la clé IGN dans la configuration de GeoNature et de GeoNature-atlas. 
    Si vous accédez aux applications par une IP et non un domaine, il faut quand même la créer en mode referer avec http:// devant l'adresse IP.

* Lancer l'installation
 
  ::  
  
        ./install_all.sh

Connexion aux applications avec les données tests par défaut
------------------------------------------------------------

Tester les applications dans un navigateur web avec l'utilisateur par défaut (admin / admin) : 

- http://ip/geonature
- http://ip/usershub
- http://ip/taxhub
- http://ip/atlas

Si une application renvoie une INTERNAL ERROR, les logs d'Apache peuvent fournir des éléments sur l'erreur. 
Pour les consulter : 
 
::  
  
        sudo tail -f /var/log/apache2/error.log

Dans UsersHub (voir documentation http://usershub.readthedocs.io) :

- On ajoute quelques utilisateurs
- On les met dans les bons groupes
- On vérfie que les groupes sont dans les listes d'observateurs souhaitées
- On met les droits aux groupes dans les applications
- On modifie les organismes

Si vous souhaitez continuer à travailler avec les quelques données tests présentes dans l'installation par défaut, celles-ci sont associées par défaut à l'organisme ``99``. 
Or par défaut, l'atlas n'affiche que les données de l'organisme ``2``. 

Mettez donc les données en cohérence pour qu'elles apparaissent dans l'atlas. 
Pour cela on va modifier l'organisme associés à ces données dans les protocoles sources. 
Dans les données Contact Faune et Flore Station, on change les ``id_organismes`` des données tests pour être en cohérence avec la table ``utilisateurs.bib_organismes``.

Rafraichir les VM de l'atlas pour faire apparaitre les modifications faites dans GeoNature et/ou TaxHub (https://github.com/PnEcrins/GeoNature-atlas/blob/master/docs/vues_materialisees_maj.rst)

Fonctionnement général
----------------------

.. image :: ../images/geonature-all-schema.jpg

**USERSHUB**

- L'application UsersHub dispose de sa propre BDD ``usershubdb``. Chaque modification dans cette base de données faites avec UsersHub est répliquée dans les BDD filles utilisant son schema ``utilisateurs``.
- ``bib_organismes`` contient la liste des organismes. ``t_roles`` la listes des utilisateurs et groupes. ``cor_roles`` permet d'associer des utilisateurs à des groupes.
- Il est conseillé de donner des droits dans des applications à des groupes plutôt qu'à des utilisateurs

**TAXHUB**

- L'applications TaxHub permet de gérer le contenu du schéma ``taxonomie`` de ``geonaturedb``.
- Celui-ci contient le référentiel taxref complet mais il permet d'y selectionner les taxons utilisés, d'y ajouter des informations et de créer des listes de taxons pour les différentes applications
- ``bib_noms`` contient la liste de tous les taxons utilisés par la structure. Cette table s'alimente dans TaxHub en ajoutant des taxons depuis l'onglet TaxRef.
- ``bib_attributs`` permet d'associer des informations complémentaires à chaque taxon. Chaque structure peut créer autant d'attributs qu'elle souhaite.
- Certains attributs sont obligatoires au fonctionnement de GeoNature. ``Saisie`` permet de définir si il est possible de saisir le taxon. ``Patrimonialité`` et ``protégé`` sont requis pour la synthese
- Les attributs ``Description``, ``Commentaire``, ``Milieu`` et ``Chorologie`` sont utilisés par l'atlas
- ``cor_taxon_attribut`` permet de stocker les valeurs des attributs pour chaque taxon
- ``bib_listes`` et ``cor_nom_liste`` permettent de créer des listes de taxons pour les différents protocoles. Il est important de mettre chaque taxon dans les bonnes listes pour qu'ils soit possible de les saisir dans les protocoles correspondants
- ``t_medias`` contient les medias locaux (chemin) ou distants (URL) de chaque taxon pour l'atlas. Il peut s'agir de photos, audios, vidéos ou d'articles

**GEONATURE**

- Chaque protocole dispose de son propre schéma correspondant à son modèle de données. 
- Il est possible d'ajouter autant de schémas que souhaité
- Certains schémas liés à des protocoles intégrés sont fournis (``contactfaune``, ``contactflore``, ``contactinv``, ``florestation``...). 
- A chaque fois qu'une donnée est saisie dans un de ces protocoles, un trigger alimente automatiquement la synthèse de GeoNature
- Pour chaque donnée, on renseigne une source, un lot, un programme et un protocole

**GEONATURE-ATLAS**

- L'application GeoNature-atlas dispose sa propre BDD ``geonatureatlasdb`` pour pouvoir être installé sur un autre serveur
- GeoNature-atlas se base uniquement sur des vues matérialisées pour pouvoir être totalement indépendante de GeoNature et pouvoir être alimenté par n'importe qu'elle autre source de données
- Dans notre cas GeoNature-atlas est alimenté par les données présentes dans la synthèse de GeoNature
- Pour disposer des données de la synthèse ainsi que des informations taxonomiques sans les répliquer, un mécanisme de Foreign Data Wrapper (FDW) est utilisé. 
- Les vues matérialisées nécessaires à GeoNature-atlas s'appuient dans notre cas sur les tables filles utilisant ces FDW
- Il est nécessaire de rafraichir les vues matérialisées pour que GeoNature-atlas prenne en compte tout changement dans la synthèse ou la taxonomie de ``geonaturedb``. 
- Ce rafraichissement peut-être réalisé manuellement ou automatiquement

Consultez le MCD complet pour en savoir plus : https://github.com/PnEcrins/GeoNature/blob/develop/docs/2017-01-mcd_geonaturedb_1.8.2.png

Intégration des données existantes dans GeoNature
-------------------------------------------------

On va maintenant copier les données de SERENA dans la BDD de GeoNature. 

Cela pour les stocker et y accéder sous leur forme brute mais aussi pour les intégrer dans la synthèse de GeoNature et dans l'atlas.

Dans notre cas, les données ont été copiées de la BDD Access de SERENA vers une BDD PostGIS locale dans un schéma spécifique. 

La structure de ce schéma ainsi que les données ont été exportées dans 2 fichiers SQL séparés. 

Ces fichiers sont copiés sur le serveur puis éxécutés dans la BDD ``geonaturedb``.

* Création du schéma ``serena_affo_pnr`` et de ses tables qui accueilleront les données SERENA brutes
 
  ::  
  
        export PGPASSWORD=MONPASSACHANGER;psql -d geonaturedb -U geonatuser -h localhost -f serena_affo_pnr_schema.sql  &>> geonature/log/install_db_serena_1.log

* Intégration des données SERENA brutes dans le schéma ``serena_affo_pnr``
 
  ::  
  
        export PGPASSWORD=MONPASSACHANGER;psql -d geonaturedb -U geonatuser -h localhost -f serena_affo_pnr_donnees.sql  &>> geonature/log/install_db_serena_2.log

* Idéalement on devrait créer une vue matérialisée (VM) basée sur ces données mais par manque de temps on va repartir de la table à plat contenant les geométries générées par le PNR.
 
  ::  
  
        export PGPASSWORD=MONPASSACHANGER;psql -d geonaturedb -U geonatuser -h localhost -f serena_affo_pnr_vm_schema.sql  &>> geonature/log/install_db_serena_6.log
        export PGPASSWORD=MONPASSACHANGER;psql -d geonaturedb -U geonatuser -h localhost -f serena_affo_pnr_vm_donnees.sql  &>> geonature/log/install_db_serena_7.log

C'est cette table que l'on utilisera pour remplir la table ``synthese.syntheseff``.

Les éléments suivants sont éxécutés en SQL avec l'utilisateur propriétaire des BDD (``user_pg``), en utilisant pgAdmin.

* Mettre à jour de la couche des communes de GeoNature (à partir des départements dans notre cas) : 
 
  ::  
  
        UPDATE layers.l_communes SET organisme = true
        WHERE inseedep IN ('14','50','53','61','72')

* Pour alléger la BDD et les traitements, on supprime toutes les communes en dehors de ces 5 départements :
 
  ::  
  
        DELETE FROM layers.l_communes
        WHERE inseedep NOT IN ('14','50','53','61','72')

On va maintenant préparer le schéma ``taxonomie`` pour y intégrer les taxons observés par le PNR et les mettre dans les bonnes listes (voir documentation de TaxHub)

Vider la table ``taxonomie.bib_noms`` et ses tables liées pour supprimer les taxons exemples. 

Idem avec les autres tables de geonaturedb qui contiennent quelques données exemple (``synthese.syntheseff``, ``contactfaune.t_fiches_cf``,...).

* Peupler ``taxonomie.bib_noms`` (liste des espèces du territoire) à partir des espèces observées dans les observations SERENA : 
 
  ::  
  
        INSERT INTO taxonomie.bib_noms (cd_nom,cd_ref,nom_francais) 
        SELECT DISTINCT	rnf.taxon_mnhn_id, t.cd_ref, t.nom_vern FROM serena_affo_pnr_vm.rnf_obse_geom rnf
        JOIN taxonomie.taxref t ON t.cd_nom = rnf.taxon_mnhn_id
        -- pour éviter les doublons si des espèces sont déjà présentes dans bib_noms :
        LEFT JOIN taxonomie.bib_noms tb ON tb.cd_nom = rnf.cd_nom
        WHERE tb.cd_nom IS NULL

Attention il semblerait que 39 taxons n'aient pas été intégrés, certainement car ils n'ont pas d'identifiant taxref ? A vérifier. 

Cela aura peut-être d'autres conséquences sur l'intégration des données dans la synthèse. A vérifier.

Vérifier aussi la version de TaxRef utilisée pour les données sources et la version utilisée par TaxHub pour être en cohérence. 

* Pour ne pas avoir de noms français vides dans ``taxonomie.bib_noms`` : 
 
  ::  
  
        UPDATE taxonomie.bib_noms SET nom_francais = '' WHERE nom_francais IS NULL

* Renseigner ``taxonomie.cor_taxon_attribut`` pour pouvoir saisir ces taxons (Saisie = oui)
 
  ::  
  
        INSERT INTO taxonomie.cor_taxon_attribut (id_attribut,valeur_attribut,cd_ref)
        SELECT 3,'oui',n.cd_ref FROM taxonomie.bib_noms n
        GROUP BY n.cd_ref;

* Mettre tous les taxons à non protégés et non patrimonial par défaut (dans ``taxonomie.cor_taxon_attribut``) car cette info est attendue par la synthèse. A retravailler au cas par cas ou à partir des infos présentes dans TaxRef
 
  ::  
  
        INSERT INTO taxonomie.cor_taxon_attribut (id_attribut,valeur_attribut,cd_ref)
        SELECT 1,'non',n.cd_ref FROM taxonomie.bib_noms n
        GROUP BY n.cd_ref;
 
  ::  
  
        INSERT INTO taxonomie.cor_taxon_attribut (id_attribut,valeur_attribut,cd_ref)
        SELECT 2,'non',n.cd_ref FROM taxonomie.bib_noms n
        GROUP BY n.cd_ref;

* Peupler les listes de taxons (``taxonomie.cor_nom_liste`` faisant référence à ``taxonomie.bib_listes``) en se basant sur les groupes INPN. A voir si les infos des groupes dans TaxRef sont fiables et complètes. A adapter selon vos données et taxons observés.
 
  ::  
  
        INSERT INTO taxonomie.cor_nom_liste (id_liste,id_nom) 
        SELECT 1,n.id_nom FROM taxonomie.bib_noms n
        JOIN taxonomie.taxref t ON t.cd_nom = n.cd_nom
        where t.group2_inpn = 'Amphibiens';
 
  ::  
  
        INSERT INTO taxonomie.cor_nom_liste (id_liste,id_nom) 
        SELECT 11,n.id_nom FROM taxonomie.bib_noms n
        JOIN taxonomie.taxref t ON t.cd_nom = n.cd_nom
        where t.group2_inpn = 'Mammifères';
 
  ::  
  
        INSERT INTO taxonomie.cor_nom_liste (id_liste,id_nom) 
        SELECT 12,n.id_nom FROM taxonomie.bib_noms n
        JOIN taxonomie.taxref t ON t.cd_nom = n.cd_nom
        where t.group2_inpn = 'Oiseaux';
 
  ::  
  
        INSERT INTO taxonomie.cor_nom_liste (id_liste,id_nom) 
        SELECT 13,n.id_nom FROM taxonomie.bib_noms n
        JOIN taxonomie.taxref t ON t.cd_nom = n.cd_nom
        where t.group2_inpn = 'Poissons';
 
  ::  
  
        INSERT INTO taxonomie.cor_nom_liste (id_liste,id_nom) 
        SELECT 14,n.id_nom FROM taxonomie.bib_noms n
        JOIN taxonomie.taxref t ON t.cd_nom = n.cd_nom
        where t.group2_inpn = 'Reptiles';
 
  ::  
  
        INSERT INTO taxonomie.cor_nom_liste (id_liste,id_nom) 
        SELECT 1001,n.id_nom FROM taxonomie.bib_noms n
        JOIN taxonomie.taxref t ON t.cd_nom = n.cd_nom
        where t.group2_inpn in ('Amphibiens','Mammifères','Oiseaux','Poissons','Reptiles');
 
  ::  
  
        INSERT INTO taxonomie.cor_nom_liste (id_liste,id_nom) 
        SELECT 1003,n.id_nom FROM taxonomie.bib_noms n
        JOIN taxonomie.taxref t ON t.cd_nom = n.cd_nom
        where t.regne ='Plantae';
 
  ::  
  
        INSERT INTO taxonomie.cor_nom_liste (id_liste,id_nom) 
        SELECT 301,n.id_nom FROM taxonomie.bib_noms n
        JOIN taxonomie.taxref t ON t.cd_nom = n.cd_nom
        where t.group2_inpn = 'Mousses';
 
  ::  
  
        INSERT INTO taxonomie.cor_nom_liste (id_liste,id_nom) 
        SELECT 302,n.id_nom FROM taxonomie.bib_noms n
        JOIN taxonomie.taxref t ON t.cd_nom = n.cd_nom
        where t.group2_inpn = 'Lichens';
 
  ::  
  
        INSERT INTO taxonomie.cor_nom_liste (id_liste,id_nom) 
        SELECT 303,n.id_nom FROM taxonomie.bib_noms n
        JOIN taxonomie.taxref t ON t.cd_nom = n.cd_nom
        where t.group2_inpn in ('Algues brunes','Algues rouges','Algues vertes');
 
  ::  
  
        INSERT INTO taxonomie.cor_nom_liste (id_liste,id_nom) 
        SELECT 305,n.id_nom FROM taxonomie.bib_noms n
        JOIN taxonomie.taxref t ON t.cd_nom = n.cd_nom
        where t.group2_inpn = 'Fougères';
 
  ::  
  
        INSERT INTO taxonomie.cor_nom_liste (id_liste,id_nom) 
        SELECT 306,n.id_nom FROM taxonomie.bib_noms n
        JOIN taxonomie.taxref t ON t.cd_nom = n.cd_nom
        where t.ordre IN ('Acorales','Asparagales','Alismatales','Dioscoreales','Geraniales','Liliales','Pandanales','Arecales','Petrosaviales','Poales','Commelinales','Zingiberales');
 
  ::  
  
        INSERT INTO taxonomie.cor_nom_liste (id_liste,id_nom) 
        SELECT 307,n.id_nom FROM taxonomie.bib_noms n
        JOIN taxonomie.taxref t ON t.cd_nom = n.cd_nom
        where t.ordre IN ('Canellales','Laurales','Magnoliales','Piperales','Buxales','Proteales','Trochodendrales','Ranunculales','Caryophyllales','Gunnerales','Santalales','Saxifragales','Vitales','Célastrales','Cucurbitales','Fabales','Fagales','Rosales','Malpighiales','Oxalidales','Zygophyllales','Brassicales','Crossomatales','Géraniales','Huerteales','Malvales','Myrtales','Picramiales','Sapindales','Cornales','Ericales','Garryales','Gentianales','Lamiales','Solanales','Apiales','Aquifoliales','Asterales','Bruniales','Dipsacales','Escalioniales','Paracryphyales');
 
  ::  
  
        INSERT INTO taxonomie.cor_nom_liste (id_liste,id_nom) 
        SELECT 2,n.id_nom FROM taxonomie.bib_noms n
        JOIN taxonomie.taxref t ON t.cd_nom = n.cd_nom
        where t.group2_inpn = 'Annélides';
 
  ::  
  
        INSERT INTO taxonomie.cor_nom_liste (id_liste,id_nom) 
        SELECT 5,n.id_nom FROM taxonomie.bib_noms n
        JOIN taxonomie.taxref t ON t.cd_nom = n.cd_nom
        where t.group2_inpn = 'Crustacés';
 
  ::  
  
        INSERT INTO taxonomie.cor_nom_liste (id_liste,id_nom) 
        SELECT 8,n.id_nom FROM taxonomie.bib_noms n
        JOIN taxonomie.taxref t ON t.cd_nom = n.cd_nom
        where t.group2_inpn = 'Gastéropodes';
 
  ::  
  
        INSERT INTO taxonomie.cor_nom_liste (id_liste,id_nom) 
        SELECT 9,n.id_nom FROM taxonomie.bib_noms n
        JOIN taxonomie.taxref t ON t.cd_nom = n.cd_nom
        where t.group2_inpn = 'Insectes';
 
  ::  
  
        INSERT INTO taxonomie.cor_nom_liste (id_liste,id_nom) 
        SELECT 10,n.id_nom FROM taxonomie.bib_noms n
        JOIN taxonomie.taxref t ON t.cd_nom = n.cd_nom
        where t.group2_inpn = 'Bivalves';
 
  ::  
  
        INSERT INTO taxonomie.cor_nom_liste (id_liste,id_nom) 
        SELECT 15,n.id_nom FROM taxonomie.bib_noms n
        JOIN taxonomie.taxref t ON t.cd_nom = n.cd_nom
        where t.group2_inpn = 'Myriapodes';
 
  ::  
  
        INSERT INTO taxonomie.cor_nom_liste (id_liste,id_nom) 
        SELECT 16,n.id_nom FROM taxonomie.bib_noms n
        JOIN taxonomie.taxref t ON t.cd_nom = n.cd_nom
        where t.group2_inpn = 'Arachnides';
 
  ::  
  
        INSERT INTO taxonomie.cor_nom_liste (id_liste,id_nom) 
        SELECT 1002,n.id_nom FROM taxonomie.bib_noms n
        JOIN taxonomie.taxref t ON t.cd_nom = n.cd_nom
        where t.group2_inpn in ('Arachnides','Myriapodes','Bivalves','Insectes','Gastéropodes','Crustacés','Annélides');

* Créer une SOURCE pour les données SERENA dans ``synthese.bib_sources``

  ::  
  
        8;"Serena";"Données saisies avec SERENA (jusqu'à novembre 2016)";"localhost";22;"";"";"geonaturedb";"serena_affo_pnr_vm";"rnf_obse_geom";""OBSE_ID"";"";"";"";"FAUNE";FALSE

:notes:
    Probleme dans ``synthese.bib_sources`` du champ GROUPE en NOT NULL alors que dans BDD du PNE c'est pas le cas. 
    Hors pour toutes les sources externes, le groupe n'a pas d'intérêt. Et pour SERENA, y a pas vraiment de groupe.
    Du coup on a mis FAUNE même si c'est pas très cohérent pour SERENA dont on n'a pas besoin de renseigner le groupe. 
 
Préparer le contenu des autres tables de métadonnées liées aux données sources avec de les intégrer dans la synthèse.

* Dans ``meta.bib_programmes``

  ::  
  
        8;"Historique";"Données historiques";TRUE;TRUE;"Données SERENA et autres ?"

* Dans ``meta.bib_lots``

  ::  
  
        8;"Historique SERENA";"Données saisies avec SERENA jusqu'en novembre 2016";FALSE;TRUE;FALSE;1

* Dans ``meta.t_protocoles``

  ::  
  
        id_protocole = 0;"Aucune info" 

On peut maintenant intégrer les données SERENA dans la synthèse de GeoNature.

* Créer une table synthèse temporaire (pas obligatoire mais c'est une sécurité dans notre cas expérimental)

  ::  
  
        CREATE TABLE synthese.syntheseff_temp
        (
          id_synthese integer,
          id_source integer,
          id_fiche_source character varying(50),
          code_fiche_source character varying(50),
          id_organisme integer,
          id_protocole integer,
          id_precision integer,
          cd_nom integer,
          insee character(5),
          dateobs date NOT NULL,
          observateurs character varying(255),
          determinateur character varying(255),
          altitude_retenue integer,
          remarques text,
          date_insert timestamp without time zone,
          date_update timestamp without time zone,
          derniere_action character(1),
          supprime boolean,
          the_geom_point geometry,
          id_lot integer,
          id_critere_synthese integer,
          the_geom_3857 geometry,
          effectif_total integer,
          the_geom_2154 geometry,
          diffusable boolean DEFAULT true)

* On y insère les données SERENA. Largement améliorable. En se basant sur les tables brutes et/ou une VM et en affinant la requête.

  ::  
  
        INSERT INTO synthese.syntheseff_temp  
        SELECT 
        	1 AS id_synthese,
        	8 AS id_source, 
        	"OBSE_ID"::text as id_fiche_source, 
        	"OBSE_RELV_ID"::text as code_fiche_source, 
        	2 AS id_organisme, 
        	0 AS id_protocole, 
        	12 AS id_precision, 
        	taxon_mnhn_id AS cd_nom, 
        	sig_commune_insee AS insee, 
        	CASE 
        	 WHEN length("OBSE_DATE") = 8 THEN (left("OBSE_DATE",4)||'-'||substring("OBSE_DATE" from 5 for 2)||'-'||right("OBSE_DATE",2))::date
        	 WHEN length("OBSE_DATE") = 6 THEN (left("OBSE_DATE",4)||'-'||substring("OBSE_DATE" from 5 for 2)||'-01')::date
        	 WHEN length("OBSE_DATE") = 4 THEN (left("OBSE_DATE",4)||'-01-01')::date
        	 ELSE ('1000-01-01')::date
        	END as dateobs,
        	"SRCE_COMPNOM_C" AS observateurs,
        	'' AS determinateur, 
        	"OBSE_ALT"::int AS altitude_retenue, 
        	"OBSE_COMMENT" AS remarques, 
        	now() AS date_insert, 
        	now() AS date_update, 
        	'c' AS derniere_action, 
        	false AS supprime, 
        	st_transform(st_centroid(geom),3857) AS the_geom_point, 
        	8 AS id_lot, 
        	1 AS id_critere_synthese, 
        	st_transform(geom, 3857) AS the_geom_3857, 
        	1 AS effectif_total, 
        	geom AS the_geom_2154, 
        	true AS diffusable
          FROM serena_affo_pnr_vm.rnf_obse_geom

:notes:
    - On pourrait retrouver l'ID des protocoles dans ``serena."RNF_RELV"`` car dans la table à plat on n'a que ``RELV_NOM``. A caler avec ``meta.t_protocoles``.
    - On pourrait retrouver l'ID des organismes dans ``serena."RNF_SRCE"`` ou le recréer dans UsersHub car dans la table à plat on n'a que ``RELV_PROP_LIBEL`` // ``SELECT DISTINCT "RELV_PROP_LIBEL" FROM serena_affo_pnr_vm.rnf_obse_geom``.
    - Pour renseigner ``id_precision``, on pourrait utiliser le champs ``type_geoloc``. 
    - Pour la géométrie, on ferait mieux de garder le geom original (maille, commune, ...) car la synthese a 2 champs pour cela. Un pour la geometrie originale et son centroïde.
    - Il y a des x dans ``OBSE_NOMBRE``, du coup on ne peut pas utiliser ce champs pour lequel on attend un nombre entier. On met 1 par défaut. On pourrait affiner en excluant les valeurs X et intégrant les autres valeurs quand il s'agit bien d'un numérique.

  
Désactiver les 4 triggers de la table ``synthese.syntheseff`` (avec pgAdmin).

* Copier les données dans la table ``synthese.syntheseff`` depuis la table ``synthese.syntheseff_temp``

  ::  
  
        INSERT INTO synthese.syntheseff 
         (id_source,
          id_fiche_source,
          code_fiche_source,
          id_organisme,
          id_protocole,
          id_precision,
          cd_nom,
          insee,
          dateobs,
          observateurs,
          determinateur,
          altitude_retenue,
          remarques,
          date_insert,
          date_update,
          derniere_action,
          supprime,
          the_geom_point,
          id_lot,
          id_critere_synthese,
          the_geom_3857,
          effectif_total,
          the_geom_2154,
          diffusable)
        SELECT 
          id_source,
          id_fiche_source,
          code_fiche_source,
          id_organisme,
          id_protocole,
          id_precision,
          cd_nom,
          insee,
          dateobs,
          observateurs,
          determinateur,
          altitude_retenue,
          remarques,
          date_insert,
          date_update,
          derniere_action,
          supprime,
          st_transform(the_geom_point,3857),
          id_lot,
          id_critere_synthese,
          ST_SetSRID(the_geom_3857,3857),
          effectif_total,
          ST_SetSRID(the_geom_2154,2154),
          diffusable
         FROM synthese.syntheseff_temp
 

Avec pgAdmin, faire un VACUUM et un REINDEX (clic droit sur la couche / Maintenance)

Pour intégrer les unités géographiques (qui vont permettre d'orienter les saisies du contact), on part des mailles 5 km de l'INPN.

On les ouvre avec QGIS, on ouvre aussi 2 tables de la BDD ``geonaturedb`` : ``layers.l_unites_geo`` et ``layers.l_communes``.

On intersecte la couche des communes avec celles des mailles INPN pour ne garder que les mailles présentes dans les communes étudiées. 

On copie colle ensuite les mailles dans ``layers.l_unites_geo``. Il leur faut un identifiant unique, donc on utilise la calculatrice de champs pour mettre à jour le champs ``id_unite_geo`` avec la fonctionn QGIS ``$rownum``.

On sort du mode édition, les mailles sont alors insérées dans la BDD dans la table ``layers.l_unites_geo``.

On réactive le trigger ``tri_maj_cor_unite_synthese`` puis on déclenche l'intersection entre toutes les observations et toutes les unités géographiques (mailles 5 km dans notre cas) : 

::  
  
        UPDATE synthese.syntheseff SET the_geom_2154 = the_geom_2154

Faire la même chose pour remplir les zones à statut (``layers.bib_typeszones`` et ``layers.l_zonesstatut``).

Réactiver les autres triggers.

Compléments GeoNature
---------------------

Le "Où ?" de la synthèse n'est pas encore très au point. La liste des communes ne remonte pas car elles ne sont pas rattachées à un secteur (Généricité à revoir). 

Toutes les réserves et les sites Natura 2000 de France remontent. A nettoyer si besoin dans la base pour ne garder que celles du territoire étudié.

Aucun taxon n'est tagué patrimonial ni protégé. Pour les protections, il y a un travail d'analyse des textes à faire dans ``taxonomie.protection_articles``. (Cocher correctement le champ ``concerne_mon_territoire`` puis utiliser ``taxonomie.taxref_protection_especes`` pour mettre à jour la table ``taxonomie.cor_taxon_attribut``.

Il y a donc encore du travail sur les données pour un fonctionnement normal.

Problème identifié dans la 1.8.0 : La synthèse ne se charge pas, c'est la vue ``synthese.v_tree_taxons_synthese`` qui n'aboutit pas car une donnée ne trouve aucun REGNE dans TaxRef.
La vue sera corrigée dans GeoNature 1.8.1.

Dans les données SERENA du PNR, il y avait 678 données avec des geom vides.

Créer une table ``invalid_synthese`` pour les mettre de côté.

::  
  
        CREATE TABLE synthese.invalid_synthese
        (
          id_synthese integer NOT NULL,
          id_source integer,
          id_fiche_source character varying(50),
          code_fiche_source character varying(50),
          id_organisme integer,
          id_protocole integer,
          id_precision integer,
          cd_nom integer,
          insee character(5),
          dateobs date NOT NULL,
          observateurs character varying(255),
          determinateur character varying(255),
          altitude_retenue integer,
          remarques text,
          date_insert timestamp without time zone,
          date_update timestamp without time zone,
          derniere_action character(1),
          supprime boolean,
          the_geom_point geometry,
          id_lot integer,
          id_critere_synthese integer,
          the_geom_3857 geometry,
          effectif_total integer,
          the_geom_2154 geometry,
          diffusable boolean DEFAULT true,
          CONSTRAINT invalid_synthese_pkey PRIMARY KEY (id_synthese)
          );
          COMMENT ON TABLE synthese.invalid_synthese
          IS 'Table des données de synthèse invalides';

        INSERT INTO synthese.invalid_synthese;
        SELECT * FROM synthese.syntheseff WHERE the_geom_3857 IS null;
        DELETE FROM synthese.syntheseff WHERE the_geom_3857 IS null;


Pour en savoir plus et aller plus loin avec GeoNature, voir la présentation (https://github.com/PnEcrins/GeoNature) et la documentation (http://geonature.readthedocs.io/).

Customisation de l'atlas
------------------------

Charger les bonnes couches SHP des communes et du territoire sur le serveur dans ``atlas/data/ref/``. 

Dans notre cas, on se limite au territoire du PNR pour le moment.

Relancer l'installation de la BDD :

::  
  
        cd atlas
        sudo ./install_db.sh

La configuration de l'atlas se trouve dans ``atlas/main/configuration/config.py``.

La customisation se fait uniquement dans ``atlas/static/custom``.

On peut y modifier les templates, ajouter ou modifier les images, créer un glossaire ou encore surcoucher les styles CSS (exemple : http://biodiversite.ecrins-parcnational.fr/static/custom/custom.css).

Il est aussi possible de modifier les vues matérialisées pour adapter le contenu de l'atlas.

Pour plus de détail sur le fonctionnement de GeoNature-atlas voir sa documentation générale : https://github.com/PnEcrins/GeoNature-atlas/blob/master/docs/installation.rst.

Le détail des vues matérialisées : https://github.com/PnEcrins/GeoNature-atlas/blob/master/docs/vues_materialisees_maj.rst.

Les présentations PDF du projet : https://github.com/PnEcrins/GeoNature-atlas/tree/master/docs.

Pour aller plus loin
--------------------

- Suivre les 4 projets sur Github (Watch en haut à droite de chaque projet)
- Créer des tickets (issues) pour tout bug ou question
- Proposer des évolutions du code en faisant des pull requests dans Github
- Mettre à jour les applications en suivant les procédures et en lisant bien les nouveautés de chaque version
- Mettre en place des sauvegardes automatiques des données
