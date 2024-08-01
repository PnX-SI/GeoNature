Cypress.Commands.add('pickDataset', (datasetName) => {
  cy.get('[data-qa="import-new-upload-datasets"]')
    .should('exist')
    .click()
    .get('ng-dropdown-panel')
    .get('.ng-option')
    .contains(datasetName)
    .then((dataset) => {
      cy.wrap(dataset).should('exist').click();
    });
});
