
//Geonature connection
before('Geonature connection', () => {
//   cy.geonatureLogout();
  cy.geonatureLogin();
  cy.wait(500);
  cy.visit("/#/occtax_ds")

});


it("Should click on OCCTAX_DS module and load data with module_code in url", () => {
    cy.intercept('http://127.0.0.1:8000/occtax/OCCTAX_DS/releves?**').as("getReleves")
    cy.wait('@getReleves').then((interception) => {
        expect(interception.response.statusCode, 200)

    })
    
})
it("Should change module nav home name", () => {
    cy.get("[data-qa='nav-home-module-name']").contains("Occtax ds")
})


