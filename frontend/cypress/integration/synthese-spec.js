describe("Geonature connection", () => {
  beforeEach(() => {
    cy.visit("http://127.0.0.1:4200");
    cy.get("#login").type("admin");
    cy.get("#cdk-step-content-0-0 > form > div:nth-child(2) > input").type(
      "admin"
    );
    cy.get("#cdk-step-content-0-0 > form > button").click();
  });

  it("should display synthese window", () => {
      // access to synthese
      cy.visit("http://127.0.0.1:4200/#/synthese")
      // check there are elements in the list
      cy.get("datatable-scroller").children('datatable-row-wrapper');
  });

  /* ==== Test Created with Cypress Studio ==== */
  it('Taxa search by name', function() { // objectifs : pouvoir rentrer un nom d'espèce dans le filtre, que cela affiche le ou les observations sur la liste correspondant à ce nom
    cy.get('[href="http://127.0.0.1:4200/#/synthese"] > .mat-list-item > .mat-list-item-content').click();
    cy.get('#taxonInput').clear();
    cy.get('#taxonInput').type('lynx');
    cy.get('#ngb-typeahead-1-1 > .ng-star-inserted > i').click();
    cy.get('.button-success').click();
    const table = cy.get('body > pnx-root > pnx-nav-home > mat-sidenav-container > mat-sidenav-content > div > div > pnx-synthese > div > div > div.col-sm-12.col-md-5.padding-sm > pnx-synthese-list > ngx-datatable > div > datatable-body > datatable-selection > datatable-scroller > datatable-row-wrapper > datatable-body-row')
    table.then(d=>{
      expect(d.length).to.greaterThan(0)
      console.log(d)
    })
    const cell = cy.get("body > pnx-root > pnx-nav-home > mat-sidenav-container > mat-sidenav-content > div > div > pnx-synthese > div > div > div.col-sm-12.col-md-5.padding-sm > pnx-synthese-list > ngx-datatable > div > datatable-body > datatable-selection > datatable-scroller > datatable-row-wrapper > datatable-body-row > div.datatable-row-center.datatable-row-group.ng-star-inserted > datatable-body-cell:nth-child(3) > div")
    cell.contains(' Lynx boréal ')
    /* ==== End Cypress Studio ==== */
  });

  /* ==== Test Created with Cypress Studio ==== */
  it('Taxa search by dates', function() { // objectifs : pouvoir changer les dates des filtres, que cela affiche le ou les taxons dans la liste d'observations dans la plage de dates donnée 
    // (prendre deux ou trois observations et vérifier que la date d'obs soit supérieure à date min et inférieure à date max) 
    cy.get('[href="http://127.0.0.1:4200/#/synthese"] > .mat-list-item > .mat-list-item-content > .module-name').click();
    cy.get(':nth-child(2) > pnx-date > .input-group > .input-group-append > .btn > .fa').click();
    cy.get('[aria-label="Select year"]').select('2017');
    cy.get('ngb-datepicker-navigation.ng-star-inserted > :nth-child(1) > .btn').click();
    cy.get('[aria-label="Saturday, December 24, 2016"] > .btn-light').click();
    cy.get(':nth-child(3) > pnx-date > .input-group > .form-control').click();
    cy.get('[aria-label="Select year"]').select('2017');
    cy.get('[aria-label="Monday, January 2, 2017"] > .btn-light').click();
    cy.get('.button-success > .mat-button-wrapper').click();
    /* ==== End Cypress Studio ==== */
  });

  /* ==== Test Created with Cypress Studio ==== */
  it('Taxa search by observer', function() { //objectifs : pouvoir entrer un nom d'observateur (ici Admin); 
    //cliquer sur rechercher et vérifier que les observations retournées ont bien pour observateur des personnes contenant 'Admin' 
    cy.get('[href="http://127.0.0.1:4200/#/synthese"] > .mat-list-item > .mat-list-item-content > .module-name').click();
    cy.get(':nth-child(4) > .ng-star-inserted > .input-group > .form-control').clear();
    cy.get(':nth-child(4) > .ng-star-inserted > .input-group > .form-control').type('Admin');
    cy.get('.button-success').click();
    /* ==== End Cypress Studio ==== */
  });

  /* ==== Test Created with Cypress Studio ==== */
  it('Taxa search by new filter', function() {
    //objectifs : pouvoir ajouter un nouveau filtre, ici comprotement (assert que nouveau filtre est bon) 
    // pouvoir sélectionner une valeur dans ce nouveau champ 
    // pouvoir afficher les observations comportant la valeur du champ sélectionné. ici la migration (dans comportement) d'un albatros (fraichement ajouté) 
    // ceci implique d'avoir une donnée de base avec un comportement défini ou un autre filtre  
    cy.get('[href="http://127.0.0.1:4200/#/synthese"] > .mat-list-item > .mat-list-item-content > .module-name').click();
    cy.get('pnx-dynamic-form-generator > :nth-child(1) > .input-group > .form-control').select('3: Object');
    cy.get('.ng-star-inserted > .auto > .ng-select-container > .ng-value-container > .ng-input > input').click();
    cy.get('#a76c8302f192-13 > .mat-tooltip-trigger').click();
    cy.get('.button-success > .mat-button-wrapper').click();
    /* ==== End Cypress Studio ==== */
  });
});