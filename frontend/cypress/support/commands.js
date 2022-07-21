
Cypress.Commands.add("geonatureLogin", () => {
    cy.visit("/");
    cy.get('[data-qa="gn-connection-id"]').type("admin");
    cy.get('[data-qa="gn-connection-pwd"]').type(
      "admin"
    );
    cy.get('[data-qa="gn-connection-button"]').click();
    Cypress.Cookies.defaults({
        preserve: 'token',
      })
});

Cypress.Commands.add('geonatureLogout', () => {
  cy.clearCookie('token'); // clear the 'authId' cookie
});
