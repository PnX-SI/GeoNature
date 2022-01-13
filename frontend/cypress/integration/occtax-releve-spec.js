import promisify from 'cypress-promise';

//Geonature connection
before('Geonature connection', () => {
  cy.visit("http://127.0.0.1:4200");
  cy.get("pnx-login form #login").type("admin");
  cy.get("#cdk-step-content-0-0 > form > div:nth-child(2) > input").type(
    "admin"
  );
  cy.get("pnx-login button[type='submit']").click();
  cy.get("[data-qa='gn-sidenav-link-OCCTAX']").click();
  cy.get("[data-qa='gn-occtax-btn-add-releve']").click();
});

before('click sur la carte', () => {
  // Test sur un clic sur l'overlay affiche l'alerte.
  cy.get("div[data-qa='overlay']")
    .click();
  cy.get("div#toast-container .toast-warning div[role='alertdialog']")
    .should('exist');

  /**
   * Test de la carto
   */
  //test si le clic sur le carte apres le zoom désactive l'overlay
  const plus = cy.get("body > pnx-root > pnx-nav-home > mat-sidenav-container > mat-sidenav-content > div > div > pnx-occtax-form > div > div > div.occtax-form-content.ng-star-inserted > div > div.col-xl-6.col-lg-7.col-sm-6 > pnx-occtax-form-map > pnx-map > div > div.leaflet-container.leaflet-touch.leaflet-fade-anim.leaflet-grab.leaflet-touch-drag.leaflet-touch-zoom > div.leaflet-control-container > div.leaflet-top.leaflet-right > div.leaflet-control-zoom.leaflet-bar.leaflet-control > a.leaflet-control-zoom-in");
  Array(10).fill(0).forEach(e => plus.wait(1000).click())
  cy.get('body > pnx-root > pnx-nav-home > mat-sidenav-container > mat-sidenav-content > div > div > pnx-occtax-form > div > div > div.occtax-form-content.ng-star-inserted > div > div.col-xl-6.col-lg-7.col-sm-6 > pnx-occtax-form-map > pnx-map > div > div.leaflet-container.leaflet-touch.leaflet-fade-anim.leaflet-grab.leaflet-touch-drag.leaflet-touch-zoom').click(100, 100);
  cy.get("[data-qa='pnx-occtax-releve-form-observers'] #overlay").should("not.exist");
  //TODO: tester le remplacement d'une geometrie, d'un polygone, d'une ligne, d'une édition...
});

describe("Geonature connection", () => {
    it("Test du form observateurs", () => {
      //test si une valeur d'observateur par défaut existe
      cy.get("[data-qa='pnx-occtax-releve-form-observers'] [data-qa='gn-common-form-observers-select']")
        .find(".ng-value-container .ng-value")
        .should("exist");
      //Test si une unique valeur est selectionnée
      cy.get("[data-qa='pnx-occtax-releve-form-observers'] [data-qa='gn-common-form-observers-select']")
        .find(".ng-value-container .ng-value")
        .should('have.length', 1);
      //test si la valeur selectionnée correspond au à 'ADMINISTRATEUR test'
      cy.get("[data-qa='pnx-occtax-releve-form-observers'] [data-qa='gn-common-form-observers-select']")
        .find(".ng-value-container .ng-value .ng-value-label")
        .contains("ADMINISTRATEUR test");

      //test si la liste s'ouvre bien
      cy.get("[data-qa='pnx-occtax-releve-form-observers'] [data-qa='gn-common-form-observers-select'] ng-dropdown-panel")
        .should("not.exist");
      cy.get("[data-qa='pnx-occtax-releve-form-observers'] [data-qa='gn-common-form-observers-select'] .ng-select-container")
        .click();
      cy.get("[data-qa='pnx-occtax-releve-form-observers'] [data-qa='gn-common-form-observers-select'] ng-dropdown-panel")
        .should("exist");

      //Test s'il ya des valeurs dans la liste
      cy.get("[data-qa='pnx-occtax-releve-form-observers'] [data-qa='gn-common-form-observers-select'] ng-dropdown-panel div.ng-option")
        .should("exist");
      //Teste si la valeur par défaut dans le input est bien indiquée selectionnée dans la liste
      cy.get("[data-qa='pnx-occtax-releve-form-observers'] [data-qa='gn-common-form-observers-select'] ng-dropdown-panel div.ng-option.ng-option-selected")
        .should('have.length', 1);

      //Test la deselection d'un observateur déjà selectionné
      cy.get("[data-qa='pnx-occtax-releve-form-observers'] [data-qa='gn-common-form-observers-select'] ng-dropdown-panel div.ng-option.ng-option-selected")
        .click();
      cy.get("[data-qa='pnx-occtax-releve-form-observers'] [data-qa='gn-common-form-observers-select'] ng-dropdown-panel div.ng-option.ng-option-selected")
        .should('have.length', 0);
      cy.get("[data-qa='pnx-occtax-releve-form-observers'] [data-qa='gn-common-form-observers-select']")
        .find(".ng-value-container .ng-value")
        .should('have.length', 0);

      //Test la selection de deux observateurs
      cy.get("[data-qa='pnx-occtax-releve-form-observers'] [data-qa='gn-common-form-observers-select'] ng-dropdown-panel div.ng-option:nth-child(1)")
        .click();
      cy.get("[data-qa='pnx-occtax-releve-form-observers'] [data-qa='gn-common-form-observers-select']")
        .find(".ng-value-container .ng-value")
        .should('have.length', 1); //compte que le nombre de valeur selectionnée = 1
      cy.get("[data-qa='pnx-occtax-releve-form-observers'] [data-qa='gn-common-form-observers-select'] .ng-select-container")
        .click(); //recouverture de la liste
      cy.get("[data-qa='pnx-occtax-releve-form-observers'] [data-qa='gn-common-form-observers-select'] ng-dropdown-panel div.ng-option.ng-option-selected")
        .should('have.length', 1); //1 valeur selectionnée dans la liste
      cy.get("[data-qa='pnx-occtax-releve-form-observers'] [data-qa='gn-common-form-observers-select'] ng-dropdown-panel div.ng-option:nth-child(2)")
        .click(); //click sur une deuxième valeur
      cy.get("[data-qa='pnx-occtax-releve-form-observers'] [data-qa='gn-common-form-observers-select']")
        .find(".ng-value-container .ng-value")
        .should('have.length', 2); //compte que le nombre de valeur selectionnée = 2
    });

    it("Test du form dataset", () => {
      //test du champ vide à l'initialisation
      cy.get("[data-qa='pnx-occtax-releve-form-datasets'] ng-select .ng-value-container")
        .find(".ng-value")
        .should('have.length', 0);

      //test de l'ouverture de la liste
      cy.get("[data-qa='pnx-occtax-releve-form-datasets'] ng-select")
        .click();
      cy.get("[data-qa='pnx-occtax-releve-form-datasets'] ng-select ng-dropdown-panel")
        .should("exist");
      //check des valeurs présentes
      cy.get("[data-qa='pnx-occtax-releve-form-datasets'] ng-select ng-dropdown-panel .ng-dropdown-panel-items .ng-option")
        .should("exist");
      //selection de la premiere valeur
      cy.get("[data-qa='pnx-occtax-releve-form-datasets'] ng-select ng-dropdown-panel .ng-dropdown-panel-items .ng-option:nth-child(1)")
        .click();
      cy.get("[data-qa='pnx-occtax-releve-form-datasets'] ng-select .ng-value-container")
        .find(".ng-value")
        .should('have.length', 1);
    });

});



      // cy.get('.check-box-sub-text').should('not.exist');


        // cy.get(".button-success > .mat-button-wrapper").click();
        // cy.get(".leaflet-container").click();
        // const plus_button = cy.get(
        //   "body > pnx-root > pnx-nav-home > mat-sidenav-container > mat-sidenav-content > div > div > pnx-occtax-form > div > div > div.occtax-form-content.ng-star-inserted > div > div.col-xl-6.col-lg-7.col-sm-6 > pnx-occtax-form-map > pnx-map > div > div.leaflet-container.leaflet-touch.leaflet-fade-anim.leaflet-grab.leaflet-touch-drag.leaflet-touch-zoom > div.leaflet-control-container > div.leaflet-top.leaflet-right > div.leaflet-control-zoom.leaflet-bar.leaflet-control > a.leaflet-control-zoom-in"
        // );