Cypress.Commands.add('checkCurrentPageIsImportUpload', (destination) => {
  // Check the url
  cy.url().should(
    'be.equal',
    `${Cypress.config('baseUrl')}/#/import/${destination}/process/upload`
  );
  // Check that the main component is there
  cy.get('[data-qa="import-new-upload-file"]').should('exist');
});
