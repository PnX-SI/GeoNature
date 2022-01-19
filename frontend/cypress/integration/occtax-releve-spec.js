import promisify from 'cypress-promise';

//Geonature connection
before('Geonature connection', () => {
  cy.geonatureLogin()
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
  const plus = cy.get("pnx-map > div > div.leaflet-container.leaflet-touch.leaflet-fade-anim.leaflet-grab.leaflet-touch-drag.leaflet-touch-zoom > div.leaflet-control-container > div.leaflet-top.leaflet-right > div.leaflet-control-zoom.leaflet-bar.leaflet-control > a.leaflet-control-zoom-in");
  Array(10).fill(0).forEach(e => plus.wait(200).click())
  cy.get('pnx-map > div > div.leaflet-container.leaflet-touch.leaflet-fade-anim.leaflet-grab.leaflet-touch-drag.leaflet-touch-zoom').click(100, 100);
  // le overlay doit être désactivé
  cy.get("[data-qa='pnx-occtax-releve-form-observers'] #overlay").should("not.exist");
  //TODO: tester le remplacement d'une geometrie, d'un polygone, d'une ligne, d'une édition...
});

after("Logout", () => {
   cy.geonatureLogout()
})

describe("Post Occtax", () => {
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

    it("Should submit a new releve", () => {
      cy.get("[data-qa='pnx-occtax-releve-submit-btn']").click()
    })
    it("Occurrence sumbit must be disabled", () => {
      cy.get("[data-qa='occurrence-add-btn'][disabled='true']");
    })
    it("Should focus on taxa input", ()=> {
      cy.focused()
      .invoke('attr', 'data-qa')
      .should('eq', 'taxonomy-form-input')
    });
    it("Search and select taxa", ()=> {
      const taxonInput = cy.get("input[data-qa='taxonomy-form-input'].ng-invalid");
      taxonInput.type("canis lupus")
      const results = cy.get("ngb-typeahead-window")
      const firstTaxon = results.first().click()
      const nomValideResult = cy.get("[data-qa='occurrence-nom-valide']");
      nomValideResult.contains("Canis lupus Linnaeus, 1758")
    })

    it("should focus on sumbit button", ()=> {
      // check the button add occurrence is focused
      cy.focused()
      .invoke('attr', 'data-qa')
      .should('eq', 'occurrence-add-btn')
    })

    it("should autocompete count max with count min value", () => {
      // HACK : must reselect countin min from selector otherwise it clear the wrong input (?!) ...
      cy.get("[data-qa='counting-count-min']").should("have.value", 1);
      cy.get("[data-qa='counting-count-max']").should("have.value", 1);
      // change count min val, count max must be updated with the same value
      cy.get("[data-qa='counting-count-min']").clear()
      cy.get("[data-qa='counting-count-min']").type(3);
      cy.get("[data-qa='counting-count-max']").should("have.value", 3);
      // change count max val with a lower value than count min - should be invalid
      cy.get("[data-qa='counting-count-max']").clear();
      cy.get("[data-qa='counting-count-max']").type(2);
      // TODO check is invalid // not working
      // try with this ?
      //       cy.get('section')
      // .should('have.class', 'container')
      // cy.get("[data-qa='counting-count-max'].ng-invalid")

      // change count min - count max should'nt be updated because it's been already change
      cy.get("[data-qa='counting-count-min']").clear()
      cy.get("[data-qa='counting-count-min']").type(1)
      cy.get("[data-qa='counting-count-max']").should("have.value", 2)
    })

    it("Should submit an occurrence", () => {
      cy.get("[data-qa='occurrence-add-btn']").click()
    })

    // TODO : check that the occurrence is in the rigth list
    // check the taxon input is focused again
    // test to edit and no autocompletion on counting



});