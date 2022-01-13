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
        // cy.get("datatable-scroller").children('datatable-row-wrapper');
        
    });

});