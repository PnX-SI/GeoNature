const SIDENAV_IMPORT_BUTTON_QA = "[data-qa=gn-sidenav-link-IMPORT]";
const IMPORT_URL = "/#/import";

const checkCurrentPageIsImport = () => {
  // Check the url
  cy.url().should('be.equal', `${Cypress.config("baseUrl")}${IMPORT_URL}`);
  // Check that the main component is there
  cy.get("[data-qa=import-list]").should('exist');
}

// ////////////////////////////////////////////////////////////////////////////
//
// ////////////////////////////////////////////////////////////////////////////

describe('Should', () => {
  beforeEach(() => {
    cy.viewport(1024, 768);
    cy.geonatureLogin();
    cy.visit('/#');
  });

  it('Should display the import button in the sidenav panel', () => {
    cy.get(SIDENAV_IMPORT_BUTTON_QA).should('exist');
  })

  it('Should switch to import page after a click on the button', () => {
    cy.get(SIDENAV_IMPORT_BUTTON_QA).click();
    checkCurrentPageIsImport();
  })

  it('Should land directly to the import page', () => {
    cy.visit(IMPORT_URL);
    checkCurrentPageIsImport();
  })
})
