const DEFAULT_MAPPING = 'Synthese GeoNature';
const DEFAULT_DATASET = '';

Cypress.Commands.add('configureImportObserverMapping', (datasetName) => {
  cy.get('[data-qa="import-observersmapping-observers-form"]')
    .should('have.length.greaterThan', 0)
    .each(($form, index, $forms) => {
      cy.wrap($form)
        .find('ng-select')
        .first()
        .click()
        .then(() => {
          cy.wrap($form).find('ng-dropdown-panel').find('.ng-option').first().click();
        });
    });
  cy.get('[data-qa="import-observersmapping-model-validate"]').should('exist').click();
});
