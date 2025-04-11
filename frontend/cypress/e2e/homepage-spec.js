const SELECTOR_SIDEBAR_OPEN_BUTTON = '[data-qa="pnx-home-content-sidebar-open-button"]';
const SELECTOR_EXPLORE_DATA_BUTTON = '[data-qa="pnx-home-content-explore-data-button"]';
const SELECTOR_EXIT_BUTTON = '[data-qa="pnx-home-content-exit-button"]';
const SELECTOR_CONNECTION_BUTTON = '[data-qa="gn-connection-button"]';
const SELECTOR_SIDEBAR = '#app-sidenav';
const SELECTOR_SIDEBAR_HOME_BUTTON = '[data-qa="gn-sidenav-mat-card"]';
const SELECTOR_HOME_CONTENT = '[data-qa="pnx-home-content"]';

describe('Testing homepage', () => {
  beforeEach(() => {
    cy.geonatureLogin();
    cy.visit('/#/');
  });

  it('should close and open the menu', () => {
    // It is a known angular issue:
    // #28446: https://github.com/angular/components/issues/28446
    // When resizing a component width that contains a mat-tab-group with multiple tabs
    Cypress.on('uncaught:exception', (err, runnable) => {
      if (err.message.includes('ResizeObserver')) {
        return false;
      }
    });
    cy.get(SELECTOR_SIDEBAR).should('exist').should('be.visible');
    cy.get(SELECTOR_SIDEBAR_OPEN_BUTTON).click();
    cy.get(SELECTOR_SIDEBAR).should('exist').should('not.be.visible');
    cy.get(SELECTOR_SIDEBAR_OPEN_BUTTON).click();
    cy.get(SELECTOR_SIDEBAR).should('exist').should('be.visible');
  });

  it('should display synthese page and back to home', () => {
    cy.get(SELECTOR_HOME_CONTENT).should('exist').should('be.visible');
    cy.get(SELECTOR_EXPLORE_DATA_BUTTON).click({ force: true });
    cy.url().should('include', 'synthese');
    cy.get(SELECTOR_SIDEBAR_HOME_BUTTON).click();
    cy.get(SELECTOR_HOME_CONTENT).should('exist').should('be.visible');
  });

  it('disconnect', () => {
    cy.get(SELECTOR_EXIT_BUTTON).click({ force: true });
    cy.get(SELECTOR_CONNECTION_BUTTON).should('exist').should('be.visible');
  });
});
