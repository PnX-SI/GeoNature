import { USERS } from './constants/users';
import { VIEWPORTS } from './constants/common';

// ////////////////////////////////////////////////////////////////////////////
//
// ////////////////////////////////////////////////////////////////////////////
const timeoutWait = 1000;
const columnName = 'Voir la fiche du JDD';
const jddList = ['JDD-TEST-IMPORT-ADMIN', 'JDD-TEST-IMPORT-2','JDD-TEST-IMPORT-3'];

Cypress.Commands.add('getCellValueByColumnName', (tableSelector, columnName, cellValue) => {
    cy.get(`${tableSelector} datatable-body-row`).each(($row, rowIndex) => {
        const cellSelector = `[data-qa="import-list-table-row-${rowIndex}-${columnName.replace(/\s+/g, '-').toLowerCase()}"]`;
        cy.wrap($row).find(cellSelector).then(($cell) => {
          if ($cell.text().trim() === cellValue) {
            cy.wrap($cell).find('a').should('exist').then(($link) => {
              cy.wrap($link).as('targetLink');
            });
          }
        });
      });
  });

describe('Test List import - Refer to JDD page', () => {
  VIEWPORTS.forEach((viewport) => {
    context(`viewport: ${viewport.width}x${viewport.height}`, () => {
      const user = USERS[0];
      context(`user: ${user.login.username}`, () => {
        beforeEach(() => {
          cy.viewport(viewport.width, viewport.height);
          cy.geonatureLogin(user.login.username, user.login.password);
          cy.visitImport();
        });

          jddList.forEach((cellValue) => it("Should be redirected to page Metada dataset with dataset name: " + cellValue , () => {
          cy.getCellValueByColumnName('[data-qa="import-list-table"]', columnName, cellValue).then(() => {
            cy.get('@targetLink').click();
            cy.wait(timeoutWait);
          });
          cy.location().then((loc) => {
            cy.log("Current URL: " + loc.href);
            expect(loc.href).to.include('metadata/dataset_detail/');
          });
        }));
        });

      });
    });
  });
