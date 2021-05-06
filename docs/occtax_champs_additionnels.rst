
Cette documentation mentionne les spécifications pour ajouter des champs additionnels dans OCCTAX en fonction d'un jeu de données:

* Créer un jeu de données et récupérer son ID :
* Créer une liste de taxons dans Taxhub pour chaque jeu de données :
* Configurer les champs additionnels dans OCCTAX dans le fichier geonature/contrib/occtax/config/conf_gn_module.toml :
exemple pour pelophylax et tortues marines :
[DATASETS_CONFIG]
    [[DATASETS_CONFIG.FORMFIELDS]]
        DATASET = 1
        ID_TAXON_LIST = 5
        [[DATASETS_CONFIG.FORMFIELDS.RELEVE]]
            type_widget = "html"
            class = "alert alert-primary"
            attribut_name = "presentation"
            html = "<p>A partir d'ici, on est dans le formulaire propre à la saisie des pélophylax <br><a href='' target='_blank'>lien vers le protocole</a></p>"
        [[DATASETS_CONFIG.FORMFIELDS.RELEVE]]
            type_widget = "select"
            attribut_label = "Expertise"
            attribut_name = "expertise"
            values = ["Débutant", "Expérimenté", "Chevronné"]
        [[DATASETS_CONFIG.FORMFIELDS.RELEVE]]
            required = false
            type_widget = "select"
            attribut_label = "Catégories paysagères"
            attribut_name = "cat_paysagere"
            values = [ "Eaux continentales","Eaux maritimes","Zones urbanisées","Zones industrielles ou commerciales et réseaux de communication","Prairies","Mines, décharges et chantiers","Espaces verts artificialisés, non agricoles","Terres arables","Forêts","Cultures permanentes","Zones agricoles hétérogènes","Milieux à végétation arbustive et/ou herbacée","Espaces ouverts, sans ou avec peu de végétation","Zones humides intérieures","Zones humides maritimes"]
        [[DATASETS_CONFIG.FORMFIELDS.RELEVE]]
            required = false
            type_widget = "select"
            attribut_label = "Description du milieu aquatique"
            attribut_name = "desc_milieu_aquatique"
            values = [ "Source",
                "Marais saumâtre",
                "Ruisselet/Ruisseau (< 3 m de large)",
                "Canal navigable",
                "Etang (50 à 450 m²)",
                "Rivière (entre 3 et 10 m de large)",
                "Grand cours d’eau (> 10 m de large)",
                "Mare (- de 50 m²)",
                "Fossé",
                "Marais / Tourbière",
                "Lac / Grand réservoir",
                "Milieu aquatique cultivé",
                "Prairie humide",
                "Estuaire"
            ]

        [[DATASETS_CONFIG.FORMFIELDS.OCCURRENCE]]
            type_widget = "text"
            attribut_label = "Numéro de la dérogation de capture"
            attribut_name = "num_derogation"
            required = false

        [[DATASETS_CONFIG.FORMFIELDS.COUNTING]]
            type_widget = "html"
            class = "alert alert-warning"
            attribut_name = "media"
            html = "Liste des médias attendus :<div><a data-toggle=\"collapse\" href=\"#photo1\" role=\"button\" aria-expanded=\"false\" aria-controls=\"photo1\"><i class=\"fa fa-question-circle\"></i>&nbsp;Prise de vue générale avec l’individu en main à côté d’un papier avec le code de l’individu</a><div class=\"collapse\" id=\"photo1\"><img src=\"custom/images/pelophylax.JPG\" alt=\"\" width=\"370\" height=\"235\"></img></div></div><div><a data-toggle=\"collapse\" href=\"#photo2\" role=\"button\" aria-expanded=\"false\" aria-controls=\"photo2\"><i class=\"fa fa-question-circle\"></i>&nbsp;Prise de vue détaillée des palmures étendues de l’individu</a><div class=\"collapse\" id=\"photo2\"><img src=\"custom/images/palmure.gif\" alt=\"\" width=\"370\" height=\"235\"></img></div></div><div><a data-toggle=\"collapse\" href=\"#photo3\" role=\"button\" aria-expanded=\"false\" aria-controls=\"photo3\"><i class=\"fa fa-question-circle\"></i>&nbsp;Prise de vue détaillée du tubercule métatarsien de l’individu</a><div class=\"collapse\" id=\"photo3\"><img src=\"custom/images/tubercule.jpg\" alt=\"\" width=\"370\" height=\"235\"></img></div></div><div><a data-toggle=\"collapse\" href=\"#photo4\" role=\"button\" aria-expanded=\"false\" aria-controls=\"photo4\"><i class=\"fa fa-question-circle\"></i>&nbsp;Prise de vue détaillée des bourrelets vomériens de l’individu</a><div class=\"collapse\" id=\"photo4\"><p>Pour ouvrir la bouche d’une grenouille, il est préférable d'utiliser un instrument (couteau pas trop pointu, critériumavec pointe plastique), ou une brindille. Pour procéder, tenir la grenouille face ventrale vers soi, placer l’outil dans lacommissure, et dès que la bouche s’ouvre glisser le pouce pour baisser la mâchoire inférieure. Pour prendre lecliché, il est plus simple d'être à deux: l'un tient la grenouille et l'autre prend la photo</p><img src=\"custom/images/bourrelet.jpg\" alt=\"\" width=\"370\" height=\"235\"></img></div></div><div><a data-toggle=\"collapse\" href=\"#photo5\" role=\"button\" aria-expanded=\"false\" aria-controls=\"photo5\"><i class=\"fa fa-question-circle\"></i>&nbsp;Prise de vue détaillée de l’arrière des cuisses de l’individu</a><div class=\"collapse\" id=\"photo5\"><img src=\"custom/images/cuisse.JPG\" alt=\"\" width=\"370\" height=\"235\"></img></div></div><div><a data-toggle=\"collapse\" href=\"#photo6\" role=\"button\" aria-expanded=\"false\" aria-controls=\"photo6\"><i class=\"fa fa-question-circle\"></i>&nbsp;Prise de vue détaillée de l’aine de l’individu</a><div class=\"collapse\" id=\"photo6\"><img src=\"custom/images/aine.JPG\" alt=\"\" width=\"370\" height=\"235\"></img><img src=\"custom/images/aine2.JPG\" alt=\"\" width=\"370\" height=\"235\"></img></div></div><div><a data-toggle=\"collapse\" href=\"#photo7\" role=\"button\" aria-expanded=\"false\" aria-controls=\"photo7\"><i class=\"fa fa-question-circle\"></i>&nbsp;Prise de vue d’ensemble en milieu naturel</a><div class=\"collapse\" id=\"photo7\"><img src=\"custom/images/naturel.JPG\" alt=\"\" width=\"370\" height=\"235\"></img></div></div><div><a data-toggle=\"collapse\" href=\"#son1\" role=\"button\" aria-expanded=\"false\" aria-controls=\"son1\"><i class=\"fa fa-question-circle\"></i>&nbsp;Fichier audio</a><div class=\"collapse\" id=\"son1\"><p>Pour les enregistrements : à la fin de chaque enregistrement, parler dans le micro pour indiquer le lieu, la date etl’heure de prise de son.Pour enregistrer, il est important d’essayer d’avoirdes phrases longues ou \"excitées\" (ce qui peutnécessiter d'attendre un peu). Un chant aboutit à 2ou 3 phrases excitées, puis à une dernière, bâclée.Cette manière de chanter, si elle est enregistréedans sa totalité, est celle qui permet de déterminerles phrases excitées. Dans ces phrases, lescaractéristiques du chant sont plus marquées(augmentation du nombre de notes, phrasesrapprochées, volume plus fort) et les différencesentre les espèces s’en trouvent accrues. Il estpossible d'utiliser différents outils pour enregistrer:dictaphone, téléphone portable, appareil photo,etc. Dans tous les cas, tenir compte du fait que,plus les bruits de fonds sont importants (rainettes,vent, etc.), plus l'analyse du chant sera difficile.</p><img src=\"custom/images/son.jpg\" alt=\"\" width=\"370\" height=\"235\"></img></div></div>"
        [[DATASETS_CONFIG.FORMFIELDS.COUNTING]]
            type_widget = "html"
            class = "alert alert-warning"
            attribut_name = "presentation"
            html = "<p>A partir d'ici, on est dans le formulaire propre à la saisie des pélophylax <br><a href='' target='_blank'>lien vers le protocole</a></p>"
        [[DATASETS_CONFIG.FORMFIELDS.COUNTING]]
            type_widget = "radio"
            attribut_label = "Prélèvement ADN effectué"
            attribut_name = "prelev_adn"
            required = false
            values = ["Oui", "Non"]
        [[DATASETS_CONFIG.FORMFIELDS.COUNTING]]
            type_widget = "text"
            attribut_label = "Lieu de stockage de l’ADN prélevé"
            attribut_name = "lieu_stockage_adn"
            required = false

    [[DATASETS_CONFIG.FORMFIELDS]]
        DATASET = 2
        ID_TAXON_LIST = 6
        [[DATASETS_CONFIG.FORMFIELDS.RELEVE]]
            type_widget = "html"
            class = "alert alert-warning"
            attribut_name = "presentation"
            html = "<p>A partir d'ici, on est dans le formulaire propre à la saisie des tortues marine</p>"

* Ensuite il faut relancer la commande de mise à jour du module OCCTAX
::

    cd geonature/backend
    source venv/bin/activate
    geonature update_module_configuration occtax
    deactivate

* Créer ou modifier la vue nécessaire pour l’export en ajoutant les champs additionnels de cet facon :
::

    (rel.additional_fields -> 'expertise'::text)::text AS expertise,
    (ccc.additional_fields -> 'commentaires_obs'::text)::text AS "commentaires_obs"	
