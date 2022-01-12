import promisify from 'cypress-promise'

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
        // check button sumbit is disabled
        const submitBtn = cy.get("[data-qa='occurrence-add-btn'][disabled='true']");
        // get taxon input which must be as required : .ng-invalid
        const taxonInput = cy.get("input[data-qa='taxonomy-form-input'].ng-invalid");
        taxonInput.type("canis lupus")
        const results = cy.get("ngb-typeahead-window")
        const firstTaxon = results.first().click()
        console.log(results);
        const nomValideResult = cy.get("[data-qa='occurrence-nom-valide']");
        nomValideResult.contains("Canis lupus Linnaeus, 1758")

        // check the button add occurrence is focused
        cy.focused()
        .invoke('attr', 'data-qa')
        .should('eq', 'occurrence-add-btn')

        // chek autocompletion on min/max
        const count_min = cy.get("[data-qa='counting-count-min']")
        console.log(count_min);
        const count_max = cy.get("[data-qa='counting-count-max']")


        });

});