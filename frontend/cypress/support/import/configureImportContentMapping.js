Cypress.Commands.add("configureImportContentMapping", () => {
  cy.get('[data-qa="import-new-contentmapping-model-select"]').should("exist").select('1: Object');
  cy.get('[data-qa="import-new-contentmapping-model-validate"]').should("exist").click();
});
