import { USERS } from './constants/users';
import { VIEWPORTS } from './constants/common';
import { FILES } from './constants/files';

// ////////////////////////////////////////////////////////////////////////////
//
// ////////////////////////////////////////////////////////////////////////////

const USER = USERS[0];
const VIEWPORT = VIEWPORTS[0];

// ////////////////////////////////////////////////////////////////////////////
//
// ////////////////////////////////////////////////////////////////////////////

describe('Import - create a new import', () => {
  beforeEach(() => {
    cy.viewport(VIEWPORT.width, VIEWPORT.height);
    cy.geonatureLogin(USER.login.username, USER.login.password);
    cy.visitImport();
  });

  it('Should be able to import a valid-file in synthese', () => {
    cy.startImport();
    cy.pickDestination();
    cy.pickDataset(USER.dataset);
    cy.loadImportFile(FILES.synthese.valid.fixture);
    cy.configureImportFile();
    cy.configureImportFieldMapping();
    cy.configureImportContentMapping();
    cy.verifyImport();
    cy.executeImport();
    cy.backToImportList();
    cy.removeFirstImportInList();
  });
});
