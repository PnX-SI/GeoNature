Cypress.Commands.add('deleteImport', (importID, destination) => {
  // Log the extracted ID
  cy.request('DELETE', `${Cypress.env('apiEndpoint')}import/${destination}/imports/${importID}/`);
});
