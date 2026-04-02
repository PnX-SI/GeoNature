Cypress.Commands.add('openObserverSheet', () => {
  cy.visit('/#/');
  cy.wait('@globalConfig');

  cy.window().then((win) => {
    const currentUser = JSON.parse(win.localStorage.getItem('gn_current_user'));
    cy.visit(`/#/synthese/observer/${currentUser.id_role}`);
  });

  cy.location('hash').should('match', /#\/synthese\/observer\/.+/);
});
