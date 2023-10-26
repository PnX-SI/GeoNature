describe('Testing homepage', () => {
  beforeEach(() => {
    cy.geonatureLogin();
    cy.visit('/#/');
  });

  it('should close and open the menu', () => {
    cy.get('[data-qa="pnx-home-content-sidebar-open-button"]').click();
    cy.wait(500);
    cy.get('#app-sidenav')
      .should('have.css', 'visibility')
      .and('match', /hidden/);
    cy.get('[data-qa="pnx-home-content-sidebar-open-button"]').click();
    cy.wait(500);
    cy.get('#app-sidenav')
      .should('have.css', 'visibility')
      .and('match', /visible/);
  });

  it('should display synthese page and back to home', () => {
    cy.get('[data-qa="pnx-home-content-explore-data-button"]').click({ force: true });
    cy.url().should('include', 'synthese');
    cy.get('[data-qa="gn-sidenav-mat-card"]').click();
  });

  it('disconnect', () => {
    cy.get('[data-qa="pnx-home-content-exit-button"]').click({ force: true });
    cy.get('[data-qa="gn-connection-button"]');
  });
});
