export const FIELDS_CONTENT_STEP_UPLOAD = {
  fileUploadField: {
    defaultValue: 'import/synthese/valid_file_test_link_list_import_synthese.csv',
    newValue: 'import/synthese/valid_file_import_synthese_test_changed.csv',
    parentSelector: '[data-qa="import-new-upload-file"]',
    selector: '[data-qa="import-new-upload-file-label"]',
  },
};

export const FIELDS_CONTENT_STEP_FILE_DECODE = {
  encodeField: {
    defaultValue: 'utf-8 (auto-détecté)',
    newValue: 'iso-8859-15',
    selector: '[data-qa="import-new-decode-encode"]',
  },
  formatField: {
    defaultValue: 'csv (auto-détecté)',
    newValue: 'geojson',
    selector: '[data-qa="import-new-decode-format"]',
  },
  delimiterField: {
    defaultValue: '; (auto-détecté)',
    newValue: ',',
    selector: '[data-qa="import-new-decode-delimiter"]',
  },
  sridField: {
    defaultValue: 'WGS84',
    newValue: 'Lambert93',
    selector: '[data-qa="import-new-decode-srid"]',
  },
};
