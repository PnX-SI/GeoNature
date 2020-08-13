export const mediaFormDefinitionsDict = {
  "title_fr": {
    "attribut_label": "Titre",
    "type_widget": "text",
    "required": true
  },
  "description_fr": {
    "attribut_label": "Description",
    "type_widget": "text",
    "required": true
  },
  "author": {
    "attribut_label": "Auteur",
    "type_widget": "text",
    "required": true
  },
  "id_nomenclature_media_type": {
    "attribut_label": "Type de média",
    "type_widget": "nomenclature",
    "required": true,
    "code_nomenclature_type": "TYPE_MEDIA",
  },
  "bFile":{
    "attribut_label": "Import du média",
    "type_widget": 'select',
    "values": ["Uploader un fichier", "Renseigner une url"],
    "value": "Uploader un fichier",
    "noNullOption": true,
    "required": true,
  },
  "media_url": {
    "attribut_label": "Url",
    "type_widget": "text",
    "hidden": ({value}) => value.bFile != "Renseigner une url",
    "required": ({value}) => value.bFile == "Renseigner une url",
  },
  "file": {
    "attribut_label": "Choisir un fichier",
    "type_widget": "file",
    "hidden": ({value}) => value.bFile != "Uploader un fichier",
    "required": ({value}) => value.bFile == "Uploader un fichier",
    "sizeMax": 2000
  },
  "id_media": {
    "attribut_label": "ID media",
    "type_widget": "number",
    "hidden": true
  },
  "uuid_attached_row": {
    "attribut_label": "uuid_attached_row",
    "type_widget": "text",
    "hidden": true
  },
  "media_path": {
    "attribut_label": "Path",
    "type_widget": "text",
    "hidden": true
  },
  "id_table_location": {
    "attribut_label": "ID table location",
    "type_widget": "number",
    "hidden": true
  },
}
