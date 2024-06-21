const SIDENAV_IMPORT_BUTTON_QA = "[data-qa=gn-sidenav-link-IMPORT]";

import { USERS } from "./constants/users";
import { VIEWPORTS } from "./constants/common";

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
            cy.get(SIDENAV_IMPORT_BUTTON_QA).should("exist").click();
            cy.checkCurrentPageIsImport();
          });

          it('Should land directly to the import page', () => {
            cy.visit('/#/import');
            cy.checkCurrentPageIsImport();
          });
        });
      });
    })
  });
});

