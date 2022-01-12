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
    it("should create relevé", async () => {

      //TODO: test sur un clic sur l'overlay affiche l'alerte.

      //test si le clic sur le carte apres le zoom désactive l'overlay
      const plus = cy.get("body > pnx-root > pnx-nav-home > mat-sidenav-container > mat-sidenav-content > div > div > pnx-occtax-form > div > div > div.occtax-form-content.ng-star-inserted > div > div.col-xl-6.col-lg-7.col-sm-6 > pnx-occtax-form-map > pnx-map > div > div.leaflet-container.leaflet-touch.leaflet-fade-anim.leaflet-grab.leaflet-touch-drag.leaflet-touch-zoom > div.leaflet-control-container > div.leaflet-top.leaflet-right > div.leaflet-control-zoom.leaflet-bar.leaflet-control > a.leaflet-control-zoom-in");
      Array(20).fill(0).forEach(e=>plus.click())
      cy.get('body > pnx-root > pnx-nav-home > mat-sidenav-container > mat-sidenav-content > div > div > pnx-occtax-form > div > div > div.occtax-form-content.ng-star-inserted > div > div.col-xl-6.col-lg-7.col-sm-6 > pnx-occtax-form-map > pnx-map > div > div.leaflet-container.leaflet-touch.leaflet-fade-anim.leaflet-grab.leaflet-touch-drag.leaflet-touch-zoom').click(100, 100);
      cy.get("pnx-occtax-form-releve #overlay").should("not.exist");


      cy.get("pnx-occtax-form-releve [data-qa='gn-common-form-observers-select']").find(".ng-value-container .ng-value").should("exist");

      //test si une valeur d'observateur par défaut existe
      cy.get("pnx-occtax-form-releve [data-qa='gn-common-form-observers-select']").find(".ng-value-container .ng-value .ng-value-label").should("exist");

      //Teste si la valeur par défaut dans le input est bien indiquée selectionnée dans la liste
      cy.get("pnx-occtax-form-releve [data-qa='gn-common-form-observers-select'] .ng-select-container").click();
      cy.get("pnx-occtax-form-releve [data-qa='gn-common-form-observers-select'] ng-dropdown-panel .ng-dropdown-panel-items")
        .find('.ng-option ng-option-selected');

    });

});



      // cy.get('.check-box-sub-text').should('not.exist');


        // cy.get(".button-success > .mat-button-wrapper").click();
        // cy.get(".leaflet-container").click();
        // const plus_button = cy.get(
        //   "body > pnx-root > pnx-nav-home > mat-sidenav-container > mat-sidenav-content > div > div > pnx-occtax-form > div > div > div.occtax-form-content.ng-star-inserted > div > div.col-xl-6.col-lg-7.col-sm-6 > pnx-occtax-form-map > pnx-map > div > div.leaflet-container.leaflet-touch.leaflet-fade-anim.leaflet-grab.leaflet-touch-drag.leaflet-touch-zoom > div.leaflet-control-container > div.leaflet-top.leaflet-right > div.leaflet-control-zoom.leaflet-bar.leaflet-control > a.leaflet-control-zoom-in"
        // );