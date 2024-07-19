Cypress.Commands.add('loadImportFile', (fixture, nextStep = true) => {
  cy.fixture(fixture).as('import_file');
  cy.get('[data-qa="import-new-upload-file"]').selectFile(
    { contents: '@import_file', fileName: fixture.split(/(\\|\/)/g).pop() },
    { force: true }
  );
  if (nextStep) {
    cy.get('[data-qa="import-new-upload-validate"]').should('be.visible').click();
  }
});
