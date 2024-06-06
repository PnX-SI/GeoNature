import { USERS, availableImportsCount } from "./constants/users";
import { VIEWPORTS } from "./constants/common"

// ////////////////////////////////////////////////////////////////////////////
//
// ////////////////////////////////////////////////////////////////////////////

describe("Import List - Toolbar - Destinations", () => {
  VIEWPORTS.forEach((viewport) => {
    context(`viewport: ${viewport.width}x${viewport.height}`, () => {
      USERS.forEach((user) => {
        context(`user: ${user.login.username}`, () => {

          beforeEach(() => {
            cy.viewport(viewport.width, viewport.height);
            cy.geonatureLogin(user.login.username, user.login.password);
            cy.visitImport();
          })

          it('Should have a correct import list setup', () => {
            cy.get('[data-qa="import-list"]')
              .should('exist')
              .should('be.visible');

            cy.get('[data-qa="import-list-toolbar-destinations"]')
              .should('exist')
              .should('be.visible')
              .should('not.be.disabled');

            cy.get('[data-qa="import-list-toolbar-search"]')
              .should('exist')
              .should('be.visible')
              .should('not.be.disabled');

            cy.get('[data-qa="import-list-table"]')
              .should('exist')
              .should('be.visible');

            cy.get('[data-qa="import-modal-destination-start"]')
              .should('exist')
              .should('be.visible')
              .should('not.be.disabled');

            const importCount = availableImportsCount(user.destinations);
            const actions = ["edit", "report", "csv", "delete"];
            for (let i = 0; i < importCount; i++){
              for (const action of actions) {
                cy.get(`[data-qa="import-list-table-row-${i}-actions-${action}"]`)
                  .should('exist')
                  .should('be.visible');
              }
            }
          })
        });
      });
    });
  });
});
