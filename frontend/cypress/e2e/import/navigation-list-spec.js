import { USERS, availableImportsCount } from './constants/users';
import { VIEWPORTS } from './constants/common';
import {
  getSelectorImportListTableAction,
  LIST_TABLE_ACTIONS,
  SELECTOR_IMPORT_LIST,
  SELECTOR_IMPORT_LIST_TABLE,
  SELECTOR_IMPORT_LIST_TOOLBAR_DESTINATIONS,
  SELECTOR_IMPORT_LIST_TOOLBAR_SEARCH,
  SELECTOR_IMPORT_MODAL_DESTINATION_START,
} from './constants/selectors';

// ////////////////////////////////////////////////////////////////////////////
//
// ////////////////////////////////////////////////////////////////////////////

describe('Import List - Toolbar - Destinations', () => {
  VIEWPORTS.forEach((viewport) => {
    context(`viewport: ${viewport.width}x${viewport.height}`, () => {
      USERS.forEach((user) => {
        context(`user: ${user.login.username}`, () => {
          beforeEach(() => {
            cy.viewport(viewport.width, viewport.height);
            cy.geonatureLogin(user.login.username, user.login.password);
            cy.visitImport();
          });

          it('Should have a correct import list setup', () => {
            cy.get(SELECTOR_IMPORT_LIST).should('exist').should('be.visible');

            cy.get(SELECTOR_IMPORT_LIST_TOOLBAR_DESTINATIONS)
              .should('exist')
              .should('be.visible')
              .should('not.be.disabled');

            cy.get(SELECTOR_IMPORT_LIST_TOOLBAR_SEARCH)
              .should('exist')
              .should('be.visible')
              .should('not.be.disabled');

            cy.get(SELECTOR_IMPORT_LIST_TABLE).should('exist').should('be.visible');

            cy.get(SELECTOR_IMPORT_MODAL_DESTINATION_START)
              .should('exist')
              .should('be.visible')
              .should('not.be.disabled');

            const importCount = availableImportsCount(user.destinations);

            for (let i = 0; i < importCount; i++) {
              for (const action of LIST_TABLE_ACTIONS) {
                cy.get(getSelectorImportListTableAction(i, action))
                  .should('exist')
                  .should('be.visible');
              }
            }
          });
        });
      });
    });
  });
});
