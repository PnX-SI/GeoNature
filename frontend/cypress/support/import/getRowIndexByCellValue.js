Cypress.Commands.add('getRowIndexByCellValue', (tableSelector, columnName, cellValue) => {
  // Define a new Cypress command to get the row index by cell value
  return cy
    .get(`${tableSelector} datatable-body-row`)
    .each(($row, rowIndex) => {
      const cellSelector = `[data-qa="import-list-table-row-${rowIndex}-${columnName
        .replace(/\s+/g, '-')
        .toLowerCase()}"]`;
      cy.wrap($row)
        .find(cellSelector)
        .then(($cell) => {
          if ($cell.text().trim() === cellValue) {
            cy.wrap(rowIndex).as('rowIndex');
          }
        });
    })
    .then(() => {
      // Return the aliased row index value
      return cy.get('@rowIndex');
    });
});
