import { USERS } from "./constants/users";
import { VIEWPORTS } from "./constants/common"
import { FILES } from "./constants/files"

// ////////////////////////////////////////////////////////////////////////////
//
// ////////////////////////////////////////////////////////////////////////////

describe("Import - Field mapping step", () => {
  const viewport = VIEWPORTS[0];
  const user = USERS[1];
  context(`viewport: ${viewport.width}x${viewport.height}`, () => {
    beforeEach(() => {
      cy.viewport(viewport.width, viewport.height);
      cy.geonatureLogin(user.login.username, user.login.password);
      cy.visitImport();
      cy.startImport();
      cy.pickDestination();
      cy.pickDataset(user.dataset);
      cy.loadImportFile(FILES.synthese.valid.fixture);
      cy.configureImportFile();
    });

    it("Should be on the correct page", () => {
      cy.get('[data-qa="import-new-fieldmapping-form"]').should('exist');
    });

    afterEach(() => {
      cy.deleteCurrentImport();
    });
  });
});
