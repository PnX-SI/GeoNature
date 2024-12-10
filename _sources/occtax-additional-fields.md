Occtax - Champs additionnels
============================

Les champs additionnels peuvent être définis à chacun des trois niveaux du formulaire (objet de rattachement): 

* releve
* occurrence
* dénombrement

Le endpoint pour connaitre les champs additionnels est : 

* <https://URL/geonature/api/gn_commons/additional_fields?module_code=OCCTAX>

Le JSON renvoie le tableau de champs additionnels d'Occtax (trois niveaux du formulaire confondu).

Pour connaitre le niveau (releve, occurrence, dénombrement), on regarde la tableau de l'attribut "objects" qui contient un attribut "code_object"

* revele = OCCTAX_OCCURENCE
* occurrence = OCCTAX_OCCURENCE
* denombrement = OCCTAX_RELEVE

Il y a aussi la possibilité de faire trois appels pour les distinguer : 

* <https://URL/geonature/api/gn_commons/additional_fields?module_code=OCCTAX&object_code=OCCTAX_RELEVE>
* <https://URL/geonature/api/gn_commons/additional_fields?module_code=OCCTAX&object_code=OCCTAX_OCCURENCE>
* <https://URL/geonature/api/gn_commons/additional_fields?&module_code=OCCTAX&object_code=OCCTAX_DENOMBREMENT>


Les champs additionnels peuvent également être globaux à tout le module (à afficher tout le temps), ou simplement rattaché à un jeu de données (à afficher uniquement si ce jeu de donnée est selectionné)

On distingue les champs additionnels globaux de ceux rattaché à un JDD via l'attribut "datasets". Si le tableau est vide alors ils sont globaux, sinon ils sont affichés uniquement quand un des JDD de ce tableau est 
selectionné en interface.


Type de champs
--------------

Le JSON renvoyé par les routes précédentes contient un dictionnaire "type_widget" qui contient lui même l'information du type de widget sous l'attribut "widget_name".

Les champs additionnels peuvent définir les "widgets" suivants :

- text (un champ comportant du texte libre : input type text)
- textarea (input type textarea - champ comportant du texte libre)
- number (input type number - entier ou réel)
- html (champs de type "présentation" permettant de décorer le formulaire: peut contenir des balises html). 
- select (input type select. Les valeurs pour peupler l'input sont dans le champs "field_values" de la route)
- radio (input type radio. Les valeurs pour peupler l'input sont dans le champs "field_values" de la route)
- checkbox (input type checkbox. Les valeurs pour peupler l'input sont dans le champs "field_values" de la route. Ce widget renvoie toujours un tableau de valeurs.)
- multiselect (input de type select à choix multiple.  Les valeurs pour peupler l'input sont dans le champs "field_values" de la route
- nomenclature (un champ select renvoyant à une nomenclature GeoNature. Les valeurs de ce "select" sont donc à précharger en synchronisation. Le code de nomenclature se trouve à l'attribut "code_nomenclature_type")

Widget non géré :

- datalist : necessite de charger des liste à partir d'une API externe
- time : l'heure est déjà gérée par occtax mobile
- date : idem

Autres informations
-------------------

- l'attribut "required" (booléen) défini si le champs est obligatoire. On ne doit pas pouvoir passer à l'écran suivant si un des champs obligatoire n'est pas rempli
- l'attribut "order" (integer) défini l'ordre d'affichage des champs pour chacun des trois niveaux du formulaire. Ce champs n'est pas obligatoire et peut être null. Si null alors le champs apparaît après ceux qui sont ordonnés
- l'attribut "value" défini la valeur par défaut de l'input. Celle-ci est préchargée à l'affichage du champ
- les champs de type nomenclature peuvent être filtrés selon leurs "cd_nomenclature". Les cd_nomenclatures à filtrer se retrouve dans l'attribut "additional_attributes" puis "cd_nomenclatures" qui est un tableau. Le backend de geonature permet directement de filtrer ces cd_nomenclatures : <https://URL/geonature/api/nomenclatures/nomenclature/VENT?regne=&group2_inpn=&orderby=label_default&cd_nomenclature=VENT_2&cd_nomenclature=VENT_3> (voir postman). Ce filtre pourrait également être fait côté mobile, au choix

Médias
======

La route à utiliser est la suivante : <https://URL/geonature/api/gn_commons/media>.

L'idée est donc de d'abord poster l'occurence est ses dénombrement. L'API renvoie les dénombrements ainsi que les médias en conservant l'ordre de l'envoi. 

On récupère donc l'UUID du dénombrement pour l'utiliser dans la route de POST des médias.

Celle-ci attend :

- id_table_location : <https://URL/geonature/api/gn_commons/get_id_table_location/pr_occtax.cor_counting_occtax>
- id_nomenclature_media_type (on ne propose que "Photo" pour le mobile) : <https://URL/geonature/api/nomenclatures/nomenclature/TYPE_MEDIA?regne=&group2_inpn=&orderby=label_default>
- title_fr : <datetime> nom du taxon 
- description : <taxon> observé le <date de l'obs>
- auteur : la personne loggué 






