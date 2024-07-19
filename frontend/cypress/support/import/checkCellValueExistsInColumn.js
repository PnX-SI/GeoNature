Cypress.Commands.add('checkCellValueExistsInColumn', (tableSelector, columnName, cellValue) => {
  let cellExists = false;
  cy.get(`${tableSelector} datatable-body-row`)
    .each(($row, rowIndex) => {
      const cellSelector = `[data-qa="import-list-table-row-${rowIndex}-${columnName
        .replace(/\s+/g, '-')
        .toLowerCase()}"]`;
      cy.log('cellSelector: ' + cellSelector);
      cy.log('cellValue: ' + cellValue);
      cy.wrap($row)
        .find(cellSelector)
        .then(($cell) => {
          cy.log('cellValue: ' + cellValue);
          cy.log('cellText: ' + $cell.text().trim());
          if ($cell.text().trim() === cellValue) {
            cellExists = true;
            return false;
          }
        });
    })
    .then(() => {
      // Return the result
      return cy.wrap(cellExists).as('cellValueExists');
    });
});
