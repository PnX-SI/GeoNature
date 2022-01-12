describe("Occtax occurrence creation", () => {
    beforeEach(() => {
      cy.visit("http://127.0.0.1:4200");
      cy.get("#login").type("admin");
      cy.get("#cdk-step-content-0-0 > form > div:nth-child(2) > input").type(
        "admin"
      );
      cy.get("#cdk-step-content-0-0 > form > button").click();
    });

    it("should create occurrence", () => {
      cy.visit('http://127.0.0.1:4200/#/occtax/form/1/taxons');
      const taxonInput = cy.get("input[data-qa='taxonomy-form-input']");
      taxonInput.type("canis lupus")
      const results = cy.get("ngb-typeahead-window")
      const firstTaxon = results.first().click()
      console.log(results);
      const nomValideResult = cy.get("[data-qa='occurrence-nom-valide']");
      nomValideResult.contains("Canis lupus Linnaeus, 1758")

      /* ==== Generated with Cypress Studio ==== */
      cy.get('.ng-tns-c206-5 > :nth-child(2) > :nth-child(1) > .form-control').clear();
      cy.get('.ng-tns-c206-5 > :nth-child(2) > :nth-child(1) > .form-control').type('2');
      cy.get('.ng-tns-c206-5 > :nth-child(2) > :nth-child(2) > .form-control').clear();
      cy.get('.ng-tns-c206-5 > :nth-child(2) > :nth-child(2) > .form-control').type('4');
      cy.get('#mat-expansion-panel-header-2 > .mat-content > .mat-expansion-panel-header-description > .mat-tooltip-trigger').click();
      cy.get('#mat-expansion-panel-header-2 > .mat-content > .mat-expansion-panel-header-description > .mat-tooltip-trigger').click();
      /* ==== End Cypress Studio ==== */
    });

});