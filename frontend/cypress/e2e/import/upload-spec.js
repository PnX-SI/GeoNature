import { USERS } from "./constants/users";
import { VIEWPORTS } from "./constants/common"
import { FILES } from "./constants/files";

// ////////////////////////////////////////////////////////////////////////////
//
// ////////////////////////////////////////////////////////////////////////////

describe("Import - Upload step", () => {
  const viewport = VIEWPORTS[0];
  const user = USERS[0];
  context(`viewport: ${viewport.width}x${viewport.height}`, () => {
    beforeEach(() => {
      cy.viewport(viewport.width, viewport.height);
      cy.geonatureLogin(user.login.username, user.login.password);
      cy.visitImport();
      cy.startImport();
      cy.pickDestination();
      cy.get('[data-qa="import-new-upload-validate"]').should('exist').should("be.disabled");
    });

    it("Should throw error if file is empty", () => {
      const file = FILES.synthese.empty
      cy.get(file.formErrorElement).should('not.exist')
      cy.loadImportFile(file.fixture);
      cy.get(file.formErrorElement).should("be.visible");
      cy.hasToastError(file.toast);
    });

    it("Should throw error if csv is not valid", () => {
      const file = FILES.synthese.bad
      cy.get(file.formErrorElement).should('not.exist')
      cy.fixture(file.fixture, null).as('import_file')
      cy.get('[data-qa="import-new-upload-file"]').selectFile('@import_file');
      cy.contains(file.fixture.split(/(\\|\/)/g).pop());
      cy.get(file.formErrorElement).should("be.visible");
    });
    it.skip("Should throw error if input is not a valid extension", () => {
      const file = FILES.synthese.bad_extension
      cy.get(file.formErrorElement).should('not.exist')
      cy.fixture(file.fixture, null).as('import_file')
      cy.get('[data-qa="import-new-upload-file"]').selectFile('@import_file');
      cy.contains(file.fixture.split(/(\\|\/)/g).pop());
      cy.get(file.formErrorElement).should("be.visible");
    });

    afterEach(() => {
      cy.deleteCurrentImport();
    });
  });
});
