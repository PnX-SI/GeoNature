const fixturePath = 'import/synthese/liste_import.json';
const tableSelector = '[data-qa=import-list-table]';
const timeoutWait = 1000;
function filterMapList(importSeachTerm) {
  cy.get('[data-qa="import-list-toolbar-search"]').clear().type(importSeachTerm);
}

describe('Test specific route call with specific pattern used in filter input', () => {
  beforeEach(() => {
    cy.viewport(1024, 768);
    cy.geonatureLogin();
    cy.visit('/#/import');
  });
  const importSearchTerm = 'valid_file.csv';
  it('should call the route with the correct pattern', () => {
    // Intercept the network request
    cy.intercept(
      Cypress.env('apiEndpoint') + 'import/imports/?page=1&search=' + importSearchTerm
    ).as('getItems');
    cy.get('[data-qa="import-list-toolbar-search"]').clear().type(importSearchTerm);

    // Wait for the request and then verify the details
    cy.wait('@getItems').then((interception) => {
      const params = new URLSearchParams(interception.request.url.split('?')[1]);
      expect(params.get('search')).to.equal(importSearchTerm);
    });
  });
});

describe('Tests list import columns and rows content', () => {

  beforeEach(() => {
    cy.viewport(1024, 768);
    cy.geonatureLogin();
    cy.visit('/#/import');
    cy.intercept(Cypress.env('apiEndpoint') + 'import/imports/?page=1&search=', {
      fixture: 'import/synthese/liste_import.json',
    });
  });

  it('Should display the correct number of rows ', () => {
    let expectedRowCount;

    cy.fixture(fixturePath).then((config) => {
      expectedRowCount = config.count;
      cy.get(tableSelector).find('datatable-body-row').should('have.length', expectedRowCount);
    });
  });

  it('Should display the correct columns present in default config ', () => {
    // Make an HTTP request to get the list of columns displayed for import
    cy.request('GET', Cypress.env('apiEndpoint') + 'gn_commons/config').then((response) => {
      // Extract the list of columns from the response
      const columnsImport = response.body.IMPORT.LIST_COLUMNS_FRONTEND;
      const columnNames = columnsImport.map((column) => column.name);
      // Assert that each column name exists in at least one header cell
      cy.get('[data-qa=import-list-table] datatable-header-cell').should(($cells) => {
        columnNames.forEach((columnName) => {
          expect($cells.toArray().some((cell) => cell.innerText.trim() === columnName)).to.be
            .true;
        });
      });
    });
  });
});


//  NOTES : WORKS ONLY IF UPLOAD two valid file (Synthese and Occhab --> from test files backend)
describe('Tests Filter Search List Import', () => {
  const filters = [
    {
      columnName: 'Voir la fiche du JDD',
      searchTerm: ['habitat', 'tous règnes confondus'],
      expectedRowsCount: [1, 1],
    },
    {
      columnName: 'Fichier',
      searchTerm: ['valid_file.csv', 'invalid_file.csv'],
      expectedRowsCount: [2, 0],
    },
  ];

  beforeEach(() => {
    cy.viewport(1024, 768);
    cy.geonatureLogin(); cy.visit('/#/import');
    // Ensure the import list table is present before proceeding
    cy.get('[data-qa=import-list-table]', { timeout: timeoutWait })
      .should('be.visible')
      .then(($table) => {
        // Calculate column index here, once the table is visible
        filters.forEach((filter) => {
          filter.columnIndex = $table
            .find('datatable-header-cell')
            .toArray()
            .findIndex((headerCell) => {
              return Cypress.$(headerCell).text().trim() === filter.columnName;
            });
          expect(filter.columnIndex).to.be.gte(0); // Ensure the column is found
        });
      });
  });

  filters.forEach((filter) => {
    filter.searchTerm.forEach((searchTerm, index) => {
      const expectedRowsCount = filter.expectedRowsCount[index];

      it(`Should get ${expectedRowsCount} rows for search term "${searchTerm}" in column "${filter.columnName}"`, () => {
        filterMapList(searchTerm);
        cy.wait(timeoutWait); // Ensure any UI updates complete
        cy.get('[data-qa=import-list-table] datatable-body', { timeout: timeoutWait }).within(
          () => {
            cy.get('datatable-body-row').should('have.length', expectedRowsCount);
          }
        );
      });

      if (expectedRowsCount > 0) {
        it(`Should get a row containing "${searchTerm}" in column "${filter.columnName}"`, () => {
          filterMapList(searchTerm);
          cy.wait(timeoutWait);

          cy.get('[data-qa=import-list-table] datatable-body-row', { timeout: timeoutWait })
            .eq(0)
            .as('firstRow');
          cy.get('@firstRow')
            .find('datatable-body-cell')
            .eq(filter.columnIndex)
            .invoke('text')
            .then((rowValue) => {
              cy.wrap(rowValue.trim()).should('contain', searchTerm);
            });
        });
      }
    });
  });
});
