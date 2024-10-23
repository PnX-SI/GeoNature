import { USERS } from './constants/users';
import { VIEWPORTS } from './constants/common';
import { FILTERS_TABLE } from './constants/filters';
import {
  SELECTOR_IMPORT_LIST_TABLE,
  SELECTOR_IMPORT_LIST_TOOLBAR_SEARCH,
} from './constants/selectors';

// ////////////////////////////////////////////////////////////////////////////
//
// ////////////////////////////////////////////////////////////////////////////

const FIXTURE_PATH = 'import/synthese/liste_import.json';
const TIMEOUT_WAIT = 3000;

function filterMapList(importSeachTerm) {
  cy.get(SELECTOR_IMPORT_LIST_TOOLBAR_SEARCH).clear().type(importSeachTerm);
}

// ////////////////////////////////////////////////////////////////////////////
//
// ////////////////////////////////////////////////////////////////////////////

describe('Tests list import columns and rows content', () => {
  VIEWPORTS.forEach((viewport) => {
    context(`viewport: ${viewport.width}x${viewport.height}`, () => {
      // TODO: rechercher le user par son id
      const user = USERS[0];
      context(`user: ${user.login.username}`, () => {
        beforeEach(() => {
          cy.viewport(viewport.width, viewport.height);
          cy.geonatureLogin(user.login.username, user.login.password);
          cy.visitImport();
          cy.intercept(Cypress.env('apiEndpoint') + 'import/imports/?page=1&search=', {
            fixture: 'import/synthese/liste_import.json',
          });
        });

        //  NOTES: [TEST][IMPORT] Redondant avec le check du nombre de lignes dans list import via ce que doit voir un utilisateur ?
        it('Should display the correct number of rows ', () => {
          // TODO: mettre en accord le json de la fixture
          cy.fixture(FIXTURE_PATH).then((config) => {
            cy.get(SELECTOR_IMPORT_LIST_TABLE)
              .find('datatable-body-row')
              .its('length')
              .should('be.gte', config.count);
          });
        });
        it('Should display the correct columns present in default config ', () => {
          // Make an HTTP request to get the list of columns displayed for import
          cy.request('GET', Cypress.env('apiEndpoint') + 'gn_commons/config').then((response) => {
            // Extract the list of columns from the response
            const columnsImport = response.body.IMPORT.LIST_COLUMNS_FRONTEND;
            const columnNames = columnsImport.map((column) => column.name);
            // Assert that each column name exists in at least one header cell
            cy.get(`${SELECTOR_IMPORT_LIST_TABLE} datatable-header-cell`).should(($cells) => {
              columnNames.forEach((columnName) => {
                expect($cells.toArray().some((cell) => cell.innerText.trim() === columnName)).to.be
                  .true;
              });
            });
          });
        });
      });
    });
  });
});

describe('Tests Filter Search List Import', () => {
  VIEWPORTS.forEach((viewport) => {
    context(`viewport: ${viewport.width}x${viewport.height}`, () => {
      const user = USERS[0];

      context(`user: ${user.login.username}`, () => {
        beforeEach(() => {
          cy.viewport(viewport.width, viewport.height);
          cy.geonatureLogin(user.login.username, user.login.password);
          cy.visitImport();
          cy.get(SELECTOR_IMPORT_LIST_TABLE, { timeout: TIMEOUT_WAIT })
            .should('be.visible')
            .then(($table) => {
              FILTERS_TABLE.forEach((filter) => {
                filter.columnIndex = getColumnIndex($table, filter.columnName);
              });
            });
        });

        FILTERS_TABLE.forEach((filter) => {
          filter.searchTerm.forEach((searchTerm, index) => {
            const expectedRowsCount = filter.expectedRowsCount[index];

            it(`Should get ${expectedRowsCount} rows for search term "${searchTerm}" in column "${filter.columnName}"`, () => {
              performSearchAndAssertRowCount(filter, searchTerm, expectedRowsCount);
            });

            if (expectedRowsCount > 0) {
              it(`Should get a row containing "${searchTerm}" in column "${filter.columnName}"`, () => {
                performSearchAndAssertRowContent(filter, searchTerm);
              });
            }
          });
        });
      });
    });
  });

  function getColumnIndex($table, columnName) {
    const index = $table
      .find('datatable-header-cell')
      .toArray()
      .findIndex((headerCell) => Cypress.$(headerCell).text().trim() === columnName);
    expect(index).to.be.gte(0);
    return index;
  }

  function performSearchAndAssertRowCount(filter, searchTerm, expectedRowsCount) {
    filterMapList(searchTerm);
    cy.wait(TIMEOUT_WAIT);
    cy.get(`${SELECTOR_IMPORT_LIST_TABLE} datatable-body`, { timeout: TIMEOUT_WAIT }).within(() => {
      cy.get('datatable-body-row').should('have.length', expectedRowsCount);
    });
  }

  function performSearchAndAssertRowContent(filter, searchTerm) {
    filterMapList(searchTerm);
    cy.wait(TIMEOUT_WAIT);
    cy.get(`${SELECTOR_IMPORT_LIST_TABLE} datatable-body-row`, { timeout: TIMEOUT_WAIT })
      .eq(0)
      .as('firstRow');
    cy.get('@firstRow')
      .find('datatable-body-cell')
      .eq(filter.columnIndex)
      .invoke('text')
      .then((rowValue) => {
        cy.wrap(rowValue.trim()).should('contain', searchTerm);
      });
  }
});
