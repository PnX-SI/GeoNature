
Cypress.Commands.add("geonatureLogin", () => {
    cy.visit("/");
    cy.get("#login").type("admin");
    cy.get("#cdk-step-content-0-0 > form > div:nth-child(2) > input").type(
      "admin"
    );
    cy.get("#cdk-step-content-0-0 > form > button").click();
    Cypress.Cookies.defaults({
        preserve: 'token',
      })
});

Cypress.Commands.add("geonatureLogout", () => {
    cy.clearCookie('token') // clear the 'authId' cookie
});

