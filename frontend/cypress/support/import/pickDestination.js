const DEFAULT_DESTINATION_NAME = 'Synthèse';
Cypress.Commands.add('pickDestination', (destinationName) => {
  destinationName = destinationName ?? DEFAULT_DESTINATION_NAME;
  cy.get('[data-qa=import-new-modal-destinations]').within(() => {
    cy.get('.ng-arrow-wrapper').should('exist').click({ force: true });
  });
  cy.get('ng-dropdown-panel')
    .get('.ng-option')
    .contains(destinationName)
    .then((destination) => {
      cy.wrap(destination).should('exist').click({ force: true });
    });
  cy.get('[data-qa=import-modal-destination-validate]').should('exist').click({ force: true });
});
