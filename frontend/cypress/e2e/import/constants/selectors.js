export const STEP_NAMES = ['upload', 'decode', 'fieldmapping', 'contentmapping', 'import'];

export const SELECTORS_NAVIGATION = {
step:{    
    'upload': {
            'back_btn_selector': '',
            'next_btn_selector': '[data-qa="import-new-upload-validate"]',
    },
    'decode': {
            'back_btn_selector': '[data-qa="import-file-decode-back-btn"]',
            'step_btn_selector': '[data-qa="import-file-decode-step-btn"]',
            'next_btn_selector': '[data-qa="import-new-file-decode-validate"]',
    },
    'fieldmapping': {
            'back_btn_selector': '[data-qa="import-fieldmapping-back-btn"]',
            'step_btn_selector': '[data-qa="import-fieldmapping-step-btn"]',
            'next_btn_selector': '[data-qa="import-new-fieldmapping-model-validate"]',
    },
    'contentmapping': {
            'back_btn_selector': '[data-qa="import-contentmapping-back-btn"]',
            'step_btn_selector': '[data-qa="import-contentmapping-step-btn"]',
            'next_btn_selector': '[data-qa="import-new-contentmapping-model-validate"]',
    },
    'import': {
            'back_btn_selector': '[data-qa="import-data-back-btn"]',
            'step_btn_selector': '[data-qa="import-data-step-btn"]',
            'next_btn_selector': '[data-qa="import-new-verification-start"]',
    },
},
general: {
    'save_and_quit_btn_selector': '[data-qa="import-new-footer-save"]',
    'cancel_and_delete_import_btn_selector': '[data-qa="import-new-footer-delete"]',
}
}

export const getSelectorsForStep = (stepName) => {
    const selectors = SELECTORS_NAVIGATION.step[stepName];
    if (!selectors) {
      throw new Error(`No selectors found for step: ${stepName}`);
    }
    return selectors;
  };