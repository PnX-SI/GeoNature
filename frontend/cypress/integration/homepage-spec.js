import promisify from 'cypress-promise';


describe("Testing homepage", () => {

  before(() => {
    cy.geonatureLogout();
    cy.geonatureLogin();
  });

  it('should close and open the menu', () => {
    cy.get("#app-toolbar > button.mat-focus-indicator.mat-tooltip-trigger.mat-elevation-z1.mr-2.mat-icon-button.mat-button-base").click()
    cy.wait(500)
    cy.get("#app-sidenav").should('have.css', 'visibility').and('match', /hidden/)
    cy.get("#app-toolbar > button.mat-focus-indicator.mat-tooltip-trigger.mat-elevation-z1.mr-2.mat-icon-button.mat-button-base").click()
    cy.wait(500)
    cy.get("#app-sidenav").should('have.css', 'visibility').and('match', /visible/)
  })

  it('should display synthese page', () => {
    cy.get('[data-qa="pnx-home-content"] > div.row > div.col-6.ng-star-inserted > div > div.panel-heading > button').click({force: true})
    cy.url().should('include', 'synthese') 
  })

  it('back to home', () => {
    cy.get('#app-sidenav > div > pnx-sidenav-items > mat-card').click()
  })

  // it('open documentation', () => {
  //   cy.get('#app-toolbar > a').click()
  // })

  it('disconnect', () => {
    cy.get('#app-toolbar > button.mat-focus-indicator.mat-tooltip-trigger.mx-2.mat-elevation-z1.mat-icon-button.mat-button-base').click()
    cy.get('#cdk-step-content-0-0 > form > button')
  })

})