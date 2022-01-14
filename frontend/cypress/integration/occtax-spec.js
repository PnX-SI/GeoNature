import promisify from 'cypress-promise';

//Geonature connection
beforeEach(() => {
  cy.visit("http://127.0.0.1:4200");
  cy.get("pnx-login form #login").type("admin");
  cy.get("#cdk-step-content-0-0 > form > div:nth-child(2) > input").type(
    "admin"
  );
  cy.get("pnx-login button[type='submit']").click();
  cy.get("[data-qa='gn-sidenav-link-OCCTAX']").click();
  cy.get("[data-qa='gn-occtax-btn-add-releve']").click();
});

describe("Geonature connection", () => {
    beforeEach(() => {
      cy.visit("http://localhost:4200");
      cy.get("#login").type("admin");
      cy.get("#cdk-step-content-0-0 > form > div:nth-child(2) > input").type(
        "admin"
      );
      cy.get("#cdk-step-content-0-0 > form > button").click();
    });

    it("should create relevé", () => {
        cy.get(
          '[href="http://localhost:4200/#/occtax"] > .sidenav-item > .mat-list-item-content > .module-name'
        ).click();
        cy.get(".button-success > .mat-button-wrapper").click();
        cy.get(".leaflet-container").click();
        const plus_button = cy.get(
          "body > pnx-root > pnx-nav-home > mat-sidenav-container > mat-sidenav-content > div > div > pnx-occtax-form > div > div > div.occtax-form-content.ng-star-inserted > div > div.col-xl-6.col-lg-7.col-sm-6 > pnx-occtax-form-map > pnx-map > div > div.leaflet-container.leaflet-touch.leaflet-fade-anim.leaflet-grab.leaflet-touch-drag.leaflet-touch-zoom > div.leaflet-control-container > div.leaflet-top.leaflet-right > div.leaflet-control-zoom.leaflet-bar.leaflet-control > a.leaflet-control-zoom-in"
        );
      });

});