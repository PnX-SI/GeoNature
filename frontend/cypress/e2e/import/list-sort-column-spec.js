import { USERS } from './constants/users';
import { VIEWPORTS } from './constants/common';
// ////////////////////////////////////////////////////////////////////////////
//
// ////////////////////////////////////////////////////////////////////////////
const columns = [
  { columnName: 'Id Import', sortable: true },
  { columnName: 'Fichier', sortable: true },
  { columnName: 'Auteur', sortable: false },
  { columnName: 'Debut import', sortable: true },
  { columnName: 'Destination', sortable: true },
  { columnName: 'Fin import', sortable: true },
]; 

function getColumnIndexByName(columnName) {
    return cy.get('datatable-header-cell').then(($headerCells) => {
      const index = $headerCells.toArray().findIndex((cell) => Cypress.$(cell).text().trim() === columnName);
      if (index >= 0) {
        return index;
      } else {
        throw new Error(`Column with name ${columnName} not found`);
      }
    });
  }
  

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
        });

        before(() => {
            cy.fetchGlobalColumns();
        });

      it('should verify column names in header', () => {

        cy.getGlobalColumns().then((columns) => {
        console.log(columns)
          cy.get('[data-qa=import-list-table] datatable-header-cell').should(($cells) => {
            columns.forEach((column) => {
              expect($cells.toArray().some((cell) => cell.innerText.trim() === column.name)).to.be
                .true;
            });
          });
        });
      });

      columns.forEach(({ columnName, sortable }) => {
        if (sortable) {
            // TODO: voir si nécessaire de checker l'état de l'icone pour la colonne de tri
        //  it(`should sort the table by the ${columnName} column and check icon changes`, () => {
        //     cy.get('datatable-header-cell').contains(columnName).then(($headerCell) => {
        //         const $sortIcon = cy.get('.datatable-icon-sort-unset.sort-btn');

        //         // Initial state check (icon should not have sorting class)
        //         cy.wrap($sortIcon).should('not.have.class', 'sort-desc').and('not.have.class', 'sort-asc');
        //     });
        //  })
          it(`should sort the table by the ${columnName} column in ascending order`, () => {
            getColumnIndexByName(columnName).then((columnIndex) => {
                cy.get('[data-qa=import-list-table]').within(() => {

                  cy.get('datatable-header-cell').contains(column.name).then(($headerCell) => {
                    // const $sortIcon = $headerCell.find('.sort-btn');
                    // Single click (should change to descending order)
                    cy.get('datatable-header-cell').eq(columnIndex).click();
                    // cy.wrap($sortIcon).should('have.class', 'sort-desc');
                  });
                });

                cy.wait(1000);
                cy.get('[data-qa=import-list-table]').within(() => {
                  cy.get('datatable-body-row').then(($rows) => {
                    const texts = [...$rows].map((row) => {
                      const cell = row.querySelectorAll('datatable-body-cell')[columnIndex];
                      return cell ? cell.innerText.trim() : '';
                    });


                    const sortedTexts = [...texts].sort();
                    console.log("texts", texts)
                    console.log("Ascent sortedTexts", sortedTexts)
                    expect(texts).to.deep.equal(sortedTexts);
                  });
                });
              });
            });

            it(`should sort the table by the ${columnName} column in descending order`, function () {
              getColumnIndexByName(columnName).then((columnIndex) => {
                cy.get('[data-qa=import-list-table]').within(() => {
                  cy.get('datatable-header-cell').eq(columnIndex).click().click();
                });

                cy.wait(1000);
                cy.get('[data-qa=import-list-table]').within(() => {
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
        } else if (columnName === columnName && !sortable) {
          // Test for non-sortable columns
          it(`should not sort the table by the ${columnName} column as it is not sortable`, () => {
            getColumnIndexByName(columnName).then((columnIndex) => {
                cy.get('[data-qa=import-list-table]').within(() => {
                  cy.get('datatable-header-cell').eq(columnIndex).click();
                });

                cy.wait(1000);
                cy.get('[data-qa=import-list-table]').within(() => {
                  cy.get('datatable-body-row').then(($rows) => {
                    const texts = [...$rows].map((row) => {
                      const cell = row.querySelectorAll('datatable-body-cell')[columnIndex];
                      return cell ? cell.innerText.trim() : '';
                    });

                    const originalTexts = [...texts];
                    const sortedTexts = [...texts].sort();
                    expect(originalTexts).to.not.deep.equal(sortedTexts);
                  });
                });
            });
          });
        }
      });
    });
  });
});
});
