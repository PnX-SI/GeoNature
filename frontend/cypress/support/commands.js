
Cypress.Commands.add("geonatureLogin", () => {
    cy.visit("/#/login");
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

let LOCAL_STORAGE_MEMORY = {};

Cypress.Commands.add("saveLocalStorage", () => {
  Object.keys(localStorage).forEach(key => {
    LOCAL_STORAGE_MEMORY[key] = localStorage[key];
  });
});

Cypress.Commands.add("restoreLocalStorage", () => {
  Object.keys(LOCAL_STORAGE_MEMORY).forEach(key => {
    localStorage.setItem(key, LOCAL_STORAGE_MEMORY[key]);
  });
});
