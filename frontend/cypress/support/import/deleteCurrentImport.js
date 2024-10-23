Cypress.Commands.add('deleteCurrentImport', () => {
  cy.url().then((url) => {
    // Extract the ID using string manipulation
    const parts = url.split('/');
    const importID = parts[parts.length - 2]; // Get the penultimate element
    const destination = parts[parts.length - 4];
    cy.deleteImport(importID, destination);
    cy.visitImport();
  });
});
