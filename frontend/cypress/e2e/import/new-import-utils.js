export const TIMEOUT_WAIT = 1000;

export function startImport() {
  cy.get('[data-qa="import-modal-destination-start"]').click();
}

export function pickDestination() {
  cy.get('.auto').click();
  cy.get('[data-qa="synthese"]').click();
  cy.get('[data-qa="import-modal-destination-validate"]').click();
}

export function loadImportFile() {
  cy.fixture('import/synthese/valid_file.csv', null).as('syntheseValidFile')
  cy.get('[data-qa="import-new-upload-file"]').selectFile('@syntheseValidFile');
  cy.contains('valid_file.csv');
  cy.get('[data-qa="import-new-upload-validate"]').should("be.visible").click();
}

export function configureImportFile() {
  cy.get('[data-qa="import-new-decode-srid"]').select('4326');
  cy.get('[data-qa="import-new-decode-validate"]').click();
}

export function configureImportFieldMapping() {
  cy.get('[data-qa="mapping-selection"]').click();
  cy.get('[data-qa="mapping-selection-1"]').click();
  cy.get('[data-qa="import-new-fieldmapping-model-validate"]').click();
}

export function configureImportContentMapping() {
  cy.get('[data-qa="import-new-contentmapping-model-select"]').select('1: Object');
  cy.get('[data-qa="import-new-contentmapping-model-validate"]').click();
}

export function verifyImport() {
  cy.get('[data-qa="import-new-verification-start"]').click();
}

export function executeImport() {
  cy.get('[data-qa="import-new-execute-start"]').click();
}
