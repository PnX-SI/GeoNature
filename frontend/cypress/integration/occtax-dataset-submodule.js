
//Geonature connection
before('Geonature connection', () => {
  cy.geonatureLogout();
  cy.geonatureLogin();
  cy.wait(500)
});

it("Should click on OCCTAX_DS_2 module and load data with id_dataset in query string", () => {
    cy.get("[data-qa='gn-sidenav-link-OCCTAX_DS_2']").click();
    cy.intercept('http://127.0.0.1:8000/occtax/releves?**').as("getReleves")
    cy.wait('@getReleves').then((interception) => {
        cy.log(interception) // first api call
        console.log(interception.response.url);
        assert.include(interception.response.url, "id_dataset")
    })
    
})
it("Should change module nav home name", () => {
    cy.get("[data-qa='nav-home-module-name']").contains("Occtax DS 2")
})
it("Should pre-select dataset in filter form", () => {
    cy.get("[data-qa='nav-home-module-name']").contains("Occtax DS 2")
    // cy.get('@get').then(console.log)

})

