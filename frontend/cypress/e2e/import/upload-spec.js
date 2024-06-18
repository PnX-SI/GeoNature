import { USERS } from "./constants/users";
import { VIEWPORTS } from "./constants/common"
import { FILES } from "./constants/files";

// ////////////////////////////////////////////////////////////////////////////
//
// ////////////////////////////////////////////////////////////////////////////

function pickDataset(datasetName) {
  cy.get('[data-qa="import-new-upload-datasets"]').should('exist').click()
    .get("ng-dropdown-panel")
    .get(".ng-option").contains(datasetName).then(dataset => {
      cy.wrap(dataset).should('exist').click();
    });
}
describe("Import - Upload step", () => {
  const viewport = VIEWPORTS[0];
  const user = USERS[1];
  context(`viewport: ${viewport.width}x${viewport.height}`, () => {
    beforeEach(() => {
      cy.viewport(viewport.width, viewport.height);
      cy.geonatureLogin(user.login.username, user.login.password);
      cy.visitImport();
      cy.startImport();
      cy.pickDestination();
      cy.get('[data-qa="import-new-upload-validate"]').should('exist').should("be.disabled");
    });

    it("Should be able to select a jdd", () => {
      pickDataset(user.dataset);
      cy.get('[data-qa="import-new-upload-datasets"] > ng-select')
        .should("have.class", "ng-valid")
        .find('.ng-value-label')
        .should('exist')
        .should("contains.text", user.dataset);

      cy.get('[data-qa="import-new-upload-datasets"]').find(".ng-clear-wrapper").should('exist').click();

      cy.get('[data-qa="import-new-upload-datasets"] > ng-select')
        .should("have.class", "ng-invalid")

      pickDataset(user.dataset);

      cy.get('[data-qa="import-new-upload-datasets"] > ng-select')
        .should("have.class", "ng-valid")
        .find('.ng-value-label')
        .should('exist')
        .should("contains.text", user.dataset);
    });

    it("Should access jdd only filtered based on permissions  ", () => {
      cy.get('[data-qa="import-new-upload-datasets"] > ng-select')
        .click()
        .get(".ng-option")
        .should('have.length', 1)
        .should('contain', user.dataset);

    });

    it("Should throw error if file is empty", () => {
      // required to trigger file validation
      pickDataset(user.dataset);
      const file = FILES.synthese.empty
      cy.get(file.formErrorElement).should('not.exist')
      cy.loadImportFile(file.fixture);
      cy.get(file.formErrorElement).should("be.visible");
      cy.hasToastError(file.toast);
    });

    it("Should throw error if csv is not valid", () => {
      // required to trigger file validation
      pickDataset(user.dataset);
      const file = FILES.synthese.bad;
      cy.get(file.formErrorElement).should('not.exist');
      cy.fixture(file.fixture, null).as('import_file');
      cy.get('[data-qa="import-new-upload-file"]').selectFile('@import_file');
      cy.contains(file.fixture.split(/(\\|\/)/g).pop());
      cy.get(file.formErrorElement).should("be.visible");
    });

    // Skipped ////////////////////////////////////////////////////////////////
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
