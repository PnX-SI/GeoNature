export const TIMEOUT_WAIT = 1000;

export function checkImportListSize(expectedLength) {
  cy.get('[data-qa=import-list-table] datatable-body', { timeout: TIMEOUT_WAIT }).within(
    () => {
      cy.get('datatable-body-row').should('have.length', expectedLength);
    }
  )
}
