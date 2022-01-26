
//Geonature connection
before('Geonature connection', () => {
//   cy.geonatureLogout();
  cy.geonatureLogin();
  cy.wait(500)
});

beforeEach(() => {
    cy.restoreLocalStorage();
  });
  
  afterEach(() => {
    cy.saveLocalStorage();
  });

it("Should click on OCCTAX_DS_2 module and load data with id_dataset in query string", () => {
    cy.intercept('http://127.0.0.1:8000/occtax/releves?**').as("getReleves")
    cy.get("[data-qa='gn-sidenav-link-OCCTAX_DS_2']").click();
    cy.wait('@getReleves').then((interception) => {
        assert.include(interception.response.url, "id_dataset")
    })
    
})
it("Should change module nav home name", () => {
    cy.get("[data-qa='nav-home-module-name']").contains("Occtax DS 2")
})
it("Should pre-select dataset in filter form", () => {
    cy.get("[data-qa='nav-home-module-name']").contains("Occtax DS 2")
    cy.get("[data-qa='occtax-map-list-filter-btn']").click()
    cy.get("pnx-datasets > ng-select > div > div > div.ng-value.ng-star-inserted > span.ng-value-label.ng-star-inserted").contains("JDD-2")
    
})

it("Should add a new releve with dataset preselected", () => {
    cy.get("[data-qa='gn-occtax-btn-add-releve']").click()
    const plus = cy.get("pnx-map > div > div.leaflet-container.leaflet-touch.leaflet-fade-anim.leaflet-grab.leaflet-touch-drag.leaflet-touch-zoom > div.leaflet-control-container > div.leaflet-top.leaflet-right > div.leaflet-control-zoom.leaflet-bar.leaflet-control > a.leaflet-control-zoom-in");
    Array(10).fill(0).forEach(e => plus.wait(200).click())
    cy.get('pnx-map > div > div.leaflet-container.leaflet-touch.leaflet-fade-anim.leaflet-grab.leaflet-touch-drag.leaflet-touch-zoom').click(100, 100);

    cy.get("pnx-datasets > ng-select > div > div > div.ng-value.ng-star-inserted") 
    cy.get("pnx-datasets > ng-select > div > div > div.ng-value.ng-star-inserted > span.ng-value-label.ng-star-inserted").contains("JDD-2")
})

it("Should click on Occtax and load all data", () => {
    cy.intercept('http://127.0.0.1:8000/occtax/releves?**').as("getReleves")
    cy.get("[data-qa='nav-home-toggle-side-bar']").click();
    cy.get("[data-qa='gn-sidenav-link-OCCTAX']").click();
    cy.wait('@getReleves').then((interception) => {
        assert.notInclude(interception.response.url, "id_dataset")
    })
})
it("Should change module nav home name", () => {
    cy.get("[data-qa='nav-home-module-name']").contains("Occtax")
})

it("Dataset form shoul be empty", () => {
    cy.get("[data-qa='occtax-map-list-filter-btn']").click()
    cy.get("pnx-datasets > ng-select > div > div > div.ng-value.ng-star-inserted > span.ng-value-label.ng-star-inserted").should('not.exist');

})

