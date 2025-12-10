const DEFAULT_MAPPING = 'Synthese GeoNature';
const DEFAULT_DATASET = '';

Cypress.Commands.add('configureImportObserverMapping', (datasetName) => {
  cy.wait(1000);
  cy.get('[data-qa="import-observersmapping-observers-form"]').each(($form, index, $forms) => {
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
