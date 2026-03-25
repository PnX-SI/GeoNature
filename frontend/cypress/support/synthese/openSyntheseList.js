Cypress.Commands.add('openSyntheseList', () => {
  cy.visit('/#/synthese');
  cy.wait('@globalConfig');
});
