const DEFAULT_SRID = 'WGS84';

Cypress.Commands.add('configureImportFile', (srid) => {
  srid = srid ?? DEFAULT_SRID;
  cy.get('[data-qa="import-new-decode-srid"]').select(DEFAULT_SRID);
  cy.get('[data-qa="import-new-decode-validate"]').should('exist').click();
});
