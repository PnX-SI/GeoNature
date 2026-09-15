# Occhab - Champs additionnels

Les champs additionnels peuvent être définis à chacun des deux niveaux du formulaire (objet de rattachement) :

- station → `OCCHAB_STATION`
- habitat → `OCCHAB_HABITAT`

Ils se déclarent depuis le module Admin, en choisissant le module `OCCHAB` puis l'un de ces deux objets.

Leurs valeurs sont stockées au format JSON dans la colonne `additional_data` des tables `pr_occhab.t_stations` et `pr_occhab.t_habitats`.

## Récupérer les champs d'un niveau

- <https://URL/geonature/api/gn_commons/additional_fields?module_code=OCCHAB&object_code=OCCHAB_STATION>
- <https://URL/geonature/api/gn_commons/additional_fields?module_code=OCCHAB&object_code=OCCHAB_HABITAT>

⚠️ Il faut bien faire **un appel par niveau**. Lorsque plusieurs `object_code` sont passés à la route, les conditions sont combinées avec un ET : un appel `object_code=OCCHAB_STATION,OCCHAB_HABITAT` ne renverrait que les champs rattachés simultanément aux deux objets.

Un appel sans `object_code` renvoie les champs des deux niveaux confondus ; on les distingue alors via l'attribut `objects`, qui contient le `code_object` de chaque rattachement.

## Champs globaux et champs rattachés à un jeu de données

Comme pour Occtax, un champ additionnel peut être global au module (affiché en permanence) ou rattaché à un ou plusieurs jeux de données (affiché uniquement lorsque l'un de ces JDD est sélectionné).

On les distingue via l'attribut `datasets` : si le tableau est vide, le champ est global.

Le module Occhab charge l'ensemble des champs en une requête par niveau, puis filtre côté client selon le jeu de données sélectionné dans le formulaire — le tri est donc immédiat au changement de JDD, sans appel supplémentaire.

## Types de champs

Les widgets disponibles sont ceux du formulaire dynamique commun de GeoNature (`text`, `textarea`, `number`, `html`, `select`, `radio`, `checkbox`, `multiselect`, `nomenclature`, `date`, `time`…), décrits dans [la documentation des champs additionnels d'Occtax](occtax-additional-fields.md#type-de-champs).

Les champs de type `nomenclature` stockent l'`id_nomenclature`, accompagné de son libellé sous une clé préfixée `_label_` (par exemple `_label_mon_champ`). Ce libellé est ajouté par le backend à l'enregistrement, et c'est lui qui est affiché en consultation.
