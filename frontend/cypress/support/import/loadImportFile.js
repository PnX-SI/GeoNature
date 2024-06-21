Cypress.Commands.add("loadImportFile", (fixture,nextStep=true) => {
  cy.fixture(fixture, null).as('import_file')
  cy.get('[data-qa="import-new-upload-file"]').selectFile('@import_file');
  cy.contains(fixture.split(/(\\|\/)/g).pop());
  nextStep ?
  cy.get('[data-qa="import-new-upload-validate"]').should("be.visible").click() :
  null;
});
