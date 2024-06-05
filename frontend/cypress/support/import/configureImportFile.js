const DEFAULT_SRID = 4326;

Cypress.Commands.add("configureImportFile", (srid) => {
  srid = srid ?? DEFAULT_SRID;
  cy.get('[data-qa="import-new-decode-srid"]').select(DEFAULT_SRID);
  cy.get('[data-qa="import-new-decode-validate"]').should("exist").click();
});
