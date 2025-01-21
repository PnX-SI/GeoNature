const DEFAULT_MAPPING = 'Synthese GeoNature';
const DEFAULT_DATASET = '';

Cypress.Commands.add('configureImportFieldMapping', (datasetName) => {
  cy.get('[data-qa="import-fieldmapping-selection-select"]')
    .should('exist')
    .click()
    .get('ng-dropdown-panel')
    .get('.ng-option')
    .contains(DEFAULT_MAPPING)
    .then((v) => {
      cy.wrap(v).should('exist').click();
    });

  cy.get('[data-qa="import-fieldmapping-theme-default-unique_dataset_id"] ng-select')
    .should('exist')
    .click()
    .get('ng-dropdown-panel')
    .get('.ng-option')
    .contains(datasetName)
    .then((dataset) => {
      cy.wrap(dataset).should('exist').click();
    });

  // Every mandatory field is filled: should be able to validate
  cy.get('[data-qa="import-new-fieldmapping-model-validate"]')
    .should('exist')
    .should('be.enabled')
    .click();

  cy.get('[data-qa="import-fieldmapping-saving-modal-cancel"]')
    .should('exist')
    .should('be.enabled')
    .click();
});
