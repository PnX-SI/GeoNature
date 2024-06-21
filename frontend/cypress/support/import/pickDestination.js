const DEFAULT_DESTINATION_NAME = "Synthèse";
Cypress.Commands.add("pickDestination", (destinationName) => {
  destinationName = destinationName ?? DEFAULT_DESTINATION_NAME;
  cy.get('[data-qa="import-new-modal-destinations"] > [data-qa="destinations"]').should("exist").click()
    .get("ng-dropdown-panel")
    .get(".ng-option").contains(destinationName).then((destination) => {
      cy.wrap(destination).should("exist").click();
      cy.get('[data-qa="import-modal-destination-validate"]').should("exist").click();
    });
});
