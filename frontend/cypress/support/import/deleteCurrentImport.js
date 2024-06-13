Cypress.Commands.add("deleteCurrentImport", () => {
  cy.get('[data-qa="import-new-footer-delete"]').should("exist").click();
});
