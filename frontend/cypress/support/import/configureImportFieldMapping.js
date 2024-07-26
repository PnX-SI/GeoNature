const DEFAULT_MAPPING = 'Synthese GeoNature';

Cypress.Commands.add('configureImportFieldMapping', () => {
  cy.get('[data-qa="import-fieldmapping-selection-select"]')
    .should('exist')
    .click()
    .get('ng-dropdown-panel')
    .get('.ng-option')
    .contains(DEFAULT_MAPPING)
    .then((v) => {
      cy.wrap(v).should('exist').click();
    });

  // Every mandatory field is filled: should be able to validate
  cy.get('[data-qa="import-new-fieldmapping-model-validate"]')
    .should('exist')
    .should('be.enabled')
    .click();
});
