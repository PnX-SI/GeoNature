import './backToImportList';
import './checkCurrentPageIsImport';
import './checkImportListSize';
import './configureImportContentMapping';
import './configureImportFieldMapping';
import './configureImportFile';
import './deleteCurrentImport';
import './geonatureInitImportList';
import "./hasToastError";
import './executeImport';
import './loadImportFile';
import './pickDataset';
import './pickDestination';
import './removeFirstImportInList';
import './startImport';
import './verifyImport';
import './visitImport';
import './getURLStepImport';


Cypress.Commands.add('getGlobalConfig', () => {
  return cy.request('GET', Cypress.env('apiEndpoint') + 'gn_commons/config')
    .its('body.IMPORT.LIST_COLUMNS_FRONTEND')
    .then((columnsImport) => {
      const columnNames = ['Id Import', 'Fichier', 'Auteur', 'Debut import', 'Destination', 'Fin import'];
      const columns = columnsImport
                .filter((column) => columnNames.includes(column.name))
                .map((column) => ({
                  name: column.name,
                  sortable: column.filter
                }));
      return columns
    })
    .as('globalColumnsConfig');
});


Cypress.Commands.add('checkCellValueExistsInColumn', (tableSelector, columnName, cellValue) => {
  let cellExists = false;
  cy.get(`${tableSelector} datatable-body-row`).each(($row, rowIndex) => {
      const cellSelector = `[data-qa="import-list-table-row-${rowIndex}-${columnName.replace(/\s+/g, '-').toLowerCase()}"]`;
      cy.log("cellSelector: " + cellSelector);
      cy.log("cellValue: " + cellValue);
      cy.wrap($row).find(cellSelector).then(($cell) => {
        cy.log("cellValue: " + cellValue);
        cy.log("cellText: " + $cell.text().trim());
          if ($cell.text().trim() === cellValue) {
            cellExists = true;
            return false; 
          }
      });
  }).then(() => {
    // Return the result
    return cy.wrap(cellExists).as('cellValueExists');
});
});
