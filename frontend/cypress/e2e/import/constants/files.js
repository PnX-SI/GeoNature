export const FILES = {
  synthese: {
    valid: {
      fixture: 'import/synthese/valid_file.csv',
      toast: '',
      formErrorElement: ''
    },
    bad_csv: {
      fixture: 'import/synthese/bad_csv.csv',
      toast: 'File must start with columns',
      formErrorElement: '[data-qa="import-new-upload-error-firstColumn"]'
    }
  }
}
