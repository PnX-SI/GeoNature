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
  it('Taxa search', function() {
    /* ==== Generated with Cypress Studio ==== */
    cy.get('[href="http://127.0.0.1:4200/#/synthese"] > .mat-list-item > .mat-list-item-content').click();
    cy.get('#taxonInput').clear();
    cy.get('#taxonInput').type('lynx');
    cy.get('#ngb-typeahead-1-1 > .ng-star-inserted > i').click();
    cy.get('.button-success').click();
    const table = cy.get('body > pnx-root > pnx-nav-home > mat-sidenav-container > mat-sidenav-content > div > div > pnx-synthese > div > div > div.col-sm-12.col-md-5.padding-sm > pnx-synthese-list > ngx-datatable > div > datatable-body > datatable-selection > datatable-scroller > datatable-row-wrapper > datatable-body-row')
    table.then(d=>{
      expect(d.length).to.equal(1)
      console.log(d)
    })
    const cell = cy.get("body > pnx-root > pnx-nav-home > mat-sidenav-container > mat-sidenav-content > div > div > pnx-synthese > div > div > div.col-sm-12.col-md-5.padding-sm > pnx-synthese-list > ngx-datatable > div > datatable-body > datatable-selection > datatable-scroller > datatable-row-wrapper > datatable-body-row > div.datatable-row-center.datatable-row-group.ng-star-inserted > datatable-body-cell:nth-child(3) > div")
    cell.contains(' Lynx boréal ')
    /* ==== End Cypress Studio ==== */
  });
});