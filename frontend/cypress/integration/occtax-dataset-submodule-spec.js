//Geonature connection
before('Geonature connection', () => {
  cy.geonatureLogout();
  cy.geonatureLogin();
});

beforeEach(() => {
  cy.restoreLocalStorage();
});

afterEach(() => {
  cy.saveLocalStorage();
});

it('Should click on OCCTAX_DS module and load data with module_code in url', () => {
  cy.visit('/#/occtax_ds');

  cy.intercept(Cypress.env('apiEndpoint') + 'occtax/OCCTAX_DS/releves?**').as('getReleves');
  cy.wait('@getReleves').then((interception) => {
    expect(interception.response.statusCode, 200);
  });
});
it('Should change module nav home name', () => {
  cy.get("[data-qa='nav-home-module-name']").contains('Occtax ds');
});

it('Should edit a releve and keep module name in URL', () => {
  cy.get("[data-qa='edit-releve']").first().click();
  cy.url().should('include', 'occtax_ds'); // => true
});
