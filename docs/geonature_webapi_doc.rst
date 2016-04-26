=======
WEB API
=======

La web API GeoNature est un service web REST. Les informations sont transmises au format JSON ou GeoJSON.
Il est possible d'utiliser les méthodes HTTP ``POST``, ``PUT``, ``DELETE``.
Les données manipuler par le service se trouvent dans la table ``synthese.syntheseff``.
Toutes les méthodes http doivent être transmise avec les 2 paramètres ``token`` et ``json`` sauf la méthode ``DELETE`` qui peut fonctionner sans le paramètre ``json``.

token :
    description : clé secrète. Si non conforme ou non fournie le service retourne une erreur.
    type : string
    obligatoire : oui
    valeur par défaut : none
json :
    description : paramètre au format JSON ou GeoJSON .
    type : string
    obligatoire : oui
    valeur par défaut : none
    

Insertion d'une observation
===========================

Méthode HTTP à utiliser : POST
url : synthese/observation?token=[votre_token]&json=[votre_geojson]
param :
    token : requis (voir ci-dessus)
    json :
        format : GeoJSON
        contenu :    
            type: requis. Seul le type "Feature" est implémenté. Ne pas utiliser de geoJSON avec le type FeatureCollection.
            geometry: requis. 
                type: requis. valeurs possible Point, LineString, Polygon
                    type : string
                    obligatoire : oui
                    valeur par défaut : none
                coordinates : requis.
                    type : tableau de valeur. Exemple [6.5, 44.85] pour un point.
                    description : les coordonnées doivent être fournies avec le SRID 4326. Exemple [6.5, 44.85] pour un point. Voir les spécifications sur http://geojson.org/
                    obligatoire : oui
            properties :
                id_source : 
                    description : identifiant de la source de la donnée. Cet identifiant est une clé étrangère et doit être présent dans la table ``synthese.bib_sources``. Au besoin, il faut le créer préalablement à tout enregistrement. Si l'id_source n'est pas fourni, l'enregistrement est créé avec l'id_source = 0.
                    type : integer
                    obligatoire : oui
                    valeur par défaut : 0
                id_fiche_source : 
                    description : identifiant correspondant à la clé primaire dans la table d'origine. Cet identifiant correspond au champ ``id_fiche_source``. Couplé au ``id_source`` il forme une valeur unique correspondant à la clé primaire de l'enregistrement présent dans la table d'origine (=enregistrement présent dans une base distante).
                    type : varchar(50)
                    obligatoire : oui
                    valeur par défaut : none
                code_fiche_source : 
                    description : cet identifiant peut être utilisé pour tracer une source dont les enregistrements figurent dans plusieurs tables (concaténation de l'id de plusieurs tables).
                    type : varchar(50)
                    obligatoire : non
                    valeur par défaut : none
                id_organisme : 
                    description : identifiant de l'organisme propriétaire de la donnée. Cet identifiant est une clé étrangère et doit être présent dans la table ``utilisateurs.bib_organismes``.
                    type : integer
                    obligatoire : oui
                    valeur par défaut : none
                id_protocole : 
                    description : identifiant du protocole ayant servi au recueil de la donnée. Cet identifiant est une clé étrangère et doit être présent dans la table ``meta.t_protocoles``.
                    type : integer
                    obligatoire : oui
                    valeur par défaut : none
                id_precision : 
                    description : identifiant du niveau de précision à l'origine de la production de la donnée. Cet identifiant est une clé étrangère et doit être présent dans la table ``meta.t_précisions``.
                    type : integer
                    obligatoire : oui
                    valeur par défaut : none
                id_lot : 
                    description : identifiant a un lot de données. Cet identifiant est une clé étrangère et doit être présent dans la table ``meta.bib_lots``; Les lots sont regroupés dans des programmes (``meta.bib_programmes``). Dans geoNature les programmes correspondent aux filtres de recherche dans le "comment ?" de l'interface.
                    type : integer
                    obligatoire : oui
                    valeur par défaut : none
                id_critere_synthese : 
                    description : identifiant du critère ayant permis l'observation. Cet identifiant est une clé étrangère et doit être présent dans la table ``synthese.bib_criteres_synthese``.
                    type : integer
                    obligatoire : oui
                    valeur par défaut : none
                cd_nom : 
                    description : identifiant du taxon observé (voir taxref). Cet identifiant est une clé étrangère et doit être présent dans la table ``taxonomie.taxref``.
                    type : integer
                    obligatoire : oui
                    valeur par défaut : none
                effectif_total : 
                    description : nombre d'individus observés.
                    type : integer
                    obligatoire : non
                    valeur par défaut : none
                insee : 
                    description : insee de la commune correspondant à la localisation de l'observation. La liste des communes est présente dans la table ``layers.l_communes``. 
                    type : varchar(5)
                    obligatoire : non
                    valeur par défaut : none
                dateobs : 
                    description : date de l'observation. format "aaaa-mm-jj". Exemple : 2015-07-28.
                    type : date
                    obligatoire : oui
                    valeur par défaut : none
                observateurs : 
                    description : le ou les observateur(s) de la donnée. Format libre (string) limité à 255 caractères.
                    type : varchar(255)
                    obligatoire : oui
                    valeur par défaut : none
                determinateur : 
                    description : le déterminateur de la donnée. Format libre (string) limité à 255 caractères.
                    type : varchar(255)
                    obligatoire : non
                    valeur par défaut : none
                altitude : 
                    description : altitude correspondant à la localisation de l'observation.
                    type : integer
                    obligatoire : non
                    valeur par défaut : none
                remarques : 
                    description : Champ libre permettant de fournir toutes information utile relative à l'observation. Pas de limite de taille.
                    type : text
                    obligatoire : non
                    valeur par défaut : none
                    
    Données des tables liées : 
        Lorsqu'il est fait référence au contenu des tables liées : "Cet identifiant est une clé étrangère et doit être présent dans la table ...". 
        Ces données étant susceptibles d'être modifiées par l'administrateur de GeoNature, vous devez vous référer au contenu des tables liées en consultant le contenu des ces tables dans votre base de données de GeoNature.
    
    Exemple de GeoJSON compatible pour une insertion de données: 
        {
            "type": "Feature"
            ,"geometry": 
            {
                "type": "Point"
                ,"coordinates": [6.5, 44.85]
            }
            ,"properties": {
                "id_source" : 18
                ,"id_fiche_source" : "36513"
                ,"code_fiche_source" : "oc36513"
                ,"id_organisme" : 1
                ,"id_protocole" : 2
                ,"id_precision" : 1
                ,"dateobs" : "2015-11-30"
                ,"cd_nom" : 67111
                ,"effectif_total" : 10
                ,"insee" : "05006"
                ,"altitude" : 1000
                ,"observateurs" : "Paulo l'observateur"
                ,"determinateur" : "Paulo le déterminateur"
                ,"remarques" : "une remarque de test"
                ,"id_lot" : 2
                ,"id_critere_synthese" : 2  
            }
        }
        
    Return : 
        format : JSON
            success : boolean - true ou false
            message : string - Information concernant l'erreur rencontrée.
            id_synthese : integer - Identifiant nouvellement créé dans la table synthese.syntheseff. Peut constituer un lien entre la donnée d'origine et la donnée enregistrée dans geoNature.
            id_source : integer - Identifiant de la source référençant la donnée nouvellement créé dans la table synthese.syntheseff
            id_fiche_source : integer - Clé primaire dans la table d'origine de la donnée nouvellement créé dans la table synthese.syntheseff. Peut constituer un lien entre la donnée d'origine et la données enregistrée dans geoNature.


Modification d'une observation
==============================

Méthode HTTP à utiliser : PUT
url : synthese/observation/[id_synthese]?token=[votre_token]&json=[votre_geojson]

Deux manières de modifier un enregistrement :
1/ en fournissant le ``id_synthese`` dans l'url. Par exemple synthese/observation/68?token=mon;token!hyper#complexe
2/ en fournissant le ``id_source`` et le ``id_fiche_source`` dans le paramètre ``json`` (voir ci-dessous). Dans ce cas, l'url ne contient pas l'id_synthese --> synthese/observation?token=mon;token!hyper#complexe

param :
    id_synthese : optionnel 
    token : requis (voir ci-dessus)
    json :
        format : GeoJSON
        contenu : Les informations de l'objet ``properties`` ne doivent pas forcement être toutes fournies, de même que les informations concernant l'objet ``geometry``
            type: optionnel. Requis avec la valeur "Feature" et l'objet ``geometry`` si la géometrie doit être mise à jour.
            geometry: optionnel. Requis avec l'objet ``type`` si la géometrie doit être mise à jour.
                type: requis. valeurs possible Point, LineString, Polygon
                    type : string
                    obligatoire : oui
                    valeur par défaut : none
                coordinates : requis.
                    type : tableau de valeur. Exemple [6.5, 44.85] pour un point.
                    description : les coordonnées doivent être fournies avec le SRID 4326. Exemple [6.5, 44.85] pour un point. Voir les spécifications sur http://geojson.org/
                    obligatoire : oui
            properties : requis
                id_source : 
                    description : identifiant de la source de la donnée. Cet identifiant doit être présent dans la table ``synthese.bib_sources``.
                    type : varchar(50)
                    obligatoire : optionnel (si non fourni, fournir le id_synthese dans l'url)
                    valeur par défaut : 0
                id_fiche_source : 
                    description : identifiant correspondant à la clé primaire dans la table d'origine. Cet identifiant correspond au champ ``id_fiche_source``. Couplé au ``id_source`` il forme une valeur unique correspondant à la clé primaire de l'enregistrement présent dans la table d'origine (=enregistrement présent dans une base distante).
                    type : varchar(50)
                    obligatoire : optionnel (si non fourni, fournir le id_synthese dans l'url)
                    valeur par défaut : none
                code_fiche_source : 
                    description : cet identifiant peut être utilisé pour tracer une source dont les enregistrements figure dans plusieurs tables (concaténation de l'id de plusieurs tables).
                    type : varchar(50)
                    obligatoire : non
                    valeur par défaut : none
                id_organisme : 
                    description : identifiant de l'organisme propriétaire de la donnée. Cet identifiant est une clé étrangère et doit être présent dans la table ``utilisateurs.bib_organismes``.
                    type : integer
                    obligatoire : non
                    valeur par défaut : none
                id_protocole : 
                    description : identifiant du protocole ayant servi au recueil de la donnée. Cet identifiant est une clé étrangère et doit être présent dans la table ``meta.t_protocoles``.
                    type : integer
                    obligatoire : non
                    valeur par défaut : none
                id_precision : 
                    description : identifiant du niveau de précision à l'origine de la production de la donnée. Cet identifiant est une clé étrangère et doit être présent dans la table ``meta.t_précisions``.
                    type : integer
                    obligatoire : non
                    valeur par défaut : none
                id_lot : 
                    description : identifiant a un lot de données. Cet identifiant est une clé étrangère et doit être présent dans la table ``meta.bib_lots``; Les lots sont regroupés dans des programmes (``meta.bib_programmes``). Dans geoNature les programmes correspondent aux filtres de recherche dans le "comment ?" de l'interface.
                    type : integer
                    obligatoire : non
                    valeur par défaut : none
                id_critere_synthese : 
                    description : identifiant du critère ayant permis l'observation. Cet identifiant est une clé étrangère et doit être présent dans la table ``synthese.bib_criteres_synthese``.
                    type : integer
                    obligatoire : non
                    valeur par défaut : none
                cd_nom : 
                    description : identifiant du taxon observé (voir taxref). Cet identifiant est une clé étrangère et doit être présent dans la table ``taxonomie.taxref``.
                    type : integer
                    obligatoire : non
                    valeur par défaut : none
                effectif_total : 
                    description : nombre d'individus observés.
                    type : integer
                    obligatoire : non
                    valeur par défaut : none
                insee : 
                    description : insee de la commune correspondant à la localisation de l'observation. La liste des communes est présente dans la table ``layers.l_communes``. 
                    type : varchar(5)
                    obligatoire : non
                    valeur par défaut : none
                dateobs : 
                    description : date de l'observation. format "aaaa-mm-jj". Exemple : 2015-07-28.
                    type : date
                    obligatoire : non
                    valeur par défaut : none
                observateurs : 
                    description : le ou les observateur(s) de la donnée. Format libre (string) limité à 255 caractères.
                    type : varchar(255)
                    obligatoire : non
                    valeur par défaut : none
                determinateur : 
                    description : le déterminateur de la donnée. Format libre (string) limité à 255 caractères.
                    type : varchar(255)
                    obligatoire : non
                    valeur par défaut : none
                altitude : 
                    description : altitude correspondant à la localisation de l'observation.
                    type : integer
                    obligatoire : non
                    valeur par défaut : none
                remarques : 
                    description : Champ libre permettant de fournir toutes information utile relative à l'observation. Pas de limite de taille.
                    type : text
                    obligatoire : non
                    valeur par défaut : none
                    
    Données des tables liées : 
        Lorsqu'il est fait référence au contenu des tables liées : -Cet identifiant est une clé étrangère et doit être présent dans la table "schéma.table"-. 
        Ces données étant susceptibles d'être modifiées par l'administrateur de GeoNature, vous devez vous référer au contenu des tables liées en consultant le contenu des ces tables dans la base de données de GeoNature.
    
    Exemples de GeoJSON compatible pour une modification de données: 
        {
            "type": "Feature"
            ,"properties": {
                "id_synthese" : 53
                ,"dateobs" : "2014-10-27"
            }
        }
        ou
        {
            "type": "Feature"
            ,"properties": {
                "id_source" : 0
                ,"id_fiche_source" : "36513"
                ,"effectif_total" : 12
                ,"altitude" : 1020
                ,"observateurs" : "Gaston l'observateur" 
            }
        }
        ou
        {
            "type": "Feature"
            ,"geometry": 
            {
                "type": "Point"
                ,"coordinates": [6.58217, 44.84799]
            }
            ,"properties": {
                "id_source" : 18
                ,"id_fiche_source":"99"
            }
        }
        
    Return : 
        format : JSON
            success : bool - true ou false
            message : string - Information concernant l'erreur rencontrée.
            id_synthese : integer - Identifiant nouvellement créé dans la table synthese.syntheseff. Peut constituer un lien entre la donnée d'origine et la données enregistrée dans geoNature.
            id_source : integer - Identifiant de la source référençant la donnée nouvellement créé dans la table synthese.syntheseff
            id_fiche_source : integer - Clé primaire dans la table d'origine de la donnée nouvellement créé dans la table synthese.syntheseff. Peut constituer un lien entre la donnée d'origine et la données enregistrée dans geoNature.
    
    Test :
        avec curl : 
            curl -i -X PUT --header 'Accept:application/json' 'http://92.222.107.92/geonature/synthese/observation/68?token=mon;token!hyper#complexe' -d 'json={"type": "Feature","properties": {"dateobs" : "2013-01-18"}}'
            curl -i -X PUT --header 'Accept:application/json' 'http://92.222.107.92/geonature/synthese/observation?token=mon;token!hyper#complexe' -d 'json={"type": "Feature","properties": {"id_source": 18, "id_fiche_source":"99", "dateobs" : "2013-01-18"}}'
        
        
Suppression d'une observation
=============================

Méthode HTTP à utiliser : DELETE
url : synthese/observation/[id_synthese]?token=[votre_token]&json=[votre_json]

Deux manières de supprimer un enregistrement :
1/ en fournissant le ``id_synthese`` dans l'url. Par exemple synthese/observation/68?token=mon;token!hyper#complexe
2/ en fournissant le ``id_source`` et le ``id_fiche_source`` dans le paramètre ``json`` (voir ci-dessous). Dans ce cas, l'url ne contient pas l'id_synthese --> synthese/observation?token=mon;token!hyper#complexe

param :
    id_synthese : oui si le paramètre ``json`` n'est pas fourni 
    token : requis (voir ci-dessus)
    json:
        format : JSON
        contenu :
            id_source : 
                description : identifiant de la source de la donnée. Cet identifiant doit être présent dans la table ``synthese.bib_sources``.
                type : varchar(50)
                obligatoire : oui si le paramètre ``id_synthese`` n'est pas fourni 
                valeur par défaut : 0
            id_fiche_source : 
                description : identifiant correspondant à la clé primaire dans la table d'origine. Cet identifiant correspond au champ ``id_fiche_source``. Couplé au ``id_source`` il forme une valeur unique correspondant à la clé primaire de l'enregistrement présent dans la table d'origine (=enregistrement présent dans une base distante).
                type : varchar(50)
                obligatoire : oui si le paramètre ``id_synthese`` n'est pas fourni
                valeur par défaut : none
    
    Return : 
        format : JSON
            success : bool - true ou false
            message : string - Information concernant l'erreur rencontrée
            id_synthese : integer - Identifiant de la donnée supprimée dans la table synthese.syntheseff.
            id_source : integer - Identifiant de la source référençant la donnée supprimée dans la table synthese.syntheseff
            id_fiche_source : integer - Clé primaire dans la table d'origine de la donnée supprimée dans la table synthese.syntheseff.
            
    Test :
        avec CURL : 
            curl -i -X DELETE --header 'Accept:application/json' 'http://92.222.107.92/geonature/synthese/observation/68?token=mon;token!hyper#complexe'
            curl -i -X DELETE --header 'Accept:application/json' 'http://92.222.107.92/geonature/synthese/observation?token=mon;token!hyper#complexe' -d 'json={"id_source": 18, "id_fiche_source":"99"}'
