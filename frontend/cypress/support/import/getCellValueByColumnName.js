Cypress.Commands.add('getCellValueByColumnName', (tableSelector, columnName, cellValue) => {
  cy.get(`${tableSelector} datatable-body-row`).each(($row, rowIndex) => {
    const cellSelector = `[data-qa="import-list-table-row-${rowIndex}-${columnName
      .replace(/\s+/g, '-')
      .toLowerCase()}"]`;
    cy.wrap($row)
      .find(cellSelector)
      .then(($cell) => {
        if ($cell.text().trim() === cellValue) {
          cy.wrap($cell)
            .find('a')
            .should('exist')
            .then(($link) => {
              cy.wrap($link).as('targetLink');
            });
        }
      });
  });
});
