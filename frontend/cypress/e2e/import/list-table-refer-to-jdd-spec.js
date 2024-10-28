import { USERS } from './constants/users';
import { TIMEOUT_WAIT, VIEWPORTS } from './constants/common';
import { SELECTOR_IMPORT_LIST_TABLE } from './constants/selectors';

const COLUMN_NAME = 'Jeu de données';
const JDD_LIST = ['JDD-TEST-IMPORT-ADMIN', 'JDD-TEST-IMPORT-2', 'JDD-TEST-IMPORT-3'];

// ////////////////////////////////////////////////////////////////////////////
//
// ////////////////////////////////////////////////////////////////////////////

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

        JDD_LIST.forEach((cellValue) =>
          it('Should be redirected to page Metada dataset with dataset name: ' + cellValue, () => {
            cy.getCellValueByColumnName(SELECTOR_IMPORT_LIST_TABLE, COLUMN_NAME, cellValue).then(
              () => {
                cy.get('@targetLink').click();
                cy.wait(TIMEOUT_WAIT);
              }
            );
            cy.location().then((loc) => {
              cy.log('Current URL: ' + loc.href);
              expect(loc.href).to.include('metadata/dataset_detail/');
            });
          })
        );
      });
    });
  });
});
