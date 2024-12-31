# CHANGELOG

## 2.15.1 (unreleased)

**🚀 Nouveautés**

- Amélioration de la recherche libre des métadonnées en cherchant chaque mot indépendamment (#3295, par @jbrieuclp)
- Amélioration de l'affichage de la photo du taxon sur les fiches taxon (#3287, par @edelclaux)
- Améliorations de la commande d’installation des modules (#3261 par @bouttier)

**🐛 Corrections**

- Correction de la pagination quand on filtre les discussions de la page d'accueil sur "Mes discussions" (#3288, par @edelclaux)
- Correction du nombre de taxons sur les fiches des cadres d'acquisition (#3228, par @jacquesfize)


## 2.15.0 - Pavo cristatus 🦚 (2025-12-11)

**⏩ En bref**

- Nouvelle version de TaxHub (2.0.0) intégrée à GeoNature
- Fiche de taxon enrichie intégrant l'actuel profil mais aussi une synthèse géographique, les informations taxonomiques ainsi qu'une liste des statuts de protection
- Module Import intégré à GeoNature
- Import de données vers le module Occhab
- Dernières discussions listées sur la page d'accueil

**🚀 Nouveautés**

- [TaxHub] Intégration de TaxHub ([2.0.0 Release Note](https://github.com/PnX-SI/TaxHub/releases/tag/2.0.0)) à GeoNature (#3280)
  - La gestion des taxons est maintenant intégrée dans le module Admin de GeoNature.
- [Import] Refonte et intégration du module Import dans GeoNature (#3269)
  - Ajout d'une nouvelle destination d'import de données : Occhab
  - Ajout de la possibilité d'étendre les destinations disponibles pour l'import de données vers d'autres modules. [Documentation de développement](https://docs.geonature.fr/development.html#integrer-limport-de-donnees-dans-votre-module) dédiée à ce sujet
  - Ajout d'un bouton pour importer des données directement depuis le module de destination (Synthèse et Occhab actuellement)
  - Evolution des permissions : la création d'un import dépend de l'action C sur le module Import et de l'action C dans le module de destination (Synthèse et/ou Occhab)
  - Plusieurs améliorations : de nouveaux contrôles des données, un rapport d'import revu et intégration de nouveaux tests frontends
  - Intégration et complément de la documentation utilisateur et administrateur du module dans la documentation de GeoNature
- [Authentification] Possibilité de se connecter à GeoNature avec d'autres fournisseurs d'identité (#3111)
  - Plusieurs protocoles de connexion intégrés activables et paramétrables : OAuth, CAS INPN, UserHub
  - Possibilité de se connecter sur d'autres instances GeoNature
- [Synthèse] Enrichissement de la fiche taxon (#2981, #3131, #3187, #3175)
  - Affichage de la synthèse géographique d'un taxon
  - Affichage du statut de protection du taxon
  - Affichage des informations taxonomiques présentes dans Taxref
  - Ajout d'un lien vers la fiche du taxon depuis la liste des observations de la Synthèse (#2718)
- [Synthèse] Possibilité de partager une URL de redirection vers un onglet (détails, taxonomie, discussion, validation, etc.) de la fiche d'une observation (#3169)
- [Accueil] Ajout d'un bloc `Discussions` sur la page d'accueil, désactivable avec le paramètre `DISPLAY_LATEST_DISCUSSIONS` (#3138)
  - Filtrable sur les discussions dans lesquelles l'utilisateur authentifié a participé, ou associé à une des observations dont il est : soit l'observateur ou l'opérateur de la saisie (#3194)
- [Occhab] Remplacement du champ `is_habitat_complex` par le nouveau champ `id_nomenclature_type_habitat` et intégration de la nomenclature SINP associée (voir MosaiqueValue dans la version 2 du standard Occurrences d'habitats du SINP) (#3125)
- [Occhab] Affichage de l'UUID de la station dans sa fiche détail (#3247)
- [Occhab] Amélioration de l'export des données en revoyant la vue `pr_occhab.v_export_sinp` (#3122)
- [Métadonnées] Possibilité de supprimer un cadre d'acquisition vide (#1673)
- [Occtax] Ajout du nom de lieu dans le détail d'un relevé (#3145)
- [RefGeo] De nouvelles mailles INPN sur la France métropolitaine (2km, 20km, 50km) sont disponibles (https://github.com/PnX-SI/RefGeo/releases/tag/1.5.4)
- [Monitoring] Ajout de la gestion de la table `gn_monitoring.t_observations` directement dans GeoNature (#2824)
- La synchronisation avec le service MTD de l'INPN n'est plus intégrée dans le code de GeoNature, elle a été déplacée dans un module externe (https://github.com/PnX-SI/mtd_sync)

**🐛 Corrections**

- Correction de l'URL des modules externes dans le menu latéral (#3093)
- Correction des erreurs d'exécution de la commande `geonature sensitivity info` (#3216)
- Correction du placement des tooltips pour le composant `ng-select` (#3142)
- Correction de l'interrogation des profils dans Occtax (#3156)
- Correction de l'affichage du lieu dans les fiches des relevés Occtax (#3145)
- Correction de l'export Occhab avec des champs additionnels vides (#2837)
- Correction d'un soucis de duplication des géométries quand on modifie un polygone (#3195)
- Correction de la recherche avancée par zonage dans le module Métadonnées (#3250)
- Correction d'un scroll non souhaité dans l'interface du module Synthèse (#3233)
- Correction de l'affichage des acteurs dans les fiches des observations de la Synthèse (#3086)
- Correction du chargement des champs additionnels de type Nomenclature (#3082)
- Correction des filtres taxonomiques avancés dans le mdoule Synthèse (#3087)
- Correction de l'affichage des boutons radio quand ceux-ci sont obligatoires (#3210)
- Correction de la commande `geonature sensitivity info` (#3208)
- Correction de la redirection vers la page d'authentification quand on accède au module Admin sans être authentifié (#3171)
- Correction du scroll du menu latéral dans le module Admin (#3145)
- Correction de l'aperçu des médias de type PDF (#3260)
- Corrections diverses de la documentation
- Ajout d'un action Github permettant de lancer les tests depuis des modules externes (#3232)
- Lancement de `pytest` sans _benchmark_ ne nécessite plus l'ajout de `--benchmark-skip` (#3183)

**⚠️ Notes de version**

- Si vous utilisez GeoNature-citizen, attendez qu'une version de celui-ci compatible avec TaxHub 2.x soit disponible.
- Si vous mettez à jour GeoNature :

**Avant la mise à jour de GeoNature :**

- Ajouter l'extension `ltree` à votre base de données : `sudo -n -u postgres -s psql -d <nom_basededonnee_de_votregeonature> -c "CREATE EXTENSION IF NOT EXISTS ltree;"`
- Si vous utilisez le module Monitoring, mettez-le à jour en version 1.0.0 minimum
- Si vous utilisez le module Monitoring, les champs `id_digitizer` des tables `gn_monitoring.t_base_sites`, `gn_monitoring.t_base_visits` est désormais obligatoire. Assurez-vous qu'ils soient peuplés avant de lancer la mise à jour de GeoNature (`SELECT * FROM gn_monitoring.t_base_visits tbv WHERE id_digitiser IS NULL; SELECT * FROM gn_monitoring.t_base_sites tbs WHERE id_digitiser IS NULL;`).
- Suivez la procédure de mise à jour classique de GeoNature (<https://docs.geonature.fr/installation.html#mise-a-jour-de-l-application>)

**Après la mise à jour de GeoNature :**

- L'application TaxHub a été integrée dans le module "Admin" de GeoNature (#3280) :
  - Les permissions basées sur les profils 1-6 ont été rapatriées et adaptées au modèle de permissions de GeoNature.
    TaxHub est désormais un "module" GeoNature et dispose des objets de permissions `TAXONS`, `THEMES`, `LISTES` et `ATTRIBUTS`. Les utilisateurs ayant anciennement des droits 6 dans TaxHub ont toutes les permissions sur les objets pré-cités. Les personnes ayant des droits inférieurs à 6 et ayant un compte sur TaxHub ont maintenant des permissions sur l'objet `TAXON` (voir et éditer des taxons = ajouter des médias et des attributs)
  - L'API de TaxHub est désormais disponible à l'URL `<URL_GEONATURE>/api/taxhub/api/` (le suffixe `/api` est une rétrocompatibilité et sera enlevé de manière transparente dans les prochaines versions)
  - Le paramètre `API_TAXHUB` de GeoNature est désormais obsolète (déduit de `API_ENDPOINT`) et peut être retiré du fichier de configuration de GeoNature
  - Si vous utilisez Occtax-mobile, veillez à modifier son paramètre `taxhub_url` du fichier `/geonature/backend/media/mobile/occtax/settings.json`, pour mettre la valeur `<URL_GEONATURE>/api/taxhub`. Idem dans le paramètre `TAXHUB_URL` de GeoNature-atlas si vous utilisez celui-ci.
  - Les médias ont été déplacés automatiquement du dossier `/static/medias/` de TaxHub vers le dossier `/backend/media/taxhub/` de GeoNature. En conséquence, les URL des médias des taxons ont changé. Vous devez donc le répercuter les paramètres de vos éventuelles applications qui les utilisent (`REMOTE_MEDIAS_URL` et `REMOTE_MEDIAS_PATH` de la configuration de GeoNature-atlas par exemple).
  - L'intégration de TaxHub dans GeoNature entraine la suppression de son service systemd dédié et la configuration Apache spécifique de TaxHub. Les logs de TaxHub sont également désormais centralisés dans le fichier de log de GeoNature.
  - L'application TaxHub indépendante n'est plus utilisée, effectuez donc les actions suivantes :
    - Supprimez la branche alembic taxhub : `geonature db downgrade taxhub-standalone@base`
    - Supprimez le dossier spécifique de l'ancien TaxHub (à priori dans `/home/monuser/taxhub/`)
  - Les commandes de TaxHub sont maintenant accessibles depuis la commande `geonature`, par exemple :
    ```shell
    geonature taxref migrate-to-v17 # flask taxref migrate-to-v17
    ```
- Le module Import a été intégré dans le coeur de GeoNature (#3269)
  - Si vous aviez installé le module externe Import, l'ancienne version a été désinstallée lors de la mise à jour de GeoNature.
  - Si vous n'aviez pas installé le module externe Import, il sera disponible après la mise à jour de GeoNature. Vous pouvez configurer les permissions de vos utilisateurs si vous souhaitez qu'ils accédent au module Import.
  - La gestion des permissions du module Import et des JDD qui lui sont associés a évolué. La migration de ces données est gérée automatiquement lors de la mise à jour de GeoNature pour garantir un fonctionnement identique du module Import.
  - Reporter l'éventuelle configuration de votre module Import dans le fichier de configuration de GeoNature (dans le bloc `[IMPORT]` du fichier `geonature_config.toml`, voir le fichier d'exemple `default_config.toml.example`)
- Si vous souhaitez intégrer les nouvelles mailles INPN, vous pouvez éxécuter ces commandes :
  ```
  geonature db upgrade ref_geo_inpn_grids_2@head  # Insertion des mailles 2x2km métropole, fournies par l’INPN
  geonature db upgrade ref_geo_inpn_grids_20@head  # Insertion des mailles 20x20km métropole, fournies par l’INPN
  geonature db upgrade ref_geo_inpn_grids_50@head # Insertion des mailles 50x50km métropole, fournies par l’INPN
  ```

**📝 Merci aux contributeurs**

@amandine-sahl, @Pierre-Narcisi, @jacquesfize, @TheoLechemia, @bouttier, @andriacap, @edelclaux, @JulienCorny, @VincentCauchois, @CynthiaBorotPNV, @JeromeMaruejouls, @jbrieuclp, @blaisegeo, @lpofredc, @amillemonchicourt, @ch-cbna

## 2.14.2 (2024-05-28)

**🚀 Nouveautés**

- Mise à jour de dépendances critiques (#3054)
- Mise à jour de NodeJS en version 20 (#2997)

**🐛 Corrections**

- Correction d'erreurs dans les fichiers de traductions du frontend (#3026)
- Correction de la fermeture des sessions SQLAlchemy lancées par Celery (#3050, #3062 )
- [CAS-INPN] Fix du système d'authentification au CAS de l'INPN (#2866)
- [Monitoring] Correction de la requête SQLAlchemy de récupération des aires de sites (#2984)
- [Occtax] Correction de la transformation de la valeur par défaut dans les champs additionnels d'Occtax (#2978, #3011, #3017)
- [RefGeo] Correction du filtre `type_code` de la route `/geo/areas` (#3057, PnX-SI/RefGeo#26)

## 2.14.1 (2024-04-29)

**🚀 Nouveautés**

- [Synthèse] Possibilité d'ajouter des colonnes supplémentaires à la liste de résultats via le paramètre `ADDITIONAL_COLUMNS_FRONTEND`. Ces champs sont masqués par défaut et controlables depuis l'interface (#2946)
- [Synthèse] Possiblité d'ajouter des exports personnalisés basés sur des vues SQL via le paramètre `EXPORT_OBSERVATIONS_CUSTOM_VIEWS` (#2955)
- [DynamicForm] Possibilité de définir une valeur par défaut sur le composant `bool_checkbox` (#2819)
- [Documentation] Simplification, automatisation et documentation du changement de l'URL de l'API de GeoNature au niveau du frontend (#2936)
- [Configuration] Enrichissement des URI autorisés de connexion à la BDD PostgreSQL (#2947)
- [TaxHub] Mise à jour de TaxHub en version 1.14.0, incluant par défaut Taxref v17, BDC statuts v17 et référentiel de sensibilité v17

**🐛 Corrections**

- [Occtax] Correction de l'inversion des valeurs par défaut de 2 nomenclatures (#2822)
- [Synthèse] Correction du lien de renvoi vers le module de saisie d'une observation (#2907)
- [Validation] Correction de l'enregistrement d'une validation quand l'utilisateur a des permissions avec une portée limitée (#2958)
- [Occhab] Prise en compte des permissions utilisateurs dans l'affichage des boutons d'actions (info, édition, suppression) dans la liste de stations du module Occhab (#2942)
- [MTD] Amélioration des performances de la synchronisation avec le service MTD (#2922)
- Correction du double chargement des fond de carte (#2902)
- [Synthèse] Amélioration des performances de la liste des zonages dans les filtres de la synthèse (#2977 & https://github.com/PnX-SI/RefGeo/pull/22)
- Correction de la redirection du bouton "Accueil" quand GeoNature est déployé sur une URL avec un suffixe (#2934)
- Correction de la connexion avec le CAS de l'INPN (#2866)
- Correction d'une mauvaise synchronisation du cookie et du JWT via une MAJ de pypnusershub (PnX-SI/UsersHub-authentification-module#94)

**💻 Développement**

- Suppression de l'utilisation du composant `ngx-mat-select-search` (#2826 & #2827)
- [Occtax] Il n'est plus obligatoire de poster le champs `additionnal_fields` au niveau de l'API des relevés, taxons et dénombrements (#2937)
- Suppression des branches et ajout d'adresses relatives dans `.gitmodules` (#2959)
- Lint et doc HTML/CSS (#2890 & #2960)
- Correction de l'héritage des composants `GenericFormComponent` (#2961)
- Utilisation de `pytest-benchmark` pour l'évaluation automatique de performances des routes (#2896)
- Utilisation de `marshmallow` pour la validation des données renvoyées par la route `get_observations_for_web` et ajout du contrôle de la présence des champs obligatoires (#2950)

**⚠️ Notes de version**

Si vous mettez à jour GeoNature :

- Les paramètres de la synthèse permettant de spécifier le nom de certaines colonnes de la vue d'export sont dépréciés (`EXPORT_ID_SYNTHESE_COL`, `EXPORT_ID_DIGITISER_COL`, `EXPORT_OBSERVERS_COL`, `EXPORT_GEOJSON_4326_COL`, `EXPORT_GEOJSON_LOCAL_COL`).
- Si vous aviez surcouché la vue par défaut `gn_synthese.v_synthese_for_export`, il est recommandé de ne plus le faire et de plutôt utiliser le nouveau paramètre `EXPORT_OBSERVATIONS_CUSTOM_VIEWS` permettant de se créer ses propres vues d'export personnalisées. Voir "Export des observations" dans la documentation du module Synthèse (https://docs.geonature.fr/admin-manual.html#module-synthese)
- Vous pouvez mettre à jour TaxHub en version 1.14.0 (ou plus si compatible) et mettre à jour Taxref en version 17, ainsi que la BDC statuts et le référentiel de sensibilité
- Vous pouvez mettre à jour UsersHub en version 2.4.2 (ou plus si compatible)

## 2.14.0 - Talpa europaea 👓 (2024-02-28)

Cette nouvelle version de GeoNature propose de nouvelles fonctionnalités comme le floutage de données sensibles dans le module Synthèse ainsi qu'un système de validation automatique des données basé sur les profils de taxons.  
Elle intégre aussi plusieurs mises à jour des versions des librairies python utilisées comme Flask (3.0) et SQLAlchemy (1.4).

**⚠️ Notes de version**

Si vous mettez à jour GeoNature :

- Le support de Debian 10 a été arrêté, votre serveur doit être en Debian 11 ou 12
- Mettre à jour TaxHub en version 1.13.3 (ou plus) et optionnellement UsersHub (2.4.0 ou plus)
- Si vous les utilisez, mettez à jour les modules Import (version 2.3.0), Export (version 1.7.0), Monitoring (version 0.7.2) et Dashboard (version 1.5.0), avec la nouvelle procédure consistant uniquement à télécharger, dézipper et renommer les dossiers des modules
- Si vous utilisez d'autres modules externes, vérifiez qu'ils disposent d'une version compatible avec GeoNature 2.14 (SQLAlchemy 1.4, Python 3.9 minimum, supression du fichier `app.config.ts`)
- Suivez la procédure de mise à jour classique de GeoNature (<https://docs.geonature.fr/installation.html#mise-a-jour-de-l-application>)
- Si vous utilisez les fonds IGN, mettez à jour les URL des flux dans votre fichier de configuration `geonature_config.toml` (#2789)

**🚀 Nouveautés**

- [Synthèse] Floutage des données sensibles (#2558)
  - Il est désormais possible de définir un filtre "Flouter les données sensibles" sur les actions _Lire_ et _Exporter_ du module Synthèse
  - Pour les utilisateurs qui ont ce filtre de permission appliqué, les données sensibles seront floutées lors de leur affichage ou de leur export dans le module Synthèse, en fonction des mailles ou zonages définis dans les règles de sensibilité du SINP
  - En mode Mailles, les données sensibles dont la géométrie floutée est plus grande que la maille affichée sont exclues
  - Dans l'onglet "Zonage" des fiches des observations de la Synthèse, on affiche uniquement les zonages plus grands que la géométrie floutée des données sensibles
  - Si un utilisateur dispose de permissions filtrées sur les données sensibles, alors les filtres par zonage s'appuie sur une intersection spatiale avec les géométries floutées pour ne pas renvoyer d'informations plus précises sur les données floutées
  - La documentation sur le sensibilité des données a été complétée : https://docs.geonature.fr/admin-manual.html#gestion-de-la-sensibilite)
  - Le paramètre `BLUR_SENSITIVE_OBSERVATIONS` permet de basculer sur l'exclusion des données sensibles plutôt que leur floutage, comme implémenté dans la version 2.13
- [Validation] Fonction de validation automatique basée sur les profils de taxons (non activée par défaut et surcouchable avec une fonction spécifique) (#2600)
- [Synthèse] Ajout des groupes 3 INPN dans les filtres et les exports de la Synthèse (#2621, #2637)
- [Occtax] Ajout de la possibilité d'associer des nomenclatures à des groupes 3 INPN (#2684)
- [Authentification] Possibilité d'ajouter des liens externes (#2917)
- [Carte] Mise à jour des exemples d'URL de fonds de carte IGN (#2789)
- [RefGeo] Répercussion du remplacement du champs `geojson_4326` par `geom_4326` dans la table `l_areas` (#2809)
- [Documentation] Ajout de diagrammes d'architecture dans la documentation (#2760)

**🐛 Corrections**

- Correction de l'affichage du nom du module quand on revient à la page d'accueil (#2795)
- [Synthèse] Correction de l'affichage du nom du taxon observé quand les profils de taxons sont désactivés (#2820)
- [Carte] Conservation de la géométrie existante lorsqu'on annule la modification d'une géométrie (#2778)
- [Métadonnées] Correction de l'affichage du type de financement sur les fiches détail des CA et JDD (#2840)
- [Occhab] Correction des permissions avec portée limitée (#2909)
- [Occtax] Correction de la suppression d'un champ additionnel (#2923)

**💻 Développement**

- Mise à jour vers SQLAlchemy 1.4 (#1812)
- Mise à jour vers Flask 3 (#2751)
- Mise à jour de Black en version 24 (#2879)
- Suppression des modules dépréciés : `utilsgeometry.py`, `utilssqlalchemy.py`, `config_manager.py` (#2751)
- Intégration de la documentation automatique des composants Frontend (avec `compodoc`) et des fonctions et classes du backend (avec `sphinx-autoapi`) (#2765)
- Abandon du système d'authentification par cookie, sauf pour le module Admin. Le token d'authentification (JWT) est maintenant passé dans chaque appel à l'API dans le header HTTP "Authorization Bearer". Il est aussi fourni par la route de login du sous-module d'authentification et stocké dans le localStorage (#2586, #2161, #490, #2574)
- Suppression du fichier `app.config.ts` (#2747)
- Passage du paramètre `--line-length` de Black de 99 à 100 caractères (#2847)
- Modification de `TModules` pour éviter de lever l'erreur de polymorphisme de SQLAlchemy (#2792)
- Fin du support de Debian 10 et de Python 3.7 (#1787)
- Changement de l'ensemble des requêtes SQLAlchemy au style 2.0 (#2751)
- Augmentation du nombre de tests unitaires dans : `gn_meta`, `occtax`, `occhab`, `synthese` (#2751)
- Modification des `fixtures` : `datasets`, `stations` + `user`(#2751). Possibilité de créer des utilisateurs de tests avec des permissions plus fines (#2915)

**📝 Merci aux contributeurs**

@amandine-sahl, @Pierre-Narcisi, @jacquesfize, @TheoLechemia, @bouttier, @mvergez, @andriacap, @edelclaux, @VincentCauchois, @MoulinZ, @pierre56, @camillemonchicourt

## 2.13.4 (2023-12-15)

**🚀 Nouveautés**

- [Synthèse] Ajout des colonnes `group[1,2,3]_inpn` à la vue `gn_synthese.v_synthese_for_web_app` (#2798, par @andriacap)

**🐛 Corrections**

- [Métadonnées] Masquage des références bibliograhpiques dans le formulaire des cadres d'acquisition en attendant la finalisation du développement du backend (#2562, par @DonovanMaillard)
- [Occtax] Correction du problème de chargement de la liste de JDD lors de la création d'un relevé (#2815, par @andriacap)
- [Synthèse et validation] Ajout de la méthode de détermination dans la fiche détail d'une observation (#2785, par @DonovanMaillard)
- [Frontend] Correction de la prise en compte des filtres dans le composant `datalist` (#2777, par @joelclems)
- [Synthèse] Optimisation du chargement de l'affichage des observations groupées par maille (#2766, par @mvergez)
- [Accueil] Optimisation du chargement des statistiques générales (#2771, par @mvergez)
- [Synthèse] Correction et enrichissement de la configuration des colonnes affichées dans la liste des observations (#2749, par @mvergez)
- [Synthèse] Correction de la recherche par attribut TaxHub de type "multiselect" (#2767, par @mvergez)
- [Occtax] Tri alphabétique de la liste des "Mes lieux" (#2805, par @DonovanMaillard)
- [Documentation] Corrections et compléments de la documentation d'administrateur (#2812, par @marie-laure-cen)

## 2.13.3 (2023-10-17)

**🐛 Corrections**

- [Métadonnées] Correction de l'affichage des descriptions dans les fiches des cadres d'acquisition (#2716, par @mvergez)
- [Admin] Correction de la modification des permissions sensibles (#2697, par @Pierre-Narcisi)
- [Synthèse] Correction de la documentation du paramètre `AREA_FILTERS` (#1892, par @camillemonchicourt)
- [Médias] Conservation de la rotation des images des vignettes (#2742, par @MathRdt)

**💻 Développement**

- Utilisation du fichier `requirements.txt` pour les tests automatiques des contributions dans la branche `master` (#2739, par @Pierre-Narcisi)
- Déplacement des dépendances de développement des types Leaflet vers les dépendances de production (#2744, par @TheoLechemia)
- Prise en compte du paramètre `creatableInModule` du composant `dataset` dans les dynamic forms (#2736, par @amandine-sahl)

## 2.13.2 (2023-09-28)

**🚀 Nouveautés**

- [Synthèse] Ajout d'un filtre par module de provenance (#2670, par @andriacap)

**🐛 Corrections**

- Correction des déconnexions non effectives dans les versions 2.13.0 et 2.13.1 (#2682, par @TheoLechemia)
- Correction des permissions vérifiées pour pouvoir supprimer un signalement en prenant en compte le C du module Validation, et non pas le R qui n'existe pas sur ce module (#2710, par @Pierre-Narcisi)
- Correction de l'API des applications mobiles quand le chemin de l'APK est absolu (#2708, par @joelclems)
- Correction des permissions des listes de JDD dans les modules de saisie (Occtax, Occhab, Import) en prenant en compte la portée du C du module, et pas seulement du R du module Métadonnées (#2712, par @Pierre-Narcisi)
- Utilisation de l'heure locale du serveur pour lancer les taches Celery (#2725, par @bouttier)
- Fermeture des connexions à la BDD à la fin des taches Celery (#2724, par @bouttier)
- Correction de l'affichage du bouton permettant d'importer directement depuis la fiche d'un JDD, nécessitant la version 2.2.3 du module Import (#2713, par @bouttier)

**💻 Développement**

- Ajout du thème Bootstrap au composant `datalist` (#2727, par @TheoLechemia)
- Docker : utilisation de python 3.11 (#2728, par @bouttier)
- Déplacement du `DispatcherMiddleware` après les fichiers statiques customisés (#2720, par @bouttier)
- Suppression du script `03b_populate_db_for_test.sh` (#2726, par @bouttier)

**📝 Documentation**

- Mise à jour de la documentation suite aux évolutions des permissions dans la 2.13.0 (par @camillemonchicourt)

## 2.13.1 (2023-09-15)

L'installation de GeoNature (ainsi que ses 4 modules externes principaux, TaxHub et UsersHub) avec Docker est désormais complet et fonctionnel. Voir la documentation sur https://docs.geonature.fr/installation.html#docker.  
C'est la manière la plus simple de déployer GeoNature avec ses 4 modules externes principaux (Import, Export, Dashboard, Monitoring) mais aussi de les mettre à jour, avec seulement quelques lignes de commandes, à partir des images construites automatiquement et du fichier `docker-compose` global, fourni dans le dépôt [GeoNature-Docker-services](https://github.com/PnX-SI/GeoNature-Docker-services).

**🚀 Nouveautés**

- Amélioration de l'affichage des taxons en passant à la ligne quand ils sont trop longs (#2690, par @JulienCorny)
- Amélioration du `Dockerfile` de GeoNature (#2623, par @joelclems et @bouttier)
- Ne pas renvoyer les modules désactivés dans la route `/modules` (#2693, par @bouttier)
- Mise à jour de TaxHub en version 1.12.1 (#2623, par @joelclems)
- Mise à jour de Utils-Flask-SQLAlchemy en version 0.3.6 et UsersHub-authentification-module en version 1.6.10 (#2704, par @TheoLechemia)
- Mise à jour de différentes dépendances Python (#2704, par @TheoLechemia)

**🐛 Corrections**

- Correction des déconnexions non effectives sur la 2.13.0 (#2682, par @TheoLechemia)
- Correction de la configuration NGINX des préfixes quand GeoNature est déployé avec Docker (#2698, par @bouttier)
- Correction des permissions vérifiées pour pouvoir supprimer un signalement en prenant en compte le R du module Validation, et non pas le V du module Synthèse (#2705, par @Pierre-Narcisi)
- Correction de l'épinglage des observations qui était encore partagé entre utilisateurs, et non pas individuels (#2702, par @Pierre-Narcisi)
- [Synthèse] Correction de la recherche de taxons avec des accents (#2676, par @Pierre-Narcisi)
- [Synthèse] Correction des couleurs des mailles quand on clique sur différentes mailles successivement en mode maille (#2677, par @Pierre-Narcisi)

**📝 Documentation**

- Documentation de la nouvelle interface d'administration des permissions (#2605, par @camillemonchicourt), disponible sur https://docs.geonature.fr/user-manual.html#admin
- Mise à jour de la documentation d'installation Docker suite à la sortie d'un Docker Compose complet et fonctionnel sur [GeoNature-Docker-services](https://github.com/PnX-SI/GeoNature-Docker-services/) (#2703)
- Correction de petites fautes d'orthographe (#2674, par @omahs)
- Correction du template d'issue (#2700, par @mvergez)

## 2.13.0 - [Carpodacus erythrinus](https://www.ecrins-parcnational.fr/breve/roselin-gondouins) 🐤 (2023-08-23)

- Révision globale des permissions pour pouvoir leur associer d'autres types de filtres (sensibilité notamment), les simplifier et clarifier en supprimant l'héritage et en définissant les permissions disponibles pour chaque module.
- Possibilité de filtrer les données dans la Synthèse selon leur sensibilité, mais sans floutage pour le moment (à venir), en affichant ou non les données sensibles selon les permissions de l'utilisateur.
- Vérifiez que vos modules soient compatibles avec le nouveau mécanisme de déclaration des permissions disponibles. C'est le cas pour les modules Import, Export, Dashboard, Monitorings et Zones humides.
- Cette nouvelle version est compatible avec Debian 12. Le support de Debian 10 sera arrêté prochainement.

**🚀 Nouveautés**

- Refonte complète des permissions (#2487)
  - Suppression de l'héritage des permissions du module "GeoNature" vers les autres modules, et de l'objet "All" vers les éventuels autres objets des modules. Chaque permission dans un module doit désormais être définie explicitement. Cela entraine de devoir définir plus de permissions (à l'installation d'un nouveau module notamment) mais aussi de les rendre plus lisibles, additives et explicites (#2474)
  - Evolution du modèle de données des permissions pour élargir les possibilités de filtrage des permissions au-delà de l'appartenance (anciennement nommée portée ou scope) (#2472)
  - Suppression des permissions ayant une appartenance de niveau 0 (Aucune donnée). En effet, en supprimant l'héritage des permissions et en les définissant par module de manière explicite, si un groupe ou utilisateur n'a aucune permission sur un module, alors il n'y accède pas et ne le voit pas dans le menu latéral. Si il a n'importe quelle permission sur un module, alors il y accède.
  - Suppression du filtre d'appartenance de niveau 3 (Toutes les données). En effet, celui-ci est désormais redondant avec l'ajout d'une permission sans filtre.
  - Définition des permissions disponibles dans chaque module dans la nouvelle table `gn_permissions.t_permissions_available`, pour ne proposer que des permissions qui ont un usage quand on ajoute ou modifie les permissions d'un utilisateur (#2489)
  - Refonte de l'interface d'administration des permissions (Flask-admin) ne proposant que les permissions disponibles, affichant les permissions explicites d'un utilisateur et calculant celles effectives provenant d'un groupe auquel il appartient (#2605)
  - Optimisation et agrégation des permissions
  - [Synthèse] Ajout d'un filtre sur la sensibilité des données, permettant de les afficher et de les exporter ou non à un groupe ou utilisateurs (pas de floutage pour le moment) (#2504 / #2584)
  - Ajout de la commande `geonature permissions supergrant` permettant d'ajouter toutes les permissions disponibles à un utilisateur ou groupe super-administrateur (#2557)
  - Ajout de la vérification des permissions manquantes sur différentes routes (#2542 / #1863)
- Ajout de notifications quand un commentaire est ajouté sur une observation (#2460)
- Amélioration des performances de la recherche de taxons dans Occtax et dans la Synthèse (#2592 / https://github.com/PnX-SI/TaxHub/issues/384)
- Support de Debian 12 (avec Python 3.11, PostgreSQL 15 et PostGIS 3.3) (#1787)
- [Admin] Fixer la barre de navigation du menu latéral et possibilité de la rabbatre (#2556)
- [Synthèse] Ajout d'un filtre par source (#2513)
- [Synthèse] Ajout d'un filtre par `id_synthese` (#2516)
- [Synthèse] Recherche des observateurs multiples et insensible aux accents (#2568)
- [Occtax] Ajout du paramètre `EXPANDED_TAXON_ADVANCED_DETAILS` permettant d'ouvrir par défaut les champs avancés du formulaire de renseignement du taxon (#2446)
- Conservation du fond de carte utilisé quand on navigue dans les modules (#2619)
- Suppression des médias orphelins basculée dans une tache Celery Beat lancée automatiquement toutes les nuits (`clean_attachments`), et non plus à l'ajout ou suppression d'un autre média (#2436)
- Ajout d'une documentation utilisateur sur le module Métadonnées - https://docs.geonature.fr/user-manual.html#metadonnees (#2662)

**🐛 Corrections**

- [Occtax] Correction du déplacement du marqueur de localisation poncutelle d'un relevé (#2554 et #2552)
- [Occtax] Correction du centrage sur la carte quand on modifie un relevé
- [Occtax] Correction de l'affichage de la géométrie du précédent relevé quand on enchaine des relevés de type polygone puis point (#2657)
- Correction de la sélection automatique des valeurs par défaut numériques dans les champs de type "Liste déroulante (Select)" des formulaires dynamiques (#2540)
- Correction de la gestion des entiers pour les champs additionnels de type "checkbox" (#2518)
- Correction de l'envoi à plusieurs destinataires des emails de demande de création de compte (#2389)
- Récupération du contenu du champs "Organisme" dans le formulaire de demande de création de compte (#1760)
- Amélioration des messages lors de la demande de création de compte (#2575)
- Correction du graphique dans l'export PDF des cadres d'acquisition (#2618)
- [Synthèse] Correction de l'affichage des géométries de type multipoint (#2536)
- [Synthèse] Correction des filtres par défaut (#2634)
- [Synthèse] Correction des filtres géographiques multiples (#2639)
- [Métadonnées] Correction de l'affichage du formulaire de filtres avancés (#2649)

**💻 Développement**

- Découpage du script `install/03_create_db.sh` en 2 (avec la création du fichier `install/03b_populate_db.sh`) notamment pour améliorer la dockerisation de GeoNature (#2544)
- Ajout d'un script `install/03b_populate_db_for_test.sh` pouvant être utilisé par la CI de test des modules GeoNature (#2544)
- Ajout d'un script `install/assets/docker_startup.sh` pour lancer les migrations Alembic depuis le docker de GeoNature (#2544)
- Création d'un fichier `install/assets/db/add_pg_extensions.sql` regroupant la création des extensions PostgreSQL (#2544)
- Amélioration de `APPLICATION_ROOT` pour qu'il fonctionne en mode développement (#2546)
- Amélioration des modèles de la Synthèse pour prendre en compte les valeurs par défaut des nomenclatures (#2524)
- Meilleure portabilité des scripts dans les différents systèmes Unix (#2435)
- Mise à jour des dépendances Python (#2596)
- Documentation de développement des permissions (#2585)

**⚠️ Notes de version**

Si vous mettez à jour GeoNature :

- Mettre à jour TaxHub en version 1.12.0 (ou plus) et optionnellement UsersHub
- Si vous les utilisez, mettez à jour les modules Import, Export, Monitoring et Dashboard dans leurs versions compatibles avec GeoNature 2.13, avec la nouvelle procédure consistant uniquement à télécharger, dézipper et renommer les dossiers des modules et de leur configuration
- Si vous utilisez d'autres modules externes, vérifiez qu'ils disposent d'une version compatible avec GeoNature 2.13, ou faites-les évoluer pour qu'ils déclarent leurs permissions disponibles (exemple : #2543)
- Suivez la procédure de mise à jour classique de GeoNature (<https://docs.geonature.fr/installation.html#mise-a-jour-de-l-application>)
- Les permissions existantes sur vos différents groupes et utilisateurs sont récupérées et remises à plat automatiquement sans système d'héritage. Vérifiez cependant les permissions après la mise à jour de vos groupes et utilisateurs.
- Désormais, quand vous installerez un nouveau module (ou sous-module), pour le voir affiché dans le menu et y avoir accès, il faudra lui appliquer des permissions aux groupes ou utilisateurs qui doivent y accéder.

✅ Exemple de procédure de mise à jour depuis une version 2.12 : https://geonature.fr/documents/procedures/2023-10-GN-212to213.txt

**📝 Merci aux contributeurs**

@bouttier / @TheoLechemia / @VincentCauchois / @Pierre-Narcisi / @joelclems / @andriacap / @mvergez / @JulienCorny / @MathRdt / @DonovanMaillard / @camillemonchicourt

## 2.12.3 (2023-05-09)

**🐛 Corrections**

- [Synthèse] Correction du filtre des observations épinglées pour ne remonter que celles de l'utilisateur connecté (#2507 par @mvergez)
- [Synthèse] Correction de la recherche géographique avec chargement d'un fichier local (#2522 par @bouttier et @mvergez)
- [Admin] Correction d'une régression des performances d'édition des permissions (#2523 par @bouttier)
- Compléments de la documentation (page maintenance, migration avec git, configuratrion dynamique, #2526, #2501, #2503 par @camillemonchicourt)
- [Métadonnées] Correction des droits de modification des cadres d'acquisition
- Correction du script `migration.sh` (#2525 par @bouttier)
- Correction du downgrade d'une migration Alembic d'Occtax (#2500 par @JulienCorny)
- Correction et ation de la page de maintenance (#2535)
- Correction de la synchronisation des JDD et de l’association aux modules (#2532 par @VincentCauchois)

**💻 Développement**

- La fonction `geonature.core.gn_permissions.tools.cruved_scope_for_user_in_module` est remplacée par `geonature.core.gn_permissions.tools.get_scopes_by_action`

**⚠️ Notes de version**

Si vous utilisez la page de maintenance, celle-ci a été revue, [référez vous à la documentation](https://docs.geonature.fr/installation.html#configuration-apache) afin de la mettre à jour.

Si vous utilisiez des champs additionnels avec des checkbox, lors de leur changement de type (recommandé dans les notes de version de la 2.12.0) il est important que les valeurs du champ `field_values` continue à avoir des "string" dans la clé values : [{"label": "Un", "value": "1"}] sans quoi il y aura des problème à l'édition. Pour les nouveaux champs additionnels, il est cependant bien possible de mettre des entiers dans la clé `value` [{"label": "Un", "value": 1}]

## 2.12.2 (2023-04-18)

**🚀 Nouveautés**

- Synthèse : ajout d’un filtre sur les observations avec ou sans commentaire (#2469, par @mvergez)

**🐛 Corrections**

- Synthèse - mode maille : récupération des observations hors référentiel de mailles pour affichage dans la liste, garantissant ainsi un nombre d’observations indentique entre le mode point et le mode maille (#2495, par @TheoLechemia)
- Synthèse : correction des filtres médias / épinglage / signalement / commentaires pour fonctionner également de manière négative (#2469)
- Backoffice des permissions :
  - Correction du module lors du contrôle d’accès (#2483, par @VincentCauchois)
  - Correction de la gestion du CRUVED des rôles sans permissions (#2496)
- Commande `install-gn-module` :
  - Correction de la détection du module_code (#2482)
  - Reload de la config après l’exécution de `pip install` (#2493)
- Occhab : tri des stations par date (#2477)
- Validation : correction des filtres avancés (#2470, par @joelclems)
- Admin : contrôle du R pour l’accès en lecture (#2491)
- Admin : rajout de l’objet NOTIFICATIONS afin de pouvoir en définir ses permissions (#2490)
- Login : désactivation du spinner après une tentative de login échouée

## 2.12.1 (2023-04-11)

**🚀 Nouveautés**

- Mise à jour de quelques dépendances python (#2438, par @MathRdt)
- Mise à jour de Utils-Flask-SQLAlchemy en version 0.3.3

**🐛 Corrections**

- Correction et ations des performances des recherches par statut de protection, notamment quand elles sont associées à une recherche géographique (#2450, par @amandine-sahl)
- Correction d’une régression des performances lors de la récupération des JDD (#2462, par @mvergez)
- Correction de jointures manquantes pour le calcul des permissions lors de la récupération des JDD (#2463, par @mvergez)
- Correction des champs additionnels de type liste (#2447, par @TheoLechemia)
- Correction d’une incompatibilité Python 3.7 (#2464, par @TheoLechemia)
- Suppression en cascade des permissions et associations aux sites lors de la suppresion d’un module (#2466, par @jbrieuclp & @VincentCauchois)
- Mise à jour des habitats dans la Synthèse quand ils sont modifiés dans un relevé Occtax (#2468, par @JulienCorny)

## 2.12.0 - Cyathea borbonica 🌴 (2023-03-27)

**⏩ En bref**

- Affichage agrégé des observations dans la Synthèse (performances et lisibilité) (#1847 et #1878)
- Filtres par défaut dans la Synthèse (#2261)
- Optimisation des performances des exports de la Synthèse (#1434)
- Optimisation du chargement des jeux de données dans le module Métadonnées pour en er les performances (#2004)
- Intégration par défaut de Taxref v16, BDC statuts v16 et référentiel de sensibilité v16
- Possibilité de gérer les tables des applications mobiles et des modules depuis le module "Admin"
- Configuration dynamique sans rebuild (#2205)
- Centralisation de la configuration des modules dans GeoNature (#2423)
- Historisation des suppressions dans la Synthèse, nécessaire pour GN2PG notamment (#789)
- Réorganisation des dossiers pour simplifier la customisation et les mises à jour (#2306)
- Stabilisation de la dockerisation (#2206)
- Refactorisation d'Occhab, module de référence et documentation développeurs associée
- Refactorisation des permissions (simplification, optimisation, centralisation, performances, tests)
- Mise à jour d'Angular en version 15 (#2154)

**⚠️ Notes de version**

Si vous mettez à jour GeoNature :

- Si vous utilisez des modules spécifiques (hors Import, Export, Dashboard, Monitoring), vérifiez qu'ils disposent d'une version compatible avec GeoNature 2.12 (compatibilité Angular 15, révision des permissions, configuration dynamique)
- Si vous les utilisez, mettre à jour les modules Import en version 2.1.0 (ou plus), Export en version 1.4.0, Dashboard en version 1.3.0 (ou plus) et Monitoring en version 0.5.0 (ou plus) avec la nouvelle procédure consistant uniquement à télécharger, dézipper et renommer les dossiers des modules et de leur configuration
- Mettez à jour TaxHub en version 1.11 (ou plus)
- La vue `gn_synthese.v_synthese_for_export` définissant la structure et le contenu des exports de la Synthèse a été modifiée pour être optimisée. Si vous l'aviez customisée, reportée vos modifications manuellement après la mise à jour de GeoNature
- Suivez la procédure de mise à jour classique de GeoNature (<https://docs.geonature.fr/installation.html#mise-a-jour-de-l-application>)
- Le script `migration.sh` se charge de déplacer automatiquement les différents fichiers suite à la réorganisation des dossiers (customisation, médias, mobile, configuration centralisée des modules)
- Les médias (incluant les fichiers d'Occtax-mobile) sont déplacés dans le dossier `backend/media/`
- Il n'est plus nécessaire de rebuilder le frontend ni de recharger GeoNature manuellement à chaque modification de la configuration de GeoNature ou de ses modules
- Les taches automatisées sont désormais gérées par Celery Beat et installées avec GeoNature. Si vous aviez mis en place des crons pour mettre à jour les profils de taxons (ou les données du module Dashboard, ou les exports planifiés du module Export), supprimez les (dans `/etc/cron.d/geonature` ou `crontab -e`) car ils ne sont plus utiles
- Il est fortement conseillé d'utiliser la configuration Apache générée par défaut dans `/etc/apache2/conf-available/geonature.conf` et de l'inclure dans votre vhost (`/etc/apache2/sites-available/geonature.conf` et/ou `/etc/apache2/sites-available/geonature-le-ssl.conf`), en suivant la [documentation dédiée](https://docs.geonature.fr/installation.html#configuration-apache)
- Si vous aviez customisé la page d’accueil de GeoNature en modifiant les composants `frontend/src/custom/components/introduction/introduction.component.html` et `frontend/src/custom/components/footer/footer.component.html` ceux-ci ont été supprimés au profit de paramètres de configuration. Il vous faut donc déplacer votre customisation dans les paramètres `TITLE`, `INTRODUCTION` et `FOOTER` de la nouvelle section `[HOME]` de la configuration de GeoNature.
  Vous pouvez renseigner du code HTML sur plusieurs lignes en le plaçant entre triple quote (`"""<b>Hello</b>"""`).
- Les paramètres de configuration suivants ont été supprimés et doivent être retirés de votre fichier de configuration (`config/geonature_config.toml`) s’ils sont présents :
  - `LOGO_STRUCTURE_FILE` (si vous aviez renommé votre logo, déplacez le dans `geonature/custom/images/logo_structure.png`)
  - `UPLOAD_FOLDER` (si vous l’aviez déplacé, renommez votre dossier d’upload en `attachments` et placez-le dans le dossier des médias (`geonature/backend/media/` par défaut, paramétrable via `MEDIA_FOLDER`))
  - `BASE_DIR`
- Occtax et champs additionnels :
  - Les champs additionnels de type `bool_radio` ne sont plus supportés.
    Si vous utilisiez ce type de widget dans vos champs additionnels d'Occtax, ils seront automatiquement remplacés par un widget de type `radio`.
    Vous devez changer le champs `field_values` sur le modèle suivant : `[{"label": "Mon label vrai", "value": true }, {"label": "Mon label faux", "value": false }]`.
  - Les champs de formulaire de type `radio`, `select`, `multiselect` et `checkbox`, attendent désormais une liste de dictionnaire `{value, label}` (voir doc des champs additionnels) (#2214)  
    La rétrocompatibilité avec des listes simples est maintenue, mais vous êtes invités à modifier ces champs dans le backoffice.  
    Pour conserver le bon affichage lors de l'édition des données, renseignez l'ancienne valeur deux fois dans la clé `value` et la clé `label`.

✅ Exemple de procédure de mise à jour depuis une version 2.11 : https://geonature.fr/documents/procedures/2023-04-GN-211to212.txt

**🚀 Nouveautés**

- Configuration dynamique du frontend : le frontend récupère dynamiquement sa configuration depuis le backend. Pour cela, il nécessite uniquement l’adresse de l’`API_ENDPOINT` qui doit être renseignée dans le fichier `frontend/src/assets/config.json`. En conséquence, il n’est plus nécessaire de rebuilder le frontend lors d’une modification de la configuration de GeoNature ou de ses modules (#2205)
- Personnalisation de la page d’accueil : ajout d’une section `[HOME]` contenant les paramètres `TITLE`, `INTRODUCTION` et `FOOTER`. Ceux-ci peuvent contenir du code HTML qui est chargé dynamiquement avec la configuration, évitant ainsi la nécessité d’un rebuild du frontend (#2300)
- Synthèse : Agrégation des observations ayant la même géométrie pour ne les charger qu'une seule fois, et ainsi améliorer les performances et la lisibilité (#1847)
- Synthèse : Possibilité d'afficher les données agrégées par maille (#1878). La fonctionnalité est configurable avec les paramètres suivants :
  ```toml
  [SYNTHESE]
      AREA_AGGREGATION_ENABLED = true
      AREA_AGGREGATION_TYPE = "M10"
      AREA_AGGREGATION_BY_DEFAULT = false    # affichage groupé par défaut
      AREA_AGGREGATION_LEGEND_CLASSES = .   # voir fichier de configuration d’exemple
  ```
- Synthèse : Possibilité de définir des filtres par défaut avec le paramètre `SYNTHESE.DEFAULT_FILTERS` (#2261)
- Métadonnées : Chargement des jeux de données seulement quand on clique sur un cadre d'acquisition dans la liste des métadonnées, pour améliorer les performances du module, en ne chargeant pas tous les jeux de données par défaut (#2004)
- Champs additionnels : Les champs de formulaire de type `radio`, `select`, `multiselect` et `checkbox`, attendent désormais une liste de dictionnaire `{value, label}` (voir doc des champs additionnels) (#2214)
- Admin : Possibilité de gérer la table des applications mobiles (`t_mobile_apps`) dans le module "Admin" de GeoNature, notamment pour faciliter la gestion des mises à jour de Occtax-mobile (#2352)
- Possibilité de configurer les modules (picto, doc, label) directement depuis le module Admin (#2409)
- Possibilité d’afficher un bouton de géolocalisation sur les cartes des formulaires Occtax et Occhab (#2338), activable avec le paramètre suivant :
  ```toml
  [MAPCONFIG]
      GEOLOCATION = true
  ```
- Profils mis à jour automatiquement par Celery Beat, toutes les nuits par défaut (#2412)
- Ajout de l’intégration de Redis à l'outil de logs Sentry, pour améliorer la précisions des traces
- Possibilité de définir des règles de notifications par défaut, s’appliquant aux utilisateurs n’ayant pas de règle spécifique. Pour cela, il suffit d’insérer une règle dans la table `gn_notifications.t_notifications_rules` avec `id_role=NULL` (#2267)
- Publication automatique de deux images Docker `geonature-backend` et `geonature-frontend` (#2206). Leur utilisation n’a pas encore été éprouvée et leur utilisation en production n’est de ce fait pas recommandée.
- Amélioration de la fiabilité du processus de migration
- Ajout d’un index sur la colonne `gn_synthese.cor_area_synthese.id_area`. La colonne `id_synthese` est déjà couverte par l’index multiple `(id_synthese, id_area)`.
- Intégration de TaxRef v16 et du référentiel de sensibilité associé pour les nouvelles installations de GeoNature
- Évolution de la gestion des fichiers statiques et des médias (#2306) :
  - Séparation des fichiers statiques (applicatif, fournis par GeoNature) et des fichiers médias (générés par l’applications). Sont déplacés du dossier `backend/static` vers le dossier `backend/media` les sous-dossiers suivants : `medias`, `exports`, `geopackages`, `mobile`, `pdf`, `shapefiles`. De plus, l’ancien dossier `medias` est renommé `attachments`.
  - Ajout des paramètres de configuration suivants :
    ```toml
    ROOT_PATH = "dossier absolu du backend"
    STATIC_FOLDER = "static"    # dossier absolu ou relatif à ROOT_PATH
    STATIC_URL = "/static"      # URL d’accès aux fichiers statiques
    MEDIA_FOLDER = "media"      # dossier absolu ou relatif à ROOT_PATH
    MEDIA_URL = "/media"        # URL d’accès aux médias
    ```
  - Ajout d’un dossier `custom` à la racine de GeoNature et du paramètre associé `CUSTOM_STATIC_FOLDER`. Les fichiers statiques réclamés sont cherchés en priorité dans le dossier `custom`, puis, si non trouvés, dans le dossier `backend/static`. Ainsi, si besoin de modifier un fichier statique, on placera un fichier du même nom dans le dossier `custom` plutôt que de modifier le fichier original (par exemple, `custom/images/logo_structure.png`). Voir la [documentation sur la customisation](https://docs.geonature.fr/admin-manual.html#customisation).
  - Retrait du préfixe `static/media/` aux chemins d’accès des fichiers joints (colonne `gn_commons.t_medias.media_path`)
  - Retrait du préfixe `static/mobile/` aux chemins d’accès des APK des applications mobiles (colonne `gn_commons.t_mobile_apps.relative_path_apk`)
  - Certains fichiers statiques sont renommés :
    - `static/css/custom.css` → `static/css/metadata_pdf_custom.css`
  - Certains assets du frontend sont déplacés vers les fichiers statiques du backend pour profiter du mécanisme de customisation :
    - `frontend/src/assets/custom.css` → `backend/static/css/frontend.css`
    - `frontend/src/favicon.ico` → `backend/static/images/favicon.ico`
    - `frontend/src/custom/images/login_background.jpg` → `backend/static/images/login_background.jpg`
    - `frontend/src/custom/images/logo_sidebar.jpg` → `backend/static/images/logo_sidebar.jpg`
    - `frontend/src/custom/images/logo_structure.png` → `backend/static/images/logo_structure.png`
  - Le lien symbolique `static/images/logo_structure.jpg` est supprimé au profit de l’utilisation de `logo_sidebar.jpg`
  - Les déplacements mentionnés ci-dessus sont effectués par le script `migration.sh`
- Mise à jour des dépendances :
  - TaxHub 1.11.1
  - UsersHub 2.3.3
  - UsersHub-authentification-module 1.6.5
  - Habref-api-module 0.3.2
  - Nomenclature-api-module 1.5.4
  - RefGeo 1.3.0
  - Utils-Flask-SQLAlchemy 0.3.2
  - Utils-Flask-SQLAlchemy-Geo 0.2.7
- Refonte des permissions et suppression de la vue `v_roles_permissions` qui posait des problèmes de performances du nombre d’utilisateurs (#2196 et #2360)
- La recherche du fichier de configuration des modules sous le nom `{module_code}_config.toml` (code du module en minuscule) dans le répertoire de configuration de GeoNature devient prioritaire devant l’utilisation du fichier `conf_gn_module.toml` dans le répertoire de configuration du module.
  Le script de mise à jour déplace les fichiers de configuration des modules vers le dossier centralisé de configuration de GeoNature (#2423)
- Rechargement automatique de GeoNature quand on modifie un fichier de configuration d'un module dans l" dossier centralisé (#2418)
- Évolution de la configuration Apache `/etc/apache2/conf-available/geonature.conf` pour activer la compression gzip des réponses de l’API (#2266) et pour servir les médias et les fichiers statiques par Apache (#2430).
  À reporter dans votre configuration Apache si celle-ci n’importe pas cette configuration fournie par défaut.
- Le script de mise à jour (`migration.sh`) peut prendre en argument le chemin vers l’ancienne installation GeoNature.
  Il peut s’agir du même dossier que la nouvelle installation GeoNature (cas d’une mise à jour d’un dossier GeoNature avec Git).
- Ajout d’une historisation des suppressions de la synthèse à travers un trigger peuplant la nouvelle table `gn_synthese.t_log_synthese` (#789)
  Une API `/synthese/log` permet d’obtenir l’historique des insertions, mises à jour et suppressions dans la synthèse (notamment utile pour GN2PG).
- Amélioration de la commande `install-gn-module` qui détecte désormais automatiquement le code du module (#2396)
- Synthèse : Optimisation de la requête par statuts de protection (#2329)
- Occtax : Optimisation des triggers de calcul automatique des altitudes pour ne les lancer que quand la géométrie du relevé est modifiée (#2137)
- Occtax et Occhab : Ajout d'une pastille indiquant le nombre de filtres activés
- Amélioration du message renvoyé à l'utilisateur en cas de Timout (#2417)
- Amélioration du composant générique de selection d'un jeu de données, en selectionnant automatiquement le JDD si la liste n'en contient qu'un et que le champs est obligatoire (#1049)

**🐛 Corrections**

- Synthèse : changement du type de `entity_source_pk_value` de `Integer` à `Unicode` dans le modèle pour correspondre à la base de données
- Correction de l’accès public automatique activable avec `?access=public` dans l’URL (#1650)
- Correction de la fonctionnalité de récupération du mot de passe
- Correction de la commande d’import du référentiel sensibilité pour correctement gérer les critères comportementales
- Occtax : correction du filtre sur les organismes
- Synthèse : correction d’un problème de performance de l’export (vue `v_synthese_for_export`) (#1434)
- Correction d’un problème de détection de l’emplacement des modules avec les versions récentes de `pip` (#2365, #2364)
- Occhab : correction du CRUVED sur la liste des jeux de données ouvert à la saisie
- Occtax : correction du contrôle des dates du formulaire d’édition des relevés (#2318)
- Correction des acteurs dans les exports PDF des métadonnées (#2034)
- Correction des graphiques dans les exports PDF des cadres d'acquisition (#2231)
- Correction du script de synchronisation des métadonnées depuis MTD INPN (#2314)
- Correction de l'appel en double de la route des notifications (#2356)
- Correction de l'URL vers la documentation depuis la page d'accueil
- Correction du formulaire Occtax quand un relevé n'a pas d'`id_digitiser` (#2421)
- Correction de l'affichage des tooltips sur la liste des obsrvations de la Synthèse (#2348)
- Correction du chargement des dates début et date fin quand on modifie un relevé dans Occtax ou une station dans OCchab (#2071)
- Correction de la récupération des emails dans l'interface "Mon compte" (#2346)

**💻 Développement**

- Suppression du support du paramètre `get_role` du décorateur `check_cruved_scope` (#2162)
- Suppression des paramètres `redirect_on_expiration` et `redirect_on_invalid_token` du décorateur `check_cruved_scope` (#2360)
- Remplacement des usages du paramètre `get_role` du décorateur `check_cruved_scope` par `get_scope` dans le code de GeoNature et des modules _contrib_ (#2164, #2199)
- Suppression de multiples fonctions du package `geonature.core.gn_permissions.tools`, notamment la classe `UserCruved` ; se reporter à la documentation développeur afin de connaître les fonctions utilisables dans votre code (#2360)
- Migration GeoNature : le venv est mis à jour plutôt que d’être supprimé et recréé (#2332)
- Les erreurs de validation Marshmallow sont automatiquement converties en erreur 400 (BadRequest)
- Les modules _contrib_ doivent également être formatés avec `prettier`
- Fiabilisation des exports PDF (#2232)
- Le composant de carte `pnx-map` a un nouvel input `geolocation` permettant d’activer le bouton de géolocalisation
- Ajout du mixin `geonature.utils.schema.CruvedSchemaMixin` permettant d’ajouter la propriété (exclue par défaut) `cruved` à un schéma Marshmallow
- L’accès aux paramètre de configuration ne se fait plus à partir des fichiers générés `AppConfig` (GeoNature) ou `ModuleConfig` (modules), mais uniquement à partir du `ConfigService` en charge de la récupération dynamique de la configuration (#2205).
- Mise à jour d'Angular version 12 à 15 et mise à jour de nombreuses dépendances frontend (#2154)
- Nettoyage des dépendances frontend de GeoNature. Si vous utilisiez certaines dépendances supprimées de GeoNature dans vos modules, vous devez les rajouter dans un fichier `package-lock.json` dans le dossier frontend de votre module.
- Suppression de la route obsolète `/config`
- Ajout du context manager `start_sentry_child` permettant de rapporter dans les traces Sentry le temps d’exécution de certaines tâches coûteuses (#2289)
- Refactorisation du module Occhab (#2324) avec passage à Marshmallow.
  Ajout à cette occasion de plusieurs fonctions et classes utilitaires au dépôt _Utils-Flask-SQLAlchemy-Geo_.
  Suppression de la vue `v_releve_occtax`.
  Module de référence pour les développements et documentation associée (#2331)
- Déplacement des routes géographiques et des tests associés vers le dépôt _RefGeo_ (#2342)
- Amélioration des tests des permissions
- La fonction `get_scopes_by_module` cherche dans le contexte applicatif (variable `g`) la présence de `g.current_module` et `g.current_object` lorsqu’ils ne sont pas fournis en paramètre.
- Travaux en cours : compatibilité SQLAlchemy 1.3 & 1.4 / Flask-SQLAlchemy 2 & 3 (#1812)
- Mise à jour de Chart.js de la version 2 à 4
- Possibilité de définir l'URL par défaut de la documentation d'un module par un entrypoint nommé `doc_url`

**📝 Merci aux contributeurs**

@ch-cbna / @bouttier / @TheoLechemia / @jpm-cbna / @bastyen / @Gaetanbrl / @VincentCauchois / @joelclems / @amandine-sahl / @andriacap / @mvergez / @DonovanMaillard / @dece / @lpofredc / @MathRdt / @gildeluermoz / @maximetoma / @pierre56 / @cecchi-a / @jbrieuclp / @camillemonchicourt

## 2.11.2 (2023-01-19)

**🐛 Corrections**

- Correction d'un import manquant dans un fichier de migration des données d'exemple d'Occtax (#2285)
- Correction d'un problème de l'installation globale en mode développement

## 2.11.1 (2023-01-18)

**🐛 Corrections**

- Correction de la documentation de la sensibilité (#2234)
- Correction de l’accès aux notifications lorsque la gestion des comptes utilisateurs est activée
- Correction des migrations Alembic des données d’exemple Occtax afin de supporter les migrations depuis GeoNature ≤ 2.9 (#2240, #2248)
- Correction de la commande `upgrade-modules-db` afin de supporter les anciens modules dont le passage à Alembic nécessite un stamp manuel

## 2.11.0 - Ilex aquifolium 🎄 (2022-12-21)

**⏩ En bref**

- Utilisation de la BDC statuts dans la Synthèse pour les filtres et infos sur les statuts des espèces
- Mise à jour des règles de sensibilité du SINP
- Notifications (changement de statut de validation de mes observations)
- Filtre des métadonnées par zonage géographique
- Affichage de zonages sur les cartes (depuis le ref_geo, un WMS, un WFS ou un GeoJSON)
- Suppression du support des modules non packagés
- Simplification et amélioration des commandes d'installation et de mise à jour des modules
- Amélioration du script `migration.sh` de mise à jour de GeoNature
- Nettoyage du frontend et amélioration de la séparation backend/frontend

**⚠️ Notes de version**

Si vous mettez à jour GeoNature :

- Mettre à jour TaxHub en version 1.10.7
- Si vous utilisez des modules spécifiques (hors Import, Export, Dashboard, Monitoring), vérifiez qu'ils disposent d'une version packagée compatible avec GeoNature 2.11 (#2058)
- Si vous aviez mis en place l'accès public à GeoNature, adaptez sa configuration avec le nouveau paramètre unique `PUBLIC_ACCESS_USERNAME` (#2202)
- Suivez la procédure de mise à jour classique de GeoNature (<https://docs.geonature.fr/installation.html#mise-a-jour-de-l-application>)
- Attention, le script de migration de la version 2.11 a une régression et ne récupère plus automatiquement la configuration des modules fournis avec GeoNature (Occtax, Occhab, Validation). Rapatriez manuellement vos éventuels fichiers de configuration de ces modules si vous en avez créé :
  ```bash
  cp geonature_old/contrib/occtax/config/conf_gn_module.toml geonature/contrib/occtax/config/conf_gn_module.toml
  cp geonature_old/contrib/gn_module_validation/config/conf_gn_module.toml geonature/contrib/gn_module_validation/config/conf_gn_module.toml
  cp geonature_old/contrib/gn_module_occhab/config/conf_gn_module.toml geonature/contrib/gn_module_occhab/config/conf_gn_module.toml
  ```
- Si vous les utilisez, mettre à jour les modules Dashboard en version 1.2.1 (ou plus) et Monitoring en version 0.4.0 (ou plus), **après** la mise à jour de GeoNature
- Vous pouvez désactiver les textes de la BDC statuts ne correspondant par à votre territoire.
  Voir rubrique "5. Configurer les filtres des statuts de protection et des listes rouges" de https://docs.geonature.fr/admin-manual.html#module-synthese
- Vous pouvez mettre à jour vos règles de sensibilité si vous utilisez TaxRef versions 14 ou 15 :

  - Désinstallez les règles fournies par Alembic :
    ```bash
    source ~/geonature/backend/venv/bin/activate
    geonature db downgrade ref_sensitivity_inpn@base
    ```
  - Vous n’avez probablement plus besoin des anciennes régions que vous pouvez alors supprimer de votre référentiel géographique :
    ```bash
    geonature db downgrade ref_geo_fr_regions_1970@base
    ```
  - Assurez-vous que votre référientiel géographique contienne les départements :
    ```bash
    geonature db upgrade ref_geo_fr_departments@head
    ```
  - Si vous avez TaxRef v15, insérez les nouvelles règles ainsi :
    ```bash
    geonature sensitivity add-referential \
        --source-name "Référentiel sensibilité TAXREF v15 20220331" \
        --url https://inpn.mnhn.fr/docs-web/docs/download/401875 \
        --zipfile RefSensibiliteV15_20220331.zip \
        --csvfile RefSensibilite_V15_31032022/RefSensibilite_15.csv  \
        --encoding=iso-8859-15
    ```
  - Si vous avez TaxRef v14, insérez les nouvelles règles ainsi :
    ```bash
    geonature sensitivity add-referential \
        --source-name "Référentiel sensibilité TAXREF v14 20220331" \
        --url https://inpn.mnhn.fr/docs-web/docs/download/401876 \
        --zipfile RefSensibiliteV14_20220331.zip \
        --csvfile RefSensibilite_V14_31032022/RefSensibilite_14.csv  \
        --encoding=iso-8859-15
    ```
  - Rafraîchissez la vue matérialisée pré-calculant les taxons enfants :
    ```bash
    geonature sensitivity refresh-rules-cache
    ```
  - Relancez le calcul de la sensibilité des observations de la synthèse :
    ```bash
    geonature sensitivity update-synthese
    ```

✅ Exemple de procédure de mise à jour depuis une version 2.9 : https://geonature.fr/documents/procedures/2023-01-GN-29to211.txt

**🚀 Nouveautés**

- [Synthèse] Ajout de filtres sur les statuts de protection et les listes rouges dans le fenêtre de recherche avancée basés sur la [BDC Statuts](https://inpn.mnhn.fr/programme/base-de-connaissance-statuts/presentation).
  Ajout des paramètres de configuration `STATUS_FILTERS` et `RED_LISTS_FILTERS` dans la section `SYNTHESE`. Il est possible de modifier les listes et statuts affichés comme indiqué dans la documentation de la configuration du module SYNTHESE. (#1492)
- [Synthèse] Affichage dans la fiche d’une observation, onglet _Taxonomie_, des informations issues de la _BDC Statuts_ (statuts de protection, listes rouges) en rapport avec le taxon et l’emplacement géographique de l’observation sélectionnée (#1492)
- [Synthèse] L’export des statuts de protection est maintenant basé sur les données de la _BDC Statuts_ (#1492)
- Documentation dans la rubrique "5. Configurer les filtres des statuts de protection et des listes rouges" de https://docs.geonature.fr/admin-manual.html#module-synthese
- Possibilité d’afficher des zonages sur les cartes (#974).
  Ces derniers peuvent provenir :
  - d’un flux WMS ou WFS
  - d’un fichier ou flux GeoJSON
  - du référentiel géographique interne
    Les couches sont configurables via le paramètre `REF_LAYERS` de la section `MAPCONFIG`.
    Par défaut un WMS des limites administrativs de l'IGN et un WMS des ZNIEFF 1 continentales en métropole sont affichés.
- Ajout d’un mécanisme de notifications (#1873).
  L’utilisateur peut choisir de souscrire, pour chaque type de notificaton, s’il veut être notifié dans GeoNature et/ou par e-mail.
  Les templates de notifications peuvent être modifiés par l’administrateur dans le module Admin.
  Actuellement seule la notification du changement du statut de validation des observations est implémentée.
  Les fonctionnalités de notifications sont activées par défaut, mais peuvent être désactivées globalement en passant le paramètre de GeoNature `NOTIFICATIONS_ENABLED` à `false`.
- Recherche des métadonnées par emprise géographique des observations (#1768)
  Le paramètre `METADATA_AREA_FILTERS` permet de spécifier les types de zonages géographiques disponibles à la recherche (communes, départements et régions activés par défaut).
- Mise à jour des règles de sensibilité des observations (incluant les règles nationales et régionales mises à plat au niveau des départements) pour TaxRef version 14 et 15 (#1891)
- Intégration et mise à jour de la documentation sur les régles et le calcul de la sensibilité
- Ajout de sous-commandes pour la gestion du référentiel de sensibilité :
  - `geonature sensitivity info` : information sur les règles présentes dans la base de données
  - `geonature sensitivity remove-referential` : supprimer les règles d’une source donnée
  - `geonature sensitivity add-referential` : ajouter de nouvelles règles
    Les nouvelles installations de GeoNature reposent sur l’utilisation de ces commandes pour fournir les règles SINP de sensibilité du 31/03/2022.
    Ces dernières sont fournies à l’échelle du département et non plus des anciennes régions.
    La branche Alembic `ref_sensitivity_inpn` ne doit plus être utilisée et sera supprimée dans une prochaine version de GeoNature.
- Deux Dockerfiles permettant de générer une image frontend et une image backend ont été intégrés.
  La dockerisation de GeoNature reste toutefois un travail en cours, et l’utilisation de ces images n’est pas encore officiellement supportée (#2206)
- Les colonnes `id_source` de la synthèse et `id_module` des relevés Occtax sont désormais `NOT NULL` (#2186)
- Suppression de la section `[PUBLIC_ACCESS]` dans les paramètres de configuration, remplacée par un unique paramètre `PUBLIC_ACCESS_USERNAME` (#2202)
- Blocage de la possibilité de modifier son compte pour l'utilisateur public (#2218)
- Possibilité d'accéder directement à une page de GeoNature avec l'utilisateur public, sans passer par la page d'authentification (#1650)
- Support de la configuration par variable d'environnement préfixée par `GEONATURE_` (_e.g_ `GEONATURE_SQLALCHEMY_DATABASE_URI`). Les paramètres définis ainsi peuvent être exclus de la configuration TOML, y compris les paramètres obligatoires
- Activation de [Celery Beat](https://docs.celeryq.dev/en/stable/userguide/periodic-tasks.html) permettant de lancer des tâches périodiquement
- Mise à jour des dépendances :
  - TaxHub 1.10.7
  - UsersHub
  - UsersHub-authentification-module 1.6.2
  - Utils-Flask-SQLAlchemy 0.3.1
  - Utils-Flask-SQLAlchemy-Geo 0.2.6
- Modules GeoNature et séparation backend/frontend (#2088) :
  - Suppression du support des modules non packagés (#2058).
  - La commande `install-packaged-gn-module` devient `install-gn-module`.
  - Suppression des paramètres `ID_MODULE`, `FRONTEND_PATH` et `MODULE_URL` de la configuration frontend des modules, (#2165).
  - Recherche de la configuration des modules également dans le dossier `config` de GeoNature, sous le nom `{module_code}_config.toml` (le code du module étant en minuscule).
  - La commande `update-module-configuration` est renommée `generate-frontend-module-config` par homogénéité avec la commande `generate-frontend-config`.
  - La commande `update-configuration` génère la configuration frontend de tous les modules actifs en plus de la configuration GeoNature (puis lance le build du frontend).
  - Les liens symboliques dans le dossier `external_modules` sont supprimés au profit de liens symboliques dans le dossier `frontend/external_modules` pointant directement vers le dossier `frontend` des modules considérés. Ces liens sont créés par la commande `install-gn-module`. Le processus de migration convertit automatiquement vos liens symboliques existants.
  - Ajout de la commande `upgrade-modules-db` permettant d'insérer le module dans la table `t_modules` et de monter sa branche Alembic afin de créer ou mettre à jour son schéma de base de données.
    Il n'est pas nécessaire de lancer cette commande manuellement pour les modules installés avec la commande `install-gn-module` sauf lorsque cette dernière est appelée avec le paramètre `--upgrade-db=false`.
  - Les assets frontend ne sont plus collectés dans un dossier portant le nom du module. Le mainteneur du module doit donc créer cette arborescence lui-même.

**🐛 Corrections**

- Installation d'une dépendance Debian manquante pour Cypress (#2125)
- Les fichiers de service systemd ont été corrigés pour fonctionner sur une machine sans PostgreSQL (BDD sur un autre hôte)
- La _BDC Statuts_ est maintenance chargée lors de l’intégration continue juste après le chargement des départements (#1492)
- Ajout de l’`id_module` aux relevés des données d’exemple Occtax
- Correction du chargement du module Validation (#2183)
- Correction du script de migration pour gérer la migration de l’ensemble des modules externes
- Correction de la gestion du protocole (http / https) lors des redirections automatique de Flask (redirection en cas de slash manquant en fin d’URL)
- Rafraîchissement du cache des règles de sensibilité en fin d’installation

**💻 Développement**

- Nettoyage du frontend : dépendances, configuration Angular
- Révision importante de la documentation, de développement notamment
- Les fichiers `tsconfig.json` et `tsconfig.app.json` n'ont plus besoin d'être générés (#2088)
- Suppression des paramètres `ID_MODULE`, `FRONTEND_PATH` et `MODULE_URL` de la configuration frontend des modules à répercuter dans les modules (#2165)
- Homogénéisation de la configuration entre `current_app.config` et `geonature.utils.config.config`
- Compilation en production sans AOT (#1855)
- L'installation du backend, du frontend et des modules peut désormais être faite sans disposer de la BDD (#1359)
- Ajout de UsersHub aux dépendances (développement uniquement)
- Correction du chemin du marqueur Leaflet (#2223)

**📝 Merci aux contributeurs**

@jpm-cbna / @pierrejego / @Gaetanbrl / @amandine-sahl / @VincentCauchois / @antoinececchimnhn / @metourneau / @bouttier / @TheoLechemia / @camillemonchicourt

## 2.10.4 (2022-11-30)

**🐛 Corrections**

- Mise à jour du RefGeo en version 1.2.1 afin de corriger une
  régression des performances dans la synthèse
- Correction de la génération du rapport de sensibilité dans les
  fiches des métadonnées
- Correction d'un filtre de permissions sur les jeux de données
  (#2160)
- Correction des boutons d'ajout de données dans les jeux de données
  (#2152)
- Ajout d'une dépendance à GeoNature dans les migrations Occtax pour
  corriger un problème aléatoire lors du passage des migrations
  (#2178)

## 2.10.3 (2022-11-15)

**🚀 Nouveautés**

- Optimisation d'une migration Occtax particulièrement lente en
  désactivant temporairement les triggers (#2138)

**🐛 Corrections**

- Correction de la fonctionnalité d'inscription des utilisateurs
  (#1874)
- Correction d'une régression des performances de la routes `/modules`
  (#2136)

## 2.10.2 (2022-11-09)

**🚀 Nouveautés**

- Documentation de la fonctionnalité de duplication d'Occtax

**🐛 Corrections**

- Correction du script de migration pour générer la configuration
  frontend des modules
- Correction des triggers d'Occtax pour correctement identifier la
  bonne source

## 2.10.1 (2022-11-08)

**🚀 Nouveautés**

- Ajout du paramètre de configuration `DISABLED_MODULES`
- Installation des dépendances frontend des modules dans le dossier
  frontend des modules eux-mêmes

**🐛 Corrections**

- La commande `geonature` ignore les modules dont le chargement a
  rencontré une erreur (#2109)
- Correction et amélioration du script de mise à jour de GeoNature
  (`install/migration/migration.sh`) (#2110)
- Correction de la commande d’installation des modules non packagés
  avec le routing dynamique (#2107)
- Correction du message de confirmation d’enregistrement d’un cadre
  d’acquisition (#2108)
- Correction d'une régression de la 2.10.0 sur la route de
  récupération des jeux de données impactant Occtax-mobile

**⚠️ Notes de version**

- Passez directement à cette version plutôt que la 2.10.0, mais en
  suivant les notes de version de la 2.10.0, en vous aidant
  éventuellement de l’exemple de migration.

## 2.10.0 - Alouatta macconnelli 🐒 (2022-11-02)

- **Angular 12, tests automatisés frontend et backend**
- **Discussions, signalement, partage, épinglage d’une occurrence**

🔧 Passage de la version 7 à 12 d’Angular. Avant de mettre à jour
GeoNature sur cette version, vérifiez que les modules que vous utilisez
sont disponibles dans une version compatible avec GeoNature 2.10.0 ou
plus (compatibilité Angular 12).

Modules compatibles à date de la publication de la version 2.10 de
GeoNature :

- Import
- Export
- Dashboard
- Monitoring

**⚠️ Notes de version**

- **Avant** de mettre à jour GeoNature :

  - Mettre à jour les versions de TaxHub (1.10.4) et UsersHub
    (2.3.1), sans la partie migration de la base de données avec
    Alembic (elle sera faite lors de la mise à jour de GeoNature)

  - Mettre à jour les modules compatibles avec GeoNature 2.10, en
    vous limitant aux étapes "Téléchargement de la nouvelle version
    du module", "Renommage des répertoires" et "Rapatriement de
    la configuration". La compilation de chaque module sera faite
    automatiquement lors de la mise à jour de GeoNature

  - Les nouveaux fichiers de logs seront placés dans le dossier
    `/var/log/geonature/`. Vous pouvez archiver ou supprimer les
    anciens fichiers de log (`/var/log/geonature.log*`).

  - Supprimer les paramètres de configuration qui ont disparu s'ils
    sont présents dans votre fichier de configuration
    `geonature_config.toml` :

    - `LOCAL_SRID`
    - `CRUVED_SEARCH_WITH_OBSERVER_AS_TXT`
    - `id_area_type_municipality`

  - Installation du worker Celery : il vous faut installer le broker
    `redis` :

    ```bash
    sudo apt install redis
    ```

- Suivez la procédure de mise à jour classique de GeoNature
  (<https://docs.geonature.fr/installation.html#mise-a-jour-de-l-application>)
- Suivez les éventuelles notes de version spécifiques des modules
  installés (SQL de migration de leur schéma de BDD, stamp Alembic de
  la BDD)

✅ Un [exemple de migration complète de GeoNature 2.9 à 2.10, ses
dépendances et ses modules principaux est disponible](https://geonature.fr/documents/procedures/2022-11-GN-210-Migrate.txt)
(pour information et à adapter à votre contexte).

**🚀 Nouveautés**

- Possibilité de dupliquer le module Occtax (#621)
- Amélioration des fiches des observations dans les modules Synthèse
  et Validation (#1474)
- Ajout d’un permalien sur les fiches des observations dans les
  modules Synthèse et Validation (#1727)
- Signaler une occurrence et paramètre `ALERT_MODULES` associé
  (#1750)
- Epingler une occurrence et son paramètre `PIN_MODULES` associé
  (#1819)
- Discussions sur une occurrence et ses paramètres
  `DISCUSSION_MODULES` et `DISCUSSION_MAX_LENGTH` associés (#1731)
- Mise à jour d’Angular de la version 7 à 12 et des dépendances
  javascript liées (#1547)
- Mise en place de tests automatisés frontend avec Cypress, simulant
  les actions de l’utilisateur et vérifiant la conformité des
  résultats dans les modules Occtax, Synthèse et Métadonnées
- Renforcement et nettoyage des tests automatisés backend
  (augmentation de la couverture de code de 49,8% à 63,1%)
- Documentation de l’utilisation et de la mise en place des tests
  automatisés backend et frontend.
- Simplification du CRUVED minimum pour accéder à GeoNature, ne
  nécessitant plus d’avoir obligatoirement un CRUVED défini au niveau
  global de GeoNature (#1622)
- [Métadonnées] Remplacement de la liste des imports par la liste
  des sources dans la fiche des JDD (#1249)
- [Métadonnées] Lister les cadres d’acquisition par ordre
  alphabétique
- [Admin] Amélioration de l’interface (#2101)
- Ajout de la commande `geonature db status` permettant de lister les
  migrations Alembic, leurs dépendances et identifier celles qui ont
  été appliquées ou non (#1574)
- Ajout d'un worker Celery pour l'exécution de tâches asynchrones
- Déplacement du fichier de log GeoNature vers
  `/var/log/geonature/geonature.log`.
- Suppression de la table `gn_sensitivity.cor_sensitivity_synthese` et
  des triggers associés (#1710)
- Suppression du paramètre `CRUVED_SEARCH_WITH_OBSERVER_AS_TXT`
  permettant d’ajouter le filtre sur l’observers_txt en ILIKE sur
  les portée 1 et 2 du CRUVED
- Documentation : Ajout d’exemples de configuration pour utiliser les
  fonds IGN (#1703)
- Documentation : Complément de la documentation sur les calculs de la
  sensibilité
- Suppression du paramètre de configuration `LOCAL_SRID`. Le SRID
  local est fourni à l'installation, puis auto-détecté depuis la base
  de données à l'usage.
- Suppression du paramètre de configuration
  `id_area_type_municipality`.
- [Occtax] Révision du style des fiches d’information des relevés
  (#1876)
- [Occtax] Ajout des valeurs par défaut directement dans la base de
  données (#1857)
- [Monitoring] Ajout d’un trigger calculant automatiquement
  l’altitude des sites
- [Profils] Ajout des paramètres `default_spatial_precision`,
  `default_temporal_precision_days` et `default_active_life_stage`
  dans la table `gn_profiles.t_parameters`, remplaçant les valeurs par
  défaut définies au niveau du règne dans la table
  `gn_profiles.cor_taxons_parameters`
- Ajout d’une couche d’objets linéaires dans le référentiel
  géographique (<https://github.com/PnX-SI/RefGeo/pull/4>)
- Installation de la version 15 de Taxref par défaut lors des
  nouvelles installations
- Possibilité de limiter la recherche de lieux à un ou plusieurs pays
  avec le paramètre `OSM_RESTRICT_COUNTRY_CODES` (#2010)
- On ne peut pas fermer un cadre d’acquisition qui ne contient que
  des jeux de données sans données
- Rechargement (`reload`) automatique de GeoNature quand on modifie la
  configuration de GeoNature (#2045)
- Redémarrage (`restart`) automatique du worker Celery lors du
  redémarrage de GeoNature (#2045)
- Synthèse : ajout d’un message lors du chargement des données
  (#1637)
- Cartes : Faire remonter la géométrie de l’objet selectionné dans la
  liste (#2036)
- Ajout du paramètre `CODE_APPLICATION`, suite à la suppression du
  paramètre `ID_APP` (#1635)
- [Metadonnées] Formulaire des CA : correction de la saisie des CA
  parents (#2097)
- [Accueil] Amélioration du formatage des nombres dans le bloc de
  statistiques (#2085)

**🐛 Corrections**

- Remise en place de la rotation automatique des fichiers de logs
  (#1627)
- [OCCTAX] Ajout des valeurs par défaut des nomenclatures au niveau
  de la base de données (#1857)
- [OCCTAX] Correction d’un bug d’édition de géométrie non pris en
  compte
- Map List: à la selection d’une ligne dans le tableau, placement de
  la géométrie correspondante au dessus des autres géométries (#2036)
- Correction de l'URL pour la mise à jour des mots de passe (#1620)
- Statistiques sur la page d'accueil : utilisation des bonnes
  permissions (action R du module SYNTHESE). Les données et la carte
  sont masquées si les permissions sont manquantes.
- Amélioration du responsive de la page d’accueil (#1682)
- Correction de l’intégration des régions quand GeoNature n’est pas
  installé avec la projection 2154 (#1695)
- [Occtax] Correction de l’affichage de la liste tronquée des
  habitats (#1701)
- Correction du style des tooltips (#1775)
- [Validation] Correction du filtre par observations disposant d’un
  média (#1757)
- [Validation] Chargement des observations ayant un UUID uniquement
- [Synthèse] Amélioration de la liste dans la recherche des taxons
  (#1803)
- Correction des URL et redirection de renouvellement du mot de passe
  (#1810 / #1620)
- Correction du CSS du bloc introduction de la page d’accueil
  (#1824)
- Suppression de l’accès à la gestion du compte pour l’utilisateur
  "public" (#1844)
- Réduction du niveau de logs de l’outil Fiona pour améliorer les
  performances des exports en format SIG (#1875)
- Correction de la concaténation des champs additionnels au niveau des
  triggers de Occtax vers Synthèse et correction des données dans la
  Synthèse (#1467)
- Correction des données dans la Synthèse suite au problème
  d’enregistrement des dénombrements dans Occtax, corrigé dans la
  version 2.9.0 (#1479)
- Correction des triggers de Occtax vers Synthèse lors de la
  modification de dénombrements multiples et correction des données
  dans la Synthèse (#1821)
- Modification du script de démarrage `systemd` pour lancer GeoNature
  et son worker Celery après PostgreSQL (#1970)
- Correction de l’installation de psycopg2 (#1994)
- Correction de la route de récupération des jeux de données quand on
  lui passe plusieurs filtres
- Correction de la fonction `gn_synthese.update_sensitivity()` en cas
  de valeurs nulles
- [OCCTAX] Correction d’un bug d’édition de géométrie non pris en
  compte (#2023)
- [OCCTAX] Correction de l’affichage des dates en utilisant l’UTC
  pour éviter les soucis de fuseaux horaires différents entre le
  serveur et le navigateur de l’utilisateur (#2005)
- [Métadonnées] Correction de l’affichage des boutons de création
  d’un JDD et d’un CA seulement si l’utilisateur en a les droits
  (#1822)

**💻 Développement**

- Mise à jour d’Angular de la version 7 à 12 à répercuter dans les
  modules spécifiques (<https://update.angular.io/?v=7.2-12.0>)
- Mise à jour des dépendances backend et frontend
- Mise à jour de Flask version 1.1 à 2.2
- Routage dynamique des modules, supprimant la nécessité de générer le
  fichier de routage du frontend (#2059)
- Ajout de Celery pour les traitements asynchrones
- Possibilité de configurer GeoNature avec un fichier python en
  définissant le nom du module dans la variable d'environnement
  `GEONATURE_SETTINGS`
- Utilisation de la pagination fournit par Flask-SQLAlchemy pour
  `get_color_taxon()`
- Suppression de la table `gn_exports.t_config_export` et du schéma
  `gn_exports` créés par GeoNature (si le module Export n’est pas
  déjà installé) (#1642)
- Suppression des commandes GeoNature `dev-front` et `frontend-build`
  (#1800, #2088) :
- Rétablissement de l'utilisation de `nvm` pour installer NodeJS
  (#1726)
- Ajout de la commande `geonature default-config`
- Externalisation du `ref_geo`, de son schéma de données et de ses
  modèles en tant que module indépendant dans un dépôt dédié (#228)
- Intégration des régions par défaut lors de l’installation de
  GeoNature
- Amélioration des composants frontend DynamicForm
- Possibilité de filtrer le composant frontend "nomenclature" par
  règne ou Goup2INPN
- Amélioration du style des tooltips (#1717)
- Ajout de la commande `geonature sensitivity refresh-rules-cache`
  pour rafraichir la vue matérialisé
  `gn_synthese.t_sensitivity_rules_cd_ref` (à lancer à chaque
  modification de règles dans la table
  `gn_synthese.t_sensitivity_rules`)
- La configuration du module n'est pas écrasée lors d'une
  réinstallation de ce dernier
- Suppression de la vue `gn_synthese.v_synthese_decode_nomenclatures`
- Génération automatique de la documentation quand on publie une
  nouvelle version
- Ajout de la commande `geonature ref_geo info` qui compte le nombre
  de zonages par type
- Suppression des dépendances "geog" et "numpy" en utilisation la
  fonction PostGIS `ST_DWithin` pour la recherche par cercle (#1972)
- La variable d'environnement `DATA_DIRECTORY` permet de définir un
  dossier pour la mise en cache et réutilisation des ressources
  téléchargées lors de la création de la base de données
- Chargement de la configuration des modules packagés directement lors
  de l'import du module `config` (avant même l'appel à `create_app`)
  (#2055)

**📝 Merci aux contributeurs**

@bouttier / @antoinececchimnhn / @TheoLechemia / @jpm-cbna /
@mvergez / @ophdlv / @Adrien-Pajot / @Gaetanbrl / @pierrejego /
@jbrieuclp / @amandine-sahl / @joelclems / @metourneau /
@gildeluermoz / @camillemonchicourt

## 2.9.2 (2022-02-15)

**🚀 Nouveautés**

- Optimisation du nombre d'informations renvoyées par l'API pour les
  utilisateurs et les organismes
- Ajout d'une commande pour relancer le calcul de la sensibilité,
  utile en cas de modification du référentiel de sensibilité :
  `geonature sensitivity update-synthese`. Elle s’appuie sur la
  fonction `gn_synthese.update_sensitivity()`.
- Le niveau de diffusion dans la synthèse n'est plus calculé
  automatiquement à partir du niveau de sensibilité (#1711)
- Le niveau de sensibilité tient compte du comportement de
  l'occurrence (`OCC_COMPORTEMENT`), en plus du statut biologique
  (`STATUT_BIO`)
- Optimisation du recalcul de la sensibilité lors de la mise à jour de
  la synthèse (trigger `BEFORE` au lieu de `AFTER`)
- Ajout de tests unitaires sur les fonctions de calcul de la
  sensibilité

**🐛 Corrections**

- Correction d'une régression sur la récupération de la liste des
  taxons (#1672)
- Correction de l'authentification au CAS de l'INPN
- Correction du calcul de la sensibilité (#1284) :
  - Gestion correcte de la présence de plusieurs règles avec et sans
    critère statut biologique
  - Utilisation de la règle la plus sensible quand plusieurs règles
    s'appliquent

**⚠️ Notes de version**

- La correction de la fonction de calcul de la sensibilité est suivie
  d'un recalcul automatique du niveau de sensibilité des données
  présentes dans la synthèse. Si vous ne souhaitez pas procéder à ce
  recalcul, ajoutez le paramètre `-x recompute-sensitivity=false` lors
  de la mise à jour de la base de données avec la commande
  `geonature db autoupgrade` (lancée automatiquement par le script
  `migration.sh`) :

      (venv)$ geonature db autoupgrade -x recompute-sensitivity=false

- Le niveau de diffusion des données dans la synthèse est remis à
  `NULL` si celui-ci équivaut au niveau de sensibilité. Seuls les
  niveaux de diffusion qui différent sont laissés intacts. Si vous
  souhaitez rectifier vous-mêmes vos niveaux de diffusion et ne pas
  les remettre à `NULL` quand ils sont équivalents au niveau de
  sensibilité, vous pouvez ajouter le paramètre
  `-x clear-diffusion-level=false` lors de la mise à jour de la base
  de données :

      (venv)$ geonature db autoupgrade -x clear-diffusion-level=false

  Si vous redescendez à l'état antérieur de votre base de données, les
  niveaux de diffusion seront restaurés à partir du niveau de
  sensibilité ; vous pouvez éviter ceci avec
  `-x restore-diffusion-level=false`.

## 2.9.1 (2022-01-27)

**🚀 Nouveautés**

- Utilisation du paramètre `page` de Flask à la place du paramètre
  maison `offset` pour la pagination des routes (rétro-compatible)
- Installation de TaxHub en version 1.9.4 (version corrective) par
  défaut
- Ajout du paramètre de configuration `CODE_APPLICATION` (par défaut
  `GN`) (#1635)

**🐛 Corrections**

- Correction de l’URL de réinitialisation de mot passe envoyée par
  email (#1620)
- Correction d'un problème d'authentification avec le CAS
- Occtax : Correction des listes déroulantes masquées dans le bloc
  dénombrement, en rajoutant un scroll
- Correction de l’URL de l’API de TaxHub (slash final manquant) pour
  l’affichage des photos sur la fiche d’un profil de taxon
- Correction de la synchronisation des métadonnées depuis MTD
- Correction de la génération du token quand on utilise le CAS de
  l’INPN pour se connecter à GeoNature
- Correction des permissions trop restrictives d'accès aux données de
  la synthèse
- Correction de la pagination de la route `/color_taxon` en rajoutant
  un ordonnancement par `cd_nom` et `id_area` (utilisé par
  Occtax-mobile)
- Contournement d’un problème de redirection incorrecte par l'API de
  TaxHub lorsque celui-ci est mal configuré (#1438, #1616)

## 2.9.0 - Actias luna 🦋 (2022-01-13)

**Profils de taxons**

**🚀 Nouveautés**

- Construction automatique d’une fiche d’identité (profil) par taxon
  grâce aux observations validées présentes dans la base de données
  (altitude min/max, distribution spatiale, date de première/dernière
  observation, nombre de données valides, phénologie) (#917 par
  \@DonovanMaillard, \@lepontois, \@Adrien-Pajot, \@TheoLechemia,
  \@bouttier, \@amandine-sahl, \@jpm-cbna)
  - Création d’un schéma `gn_profiles` dans la BDD contenant les
    tables, les vues, les fonctions et les paramètres de calcul des
    profils de taxons
    (<https://github.com/PnX-SI/GeoNature/blob/develop/data/core/profiles.sql>)
    (#1103)
  - Mise en place de l’API des profils de taxons (#1104)
  - Affichage des scores de chaque observation par rapport au profil
    du taxon dans la liste des observations du module Validation,
    ainsi que dans les fiches détails des observations dans les
    modules Synthèse et Validation (#1105)
  - Ajout de filtres des observations par score ou critère des
    profils de taxon dans le module Validation (#1105)
  - Ajout d’une alerte de contextualisation d’une observation par
    rapport au profil de taxon, lors de sa saisie dans le module
    Occtax
  - Mise en place de paramètres pour activer ou non les profils de
    taxons, paramétrer leurs règles et définir les statut de
    validation pris en compte pour le calcul des profils
    ("Certain-très probable" et "Probable" par défaut)
  - Documentation des profils de taxons et de leur paramètrage
    (<https://docs.geonature.fr/admin-manual.html#profils-de-taxons>)
  - Suppression de la vue matérialisée
    `gn_synthese.vm_min_max_for_taxons` et de la fonction
    `gn_synthese.fct_calculate_min_max_for_taxon()` qui n’étaient
    pas utilisées
- [OCCTAX] Ajout d’un bouton permettant d’annuler la modification
  d’un taxon (#1508 par \@jbrieuclp)
- [OCCTAX] Ajout de valeurs par défaut aux champs additionnels
  (`gn_commons.t_additional_fields.default_value`)
- [OCCTAX] Ajout d’un filtre avancé par `id_releve`
- [SYNTHESE] Ajout d’un filtre avancé par UUID d’observation
  (#973)
- Amélioration des listes déroulantes en passant à la librairie
  `ng-select2` pour les composants multiselects (#616
  par \@jbrieuclp)
- Gestion du référentiel des régions par Alembic (#1475)
- Ajout des anciennes régions (1970-2016), inactives par défaut, mais
  utiles pour les règles régionales de sensibilité
- Gestion du référentiel de sensibilité (règles nationales et
  régionales) par Alembic (#1576)
- Ajout d’une documentation sur le calcul de la sensibilité des
  observations
  (<https://docs.geonature.fr/admin-manual.html#gestion-de-la-sensibilite>,
  par \@mvergez)
- [SYNTHESE] Amélioration de la fenêtre de limite d’affichage
  atteinte (#1520 par \@jpm-cbna)
- [OCCHAB] Utilisation de tout Habref par défaut si aucune liste
  d’habitats n’est renseignée dans la configuration du module
- [METADONNEES] Attribuer des droits à un utilisateur sur un JDD si
  il a des droits sur son cadre d’acquisition
- Association automatique et paramétrable des jeux de données
  personnels auto-générés à des modules (Occtax par défaut) (#1555)
- Utilisation du C du CRUVED de l’utilisateur pour lister les jeux de
  données dans lesquels il peut ajouter des données dans les
  différents modules (et non plus le R du CRUVED sur GeoNature)
  (#659)

**🐛 Corrections**

- [OCCTAX] Correction de l’enregistrement des dénombrements lors de
  l’enchainement des relevés (#1479 par \@jbrieuclp)
- [OCCTAX] Correction du filtre du champs "Habitat" par typologie
  d’habitat
- [ADMIN] Correction de l’affichage du module (#1427
  par \@jbrieuclp)
- [ADMIN] Sécurisation du module (#839)
- [VALIDATION] Corrections de la validation des observations (#1485
  / #1529)
- [METADONNEES] Amélioration des performances (#1559)
- [METADONNEES] Correction de la suppression des JDD
- [METADONNEES] Correction de l’export PDF des JDD (#1544)
- [METADONNEES] Correction des permissions (#1528)
- [METADONNEES] Correction de la recherche avancée
- [SYNTHESE] Correction de la recherche sur les champs génériques de
  type nombre entier (#1519 par \@jpm-cbna)
- [SYNTHESE] Correction des permissions
- [SYNTHESE] Correction du lien entre les filtres CA et JDD (#1530)
- [OCCHAB] Correction du chargement de la configuration, des fiches
  info et de la modification d’une station
- [METADONNEES] Améliorations des performances et des contrôles du
  formulaire des acteurs pour les JDD et les CA (par \@joelclems)
- Correction de la redirection vers le formulaire de login en cas de
  cookie corrompu (#1550 par \@antoinececchimnhn)
- Correction de la création de compte utilisateur (#1527)
- Mise à jour du module Habref-api-module pour corrections de
  certaines données d’Habref

**💻 Développement**

- Migration vers la librairie `gn-select2` pour les listes déroulantes
  des formulaires (#616 / #1285 par \@jbrieuclp)
- Documentation de développement backend revue et complétée (#1559,
  <https://docs.geonature.fr/development.html#developpement-backend>)
- Amélioration de nombreuses routes et fonctions du backend
- Ajouts de tests automatisés du backend
- Mise en place d’une intégration continue pour exécuter
  automatiquement les tests backend et leur couverture de code avec
  GitHub Actions, à chaque commit ou pull request dans les branches
  `develop` ou `master` (#1568,
  <https://github.com/PnX-SI/GeoNature/actions>)
- [VALIDATION] Suppression des vues SQL et optimisation des routes
- Génération automatique et aléatoire du paramètre `SECRET_KEY`
- [SYNTHESE] Remplacement de `as_literal` par `json.loads`, plus
  performant (par \@antoinececchimnhn)
- Possibilité de filter la route `synthese/taxa_distribution` par
  `id_source` (#1446 par \@mvergez)
- Factorisation du composant `pnx-municipalities` avec le composant
  `pnx-areas`
- Ajout du composant `pnx-areas` dans dynamic-form
- Ajout d’un input `valueFieldName` aux composants `pnx-areas` et
  `pnx-municipalities`.
- Mise à jour de nombreuses dépendances

**⚠️ Notes de version**

- La liste des JDD dans les modules de saisie (Occtax, Occhab,
  Monitoring et Import) se base désormais sur le C du CRUVED de
  l’utilisateur au niveau du module (ou du C du CRUVED de GeoNature
  si l’utilisateur n’a pas de CRUVED sur le module), au lieu du R de
  GeoNature jusqu’à présent. Vous devrez donc potentiellement adapter
  vos permissions à ce changement de comportement (#659)

- Si vous avez surcouché le paramètre de configuration `AREA_FILTERS`
  de la section `[SYNTHESE]`, veuillez remplacer `id_type` par
  `type_code` (voir `ref_geo.bib_areas_types`)

  ```python
  AREA_FILTERS = [
      { label = "Communes", id_type = 25 }
  ]
  ```

  devient

  ```python
  AREA_FILTERS = [
      { label = "Communes", type_code = "COM" }
  ]
  ```

- Si vous aviez modifié les colonnes de la liste des observations du
  module Validation en adaptant la vue
  `gn_validation.v_synthese_validation_forwebapp`, celle-ci a été
  supprimée et il suffit désormais d’indiquer les colonnes souhaitées
  dans la configuration du module. Voir documentation
  (<http://docs.geonature.fr/admin-manual.html#liste-des-champs-visibles>)

- Les nouvelles fonctionnalités liées aux profils de taxons
  nécessitent de rafraichir des vues materialisées à intervalles
  réguliers et donc de créer une tâche planfiée (cron). Voir
  documentation
  (<https://docs.geonature.fr/installation.html#taches-planifiees>)

- Les régions sont maintenant disponibles via des migrations Alembic.
  Si vous possédez déjà les régions, vous pouvez l'indiquer à Alembic
  :

      geonature db upgrade ref_geo@head
      geonature db stamp d02f4563bebe

- Le référentiel de sensibilité est désormais disponible via une
  migration Alembic. Celui-ci nécessite le référentiel des régions
  (branche Alembic `ref_geo_fr_regions`), ainsi que le référentiel des
  anciennes régions (branche Alembic `ref_geo_fr_regions_1970`) --
  l'installation de ces référentiels est automatique avec
  l’installation des règles de sensibilité.

  - Si vous possédez déjà le référentiel, vous pouvez l'indiquer à
    Alembic :

        geonature db stamp 7dfd0a813f86

  - Si vous avez installé GeoNature 2.8.X, le référentiel de
    sensibilité n'a pas été installé automatiquement. Vous pouvez
    l'installer manuellement :

        geonature db upgrade ref_sensitivity_inpn@head

  Par défaut, seule les règles nationales sont activées, vous laissant
  le soin d'activer vos règles locales en base vous-même. Vous pouvez
  également demander, lors de l'installation du référentiel, à activer
  (resp. désactiver) toutes les règles en ajout à la commande Alembic
  l'option `-x active=true` (resp. `-x active=false`).

- Si vous souhaitez surcoucher les paramètres par défaut de Gunicorn
  (app_name, timeout\...), depuis le passage à `systemd` dans la
  version 2.8.0, c’est désormais à faire dans un fichier `environ` à
  la racine du dossier de votre GeoNature (#1588,
  <https://docs.geonature.fr/admin-manual.html#parametres-gunicorn>)

- Si vous les utilisez, mettez à jour les modules Import, Export et
  Monitoring dans leurs dernières versions compatibles avec le version
  2.9.0 de GeoNature

## 2.8.1 (2021-10-17)

**🚀 Nouveautés**

- Ajout de l'indication du département au formulaire des communes
  (#1480)
- Ajout des champs `group2inpn` et `regne` au formulaire des
  nomenclatures (#1481)

**🐛 Corrections**

- Correction de la commande `geonature db autoupgrade`
- Mise-à-jour corrective de [UsersHub-authentification-module
  1.5.7](https://github.com/PnX-SI/UsersHub-authentification-module/releases/tag/1.5.7)

## 2.8.0 - Vaccinium myrtillus 🌿 (2021-10-18)

**Gestion de la base de données avec Alembic**

⚠️ Avant de mettre à jour GeoNature, vérifiez que les modules que vous
utilisez disposent d’une version compatible avec la 2.8.0, suite au
passage à la version 3 de Marshmallow.

**🚀 Nouveautés**

- Support de Debian 11 / Python 3.9
- Passage de `supervisor` à `systemd`
- Gestion de la base de données et de ses évolutions avec Alembic
  (#880)
- Mise à jour de la procédure d'installation afin d'utiliser Alembic
  (#880)
- Révision et réorganisation des scripts et de la documentation
  d’installation
- Passage à la version 3 de Marshmallow (#1451)
- Suppression du paramètre `ID_APP`, celui-ci est automatiquement
  déterminé à partir de la base de données et du code de l'application
- Ajout d'un index sur le champs `ref_geo.l_areas.id_area`
- Mise à jour des dépendances
  - [TaxHub
    1.9.0](https://github.com/PnX-SI/TaxHub/releases/tag/1.9.0)
  - [UsersHub-authentification-module
    1.5.6](https://github.com/PnX-SI/UsersHub-authentification-module/releases/tag/1.5.6)
  - [Nomenclature-api-module
    1.4.4](https://github.com/PnX-SI/Nomenclature-api-module/releases/tag/1.4.4)
  - [Habref-api-module
    0.2.0](https://github.com/PnX-SI/Habref-api-module/releases/tag/0.2.0)
  - [Utils-Flask-SQLAlchemy
    0.2.4](https://github.com/PnX-SI/Utils-Flask-SQLAlchemy/releases/tag/0.2.4)
  - [Utils-Flask-SQLAlchemy-Geo
    0.2.1](https://github.com/PnX-SI/Utils-Flask-SQLAlchemy-Geo/releases/tag/0.2.1)

**🐛 Corrections**

- Corrections et améliorations des formulaires dynamiques et des
  champs additionnels
- Correction de l’envoi d’email lors de la récupération du mot de
  passe (#1471)
- Occtax : Correction du focus sur le champs "taxon" quand on
  enchaine les taxons (#1462)
- Occtax : Correction du formulaire de modification quand le relevé
  est une ligne ou un polygone (#1461)
- Occtax : Correction de la conservation de la date quand on enchaine
  les relevés (#1442)
- Occtax : Correction du paramètre d’export des champs additionnels
  (#1440)
- Synthèse : correction de la recherche par jeu de données (#1494)
- Correction de l’affichage des longues listes déroulantes dans les
  champs additionnels (#1442)
- Mise à jour de la table `cor_area_synthese` lors de l'ajout de
  nouvelles zones via un trigger sur la table `l_areas` (#1433)
- Correction de l’export PDF des fiches de métadonnées (#1449)
- Jeux de données : correction de l'affichage des imports sources
- Correction de la configuration Apache et de la gestion par flask
  d'un GeoNature accessible sur un préfix (e.g. `/geonature`) (#1463)
- Correction de la commande `install_packaged_gn_module`
- Correction des champs additionnels de type boutons radios (#1464 et
  #1472)
- Occtax : Correction du contrôle des heures quand on est sur 2 mois
  distincts (#1468)
- Suppression de nombreux identifiants en dur dans les scripts SQL de
  création de la BDD
- Correction du trigger d’Occtax vers la Synthèse pour le champs
  `Comportement` (#1469)
- Correction des fonctions `get_default_nomenclature_value`
- Correction du composant `multiselect` (#1488)
- Correction du script `migrate.sh` pour récupérer le fichier
  `custom.scss` depuis son nouvel emplacement (#1430)
- Correction du paramètre `EXPORT_OBSERVERS_COL`
- Métadonnées : Suppression en cascade sur les tables
  `gn_meta.cor_dataset_territory` et `gn_meta.cor_dataset_protocol`
  (#1452)
- Correction de la commande `install_packaged_gn_module` :
  rechargement des entry points après installation avec pip d'un
  module packagé
- Correction d'un bug lors de l'ajout d'un cadre d'acquisition

**💻 Développement**

- Mise à jour de plusieurs dépendances
- Packetage des modules fournis avec GeoNature
- L'utilisateur connecté est maintenant accessible via
  `g.current_user`
- Nettoyage et refactoring divers

**⚠️ Notes de version**

- Mettre à jour [UsersHub en version
  2.2.1](https://github.com/PnX-SI/UsersHub/releases/tag/2.2.1) et
  [TaxHub en version
  1.9.0](https://github.com/PnX-SI/TaxHub/releases/tag/1.9.0) (si vous
  les utilisez) **en sautant leur étape de passage à Alembic** (car la
  mise à jour de GeoNature se charge désormais de mettre à jour aussi
  les schémas `taxonomie` et `utilisateurs`)

- Suppression de `supervisor` :

  - Stopper GeoNature : `sudo supervisorctl stop geonature2`
  - Supprimer le fichier de configuration supervisor de GeoNature :
    `sudo rm /etc/supervisor/conf.d/geonature-service.conf`
  - Si supervisor n'est plus utilisé par aucun service (répertoire
    `/etc/supervisor/conf.d/` vide), il peut être désinstallé
    (`sudo apt remove supervisor`)

- Suivre la procédure classique de mise à jour de GeoNature
  (<http://docs.geonature.fr/installation-standalone.html#mise-a-jour-de-l-application>)

- Passage à `systemd` :

  - Copier le fichier `install/assets/geonature.service` dans
    `/etc/systemd/system/`
  - Éditer `/etc/systemd/system/geonature.service` et remplacer les
    variables `${USER}` (votre utilisateur linux courant) et
    `${BASE_DIR}` (chemin absolu du répertoire de GeoNature) par les
    valeurs appropriées
  - Lancer la commande `sudo systemctl daemon-reload`
  - Pour démarrer GeoNature : `sudo systemctl start geonature`
  - Pour lancer GeoNature automatiquement au démarrage du serveur :
    `sudo systemctl enable geonature`

- Correction de la configuration Apache : si vous servez GeoNature sur
  un préfixe (typiquement `/geonature/api`), assurez vous que ce
  préfixe figure bien également à la fin des directives `ProxyPass` et
  `ProxyPassReverse` comme dans l'exemple suivant :

  ```apache
  <Location /geonature/api>
      ProxyPass http://127.0.0.1:8000/geonature/api
      ProxyPassReverse  http://127.0.0.1:8000/geonature/api
  </Location>
  ```

  Si vous servez GeoNature sur un sous-domaine, vérifiez ou modifier
  la configuration Apache :

  ```apache
  <Location /api>
      ProxyPass http://127.0.0.1:8000/api
      ProxyPassReverse  http://127.0.0.1:8000/api
  </Location>
  ```

  Pensez à recharger Apache si vous êtes amené à en changer la
  configuration : `sudo systemctl reload apache2`

- Passage à Alembic :

  - S'assurer d'avoir une base de données de GeoNature en version
    2.7.5
  - Si vous avez UsersHub installé, ajoutez dans votre configuration
    GeoNature la section suivante (en adaptant le chemin) :

  ```ini
  [ALEMBIC]
  VERSION_LOCATIONS = '/path/to/usershub/app/migrations/versions'
  ```

  - Entrer dans le virtualenv afin d'avoir la commande `geonature`
    disponible : `source backend/venv/bin/activate`
  - Exécuter les commandes suivantes afin d'indiquer à Alembic
    l'état de votre base de données :

  ```bash
  geonature db stamp f06cc80cc8ba  # GeoNature 2.7.5
  geonature db stamp 0dfdbfbccd63  # référentiel géographique des communes
  geonature db stamp 3fdaa1805575  # référentiel géographique des départements
  geonature db stamp 586613e2faeb  # référentiel géographique des mailles 1×1
  geonature db stamp 7d6e98441e4c  # référentiel géographique des mailles 5×5
  geonature db stamp ede150d9afd9  # référentiel géographique des mailles 10×10
  geonature db stamp 1715cf31a75d  # MNT de l’IGN
  ```

  - Si vous aviez déjà intallé certains modules, vous devez
    l'indiquer à Alembic :
    - Module _Occtax_ : `geonature db stamp f57107d2d0ad`
    - Module _Occhab_ : `geonature db stamp 2984569d5df6`
  - Mettre sa base de données à jour avec Alembic :
    `geonature db autoupgrade`

  Pour plus d'information sur l'utilisation d'Alembic, voir la
  [documentation administrateur de
  GeoNature](https://docs.geonature.fr/admin-manual.html#administration-avec-alembic).

## 2.7.5 (2021-07-28)

**🐛 Corrections**

- Compatibilité avec Occtax-mobile 1.3. Possibilité d’ajouter la
  query string `fields` sur la route `meta/datasets` pour choisir les
  champs renvoyés par l’API

**⚠️ Notes de version**

Si vous mettez à jour GeoNature :

- Vous pouvez passer directement à cette version mais en suivant les
  notes des versions intermédiaires

## 2.7.4 (2021-07-23)

**🐛 Corrections**

- Correction d’un import manquant entrainant un problème de
  compilation du frontend (#1424)

**⚠️ Notes de version**

Si vous mettez à jour GeoNature :

- Vous pouvez passer directement à cette version mais en suivant les
  notes des versions intermédiaires

## 2.7.3 (2021-07-22)

**🚀 Nouveautés**

- Métadonnées : ajout des paramètres `CD_NOMENCLATURE_ROLE_TYPE_DS` et
  `CD_NOMENCLATURE_ROLE_TYPE_AF` pour limiter les rôles utilisables au
  niveau des jeux de données et des cadres d’acquisition (#1417)
- Ajout de la commande `mtd_sync` qui permet de synchroniser les
  métadonnées de toute une instance depuis le flux MTD du SINP

**🐛 Corrections**

- Correction de l’affichage des jeux de données sur les fiches des
  cadres d’acquisition (#1410)
- Doc : Précision des OS supportés (Debian 10 uniquement en
  production)

**💻 Développement**

- Support des commandes Flask au niveau de la commande `geonature`
  (`run`, `db`, `routes`, `shell`\...)
- Ajout des sous-modules en tant que dépendances
- Ajout d’une commande `install_packaged_gn_module`

**⚠️ Notes de version**

Si vous mettez à jour GeoNature :

- Vous pouvez passer directement à cette version mais en suivant les
  notes des versions intermédiaires

## 2.7.2 (2021-07-05)

**🐛 Corrections**

- OCCTAX : correction de la vérification du CRUVED (#1413)
- OCCTAX : correction du dégrisement du formulaire au chargement de la
  fonctionnalité "mes lieux" (#1414)
- OCCTAX : Déplacement des champs additionnels pour les dénombrements
  avant les médias (#1409)
- Suppression des champs additionnels de type "taxonomy" qui
  n’étaient pas supportés

**⚠️ Notes de version**

Si vous mettez à jour GeoNature :

- Vous pouvez passer directement à cette version mais en suivant les
  notes des versions intermédiaires
- Exécuter le script SQL de mise à jour de la BDD de GeoNature
  (<https://github.com/PnX-SI/GeoNature/blob/master/data/migrations/2.7.1to2.7.2.sql>)

## 2.7.1 (2021-07-02)

**🐛 Corrections**

- Installation des dépendances javascript des modules lors de la
  migration de version de GeoNature (#1252)
- Installation de la version 1.8.1 de TaxHub par défaut à la place de
  la 1.8.0
- Intégration de la documentation permettant de mettre en place
  l’accès public à GeoNature

**⚠️ Notes de version**

Si vous mettez à jour GeoNature :

- Vous pouvez passer directement à cette version mais en suivant les
  notes des versions intermédiaires

## 2.7.0 - Androsace delphinensis 🌼 (2021-06-30)

Nécessite la version 1.8.x de TaxHub.

**🚀 Nouveautés**

- Compatible avec TaxHub 1.8.x qui inclut notamment la migration
  (optionnelle) vers Taxref version 14 et l’ajout de la BDC statuts
- Installation globale migrée de Taxref version 13 à 14
- Occtax : Possibilité d’ajouter des champs additionels par JDD ou
  globaux au module et documentation liée (#1007)
- Occtax/Synthese : Ajout des champs additionnels dans les exports
  (#1114)
- Occtax/Synthese : Affichage des champs additionnels dans les fiches
  info
- Customisation : possibilité de changer le CSS sans rebuilder
  l’application
- Admin : Création d’un backoffice d’administration des champs
  additionels (#1007)
- Admin : Création d’une documentation d’administration des champs
  additionnels (#1007)
- Occtax : Possibilité de désactiver la recherche de taxon par liste
  (#1315)
- Occtax : Par défaut la recherche de taxon n’interroge pas une liste
  mais tout Taxref, si aucune liste de taxons n’a été spécifiée dans
  la configuration du module Occtax (voir notes de version) (#1315)
- Occtax/Metadonnées : possibilité d’associer une liste de taxons à
  un JDD (implémenté uniquement dans Occtax) (#1315)
- Occtax : Possibilité d’ajouter les infos sur les médias dans les
  exports (paramètre `ADD_MEDIA_IN_EXPORT`) (#1326)
- Occtax : Possibilité de paramétrer l’affichage des champs du
  composant MEDIA dans OCCTAX (paramètre `MEDIA_FIELDS_DETAILS` -
  #1287)
- Occtax : Possibilité de filtrer la liste des habitats du formulaire
  avec les nouveaux paramètres `ID_LIST_HABITAT` et `CD_TYPO_HABITAT`
- Occtax : Possibilité d’ouvrir le module avec un JDD pré-selectionné
  en passant le paramètre `id_dataset` dans l’URL (#1071)
- Accueil : Réorganisation des blocs (#1375)
- Accueil : Ajout d’un paramètre controlant la fréquence de MAJ du
  cache des statistiques de la page d’accueil (`STAT_BLOC_TTL`, par
  défaut 1h: 3600 secondes) (#1320)
- Amélioration des performances de récupération des modules et du
  CRUVED
- Monitoring : Ajout d’un trigger garantissant la cohérence entre
  `date_min` et `date_max` et historisation de la table
  `gn_monitoring.cor_visit_observer` (#1247)
- La page d’authentification affiche désormais le nom de
  l’application (`appName`) défini dans la configuration de GeoNature
  (#1277)
- Possibilité d’ouvrir l’accès à GeoNature sans authentification
  (voir documentation d’administration) (#1323)
- Métadonnées : Optimisation du temps de chargement des listes des CA
  et JDD (#1291)
- Métadonnées : Passage de la version 1.3.9 du standard SINP à la
  version 1.3.10 et ajout des champs liés dans les formulaires
  (#1291)
- Métadonnées : Révision du design la partie "Acteurs" du formulaire
  et mise à part de l’acteur de type "Contact principal",
  obligatoire dans le standard SINP
- Métadonnées : Ordonnancement des JDD par leur nom
- Métadonnées : Ajout de la suppression en cascade au niveau des
  tables des CA et des JDD
- Métadonnées : Ajout d’un message quand un CA ou JDD n’a pas
  d’acteur (#1404)
- Synthèse et validation : Ajout d’un filtre avancé
  `Possède des médias` (#1179, #1338, #1180)
- Synthèse : Affichage du contenu json du champs des données
  additionnelles, dans la fiche détail d’une observation
- Synthèse : Ajout de la possibilité d’afficher la colonne
  "Effectif" dans la liste des observations
- DynamicForm : enrichissement des formulaires dynamiques pour les
  médias, l’ajout de liens externes
- Ajout d’une contrainte d’unicité de la combinaison des champs
  `id_type` et `area_code` dans `ref_geo.l_areas` (#1270)
- Ajout d’une contrainte d’unicité du champs `type_code` de la table
  `ref_geo.bib_areas_types`
- Mise à jour des versions de nombreuses dépendances Python et
  Javascript
- Support du gestionnaire d’erreurs Sentry
- Compression des images
- Ajout d’un script permettant d’identifier les doublons dans
  `data/scripts/duplicates_deletion` (#1324)
- Validation : possibilité de passer des fonctions dans la liste des
  colonnes affichées (pour décoder une nomenclature)
- Validation : Les paramètres `LIST_COLUMNS_FRONTEND` et
  `COLUMNS_API_VALIDATION_WEB_APP` sont regroupés en un seul paramètre
  nommé `COLUMN_LIST`. Voir le fichier
  `contrib/gn_module_validation/config/conf_gn_module.toml.example`

**🐛 Corrections**

- Occtax : Correction d’un bug sur le champs observateur lors de la
  modification d’un relevé (#1177)
- Occtax : Renseignement par défaut de l’utilisateur connecté à la
  création d’un relevé en mode "observers_txt" (#1292)
- Occtax : Déplacement des boutons d’action à gauche dans la liste
  des taxons d’un relevé pour éviter qu’ils soient masqués quand les
  noms de taxon sont longs (#1299 et #1337)
- Occtax : Correction de la possibilité de modifier un relevé si U=1
  (#1365)
- Occtax : Suppression du zoom quand on localise le relevé (#1317)
- Occtax : Correction du nombre de lignes affichées après une
  recherche
- Occtax : Correction de la suppression d’un habitat lors de la
  modification d’un relevé (#1296)
- Occtax : Correction des champs "Habitat" et "Lieu" quand on
  enchaine des relevés (#1191)
- Occtax : Correction de l’enchainement des saisies (#1300)
- Occtax : Correction de l’affichage des taxons quand le nom est long
  (#1299, #1337)
- Occtax : Correction de l’observateur par défaut en mode
  `observers_txt`
- Occtax : Correction des messages d’information multiples (#1367)
- Occtax : Correction de la mise à jour du "digitiser" lors d’une
  édition de relevé (#1392)
- Occtax : Correction du trigger alimentant les observateurs de la
  synthèse depuis Occtax (#1399)
- Métadonnées : Correction de la suppression d’un JDD sans données,
  depuis la liste des JDD (#1312)
- Métadonnées : Correction de la récupération des valeurs de
  nomenclature depuis MTD n’existant pas dans GeoNature (#1297)
- Authentification : Redirection vers la page login après une période
  d’inactivité (#1193)
- Résolution des problèmes de permission sur le fichier
  `gn_errors.log` (#1003)

**💻 Développement**

- Possibilité d’utiliser la commande `flask` (eg `flask shell`)
- Préparation de l’utilisation d’Alembic pour la gestion des
  migrations de la structure de la BDD (#880)
- Possibilité d’importer des modules packagés (#1272)
- Réorganisation des fichiers `requirements` et installation des
  branches `develop` des dépendances du fichier `requirements-dev.txt`
- Simplification de la gestion des erreurs
- Création de templates pour les configurations Apache de GeoNature,
  TaxHub et UsersHub, utilisés par le script `install_all.sh`
- Ajout du plugon `leaflet-image`
- Ajout d’un champs `type` dans la table `gn_commons.t_modules` pour
  gérer le polymorphisme, utilisé dans le module Monitoring
- Ajout des champs `meta_create_date` et `meta_update_date` dans la
  table `gn_commons.t_modules`
- Diverses améliorations mineures de l’architecture du code

**⚠️ Notes de version**

Si vous mettez à jour GeoNature :

- Mettez à jour TaxHub 1.8.x avant d’effectuer la mise à jour de
  GeoNature : <https://github.com/PnX-SI/TaxHub/releases>
- Si vous utilisez le module Monitoring, mettez le à jour en version
  0.2.4 minimum avant de mettre à jour GeoNature
- Si vous n’aviez pas renseigné de valeur pour le paramètre
  `id_taxon_list` dans le fichier
  `contrib/occtax/config/conf_gn_module.toml` du module Occtax, la
  liste 100 n’est plus passée par defaut et le module va rechercher
  sur tout Taxref. Si vous souhaitez utiliser une liste de taxons dans
  la saisie Occtax, veuillez renseigner l’identifiant de votre liste
  dans la configuration du module
- Vous pouvez passer directement à cette version mais en suivant les
  notes des versions intermédiaires
- Exécuter le script SQL de mise à jour de la BDD de GeoNature
  (<https://github.com/PnX-SI/GeoNature/blob/master/data/migrations/2.6.2to2.7.0.sql>)
- Le script SQL de mise à jour va supprimer et recréer les vues
  `pr_occtax.v_export_occtax` et `gn_synthese.v_synthese_for_export`
  pour y intégrer les champs additionnels. Si vous aviez modifié ces
  vues, adaptez le script de mise à jour de GeoNature 2.6.2 à 2.7.0,
  ou répercuter vos modifications après la mise à jour, à appliquer
  aussi dans votre éventuelle surcouche des paramètres
  `default_columns_export` (dans
  `contrib/occtax/config/conf_gn_module.toml`) et `EXPORT_COLUMNS`
  (dans `config/geonature_config.toml`)
- Le fichier de customisation CSS a été déplacé de
  `frontend/src/custom/custom.scss` vers
  `frontend/src/assets/custom.css` pour pouvoir être modifié sans
  devoir rebuilder l’application. Son déplacement est fait
  automatiquement lors de la mise à jour de GeoNature. Si vous avez
  customisé les styles dans ce fichier et notamment fait référence à
  d’autres fichiers, vérifiez ou adaptez leurs chemins
- Si vous aviez renseigner un des deux paramètres
  `LIST_COLUMNS_FRONTEND`, `COLUMNS_API_VALIDATION_WEB_APP` dans le
  module Validation, il est nécessaire de les remplacer par le nouveau
  paramètre `COLUMN_LIST`. Voir le fichier
  `contrib/gn_module_validation/config/conf_gn_module.toml.example`
- Modifier dans le fichier
  `/etc/supervisor/conf.d/geonature-service.conf`, remplacer
  `gn_errors.log` par `supervisor.log` dans la variable
  `stdout_logfile` :

  ```bash
  sudo sed -i 's|\(stdout_logfile = .*\)/gn_errors.log|\1/supervisor.log|' /etc/supervisor/conf.d/geonature-service.conf
  sudo supervisorctl reload
  ```

## 2.6.2 (2021-02-15)

**🐛 Corrections**

- Metadonnées : correction d’un bug sur la fiche JDD si le module
  d’import n’est pas installé
- Metadonnées : correction de l’affichage de certains champs sur la
  fiche des cadres d’acquisition
- Metadonnées : la recherche rapide n’est plus sensible à la casse
  casse

## 2.6.1 (2021-02-11)

**🐛 Corrections**

- Correction de la fonction
  `gn_synthese.fct_tri_cal_sensi_diff_level_on_each_statement()` non
  compatible avec PostgreSQL 10 (#1255)
- Synthèse : correction de l’affichage du filtre "statut de
  validation" (#1267)
- Permissions : correction de l’URL de redirection après
  l’édition des permissions (#1253)
- Précision de la documentation de mise à jour de GeoNature (#1251)
- Ajout du paramètre `DISPLAY_EMAIL_INFO_OBS` dans le fichier
  d’exemple de configuration (#1066 par @jbdesbas)
- Sécurité : suppression d’une route inutile
- Correction de l’URL de la doc sur la page d’accueil

**⚠️ Notes de version**

Si vous mettez à jour GeoNature :

- Vous pouvez passer directement à cette version mais en suivant les
  notes des versions intermédiaires
- Exécuter le script de mise à jour de la BDD du sous-module de
  nomenclature :
  https://github.com/PnX-SI/Nomenclature-api-module/blob/master/data/update1.3.5to1.3.6.sql
- Exécuter ensuite le script SQL de mise à jour de la BDD de GeoNature
  (https://github.com/PnX-SI/GeoNature/blob/master/data/migrations/2.6.0to2.6.1.sql)
- Suivez la procédure classique de mise à jour de GeoNature
  (http://docs.geonature.fr/installation-standalone.html#mise-a-jour-de-l-application)

## 2.6.0 - Saxifraga 🌸 (2021-02-04)

Nécessite Debian 10, car cette nouvelle version nécessite PostgreSQL 10
minimum (qui n’est pas fourni par défaut avec Debian 9) pour les
triggers déclenchés "on each statement", plus performants.

**🚀 Nouveautés**

- Sensibilité : Ajout d’un trigger sur la synthèse déclenchant
  automatiquement le calcul de la sensibilité des observations et
  calculant ensuite leur niveau de diffusion (si celui-ci est NULL) en
  fonction de la sensibilité (#413 et #871)
- Ajout du format GeoPackage (GPKG) pour les exports SIG, plus simple,
  plus léger, plus performant et unique que le SHAPEFILE. Les exports
  au format SHP restent pour le moment utilisés par défaut (modifiable
  dans la configuration des modules Occtax, Occhab et Synthèse)
  (#898)
- Performances : Suppression du trigger le plus lourd calculant les
  couleurs des taxons par unités géographiques. Il est remplacé par
  une vue utilisant le nouveau paramètre
  `gn_commons.t_parameters.occtaxmobile_area_type`, définissant le
  code du type de zonage à utiliser pour les unités géographiques dans
  Occtax-mobile (Mailles de 5km par défaut) (#997)
- Performances : Amélioration du trigger de la Synthèse calculant les
  zonages d’une observation en ne faisant un `ST_Touches()` seulement
  si l’observation n’est pas un point et en le passant
  `on each statement` (#716)
- Métadonnées : Refonte de la liste des CA et JDD avec l’ajout
  d’informations et d’actions, ainsi qu’une recherche avancée
  (#889)
- Métadonnées : Révision des fiches info des CA et JDD avec l’ajout
  d’actions, du tableau des imports et du téléchargement des rapports
  d’UUID et de sensibilité (#889)
- Métadonnées: Ajout de la fonctionnalité de fermeture (dépot) au
  niveau du CA (qui ferme tous les JDD du CA), seulement si le CA a au
  moins un JDD. Désactivée par défaut via le paramètre
  `ENABLE_CLOSE_AF` (#889 par \@alainlaupinmnhn)
- Métadonnées : Possibilité d’envoyer un email automatique au
  créateur et à l’utilisateur d’un CA quand celui-ci est fermé
  (#889)
- Métadonnées : Possibilité d’ajouter un titre spécifique aux exports
  PDF des CA quand ceux-ci sont fermés, par exemple pour en faire un
  certificat (#889)
- Métadonnées : Possibilité d’importer directement dans un JDD actif
  depuis le module Métadonnées, désactivé par défaut (#889)
- Métadonnées : Amélioration des possibilités de customisation des PDF
  des fiches de métadonnées
- Métadonnées : Amélioration des fiches détail des CA et JDD et ajout
  de la liste des imports dans les fiches des JDD (#889)
- Métadonnées : Ajout d’un spinner lors du chargement de la liste des
  métadonnées et parallélisation du calcul du nombre de données par
  JDD (#1231)
- Synthèse : Possibilité d’ouvrir le module avec un JDD
  préselectionné (`<URL_GeoNature>/#/synthese?id_dataset=2`) et ajout
  d’un lien direct depuis le module Métadonnées (#889)
- Synthèse : ajout de web service pour le calcul du nombre
  d’observations par un paramètre donné (JDD, module, observateur),
  et du calcul de la bounding-box par jeu de données
- Synthese : ajout d’un filtre avancé `Possède médias`
- Exports au format SHP remplacés par défaut par le format GeoPackage
  (GPKG) plus simple, plus léger, plus performant et unique. Les
  exports SHP restent activables dans la configuration des modules
  (#898)
- Occtax : ajout du paramètre `DISPLAY_VERNACULAR_NAME` qui contrôle
  l’affichage du nom vernaculaire vs nom complet sur les interfaces
  (Defaut = true: afffiche le nom vernaculaire)
- Validation : Préremplir l’email à l’observateur avec des
  informations paramétrables sur l’occurrence (date, nom du taxon,
  commune, médias) (#981)
- Validation : Possibilité de paramètrer les colonnes affichées dans
  la liste des observations (#980)
- Possibilité de customiser le logo principal (GeoNature par défaut)
  dans `frontend/src/custom/images/`
- Ajout d’un champs json `additional_data` dans la table `l_areas`
  (#1111)
- Complément des scripts de migration des données depuis GINCO
  (`data/scripts/import_ginco/`)
- Barre de navigation : Mention plus générique et générale des auteurs
  et contributeurs
- Redirection vers le formulaire d’authentification si on tente
  d’accéder à une page directement sans être authentifié et sans
  passer par le frontend (#1193)
- Connexion à MTD : possibilité de filtrer les JDD par instance, avec
  le paramètre `ID_INSTANCE_FILTER`, par exemple pour ne récupérer que
  les JDD de sa région (#1195)
- Connexion à MTD : récupération du créateur et des acteurs (#922,
  #1008 et #1196)
- Connexion à MTD : récupération du nouveau champs
  `statutDonneesSource` pour indiquer si le JDD est d’origine
  publique ou privée
- Création d’une commande GeoNature permettant de récupérer les JDD,
  CA et acteurs depuis le webservice MTD de l’INPN, en refactorisant
  les outils existants d’import depuis ce webservice
- Ajout de contraintes d’unicité sur certains champs des tables de
  métadonnées et de la table des sources (#1215)
- Création d’un script permettant de remplacer les règles de
  sensibilité nationales et régionales, par les règles départementales
  plus précises (`data/scripts/sensi/import_sensi_depobio.sh`),
  uniquement utilisé pour DEPOBIO pour le moment, en attendant de
  clarifier dans une prochaine release le fonctionnement que l’on
  retient par défaut dans GeoNature (#413)
- Création d’un script permettant d’importer les régions dans le
  référentiel géographique (`data/migrations/insert_reg.sh`)

**🐛 Corrections**

- Occhab : Export SIG (GPKG ou SHP) corrigé (#898)
- Meilleur nettoyage des sessions enregistrées dans le navigateur
  (#1178)
- Correction des droits CRUVED et de leur héritage (#1170)
- Synthèse : Retour du bouton pour revenir à l’observation dans son
  module d’origine (Occtax par exemple) depuis la fiche info d’une
  observation (#1147)
- Synthèse : Suppression du message "Aucun historique de validation"
  quand une observation n’a pas encore de validation (#1147)
- Synthèse : Correction du CRUVED sur le R = 1 (ajout des JDD de
  l’utilisateur)
- Synthèse : Correction de l’export des statuts basé sur une
  recherche géographique (#1203)
- Occtax : Correction de l’erreur de chargement de l’observateur
  lors de la modification d’un relevé (#1177)
- Occtax : Suppression de l’obligation de remplir les champs
  "Déterminateur" et "Méthode de détermination"
- Métadonnées : Suppression du graphique de répartition des espèces
  dans les exports PDF car il était partiellement fonctionnel
- Synthèse : Fonction `import_row_from_table`, test sur
  `LOWER(tbl_name)`
- Redirection vers le formulaire d’authentification si l’on essaie
  d’accéder à une URL sans être authentifié et sans passer par le
  frontend (#1193)
- Script d’installation globale : prise en compte du paramètre
  `install_grid_layer` permettant d’intégrer ou non les mailles dans
  le `ref_geo` lors de l’installation initiale (#1133)
- Synthèse : Changement de la longueur du champs `reference_biblio` de
  la table `gn_synthese.synthese` (de 255 à 5000 caractères)
- Sensibilité : Corrections des contraintes NOT VALID (#1245)

**⚠️ Notes de version**

Si vous mettez à jour GeoNature :

- Vous pouvez passer directement à cette version mais en suivant les
  notes des versions intermédiaires
- Exécuter ensuite le script SQL de mise à jour de la BDD de GeoNature
  (<https://github.com/PnX-SI/GeoNature/blob/master/data/migrations/2.5.5to2.6.0.sql>)
- Toutes les nouvelles données intégrées dans le Synthèse auront leur
  niveau de sensibilité et de diffusion calculés automatiquement. Vous
  pouvez ajouter ou désactiver des règles de sensibilité dans la table
  `gn_sensivity.t_sensitivity_rules`
- Vous pouvez aussi exécuter le script qui va calculer automatiquement
  le niveau de sensibilité et de diffusion de toutes les données déjà
  présentes dans la Synthèse, éventuellement en l’adaptant à votre
  contexte :
  <https://github.com/PnX-SI/GeoNature/blob/master/data/migrations/2.5.5to2.6.0-update-sensitivity.sql>
- Mettez à jour de la longueur du champs
  `gn_synthese.synthese.reference_biblio` à 5000 charactères. Exécutez
  la commande suivante dans la console :
  `sudo -u postgres psql -d geonature2db -c "UPDATE pg_attribute SET atttypmod = 5004 WHERE attrelid = 'gn_synthese.synthese'::regclass AND attname = 'reference_biblio';"`
- Exécuter le script de mise à jour de la BDD du sous-module de
  nomenclature :
  <https://github.com/PnX-SI/Nomenclature-api-module/blob/master/data/update1.3.4to1.3.5.sql>
- Suivez la procédure classique de mise à jour de GeoNature
  (<http://docs.geonature.fr/installation-standalone.html#mise-a-jour-de-l-application>)
- Si vous utilisez Occtax-mobile, vous pouvez modifier la valeur du
  nouveau paramètre `gn_commons.t_parameters.occtaxmobile_area_type`
  pour lui indiquer le code du type de zonage que vous utilisez pour
  les unités géographiques (mailles de 5km par défaut)
- Si vous disposez du module d’import, vous devez le mettre à jour en
  version 1.1.1

## 2.5.5 (2020-11-19)

**🚀 Nouveautés**

- Ajout d’un composant fil d’ariane (#1143)
- Ajout de la possiblité de désactiver les composants `pnx-taxa` et
  `pnx-areas` (#1142)
- Ajout de tests sur les routes pour assurer la compatibilité avec les
  applications mobiles

**🐛 Corrections**

- Correction d’un bug de récupération du CRUVED sur les modules
  (#1146)
- Correction des validateurs sur les preuves d’existence (#1134)
- Correction de la récupération des dossiers dans `backend/static`
  dans le script `migrate.sh`
- Correction de l’affichage de l’utilisateur dans la navbar
  lorsqu’on est connecté via le CAS INPN

## 2.5.4 (2020-11-17)

**🚀 Nouveautés**

- Ajout de scripts `sql` et `sh` de restauration des medias dans
  `data/medias` (#1148)
- Ajout d’un service pour pouvoir récupérer les informations sur
  l’utilisateur connecté

**🐛 Corrections**

- Correction des médias qui sont actuellement tous supprimés
  automatiquement après 24h, et non pas seulement ceux orphelins
  (#1148)
- Correction des permissions sur les fiches info des relevés dans
  Occtax avec la désactivation du bouton de modification du relevé
  quand l’utilisateur n’en a pas les droits

**⚠️ Notes de version**

- Si vous aviez associé des médias à des observations dans Occtax ou
  autre et qu’ils ont été supprimés, vous pouvez les retrouver dans
  la table d’historisation des actions
  (`SELECT * FROM gn_commons.t_history_actions WHERE table_content->'id_media' IS NOT NULL AND operation_type = 'D'`)
- Pour restaurer les médias supprimés depuis la table
  `gn_commons.t_history_actions` vous pouvez :
  - exécuter le script SQL `data/medias/restore_medias.sql` qui va
    recréer les médias supprimés dans la table `gn_commons.t_medias`
  - exécuter le script BASH `data/medias/restore_medias.sh`
    (`` bash /home/`whoami`/geonature/data/medias/restore_medias.sh ``
    en `sudo` si besoin) qui va renommer des fichiers supprimés en
    supprimant le préfixe `deleted_`

## 2.5.3 (2020-11-04)

**🚀 Nouveautés**

- Mise en place de l’héritage du CRUVED au niveau des objets des
  modules (#1028)
- Révision de l’export des observations de la Synthèse (noms plus
  lisibles, ajout des communes et d’informations taxonomiques,
  complément des champs existants (#755)
- Ajout d’un paramètre permettant d’ajouter un message personnalisé
  à la fin des emails (inscriptions, exports\...) (#1050
  par \@jpm-cbna)
- Ajout d’une alerte de dépréciation sur les fonctions
  `utils-sqlalchemy` présentes dans GeoNature
- Ajout d’un widget de type "HTML" dans les formulaires dynamiques,
  permettant d’ajouter des informations dans un formulaire (#1043 et
  #1068 par \@jpm-cbna)
- Ajout de la possibilité d’ajouter un texte d’aide sur les champs
  des formulaires dynamiques (#1065 par \@jpm-cbna)
- Ajout de la possibilité de définir un min et un max au composant
  commun `date` (#1069 par \@jpm-cbna)
- Ajout de la possibilité de définir le nombre de lignes du composant
  commun `textarea` (#1067 par \@jpm-cbna)
- Ajout de la possibilité de contrôler par une expression régulière le
  contenu d’un champs de type `text` des formulaires dynamiques
  (#1073 par \@FlorentRICHARD44)
- Ajout de la possibilité de masquer certains champs du composant
  `media` (#1072, #1078 et #1083 par \@metourneau)
- Ajout d’un spinner sur les statistiques de la page d’accueil
  (#1086 par \@jpm-cbna)
- Ajout d’un composant d’autocomplete multiselect `pnx-taxa`
  permettant de rechercher des taxons dans tout l’arbre taxonomique
  et de limiter la recherche à un rang
- Possibilité d’ajouter plusieurs cartes sur la même page à l’aide
  du composant `pnx-map`
- Homogénéisation du style du code et documentation des pratiques de
  développement

**🐛 Corrections**

- Correction de l’affichage des noms des validateurs sur la liste
  dans le module validation (#1091 par \@lpofredc)
- Corrections mineures de l’export des observations de la Synthèse
  (#1108)
- Synthèse : Correction du masquage de la recherche par arbre
  taxonomique (#1057 par \@jpm-cbna)
- Ajout du champs `id_nomenclature_biogeo_status` dans la Synthese
  (correspondance standard : statut biogéographique). La BDD est
  remplie avec la valeur par défaut de la table
  `gn_synthese.default_nomenclature_value` (valeur = non renseignée)
- Accueil : Correction de l’affichage du nom du module (#1087)
- Correction du trigger de mise à jour d’Occtax vers la Synthèse
  (champs `the_geom_local` non mis à jour) (#1117 par \@jbrieuclp)
- Correction du paramètre stockant la version de Taxref, passé à 13.0
  pour les nouvelles installations (#1097 par \@RomainBaghi)
- Correction de l’affichage en double des markers dans Leaflet.draw
  (#1095 par \@FlorentRICHARD44)
- Synthèse : Correction des filtres avancés par technique
  d’observation et méthode de détermination (#1110 par \@jbrieuclp)
- Recréation du fichier de configuration à chaque installation (#1074
  par \@etot)
- Annulation de l’insertion du module lorsqu’une erreur est levée à
  l’installation d’un module

**⚠️ Notes de version**

- Désormais les objets des modules (par exemple les objets
  ’Permissions’ et ’Nomenclatures’ du module ’ADMIN’) héritent
  automatiquement des permissions définies au niveau du module parent
  et à défaut au niveau de GeoNature (#1028). Il s’agit d’une
  évolution de mise en cohérence puisque les modules héritaient déjà
  des permissions de GeoNature, mais pas leurs objets. Si vous avez
  défini des permissions particulières aux niveaux des objets,
  vérifier leur cohérence avec le nouveau fonctionnement. NB : si vous
  aviez mis des droits R=0 pour un groupe au module ’ADMIN’, les
  utilisateurs de ce groupe ne pourront pas accéder aux sous-modules
  ’permissions’ et ’nomenclatures’.
- Exécuter ensuite le script SQL de mise à jour de la BDD de GeoNature
  (<https://github.com/PnX-SI/GeoNature/blob/master/data/migrations/2.5.2to2.5.3.sql>).
  Attention, si vous avez customisé les vues des exports Occtax et
  Synthèse, elles seront supprimées et recrées automatiquement par le
  script SQL de mise à jour de la BDD de GeoNature pour intégrer leurs
  évolutions réalisées dans cette nouvelle version. Révisez
  éventuellement ces vues avant et/ou après la mise à jour.
- Suivez la procédure classique de mise à jour de GeoNature
  (<http://docs.geonature.fr/installation-standalone.html#mise-a-jour-de-l-application>).
- Les noms de colonnes de l’export de la Synthèse ont été entièrement
  revus dans la vue fournie par défaut
  (`gn_synthese.v_synthese_for_export`). Si vous aviez surcouché le
  paramètre `EXPORT_COLUMNS` dans le fichier
  `config/geonature_config.toml`, vérifiez les noms des colonnes.
- Vérifiez que la valeur du paramètre `taxref_version` dans la table
  `gn_commons.t_parameters` correspond bien à votre version actuelle
  de Taxref (11.0 ou 13.0).

## 2.5.2 (2020-10-13)

**🐛 Corrections**

- Occtax : correction du problème d’installation du module dans le
  fichier `schemas.py`
- Synthese : correction de la fonctions SQL
  `gn_synthese.import_row_from_table` et répercussion dans le fichier
  `gn_synthese/process.py`

**⚠️ Notes de version**

Si vous mettez à jour GeoNature :

- Vous pouvez passer directement à cette version mais en suivant les
  notes des versions intermédiaires
- Exécuter ensuite le script SQL de mise à jour de la BDD de GeoNature
  (<https://github.com/PnX-SI/GeoNature/blob/master/data/migrations/2.5.1to2.5.2.sql>)

## 2.5.1 (2020-10-06)

**🐛 Corrections**

- Ajout d’un paramètre `DISPLAY_EMAIL_INFO_OBS` définissant si les
  adresses email des observateurs sont affichées ou non dans les
  fiches info des observations des modules Synthèse et Validation
  (#1066)
- Occtax : correction de l’affichage du champs "Technique de
  collecte Campanule" (#1059)
- Occtax : correction du fichier d’exemple de configuration
  `contrib/occtax/config/conf_gn_module.toml.example` (#1059)
- Occtax : paramètre `DISPLAY_SETTINGS_TOOLS` renommé
  `ENABLE_SETTINGS_TOOLS` et désactivé par défaut (#1060)
- Occtax : quand le paramètre `ENABLE_SETTINGS_TOOLS` est désactivé,
  remise en place du fonctionnement de l’outil "Echainer les
  relevés". Dans ce cas, quand on enchaine les relevés, on conserve
  le JDD, les observateurs, les dates et heures d’un relevé à
  l’autre (#1060)
- Occtax : correction de l’observateur par défaut en mode
  `observers_as_txt`
- Verification des UUID : autoriser toutes les versions (#1063)

**⚠️ Notes de version**

Si vous mettez à jour GeoNature :

- Vous pouvez passer directement à cette version mais en suivant les
  notes des versions intermédiaires

## 2.5.0 - Manidae (2020-09-30)

Occtax v2 et médias

**🚀 Nouveautés**

- Refonte de l’ergonomie et du fonctionnement du module de saisie
  Occtax (#758 et #860 par \@jbrieuclp et \@TheoLechemia)
  - Enregistrement continu au fur et à mesure de la saisie d’un
    relevé
  - Découpage en 2 onglets (Un pour le relevé et un onglet pour les
    taxons)
  - Amélioration de la liste des taxons saisis sur un relevé (#635
    et #682)
  - Amélioration de la saisie au clavier
  - Zoom réalisé dans la liste des relevé conservé quand on saisit
    un nouveau relevé (#436 et #912)
  - Filtres conservés quand on revient à la liste des relevés
    (#772)
  - Possibilité de conserver les informations saisies entre 2 taxons
    ou relevés, désactivable avec le paramètre
    `DISPLAY_SETTINGS_TOOLS` (#692)
  - Correction de la mise à jour des dates de début et de fin
    (#977)
  - Affichage d’une alerte si on saisit 2 fois le même taxon sur un
    même relevé
  - Fiche d’information d’un relevé complétée et mise à jour
- Passage de la version 1.2.1 à la version 2.0.0 du standard
  Occurrences de taxon (dans les modules Occtax, Synthèse et
  Validation) (#516)
  - Ajout des champs "Comportement", "NomLieu", "Habitat",
    "Méthode de regroupement", "Type de regroupement" et
    "Profondeur"
  - Ajout du champs "Précision" dans Occtax et suppression de sa
    valeur par défaut à 100 m
  - Renommage du champs "Méthode d’observation" en "Technique
    d’observation"
  - Suppression du champs "Technique d’observation" actuel de la
    synthèse
  - Renommage du champs "Technique d’observation" actuel
    d’Occtax en "Technique de collecte Campanule"
  - Ajout et mise à jour de quelques nomenclatures
  - Ajout d’un document de suivi de l’implémentation du standard
    Occurrences de taxon dans GeoNature
    (`docs/implementation_gn_standard_occtax2.0.ods`) (#516)
- Passage de la version 1.3.9 à la version 1.3.10 du standard de
  Métadonnées. Mise à jour des nomenclatures "CA_OBJECTIFS" et mise
  à jour des métadonnées existantes en conséquence
  (par \@DonovanMaillard)
- Ajout d’un champs `addtional_data` de type `jsonb` dans la table
  `gn_synthese.synthese`, en prévision de l’ajout des champs
  additionnels dans Occtax et Synthèse (#1007)
- Mise en place de la gestion transversale et générique des médias
  (images, audios, vidéos, PDF\...) dans `gn_commons.t_medias` et le
  Dynamic-Form (#336) et implémentation dans le module Occtax
  (désactivables avec le paramètre `ENABLE_MEDIAS`) (#620
  par \@joelclems)
- Mise en place de miniatures et d’aperçus des médias, ainsi que de
  nombreux contrôles des fichiers et de leurs formats
- Affichage des médias dans les fiches d’information des modules de
  saisie, ainsi que dans les modules Synthèse et Validation
- Ajout de la fonctionnalité "Mes lieux" (`gn_commons.t_places`),
  permettant de stocker la géométrie de ieux individuels fréquemment
  utilisés, implémentée dans le module cartographique d’Occtax
  (désactivable avec le paramètre `ENABLE_MY_PLACES`) (#246
  par \@metourneau)
- Tri de l’ordre des modules dans le menu latéral par ordre
  alphabétique par défaut et possibilité de les ordonner avec le
  nouveau champs `gn_commons.t_modules.module_order` (#787
  par \@alainlaupinmnhn)
- Arrêt du support de l’installation packagée sur Debian 9 et Ubuntu
  16 pour passer à Python version 3.6 et plus
- Prise en charge de PostGIS 3 et notamment l’installation de
  l’extension `postgis_raster` (#946 par \@jpm-cbna)
- Création de compte : Envoi automatique d’un email à l’utilisateur
  quand son compte est validé. Nécessite la version 2.1.3 de UsersHub
  (#862 et #1035 par \@jpm-cbna)

**Ajouts mineurs**

- Homogénéisation des styles des boutons (#1026)
- Factorisation du code des fiches infos d’une observation dans les
  modules Synthèse et Validation (#1053)
- Métadonnées : Ajout d’un paramètre permettant de définir le nombre
  de CA affichés sur la page (100 par défaut)
- Métadonnées : Tri des CA et JDD par ordre alphabétique
- Métadonnées : Ajout d’un champs `id_digitiser` dans la table des CA
  et des JDD, utilisé en plus des acteurs pour le CRUVED des JDD
  (#921)
- Dynamic-Form : Ajout d’un composant "select" prenant une API en
  entrée (#1029)
- Dynamic-Form : Ajout de la possibilité d’afficher une définition
  d’un champs sous forme de tooltip
- CAS INPN : Redirection vers la page de connexion de GeoNature quand
  on se déconnecte
- Ajout d’une contrainte d’unicité sur `schema_name` et `table_name`
  sur la table `gn_commons_bib_tables_location_unique` (#962)
- Ajout d’une contrainte d’unicité sur `id_organism` et
  `parameter_name` dans la table `gn_commons.t_parameters` (#988)
- Ajout de la possibilité de filtrer le composant `dataset` du
  Dynamic-Form par `module_code` pour pouvoir choisir parmis les JDD
  associées à un module (#964)
- Mise à jour de `psycopg2` en version 2.8.5, sqlalchemy en 1.3.19,
  marshmallow en 2.15.6, virtualenv en 20.0.31 (par \@jpm-cbna)
- Mises à jour de sécurité diverses
- Améliorations des scripts `install/install_db.sh` et
  `install/install_app.sh` (par \@jpm-cbna)
- Ajout de l’autocomplétion des commandes `geonature` (#999
  par \@jpm-cbna)
- Suppression du fichier `backend/gunicorn_start.sh.sample`
- Amélioration du script `install/migration/migration.sh` en vérifiant
  la présence des dossiers optionnels avant de les copier
- Amélioration des fonctions
  `gn_synthese.import_json_row_format_insert_data` et
  `gn_synthese.import_json_row` pour prendre en charge la génération
  des geojson dans PostGIS 3
- Documentation administrateur : Précisions sur les labels, pictos et
  ordres des modules dans le menu de navigation latéral

**🐛 Corrections**

- Module Validation : Affichage des commentaires du relevé et de
  l’observation (#978 et #854)
- Module Validation : Ne lister que les observations ayant un UUID et
  vérification de sa validité (#936)
- Module Validation : Correction et homogénéisation de l’affichage et
  du tri des observations par date (#971)
- Module Validation : Correction de l’affichage du statut de
  validation après mise à jour dans la liste des observations (#831)
- Module Validation : Correction de l’affichage du nom du validateur
- Module Validation : Amélioration des performances avec l’ajout
  d’un index sur le champs `uuid_attached_row` de la table
  `gn_commons.t_validations` (#923 par \@jbdesbas)
- Suppression du trigger en double
  `tri_insert_synthese_cor_role_releves_occtax` sur
  `pr_occtax.cor_role_releves_occtax` (#762 par \@jbrieuclp)
- Passage des requêtes d’export de la synthèse en POST plutôt qu’en
  GET (#883)
- Correction du traitement du paramètre `offset` de la route
  `synthese/color_taxon` utilisé par Occtax-mobile (#994)
- Correction et complément des scripts de migration de données depuis
  GINCO v1 (`data/scripts/import_ginco/occtax.sql`)
- Import des utilisateurs depuis le CAS INPN : Activer les
  utilisateurs importés par défaut et récupérer leur email
- Calcul automatique de la sensibilité : Ajout de la récursivité dans
  la récupération des critères de sensibilité au niveau de la fonction
  `gn_sensitivity.get_id_nomenclature_sensitivity` (#284)
- Typo sur le terme "Preuve d’existence" (par \@RomainBaghi)

**⚠️ Notes de version**

Si vous mettez à jour GeoNature :

- Nomenclatures : Commencer par exécuter le script SQL de mise à jour
  du schéma `ref_nomenclatures` de la BDD
  (<https://github.com/PnX-SI/Nomenclature-api-module/blob/master/data/update1.3.3to1.3.4.sql>)
- Exécuter ensuite le script SQL de mise à jour de la BDD de GeoNature
  (<https://github.com/PnX-SI/GeoNature/blob/master/data/migrations/2.4.1to2.5.0.sql>).
  Attention, si vous avez customisé les vues des exports Occtax et
  Synthèse, elles seront supprimées et recrées automatiquement par le
  script SQL de mise à jour de la BDD de GeoNature pour s’adapter aux
  évolutions du standard Occtax en version 2.0.0. Révisez
  éventuellement ces vues avant et/ou après la mise à jour. Le script
  SQL de mise à jour vérifiera aussi si vous avez d’autres vues (dans
  le module Export notamment) qui utilisent le champs
  `id_nomenclature_obs_technique` qui doit être renommé et
  l’indiquera dès le début de l’exécution du script, en l’arrêtant
  pour que vous puissiez modifier ou supprimer ces vues bloquant la
  mise à jour.
- Les colonnes de l’export de la Synthèse ont été partiellement revus
  dans la vue fournie par défaut
  (`gn_synthese.v_synthese_for_export`). Si vous aviez surcouché le
  paramètre `EXPORT_COLUMNS` dans le fichier
  `config/geonature_config.toml`, vérifiez les noms des colonnes.
- A partir la version 2.5.0 de GeoNature, la version 3.5 de Python
  n’est plus supportée. Seules les versions 3.6 et + le sont. Si vous
  êtes encore sur Debian 9 (fourni par défaut avec Python 3.5),
  veuillez suivre les instructions de mise à jour de Python sur cette
  version
  (<https://github.com/PnX-SI/GeoNature/blob/master/docs/installation-standalone.rst#python-37-sur-debian-9>).
  Il est cependant plutôt conseillé de passer sur Debian 10 pour
  rester à jour sur des versions maintenues
- Suivez la procédure classique de mise à jour de GeoNature
  (<http://docs.geonature.fr/installation-standalone.html#mise-a-jour-de-l-application>)
- A noter, quelques changements dans les paramètres du module Occtax.
  Les paramètres d’affichage/masquage des champs du formulaire ont
  évolué ainsi :
  - `obs_meth` devient `obs_tech`
  - `obs_technique` devient `tech_collect`
- A noter aussi que cette version de GeoNature est compatible avec la
  version 1.1.0 minimum d’Occtax-mobile (du fait de la mise du
  standard Occurrence de taxons)

## 2.4.1 (2020-06-25)

**🚀 Nouveautés**

- Occurrences sans géométrie précise : Ajout d’un champs
  `id_area_attachment` dans la table `gn_synthese.synthese` permettant
  d’associer une observation à un zonage dans le référentiel
  géographique (`ref_geo.l_areas.id_area`) (#845 et #867)
- Ajout d’un champs `geojson_4326` dans la table `ref_geo.l_areas`
  pour pouvoir afficher les zonages du référentiel géographique sur
  les cartes (#867)
- Ajout de l’import par défaut des départements de France métropole
  dans le référentiel géographique lors de l’installation de
  GeoNature (en plus des actuelles communes et grilles)
- Mise à jour des communes importées sur la version de février 2020
  d’Admin express IGN pour les nouvelles installations

**🐛 Corrections**

- Correction d’un bug d’affichage des fonds de carte WMTS de l’IGN,
  apparu dans la version 2.4.0 avec l’ajout du support des fonds WMS
  (#890)
- Gestion des exceptions de type `FileNotFoundError` lors de l’import
  des commandes d’un module

**⚠️ Notes de version**

Si vous mettez à jour GeoNature :

- Vous pouvez passer directement à cette version mais en suivant les
  notes des versions intermédiaires
- Exécuter le script SQL de mise à jour de la BDD de GeoNature :
  <https://github.com/PnX-SI/GeoNature/blob/master/data/migrations/2.4.0to2.4.1.sql>
- Suivez la procédure classique de mise à jour de GeoNature
  (<http://docs.geonature.fr/installation-standalone.html#mise-a-jour-de-l-application>)
- Vous pouvez alors lancer le script d’insertion des départements de
  France métropole dans le réferentiel géographique (optionnel) :
  <https://github.com/PnX-SI/GeoNature/blob/master/data/migrations/2.4.0to2.4.1_insert_departments.sh>.
  Vérifier le déroulement de l’import dans le fichier
  `var/log/insert_departements.log`

## 2.4.0 - Fiches de métadonnées (2020-06-22)

**🚀 Nouveautés**

- Métadonnées : Ajout d’une fiche pour chaque jeu de données et
  cadres d’acquisition, incluant une carte de l’étendue des
  observations et un graphique de répartition des taxons par Groupe
  INPN (#846 par \@FloVollmer)
- Métadonnées : Possibilité d’exporter les fiches des JDD et des CA
  en PDF, générés par le serveur avec WeasyPrint. Logo et entêtes
  modifiables dans le dossier `backend/static/images/` (#882
  par \@FloVollmer)
- Métadonnées : Implémentation du CRUVED sur la liste des CA et JDD
  (#911)
- Métadonnées : Affichage de tous les CA des JDD pour lequels
  l’utilisateur connecté a des droits (#908)
- Compatible avec TaxHub 1.7.0 qui inclut notamment la migration
  (optionnelle) vers Taxref version 13
- Installation globale migrée de Taxref version 11 à 13
- Synthèse et zonages : Ne pas inclure l’association aux zonages
  limitrophes d’une observation quand sa géométrie est égale à un
  zonage (maille, commune\...) (#716 par \@jbdesbas)
- Synthèse : Ajout de la possibilité d’activer la recherche par
  observateur à travers une liste, avec ajout des paramètres
  `SEARCH_OBSERVER_WITH_LIST` (`False` par défaut) et
  `ID_SEARCH_OBSERVER_LIST` (#834 par \@jbrieuclp)
- Synthèse : Amélioration de la recherche des observateurs. Non prise
  en compte de l’ordre des noms saisis (#834 par \@jbrieuclp)
- Synthèse : Ajout de filtres avancés (`Saisie par` basé sur
  `id_digitiser`, `Commentaire` du relevé et de l’occurrence,
  `Déterminateur`) (#834 par \@jbrieuclp)
- Occtax : Création d’un trigger générique de calcul de l’altitude
  qui n’est exécuté que si l’altitude n’est pas postée (#848)
- Ajout d’une table `gn_commons.t_mobile_apps` permettant de lister
  les applications mobiles, l’URL de leur APK et d’une API pour
  interroger le contenu de cette table. Les fichiers des applications
  et leurs fichiers de configurations peuvent être chargés dans le
  dossier `backend/static/mobile` (#852)
- Ajout d’un offset et d’une limite sur la route de la couleur des
  taxons (utilisée uniquement par Occtax-mobile actuellement)
- Support des fonds de carte au format WMS
  (<https://leafletjs.com/reference-1.6.0.html#tilelayer-wms-l-tilelayer-wms>),
  (#890 par \@jbdesbas)
- Ajout d’un champs texte `reference_biblio` dans la table
  `gn_synthese`
- Amélioration des perfomances du module de validation, en revoyant la
  vue `gn_commons.v_synthese_validation_forwebapp`, en revoyant les
  requêtes et en générant le GeoJSON au niveau de la BDD (#923)
- Ajout d’une fonction SQL d’insertion de données dans la synthese
  (et une fonction python associée)
- Compléments de la documentation (Permissions des utilisateurs,
  Occhab\...)
- Ajout de scripts de migration des données de GINCO1 vers GeoNature
  (`data/scripts/import_ginco`)
- Trigger Occtax vers Synthèse : Amélioration du formatage des heures
  avec `date_trunc()` dans la fonction
  `pr_occtax.insert_in_synthese()` (#896 par \@jbdesbas)
- Barre de navigation : Clarification de l’icône d’ouverture du
  menu, ajout d’un paramètre `LOGO_STRUCTURE_FILE` permettant de
  changer le nom du fichier du logo de l’application (#897
  par \@jbrieuclp)
- Médias : Amélioration des fonctions backend
- Mise à jour de jQuery en version 3.5.0
- Suppression de la table `gn_synthese.taxons_synthese_autocomplete`
  et du trigger sur la Synthèse qui la remplissait pour utiliser la
  vue matérialisée `taxonomie.vm_taxref_list_forautocomplete` listant
  les noms de recherche de tous les taxons de Taxref, entièrement
  revue dans TaxHub 1.7.0
- Monitoring : Correction du backend pour utiliser la nouvelle syntaxe
  de jointure des tables
- Ajout de fonctions SQL d’insertion de données dans la Synthèse
  (`gn_synthese.import_json_row()` et
  `gn_synthese.import_row_from_table()`) et de la fonction Python
  associée
  (`import_from_table(schema_name, table_name, field_name, value)`)
  pour l’API permettant de poster dans la Synthèse (#736). Utilisée
  par le module Monitoring.
- Ajout du plugin Leaflet.Deflate (#934 par \@jpm-cbna)
- Connexion au CAS INPN : Association des JDD aux modules Occtax et
  Occhab (paramétrable) quand on importe les JDD de l’utilisateur qui
  se connecte (dans la table `gn_commons.cor_module_dataset`)
- Mise à jour des librairies Python Utils-Flask-SQLAlchemy (en version
  0.1.1) et Utils-Flask-SQLAlchemy-Geo (en version 0.1.0) permettant
  de mettre en place les exports au format GeoPackage et corrigeant
  les exports de SHP contenant des géométries multiples

**🐛 Corrections**

- Mise à jour des URL de la documentation utilisateur des modules,
  renvoyant vers <http://docs.geonature.fr>
- Validation : Correction de l’ouverture de la fiche d’information
  d’une observation (#858)
- Modification de l’attribution de la hauteur du composant
  `map-container` pour permettre d’adapter la hauteur de la carte si
  la hauteur d’un conteneur parent est modifié. Et que
  `<pnx-map height="100%">` fonctionne (#844 par \@jbrieuclp)
- Mise à jour de la librairie python Markupsafe en version 1.1,
  corrigeant un problème de setuptools (#881)
- Page Maintenance : Correction de l’affichage de l’image
  (par \@jpm-cbna)
- Correction du multiselect du composant `pnx-nomenclatures` (#885
  par \@jpm-cbna)
- Correction de l’`input('coordinates')` du composant `marker` (#901
  par \@jbrieuclp)
- Utilisation de NVM quand on installe les dépendances javascript
  (#926 par \@jpm-cbna)
- Formulaire JDD : Correction de l’affichage de la liste des modules
  (#861)
- Correction de l’utilisation des paramètres du proxy (#944)

**⚠️ Notes de version**

Si vous mettez à jour GeoNature.

- Vous devez d’abord mettre à jour TaxHub en version 1.7.0
- Si vous mettez à jour TaxHub, vous pouvez mettre à jour Taxref en
  version 13. Il est aussi possible de le faire en différé, plus tard
- Vous pouvez mettre à jour UsersHub en version 2.1.2
- Exécuter le script SQL de mise à jour des nomenclatures
  (<https://github.com/PnX-SI/Nomenclature-api-module/blob/master/data/update1.3.2to1.3.3.sql>).
- Si vous avez mis à jour Taxref en version 13, répercutez les
  évolutions au niveau des nomenclatures avec le script SQL
  <https://github.com/PnX-SI/Nomenclature-api-module/blob/master/data/update_taxref_v13.sql>.
  Sinon vous devrez l’exécuter plus tard, après avoir mis à jour
  Taxref en version 13. Après avoir mis à jour Taxref en version 13,
  pensez à mettre à jour le paramètre `taxref_version` dans la table
  `gn_commons.t_parameters`.
- Exécuter le script SQL de mise à jour de la BDD de GeoNature
  (<https://github.com/PnX-SI/GeoNature/blob/master/data/migrations/2.3.2to2.4.0.sql>)
- Installer les dépendances de la librairie Python WeasyPrint :

  ```bash
  sudo apt-get install -y libcairo2
  sudo apt-get install -y libpango-1.0-0
  sudo apt-get install -y libpangocairo-1.0-0
  sudo apt-get install -y libgdk-pixbuf2.0-0
  sudo apt-get install -y libffi-dev
  sudo apt-get install -y shared-mime-info
  ```

- Corriger l’utilisation des paramètres du proxy (#944) dans le
  fichier `backend/gunicorn_start.sh` en remplaçant les 2 lignes :

  ```bash
  export HTTP_PROXY="'$proxy_http'"
  export HTTPS_PROXY="'$proxy_https'"
  ```

  par :

  ```bash
  # Activation de la configuration des proxy si necessaire
  [[ -z "$proxy_http" ]] || export HTTP_PROXY="'$proxy_http'"
  [[ -z "$proxy_https" ]] || export HTTPS_PROXY="'$proxy_https'"
  ```

- Vous pouvez supprimer les associations des observations de la
  synthèse aux zonages limitrophes, si vous n’avez pas
  d’observations sans géométrie (#719) :

  ```sql
  DELETE FROM gn_synthese.cor_area_synthese cas
  USING gn_synthese.synthese s, ref_geo.l_areas a
  WHERE cas.id_synthese = s.id_synthese AND a.id_area = cas.id_area
  AND public.ST_TOUCHES(s.the_geom_local,a.geom);
  ```

- Suivez ensuite la procédure classique de mise à jour de GeoNature
  (<http://docs.geonature.fr/installation-standalone.html#mise-a-jour-de-l-application>)

## 2.3.2 (2020-02-24)

**🚀 Nouveautés**

- Possibilité de charger les commandes d’un module dans les commandes
  de GeoNature
- Ajout de commentaires dans le fichier d’exemple de configuration
  `config/default_config.toml.example`

**🐛 Corrections**

- Correction d’une incohérence dans le décompte des JDD sur la page
  d’accueil en leur appliquant le CRUVED (#752)
- Montée de version de la librairie `utils-flask-sqlalchemy-geo` pour
  compatibilité avec la version 1.0.0 du module d’export

## 2.3.1 (2020-02-18)

**🚀 Nouveautés**

- Installation globale : Compatibilité Debian 10 (PostgreSQL 11,
  PostGIS 2.5)
- Installation globale : Passage à Taxhub 1.6.4 et UsersHub 2.1.1
- Utilisation généralisée des nouvelles librairies externalisées de
  sérialisation (<https://github.com/PnX-SI/Utils-Flask-SQLAlchemy> et
  <https://github.com/PnX-SI/Utils-Flask-SQLAlchemy-Geo>)
- Possibilité de régler le timeout de Gunicorn pour éviter le plantage
  lors de requêtes longues
- Ne pas zoomer sur les observations au premier chargement de la carte
  (#838)
- Leaflet-draw : Ajout de la possibilité de zoomer sur le point
  (par \@joelclems)
- Ajout du nom vernaculaire dans les fiches d’information des relevés
  d’Occtax (par \@FloVollmer / #826)

**🐛 Corrections**

- Correction de l’installation de Node.js et npm par l’utilisation
  généralisée de nvm (#832 et #837)
- Fixation de la version de Node.js en 10.15.3 (dans le fichier
  `fronted/.nvmrc`)
- Ajout d’une référence de l’objet Leaflet `L` afin qu’il soit
  utilisé dans les modules et changement du typage de l’évenement
  Leaflet `MouseEvent` en `L.LeafletMouseEvent`
- Fixation de la version de vitualenv en 20.0.1 (par \@sogalgeeko)
- Corrections de typos dans la documentation d’administration
  (#840 - par \@sogalgeeko)

**⚠️ Notes de version**

- Vous pouvez passer directement à cette version depuis la 2.2.x, mais
  en suivant les notes des versions intermédiaires (NB : il n’est pas
  nécessaire d'exécuter le script `migrate.sh` des versions
  précédentes)

- Installez `pip3` et `virtualenv`:

      sudo apt-get update
      sudo apt-get install python3-pip
      sudo pip3 install virtualenv==20.0.1

- Rajoutez la ligne `gun_timeout=30` au fichier `config/settings.ini`
  puis rechargez supervisor (`sudo supervisorctl reload`). Il s’agit
  du temps maximal (en seconde) autorisé pour chaque requête. A
  augmenter, si vous avez déjà rencontré des problèmes de timeout.

- Depuis le répertoire `frontend`, lancez la commande `nvm install`

## 2.3.0 - Occhab de Noël (2019-12-27)

**🚀 Nouveautés**

- Développement du module Occhab (Occurrences d’habitats) basé sur
  une version minimale du standard SINP du même nom et s’appuyant sur
  le référentiel Habref du SINP (#735)
  - Consultation (carte-liste) des stations et affichage de leurs
    habitats
  - Recherche (et export) des stations par jeu de données, habitats
    ou dates
  - Saisie d’une station et de ses habitats
  - Possibilité de saisir plusieurs habitats par station
  - Saisie des habitats basée sur une liste pré-définie à partir
    d’Habref. Possibilité d’intégrer toutes les typologies
    d’habitat ou de faire des listes réduites d’habitats
  - Possibilité de charger un fichier GeoJson, KML ou GPX sur la
    carte et d’utiliser un de ses objets comme géométrie de station
  - Mise en place d’une API Occhab (Get, Post, Delete, Export
    stations et habitats et récupérer les valeurs par défaut des
    nomenclatures)
  - Calcul automatique des altitudes (min/max) et de la surface
    d’une station
  - Gestion des droits (en fonction du CRUVED de l’utilisateur
    connecté)
  - Définition des valeurs par défaut dans la BDD (paramétrable par
    organisme)
  - Possibilité de masquer des champs du formulaire
- Création d’un sous-module autonome ou intégré pour gérer l’API
  d’Habref (<https://github.com/PnX-SI/Habref-api-module>) pour :
  - Rechercher un habitat dans Habref (avec usage du trigramme pour
    la pertinence du résultat)
  - Obtenir les infos d’un habitat et de ses correspondances à
    partir de son cd_hab
  - Obtenir les habitats d’une liste (avec ou sans leur code en
    plus de leur nom et filtrable par typologie)
  - Obtenir la liste des typologies (filtrable par liste
    d’habitats)
- Mise à jour du module des nomenclatures
  (<https://github.com/PnX-SI/Nomenclature-api-module>) en version
  1.3.2 incluant notamment :
  - Ajout de nomenclatures SINP concernant les habitats
  - Ajout d’une contrainte d’unicité sur la combinaison des champs
    `id_type` et `cd_nomenclature` de la table `t_nomenclatures`
- Association des JDD à des modules pour filtrer les JDD utilisés dans
  Occtax ou dans Occhab notamment (#399)
- Mise à jour de Angular 4 à Angular 7 (performances, \....) par
  \@jbrieuclp
- Ajout d’une documentation utilisateur pour le module Synthèse :
  <http://docs.geonature.fr/user-manual.html#synthese>
  (par \@amandine-sahl)
- OCCTAX : Amélioration importante des performances de la liste des
  relevés (par \@jbrieuclp) (#690, #740)
- Améliorations des performances des exports de Occtax et de Synthèse
  et ajout d’index dans Occtax (par \@gildeluermoz) (#560)
- Partage de scripts de sauvegarde de l’application et de la BDD dans
  `data/scripts/backup/` (par \@gildeluermoz)
- Externalisation des librairies d’outils Flask et SQLAlchemy
  (<https://github.com/PnX-SI/Utils-Flask-SQLAlchemy> et
  <https://github.com/PnX-SI/Utils-Flask-SQLAlchemy-Geo>) pour pouvoir
  les factoriser et les utiliser dans d’autres applications. Cela
  améliore aussi les performances des jointures.
- SYNTHESE : Ajout d’un export de la liste des espèces (#805)
- SYNTHESE : Baser la portée de tous les exports (y compris Statuts)
  sur l’action E (#804)
- METADONNEES : Affichage des ID des JDD et CA
- OCCTAX : Conserver le fichier GPX ou GeoJSON chargé sur la carte
  quand on enchaine des relevés et ajouter de la transparence sur les
  géométries utilisés dans les relevés précédents (#813)
- OCCTAX : Clarification de l’ergonomie pour ajouter un dénombrement
  sur un taxon (#780)
- Ajout des dates de creation et de modification dans les tables
  `gn_monitoring.t_base_sites` et `gn_monitoring.t_base_visits` et
  triggers pour les calculer automatiquement
- Ajout des champs `geom_local`, `altitude_min` et `altitude_max` dans
  la table `gn_monitoring.t_base_sites` et triggers pour les calculer
  automatiquement (#812)
- Ajout des champs `id_dataset`, `id_module`,
  `id_nomenclature_obs_technique` et `id_nomenclature_grp_typ` dans la
  table `gn_monitoring.t_base_visits` (#812)
- Le composant générique FileLayer expose un `output` pour récuperer
  la géométrie sélectionnée (un observable de MapService était utilisé
  auparavant)
- Support des markers sur le composant `leaflet-draw`
- Possibilité de ne pas activer le composant `marker` au lancement
  lorsque celui-ci est utilisé (input `defaultEnable`)
- Ajout d’inputs `time`, `number`, `medias` et `datalist` au
  composant DynamicForm permettant de générer des formulaires
  dynamiques.
- Améliorations diverses du composant DynamicForm (par \@joelclems)
- Ajout d’un paramètre dans le cas où le serveur se trouve derrière
  un proxy (`proxy_http` ou dans `proxy_https` dans
  `config/settings.ini`)
- Ajout d’une route permettant de récupérer la liste des rôles d’une
  liste à partir de son code (par \@joelclems)

**🐛 Corrections**

- MENU Side nav : Correction pour ne pas afficher les modules pour
  lesquels le paramètre `active_frontend` est False (#822)
- OCCTAX : Gestion de l’édition des occurrences où le JDD a été
  désactivé, en ne permettant pas de modifier le JDD (#694)
- OCCTAX : Correction d’une faiblesse lors de la récupération des
  informations taxonomiques d’un relevé (utilisation d’une jointure
  plutôt que l’API TaxHub) (#751)
- OCCTAX : Correction des longues listes de taxons dans les tooltip
  des relevés en y ajoutant un scroll (par \@jbrieuclp) (#666)
- OCCTAX : Masquer le bouton `Télécharger` si l’utilisateur n’a pas
  de droits d’export dans le module (E = 0)
- OCCTAX : Correction de l’affichage des relevés dans la liste
  (#777)
- OCCTAX : Correction des exports quand on filtre sur un obervateur en
  texte
- SYNTHESE : Filtre sur `date_max` en prenant `date_max <= 23:59:59`
  pour prendre en compte les observations avec un horaire (#778)
- SYNTHESE : Correction des boutons radios pour les filtres
  taxonomiques avancés basés sur les attributs TaxHub (#763)
- SYNTHESE : Correction de la recherche par `cd_nom` dans le composant
  `SearchTaxon` (#824)
- VALIDATION : Corrections mineures (par \@jbrieuclp) (#715)
- INSCRIPTION : Correction si aucun champ additionnel n’a été ajouté
  au formulaire (par \@jbrieuclp) (#746)
- INSCRIPTION : Correction de l’usage des paramètres `ENABLE_SIGN_UP`
  et `ENABLE_USER_MANAGEMENT` (#791)
- Simplification de l’écriture des logs dans le script
  `install_db.sh`
- Correction de l’installation des requirements.txt lors de
  l’installation d’un module (#764 par \@joelclems)
- COMMONS : Modification des champs de `t_modules` de type
  CHARACTER(n) en CHARACTER VARYING(n) (`module_path`,
  `module_target`, `module_external_url`) (#799)
- COMMONS : Ajout de contraintes d’unicité pour les champs
  `module_path` et `module_code` de `t_modules`
- pnx-geojson : Amélioration du zoom, gestion des styles
- Migration des données GeoNature V1 vers V2
  (`data/migrations/v1tov2/`) : ajustements mineurs

**⚠️ Notes de version**

NB: La version 2.3.0 n’est pas compatible avec le module Dashboard. Si
vous avez le module Dashboard installé, ne passez pas à cette nouvelle
version. Compatibilité dans la 2.3.1.

- Lancer le script de migration qui va installer et remplir le nouveau
  schéma `ref_habitats` avec Habref et mettre à jour le schéma
  `ref_nomenclatures` :

  ```bash
  cd /home/`whoami`/geonature/install/migration
  chmod +x 2.2.1to2.3.0.sh
  ./2.2.1to2.3.0.sh
  ```

Vérifier que la migration s’est bien déroulée dans le fichier
`var/log/2.2.1to2.3.0.log`.

- Lancer le script SQL de mise à jour de la BDD de GeoNature
  <https://raw.githubusercontent.com/PnX-SI/GeoNature/2.3.0/data/migrations/2.2.1to2.3.0.sql>
- Vous pouvez installer le nouveau module Occhab (Occurrences
  d’habitats) si vous le souhaitez :

  ```bash
  cd /home/`whoami`/geonature/backend
  source venv/bin/activate
  geonature install_gn_module /home/`whoami`/geonature/contrib/gn_module_occhab /occhab
  deactivate
  ```

- Lors de la migration (`/data/migrations/2.2.1to2.3.0.sql`), tous les
  JDD actifs sont associés par défaut au module Occtax
  (<https://github.com/PnX-SI/GeoNature/blob/master/data/migrations/2.2.1to2.3.0.sql#L17-L22>).
  A chacun d’adapter si besoin, en en retirant certains. Pour
  utiliser le module Occhab, vous devez y associer au moins un JDD.

## 2.2.1 (2019-10-09)

**🐛 Corrections**

- La route de changement de mot de passe était désactivée par le
  mauvais paramètre (`ENABLE_SIGN_UP` au lieu de
  `ENABLE_USER_MANAGEMENT`)
- Désactivation du mode "enchainement des relevés" en mode édition
  (#669). Correction effacement du même relevé (#744)
- Correction d’affichage du module métadonnées lorsque les AF n’ont
  pas de JDD pour des raisons de droit (#743)
- Diverses corrections de doublons d’import et de logs de débugs
  (#742)
- Montée de version du sous-module d’authentification: 1.4.2

## 2.2.0 - Module utilisateurs (2019-09-18)

**🚀 Nouveautés**

- Ajout d’interfaces et de paramètres de création de compte, de
  récupération de son mot de passe et d’administration de son profil,
  basé sur l’API UsersHub 2.1.0 (par \@jbrieuclp et \@TheoLechemia)
  #615
- Ajout d’une fonctionnalité de création automatique d’un CA et
  d’un JDD personnel lors de la validation d’un compte créé
  automatiquement (paramétrable)
- Amélioration du composant de création dynamique de formulaire
  (support de text-area, checkbox simple et multiple et exemple
  d’utilisation à partir de la conf GeoNature)
- Le composant ’observateur’ permet de rechercher sur le nom ou le
  prénom (utilisation des RegEx) #567
- Mise à jour de Flask en version 1.1.1
- Nouvelle version du sous-module d’authentification (1.4.1),
  compatible avec UsersHub 2.1.0
- Mise à jour du sous-module de nomenclatures (version 1.3.0)
- Mise à jour et clarification du MCD
  (<http://docs.geonature.fr/admin-manual.html#base-de-donnees>) par
  \@jpm-cbna
- Ajout d’une tutoriel vidéo d’installation dans la documentation
  (<https://www.youtube.com/watch?v=JYgH7cV9AjE>, par \@olivier8064)

**🐛 Corrections**

- Correction d’un bug sur les export CSV en utilisant la librairie
  Python standard `csv` (#733)
- SYNTHESE API : Passage de la route principale de récupération des
  données en POST plutôt qu’en GET (#704)
- SYNTHESE BDD : Suppression automatique des aires intersectées
  (`synthese.cor_area_synthese`) lorsqu’une observation est supprimée
  (DELETE CASCADE)
- SYNTHESE : Prise en compte du paramètre `EXPORT_ID_SYNTHESE_COL`
  (#707)
- OCCTAX : Correction d’une autocomplétion automatique erronée de la
  date max en mode édition (#706)
- VALIDATION : Améliorations des performances, par \@jbrieuclp (#710)
- Prise en compte des sous-taxons pour le calcul des règles de
  sensibilité
- Correction des contraintes CHECK sur les tables liées à la
  sensibilité
- Complément et correction des scripts de migration
  `data/migrations/v1tov2`
- Correction et clarification de la documentation d’administration
  des listes de taxons et de sauvegarde et restauration de la BDD
  (par \@lpofredc)
- Correction de la rotation des logs

**⚠️ Notes de version**

- Passer le script de migration suivant:
  <https://github.com/PnX-SI/GeoNature/blob/master/data/migrations/2.1.2to2.2.0.sql>
- Suivez ensuite la procédure classique de mise à jour de GeoNature
  (<http://docs.geonature.fr/installation-standalone.html#mise-a-jour-de-l-application>)
- Si vous souhaitez activer les fonctionnalités de création de compte,
  veuillez lire **attentivement** cette documentation :
  <http://docs.geonature.fr/admin-manual.html#configuration-de-la-creation-de-compte>
- Si vous activez la création de compte, UsersHub 2.1.0 doit être
  installé. Voir sa [note de
  version](https://github.com/PnX-SI/UsersHub/releases).

## 2.1.2 (2019-07-25)

**🐛 Corrections**

- SYNTHESE : Correction d’une URL en dur pour la recherche de rangs
  taxonomiques
- OCCTAX : Affichage uniquement des JDD actifs
- VALIDATION : Abaissement de la limite d’affichage de données sur la
  carte par défaut + message indicatif
- Migration : Suppression d’un lien symbolique qui créait des liens
  en cascade
- Amélioration de la documentation (\@dthonon)
- Amélioration de la rapidité d’installation du MNT grâce à la
  suppression d’un paramètre inutile
- BACKOFFICE : Correction d’une URL incorrecte et customisation

**⚠️ Notes de version**

Ceci est une version corrective mineure. Si vous migrez depuis la 2.1.0,
passez directement à cette version en suivant les notes de version de la
2.1.1.

## 2.1.1 (2019-07-18)

**🚀 Nouveautés**

- SYNTHESE: Factorisation du formulaire de recherche (utilisé dans le
  module synthese et validation)
- SYNTHESE: Simplification et correction du module de recherche
  avancée d’un taxon en le limitant à l’ordre (performances)
- SYNTHESE: Ajout d’un composant de recherche taxonomique avancé basé
  sur les rangs taxonomiques (modules synthese et validation), basé
  sur la nouvelle fonction `taxonomie.find_all_taxons_children`
  ajoutée à TaxHub
- Création d’un backoffice d’admnistration dans le coeur de
  GeoNature. Basé sur Flask-admin, les modules peuvent alimenter
  dynamiquement le backoffice avec leur configuration
- Mise en place d’une documentation développeur automatique de l’API
  à partir des docstring et des composants frontend, générée par
  Travis et désormais accessible à l’adresse
  <http://docs.geonature.fr> (#673)
- Amélioration de la documentation (triggers, installation, module
  validation)
- Suppression du module d’exemple, remplacé par un template de module
  (<https://github.com/PnX-SI/gn_module_template>)
- Ajout d’un champ `validable` sur la table `gn_meta.t_datasets`
  controlant les données présentes dans le module VALIDATION
  (<https://github.com/PnX-SI/gn_module_validation/issues/31>)
- VALIDATION: Lister toutes les données de la synthèse ayant un
  `uuid_sinp` dans le module validation, et plus seulement celles qui
  ont un enregistrement dans `gn_commons.t_validations`
- VALIDATION: On ne liste plus les `id_nomenclatures` des types de
  validation à utiliser, dans la configuration du module. Mais on
  utilise toutes les nomenclatures activées du type de nomenclature
  `STATUT_VALID`.
  (<https://github.com/PnX-SI/gn_module_validation/issues/30>)
- Ajout de tests sur les ajouts de JDD et CA
- Ajout d’une fonctionnalité d’envoie d’email via Flask-Mail dans
  le coeur de GeoNature
- Amélioration des performances: ajout d’index sur Occtax et
  Metadonnées
- Script d’import des métadonnées à partir du webservice MTD de
  l’INPN (\@DonovanMaillard)
- Complément, correction et compatibilité 2.1.0 des scripts de
  migration `data/migrations/v1tov2`

**🐛 Corrections**

- Nombreuses corrections du module de validation (non utilisation des
  id_nomenclature, simplification des vues et de la table
  `gn_commons.t_validations`)
- Ordonnancement de listes déroulantes (#685)
- OCCTAX : correction de l’édition d’un relevé à la géométrie de
  type Polyline (#684)
- OCCTAX : correction l’édition et du contrôle conditionnel des
  champs de "preuves" (preuve d’existence numérique / non
  numérique) (#679)
- OCCTAX : correction du parametre `DATE_FORM_WITH_TODAY` non pris en
  compte (#670)
- OCCTAX: correction de la date_max non remplie lorsque
  `DATE_FORM_WITH_TODAY = false`
- OCCTAX: correction d’un bug lors de l’enchainement de relevé
  lorsque l’heure est remplie
- SYNTHESE: correction des doublons lorsqu’il y a plusieurs
  observateurs
- Correction du composant `dynamicForm` sur les champs de recherche de
  type texte (recherche sur Preuve numérique) (#530)
- Désactivation du mode "enchainer les relevés" en mode édition
  (#699)
- Correction de `gn_monitoring` : utiliser `gn_commons.t_modules` à la
  place de `utilisateurs.t_applications` pour associer des sites de
  suivi à des modules
- Fix de SQLalchemy 1.3.3 et jointure sur objet Table
- Le trigger remplissant `cor_area_synthese` en intersectant
  `gn_synthese.synthese` avec `ref_geo.l_areas` ne prend plus que les
  zonages ayant le champs `enabled=true`
- Correction `dict()` et version de Python (par \@jpm-cbna)
- MAJ de sécurité de Bootstrap (en version 4.3.1)
- L’ancien module export du coeur est enlevé en vue de la sortie du
  nouveau module export

**⚠️ Notes de version**

- Passer TaxHub en version 1.6.3
  (<https://github.com/PnX-SI/TaxHub/releases/tag/1.6.3>)
- Passer le script de migration `data/2.1.0to2.1.1.sql`
- Si vous aviez modifier les `id_nomenclature` dans la surcouche de la
  configuration du module validation, supprimer les car on se base
  maintenant sur les `cd_nomenclature`
- Suivez ensuite la procédure classique de mise à jour de GeoNature
  (<http://docs.geonature.fr/installation-standalone.html#mise-a-jour-de-l-application>)
- Nouvelle localisation de la doc : <http://docs.geonature.fr>

## 2.1.0 - Module validation (2019-06-01)

**🚀 Nouveautés**

- Intégration du module Validation dans GeoNature (développé par
  \@JulienCorny, financé par \@sig-pnrnm)
- Ajout de tables, règles et fonctions permettant de calculer la
  sensibilité des occurrences de taxon de la synthèse (#284)
- Occtax - Possibilité d’enchainer les saisies de relevés et de
  garder les informations du relevé (#633)
- Occtax - Amélioration de l’ergonomie de l’interface MapList pour
  clarifier la recherche et l’ajout d’un relevé + ajout compteur
  (#467)
- Révision de l’interface du module Métadonnées, listant les cadres
  d’acquisition et leurs jeux de données (par \@jbrieuclp)
- Ajout d’un mécanisme du calcul des taxons observés par zonage
  géographique (#617)
- Les mailles INPN (1, 5, 10km) sont intégrées à l’installation (avec
  un paramètre)
- Statistiques de la page d’accueil - Ajout d’un paramètre
  permettant de les désactiver (#599)
- Occtax - Date par défaut paramétrable (#351)
- Support des géometries multiples (MultiPoint, MultiPolygone,
  MultiLigne) dans la synthèse et Occtax (#609)
- Synthese - Affichage des zonages intersectés dans un onglet séparé
  (#579)

**🐛 Corrections**

- Révision complète des scripts de migration de GeoNature v1 à v2
  (`data/migrations/v1tov2`)
- Masquer l’export du module Synthèse si son CRUVED est défini à 0
  (#608)
- Correction de la vérification du CRUVED du module METADONNEES
  (#601)
- Correction de la vérification du CRUVED lorsque get_role = False
- Correction de la traduction sur la page de connexion
  (par \@jbrieuclp)
- Occtax - Retour du composant GPS permettant de charger un marker à
  partir de coordonnées X et Y (#624)
- Correction lors d’import de fichier GPX ayant une altitude (#631)
- Occtax - Correction du filtre Observateur texte libre (#598)
- Métadonnées - Inversion des domaines terrestre/marin
  (par \@xavyeah39)
- Métadonnées - Correction de l’édition des cadres d’acquisition
  (#654, par \@DonovanMaillard)
- Mise à jour de sécurité de Jinja2 et SQLAlchemy

**⚠️ Notes de version**

- Vous pouvez passer directement à cette version, mais en suivant les
  notes des versions intermédiaires

- Suivez ensuite la procédure classique de mise à jour de GeoNature
  (<http://docs.geonature.fr/installation-standalone.html#mise-a-jour-de-l-application>)

- Lancer le script de migration de la base de données :

  Cette nouvelle version de GeoNature intègre les mailles INPN (1, 5,
  10km) dans le réferentiel géographique. Si vous ne souhaitez pas les
  installer, lancer le script ci dessous en passant le paramètre
  `no-grid`

      cd /home/`whoami`/geonature/data/migrations
      # avec les mailles
      ./2.0.1to2.1.0.sh
      # sans les mailles:
      # ./2.0.1to2.1.0.sh no-grid

- Installer le module VALIDATION si vous le souhaitez :

  Se placer dans le virtualenv de GeoNature

      cd /home/`whoami`/geonature/backend
      source venv/bin/activate

  Lancer la commande d’installation du module puis sortir du
  virtualenv

      geonature install_gn_module /home/`whoami`/geonature/contrib/gn_module_validation/ /validation
      deactivate

## 2.0.1 (2019-03-18)

**🚀 Nouveautés**

- Développement : ajout d’une fonction de génération dynamique de
  requête SQL (avec vérification et cast des types)
- Synthese : Ajout d’un message indiquant que le module affiche les
  dernières observations par défaut

**🐛 Corrections**

- Synthese : correction du filtre CRUVED pour les portées 1 et 2 sur
  la route `synthese/for_web` (#584)
- Synthese : correction du bug lorsque la géométrie est null (#580)
- Synthese : Correction de la redirection vers le module de saisie
  (#586)
- Synthese : Correction de la valeur par défaut de la nomenclature
  `STATUT_OBS` (`Présent` au lieu de `NSP`)
- Configuration carto : correction du bug d’arrondissement des
  coordonnées géographiques (#582)
- Correction du trigger de calcul de la geom locale
- Recréation de la vue `pr_occtax.export_occtax_sinp` qui avait été
  supprimée lors de la migration RC3 vers RC4
- Correction de la vue `pr_occtax.v_releve_list`
- Correction ajout rang et cd_nom sur l’autocomplete de la synthese,
  absent dans le script de migration
- DEPOBIO : Correction de la déconnexion au CAS INPN
- Occtax et Metadata: correction lors de la mise à jour d’un élement
  (Merge mal géré par SQLAlchemy lorsqu’on n’a pas une valeur NULL)
  (#588)
- Composant "jeu de données" : retour à l’affichage du nom long
  (#583)
- Amélioration du style du composant multiselect
- Metadata : formulaire cadre d’acquisition - listage uniquement des
  cadres d’acquisition parent pour ne pas avoir de cadres
  d’acquisition imbriqués
- Ajouts de tests automatisés complémentaires

**⚠️ Notes de version**

- Vous pouvez passer directement à cette version, mais en suivant les
  notes des versions intermédiaires
- Exécuter le script de migration SQL du sous-module Nomenclatures
  (<https://github.com/PnX-SI/Nomenclature-api-module/blob/1.2.4/data/update1.2.3to1.2.4.sql>)
- Exécuter le script de migration SQL de GeoNature
  (<https://github.com/PnX-SI/GeoNature/blob/master/data/migrations/2.0.0to2.0.1.sql>)
- Suivez ensuite la procédure classique de mise à jour de GeoNature
  (<http://docs.geonature.fr/installation-standalone.html#mise-a-jour-de-l-application>)

## 2.0.0 - La refonte (2019-02-28)

La version 2 de GeoNature est une refonte complète de l’application.

- Refonte technologique en migrant de PHP/Symfony/ExtJS/Openlayers à
  Python3/Flask/Angular4/Leaflet
- Refonte de l’architecture du code pour rendre GeoNature plus
  générique et modulaire
- Refonte de la base de données pour la rendre plus standardisée, plus
  générique et modulaire
- Refonte ergonomique pour moderniser l’application

Pour plus de détails sur les évolutions apportées dans la version 2,
consultez les détails des versions RC (Release Candidate) ci-dessous.

**Nouveautés**

- Possibilité de charger un fichier (GPX, GeoJson ou KML) sur la carte
  pour la saisie dans le module Occtax (#256)
- Ajout d’un moteur de recherche de lieu (basé sur l’API
  OpenStreetMap Nominatim) sur les modules cartographiques (#476)
- Intégration du plugin leaflet markerCluster permettant d’afficher
  d’avantage d’observations sur les cartes et de gérer leurs
  superposition (#559)
- Synthèse : possibilité de grouper plusieurs types de zonages dans le
  composant `pnx-areas`
- Design de la page de login
- Intégration d’un bloc stat sur la page d’accueil
- Ajout d’un export des métadonnées dans la synthèse
- Centralisation de la configuration cartographique dans la
  configuration globale de GeoNature (`geonature_config.toml`)
- Cartographie : zoom sur l’emprise des résultats après une recherche
- Migration de la gestion des métadonnées dans un module à part :
  ’METADATA’ (#550)
- Export vue synthèse customisable (voir doc)
- Lien vers doc par module (customisables dans `gn_commons.t_modules`)
  (#556)
- Ajout du code du département dans les filtres par commune (#555)
- Ajout du rang taxonomique et du cd_nom après les noms de taxons
  dans la recherche taxonomique (#549)
- Mise à jour des communes fournies lors de l’installation (IGN admin
  express 2019) (#537)
- Synthèse : Ajout du filtre par organisme (#531), affichage des
  acteurs dans les fiches détail et les exports
- Synthese: possibilité de filtrer dans les listes déroulantes des
  jeux de données et cadres d’acquisition
- Filtre de la recherche taxonomique par règne et groupe INPN retiré
  des formulaires de recherche (#531)
- Suppression du champ validation dans le schéma de BDD Occtax car
  cette information est stockée dans la table verticale
  `gn_commons.t_validations` + affichage du statut de validation dans
  les fiches Occtax et Synthèse
- Ajout d’une vue `gn_commons.v_lastest_validation` pour faciliter la
  récupération du dernier statut de validation d’une observation
- Suppression de toutes les références à `taxonomie.bib_noms` en vue
  de le supprimer de TaxHub
- Séparation des commentaires sur l’observation et sur le contexte
  (relevé) dans la Synthèse et simplification des triggers de Occtax
  vers Synthèse (#478)
- Nouveau logo GeoNature (#346)

**Corrections**

- Améliorations importantes des performances de la synthèse (#560)
- Synthèse : correction liée aux filtres multiples et aux filtres
  géographiques de type cercle
- Ajout d’une contrainte `DELETE CASCADE` entre
  `ref_geo.li_municialities` et `ref_geo.l_areas` (#554)
- Occtax : possibilité de saisir un dénombrement égal à 0 (cas des
  occurrences d’absence)
- Occtax : retour à l’emprise cartographique précédente lorsqu’on
  enchaine les relevés (#570)
- Occtax : correction de l’automplissage du champ `hour_max` lors de
  l’édition d’un relevé
- Divers compléments de la documentation (merci \@jbdesbas,
  \@xavyeah39 et \@DonovanMaillard)
- Ajout de contraintes d’unicité sur les UUID_SINP pour empêcher les
  doublons (#536)
- Corrections et compléments des tests automatiques
- Amélioration de l’installation des modules GeoNature

**Notes de version**

**1.** Pour les utilisateurs utilisant la version 1 de GeoNature :

Il ne s’agit pas de mettre à jour GeoNature mais d’en installer une
nouvelle version. En effet, il s’agit d’une refonte complète.

- Sauvegarder toutes ses données car l’opération est complexe et
  non-automatisée
- Passer à la dernière version 1 de GeoNature (1.9.1)
- Passer aux dernières versions de UsersHub et TaxHub
- Installer GeoNature standalone ou refaire une installation complète
- Adaptez les scripts présents dans `/data/migrations/v1tov2` et
  exécutez-les pas à pas. Attention ces scripts ont été faits pour la
  version 2.0.0-rc.1 et sont donc à ajuster, tester, compléter et
  adapter à votre contexte

**2.** Pour les utilisateurs utilisant une version RC de GeoNature 2 :

Veuillez bien lire ces quelques consignes avant de vous lancer dans la
migration.

- Vous pouvez passer directement à cette version, mais en suivant les
  notes des versions intermédiaires.
- Les personnes ayant configuré leur fichier `map.config.ts` devront
  le répercuter dans `geonature_config.toml`, suite à la
  centralisation de la configuration cartographique (voir
  <https://github.com/PnX-SI/GeoNature/blob/2.0.0/config/default_config.toml.example>
  section `[MAPCONFIG]`).
- La configuration des exports du module synthèse a été modifiée (voir
  <http://docs.geonature.fr/user-manual.html#synthese>). Supprimer la
  variable`[SYNTHESE.EXPORT_COLUMNS]` dans le fichier
  `geonature_config.toml`. Voir l’exemple dans le fichier (voir
  <https://github.com/PnX-SI/GeoNature/blob/2.0.0/config/default_config.toml.example>
  section) pour configurer les exports.
- Supprimer la variable `COLUMNS_API_SYNTHESE_WEB_APP` si elle a été
  ajoutée dans le fichier `geonature_config.toml`.
- Pour simplifier son édition, le template personalisable de la page
  d’accueil
  (`frontend/src/custom/components/introduction/introduction.component.html`)
  a été modifié (la carte des 100 dernière observations n’y figure
  plus). Veuillez supprimer tout ce qui se situe à partir de la ligne
  21 (`<div class="row row-0">`) dans ce fichier.
- Exécuter le script de migration SQL:
  <https://github.com/PnX-SI/GeoNature/blob/2.0.0/data/migrations/2.0.0rc4.2to2.0.0.sql>.
- Le backoffice de gestion des métadonnées est dorénavant un module
  GeoNature à part. Le script migration précédemment lancé prévoit de
  mettre un CRUVED au groupe_admin et groupe_en_poste pour le
  nouveau module METADATA. Les groupes nouvellement créés par les
  administrateurs et n’ayant de CRUVED pour l’objet METADATA (du
  module Admin), se retrouvent avec le CRUVED hérité de GeoNature.
  L’administrateur devra changer lui-même le CRUVED de ces groupes
  pour le nouveau module METADATA via le backoffice des permissions.
- Suivez ensuite la procédure classique de mise à jour de GeoNature
  (<http://docs.geonature.fr/installation-standalone.html#mise-a-jour-de-l-application>).

## 2.0.0-rc.4.2 (2019-01-23)

**Nouveautés**

- Mise en place de logs rotatifs pour éviter de surcharger le serveur
- Centralisation des logs applicatifs dans le dossier
  `var/log/gn_errors.log` de GeoNature

**Corrections**

- Synthèse - Correction et amélioration de la gestion des dates
  (#540)
- Amélioration des tests automatisés
- Correction et complément ds scripts d’installation des modules
  GeoNature
- Remplacement de `gn_monitoring.cor_site_application` par
  `gn_monitoring.cor_site_module`
- Complément des documentations de customisation, d’administration et
  de développement
- Ajout d’une documentation de migration de données Serena vers
  GeoNature
  (<https://github.com/PnX-SI/Ressources-techniques/tree/master/GeoNature/migration/serena>)
  par \@xavyeah39

**Note de version**

- Vous pouvez passer directement à cette version, mais en suivant les
  notes des versions intermédiaires

- Exécutez la mise à jour de la BDD GeoNature
  (`data/migrations/2.0.0rc4.1to2.0.0rc4.2.sql`)

- Depuis la version 2.0.0-rc.4, on ne stocke plus les modules de
  GeoNature dans `utilisateurs.t_applications`. On ne peut donc plus
  associer les sites de suivi de `gn_monitoring` à des applications,
  utilisé par les modules de suivi (Flore, habitat, chiro). Le
  mécanisme est remplacé par une association des sites de suivi aux
  modules. La création de la nouvelle table est automatisée
  (`data/migrations/2.0.0rc4.1to2.0.0rc4.2.sql`), mais pas la
  migration des éventuelles données existantes de
  `gn_monitoring.cor_site_application` vers
  `gn_monitoring.cor_site_module`, à faire manuellement.

- Afin que les logs de l’application soient tous écrits au même
  endroit, modifier le fichier `geonature-service.conf`
  (`sudo nano /etc/supervisor/conf.d/geonature-service.conf`). A la
  ligne `stdout_logfile`, remplacer la ligne existante par
  `stdout_logfile = /home/<MON_USER>/geonature/var/log/gn_errors.log`
  (en remplaçant \<MON_USER\> par votre utilisateur linux).

- Vous pouvez également mettre en place un système de logs rotatifs
  (système permettant d’archiver les fichiers de logs afin qu’ils ne
  surchargent pas le serveur - conseillé si votre serveur a une
  capacité disque limitée). Créer le fichier suivant
  `sudo nano /etc/logrotate.d/geonature` puis copiez les lignes
  suivantes dans le fichier nouvellement créé (en remplaçant
  \<MON_USER\> par votre utilisateur linux)

      /home/<MON_USER>/geonature/var/log/*.log {
      daily
      rotate 8
      size 100M
      create
      compress
      }

  Exécutez ensuite la commande `sudo logrotate -f /etc/logrotate.conf`

- Suivez ensuite la procédure classique de mise à jour de GeoNature
  (<http://docs.geonature.fr/installation-standalone.html#mise-a-jour-de-l-application>)

## 2.0.0-rc.4.1 (2019-01-21)

**Corrections**

- Mise à jour des paquets du frontend (#538)
- Correction d’un conflit entre Marker et Leaflet-draw
- Utilisation du paramètre `ID_APP` au niveau de l’application
- Corrections mineures diverses

**Note de version**

- Sortie de versions correctives de UsersHub (2.0.2 -
  <https://github.com/PnX-SI/UsersHub/releases>) et TaxHub (1.6.1 -
  <https://github.com/PnX-SI/TaxHub/releases>) à appliquer aussi
- Vous pouvez vous référer à la documentation globale de mise à jour
  de GeoNature RC3 vers RC4 par \@DonovanMaillard
  (<https://github.com/PnX-SI/GeoNature/blob/master/docs/update-all-RC3-to-RC4.rst>)

## 2.0.0-rc.4 (2019-01-15)

**Nouveautés**

- Intégration de la gestion des permissions (CRUVED) dans la BDD de
  GeoNature, géré via une interface d’administration dédié (#517)
- Mise en place d’un système de permissions plus fin par module et
  par objet (#517)
- Mise en place d’un mécanimse générique pour la gestion des
  permissions via des filtres : filtre de type portée (SCOPE),
  taxonomique, géographique etc\... (#517)
- Compatibilité avec UsersHub version 2
- L’administration des permissions ne propose que les rôles qui sont
  actif et qui ont un profil dans GeoNature
- Ajout du composant Leaflet.FileLayer dans le module Synthèse pour
  pouvoir charger un GeoJSON, un GPS ou KML sur la carte comme
  géométrie de recherche (#256)
- Ajout et utilisation de l’extension PostgreSQL `pg_tgrm` permettant
  d’améliorer l’API d’autocomplétion de taxon dans la synthèse, en
  utilisant l’algorithme des trigrammes
  (<http://si.ecrins-parcnational.com/blog/2019-01-fuzzy-search-taxons.html>),
  fonctionnel aussi dans les autres modules si vous mettez à jour
  TaxHub en version 1.6.0.
- Nouvel exemple d’import de données historiques vers GeoNature V2 :
  <https://github.com/PnX-SI/Ressources-techniques/blob/master/GeoNature/V2/2018-12-csv-vers-synthese-FLAVIA.sql>
  (par \@DonovanMaillard)
- Complément de la documentation HTTPS et ajout d’une documentation
  Apache (par \@DonovanMaillard, \@RomainBaghi et \@lpofredc)

**Corrections**

- Correction de l’id_digitiser lors de la mise à jour (#481)
- Corrections multiples de la prise en compte du CRUVED (#496)
- Deconnexion apres inactivité de l’utilisateur (#490)
- Suppression des heures au niveau des dates de l’export occtax
  (#485)
- Correction du message d’erreur quand on n’a pas de JDD (#479)
- Correction du champs commentaire dans les exports d’Occtax séparé
  entre relevé et occurrence (#478)
- Correction des paramètres de la fonction
  `GenericQuery.build_query_filter()` (par \@patkap)
- Correction de l’administration des métadonnées (#466 #420)
- Métadonnées (JDD et CA) : ne pas afficher les utilisateurs qui sont
  des groupes dans les acteurs
- Ajout d’un champs dans la Synthèse permettant de stocker de quel
  module provient une occurrence et fonctions SQL associées (#412)
- Amélioration du style des champs obligatoires
- Améliorations mineures de l’ergonomie d’Occtax
- Correction du spinner qui tournait en boucle lors de l’export CSV
  de la Synthèse (#451)
- Correction des tests automatisés
- Amélioration des performances des intersections avec les zonages de
  `ref_geo.l_areas`
- Complément de la documentation de développement
- Simplification de la configuration des gn_modules
- Occtax : ordonnancement des observation par date (#467)
- Occtax : Remplissage automatique de l’heure_max à partir de
  l’heure_min (#522)
- Suppression des warnings lors du build du frontend
- Correction de l’installation des modules GeoNature
- Ajout d’un message quand on n’a pas accès à une donnée d’un
  module
- Affichage du nom du module dans le Header (#398)
- Correction des outils cartographiques dans Occtax
- Correction complémentaire des styles des lignes sans remplissage
  (#458)
- MaplistService : correction du zoom sur les polygones et polylignes
- Composant Areas et Municipalities : remise à zéro de la liste
  déroulante quand on efface la recherche ou remet à jour les filtres
- Composant Taxonomy : la recherche autocompletée est lancée même si
  on tape plus de 20 caractères. Le nombre de résultat renvoyé est
  désormais paramétrable (#518)
- Limitation du nombre de connexions à la BDD en partageant
  l’instance `DB` avec les sous-modules
- Installation : utilisation d’un répertoire `tmp` local et non plus
  au niveau système pour limiter les problèmes de droits (#503)
- Evolution du template d’exemple de module GeoNature
  (<https://github.com/PnX-SI/GeoNature/tree/master/contrib/module_example>)
  pour utiliser l’instance DB et utiliser les nouveaux décorateurs de
  permissions (CRUVED)

**Note de version**

- Si vous effectuez une migration de GeoNature RC3 vers cette nouvelle
  version, il est nécessaire d’avoir installé UsersHub version 2.x au
  préalable. Suivez donc sa documentation
  (<https://github.com/PnX-SI/UsersHub/releases>) avant de procéder à
  la montée de version de GeoNature.
- Exécuter la commande suivante pour ajouter l’extension `pg_trgm`,
  en remplaçant la variable `$db_name` par le nom de votre BDD :
  `sudo -n -u postgres -s psql -d $db_name -c "CREATE EXTENSION IF NOT EXISTS pg_trgm;"`
- Mettez à jour TaxHub en version 1.6.0 pour bénéficier de
  l’amélioration de la recherche taxonomique dans tous les modules
- Exécutez la mise à jour de la BDD GeoNature
  (`data/migrations/2.0.0rc3.1-to-2.0.0rc4.sql`)
- Suivez ensuite la procédure classique de mise à jour de GeoNature
  (<http://docs.geonature.fr/installation-standalone.html#mise-a-jour-de-l-application>)

**Note développeurs**

- Vous pouvez faire évoluer les modules GeoNature en utilisant
  l’instance `DB` de GeoNature pour lancer les scripts
  d’installation (#498)
- Il n’est plus nécéssaire de définir un `id_application` dans la
  configuration des modules GeoNature.
- La gestion des permissions a été revue et est désormais internalisée
  dans GeoNature (voir
  <http://docs.geonature.fr/development.html#developpement-backend>),
  il est donc necessaire d’utiliser les nouveaux décorateurs décrit
  dans la doc pour récupérer le CRUVED.

## 2.0.0-rc.3.1 (2018-10-21)

**Corrections**

- Correction du script `ìnstall_all.sh` au niveau de la génération de
  la configuration Apache de TaxHub et UsersHub (#493)
- Suppression du Servername dans la configuration Apache de TaxHub du
  script `install_all.sh`
- Complément de la documentation de mise à jour de GeoNature
  (<http://docs.geonature.fr/installation-standalone.html#mise-a-jour-de-l-application>)

**Notes de version**

- Si vous migrez depuis une version 2.0.0-rc.2, installez directement
  cette version corrective plutôt que la 2.0.0-rc.3, mais en suivant
  les notes de versions de la 2.0.0-rc.3
- Pour mettre en place la redirection de TaxHub sans `/`, consultez sa
  documentation
  <https://taxhub.readthedocs.io/fr/latest/installation.html#configuration-apache>
- Le script `install_all.sh` actuel ne semble pas fonctionner sur
  Debian 8, problème de version de PostGIS qui ne s’installe pas
  correctement

## 2.0.0-rc.3 (2018-10-18)

- Possibilité d’utiliser le MNT en raster ou en vecteur dans la BDD
  (+ doc MNT) #439 (merci \@mathieubossaert)
- INSTALL_ALL - gestion du format date du serveur PostgreSQL (#435)
- INSTALL_ALL - Amélioration de la conf Apache de TaxHub pour gérer
  son URL sans `/` à la fin
- Dessin cartographique d’une autre couleur (rouge) que les
  observations (bleu)
- Occtax : retour au zoom précédent lors de l’enchainement de relevé
  (#436)
- Occtax : observateur rempli par défaut avec l’utilisateur connecté
  (#438)
- Prise en compte des géométries nulles dans la fonction
  `serializegeofn`
- Gestion plus complète des données exemple intégrées ou non lors de
  l’installation (#446)
- Complément des différentes documentations
- Complément FAQ (#441)
- Documentation de la customisation (merci \@DonovanMaillard)
- Amélioration de l’architecture du gn_module d’exemple
- Clarification de la configuration des gn_modules
- Lire le fichier `VERSION` pour l’afficher dans l’interface (#421)
- Utilisation de la vue `export_occtax_sinp` et non plus
  `export_occtax_dlb` par défaut pour les exports Occtax (#462)
- Complément et correction des vues `export_occtax_sinp` et
  `export_occtax_dlb` (#462)
- Mise à jour de Marshmallow (2.5.0 =\> 2.5.1)
- Améliorations des routes de `gn_monitoring` et de la configuration
  des modules de suivi pour pouvoir utiliser le nom d’une application
  plutôt que son identifiant
- Export Synthèse - Remplacement de la barre de téléchargement par un
  spinner (#451)

**Corrections**

- Doc Import niveau 2 : Corrections et compléments
- Correction du trigger Occtax \> Synthèse qui met à jour le champs
  `gn_synthese.observers_txt` et les commentaires (#448 et #459)
- Correction et amélioration de la fonction `install_gn_module`
- Correction coquille dans le modèle `gn_monitoring` et la fonction
  `serializegeofn`
- Installation uniquement sur un environnement 64 bits
  (documentation + vérification) #442 (merci \@jbrieuclp
  et \@sig-pnrnm)
- Correction et découpage des scripts de mise à jour de la BDD depuis
  la version Beta5
- Correction de l’édition des date_debut et date_fin de Occtax
  (#457)
- Correction des exports depuis la Synthèse et intégration de la
  géométrie des observations (#461 et #456)
- Ne pas remplir `pr_occtax.cor_role_releves_occtax` si
  `observers_txt = true` (#463)
- Edition d’un relevé Occtax - Ne pas recalculer l’altitude
  existante (#424)
- Correction de l’activation du formulaire Occtax après localisation
  du relevé (#469 et #471)
- Carte - Enlever le remplissage des lignes (#458)
- Amélioration du script de mise à jour de GeoNature
  (`install/migration/migration.sh`) (#465)
- Suppression d’un doublon dans le modèle de `gn_commons.t_modules`
  (merci \@lpofredc)

**Autres**

- Mise à jour de TaxHub (Doc utilisateur, configuration Apache, script
  d’import des médias depuis API INPN Taxref et remise à zéro des
  séquences)
- Script de migration des données SICEN (ObsOcc) vers GeoNature :
  <https://github.com/PnX-SI/Ressources-techniques/tree/master/GeoNature/migration/sicen>
- Script d’import continu depuis une BDD externe vivante (avec
  exemple SICEN) :
  <https://github.com/PnX-SI/Ressources-techniques/tree/master/GeoNature/migration/generic>
- Module Suivi Flore Territoire fonctionnel et installable
  (<https://github.com/PnX-SI/gn_module_suivi_flore_territoire>)
- Module Suivi Chiro fonctionnel et installable
  (<https://github.com/PnCevennes/gn_module_suivi_chiro>) ainsi que
  son Frontend générique pour les protocoles de suivi
  (<https://github.com/PnCevennes/projet_suivis_frontend/>)
- Ebauche d’un module pour les protocoles CMR
  (Capture-Marquage-Recapture) :
  <https://github.com/PnX-SI/gn_module_cmr>
- MCD du module Suivi Habitat Territoire
  (<https://github.com/PnX-SI/gn_module_suivi_habitat_territoire>)
- MCD du module Flore Prioritaire
  (<https://github.com/PnX-SI/gn_module_flore_prioritaire>)
- Consolidation du backend et premiers développements du frontend de
  GeoNature-citizen (<https://github.com/PnX-SI/GeoNature-citizen>)
- Création d’un script expérimental d’installation de
  GeoNature-atlas compatible avec GeoNature V2 dt pouvant utiliser son
  schéma `ref_geo` pour les communes, le territoire et les mailles
  (<https://github.com/PnX-SI/GeoNature-atlas/blob/develop/install_db_gn2.sh>)

**Notes de version**

- Suivez la procédure standard de mise à jour de GeoNature
  (<http://docs.geonature.fr/installation-standalone.html#mise-a-jour-de-l-application>)
- Exécutez l’update de la BDD GeoNature
  (`data/migrations/2.0.0rc2-to-2.0.0rc3.sql`)
- Il est aussi conseillé de mettre à jour TaxHub en 1.5.1
  (<https://github.com/PnX-SI/TaxHub/releases>) ainsi que sa
  configuration pour qu’il fonctionne sans `/` à la fin de son URL
- Attention, si vous installez cette version avec le script global
  `install_all.sh`, il créé un problème dans la configuration Apache
  de UserHub (`/etc/apache2/sites-available/usershub.conf`) et
  supprime tous les `/`. Les ajouter sur la page de la documentation
  de UsersHub
  (<https://github.com/PnX-SI/UsersHub/blob/master/docs/installation.rst#configuration-apache>)
  puis relancer Apache
  (`https://github.com/PnX-SI/GeoNature-atlas/blob/develop/docs/installation.rst`).
  Il est conseillé d’installer plutôt la version corrective.

## 2.0.0-rc.2 (2018-09-24)

**Nouveautés**

- Script `install_all.sh` compatible Ubuntu (16 et 18)
- Amélioration du composant Download
- Amélioration du ShapeService
- Compléments de la documentation
- Intégration de la documentation Développement backend dans la
  documentation
- Nettoyage du code
- Mise à jour de la doc de l’API :
  <https://documenter.getpostman.com/view/2640883/RWaPskTw>
- Configuration de la carte (`frontend/src/conf/map.config.ts`) : OSM
  par défaut car OpenTopoMap ne s’affiche pas à petite échelle

**Corrections**

- Correction du script `install/migration/migration.sh`
- Ne pas afficher le debug dans le recherche de la synthèse
- Correction du bug de déconnexion entre TaxHub et GeoNature (#423)
- Correction de la fiche info d’Occtax
- Champs Multiselect : Ne pas afficher les valeurs selectionnées dans
  la liste quand on modifie un objet
- Trigger Occtax vers Synthèse : Correction des problèmes d’heure de
  relevés mal copiés dans la Synthèse
- Correction des altitudes (non abouti) (#424)
- Données exemple : Suppression de l’`observers_txt` dans la synthèse
- Suppression d’un `id_municipality` en dur dans une route
- Suppression de la librairie Certifi non utilisée

**Notes de version**

- Suivez la procédure standard de mise à jour de GeoNature
- Exécuter l’update de la BDD GeoNature
  (`data/migrations/2.0.0rc1-to-2.0.0rc2.sql`)

## 2.0.0-rc.1 (2018-09-21)

La version 2 de GeoNature est une refonte complète de l’application.

- Refonte technologique en migrant de PHP/Symfony/ExtJS/Openlayers à
  Python3/Flask/Angular4/Leaflet
- Refonte de l’architecture du code pour rendre GeoNature plus
  générique et modulaire
- Refonte de la base de données pour la rendre plus standarde, plus
  générique et modulaire
- Refonte ergonomique pour moderniser l’application

Présentation et suivi des développements :
<https://github.com/PnX-SI/GeoNature/issues/168>

**Accueil**

- Message d’introduction customisable
- Carte des 100 dernières observations
- CSS général de l’application surcouchable

**Occtax**

Module permettant de saisir, consulter, rechercher et exporter des
données Faune, Flore et Fonge de type Contact selon le standard
Occurrences de taxon du SINP
(<https://inpn.mnhn.fr/telechargement/standard-occurrence-taxon>).

- Développement des formulaires de saisie, page de recherche, fiche
  détail, API, CRUVED et export
- Possibilité de masquer ou afficher les différents champs dans le
  formulaire Occtax (#344)
- Développement du formulaire de manière générique pour pouvoir
  réutiliser ses différents éléments dans d’autres modules sous forme
  de composants Angular
- Configuration possible du module (Niveau de zoom, champs affichées,
  export\...)
- Ajout des nomenclatures dans les filtres d’Occtax à partir du
  composant `dynamicForm` qui permet de créer dynamiquement un
  formulaire en déclarant ses champs et leur type (#318)
- Amélioration du composant de recherche d’un taxon en ne recherchant
  que sur les débuts de mot et en affichant en premier les noms de
  référence (`ordrer_by cd_nom=cd_ref DESC`) #334
- Multilingue fourni avec français et anglais (extensible à d’autres
  langues)
- Mise en place d’un export CSV, SHP, GeoJSON paramétrable dans
  Occtax. #363 et #366
- Ajout d’un message d’erreur si l’utilisateur n’a pas de jeu de
  données ou si il y a eu un problème lors de la récupération des JDD
  depuis MTD
- Prise en compte du CRUVED au niveau des routes et du front pour
  adapter les contenus et fonctionnalités aux droits de l’utilisateur
- Mise en place des triggers alimentant la synthèse à partir des
  données saisies et modifiées dans Occtax

**Synthèse**

Module permettant de rechercher parmi les données des différentes
sources présentes ou intégrées dans la base de données de GeoNature

- Mise en place du backend, de l’API et du frontend #345
- Interface de consultation, de recherche et d’export dans la
  Synthèse
- Synthèse : Calcul automatique (trigger) des zonages de chaque
  observation (communes, zonages réglementaires et naturels)
- Recherche sur les zonages générique et paramétrable
- Recherche par taxon, liste de taxons, par rang, groupe, liste rouge,
  milieu, attribut taxonomique, nomenclature, date, période, commune,
  zonage, cadre d’acquisition, jeu de données, observateur, polygone,
  rectange ou cercle dessiné
- Retour à la fiche source possible si l’observation a été saisie
  dans un module de GeoNature
- Affichage de la fiche détail de chaque observation
- Attributs TaxHub dynamiques et paramétrables
- Configuration possible du module (colonnes, limites de recherche et
  d’export, zoom, export\...)
- Export basé sur une vue (observations et statuts)
- Prise en compte du CRUVED pour définir les données à afficher et à
  exporter #412
- Recherche de taxons : Liste basée sur une table alimentée
  automatiquement par les taxons présents au moins une fois dans la
  Synthèse

**Export**

Module permettant de proposer des exports basés sur des vues

- Mise en place temporaire d’un export unique, basé sur une vue
  s’appuyant sur les données de Occtax, par jeu de données
- A remplacer par le module générique
  <https://github.com/PnX-SI/gn_module_export> (en cours de
  développement) permettant de générer des exports à volonté en créant
  des vues et en les affectant à des utilisateurs ou des groupes.
  Chaque export sera accompagné de son API standardisée et documentée

**Admin**

Module d’administration des tables centrales de GeoNature

- Mise en place d’un module (incomplet) permettant de gérer les
  métadonnées et les nomenclatures

**Gestion des droits**

- Mise en place d’un système baptisé CRUVED permettant de définir
  globalement ou par module 6 actions sont possibles (Create / Read /
  Update / Validate / Export / Delete) sur 3 portées possibles (Mes
  données / Les données de mon organisme / Toutes les données)
- Ces évolutions ont été intégrées au niveau du schéma `utilisateurs`
  de la base de données de UsersHub, de son module
  (<https://github.com/PnX-SI/UsersHub-authentification-module>), des
  routes de l’API GeoNature et des interfaces

**Bases de données**

- Développement d’un module et d’une API générique et autonome pour
  la gestion des nomenclatures
  (<https://github.com/PnX-SI/Nomenclature-api-module>). Il permet
  d’avoir un mécanisme générique de centralisation des listes de
  valeurs (nomenclatures) pour ne pas créer des tables pour chaque
  liste : <https://github.com/PnX-SI/Nomenclature-api-module>. Les
  valeurs de chaque nomenclature s’adaptent en fonction des regnes et
  groupe 2 INPN des taxons.
- Mise en place de tables de stockage verticales (historique, médias
  et validation) #339
- Mise en place d’un référentiel géographique avec un schéma dédié
  (`ref_geo`), partageable avec d’autres applications comprenant une
  table des communes, une table générique des zonages, une table pour
  le MNT et des fonctions pour intersecter point/ligne/polygones avec
  les zonages et le MNT (#228)
- Evolution du schéma `utilisateurs` de UsersHub pour passer d’une
  gestion des droits avec 6 niveaux à un mécanisme plus générique,
  souple et complet. Il permet d’attribuer des actions possibles à un
  rôle (utilisateur ou groupe), sur une portée; dans une application
  ou un module. 6 actions sont possibles dans GeoNature : Create /
  Read / Update / Validate / Export / Delete (aka CRUVED). 3 portées
  de ces actions sont possibles : Mes données / Les données de mon
  organisme / Toutes les données.
- Droits CRUVED : La définition du CRUVED d’un rôle (utilisateur ou
  groupe) sur un module de GeoNature surcouche ses droits GeoNature
  même si ils sont inférieurs. Si une action du CRUVED n’est pas
  définie au niveau du module, on prend celle de l’application
  parente. #292
- Si un rôle a un R du CRUVED à 0 pour un module, alors celui-ci ne
  lui est pas listé dans le Menu et il ne lui est pas accessible si il
  en connait l’URL. #360
- Développement des métadonnées dans la BDD (schéma `gn_meta`) sur la
  base du standard Métadonnées du SINP
  (<http://standards-sinp.mnhn.fr/category/standards/metadonnees/>).
  Elles permettent de gérer des jeux de données, des cadres
  d’acquisition, des acteurs (propriétaire, financeur,
  producteur\...) et des protocoles. Chaque relevé est associé à un
  jeu de données.
- Développement d’un mécanisme de calcul automatique de la
  sensibilité d’une espèce directement dans la BDD (sur la base des
  règles nationales et régionales du SINP + locales éventuellement)
- Intégration du calcul automatique de l’identifiant permanent SINP
  (#209)
- Création du schéma `gn_monitoring` pour gérer la partie générique
  des modules de suivi (sites et visites centralisés) et les routes
  associées
- Mise en place d’un schéma `gn_commons` dans la BDD qui permet de
  stocker de manière générique des informations qui peuvent être
  communes aux autres modules : l’historique des actions sur chaque
  objet de la BDD, la validation d’une donnée et les médias associés
  à une donnée. Accompagné de fonctions génériques d’historisation et
  de validation des données mises en place sur le module Occtax. #339
- Ajout d’une vue matérialisée (`gn_synthese.vm_min_max_for_taxons`)
  et d’une fonction (`gn_synthese.fct_calculate_min_max_for_taxon`)
  permettant de renvoyer des informations sur les observations
  existantes d’un taxon (étendue des observations, date min et max,
  altitude min et max, nombre d’observations) pour orienter la
  validation et la saisie
  (<https://github.com/PnX-SI/gn_module_validation/issues/5>).
  Désactivée pour le moment.
- Ajout d’un trigger générique pour calculer la géométrie dans la
  projection locale à partir de la géométrie 4326 (#370)
- Ajout d’un trigger pour calculer automatiquement les zonages des
  sites de suivi (`gn_monitoring.fct_trg_cor_site_area()`)
- Gestion des conflits de nomenclatures en n’utilisant plus leur
  `id_type` ni leur `id_nomenclature` lors de la création de leur
  contenu (code_nomenclature) (#384)
- Mise en place d’un schéma `gn_imports` intégrant des fonctions SQL
  permettant d’importer un CSV dans la BDD et de mapper des champs de
  tables importées avec ceux d’une table de GeoNature pour générer le
  script `INSERT INTO`
- Début de script de migration GeoNature V1 vers GeoNature V2
- Nombreuses fonctions intégrées dans les schémas de la BDD

**Installation**

- Scripts d’installation autonome ou globale de GeoNature sur Debian
  (8 et 9) et Ubuntu (16 et 18)
- Scripts de déploiement spécifiques de DEPOBIO (MTES-MNHN)

**Documentation**

- Rédaction d’une documentation concernant l’installation (autonome
  ou globale), l’utilisation, l’administration et le développement :
  <http://docs.geonature.fr>

**Développement**

- Découpage de l’application en backend / API / Frontend
- Multilingue au niveau de l’interface et des listes de valeurs avec
  français et anglais intégrés mais extensible à d’autres langues
  (#173)
- Développement de composants Angular génériques pour pouvoir les
  utiliser dans plusieurs modules sans avoir à les redévelopper ni les
  dupliquer (composant CARTE, composant RECHERCHE TAXON, composant
  OBSERVATEURS, composant NOMENCLATURES, SelectSearch, Municipalities,
  Observers, DynamicForm, MapList\...)
- Implémentation de la gestion des droits au niveau de l’API (pour
  limiter les données affichées à un utilisateur en fonction de ses
  droits) et au niveau du Frontend (pour afficher ou non certains
  boutons aux utilisateurs en fonction de leurs droits).
- Par défaut, l’authentification et les utilisateurs sont gérés
  localement dans UsersHub, mais il est aussi possible de connecter
  GeoNature directement au CAS de l’INPN, sans UsersHub (cas de
  l’instance nationale INPN de GeoNature).
- Connexion possible au webservice METADONNEES de l’INPN pour y
  récupérer les jeux de données en fonction de l’utilisateur
  connecté, avec mise à jour des JDD à chaque appel de la route
- Mise en place d’un mécanisme standardisé de développement de
  modules dans GeoNature (#306)
- Ajout de tests unitaires au niveau du backend et du frontend
- Ajout d’un mécanisme de log par email (paramètres MAILERROR)
- Début de création du module de gestion des médias (backend
  uniquement)
- Mise en place d’une configuration globale et d’une configuration
  par module
- Fonction d’installation d’un module et de génération des fichiers
  de configuration
- Gestion de l’installation d’un module qui n’a pas de Frontend
  dans GeoNature
- Mise en place d’une route générique permettant de requêter dans une
  vue non mappée
- Mise en place d’un script pour la customisation de la plateforme
  nationale
  (<https://github.com/PnX-SI/GeoNature/blob/develop/install_all/configuration_mtes.sh>)

**Autres modules**

- Module Export en cours de développement
  (<https://github.com/PnX-SI/gn_module_export>). Chaque export
  s’appuie sur une vue. Il sera possible aux administrateurs d’une
  GeoNature d’ajouter autant de vues que nécessaires dans son
  GeoNature.
- Module de validation des données en cours de développement
  (<https://github.com/PnX-SI/gn_module_validation/issues/4>)
- Module Suivi Flore territoire en cours de développement
  (<https://github.com/PnX-SI/gn_module_suivi_flore_territoire>)
- Module Suivi Habitat en cours de développement
  (<https://github.com/PnX-SI/gn_module_suivi_habitat_territoire/issues/1>)
- gn_module_suivi_chiro refondu pour devenir un module de GeoNature
  V2 (<https://github.com/PnCevennes/gn_module_suivi_chiro>)
- Projet suivi utilisé comme Frontend générique et autonome pour le
  Suivi chiro (<https://github.com/PnCevennes/projet_suivis_frontend>)
- GeoNature-citizen en cours de développement
  (<https://github.com/PnX-SI/GeoNature-citizen/issues/2>)
- GeoNature-mobile en cours de refonte pour compatibilité avec
  GeoNature V2
  (<https://github.com/PnEcrins/GeoNature-mobile/issues/19>)
- GeoNature-atlas en cours d’ajustements pour compatibilité avec
  GeoNature V2
  (<https://github.com/PnX-SI/GeoNature-atlas/issues/162>)

**Notes de version**

**1.** Pour les utilisateurs utilisant la version 1 de GeoNature :

Il ne s’agit pas de mettre à jour GeoNature mais d’en installer une
nouvelle version. En effet, il s’agit d’une refonte complète.

- Passer à la dernière version 1 de GeoNature (1.9.1)
- Idem pour UsersHub et TaxHub
- Installer GeoNature standalone ou refaire une installation complète
- Adaptez les scripts présents dans `/data/migrations/v1tov2` et
  éxécutez-les

_TODO : MAJ depuis V1 à tester et compléter_

**2.** Pour les utilisateurs utilisant la version 2.0.0.beta5 :

- Supprimer le schéma `gn_synthese` puis le recréer dans sa version
  RC1 (#430)

- Exécuter l’update de la BDD GeoNature
  (`data/migrations/2.0.0beta5-to-2.0.0rc1.sql`) ainsi que celui du
  sous-module Nomenclature
  (<https://github.com/PnX-SI/Nomenclature-api-module/blob/1.2.1/data/update1.1.0to1.2.1.sql>)

- Suivre la procédure habituelle de mise à jour

- Exécuter les commandes suivantes :

      cd geonature/backend
      source venv/bin/activate
      geonature generate_frontend_modules_route
      geonature frontend_build

## 2.0.0.beta5 (2018-07-16)

**Nouveautés**

- Ajout d’un message d’erreur si l’utilisateur n’a pas de JDD ou
  si il y a eu un problème lors de la récupération des JDD de MTD
- Ajout d’une vue matérialisée (`gn_synthese.vm_min_max_for_taxons`)
  et d’une fonction (`gn_synthese.fct_calculate_min_max_for_taxon`)
  permettant de renvoyer des informations sur les observations
  existantes d’un taxon (étendue des observations, date min et max,
  altitude min et max, nombre d’observations) pour orienter la
  validation et la saisie
  (<https://github.com/PnX-SI/gn_module_validation/issues/5>)
- L’export OccTax est désormais basé sur une vue qu’il est possible
  d’adapter
- Ajouts de nouveaux tests automatisés du code et mise en place de
  Travis pour les lancer automatiquement à chaque commit
  (<https://travis-ci.org/PnX-SI/GeoNature>)
- Ajout de données test
- Mise à jour des scripts de déploiement spécifiques de DEPOBIO (MTES)
- Déplacement de la table centrale de gestion des paramètres
  `t_parameters` dans le schéma `gn_commons` (#376)
- Ajout d’un trigger générique pour calculer la géométrie dans la
  projection locale à partir de la géométrie 4326 (#370)
- Regroupement des fichiers liés à l’installation et la mise à jour
  dans un répertoire dédié (`install`) (#383)
- Mise en place de scripts de migration global de la BDD
  (`data/migrations/2.0.0beta4to2.00beta5.sql`) et du schéma
  `pr_occtax`
  (`contrib/occtax/data/migration_2.0.0.beta4to2.0.0.beta5.sql`),
  d’un script générique de migration de l’application
  (`install/migration/migration.sh`) et d’une doc de mise à jour
  (<https://github.com/PnX-SI/GeoNature/blob/develop/docs/installation-standalone.rst#mise-%C3%A0-jour-de-lapplication>)
- Réintégration des fichiers de configuration, de logs et des modules
  externes dans les répertoires de l’application (#375)
- Ajout de routes à `gn_monitoring`
- Ajout d’un trigger pour calculer automatiquement les zonages des
  sites de suivi (`gn_monitoring.fct_trg_cor_site_area()`)
- Améliorations et documentation des commandes d’installation d’un
  module
- Ajout des unités géographiques dans le schéma `ref_geo`
- Ajout d’un bouton `Annuler` dans le formulaire Occtax
- Gestion des conflits de nomenclatures en n’utilisant plus leur
  `id_type` ni leur `id_nomenclature` (#384)
- Migration du SQL de `ref_nomenclautres` dans le dépôt du sous-module
  (<https://github.com/PnX-SI/Nomenclature-api-module>)
- Début de mise en place d’un backoffice (métadonnées et
  nomenclatures)

**Corrections**

- OccTax : Correction du double post
- OccTax : Correction des droits dans les JDD
- OccTax : Correction de l’affichage des observers_txt dans la fiche
  d’un relevé
- Correction de la gestion générique des médias
- Suppression du lien entre `ref_geo` et `ref_nomenclatures` (#374)
- Compléments et relecture de la documentation
- Correction

**Notes de version**

Si vous mettez à jour votre GeoNature depuis une Beta4 :

- Téléchargez la beta5 et renommer les répertoires :

  ```bash
  cd /home/myuser
  wget https://github.com/PnX-SI/GeoNature/archive/geonature2beta.zip
  unzip geonature2beta.zip
  mv /home/<mon_user>/geonature/ /home/<mon_user>/geonature_old/
  mv GeoNature-geonature2beta /home/<mon_user>/geonature/
  ```

- Exécutez le script de migration `install/migration/beta4tobeta5.sh`
  depuis la racine de votre GeoNature :

  ```bash
  cd geonature
  ./install/migration/beta4tobeta5.sh
  ```

Celui-ci va récupérer vos fichiers de configuration, déplacer les
modules et appliquer les changements de la BDD.

- Si vous avez développé des modules externes, voir
  <https://github.com/PnX-SI/GeoNature/issues/375>, en ajoutant un
  lien symbolique depuis le répertoire `external_modules` et en
  réintégrant la configuration du module dans son répertoire `config`

## 2.0.0.beta4 (2018-05-25)

**Nouveautés**

- Synthèse : début de mise en place du backend, de l’API et du
  frontend #345
- Complément de la nomenclature des Méthodes de détermination et
  suppression du champs Complement_Determination.
  Merci \@DonovanMaillard. #341
- Nouveaux composants Angular (SelectSearch, Municipalities,
  Observers)
- Amélioration de composants Angular (Date du jour par défaut, Option
  de tri des nomenclatures, DynamicForm
- Connexion à MTD INPN : Mise à jour des JDD à chaque appel de la
  route
- Finalisation du renommage de Contact en OccTax (BDD, API, backend)
- Droits CRUVED : La définition du CRUVED d’un rôle (utilisateur ou
  groupe) sur un module de GeoNature surcouche ses droits GeoNature
  même si ils sont inférieurs. Si une action du CRUVED n’est pas
  définie au niveau du module, on prend celle de l’application
  parente. #292
- Si un rôle a un R du CRUVED à 0 pour un module, alors celui-ci ne
  lui est pas listé dans le Menu et il ne lui ai pas accessible si il
  en connait l’URL. #360
- Mise en place d’un schéma `gn_commons` dans la BDD qui permet de
  stocker de manière générique des informations qui peuvent être
  communes aux autres modules : l’historique des actions sur chaque
  objet de la BDD, la validation d’une donnée et les médias associés
  à une donnée. Accompagné de fonctions génériques d’historisation et
  de validation des données mises en place sur le module Occtax. #339
- Amélioration de l’ergonomie du MapList de OccTax. #361
- Mise en place d’un export CSV, SHP, GeoJSON paramétrable dans
  OccTax. #363 et #366
- Amélioration du module générique `gn_monitoring` et de ses
  sous-modules <https://github.com/PnCevennes/gn_module_suivi_chiro>
  et <https://github.com/PnCevennes/projet_suivis_frontend>
- Amélioration et compléments des scripts d’installation
- Mise en place d’un script pour la customisation de la plateforme
  nationale
  (<https://github.com/PnX-SI/GeoNature/blob/develop/install_all/configuration_mtes.sh>)

**Documentation**

- Complément des différentes documentations
- Ajout d’une documentation d’administration d’OccTax
  (<https://github.com/PnX-SI/GeoNature/blob/develop/docs/admin-manual.rst#module-occtax>)

## 2.0.0.beta3 (2018-03-28)

**Nouveautés**

- Travail sur le module générique de Suivi intégré à GeoNature
  (`gn_monitoring`). Gestion des fichiers de configuration
- Gestion de l’installation d’un module qui n’a pas de Frontend
  dans GeoNature
- Mise en place de tests automatiques au niveau du Frontend
- Ménage et réorganisation du code du Frontend
- Factorisation et harmonisation des composants génériques Angular
- Suppression des blocs non fonctionnels sur la Home
- Mise à jour de la doc et du MCD
- Possibilité de masquer ou afficher les différents champs dans le
  formulaire Occtax (#344)
- Ajout des nomenclatures dans les filtres d’OccTax à partir du
  nouveau composant `dynamicForm` qui permet de créer dynamiquement un
  formulaire en déclarant les champs (#318)
- Amélioration du composant de recherche d’un taxon en ne recherchant
  que sur les débuts de mot et en affichant en premier les noms de
  référence (ordrer_by cd_nom=cd_ref DESC) - #334
- Mise en place d’une route générique permettant de requêter dans une
  vue non mappée
- Suppression des options vides dans les listes déroulantes des
  nomenclatures
- Ajout de quelques paramètres (niveau de zoom mini dans chaque
  module, ID de la liste des taxons saisissables dans Occtax\...)

**Corrections**

- Correction de la pagination du composant MapList
- Correction des droits attribués automatiquement quand on se connecte
  avec le CAS
- Correction de l’installation optionnelle de UsersHub dans le script
  `install_all.sh`

**Modules annexes**

- Début de refonte du module Suivi chiro
  (<https://github.com/PnCevennes/gn_module_suivi_chiro>) connecté au
  module générique de suivi de GeoNature, dont le front sera externe à
  GeoNature (<https://github.com/PnCevennes/projet_suivi>)
- Maquettage et avancée sur le module Validation
  (<https://github.com/PnX-SI/gn_module_validation>)
- Définition du module Suivi Habitat Territoire
  (<https://github.com/PnX-SI/gn_module_suivi_habitat_territoire>)
- Piste de définition du module Interopérabilité
  (<https://github.com/PnX-SI/gn_module_interoperabilite>)

## 2.0.0.beta2 (2018-03-16)

**Nouveautés**

- Compléments de la documentation (schéma architecture,
  administration, installation, développement, FAQ\...)
- Amélioration de l’ergonomie du module OccTax (composant MapList,
  filtres, colonnes et formulaires) et du module Exports
- Amélioration du composant de recherche d’un taxon (#324)
- Amélioration et optimisation de la sérialisation des données
- Ajout de tests unitaires au niveau du backend
- Ajout d’un mécanisme de log par email (paramètres MAILERROR)
- Migration du module occtax dans le répertoire `/contrib` pour
  homogénéiser les modules
- Création du schéma `gn_monitoring` pour gérer la partie générique
  des modules de suivi (sites et visites centralisés)
- Début de création du module générique des protocoles de suivi
- Début de création du module de gestion des médias

**Corrections**

- Corrections de l’installation globale et autonome
- Renommage Contact en OccTax (en cours)
- Nettoyage du schéma des métadonnées (`gn_meta`)

## 2.0.0.beta1 (2018-02-16)

La version 2 de GeoNature est une refonte complète de l’application.

- Refonte technologique en migrant de PHP/Symfony/ExtJS/Openlayers à
  Python3/Flask/Angular4/Leaflet
- Refonte de l’architecture du code pour rendre GeoNature plus
  générique et modulaire
- Refonte de la base de données pour la rendre plus standarde, plus
  générique et modulaire
- Refonte ergonomique pour moderniser l’application

Présentation et suivi du projet :
<https://github.com/PnX-SI/GeoNature/issues/168>

**Nouveautés**

- Refonte de la base de données du module Contact, renommé en OccTax,
  s’appuyant sur le standard Occurrence de taxons du SINP (#183)
- Développement du module OccTax regroupant les contacts Faune, Flore,
  Fonge et Mortalité (avec formulaire de consultation et de saisie des
  données)
- Développement d’un module et d’une API générique et autonome pour
  la gestion des nomenclatures
  (<https://github.com/PnX-SI/Nomenclature-api-module>). Il permet
  d’avoir un mécanisme générique de centralisation des listes de
  valeurs (nomenclatures) pour ne pas créer des tables pour chaque
  liste : <https://github.com/PnX-SI/Nomenclature-api-module>. Les
  valeurs de chaque nomenclature s’adaptent en fonction des regnes et
  groupe 2 INPN des taxons.
- Découpage de l’application en backend / API / Frontend
- Multilingue au niveau de l’interface et des listes de valeurs avec
  français et anglais intégrés mais extensible à d’autres langues
  (#173)
- Développement de composants génériques pour pouvoir les utiliser
  dans plusieurs modules sans avoir à les redévelopper ni les
  dupliquer (composant CARTE, composant RECHERCHE TAXON, composant
  OBSERVATEURS, composant NOMENCLATURES\...)
- Mise en place d’un référentiel géographique avec un schéma dédié
  (`ref_geo`), partageable avec d’autres applications comprenant une
  table des communes, une table générique des zonages, une table pour
  le MNT et des fonctions pour intersecter point/ligne/polygones avec
  les zonages et le MNT (#228)
- Evolution du schéma `utilisateurs` de UsersHub pour passer d’une
  gestion des droits avec 6 niveaux à un mécanisme plus générique,
  souple et complet. Il permet d’attribuer des actions possibles à un
  rôle (utilisateur ou groupe), sur une portée; dans une application
  ou un module. 6 actions sont possibles dans GeoNature : Create /
  Read / Update / Validate / Export / Delete (aka CRUVED). 3 portées
  de ces actions sont possibles : Mes données / Les données de mon
  organisme / Toutes les données.
- Implémentation de la gestion des droits au niveau de l’API (pour
  limiter les données affichées à un utilisateur en fonction de ses
  droits) et au niveau du Frontend (pour afficher ou non certains
  boutons aux utilisateurs en fonction de leurs droits).
- Par défaut, l’authentification et les utilisateurs sont gérés
  localement dans UsersHub, mais il est aussi possible de connecter
  GeoNature au CAS de l’INPN, sans utiliser GeoNature (utilisé pour
  l’instance nationale INPN de GeoNature). GeoNature peut aussi se
  connecter au webservice METADONNEES de l’INPN pour y récupérer les
  jeux de données en fonction de l’utilisateur connecté.
- Mise en place d’un module d’export. Chaque export s’appuie sur
  une vue. Il sera possible à chaque administrateur d’ajouter autant
  de vues que nécessaires dans son GeoNature. Pour le moment, un
  export au format SINP Occurrence de taxons a été intégré par défaut.
- Développement des métadonnées dans la BDD (schema `gn_meta`) sur la
  base du standard Métadonnées du SINP
  (<http://standards-sinp.mnhn.fr/category/standards/metadonnees/>).
  Elles permettent de gérer des jeux de données, des cadres
  d’acquisition, des acteurs (propriétaire, financeur,
  producteur\...) et des protocoles. Chaque relevé est associé à un
  jeu de données.
- Développement d’un mécanisme de calcul automatique de la
  sensibilité d’une espèce directement dans la BDD (sur la base des
  règles nationales et régionales du SINP + locales éventuellement)
- Intégration du calcul automatique de l’identifiant permanent SINP
  (#209)
- Mise en place d’un mécanisme standardisé de développement de
  modules dans GeoNature (#306)
- Scripts d’installation autonome ou globale de GeoNature sur Debian
  8 et 9

**Documentation**

- Installation globale de GeoNature (avec TaxHub et UsersHub) /
  <https://github.com/PnX-SI/GeoNature/blob/develop/docs/installation-all.rst>
- Installation autonome de GeoNature /
  <https://github.com/PnX-SI/GeoNature/blob/develop/docs/installation-standalone.rst>
- Manuel utilisateur /
  <https://github.com/PnX-SI/GeoNature/blob/develop/docs/user-manual.rst>
- Manuel administrateur /
  <https://github.com/PnX-SI/GeoNature/blob/develop/docs/admin-manual.rst>
- Développement (API, modules et composants) /
  <https://github.com/PnX-SI/GeoNature/blob/develop/docs/development.rst>

Documentation complète disponible sur
<http://geonature.fr/docs/2-0-0-beta1>

**A venir**

- Finalisation MCD du module Synthèse
- Triggers d’alimentation automatique de la Synthèse depuis le module
  OccTax
- Développement de l’interface du module Synthèse
- Amélioration et généricité du module OccTax (médias, import GPX,
  champs masquables et pseudo-champs)
- Généricité du module d’export
- Développement du module de validation (#181)
- Développement d’un module de suivi des habitats avec une gestion
  générique des sites et visites de suivi
- Développement d’un module de collecte citoyenne (#242)

## Versions 1 (2014-2018)

Pour consulter les notes des versions 1 de GeoNature, elles sont disponibles dans la branche dédiée : https://github.com/PnX-SI/GeoNature/blob/v1/docs/changelog.rst
