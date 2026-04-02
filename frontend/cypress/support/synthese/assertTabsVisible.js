Cypress.Commands.add('assertTabsVisible', (paths) => {
  cy.get('[data-qa="tabs-layout-nav"]').within(() => {
    paths.forEach((path) => {
      cy.get(`[data-qa="tabs-layout-tab-${path}"]`).should('exist');
    });
  });
});
