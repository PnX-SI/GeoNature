const hideDetails = ({ value, meta, attribut_name }) => {
  const details = meta.details;
  const cond =
    details && details.length && !value['displayDetails'] && details.includes(attribut_name);
  return cond;
};

export const mediaFormDefinitionsDict = {
  file: {
    attribut_label: 'Choisir un fichier',
    type_widget: 'file',
    hidden: ({ value }) => !value.bFile,
    required: ({ value }) => value.bFile && !value.media_path,
    sizeMax: null,
    meta: null,
    accept: ({ value, meta }) => {
      if (!value.id_nomenclature_media_type) return '*';
      const label_fr = meta.nomenclatures[value.id_nomenclature_media_type].label_fr;
      switch (label_fr) {
        case 'Photo': {
          return 'image/*';
        }
        case 'Vidéo (fichier)': {
          return 'video/*';
        }
        case 'Audio': {
          return 'audio/*';
        }
        case 'PDF': {
          return '.pdf';
        }
        case 'Excel/CSV (fichier)': {
          return '.xls,.csv,.xlsx';
        }
        default:
          return '*';
      }
    },
  },
  media_url: {
    attribut_label: 'URL',
    type_widget: 'text',
    hidden: ({ value }) => value.bFile,
    required: ({ value }) => !value.bFile,
  },
  displayDetails: {
    type_widget: 'bool_checkbox',
    attribut_label: 'Avancé',
    definition: "Afficher plus d'options pour le formulaire",
    value: true,
    hidden: ({ meta }) => !(meta.details && meta.details.length) || meta.hideDetailsFields,
  },
  id_nomenclature_media_type: {
    attribut_label: 'Type de média',
    type_widget: 'nomenclature',
    required: true,
    code_nomenclature_type: 'TYPE_MEDIA',
    hidden: hideDetails,
  },
  bFile: {
    attribut_label: 'Import du média',
    type_widget: 'bool_radio',
    values: ['Uploader un fichier', 'Renseigner une URL'],
    value: true,
    required: true,
    hidden: ({ value, meta, attribut_name }) => {
      if (!value.id_nomenclature_media_type) {
        return;
      }
      const label_fr = meta.nomenclatures[value.id_nomenclature_media_type].label_fr;
      return (
        [
          'Vidéo Dailymotion',
          'Vidéo Youtube',
          'Vidéo Viméo',
          'Page web',
          'Vidéo (fichier)',
        ].includes(label_fr) || hideDetails({ value, meta, attribut_name })
      );
    },
  },
  title_fr: {
    attribut_label: 'Titre',
    type_widget: 'text',
    required: true,
    hidden: hideDetails,
  },
  description_fr: {
    attribut_label: 'Description',
    type_widget: 'text',
    hidden: hideDetails,
  },
  author: {
    attribut_label: 'Auteur',
    type_widget: 'text',
    hidden: hideDetails,
  },
  id_media: {
    attribut_label: 'ID media',
    type_widget: 'number',
    hidden: true,
  },
  uuid_attached_row: {
    attribut_label: 'uuid_attached_row',
    type_widget: 'text',
    hidden: true,
  },
  media_path: {
    attribut_label: 'Path',
    type_widget: 'text',
    hidden: true,
  },
  id_table_location: {
    attribut_label: 'ID table location',
    type_widget: 'number',
    hidden: true,
  },
};
