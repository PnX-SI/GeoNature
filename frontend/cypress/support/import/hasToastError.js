Cypress.Commands.add('hasToastError', (error_msg) => {
  cy.get('#toast-container .toast-error .toast-message').should('be.visible').contains(error_msg);
});
