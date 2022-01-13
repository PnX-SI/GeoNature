beforeEach(() => {
  cy.viewport(1600,1000)
  cy.visit("/");
  cy.get("#login").type("admin");
  cy.get("#cdk-step-content-0-0 > form > div:nth-child(2) > input").type(
    "admin"
  );
  cy.get("#cdk-step-content-0-0 > form > button").click();
  // access to synthese
  cy.visit("/#/synthese")
});

describe("Geonature connection", () => {
  
  it("should display synthese window", () => {
    // check there are elements in the list --> au 13/01/22, ce test n'est pas complet, plus d'éléments testables sur la fenêtre : présence des filtres, de la carte et des listes d'observations
    cy.get("datatable-scroller").children('datatable-row-wrapper');
  });

  /* ==== Test Created with Cypress Studio ==== */
  it('Taxa search by name', function() { // objectifs : pouvoir rentrer un nom d'espèce dans le filtre, que cela affiche le ou les observations sur la liste correspondant à ce nom
    cy.get('#taxonInput').clear();
    cy.get('#taxonInput').type('lynx');
    cy.get('#ngb-typeahead-0-0').click();
    cy.get('.button-success').click();
    cy.wait(500)
    const table = cy.get('body > pnx-root > pnx-nav-home > mat-sidenav-container > mat-sidenav-content > div > div > pnx-synthese > div > div > div.col-sm-12.col-md-5.padding-sm > pnx-synthese-list > ngx-datatable > div > datatable-body > datatable-selection > datatable-scroller > datatable-row-wrapper > datatable-body-row')
    table.then(d=>{
      expect(d.length).to.greaterThan(0)
      Array.prototype.forEach.call(d,e=>{
        expect(e.children[1].children[2].firstChild.innerText).to.equal('Lynx boréal')
      })
    })
  });

  /* ==== Test Created with Cypress Studio ==== */
  it('Taxa search by dates', function() { // objectifs : pouvoir changer les dates des filtres, que cela affiche le ou les taxons dans la liste d'observations dans la plage de dates donnée 
    // (prendre deux ou trois observations et vérifier que la date d'obs soit supérieure à date min et inférieure à date max) 
    cy.get(':nth-child(2) > pnx-date > .input-group > .input-group-append > .btn > .fa').click();
    cy.get('[aria-label="Select year"]').select('2017');
    cy.get('ngb-datepicker-navigation.ng-star-inserted > :nth-child(1) > .btn').click();
    cy.get('[aria-label="Saturday, December 24, 2016"] > .btn-light').click();
    cy.get(':nth-child(3) > pnx-date > .input-group > .form-control').click();
    cy.get('[aria-label="Select year"]').select('2017');
    cy.get('[aria-label="Monday, January 2, 2017"] > .btn-light').click();
    cy.get('.button-success > .mat-button-wrapper').click();
    const table = cy.get('body > pnx-root > pnx-nav-home > mat-sidenav-container > mat-sidenav-content > div > div > pnx-synthese > div > div > div.col-sm-12.col-md-5.padding-sm > pnx-synthese-list > ngx-datatable > div > datatable-body > datatable-selection > datatable-scroller > datatable-row-wrapper > datatable-body-row')
    table.then(d=>{
      expect(d.length).to.greaterThan(0)
    })
    const cell = cy.get('body > pnx-root > pnx-nav-home > mat-sidenav-container > mat-sidenav-content > div > div > pnx-synthese > div > div > div.col-sm-12.col-md-5.padding-sm > pnx-synthese-list > ngx-datatable > div > datatable-body > datatable-selection > datatable-scroller > datatable-row-wrapper:nth-child(1) > datatable-body-row > div.datatable-row-center.datatable-row-group.ng-star-inserted > datatable-body-cell:nth-child(4) > div')
    cell.contains(' 01-01-2017 ')
  });

  /* ==== Test Created with Cypress Studio ==== */
  it('Taxa search by observer', function() { //objectifs : pouvoir entrer un nom d'observateur (ici Admin); 
    // cliquer sur rechercher et vérifier que les observations retournées ont bien pour observateur des personnes contenant 'Admin' 
    cy.get(':nth-child(4) > .ng-star-inserted > .input-group > .form-control').clear();
    cy.get(':nth-child(4) > .ng-star-inserted > .input-group > .form-control').type('Admin');
    cy.get('.button-success').click();
    cy.wait(500)
    const table = cy.get('body > pnx-root > pnx-nav-home > mat-sidenav-container > mat-sidenav-content > div > div > pnx-synthese > div > div > div.col-sm-12.col-md-5.padding-sm > pnx-synthese-list > ngx-datatable > div > datatable-body > datatable-selection > datatable-scroller > datatable-row-wrapper > datatable-body-row')
    table.then(d=>{
      expect(d.length).to.greaterThan(0)
      Array.prototype.forEach.call(d,e=>{
        expect(e.children[1].children[5].firstChild.innerText).to.equal('Administrateur test')
      })
    })
  });

  // /* ==== Test Created with Cypress Studio ==== */
  it('Taxa search by new filter', function() {
    //objectifs : pouvoir ajouter un nouveau filtre, ici comprotement (assert que nouveau filtre est bon) 
    // pouvoir sélectionner une valeur dans ce nouveau champ 
    // pouvoir afficher les observations comportant la valeur du champ sélectionné. ici la migration (dans comportement) d'un albatros (fraichement ajouté) 
    // ceci implique d'avoir une donnée de base avec un comportement défini ou un autre filtre  
    // cy.get('[href="http://localhost:4200/#/synthese"] > .mat-list-item > .mat-list-item-content > .module-name').click();
    cy.get('pnx-dynamic-form-generator > :nth-child(1) > .input-group > .form-control').select('3: Object');
    cy.get('.ng-star-inserted > .auto > .ng-select-container > .ng-value-container > .ng-input > input').click();
    cy.get("#sidebar > pnx-synthese-search > div.card.search-wrapper > fieldset:nth-child(6) > pnx-dynamic-form-generator > div.full-wrapper.ng-star-inserted > div > pnx-dynamic-form > div > div > pnx-nomenclature > ng-select")
    .type("Migra")
    cy.get('[qa-test="Migration : L\'individu (ou groupe d\'individus) est en migration active"]').click();
    cy.get('.button-success > .mat-button-wrapper').click();
    cy.get(':nth-child(1) > .datatable-body-cell-label > .btn > .mat-tooltip-trigger').click();
    cy.get("#mat-tab-content-0-0 > div > table > tr:nth-child(6) > td:nth-child(1)").contains(" Comportement ")
    cy.get("#mat-tab-content-0-0 > div > table > tr:nth-child(6) > td:nth-child(2)").contains(" Migration ")
    cy.debug()
  });

  /* ==== Test Created with Cypress Studio ==== */
  // it('Taxa search with dataset', function() {
  //   //objectifs : pouvoir sélectionnner un jeu de données dans la liste déroulante, jeu de données qui existe bien dans les métadonnées (voir si testable)
  //   //cliquer sur rechercher et vérifier que les observations retournées ont bien pour jeu de données le jeu de données sélectionné
  //   cy.get('[href="http://localhost:4200/#/synthese"] > .mat-list-item > .mat-list-item-content > .module-name').click();
  //   cy.get('pnx-datasets > .auto > .ng-select-container > .ng-value-container > .ng-input > input').click();
  //   cy.get('#ab5b2c6557fb-0 > .mat-tooltip-trigger > .pre-wrap').click();
  //   cy.get('.button-success > .mat-button-wrapper').click();
  //   /* ==== End Cypress Studio ==== */
  // });

  // it('Interaction acquisition framework & dataset', function() {
  //   // objectifs : pouvoir sélectionnner un jeu de données dans la liste déroulante qui soit lié au bon cadre d'acquisition correspondannt, je suis pas sûr que ce soir dans la synthèse --<
  //   // vérifier que la sélection d'un cadre d'acquisition filtre bien les jeux de données 
  //   /* ==== End Cypress Studio ==== */
  // });

  /* ==== Test Created with Cypress Studio ==== */
  it('Taxa search with acquisition framework and dataset', function() { 
    // ce test permet de faire une suite d'actions basées sur la sélection des CA et des JDD
    // l'idéal serait de tester sur plus que la première ligne, ce qui n'est pas le cas au 13/01/22
    cy.get('pnx-acquisition-frameworks > .auto > .ng-select-container > .ng-value-container').click(); // selection d'un cadre d'acquisition 
    cy.get('[qa-test="Données d\'observation de la faune, de la Flore et de la fonge du Parc national des Ecrins"]').click(); //doit assert que le cadre d'acquisition se met bien dans la barre de multiselect 
    cy.get('pnx-datasets > .auto > .ng-select-container > .ng-value-container > .ng-input > input').click(); // doit assert que les jeux de données disponibles sont bien ceux associés au cadre d'acquisition (je sais pas comment faire?)
    cy.get('[qa-test="ATBI de la réserve intégrale du Lauvitel dans le Parc national des Ecrins"]').click(); //doit assert que le jeu de données sélectionné se met bien dans la barre multiselect 
    cy.get('.button-success').click(); //cliquer sur rechercher, la liste des observations doit évoluer et on doit assert que toutes les observations disponibles sont associés au(x) jeu(x) de données sélectionné(s) (direct dans le tableau)
    cy.get(':nth-child(1) > .clickable > .datatable-row-center > :nth-child(1) > .datatable-body-cell-label > .btn > .mat-tooltip-trigger').click(); //clic sur le bouton d'information, assert que cela sorte une pop up avec la donnée sélectionnée (bon identifiant (test sur l'espèce ?))
    cy.get('#mat-tab-content-0-0 > div > table > tr:nth-child(1) > td:nth-child(2)').contains(" Présent ")
    cy.get('#mat-tab-label-0-1 > .mat-tab-label-content').click(); //clic sur métadonnées --> doit bien changer de page et être sur la page métadonnées
    cy.get('#mat-tab-content-0-1 > div > table > tr:nth-child(2) > td:nth-child(2)').contains(" Données d'observation de la faune, de la Flore et de la fonge du Parc national des Ecrins")
    cy.get('#mat-tab-content-0-1 > div > table > tr:nth-child(1) > td:nth-child(2)').contains(" ATBI de la réserve intégrale du Lauvitel dans le Parc national des Ecrins ")
  });
});