
Cypress.Commands.add("geonatureLogin", () => {
  cy.session("admin", () => {
    cy.request({
      method: 'POST',
      url: 'http://localhost:8000/auth/login',
      body: {
        login: "admin",
        password: "admin"
      }
    })
    .its('body')
    .then(body => {
      window.localStorage.setItem("expires_at", body.expires);
      window.localStorage.setItem("gn_id_token", body.token);
      window.localStorage.setItem('current_user', JSON.stringify(body.user));
    })
  })
});
