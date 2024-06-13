export const FILES = {
  synthese: {
    valid: {
      fixture: 'import/synthese/valid_file.csv',
      toast: '',
      formErrorElement: ''
    },
    bad: {
      fixture: 'import/synthese/bad.csv',
      toast: '',
      formErrorElement: '[data-qa="import-new-upload-error-empty"]'
    },
    empty: {
      fixture: 'import/synthese/empty.csv',
      toast: 'File must start with columns',
      formErrorElement: '[data-qa="import-new-upload-error-firstColumn"]'
    },
    bad_extension: {
      fixture: 'import/synthese/bad_extension.pdf',
      toast: '',
      formErrorElement: ''
    },
  }
}
