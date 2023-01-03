
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

let LOCAL_STORAGE_MEMORY = {};

Cypress.Commands.add('saveLocalStorage', () => {
  Object.keys(localStorage).forEach((key) => {
    LOCAL_STORAGE_MEMORY[key] = localStorage[key];
  });
});

Cypress.Commands.add('restoreLocalStorage', () => {
  Object.keys(LOCAL_STORAGE_MEMORY).forEach((key) => {
    localStorage.setItem(key, LOCAL_STORAGE_MEMORY[key]);
  });
});
