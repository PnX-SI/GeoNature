import { USERS } from './constants/users';
import { VIEWPORTS } from './constants/common';
import { SELECTOR_IMPORT_LIST_TABLE } from './constants/selectors';

// ////////////////////////////////////////////////////////////////////////////
//
// ////////////////////////////////////////////////////////////////////////////

const COLUMNS = [
  { columnName: 'Id Import', sortable: true },
  { columnName: 'Fichier', sortable: true },
  { columnName: 'Auteur', sortable: false },
  { columnName: 'Debut import', sortable: true },
  { columnName: 'Destination', sortable: true },
  { columnName: 'Fin import', sortable: true },
];

function getColumnIndexByName(columnName) {
  return cy.get('datatable-header-cell').then(($headerCells) => {
    const index = $headerCells
      .toArray()
      .findIndex((cell) => Cypress.$(cell).text().trim() === columnName);
    if (index >= 0) {
      return index;
    } else {
      throw new Error(`Column with name ${columnName} not found`);
    }
  });
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
          cy.getGlobalConfig();
        });

        it('should verify column names in header', () => {
          cy.get('@globalColumnsConfig').then((columns) => {
            cy.get(`${SELECTOR_IMPORT_LIST_TABLE} datatable-header-cell`).should(($cells) => {
              columns.forEach((column) => {
                expect($cells.toArray().some((cell) => cell.innerText.trim() === column.name)).to.be
                  .true;
              });
            });
          });
        });

        COLUMNS.forEach(({ columnName, sortable }) => {
          if (sortable) {
            if (columnName == 'Id Import') {
              it.skip(
                `should sort the table by the ${columnName} column in ascending/descending order`
              );
            } else {
              it(`should sort the table by the ${columnName} column in ascending/descending order`, () => {
                getColumnIndexByName(columnName).then((columnIndex) => {
                  // Ascending order
                  cy.get(
                    `[title="${columnName}"] > .datatable-header-cell-template-wrap > .datatable-icon-sort-unset`
                  ).click();
                  cy.get(SELECTOR_IMPORT_LIST_TABLE).within(() => {
                    cy.get('datatable-body-row').then(($rows) => {
                      const texts = [...$rows].map((row) => {
                        const cell = row.querySelectorAll('datatable-body-cell')[columnIndex];
                        return cell ? cell.innerText.trim() : '';
                      });
                      const sortedTexts = [...texts].sort();
                      expect(texts).to.deep.equal(sortedTexts);
                    });
                  });

                  // Descending order
                  cy.get(
                    `[title="${columnName}"] > .datatable-header-cell-template-wrap > .sort-btn`
                  ).click();
                  cy.get(SELECTOR_IMPORT_LIST_TABLE).within(() => {
                    cy.get('datatable-body-row').then(($rows) => {
                      const texts = [...$rows].map((row) => {
                        const cell = row.querySelectorAll('datatable-body-cell')[columnIndex];
                        return cell ? cell.innerText.trim() : '';
                      });

                      const sortedTexts = [...texts].sort().reverse();
                      expect(texts).to.deep.equal(sortedTexts);
                    });
                  });
                });
              });
            }
          } else if (columnName === columnName && !sortable) {
            // Test for non-sortable columns
            it(`should not sort the table by the ${columnName} column as it is not sortable`, () => {
              getColumnIndexByName(columnName).then((columnIndex) => {
                cy.get(
                  `[title="${columnName}"] > .datatable-header-cell-template-wrap > .datatable-icon-sort-unset`
                ).should('not.exist');
              });
            });
          }
        });
      });
    });
  });
});
