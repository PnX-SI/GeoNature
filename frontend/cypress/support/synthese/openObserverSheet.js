Cypress.Commands.add('openObserverSheet', () => {
  cy.visit('/#/');
  cy.wait('@globalConfig');

  cy.visit('/#/synthese/observer');

  cy.location('hash').should('match', /#\/synthese\/observer(\/|$)/);
});
