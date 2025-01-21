import { USERS } from './constants/users';
import { TIMEOUT_WAIT, VIEWPORTS } from './constants/common';
import { FILES } from './constants/files';
import {
  getSelectorImportListTableRowDelete,
  getSelectorImportListTableRowEdit,
  SELECTOR_IMPORT_LIST_TABLE,
  SELECTOR_IMPORT_MODAL_DELETE,
} from './constants/selectors';

// ////////////////////////////////////////////////////////////////////////////
//
// ////////////////////////////////////////////////////////////////////////////

const COLUMN_NAME = 'Jeu de données';
const JDD_LIST = [
  {
    jdd_name: 'JDD-TEST-IMPORT-ADMIN',
    jdd_is_active: true,
    url_on_click_edit: Cypress.env('urlApplication') + 'import/occhab/process/1001',
  },
  {
    jdd_name: 'JDD-TEST-IMPORT-INACTIF',
    jdd_is_active: false,
    url_on_click_edit: Cypress.env('urlApplication') + 'import',
  },
];

// ////////////////////////////////////////////////////////////////////////////
//
// ////////////////////////////////////////////////////////////////////////////

describe('Tests actions on active/inactive list JDD ', () => {
  VIEWPORTS.forEach((viewport) => {
    context(`viewport: ${viewport.width}x${viewport.height}`, () => {
      const user = USERS[0];

      context(`user: ${user.login.username}`, () => {
        beforeEach(() => {
          cy.viewport(viewport.width, viewport.height);
          cy.geonatureLogin(user.login.username, user.login.password);
          cy.visitImport();
          cy.get(SELECTOR_IMPORT_LIST_TABLE, { timeout: TIMEOUT_WAIT }).should('be.visible');
        });

        JDD_LIST.forEach((jdd_item) => {
          it.skip(`should verify actions for ${jdd_item.jdd_name} (${
            jdd_item.jdd_is_active ? 'active' : 'inactive'
          })`, () => {
            cy.getRowIndexByCellValue(
              SELECTOR_IMPORT_LIST_TABLE,
              COLUMN_NAME,
              jdd_item.jdd_name
            ).then((rowIndex) => {
              verifyEditAction(rowIndex, jdd_item);
              verifyDeleteAction(rowIndex, jdd_item);
            });
          });
        });

        it.skip('Should be able to modify a finished import, but still active JDD', () => {
          cy.startImport();
          cy.pickDestination();
          cy.loadImportFile(FILES.synthese.valid.fixture);
          cy.configureImportFile();
          cy.configureImportFieldMapping(user.dataset);
          cy.configureImportContentMapping();
          cy.verifyImport();
          cy.executeImport();
          cy.backToImportList();

          cy.get(getSelectorImportListTableRowEdit.skip(0))
            .should('exist')
            .should('be.visible')
            .should('not.be.disabled');

          cy.request('PATCH', `${Cypress.env('apiEndpoint')}meta/dataset/${user.datasetId}`, {
            active: false,
          });

          cy.reload();
          cy.get(getSelectorImportListTableRowEdit.skip(0))
            .should('exist')
            .should('be.visible')
            .should('be.disabled');

          cy.request('PATCH', `${Cypress.env('apiEndpoint')}meta/dataset/${user.datasetId}`, {
            active: true,
          });

          cy.reload();
          cy.get(getSelectorImportListTableRowEdit.skip(0))
            .should('exist')
            .should('be.visible')
            .should('not.be.disabled');

          cy.removeFirstImportInList();
        });
      });
    });
  });
});

function verifyEditAction(rowIndex, jdd_item) {
  const actionStatus = jdd_item.jdd_is_active ? 'not.be.disabled' : 'be.disabled';
  cy.get(getSelectorImportListTableRowEdit.skip(rowIndex))
    .should('exist')
    .should('be.visible')
    .should(actionStatus)
    .then(($btn) => {
      if (!$btn.prop('disabled')) {
        cy.wrap($btn).click();
        cy.url().should('contain', jdd_item.url_on_click_edit);
        cy.visitImport(); // Reset state for the next action
        cy.get(SELECTOR_IMPORT_LIST_TABLE, { timeout: TIMEOUT_WAIT }).should('be.visible');
      }
    });
}

function verifyDeleteAction(rowIndex, jdd_item) {
  const actionStatus = jdd_item.jdd_is_active ? 'not.be.disabled' : 'be.disabled';
  cy.get(getSelectorImportListTableRowDelete(rowIndex))
    .should('exist')
    .should('be.visible')
    .should(actionStatus)
    .then(($btn) => {
      if (!$btn.prop('disabled')) {
        cy.wrap($btn).click();
        cy.get(SELECTOR_IMPORT_MODAL_DELETE).should('be.visible');
      }
    });
}
