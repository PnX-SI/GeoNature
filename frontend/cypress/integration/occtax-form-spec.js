import promisify from 'cypress-promise';


describe("Testing adding an observation in OccTax", () => {
  // 
  const taxaNameRef = "Loup gris = Canis lupus Linnaeus, 1758 - [ES - 60577]"
  const dateSaisieTaxon = "25/01/2022"
  const taxaSearch = "canis lupus"

  before(() => {
    cy.geonatureLogout();
    cy.geonatureLogin();
    cy.visit("/#/occtax")
    cy.get("[data-qa='gn-occtax-btn-add-releve']").click();
  });

  it('should not be possible to add data if any geometry had been selected', () => {
    // Un recouvrement des champs de saisie (overlay) existe à l'arrivée sur la page
    cy.get("div[data-qa='overlay']")
      .click();
    cy.get("div#toast-container .toast-warning div[role='alertdialog']")
      .should('exist');
  
    // Après un zoom sur la carte suffisant sur la carte et la sélection d'un point ou la sélection d'une géométrie, le recouvrement des champs de saisie n'existe plus
    const plus = cy.get("pnx-map > div > div.leaflet-container.leaflet-touch.leaflet-fade-anim.leaflet-grab.leaflet-touch-drag.leaflet-touch-zoom > div.leaflet-control-container > div.leaflet-top.leaflet-right > div.leaflet-control-zoom.leaflet-bar.leaflet-control > a.leaflet-control-zoom-in");
    Array(10).fill(0).forEach(e => plus.wait(200).click())
    cy.get('pnx-map > div > div.leaflet-container.leaflet-touch.leaflet-fade-anim.leaflet-grab.leaflet-touch-drag.leaflet-touch-zoom').click(100, 100);
    cy.get("[data-qa='pnx-occtax-releve-form-observers'] #overlay").should("not.exist");
  });

  // TODO 
  it('should be possible to add a geometry on the map', () => {
    // Le point 
      // Il est impossible d'ajouter un point au zoom minimal du relevé
      // Tester que l'ajout de point n'est pas possible 
      // Tester que l'erreur "échelle de saisie inadaptée apparait"
      // Tester si aucun point n'est sélectionné alors le recouvrement des champs de saisie (overlay) existe 
      // Après un zoom suffisamment avancé, tester s'il est possible d'ajouter un point 
      // Tester si l'ajout d'un point enlève le recouvrement des champs de saisie (overlay)
    // La ligne 
      // Tester : Il est possible de sélectionner l'îcone ajout de lignes qui entraine l'apparition d'un tooltip gris contenant "finish, delete last point, cancel"
      // Tester le tracé d'une ligne si seulement c'est possible avec Cypress 
    // Le Polygone 
      // Tester : Il est possible de sélectionner l'îcone ajout de polygone qui entraine l'apparition d'un tooltip gris contenant "finish, delete last point, cancel"
    // L'édition des géométries 
      // Intestable en l'état 03/02/2022
    // L'îcone dossier 
      // Tester : cliquer sur l'icone dossier de la carte ouvre le gestionnaire de fichier de la machine 
    // L'icone GPS
      // Tester : cliquer sur l'icone GPS ouvre une modale "Coordonées GPS" permettant de saisir des coordonées en X et en Y 
      // Tester : il est impossible de rentrer autre chose qu'un nombre décimal dans les champs 
      // Tester : Les flèches dans les champs fonctionnent et permette d'incréemnter de plus ou moins 1 la valeur du champ 
      // Tester : Rentrer les coordonnées vides ne permet pas de valider (intestable parce que là si mais ticket ouvert #1681)
      // Tester : Rentrer des coordonnées 0 et 0 nous déplace bien sur la carte avec un point (au large de l'Afrique notamment)  
    // Une fois une géométrie sélectionnée il est impossible d'enregistrer et saisir des taxons avant de remplir des champs 
    cy.get("[data-qa=\"pnx-occtax-releve-submit-btn\"]")
    .should('be.disabled')
  });

  it("should test the observer form", () => {
    // Test de l'existence d'une valeur initiale 
      // Tester si une valeur d'observateur par défaut existe 
      cy.get("[data-qa='pnx-occtax-releve-form-observers'] [data-qa='gn-common-form-observers-select']")
        .find(".ng-value-container .ng-value")
        .should("exist");
      // Tester si une unique valeur est selectionnée
      cy.get("[data-qa='pnx-occtax-releve-form-observers'] [data-qa='gn-common-form-observers-select']")
        .find(".ng-value-container .ng-value")
        .should('have.length', 1);
      // Tester si la valeur selectionnée correspond à 'ADMINISTRATEUR test'
      cy.get("[data-qa='pnx-occtax-releve-form-observers'] [data-qa='gn-common-form-observers-select']")
        .find(".ng-value-container .ng-value .ng-value-label")
        .contains("ADMINISTRATEUR test");

    // Test de la liste déroulante observateurs 
      // Tester si la liste déroulante du champ observateur s'ouvre bien
      cy.get("[data-qa='pnx-occtax-releve-form-observers'] [data-qa='gn-common-form-observers-select'] ng-dropdown-panel")
        .should("not.exist");
      cy.get("[data-qa='pnx-occtax-releve-form-observers'] [data-qa='gn-common-form-observers-select'] .ng-select-container")
        .click();
      cy.get("[data-qa='pnx-occtax-releve-form-observers'] [data-qa='gn-common-form-observers-select'] ng-dropdown-panel")
        .should("exist");
      //Tester s'il ya des valeurs dans la liste
      cy.get("[data-qa='pnx-occtax-releve-form-observers'] [data-qa='gn-common-form-observers-select'] ng-dropdown-panel div.ng-option")
        .should("exist");
      //Tester si la valeur par défaut dans le input est bien indiquée selectionnée dans la liste
      cy.get("[data-qa='pnx-occtax-releve-form-observers'] [data-qa='gn-common-form-observers-select'] ng-dropdown-panel div.ng-option.ng-option-selected")
        .should('have.length', 1);
      //Tester la deselection d'un observateur déjà selectionné
      cy.get("[data-qa='pnx-occtax-releve-form-observers'] [data-qa='gn-common-form-observers-select'] ng-dropdown-panel div.ng-option.ng-option-selected")
        .click();
      cy.get("[data-qa='pnx-occtax-releve-form-observers'] [data-qa='gn-common-form-observers-select'] ng-dropdown-panel div.ng-option.ng-option-selected")
        .should('have.length', 0);
      cy.get("[data-qa='pnx-occtax-releve-form-observers'] [data-qa='gn-common-form-observers-select']")
        .find(".ng-value-container .ng-value")
        .should('have.length', 0);
      //Tester la selection de deux observateurs
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

  it("should test the dataset form", async () => {
    // Tester le champ vide à l'initialisation
    cy.get("[data-qa='pnx-occtax-releve-form-datasets'] ng-select .ng-value-container")
      .find(".ng-value")
      .should('have.length', 0);

    // Tester l'ouverture de la liste
    cy.get("[data-qa='pnx-occtax-releve-form-datasets'] ng-select")
      .click();
    cy.get("[data-qa='pnx-occtax-releve-form-datasets'] ng-select ng-dropdown-panel")
      .should("exist");
    // Check des valeurs présentes
    cy.get("[data-qa='pnx-occtax-releve-form-datasets'] ng-select ng-dropdown-panel .ng-dropdown-panel-items .ng-option")
      .should("exist");
    // Sélection de la première valeur
    cy.get("[data-qa='pnx-occtax-releve-form-datasets'] ng-select ng-dropdown-panel .ng-dropdown-panel-items .ng-option:nth-child(1)")
      .click();
    cy.get("[data-qa='pnx-occtax-releve-form-datasets'] ng-select .ng-value-container")
      .find(".ng-value")
      .should('have.length', 1);
    cy.get("[data-qa=\"pnx-occtax-releve-submit-btn\"]")
      .should('be.enabled')

    // TODO : SUPPRIMER TOUS LES TESTS OBSERVATEURS PARCE QUE JE PENSE QU'ILS SONT AU DESSUS OU AU MOINS LES MERGER AVEC AVANT SI Y A DU PLUS  
    cy.get("[data-qa='pnx-occtax-releve-form-observers'] [data-qa='gn-common-form-observers-select'] .ng-select-container")
      .click();
    cy.get("[data-qa='pnx-occtax-releve-form-observers'] [data-qa='gn-common-form-observers-select'] ng-dropdown-panel div.ng-option.ng-option-selected")
      .click({ multiple: true });
    cy.get("[data-qa=\"pnx-occtax-releve-submit-btn\"]")
      .should('be.disabled')
    
    cy.get("[data-qa='pnx-occtax-releve-form-observers'] [data-qa='gn-common-form-observers-select'] ng-dropdown-panel div.ng-option:nth-child(1)")
      .click();
    cy.get("[data-qa='pnx-occtax-releve-form-observers'] [data-qa='gn-common-form-observers-select'] .ng-select-container")
      .click();
    cy.get("[data-qa='pnx-occtax-releve-form-observers'] [data-qa='gn-common-form-observers-select'] ng-dropdown-panel div.ng-option:nth-child(2)")
      .click();
    cy.get("[data-qa='pnx-occtax-releve-form-observers'] [data-qa='gn-common-form-observers-select']")
      .find(".ng-value-container .ng-value")
      .should('have.length', 2);


    // TODO : CREER UN it{should test the date field}
    cy.get("[data-qa='pnx-occtax-releve-form-adddate']").click()

    cy.get("[data-qa='pnx-occtax-releve-form-datemin'] [data-qa='input-date']").click().clear().type(" ")
    cy.get("[data-qa='pnx-occtax-releve-form-datemin'] [data-qa='input-date']").should('have.class','ng-invalid')
    cy.get("[data-qa='pnx-occtax-releve-form-datemax'] [data-qa='input-date']").should('have.class','ng-invalid')
    cy.get("[data-qa=\"pnx-occtax-releve-submit-btn\"]")
      .should('be.disabled')

    cy.get("[data-qa='pnx-occtax-releve-form-datemin'] [data-qa='input-date']").click().type(dateSaisieTaxon)
    const dateMaxVal = await promisify(cy.get("[data-qa='pnx-occtax-releve-form-datemax'] [data-qa='input-date']"))
    expect(dateMaxVal[0].value).to.equal(dateSaisieTaxon)
    cy.get("[data-qa=\"pnx-occtax-releve-submit-btn\"]")
      .should('be.enabled')
  });

  it("Should submit a new releve", () => {
    cy.get("[data-qa='pnx-occtax-releve-submit-btn']").click()
    // TODO : assert que y a bien un changement de page vers la page taxon 
  })


  // A Partir de là, on passe de l'écran relevé à l'écran taxon, TODO : le matérialiser proprement en termes d'incrémentation ou de structure de code 
  it("should not be possible to add any observation at the beginning", () => {
    // Le bouton d'ajout d'occurence doit être disable 
    const taxonInput = cy.get("input[data-qa='taxonomy-form-input'].ng-invalid");
    taxonInput.then(d => {
      expect(d[0].value).to.contains('')
      cy.get("[data-qa='occurrence-add-btn'][disabled='true']");
    })
  })

  it("Should focus on taxa input", ()=> {
    cy.focused()
    .invoke('attr', 'data-qa')
    .should('eq', 'taxonomy-form-input')
  });

  it("Should be possible to search and select taxa", async ()=> {
    const taxonInput = cy.get("input[data-qa='taxonomy-form-input'].ng-invalid");
    taxonInput.type(taxaSearch)
    const results = cy.get("ngb-typeahead-window")
    const firstTaxon = results.first().click() // TODO : variable utilisée? 
    const nomValideResult = cy.get("[data-qa='occurrence-nom-valide']");
    nomValideResult.contains("Canis lupus Linnaeus, 1758")
    cy.get('[data-qa="occurrence-add-btn"]').should('be.enabled')
    
    cy.get('[data-qa="pnx-nomenclature-meth-obs"] > ng-select > div > span.ng-clear-wrapper.ng-star-inserted').click()
    cy.get('[data-qa="occurrence-add-btn"]').should('be.disabled')
    cy.get('[data-qa="pnx-nomenclature-info-comp"]').click()
    cy.get('[data-qa="pnx-nomenclature-meth-obs-error"]').contains(" Veuillez indiquer la technique d'observation ")
    cy.get('[qa-test="Technique d\'observation"]').click()
    cy.get('[data-qa="Pour tout cas qui ne rentrerait pas dans la présente liste. Le nombre d\'apparitions permettra de faire évoluer la nomenclature."]').click()
    cy.get('[data-qa="occurrence-add-btn"]').should('be.enabled')

    cy.get('[data-qa="pnx-nomenclature-eta-bio"] > ng-select > div > span.ng-clear-wrapper.ng-star-inserted').click()
    cy.get('[data-qa="occurrence-add-btn"]').should('be.disabled')
    cy.get('[data-qa="pnx-nomenclature-info-comp"]').click()
    cy.get('[data-qa="pnx-nomenclature-eta-bio-error"]').contains(" Veuillez indiquer l'état biologique ")
    cy.get('[qa-test="Etat biologique"]').click()
    cy.get('[data-qa="L\'individu a été observé vivant."]').click()
    cy.get('[data-qa="occurrence-add-btn"]').should('be.enabled')

    cy.get('[data-qa="pnx-occtax-taxon-form-advanced"]').click()
    cy.get('[data-qa="pnx-occtax-taxon-form-determinator"]')

    cy.get('[qa-test="Objet du dénombrement"] > div > span.ng-clear-wrapper.ng-star-inserted').click()
    cy.get('[data-qa="pnx-nomenclature-obj-denombrement"] > div:nth-child(1)').click()
    cy.get('[data-qa="pnx-nomenclature-obj-denombrement"] > small').contains(" Veuillez indiquer l'objet du dénombrement ")
    cy.get('[qa-test="Objet du dénombrement"]').click()
    cy.get('[data-qa="Nombre d\'individus observés."]').click()

    cy.get("#left-form").scrollTo("bottom")
    cy.get('[data-qa="pnx-occtax-taxon-form-add-count"]').click()
    cy.get('[data-qa="pnx-occtax-taxon-form-count-1"]')
    cy.get("[data-qa='pnx-occtax-taxon-form-count-1'] > mat-expansion-panel > mat-expansion-panel-header > span > mat-panel-description").click({force: true})
    const listCount = await promisify(cy.get('[data-qa="pnx-occtax-taxon-form-count"]'))
    expect(listCount[0].children.length).to.equal(2)
  })

  // it("should focus on sumbit button", ()=> {
  //   // check the button add occurrence is focused
  //   cy.focused()
  //   .invoke('attr', 'data-qa')
  //   .should('eq', 'occurrence-add-btn')
  // }) TODO : à supprimer ou pas ? 

  it("Should autocompete count max with count min value", () => {
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
    cy.get("[data-qa='occurrence-add-btn']").click({force: true})
  })

  it("Should save the good taxa", async () => {
    const cyTaxaHead = cy.get('[data-qa="pnx-occtax-taxon-form-taxa-head-0"]')
    const taxaHead = await promisify(cyTaxaHead)
    expect(taxaHead[0].innerText).to.equal(taxaNameRef)

    cyTaxaHead.click()
  })

  it("Should display good taxa's name", async () => {
    const cyTaxaName = cy.get('[data-qa="pnx-occtax-taxon-form-taxa-name-0"]')
    const taxaName = await promisify(cyTaxaName)
    expect(taxaName[0].innerText).to.equal(taxaNameRef)
  })

  it("Should display good taxa's obs tech", async () => {
    const cyTaxaObsTech = cy.get('[data-qa="pnx-occtax-taxon-form-taxa-ObsTech-0"]')
    const taxaObsTech = await promisify(cyTaxaObsTech)
    expect(taxaObsTech[0].innerText).to.equal("Autre")
  })

  it("Should close observation", () => {
    cy.get("[data-qa='pnx-occtax-taxon-form-finish']").click()
  })

  it("Should filter the last observation", () => {
    cy.get('[data-qa="pnx-occtax-filter"]').click()
    cy.get('[data-qa="taxonomy-form-input"]').type(taxaSearch)
    const results = cy.get("ngb-typeahead-window")
    const firstTaxon = results.first().click()
    cy.get('[data-qa="pnx-occtax-filter-date-min"] [data-qa="input-date"]').click().type(dateSaisieTaxon)
    cy.get('[data-qa="pnx-occtax-filter-search"]').click()
  })

  it("Should be the good taxa", async () => {
    const date = await promisify(cy.get("[data-qa='pnx-occtax-map-list'] > div > div.row > div:nth-child(2) > ngx-datatable > div > datatable-body > datatable-selection > datatable-scroller > datatable-row-wrapper > datatable-body-row > div.datatable-row-center.datatable-row-group.ng-star-inserted > datatable-body-cell:nth-child(7) > div > div > span"))
    expect(date[0].innerText).to.equal("25-01-2022")
  })

  it("Should delete the taxa", () => {
    cy.get('[data-qa="pnx-occtax-delete-taxa-0"]').click()
    // cy.wait(2000)
    cy.get('[data-qa="pnx-occtax-delete"]').click()
  })

});
