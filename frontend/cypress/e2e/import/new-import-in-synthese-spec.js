import { USERS } from "./constants/users";
import { VIEWPORTS } from "./constants/common"
import { FILES } from "./constants/files"

describe('Import - create a new import', () => {
  const viewport = VIEWPORTS[0];
  const user = USERS[0];
  beforeEach(() => {
    cy.viewport(viewport.width, viewport.height);
    cy.geonatureLogin(user.login.username, user.login.password);
    cy.visitImport();
  });

  it('Should be able to import a valid-file in synthese', () => {
    cy.startImport();
    cy.pickDestination();
    cy.pickDataset(user.dataset);
    cy.loadImportFile(FILES.synthese.valid.fixture);
    cy.configureImportFile();
    cy.configureImportFieldMapping();
    cy.configureImportContentMapping();
    cy.verifyImport();
    cy.executeImport();
    cy.backToImportList();
    cy.removeFirstImportInList();
  })
})
