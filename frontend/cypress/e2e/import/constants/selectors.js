export const STEP_NAMES = ['upload', 'decode', 'fieldmapping', 'contentmapping', 'import'];

export const SELECTORS_NAVIGATION = {
  step: {
    upload: {
      back_btn_selector: '',
      next_btn_selector: '[data-qa="import-new-upload-validate"]',
    },
    decode: {
      back_btn_selector: '[data-qa="import-file-decode-back-btn"]',
      step_btn_selector: '[data-qa="import-file-decode-step-btn"]',
      next_btn_selector: '[data-qa="import-new-decode-validate"]',
    },
    fieldmapping: {
      back_btn_selector: '[data-qa="import-fieldmapping-model-back-btn"]',
      step_btn_selector: '[data-qa="import-fieldmapping-step-btn"]',
      next_btn_selector: '[data-qa="import-new-fieldmapping-model-validate"]',
    },
    contentmapping: {
      back_btn_selector: '[data-qa="import-contentmapping-back-btn"]',
      step_btn_selector: '[data-qa="import-contentmapping-step-btn"]',
      next_btn_selector: '[data-qa="import-new-contentmapping-model-validate"]',
    },
    import: {
      back_btn_selector: '[data-qa="import-data-back-btn"]',
      step_btn_selector: '[data-qa="import-data-step-btn"]',
      next_btn_selector: '[data-qa="import-new-verification-start"]',
    },
  },
  general: {
    save_and_quit_btn_selector: '[data-qa="import-new-footer-save"]',
    cancel_and_delete_import_btn_selector: '[data-qa="import-new-footer-delete"]',
    'delete-import-modal-btn-selector': '[data-qa="modal-delete-validate"]',
  },
};

export const getSelectorsForStep = (stepName) => {
  const selectors = SELECTORS_NAVIGATION.step[stepName];
  if (!selectors) {
    throw new Error(`No selectors found for step: ${stepName}`);
  }
  return selectors;
};

// ////////////////////////////////////////////////////////////////////////////
//
// ////////////////////////////////////////////////////////////////////////////

export const SELECTOR_IMPORT_MODAL_DELETE = '[data-qa=import-modal-delete]';
export const SELECTOR_IMPORT_MODAL_DELETE_VALIDATE = '[data-qa=modal-delete-validate]';

export const SELECTOR_IMPORT_MODAL_EDIT = '[data-qa=import-modal-edit]';
export const SELECTOR_IMPORT_MODAL_EDIT_VALIDATE = '[data-qa=modal-edit-validate]';

export const SELECTOR_IMPORT_MODAL_DESTINATION_START = '[data-qa=import-modal-destination-start]';
export const SELECTOR_IMPORT_FIELDMAPPING_DATE_MIN = '[data-qa=import-fieldmapping-theme-date_min]';
export const SELECTOR_IMPORT_FIELDMAPPING_OBSERVERS =
  '[data-qa=import-fieldmapping-theme-observers]';
export const SELECTOR_IMPORT_FIELDMAPPING_NOM_CITE = '[data-qa=import-fieldmapping-theme-nom_cite]';
export const SELECTOR_IMPORT_FIELDMAPPING_WKT = '[data-qa=import-fieldmapping-theme-WKT]';
export const SELECTOR_IMPORT_FIELDMAPPING_CD_HAB = '[data-qa=import-fieldmapping-theme-cd_hab]';
export const SELECTOR_IMPORT_FIELDMAPPING_CD_NOM = '[data-qa=import-fieldmapping-theme-cd_nom]';
export const SELECTOR_IMPORT_FIELDMAPPING_DATASET =
  '[data-qa=import-fieldmapping-theme-unique_dataset_id]';

export const SELECTOR_IMPORT_FIELDMAPPING_DEFAULT_ALTITUDE_MAX =
  '[data-qa=import-fieldmapping-theme-default-altitude_max] [data-qa=field-number-altitude_max_default_value]';
export const SELECTOR_IMPORT_FIELDMAPPING_DEFAULT_NOM_CITE =
  '[data-qa=import-fieldmapping-theme-default-nom_cite] [data-qa=field-textarea-nom_cite_default_value]';
export const SELECTOR_IMPORT_FIELDMAPPING_DEFAULT_DATE_MIN =
  '[data-qa=import-fieldmapping-theme-default-date_min] [data-qa=input-date]';
export const SELECTOR_IMPORT_FIELDMAPPING_DEFAULT_NOMENCLATURE_GEO_OBJECT_NATURE =
  '[data-qa=import-fieldmapping-theme-default-id_nomenclature_geo_object_nature] ng-select';

export const SELECTOR_IMPORT_FIELDMAPPING_DEFAULT_STATION_NAME =
  '[data-qa=import-fieldmapping-theme-default-station_name] [data-qa=field-textarea-station_name_default_value]';
export const SELECTOR_IMPORT_FIELDMAPPING_DEFAULT_NOMENCLATURE_DETERMINATION_TYPE =
  '[data-qa=import-fieldmapping-theme-default-id_nomenclature_determination_type] ng-select';

export const SELECTOR_IMPORT_FIELDMAPPING_DEFAULT_DATASET =
  '[data-qa=import-fieldmapping-theme-default-unique_dataset_id] ng-select';

export const SELECTOR_IMPORT_FIELDMAPPING_VALIDATE =
  '[data-qa=import-new-fieldmapping-model-validate]';
export const SELECTOR_IMPORT_FIELDMAPPING_BUTTON_DELETE =
  '[data-qa=import-fieldmapping-selection-button-delete]';
export const SELECTOR_IMPORT_FIELDMAPPING_BUTTON_DELETE_OK =
  '[data-qa=import-fieldmapping-selection-modal-delete-ok]';
export const SELECTOR_IMPORT_FIELDMAPPING_SELECTION =
  '[data-qa=import-fieldmapping-selection-select]';
export const SELECTOR_IMPORT_FIELDMAPPING_SELECTION_RENAME =
  '[data-qa=import-fieldmapping-selection-button-rename]';
export const SELECTOR_IMPORT_FIELDMAPPING_SELECTION_RENAME_OK =
  '[data-qa=import-fieldmapping-selection-rename-ok]';
export const SELECTOR_IMPORT_FIELDMAPPING_SELECTION_RENAME_TEXT =
  '[data-qa=import-fieldmapping-selection-rename-text]';
export const SELECTOR_IMPORT_FIELDMAPPING_MODAL = '[data-qa=import-fieldmapping-saving-modal]';
export const SELECTOR_IMPORT_FIELDMAPPING_MODAL_CANCEL =
  '[data-qa=import-fieldmapping-saving-modal-cancel]';
export const SELECTOR_IMPORT_FIELDMAPPING_MODAL_CLOSE =
  '[data-qa=import-fieldmapping-saving-modal-close]';
export const SELECTOR_IMPORT_FIELDMAPPING_MODAL_OK =
  '[data-qa=import-fieldmapping-saving-modal-ok]';
export const SELECTOR_IMPORT_FIELDMAPPING_MODAL_NEW_OK =
  '[data-qa=import-fieldmapping-saving-modal-new-ok]';
export const SELECTOR_IMPORT_FIELDMAPPING_MODAL_NAME =
  '[data-qa=import-fieldmapping-saving-modal-mapping-name]';
export const SELECTOR_IMPORT_FOOTER_DELETE = '[data-qa=import-new-footer-delete]';
export const SELECTOR_IMPORT_FOOTER_SAVE = '[data-qa=import-new-footer-save]';
export const SELECTOR_IMPORT_LIST = '[data-qa="import-list"]';
export const SELECTOR_IMPORT_LIST_TABLE = '[data-qa=import-list-table]';
export const SELECTOR_IMPORT_LIST_TOOLBAR = '[data-qa=import-list-toolbar]';
export const SELECTOR_IMPORT_LIST_TOOLBAR_DESTINATIONS =
  '[data-qa=import-list-toolbar-destinations]';
export const SELECTOR_IMPORT_LIST_TOOLBAR_SEARCH = '[data-qa=import-list-toolbar-search]';
export const SELECTOR_DESTINATIONS = '[data-qa=destinations]';
export const SELECTOR_IMPORT = '[data-qa=gn-sidenav-link-IMPORT]';
export const SELECTOR_IMPORT_UPLOAD_FILE = '[data-qa=import-new-upload-file]';
export const SELECTOR_IMPORT_UPLOAD_VALIDATE = '[data-qa=import-new-upload-validate]';
export const SELECTOR_IMPORT_CONTENTMAPPING_STEP_BUTTON =
  '[data-qa=import-contentmapping-step-btn]';
export const SELECTOR_IMPORT_CONTENTMAPPING_BUTTON_DELETE =
  '[data-qa=import-contentmapping-selection-button-delete]';
export const SELECTOR_IMPORT_CONTENTMAPPING_MODAL_DELETE_OK =
  '[data-qa=import-contentmapping-selection-modal-delete-ok]';
export const SELECTOR_IMPORT_CONTENTMAPPING_VALIDATE =
  '[data-qa=import-contentmapping-model-validate]';
export const SELECTOR_IMPORT_CONTENTMAPPING_SELECT = '[data-qa=import-contentmapping-model-select]';
export const SELECTOR_IMPORT_CONTENTMAPPING_MODAL = '[data-qa=import-contentmapping-saving-modal]';
export const SELECTOR_IMPORT_CONTENTMAPPING_MODAL_OK =
  '[data-qa=import-contentmapping-saving-modal-ok]';
export const SELECTOR_IMPORT_CONTENTMAPPING_MODAL_NEW_OK =
  '[data-qa=import-contentmapping-saving-modal-new-ok]';
export const SELECTOR_IMPORT_CONTENTMAPPING_MODAL_NAME =
  '[data-qa=import-contentmapping-saving-modal-mapping-name]';
export const SELECTOR_IMPORT_CONTENTMAPPING_MODAL_CLOSE =
  '[data-qa=import-contentmapping-saving-modal-close]';
export const SELECTOR_IMPORT_CONTENTMAPPING_FORM = '[data-qa=import-contentmapping-form]';

export const SELECTOR_IMPORT_CONTENTMAPPING_SELECTION_RENAME =
  '[data-qa=import-contentmapping-selection-button-rename]';
export const SELECTOR_IMPORT_CONTENTMAPPING_SELECTION_RENAME_OK =
  '[data-qa=import-contentmapping-selection-rename-ok]';
export const SELECTOR_IMPORT_CONTENTMAPPING_SELECTION_TEXT =
  '[data-qa=import-contentmapping-selection-rename-text]';
export const SELECTOR_IMPORT_NEW_VERIFICATION_START = '[data-qa=import-new-verification-start]';

export const SELECTOR_IMPORT_RECAPITULATIF = '[data-qa=import-recapitulatif]';
export const SELECTOR_IMPORT_RECAPITULATIF_MAP = '[data-qa=import-recapitulatif-map]';

export const SELECTOR_IMPORT_REPORT = '[data-qa=import-report]';
export const SELECTOR_IMPORT_REPORT_DOWNLOAD_PDF = '[data-qa=import-report-download-pdf]';
export const SELECTOR_IMPORT_REPORT_MAP = '[data-qa=import-report-map]';
export const SELECTOR_IMPORT_REPORT_CHART = '[data-qa=import-report-chart]';
export const SELECTOR_IMPORT_REPORT_ERRORS_TITLE = '[data-qa=import-report-errors-title]';
export const SELECTOR_IMPORT_REPORT_ERRORS_CSV = '[data-qa=import-report-errors-csv]';

export const LIST_TABLE_ACTIONS = ['edit', 'report', 'csv', 'delete'];
export function getSelectorImportListTableAction(rowIndex, action) {
  return `[data-qa="import-list-table-row-${rowIndex}-actions-${action}"]`;
}

export function getSelectorImportListTableRowCSV(rowIndex) {
  return getSelectorImportListTableAction(rowIndex, 'csv');
}

export function getSelectorImportListTableRowDelete(rowIndex) {
  return getSelectorImportListTableAction(rowIndex, 'delete');
}

export function getSelectorImportListTableRowEdit(rowIndex) {
  return getSelectorImportListTableAction(rowIndex, 'edit');
}

export function getSelectorImportListTableRowReport(rowIndex) {
  return getSelectorImportListTableAction(rowIndex, 'report');
}

export function getSelectorImportListTableRowFile(rowIndex) {
  return `[data-qa="import-list-table-row-${rowIndex}-fichier"]`;
}

export function getSelectorImportListTableRowId(rowIndex) {
  return `[data-qa="import-list-table-row-${rowIndex}-id-import"]`;
}
