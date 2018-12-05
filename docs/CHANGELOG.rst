=========
CHANGELOG
=========

2.0.0-rc.4 (unreleased)
-----------------------

**Corrections**

* Correction de l'id_digitiser lors de la mise à jour #481
* Corrections multiples de la prise en compte du CRUVED #496
* Deconnexion apres inactivité de l'utilisateur #490
* Suppression des heures au niveau des dates de l'export occtax #485
* Correction du message d'erreur quand on n'a pas de JDD #479
* Correction du champs commentaire dans les exports d'Occtax séparé entre relevé et occurrence #478
* Correction des paramètres de la fonction ``GenericQuery.build_query_filter()`` (merci @patkap)
* Correction de l'administration des métadonnées #466 #420
* Métadonnées (JDD et CA) : ne pas afficher les utilisateurs qui sont des groupes dans les acteurs
* Ajout d'un champs dans la Synthèse permettant de stocker de quel module provient une occurrence et fonctions SQL associées #412
* Amélioration du style des champs obligatoires
* Améliorations mineures de l'ergonomie d'Occtax
* Correction du spinner qui tournait en boucle lors de l'export CSV de la Synthèse #451
* Correction des tests automatisés
* Amélioration des performances des intersections avec les zonages de ``ref_geo.l_areas``
* Diverses autres corrections et améliorations mineures
* Complément de la documentation de développement
* Simplification de la configuration des gn_modules
* Occtax : ordonnancement des observation par date #467
* Suppression des warnings lors du build du frontend
* Correction de l'installation des modules GeoNature
* Ajout d'un message quand on n'a pas accès à une donnée d'un module
* Affichage du nom du module dans le Header (#398)
* Correction des outils cartographiques dans Occtax
* Correction complémentaire des styles des lignes sans remplissage (#458)
* MaplistService : correction du zoom sur les polygones et polylignes

**Note de version**

* MAJ BDD GN (update...)
* MAJ BDD sous-modules
* Evolution pour les sous-modules >> Utiliser instance DB de GN pour lancer scripts (#498) et ne plus avoir d'id_application dans la conf du module + Utilisation du CRUVED

2.0.0-rc.3.1 (2018-10-21)
-------------------------

**Corrections**

* Correction du script ``ìnstall_all.sh`` au niveau de la génération de la configuration Apache de TaxHub et UsersHub (#493)
* Suppression du Servername dans la configuration Apache de TaxHub du script ``install_all.sh``
* Complément de la documentation de mise à jour de GeoNature (https://geonature.readthedocs.io/fr/latest/installation-standalone.html#mise-a-jour-de-l-application)

**Notes de version**

* Si vous migrez depuis une version 2.0.0-rc.2, installez directement cette version corrective plutôt que la 2.0.0-rc.3, mais en suivant les notes de versions de la 2.0.0-rc.3
* Pour mettre en place la redirection de TaxHub sans ``/``, consultez sa documentation https://taxhub.readthedocs.io/fr/latest/installation.html#configuration-apache
* Le script ``install_all.sh`` actuel ne semble pas fonctionner sur Debian 8, problème de version de PostGIS qui ne s'installe pas correctement


2.0.0-rc.3 (2018-10-18)
-----------------------

**Nouveautés**

* Possibilité d'utiliser le MNT en raster ou en vecteur dans la BDD (+ doc MNT) #439 (merci @mathieubossaert)
* INSTALL_ALL - gestion du format date du serveur PostgreSQL (#435)
* INSTALL_ALL - Amélioration de la conf Apache de TaxHub pour gérer son URL sans ``/`` à la fin
* Dessin cartographique d'une autre couleur (rouge) que les observations (bleu)
* Occtax : retour au zoom précédent lors de l'enchainement de relevé (#436)
* Occtax : observateur rempli par défaut avec l'utilisateur connecté (#438)
* Prise en compte des géométries nulles dans la fonction ``serializegeofn``
* Gestion plus complète des données exemple intégrées ou non lors de l'installation (#446)
* Complément des différentes documentations
* Complément FAQ (#441)
* Documentation de la customisation (merci @DonovanMaillard)
* Amélioration de l'architecture du gn_module d'exemple
* Clarification de la configuration des gn_modules
* Lire le fichier ``VERSION`` pour l'afficher dans l'interface (#421)
* Utilisation de la vue ``export_occtax_sinp`` et non plus ``export_occtax_dlb`` par défaut pour les exports Occtax (#462)
* Complément et correction des vues ``export_occtax_sinp`` et ``export_occtax_dlb`` (#462)
* Mise à jour de Marshmallow (2.5.0 => 2.5.1)
* Améliorations des routes de ``gn_monitoring`` et de la configuration des modules de suivi pour pouvoir utiliser le nom d'une application plutôt que son identifiant
* Export Synthèse - Remplacement de la barre de téléchargement par un spinner (#451)

**Corrections**

* Doc Import niveau 2 : Corrections et compléments
* Correction du trigger Occtax > Synthèse qui met à jour le champs ``gn_synthese.observers_txt`` et les commentaires (#448 et #459)
* Correction et amélioration de la fonction ``install_gn_module``
* Correction coquille dans le modèle ``gn_monitoring`` et la fonction ``serializegeofn``
* Installation uniquement sur un environnement 64 bits (documentation + vérification) #442 (merci @jbrieuclp et @sig-pnrnm)
* Correction et découpage des scripts de mise à jour de la BDD depuis la version Beta5
* Correction de l'édition des date_debut et date_fin de Occtax (#457)
* Correction des exports depuis la Synthèse et intégration de la géométrie des observations (#461 et #456)
* Ne pas remplir ``pr_occtax.cor_role_releves_occtax`` si ``observers_txt = true`` (#463)
* Edition d'un relevé Occtax - Ne pas recalculer l'altitude existante (#424)
* Correction de l'activation du formulaire Occtax après localisation du relevé (#469 et #471)
* Carte - Enlever le remplissage des lignes (#458)
* Amélioration du script de mise à jour de GeoNature (``install/migration/migration.sh``) (#465)
* Suppression d'un doublon dans le modèle de ``gn_commons.t_modules`` (merci @lpofredc)

**Autres**

* Mise à jour de TaxHub (Doc utilisateur, configuration Apache, script d'import des médias depuis API INPN Taxref et remise à zéro des séquences)
* Script de migration des données SICEN (ObsOcc) vers GeoNature : https://github.com/PnX-SI/Ressources-techniques/tree/master/GeoNature/migration/sicen
* Script d'import continu depuis une BDD externe vivante (avec exemple SICEN) : https://github.com/PnX-SI/Ressources-techniques/tree/master/GeoNature/migration/generic
* Module Suivi Flore Territoire fonctionnel et installable (https://github.com/PnX-SI/gn_module_suivi_flore_territoire)
* Module Suivi Chiro fonctionnel et installable (https://github.com/PnCevennes/gn_module_suivi_chiro) ainsi que son Frontend générique pour les protocoles de suivi (https://github.com/PnCevennes/projet_suivis_frontend/)
* Ebauche d'un module pour les protocoles CMR (Capture-Marquage-Recapture) : https://github.com/PnX-SI/gn_module_cmr
* MCD du module Suivi Habitat Territoire (https://github.com/PnX-SI/gn_module_suivi_habitat_territoire)
* MCD du module Flore Prioritaire (https://github.com/PnX-SI/gn_module_flore_prioritaire)
* Consolidation du backend et premiers développements du frontend de GeoNature-citizen (https://github.com/PnX-SI/GeoNature-citizen)
* Création d'un script expérimental d'installation de GeoNature-atlas compatible avec GeoNature V2 dt pouvant utiliser son schéma ``ref_geo`` pour les communes, le territoire et les mailles (https://github.com/PnEcrins/GeoNature-atlas/blob/develop/install_db_gn2.sh)

**Notes de version**

* Suivez la procédure standard de mise à jour de GeoNature (https://geonature.readthedocs.io/fr/latest/installation-standalone.html#mise-a-jour-de-l-application)
* Exécutez l'update de la BDD GeoNature (``data/migrations/2.0.0rc2-to-2.0.0rc3.sql``)
* Il est aussi conseillé de mettre à jour TaxHub en 1.5.1 (https://github.com/PnX-SI/TaxHub/releases) ainsi que sa configuration pour qu'il fonctionne sans ``/`` à la fin de son URL
* Attention, si vous installez cette version avec le script global ``install_all.sh``, il créé un problème dans la configuration Apache de UserHub (``/etc/apache2/sites-available/usershub.conf``) et supprime tous les ``/``. Les ajouter sur la page de la documentation de UsersHub (https://github.com/PnEcrins/UsersHub/blob/master/docs/installation.rst#configuration-apache) puis relancer Apache (``https://github.com/PnEcrins/GeoNature-atlas/blob/develop/docs/installation.rst``). Il est conseillé d'installer plutôt la version corrective.


2.0.0-rc.2 (2018-09-24)
-----------------------

**Nouveautés**

* Script ``install_all.sh`` compatible Ubuntu (16 et 18)
* Amélioration du composant Download
* Amélioration du ShapeService
* Compléments de la documentation
* Intégration de la documentation Développement backend dans la documentation
* Nettoyage du code
* Mise à jour de la doc de l'API : https://documenter.getpostman.com/view/2640883/RWaPskTw
* Configuration de la carte (``frontend/src/conf/map.config.ts``) : OSM par défaut car OpenTopoMap ne s'affiche pas à petite échelle

**Corrections**

* Correction du script ``install/migration/migration.sh``
* Ne pas afficher le debug dans le recherche de la synthèse
* Correction du bug de déconnexion entre TaxHub et GeoNature (#423)
* Correction de la fiche info d'Occtax
* Champs Multiselect : Ne pas afficher les valeurs selectionnées dans la liste quand on modifie un objet
* Trigger Occtax vers Synthèse : Correction des problèmes d'heure de relevés mal copiés dans la Synthèse
* Correction des altitudes (non abouti) (#424)
* Données exemple : Suppression de l'``observers_txt`` dans la synthèse
* Suppression d'un ``id_municipality`` en dur dans une route
* Suppression de la librairie Certifi non utilisée

**Notes de version**

* Suivez la procédure standard de mise à jour de GeoNature
* Exécuter l'update de la BDD GeoNature (``data/migrations/2.0.0rc1-to-2.0.0rc2.sql``)


2.0.0-rc.1 (2018-09-21)
-----------------------

La version 2 de GeoNature est une refonte complète de l'application.

* Refonte technologique en migrant de PHP/Symfony/ExtJS/Openlayers à Python3/Flask/Angular4/Leaflet
* Refonte de l'architecture du code pour rendre GeoNature plus générique et modulaire
* Refonte de la base de données pour la rendre plus standarde, plus générique et modulaire
* Refonte ergonomique pour moderniser l'application

Présentation et suivi des développements : https://github.com/PnX-SI/GeoNature/issues/168

**Accueil**

* Message d'introduction customisable
* Carte des 100 dernières observations
* CSS général de l'application surcouchable

**Occtax**

Module permettant de saisir, consulter, rechercher et exporter des données Faune, Flore et Fonge de type Contact selon le standard Occurrences de taxon du SINP (https://inpn.mnhn.fr/telechargement/standard-occurrence-taxon).

* Développement des formulaires de saisie, page de recherche, fiche détail, API, CRUVED et export
* Possibilité de masquer ou afficher les différents champs dans le formulaire Occtax (#344)
* Développement du formulaire de manière générique pour pouvoir réutiliser ses différents éléments dans d'autres modules sous forme de composants Angular
* Configuration possible du module (Niveau de zoom, champs affichées, export...)
* Ajout des nomenclatures dans les filtres d'Occtax à partir du composant ``dynamicForm`` qui permet de créer dynamiquement un formulaire en déclarant ses champs et leur type (#318)
* Amélioration du composant de recherche d'un taxon en ne recherchant que sur les débuts de mot et en affichant en premier les noms de référence (``ordrer_by cd_nom=cd_ref DESC``) #334
* Multilingue fourni avec français et anglais (extensible à d'autres langues)
* Mise en place d'un export CSV, SHP, GeoJSON paramétrable dans Occtax. #363 et #366
* Ajout d'un message d'erreur si l'utilisateur n'a pas de jeu de données ou si il y a eu un problème lors de la récupération des JDD depuis MTD
* Prise en compte du CRUVED au niveau des routes et du front pour adapter les contenus et fonctionnalités aux droits de l'utilisateur
* Mise en place des triggers alimentant la synthèse à partir des données saisies et modifiées dans Occtax

**Synthèse**

Module permettant de rechercher parmi les données des différentes sources présentes ou intégrées dans la base de données de GeoNature

* Mise en place du backend, de l'API et du frontend #345
* Interface de consultation, de recherche et d'export dans la Synthèse
* Synthèse : Calcul automatique (trigger) des zonages de chaque observation (communes, zonages réglementaires et naturels)
* Recherche sur les zonages générique et paramétrable
* Recherche par taxon, liste de taxons, par rang, groupe, liste rouge, milieu, attribut taxonomique, nomenclature, date, période, commune, zonage, cadre d'acquisition, jeu de données, observateur, polygone, rectange ou cercle dessiné
* Retour à la fiche source possible si l'observation a été saisie dans un module de GeoNature
* Affichage de la fiche détail de chaque observation
* Attributs TaxHub dynamiques et paramétrables
* Configuration possible du module (colonnes, limites de recherche et d'export, zoom, export...)
* Export basé sur une vue (observations et statuts)
* Prise en compte du CRUVED pour définir les données à afficher et à exporter #412
* Recherche de taxons : Liste basée sur une table alimentée automatiquement par les taxons présents au moins une fois dans la Synthèse

**Export**

Module permettant de proposer des exports basés sur des vues

* Mise en place temporaire d'un export unique, basé sur une vue s'appuyant sur les données de Occtax, par jeu de données
* A remplacer par le module générique https://github.com/PnX-SI/gn_module_export (en cours de développement) permettant de générer des exports à volonté en créant des vues et en les affectant à des utilisateurs ou des groupes. Chaque export sera accompagné de son API standardisée et documentée

**Admin**

Module d'administration des tables centrales de GeoNature

* Mise en place d'un module (incomplet) permettant de gérer les métadonnées et les nomenclatures

**Gestion des droits**

* Mise en place d'un système baptisé CRUVED permettant de définir globalement ou par module 6 actions sont possibles (Create / Read / Update / Validate / Export / Delete) sur 3 portées possibles (Mes données / Les données de mon organisme / Toutes les données)
* Ces évolutions ont été intégrées au niveau du schéma ``utilisateurs`` de la base de données de UsersHub, de son module (https://github.com/PnX-SI/UsersHub-authentification-module), des routes de l'API GeoNature et des interfaces

**Bases de données**

* Développement d'un module et d'une API générique et autonome pour la gestion des nomenclatures (https://github.com/PnX-SI/Nomenclature-api-module). Il permet d'avoir un mécanisme générique de centralisation des listes de valeurs (nomenclatures) pour ne pas créer des tables pour chaque liste : https://github.com/PnX-SI/Nomenclature-api-module. Les valeurs de chaque nomenclature s'adaptent en fonction des regnes et groupe 2 INPN des taxons.
* Mise en place de tables de stockage verticales (historique, médias et validation) #339
* Mise en place d'un référentiel géographique avec un schéma dédié (``ref_geo``), partageable avec d'autres applications comprenant une table des communes, une table générique des zonages, une table pour le MNT et des fonctions pour intersecter point/ligne/polygones avec les zonages et le MNT (#228)
* Evolution du schéma ``utilisateurs`` de UsersHub pour passer d'une gestion des droits avec 6 niveaux à un mécanisme plus générique, souple et complet. Il permet d'attribuer des actions possibles à un rôle (utilisateur ou groupe), sur une portée; dans une application ou un module. 6 actions sont possibles dans GeoNature : Create / Read / Update / Validate / Export / Delete (aka CRUVED). 3 portées de ces actions sont possibles : Mes données / Les données de mon organisme / Toutes les données.
* Droits CRUVED : La définition du CRUVED d'un rôle (utilisateur ou groupe) sur un module de GeoNature surcouche ses droits GeoNature même si ils sont inférieurs. Si une action du CRUVED n'est pas définie au niveau du module, on prend celle de l'application parente. #292
* Si un rôle a un R du CRUVED à 0 pour un module, alors celui-ci ne lui est pas listé dans le Menu et il ne lui est pas accessible si il en connait l'URL. #360
* Développement des métadonnées dans la BDD (schéma ``gn_meta``) sur la base du standard Métadonnées du SINP (http://standards-sinp.mnhn.fr/category/standards/metadonnees/). Elles permettent de gérer des jeux de données, des cadres d'acquisition, des acteurs (propriétaire, financeur, producteur...) et des protocoles. Chaque relevé est associé à un jeu de données.
* Développement d'un mécanisme de calcul automatique de la sensibilité d'une espèce directement dans la BDD (sur la base des règles nationales et régionales du SINP + locales éventuellement)
* Intégration du calcul automatique de l'identifiant permanent SINP (#209)
* Création du schéma ``gn_monitoring`` pour gérer la partie générique des modules de suivi (sites et visites centralisés) et les routes associées
* Mise en place d'un schéma ``gn_commons`` dans la BDD qui permet de stocker de manière générique des informations qui peuvent être communes aux autres modules : l'historique des actions sur chaque objet de la BDD, la validation d'une donnée et les médias associés à une donnée. Accompagné de fonctions génériques d'historisation et de validation des données mises en place sur le module Occtax. #339
* Ajout d'une vue matérialisée (``gn_synthese.vm_min_max_for_taxons``) et d'une fonction (``gn_synthese.fct_calculate_min_max_for_taxon``) permettant de renvoyer des informations sur les observations existantes d'un taxon (étendue des observations, date min et max, altitude min et max, nombre d'observations) pour orienter la validation et la saisie (https://github.com/PnX-SI/gn_module_validation/issues/5). Désactivée pour le moment.
* Ajout d'un trigger générique pour calculer la géométrie dans la projection locale à partir de la géométrie 4326 (#370)
* Ajout d'un trigger pour calculer automatiquement les zonages des sites de suivi (``gn_monitoring.fct_trg_cor_site_area()``)
* Gestion des conflits de nomenclatures en n'utilisant plus leur ``id_type`` ni leur ``id_nomenclature`` lors de la création de leur contenu (code_nomenclature) (#384)
* Mise en place d'un schéma ``gn_imports`` intégrant des fonctions SQL permettant d'importer un CSV dans la BDD et de mapper des champs de tables importées avec ceux d'une table de GeoNature pour générer le script ``INSERT INTO``
* Début de script de migration GeoNature V1 vers GeoNature V2
* Nombreuses fonctions intégrées dans les schémas de la BDD

**Installation**

* Scripts d'installation autonome ou globale de GeoNature sur Debian (8 et 9) et Ubuntu (16 et 18)
* Scripts de déploiement spécifiques de DEPOBIO (MTES-MNHN)

**Documentation**

* Rédaction d'une documentation concernant l'installation (autonome ou globale), l'utilisation, l'administration et le développement : https://geonature.readthedocs.io

**Développement**

* Découpage de l'application en backend / API / Frontend
* Multilingue au niveau de l'interface et des listes de valeurs avec français et anglais intégrés mais extensible à d'autres langues (#173)
* Développement de composants Angular génériques pour pouvoir les utiliser dans plusieurs modules sans avoir à les redévelopper ni les dupliquer (composant CARTE, composant RECHERCHE TAXON, composant OBSERVATEURS, composant NOMENCLATURES, SelectSearch, Municipalities, Observers, DynamicForm, MapList...)
* Implémentation de la gestion des droits au niveau de l'API (pour limiter les données affichées à un utilisateur en fonction de ses droits) et au niveau du Frontend (pour afficher ou non certains boutons aux utilisateurs en fonction de leurs droits).
* Par défaut, l'authentification et les utilisateurs sont gérés localement dans UsersHub, mais il est aussi possible de connecter GeoNature directement au CAS de l'INPN, sans UsersHub (cas de l'instance nationale INPN de GeoNature).
* Connexion possible au webservice METADONNEES de l'INPN pour y récupérer les jeux de données en fonction de l'utilisateur connecté, avec mise à jour des JDD à chaque appel de la route
* Mise en place d'un mécanisme standardisé de développement de modules dans GeoNature (#306)
* Ajout de tests unitaires au niveau du backend et du frontend
* Ajout d'un mécanisme de log par email (paramètres MAILERROR)
* Début de création du module de gestion des médias (backend uniquement)
* Mise en place d'une configuration globale et d'une configuration par module
* Fonction d'installation d'un module et de génération des fichiers de configuration
* Gestion de l'installation d'un module qui n'a pas de Frontend dans GeoNature
* Mise en place d'une route générique permettant de requêter dans une vue non mappée
* Mise en place d'un script pour la customisation de la plateforme nationale (https://github.com/PnX-SI/GeoNature/blob/develop/install_all/configuration_mtes.sh)

**Autres modules**

* Module Export en cours de développement (https://github.com/PnX-SI/gn_module_export). Chaque export s'appuie sur une vue. Il sera possible aux administrateurs d'une GeoNature d'ajouter autant de vues que nécessaires dans son GeoNature.
* Module de validation des données en cours de développement (https://github.com/PnX-SI/gn_module_validation/issues/4)
* Module Suivi Flore territoire en cours de développement (https://github.com/PnX-SI/gn_module_suivi_flore_territoire)
* Module Suivi Habitat en cours de développement (https://github.com/PnX-SI/gn_module_suivi_habitat_territoire/issues/1)
* gn_module_suivi_chiro refondu pour devenir un module de GeoNature V2 (https://github.com/PnCevennes/gn_module_suivi_chiro)
* Projet suivi utilisé comme Frontend générique et autonome pour le Suivi chiro (https://github.com/PnCevennes/projet_suivis_frontend)
* GeoNature-citizen en cours de développement (https://github.com/PnX-SI/GeoNature-citizen/issues/2)
* GeoNature-mobile en cours de refonte pour compatibilité avec GeoNature V2 (https://github.com/PnEcrins/GeoNature-mobile/issues/19)
* GeoNature-atlas en cours d'ajustements pour compatibilité avec GeoNature V2 (https://github.com/PnEcrins/GeoNature-atlas/issues/162)

**Notes de version**

**1.** Pour les utilisateurs utilisant la version 1 de GeoNature : 

Il ne s'agit pas de mettre à jour GeoNature mais d'en installer une nouvelle version. En effet, il s'agit d'une refonte complète. 

* Passer à la dernière version 1 de GeoNature (1.9.1)
* Idem pour UsersHub et TaxHub
* Installer GeoNature standalone ou refaire une installation complète
* Adaptez les scripts présents dans ``/data/migrations/v1tov2`` et éxécutez-les

*TODO : MAJ depuis V1 à  tester et compléter*

**2.** Pour les utilisateurs utilisant la version 2.0.0.beta5 : 

* Supprimer le schéma ``gn_synthese`` puis le recréer dans sa version RC1 (#430)
* Exécuter l'update de la BDD GeoNature (``data/migrations/2.0.0beta5-to-2.0.0rc1.sql``) ainsi que celui du sous-module Nomenclature (https://github.com/PnX-SI/Nomenclature-api-module/blob/1.2.1/data/update1.1.0to1.2.1.sql)
* Suivre la procédure habituelle de mise à jour
* Exécuter les commandes suivantes :

  ::

    cd geonature/backend
    source venv/bin/activate
    geonature generate_frontend_modules_route
    geonature frontend_build


2.0.0.beta5 (2018-07-16)
------------------------

**Nouveautés**

* Ajout d'un message d'erreur si l'utilisateur n'a pas de JDD ou si il y a eu un problème lors de la récupération des JDD de MTD
* Ajout d'une vue matérialisée (``gn_synthese.vm_min_max_for_taxons``) et d'une fonction (``gn_synthese.fct_calculate_min_max_for_taxon``) permettant de renvoyer des informations sur les observations existantes d'un taxon (étendue des observations, date min et max, altitude min et max, nombre d'observations) pour orienter la validation et la saisie (https://github.com/PnX-SI/gn_module_validation/issues/5)
* L'export OccTax est désormais basé sur une vue qu'il est possible d'adapter
* Ajouts de nouveaux tests automatisés du code et mise en place de Travis pour les lancer automatiquement à chaque commit (https://travis-ci.org/PnX-SI/GeoNature)
* Ajout de données test
* Mise à jour des scripts de déploiement spécifiques de DEPOBIO (MTES)
* Déplacement de la table centrale de gestion des paramètres ``t_parameters`` dans le schéma ``gn_commons`` (#376)
* Ajout d'un trigger générique pour calculer la géométrie dans la projection locale à partir de la géométrie 4326 (#370)
* Regroupement des fichiers liés à l'installation et la mise à jour dans un répertoire dédié (``install``) (#383)
* Mise en place de scripts de migration global de la BDD (``data/migrations/2.0.0beta4to2.00beta5.sql``) et du schéma ``pr_occtax`` (``contrib/occtax/data/migration_2.0.0.beta4to2.0.0.beta5.sql``), d'un script générique de migration de l'application (``install/migration/migration.sh``) et d'une doc de mise à jour (https://github.com/PnX-SI/GeoNature/blob/develop/docs/installation-standalone.rst#mise-%C3%A0-jour-de-lapplication)
* Réintégration des fichiers de configuration, de logs et des modules externes dans les répertoires de l'application (#375)
* Ajout de routes à ``gn_monitoring``
* Ajout d'un trigger pour calculer automatiquement les zonages des sites de suivi (``gn_monitoring.fct_trg_cor_site_area()``)
* Améliorations et documentation des commandes d'installation d'un module
* Ajout des unités géographiques dans le schéma ``ref_geo``
* Ajout d'un bouton ``Annuler`` dans le formulaire Occtax
* Gestion des conflits de nomenclatures en n'utilisant plus leur ``id_type`` ni leur ``id_nomenclature`` (#384)
* Migration du SQL de ``ref_nomenclautres`` dans le dépôt du sous-module (https://github.com/PnX-SI/Nomenclature-api-module)
* Début de mise en place d'un backoffice (métadonnées et nomenclatures)

**Corrections**

* OccTax : Correction du double post
* OccTax : Correction des droits dans les JDD
* OccTax : Correction de l'affichage des observers_txt dans la fiche d'un relevé
* Correction de la gestion générique des médias
* Suppression du lien entre ``ref_geo`` et ``ref_nomenclatures`` (#374)
* Compléments et relecture de la documentation
* Correction 

**Notes de version**

Si vous mettez à jour votre GeoNature depuis une Beta4 : 

* Téléchargez la beta5 et renommer les répertoires :
::

    cd /home/myuser
    wget https://github.com/PnX-SI/GeoNature/archive/geonature2beta.zip
    unzip geonature2beta.zip
    mv /home/<mon_user>/geonature/ /home/<mon_user>/geonature_old/
    mv GeoNature-geonature2beta /home/<mon_user>/geonature/
* Exécutez le script de migration ``install/migration/beta4tobeta5.sh`` depuis la racine de votre GeoNature :
::

    cd geonature
   ./install/migration/beta4tobeta5.sh

Celui-ci va récupérer vos fichiers de configuration, déplacer les modules et appliquer les changements de la BDD.

* Si vous avez développé des modules externes, voir https://github.com/PnX-SI/GeoNature/issues/375, en ajoutant un lien symbolique depuis le répertoire ``external_modules`` et en réintégrant la configuration du module dans son répertoire ``config``

2.0.0.beta4 (2018-05-25)
------------------------

**Nouveautés**

* Synthèse : début de mise en place du backend, de l'API et du frontend #345
* Complément de la nomenclature des Méthodes de détermination et suppression du champs Complement_Determination. Merci @DonovanMaillard. #341
* Nouveaux composants Angular (SelectSearch, Municipalities, Observers)
* Amélioration de composants Angular (Date du jour par défaut, Option de tri des nomenclatures, DynamicForm
* Connexion à MTD INPN : Mise à jour des JDD à chaque appel de la route
* Finalisation du renommage de Contact en OccTax (BDD, API, backend)
* Droits CRUVED : La définition du CRUVED d'un rôle (utilisateur ou groupe) sur un module de GeoNature surcouche ses droits GeoNature même si ils sont inférieurs. Si une action du CRUVED n'est pas définie au niveau du module, on prend celle de l'application parente. #292
* Si un rôle a un R du CRUVED à 0 pour un module, alors celui-ci ne lui est pas listé dans le Menu et il ne lui ai pas accessible si il en connait l'URL. #360
* Mise en place d'un schéma ``gn_commons`` dans la BDD qui permet de stocker de manière générique des informations qui peuvent être communes aux autres modules : l'historique des actions sur chaque objet de la BDD, la validation d'une donnée et les médias associés à une donnée. Accompagné de fonctions génériques d'historisation et de validation des données mises en place sur le module Occtax. #339
* Amélioration de l'ergonomie du MapList de OccTax. #361
* Mise en place d'un export CSV, SHP, GeoJSON paramétrable dans OccTax. #363 et #366
* Amélioration du module générique ``gn_monitoring`` et de ses sous-modules https://github.com/PnCevennes/gn_module_suivi_chiro et https://github.com/PnCevennes/projet_suivis_frontend
* Amélioration et compléments des scripts d'installation
* Mise en place d'un script pour la customisation de la plateforme nationale (https://github.com/PnX-SI/GeoNature/blob/develop/install_all/configuration_mtes.sh)

**Documentation**

* Complément des différentes documentations
* Ajout d'une documentation d'administration d'OccTax (https://github.com/PnX-SI/GeoNature/blob/develop/docs/admin-manual.rst#module-occtax)

2.0.0.beta3 (2018-03-28)
------------------------

**Nouveautés**

* Travail sur le module générique de Suivi intégré à GeoNature (``gn_monitoring``). Gestion des fichiers de configuration
* Gestion de l'installation d'un module qui n'a pas de Frontend dans GeoNature
* Mise en place de tests automatiques au niveau du Frontend
* Ménage et réorganisation du code du Frontend
* Factorisation et harmonisation des composants génériques Angular
* Suppression des blocs non fonctionnels sur la Home
* Mise à jour de la doc et du MCD
* Possibilité de masquer ou afficher les différents champs dans le formulaire Occtax (#344)
* Ajout des nomenclatures dans les filtres d'OccTax à partir du nouveau composant ``dynamicForm`` qui permet de créer dynamiquement un formulaire en déclarant les champs (#318)
* Amélioration du composant de recherche d'un taxon en ne recherchant que sur les débuts de mot et en affichant en premier les noms de référence (ordrer_by cd_nom=cd_ref DESC) - #334
* Mise en place d'une route générique permettant de requêter dans une vue non mappée
* Suppression des options vides dans les listes déroulantes des nomenclatures
* Ajout de quelques paramètres (niveau de zoom mini dans chaque module, ID de la liste des taxons saisissables dans Occtax...)

**Corrections**

* Correction de la pagination du composant MapList
* Correction des droits attribués automatiquement quand on se connecte avec le CAS
* Correction de l'installation optionnelle de UsersHub dans le script ``install_all.sh``

**Modules annexes**

* Début de refonte du module Suivi chiro (https://github.com/PnCevennes/gn_module_suivi_chiro) connecté au module générique de suivi de GeoNature, dont le front sera externe à GeoNature (https://github.com/PnCevennes/projet_suivi)
* Maquettage et avancée sur le module Validation (https://github.com/PnX-SI/gn_module_validation)
* Définition du module Suivi Habitat Territoire (https://github.com/PnX-SI/gn_module_suivi_habitat_territoire)
* Piste de définition du module Interopérabilité (https://github.com/PnX-SI/gn_module_interoperabilite)

2.0.0.beta2 (2018-03-16)
------------------------

**Nouveautés**

* Compléments de la documentation (schéma architecture, administration, installation, développement, FAQ...)
* Amélioration de l'ergonomie du module OccTax (composant MapList, filtres, colonnes et formulaires) et du module Exports
* Amélioration du composant de recherche d'un taxon (#324)
* Amélioration et optimisation de la sérialisation des données
* Ajout de tests unitaires au niveau du backend
* Ajout d'un mécanisme de log par email (paramètres MAILERROR)
* Migration du module occtax dans le répertoire ``/contrib`` pour homogénéiser les modules
* Création du schéma ``gn_monitoring`` pour gérer la partie générique des modules de suivi (sites et visites centralisés)
* Début de création du module générique des protocoles de suivi
* Début de création du module de gestion des médias

**Corrections**

* Corrections de l'installation globale et autonome
* Renommage Contact en OccTax (en cours)
* Nettoyage du schéma des métadonnées (``gn_meta``)

2.0.0.beta1 (2018-02-16)
------------------------

La version 2 de GeoNature est une refonte complète de l'application.

* Refonte technologique en migrant de PHP/Symfony/ExtJS/Openlayers à Python3/Flask/Angular4/Leaflet
* Refonte de l'architecture du code pour rendre GeoNature plus générique et modulaire
* Refonte de la base de données pour la rendre plus standarde, plus générique et modulaire
* Refonte ergonomique pour moderniser l'application

Présentation et suivi du projet : https://github.com/PnX-SI/GeoNature/issues/168

**Nouveautés**

* Refonte de la base de données du module Contact, renommé en OccTax, s'appuyant sur le standard Occurrence de taxons du SINP (#183)
* Développement du module OccTax regroupant les contacts Faune, Flore, Fonge et Mortalité (avec formulaire de consultation et de saisie des données)
* Développement d'un module et d'une API générique et autonome pour la gestion des nomenclatures (https://github.com/PnX-SI/Nomenclature-api-module). Il permet d'avoir un mécanisme générique de centralisation des listes de valeurs (nomenclatures) pour ne pas créer des tables pour chaque liste : https://github.com/PnX-SI/Nomenclature-api-module. Les valeurs de chaque nomenclature s'adaptent en fonction des regnes et groupe 2 INPN des taxons.
* Découpage de l'application en backend / API / Frontend
* Multilingue au niveau de l'interface et des listes de valeurs avec français et anglais intégrés mais extensible à d'autres langues (#173)
* Développement de composants génériques pour pouvoir les utiliser dans plusieurs modules sans avoir à les redévelopper ni les dupliquer (composant CARTE, composant RECHERCHE TAXON, composant OBSERVATEURS, composant NOMENCLATURES...)
* Mise en place d'un référentiel géographique avec un schéma dédié (``ref_geo``), partageable avec d'autres applications comprenant une table des communes, une table générique des zonages, une table pour le MNT et des fonctions pour intersecter point/ligne/polygones avec les zonages et le MNT (#228)
* Evolution du schéma ``utilisateurs`` de UsersHub pour passer d'une gestion des droits avec 6 niveaux à un mécanisme plus générique, souple et complet. Il permet d'attribuer des actions possibles à un rôle (utilisateur ou groupe), sur une portée; dans une application ou un module. 6 actions sont possibles dans GeoNature : Create / Read / Update / Validate / Export / Delete (aka CRUVED). 3 portées de ces actions sont possibles : Mes données / Les données de mon organisme / Toutes les données.
* Implémentation de la gestion des droits au niveau de l'API (pour limiter les données affichées à un utilisateur en fonction de ses droits) et au niveau du Frontend (pour afficher ou non certains boutons aux utilisateurs en fonction de leurs droits).
* Par défaut, l'authentification et les utilisateurs sont gérés localement dans UsersHub, mais il est aussi possible de connecter GeoNature au CAS de l'INPN, sans utiliser GeoNature (utilisé pour l'instance nationale INPN de GeoNature). GeoNature peut aussi se connecter au webservice METADONNEES de l'INPN pour y récupérer les jeux de données en fonction de l'utilisateur connecté.
* Mise en place d'un module d'export. Chaque export s'appuie sur une vue. Il sera possible à chaque administrateur d'ajouter autant de vues que nécessaires dans son GeoNature. Pour le moment, un export au format SINP Occurrence de taxons a été intégré par défaut.
* Développement des métadonnées dans la BDD (schema ``gn_meta``) sur la base du standard Métadonnées du SINP (http://standards-sinp.mnhn.fr/category/standards/metadonnees/). Elles permettent de gérer des jeux de données, des cadres d'acquisition, des acteurs (propriétaire, financeur, producteur...) et des protocoles. Chaque relevé est associé à un jeu de données.
* Développement d'un mécanisme de calcul automatique de la sensibilité d'une espèce directement dans la BDD (sur la base des règles nationales et régionales du SINP + locales éventuellement)
* Intégration du calcul automatique de l'identifiant permanent SINP (#209)
* Mise en place d'un mécanisme standardisé de développement de modules dans GeoNature (#306)
* Scripts d'installation autonome ou globale de GeoNature sur Debian 8 et 9

**Documentation**

* Installation globale de GeoNature (avec TaxHub et UsersHub) / https://github.com/PnX-SI/GeoNature/blob/develop/docs/installation-all.rst
* Installation autonome de GeoNature / https://github.com/PnX-SI/GeoNature/blob/develop/docs/installation-standalone.rst
* Manuel utilisateur / https://github.com/PnX-SI/GeoNature/blob/develop/docs/user-manual.rst
* Manuel administrateur / https://github.com/PnX-SI/GeoNature/blob/develop/docs/admin-manual.rst
* Développement (API, modules et composants) / https://github.com/PnX-SI/GeoNature/blob/develop/docs/development.rst

Documentation complète disponible sur http://geonature.fr/docs/2-0-0-beta1

**A venir**

* Finalisation MCD du module Synthèse
* Triggers d'alimentation automatique de la Synthèse depuis le module OccTax
* Développement de l'interface du module Synthèse
* Amélioration et généricité du module OccTax (médias, import GPX, champs masquables et pseudo-champs)
* Généricité du module d'export
* Développement du module de validation (#181)
* Développement d'un module de suivi des habitats avec une gestion générique des sites et visites de suivi
* Développement d'un module de collecte citoyenne (#242)


1.9.1 (2018-05-17)
------------------

**Corrections**

* Installation - Suppression des couches SIG (communes, znieff...) pour les télécharger sur http://geonature.fr/data/inpn/layers/ et ainsi alléger le dépôt de 158 Mo.
* Compléments mineurs de la documentation
* Migration du script ``install_all`` en Debian 9. La doc et le script Debian 8 restent disponibles dans le répertoire ``docs/install_all``
* Corrections mineures de triggers
* Compatibilité avec TaxHub 1.3.2, UsersHub 1.3.1, GeoNature-atlas 1.3.2

**Notes de version**

* Vous pouvez passer directement d'une 1.7.X à la 1.9.1, en prenant en compte les notes des différentes versions intermédiaires, notamment les scripts de mise à jour de la BDD ainsi que les éventuels nouveaux paramètres à ajouter. 
* Exécuter le script de mise à jour de la BDD ``data/update_1.9.0to1.9.1.sql``


1.9.0 (2017-07-06)
------------------

**ATTENTION : Les évolutions de cette version concernent aussi la webapi. Si vous utilisez les applications GeoNature-mobile, vous devez attendre la sortie d'une version de GeoNature-mobile-webapi (https://github.com/PnEcrins/GeoNature-mobile-webapi) compatible avec cette version 1.9.0 de GeoNature.** Coming soon !

A noter aussi que cette version de GeoNature est compatible avec GeoNature-atlas 1.2.4 et +.

**Nouveautés**

* Ajout de la création des index spatiaux à la création initiale de la base.
* Création ou mise à jour des géométries compatible PostGIS 2.
* Ajout du champ diffusable (oui/non) dans le formulaire web de saisie, uniquement pour ContactFaune et Mortalité (TODO : faire la même chose pour les autres protocoles).
* Multi-projection : Les versions antérieures de GeoNature n'étaient compatibles qu'avec la projection Lambert 93 (srid: 2154). Cette version permet de choisir sa projection locale. Elle ajoute un paramètre ``srid_local`` dans le ``config/settings.ini`` et renomme tous les champs ``the_geom_2154`` en ``the_geom_local`` des tables "métier".
Ce paramètre est notamment utilisé lors de la création de la base pour affecter le srid de la projection locale à tous les champs ``the_geom_local`` présents dans les tables de la base. Ce paramètre est également utilisé pour mettre en cohérence le système de projection local utilisé dans toutes les couches SIG présentes dans la base et les géométries stockées dans les champs ``the_geom_local`` des tables "métier". Le paramétrage du service WMS dans ``wms/wms.map`` est également pris en charge par le script d'installation de l'application.
* Correction de l'installation de npm
* Script ``install_all.sh`` mis à jour avec les nouvelles versions de GeoNature-atlas, de TaxHub et de UsersHub.

IMPORTANT : toutes les couches SIG insérées dans le schéma ``layers`` doivent être dans la projection fournie pour le paramètre ``srid_local``. L'application est livrée avec un ensemble de couches en Lambert 93 concernant la métropole. Une installation avec une autre projection, hors métropole, doit donc se faire sans l'insertion des couches SIG. Vous devrez manuellement fournir le contenu des tables du schéma ``layers`` dans la projection choisie.

**Notes de versions**

* Vous pouvez ajouter les paramètres ``srid_local``, ``install_sig_layers`` et ``add_sample_data`` au fichier ``config/settings.ini`` en vous inspirant du fichier ``config/settings.ini.sample``. Toutefois ces paramètres ne sont utilisés que pour une nouvelle installation et notamment pour l'installation de la base.

* Vous pouvez passer directement d'une 1.7.X à la 1.9.0, en prenant en compte les notes des différentes versions intermédiaires, notamment les scripts de mise à jour de la BDD ainsi que les éventuels nouveaux paramètres à ajouter. 

* Si vous migrez depuis la version 1.8.3, exécutez le fichier SQL ``data/update_1.8.3to1.9.0.sql``. Comme GeoNature ne fonctionne jusque là que pour des structures de métropole, il est basé sur le fait que le champ ``the_geom_local`` reste en Lambert 93 (2154). Assurez-vous que le paramètre ``$srid_local`` dans ``lib/sfGeonatureConfig.php`` est égal à ``2154``.
ATTENTION : ce script SQL renomme tous les champs ``the_geom_2154`` en ``the_geom_local`` de la BDD de GeoNature. Ceci affecte de nombreuses tables, de nombreux triggers et de nombreuses vues de la base. Le script n'intègre que les vues fournies par défaut. Si vous avez créé des vues spécifiques, notamment pour le module d'export, ou si vous avez modifié des vues fournies, vous devez adapter/compléter le script. Vous pouvez vous inspirer de son contenu.

* RAPPEL : Ceci affecte également la webapi des applications mobiles. Vous devez donc mettre à jour votre webapi si vous utilisez la saisie sur les applications mobiles. Une release de la webapi devrait sortir bientôt.


1.8.4 (2017-04-10)
------------------

**Corrections**

* Correction du script d'installation globale (``install_all``) si l'utilisateur de BDD par défaut a été renommé (``data/grant.sql``)
* Correction de la création des vues qui remontent la liste des taxons dans les 3 contacts


1.8.3 (2017-02-23)
------------------

**Nouveautés**

* Multi-organisme : l'organisme associé à la donnée est désormais celui de l'utilisateur connecté dans l'application (lors de la création d'une observation uniquement).
* Taxonomie : création d'une liste ``Saisie possible``, remplaçant l'attribut ``Saisie``. Cela permet de choisir les synonymes que l'on peut saisir ou non dans GeoNature en se basant sur les ``cd_nom`` (``bib_listes`` et ``cor_nom_liste``) et non plus sur les ``cd_ref`` (``bib_attributs`` et ``cor_taxon_attribut``). Voir le script de migration SQL ``data/update_1.8.2to1.8.3.sql`` pour bien basculer les informations de l'attribut dans la nouvelle liste. 
* Correction de la vue ``synthese.v_tree_taxons_synthese`` potentiellement bloquante à l'ouverture de la synthèse.
* Suppression de la table ``utilisateurs.bib_observateurs`` inutile.
* Création des index spatiaux manquants (performances)
* Clarification et corrections mineures du script ``install_all``
* Ajout du MCD de la 1.8 (par @xavier-pnm)
* Améliorations du nom des fichiers exportés depuis la Synthèse (par @sylvain-m)

**Notes de versions**

Vous pouvez supprimer les lignes concernant le paramètre ``public static $id_organisme = ...`` dans ``lib/sfGeonatureConfig.php``, l'organisme n'étant plus un paramètre fixe mais désormais celui de l'utilisateur connecté.

Vous pouvez passer directement d'une 1.7.X à la 1.8.3, en prenant en compte les notes des différentes versions intermédiaires. 

Si vous migrez depuis la version 1.8.2, éxécutez le fichier SQL ``data/update_1.8.2to1.8.3.sql``.


1.8.2 (2017-01-11)
------------------

**Nouveautés**

* Modularité des scripts SQL de création de la base en les dissociant par protocole et en regroupant les triggers dans les schémas de chaque protocole (préparation GeoNature V2)
* Correction d'une requête dans flore station (indépendance vis à vis de flore patrimoniale)
* Correction du trigger ``synthese_update_fiche_cflore`` (@ClaireLagaye)

**Notes de versions**

Vous pouvez passer directement d'une 1.7.X à la 1.8.2, en prenant en compte les notes des différentes versions intermédiaires. 

Si vous migrez depuis la version 1.8.1, éxécutez le fichier ``data/update_1.8.1to1.8.2.sql``. Consultez les dernières lignes de ce fichier : vous devez évaluer si la requête d'insertion dans la table ``taxonomie.cor_taxon_attribut`` doit être faite ou non (vous pourriez avoir déjà constaté et corrigé cette erreur lors d'une précédente migration). Cela corrige l'absence de taxons protégés dans votre synthese en récupérant les informations de protection présentes dans le champ ``filtre3`` de la table ``save.bib_taxons``


1.8.1 (2017-01-05)
------------------

**Nouveautés**

* Ajout des sauvegardes et de l'installation globale avec un exemple détaillé dans la documentation : http://geonature.readthedocs.io
* Optimisation et correction de la vue qui retourne l'arbre des rangs taxonomiques (synthese.v_tree_taxons_synthese)
* Mise en cohérence des données exemple de GeoNature-atlas avec les critères des vues matérialisées de GeoNature-atlas
* Mise à jour de 2 triggers du Contact Flore (@ClaireLagaye)

**Notes de versions**

Vous pouvez passer directement d'une 1.7.X à la 1.8.1, en prenant en compte les notes des différentes versions intermédiaires. 

Si vous migrez depuis la version 1.8.0, éxécutez le fichier ``data/update_1.8to1.8.1.sql``


1.8.0 (2016-12-14)
------------------

**Nouveautés**

* Passage à TAXREF version 9
* Accès à la synthèse en consultation uniquement pour des utilisateurs enregistrés avec des droits 1
* Ajout d'un champ ``diffusion`` (oui/non) dans la table ``synthese.syntheseff``, utilisable dans GeoNature-atlas. Pas d'interface de gestion de ce champ pour le moment. CF #132
* Création d'un script d'installation simplifié pour un pack UsersHub, TaxHub, GeoNature et GeoNature-atlas : https://github.com/PnEcrins/GeoNature/tree/master/docs/install_all
* Factorisation des SQL de création des schémas ``taxonomie`` et ``utilisateurs`` en les récupérant dans les dépots TaxHub et UsersHub
* Compatibilité avec l'application `TaxHub <https://github.com/PnX-SI/TaxHub>`_ qui permet de gérer la taxonomie à partir de TAXREF. Cela induit d'importants changements dans le schéma ``taxonomie``, notamment le renommage de ``taxonomie.bib_taxons`` en ``taxonomie.bib_noms``, la suppression de ``taxonomie.bib_filtres`` et l'utilisation de ``taxonomie.bib_attributs`` (voir https://github.com/PnX-SI/TaxHub/issues/71 pour plus d'informations). Voir aussi le fichier de migration ``data/update_1.7to1.8.sql`` qui permet d'automatiser ces évolutions de la BDD
* Compatibilité avec l'application `GeoNature-atlas <https://github.com/PnEcrins/GeoNature-atlas>`_ qui permet de diffuser les données de la synthèse faune et flore dans un atlas en ligne (exemple : http://biodiversite.ecrins-parcnational.fr)
* Création d'un site internet de présentation de GeoNature : http://geonature.fr

**Corrections**

* Amélioration des triggers concernant la suppression de fiches orphelines
* Affichage par défaut du nom latin dans Contact flore et Contact invertébrés
* Correction des exports lors de la présence de points-virgules dans les commentaires. Fix #143
* Suppression du besoin d'un super utilisateur lors de l'installation de la BDD. Fix #141
* Correction de l'ID des protocoles mortalité et invertebres dans la configuration par défaut
* Suppression d'un doublon dans le fichier de configuration symfony de l'application
* Correction des coordonnées lors de l'export de données Flore Station
* Autres corrections mineures

**Note de version**

* Exécuter le script SQL de migration réalisant les modifications de la BDD de la version 1.7.X à 1.8.0 ``data/update_1.7to1.8.sql``
* Mettre à jour taxref en V9 en vous inspirant du script ``data/taxonomie/inpn/update_taxref_v8tov9``

**TaxHub**

L'application TaxHub (https://github.com/PnX-SI/TaxHub) est désormais fonctionnelle, documenté et installable.

Elle vous aidera à gérer vos taxons et l'ensemble du schéma ``taxonomie``, présent dans la BDD de GeoNature. 

TaxHub évoluera pour intégrer progressivement de nouvelles fonctionnalités.

Il est conseillé de ne pas installer la base de données de TaxHub indépendamment et de connecter l'application directement sur le la base de données de GeoNature.

**GeoNature-atlas**

GeoNature-atlas est également basé sur le schéma ``taxonomie`` de TaxHub. Ainsi TaxHub permet la saisie des informations relatives aux taxons (descriptions, milieux, photos, liens, PDF...). GeoNature-atlas dispose de sa propre base de données mais pour fonctionner en connexion avec le contenu de la base GeoNature il faut à minima disposer d'une version 1.8 de GeoNature.
  
:notes:

    Une régression dans le contenu de Taxref V9 conduit à la suppression de l'information concernant le niveau de protection des espèces (régional, national, international,...). 
    Cette information était utilisée par GeoNature, notamment pour définir les textes à retenir pour la colonne ``concerne_mon_territoire`` de la table ``taxonomie.taxref_protection_articles``.
    Vous devez désormais remplir cette colonne manuellement.


1.7.4 (2016-07-06)
------------------

**Corrections de bugs**

* Correction du script d'installation des tables liées au Contact flore (5a1fb07)
* Mise en cohérence avec GeoNature-mobile utilisant les classes 'gasteropodes' et 'bivalves' et non la classe générique 'mollusques'.

**Nouveautés**

* Corrections de mise en forme de la documentation
* Ajout de la liste rouge France de TaxRef lors d'une nouvelle installation (f4be2b6). A ne pas prendre en compte dans le cas d'une mise à jour.
* Ajout du MCD de la BDD - https://github.com/PnEcrins/GeoNature/blob/master/docs/2016-04-29-mcd_geonaturedb.png

**Note de version**

* Vous pouvez passer directement de la version 1.6.0 à la 1.7.4 mais en vous référant aux notes de version de la 1.7.0.
* Remplacer ``id_classe_mollusques`` par ``id_classe_gasteropodes`` dans ``web/js/config.js`` et renseigner la valeur en cohérence avec l'``id_liste`` retenu dans la table ``taxonomie.bib_listes`` pour les gastéropodes. Attention, vous devez avoir établi une correspondance entre les taxons gastéropodes et bivalves et leur liste dans la table ``taxonomie.cor_taxon_liste``.


1.7.3 (2016-05-19)
------------------

**Corrections de bugs**

* Correction de coordonnées vides dans l'export de Flore station. cf https://github.com/PnEcrins/GeoNature/commit/0793a3d3d2b3719ed515058d1a0ba9baf7cb2096
* Correction des triggers en base concernant un bug de saisie pour les taxons dont le taxon de référence n'est pas présent dans ``taxonomie.bib_taxons``.

**Note de version**

Rappel : commencez par suivre la procédure classique de mise à jour. http://geonature.readthedocs.org/fr/latest/update.html

* Vous pouvez passer directement de la version 1.6.0 à la 1.7.3 mais en vous référant aux notes de version de la 1.7.0.

* Pour passer de la 1.7.2 à la 1.7.3 vous devez exécuter le script ``https://github.com/PnEcrins/GeoNature/blob/master/data/update_1.7.2to1.7.3.sql``.


1.7.2 (2016-04-27)
----------------------

**Corrections de bug**

* Correction d'un bug dans l'export XLS depuis Flore Station.

**Note de version**

* Vous pouvez passer directement de la version 1.6.0 à la 1.7.2 mais en vous référant aux notes de version de la 1.7.0.


1.7.1 (2016-04-27)
----------------------

**Corrections de bug**

* Ajout des listes flore manquantes dans le script de mise à jour ``data/update_1.6to1.7.sql``.


1.7.0 (2016-04-24)
----------------------

**Nouveautés**

* Ajout du contact flore
* Correction et compléments dans les statistiques et mise en paramètre de leur affichage ou non, ainsi que de la date de début à prendre en compte pour leur affichage.
* Ajout d'un module d'export des données permettant d'offrir, en interne ou à des partenaires, un lien de téléchargement des données basé sur une ou des vues de la base de données (un fichier par vue). Voir http://geonature.readthedocs.org/fr/latest/export.html
* Modification des identifiants des listes pour compatibilité avec les applications GeoNature-Mobile.
* Complément dans la base de données pour compatibilité avec les applications GeoNature-Mobile.
* Correction d'une erreur sur l'importation de shape pour la recherche géographique
* WMS : correction de la liste des sites N2000, correction de l'affichage de l'aire optimale d'adhésion des parcs nationaux et retrait des sites inscrits et classés
* Correction d'un bug permettant la saisie d'une date d'observation postérieure à aujourd'hui dans Flore station
* Mention de la version de taxref sur la page d'accueil

**Note de version**

Rappel : commencez par suivre la procédure classique de mise à jour. http://geonature.readthedocs.org/fr/latest/update.html

**1.** Modification des identifiants des listes de taxons pour compatibilité avec les applications GeoNature-Mobile.
   
Dans GeoNature-Mobile, les taxons sont filtrables par classe sur la base d'un ``id_classe``. Ces id sont inscrits en dur dans le code des applications mobiles. 

Dans la base GeoNature les classes taxonomiques sont configurables grace au vues ``v_nomade_classes`` qui utilisent les listes (``taxonomie.bib_listes``).

Les ``id_liste`` ont donc été mis à jour pour être compatibles avec les ``id_classe`` des applications mobiles.

Voir le script SQL d'update ``data/update_1.6to1.7.sql`` et LIRE ATTENTIVEMENT LES COMMENTAIRES.

* En lien avec les modifications ci-dessus, mettre à jour les variables des classes taxonomiques correspondant aux modification des ``id_liste`` dans ``web/js/config.js``

* Ajouter dans le fichier ``lib/sfGeonatureConfig.php`` les variables ``$struc_abregee``, ``$struc_long``, ``$taxref_version``, ``$show_statistiques`` et ``$init_date_statistiques`` (voir le fichier ``lib/sfGeonatureConfig.php.sample``)

**2.** Pour ajouter le Contact flore

* Exécuter le script sql ``data/2154/contactflore.sql``
* Ajouter les variables ``$id_lot_cflore  = 7``, ``$id_protocole_cflore  = 7``, ``$id_source_cflore = 7`` et ``$appname_cflore = 'Contact flore - GeoNature';`` dans ``lib/sfGeonatureConfig.php`` (voir le fichier d'exemple ``lib/sfGeonatureConfig.php.sample``)
* Ajouter les variables  ``id_lot_contact_flore = 7``, ``id_protocole_contact_flore = 7``, ``id_source_contactflore = 7`` dans ``web/js/config.js`` (voir le fichier d'exemple ``web/js/config.js.sample``)
* l'enregistrement correspondant au contact flore dans la table ``synthese.bib_sources`` doit être actif (dernière colonne) pour que le contact flore soit accessible depuis la page d'accueil.
            
**3.** Afin de mettre à jour la configuration WMS, vous devez exécuter le fichier ``wms/update1.6to1.7.sh``. 

Au préalable, assurez vous que les informations renseignées dans le fichier ``config/settings.ini`` sont à jour. L'ancien fichier sera sauvegardé sous ``wms/wms_1.6.map``. Vous pourrez faire le choix de conserver ou de supprimer ce fichier de sauvegarde qui ne sera pas utilisé par l'application.

   :: 

      ./wms/update1.6to1.7.sh
        
**4.** Mise en place du module d'export 

* Créer les vues retournant les données attendues.
* Configurer le module dans le fichier ``lib/sfGeonatureConfig.php`` à partir de l'exemple du fichier ``lib/sfGeonatureConfig.php.sample``); section ``configuration du module d'export``
   
   * Vous pouvez paramétrer plusieurs modules avec un nom pour chacun grace au paramètre ``exportname``
   * Pour chacun des modules seuls les utilisateurs de geonature dont le ``id_role`` figure dans le tableau ``authorized_roles_ids`` peuvent exporter les données mises à disposition par le module d'export.
   * Chaque module peut comporter autant que vues que nécessaire (un bouton par vue générera un fichier zip par vue). Renseigner le tableau ``views`` pour chacun des modules.
   * Voir la documentation ici : http://geonature.readthedocs.org/fr/latest/export.html

* Attribution des droits nécessaires pour le répertoire permettant l'enregistrement temporaire des fichiers générés par le module d'export.

   :: 

      chmod -R 775 web/uploads/exports
        
* Rétablir les droits d'écriture et vider le cache 

   ::

      chmod -R 777 cache/
      chmod -R 777 log/
      php symfony cc


1.6.0 (2016-01-14)
------------------

**Note de version**

* Pour les changements dans la base de données vous pouvez exécuter le fichier ``data/update_1.5to1.6.sql``
* Mise à jour de la configuration Apache. Modifier le fichier ``apache/wms.conf`` en vous basant sur l'exemple https://github.com/PnEcrins/GeoNature/blob/master/apache/wms.conf.sample#L16-L17
* Ajouter le paramètre ``$id_application`` dans ``lib/sfGeonatureConfig.php.php`` (voir la valeur utilisée pour GeoNature dans les tables ``utilisateurs.t_applications`` et ``utilisateurs.cor_role_droit_application``)
* Ajouter le paramètre ``import_shp_projection`` dans ``web/js/configmap.map`` - voir l'exemple dans le fichier ``https://github.com/PnEcrins/GeoNature/blob/master/web/js/configmap.js.sample#L35``
* Supprimer toute référence à gps_user_projection dans ``web/js/configmap.map`` 
* Ajouter un tableau JSON des projections disponibles pour l'outil de pointage GPS : ``gps_user_projections`` dans ``web/js/configmap.map``. Respecter la structure définie dans ``https://github.com/PnEcrins/GeoNature/blob/master/web/js/configmap.js.sample#L7-L14``. Attention de bien respecter la structure du tableau JSON et notamment sa syntaxe (accolades, virgules, nom des objects, etc...)
* Ajouter les ``id_liste`` pour les classes faune filtrables dans les formulaires de saisie dans le fichier ``web/js/config.map``. Ceci concerne les variables ``id_classe_oiseaux``, ``id_classe_mammiferes``, ``id_classe_amphibiens``, ``id_classe_reptiles``, ``id_classe_poissons`` et ``id_classe_ecrevisses``, ``id_classe_insectes``, ``id_classe_arachnides``, ``id_classe_myriapodes`` et  ``id_classe_mollusques``. Voir l'exemple dans le fichier ``https://github.com/PnEcrins/GeoNature/blob/master/web/js/config.js.sample#L32-44``
* Taxref a été mis à jour de la version 7 à 8. GeoNature 1.6.0 peut fonctionner avec la version 7. Cependant il est conseillé de passer en taxref V8 en mettant à jour la table ``synthese.taxref`` avec la version 8. Cette mise à jour pouvant avoir un impact fort sur vos données, son automatisation n'a pas été prévue. Le script SQL de migration de vos données de taxref V7 vers taxref V8 n'est donc pas fourni. Pour une installation nouvelle de la base de données, GeoNature 1.6.0 est fourni avec taxref V8.
* Le routing a été mis à jour, vous devez vider le cache de Symfony pour qu'il soit pris en compte. Pour cela, placez vous dans le répertoire racine de l'application et effectuez la commande suivante :

    ::
    
        php symfony cc

**Changements**

* Les recherches dans la synthèse sont désormais faites sur le ``cd_ref`` et non plus sur le ``cd_nom`` pour retourner tous les synonymes du taxon recherché - Fix #92
* Passage de taxref V7 à Taxref V8 - Fix #34
* Intégration de la première version de l'API permettant d'intégrer des données dans la synthèse depuis une source externe - https://github.com/PnEcrins/GeoNature/blob/master/docs/geonature_webapi_doc.rst
* Mise en paramètre du ``id_application`` dans ``lib/sfGeonatureConfig.php.php`` - Fix #105
* Recharger la synthese après suppression d'un enregistrement - Fix #94 
* L'utilisateur peut lui-même définir le système de coordonnées dans l'outil de pointage GPS - Fix #107 
* Mise en paramètre de la projection de la shape importée comme zone de recherche dans la synthèse
* Les exports XLS et SHP comportent le ``cd_nom`` ET le ``cd_ref`` de tous les synonymes du nom recherché ainsi que le nom_latin (bib_taxons) ET le nom_valide (taxref) - Fix #92
* SAISIE invertébrés - Ajout d'un filtre Mollusques - Fix #117
* Amélioration du vocabulaire utilisé sur la page d'accueil - #118
* Affichage d'un message pendant le chargement des exports
* Mise en place de statistiques automatiques sur la page d'accueil, basées sur les listes de taxons. A compléter. 

**Corrections de bug**

* Intégration de la librairie ``OpenLayers.js`` en local dans le code car les liens distants ne fonctionnaient plus - Fix #97
* Correction d'une erreur lors de l'enregistrement de la saisie invertébrés - Fix #104
* Correction d'une erreur de redirection si on choisit "Quitter" après la saisie de l'enregistrement (contact faune, mortalité et invertébrés) - Fix #102
* Correction du trigger ``contactfaune.synthese_update_cor_role_fiche_cf()`` - Fix #95
* Correction d'un bug dans les listes déroulantes des taxons filtrée par classe qui n'affichaient rien - Fix #109 
* Correction d'un bug sur le contenu des exports shape avec le critère de protection activé - Fix #114
* Correction et adaptation faune-flore des exports shape
* SYNTHESE - Correction de la liste des taxons sans nom français - Fix #116
* Corrections CSS sur la page d'accueil - Fix #115
* Correction sur la largeur de la liste des résultats de la synthèse - Fix #110
* Correction des doublons dans la recherche multi-taxons - Fix #101
* Autres corrections mineures


1.5.0 (2015-11-26)
------------------

**Note de version**

* Pour les changements dans la base de données vous pouvez exécuter le fichier ``data/update_1.4to1.5.sql``
* Le bandeau de la page d'accueil ``web/images/bandeau_faune.jpg`` a été renommé en ``bandeau_geonature.jpg``. Renommez le votre si vous aviez personnalisé ce bandeau.
* Si vous souhaitez désactiver certains programmes dans le "Comment ?" de la synthèse vous devez utiliser le champs ``actif`` de la table ``meta.bib_programmes``.
* Compléter si nécessaire les champs ``url``, ``target``, ``picto``, ``groupe`` et ``actif`` dans la table ``synthese.bib_sources``.
* Nouvelle répartition des paramètres de configuration javascript en 2 fichiers (``config.js`` et ``configmap.js``). Vous devez reprendre vos paramètres de configuration du fichier ``web/js/config.js`` et les ventiler dans ces deux fichiers.
* Ajouter le paramètre ``id_source_mortalite = 2;`` au fichier ``web/js/config.js``;
* Retirer le paramètre ``fuseauUTM;`` du fichier ``web/js/config.js``;
* Bien définir le système de coordonnées à utiliser pour les pointages par coordonnées fournies en renseignant le paramètre ``gps_user_projection`` dans le fichier ``web/js/configmap.js``;
* Ajouter le paramètre ``public static $id_source_mortalite = 2;`` au fichier ``lib/sfGeonatureConfig.php``;
* Ajouter le paramètre ``public static $srid_ol_map = 3857;`` au fichier ``lib/sfGeonatureConfig.php``;
* L'altitude est calculée automatiquement à partir du service "Alticodage" de l'API GeoPortail de l'IGN et non pluas à partir de la couche ``layers.l_isolines20``. Ajoutez ce service dans votre contrat API Geoportail. Il n'est donc plus nécessaire de remplir la couche ``layers.l_isolines20``. Cette couche peut toutefois encore être utile si l'utilisateur supprime l'altitude calculée par l'API Geoportail dans les formulaires de saisie.
* Le loup et le lynx sont retirés par défaut de la saisie (saisie recommandée dans le protocole national du réseau grands prédateurs)
* Le cerf, chamois et le bouquetin doivent être saisis selon 6 critères de sexe et age et non 5 comme les autres taxons. Comportement peut-être changé en modifiant la vue ``contactfaune.v_nomade_taxons_faune``.
* Mortailité est désormais une source à part entière alors qu'elles étaient mélangées avec la source ContactFaune précédemment. Si vous avez déjà des données de mortalité enregistrées, vous devez adapter la requête SQL ci-dessous avec votre ``id_source`` pour Mortalité et l'exécuter :
    
    ::
    
        UPDATE synthese.syntheseff SET id_source = 2 WHERE id_source = 1 AND id_critere_synthese = 2;

**Changements**

* Optimisation des vues aux chargement des listes de taxons. Fixes #64
* Généricité des champs dans ``meta.bib_programmes`` (champs ``sitpn`` renommé en ``public``). Fixes #68
* Ajout d'un champ ``actif`` à la table ``meta.bib_programmes`` permettant de masquer certains programmes dans le "Comment ?" de la synthèse. Fixes #66
* Ajout d'un champ ``url``, ``target``, ``picto``, ``groupe`` et ``actif`` dans la table ``synthese.bib_sources`` pour générer la page d'accueil dynamiquement et de manière générique. Fixes #69
* Construire dynamiquement la liste des liens vers la saisie des différents protocoles à partir de la table ``synthese.bib_sources``. Fixes #69
* Tous les styles des éléments de la page d'accueil ont été passés en CSS. Fixes #57
* Amélioration de l'interface pendant le chargement des différentes applications (synthèse, flore station, formualires de saisie...). Fixes #65
* Recentrage sur la position de l'utilisation en utilisant le protocole de géolocalisation intégré au navigateur de l'utilisateur. Fixes #65
* Un message automatique conseille les utilisateurs d'Internet Explorer de plutôt utiliser Firefox ou Chrome. Fixes #65
* Tri par défaut par date décroissante des 50 dernières observations affichées à l'ouverture de la Synthèse. Fixes #51
* Vocabulaire. "Dessiner un point" remplacé par "Localiser l'observation". Fixes #66
* Mise à jour des copyrights dans les pieds de page de toutes les applications.
* Refonte du CSS du formulaire de login avec bootstrap et une image de fond différente.
* Refonte Bootstrap de la page d'accueil.
* Homogénéisation du pied de page.
* FloreStation et Bryophytes - Homogénéiser interaction carte liste - ajout d'un popup au survol. Fixes #74
* Suppression d'images non utilisées dans le répertoire ``web/images``.
* Mise en cohérence des vues taxonomiques faune. Fixes #81
* Calcul de l'altitude à partir du service "Alticodage" de l'API GeoPortail de l'IGN.
* Factorisation et généralisation du module permettant un positionnement des pointages par saisie de coordonnées selon projection et bbox fournies en paramètres de config.
* Création d'une configuration javascript carto dédiée (``configmap.js``).
 
**Corrections de bug**
 
* Correction des problèmes de saisie de la version 1.4.0 liés à la migration de la taxonomie.
* Correction de bugs dans Flore Station et Bryophytes (Zoom, recherche


1.4.0 (2015-10-16)
------------------

**Note de version**

* La gestion de la taxonomie a été mis en conformité avec le schéma ``taxonomie`` de la base de données de TaxHub (https://github.com/PnX-SI/TaxHub). Ainsi le schéma ``taxonomie`` intégré à GeoNature 1.3.0 doit être globalement revu. L'ensemble des modifications peuvent être réalisées en éxecutant la partie correspondante dans le fichier ``data/update_1.3to1.4.sql`` (https://github.com/PnEcrins/GeoNature/blob/master/data/update_1.3to1.4.sql).
* De nouveaux paramètres ont potentiellement été ajoutés à l'application. Après avoir récupéré le fichier de configuration de votre version 1.3.0, vérifiez les changements éventuels des différents fichiers de configuration.
* Modification du nom de l'host host hébergeant la base de données. databases --> geonatdbhost. A changer ou ajouter dans le ``/etc/hosts`` si vous avez déjà installé GeoNature.
* Suivez la procédure de mise à jour : http://geonature.readthedocs.org/fr/latest/update.html

**Changements**

* A l'installation initiale, chargement en base des zones à statuts juridiques pour toute la France métropolitaine à partir des sources de l'INPN
* A l'installation initiale, chargement en base de toutes les communes de France
* Mise en place de la compatibilité de la base avec le schema de TaxHub


1.3.0 (2015-02-11)
------------------

Pré-Version de GeoNature - Faune ET Flore. Le fonctionnement de l'ensemble n'a pas été totalement testé, des bugs sont identifiés, d'autres subsistent certainement.

**Changements**

* Grosse évolution de la base de données
* Ajout de deux applications de saisie flore (flore station et bryophytes)
* Intégration de la flore en sythese
* Ajouter un id_lot, id_organisme, id_protocole dans toutes les tables pour que ces id soit ajoutés vers la synthese en trigger depuis les tables et pas avec des valeurs en dur dans les triggers. Ceci permet d'utiliser les paramètres de conf de GeoNature
* Ajout d'une fonction à la base pour correction du dysfonctionnement du wms avec mapserver
* Suppression du champ id_taxon en synthese et lien direct de la synthese avecle taxref. ceci permet d'ajouter des données en synthese directement dans la base sans ajouter tous les taxons manquants dans la table bib_taxons
* Suppression de la notion de coeur dans les critère de recherche en synthese
* Ajout d'un filtre faune flore fonge dans la synthese
* Ajout de l'embranchement et du regne dans les exports
* Permettre à des partenaires de saisir mais d'exporter uniquement leurs données perso
* Ajout du déterminateur dans les formulaires invertébrés et contactfaune + en synthese
* Ajout du référentiel géographique de toutes les communes de France métropolitaine
* Ajout des zones à statuts juridiques de la région sud-est (national à venir)
* Bugs fix
 
**BUG à identifier**

Installation :

* corriger l'insertion de données flore station qui ne fonctionne pas

Bryophythes :

* Corriger la recherche avancée par date sans années

Synthèse :

* la construction de l'arbre pour choisir plusieurs taxons ne tient pas compte des filtres
* le fonctionnement des unités geographiques n'a pas été testé (initialement conçu uniquement pour la faune)


1.2.0 (2015-02-11)
------------------

Version stabilisée de GeoNature - Faune uniquement (Synthèse Faune + Saisie ContactFauneVertebre, ContactFauneInvertebre et Mortalité).

**Changements**

* Modification du nom de l'application de FF-synthese en GeoNature
* Changement du nom des utilisateurs PostgreSQL
* Changement du nom de la base de données
* Mise à jour de la documentation (http://geonature.readthedocs.org/)
* Automatisation de l'installation de la BDD
* Renommer les tables pour plus de généricité
* Supprimer les tables inutiles ou trop spécifiques
* Gestion des utilisateurs externalisée et centralisée avec UsersHub (https://github.com/PnEcrins/UsersHub)
* Correction de bugs
* Préparation de l'intégration de la Flore pour passer de GeoNature Faune à GeoNature Faune-Flore


1.1.0 (2014-12-11)
------------------

**Changements**

* Modification du schéma de la base pour être compatible taxref v7
* Import automatisé de taxref v7
* Suppression des tables de hiérarchie taxonomique (famille, ordre, ...) afin de simplifier l'utilisation de la taxonomie.
* Création de la notion de groupe (para-taxonomique) à la place de l'utilisation des classes.
* Ajout de données pour pouvoir tester de façon complète l'application (invertébrés, vertébrés)
* Ajout de données exemples
* Bugs fix


1.0.0 (2014-12-10)
------------------

Version fonctionnelle des applications : visualisation de la synthèse faune, saisie d'une donnée de contact (vertébrés, invertébrés, mortalité)

**Changements**

* Documentation de l'installation d'un serveur Debian wheezy pas à pas
* Documentation de la mise en place de la base de données
* Documentation de la mise en place de l'application et de son paramétrage
* Script d'insertion d'un jeu de données test
* Passage à PostGIS v2
* Mise en paramètre de la notion de lot, protocole et source

**Prochaines évolutions**

* Script d'import de taxref v7
* Utilisation préférentielle de la taxonomie de taxref plutôt que les tables de hiérarchie taxonomique


0.1.0 (2014-12-01)
------------------

* Création du projet et de la documentation
