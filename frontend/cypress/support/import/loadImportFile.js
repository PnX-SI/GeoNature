ypress.Commands.add("loadImportFile", (fixture) => {
  cy.fixture(fixture, null).as('validFile')
  cy.get('[data-qa="import-new-upload-file"]').selectFile('@validFile');
  cy.contains('valid_file.csv');
  cy.get('[data-qa="import-new-upload-validate"]').should("be.visible").click();
});
