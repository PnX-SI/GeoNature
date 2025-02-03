import { USERS } from './constants/users';
import { VIEWPORTS } from './constants/common';
import { SELECTOR_IMPORT } from './constants/selectors';

// ////////////////////////////////////////////////////////////////////////////
//
// ////////////////////////////////////////////////////////////////////////////

describe(`Should be able to acces the import module`, () => {
  VIEWPORTS.forEach((viewport) => {
    context(`viewport: ${viewport.width}x${viewport.height}`, () => {
      USERS.forEach((user) => {
        context(`user: ${user.login.username}`, () => {
          beforeEach(() => {
            cy.viewport(viewport.width, viewport.height);
            cy.geonatureLogin(user.login.username, user.login.password);
            cy.visit('/#');
          });

          it('Should switch to import page after a click on the button', () => {
            cy.get(SELECTOR_IMPORT).should('exist').click();
            cy.checkCurrentPageIsImport();
          });

          it('Should land directly to the import page', () => {
            cy.visitImport();
            cy.checkCurrentPageIsImport();
          });

          it('Should be able to visit synthese upload', () => {
            cy.visit('/#/import/synthese/process/upload');
          });

          it('Should not be able to visit bad-destination upload', () => {
            cy.visit('/#/import/bad-destination/process/upload');
            cy.checkCurrentPageIsImport();
          });
        });
      });
    });
  });
});
