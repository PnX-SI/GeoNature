import { USERS } from './constants/users';
import { VIEWPORTS } from './constants/common';
import {
  SELECTOR_IMPORT_RECAPITULATIF,
  SELECTOR_IMPORT_RECAPITULATIF_MAP,
} from './constants/selectors';

// ////////////////////////////////////////////////////////////////////////////
// Create a mapping with dummy values
// ////////////////////////////////////////////////////////////////////////////

const USER_ADMIN = USERS[0];
const VIEWPORT = VIEWPORTS[0];

function runTheProcess(user) {
  cy.setupImportViaApi('import', { datasetName: user.dataset }).as('currentImportId');
}

// ////////////////////////////////////////////////////////////////////////////
// Create a mapping with dummy values
// ////////////////////////////////////////////////////////////////////////////

describe('Import - Recapitulatif step', () => {
  context(`viewport: ${VIEWPORT.width}x${VIEWPORT.height}`, () => {
    beforeEach(() => {
      cy.viewport(VIEWPORT.width, VIEWPORT.height);
      cy.geonatureLogin(USER_ADMIN.login.username, USER_ADMIN.login.password);
      runTheProcess(USER_ADMIN);
    });

    it('should contains all the mains elements', () => {
      cy.get(SELECTOR_IMPORT_RECAPITULATIF).should('exist');
      cy.get(SELECTOR_IMPORT_RECAPITULATIF_MAP).should('exist');
    });

    afterEach(() => {
      cy.get('@currentImportId').then((importId) => {
        cy.deleteImport(importId, 'synthese');
      });
    });
  });
});
