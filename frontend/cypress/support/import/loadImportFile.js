const DEFAULT_FIXTURE = 'import/synthese/valid_file.csv';
Cypress.Commands.add("loadImportFile", (fixture) => {
  fixture = fixture ?? DEFAULT_FIXTURE;
  cy.fixture(fixture, null).as('validFile')
  cy.get('[data-qa="import-new-upload-file"]').selectFile('@validFile');
  cy.contains('valid_file.csv');
  cy.get('[data-qa="import-new-upload-validate"]').should("be.visible").click();
});
