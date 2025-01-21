import { USERS } from './constants/users';
import { VIEWPORTS } from './constants/common';
import { FILES } from './constants/files';
import {
  SELECTOR_IMPORT_UPLOAD_FILE,
  SELECTOR_IMPORT_UPLOAD_VALIDATE,
} from './constants/selectors';

// ////////////////////////////////////////////////////////////////////////////
//
// ////////////////////////////////////////////////////////////////////////////

const USER = USERS[1];
const VIEWPORT = VIEWPORTS[0];

// ////////////////////////////////////////////////////////////////////////////
//
// ////////////////////////////////////////////////////////////////////////////

describe('Import - Upload step', () => {
  context(`viewport: ${VIEWPORT.width}x${VIEWPORT.height}`, () => {
    beforeEach(() => {
      cy.viewport(VIEWPORT.width, VIEWPORT.height);
      cy.geonatureLogin(USER.login.username, USER.login.password);
      cy.visitImport();
      cy.startImport();
      cy.pickDestination();
      cy.get(SELECTOR_IMPORT_UPLOAD_VALIDATE).should('exist').should('be.disabled');
    });

    it('Should throw error if file is empty', () => {
      // required to trigger file validation
      const file = FILES.synthese.empty;
      cy.get(file.formErrorElement).should('not.exist');
      cy.loadImportFile(file.fixture);
      cy.get(file.formErrorElement).should('be.visible');
      cy.hasToastError(file.toast);
    });

    it('Should throw error if csv is not valid', () => {
      // required to trigger file validation
      const file = FILES.synthese.bad;
      cy.get(file.formErrorElement).should('not.exist');
      cy.fixture(file.fixture, null).as('import_file');
      cy.get(SELECTOR_IMPORT_UPLOAD_FILE).selectFile('@import_file');
      cy.contains(file.fixture.split(/(\\|\/)/g).pop());
      cy.get(file.formErrorElement).should('be.visible');
    });

    // Skipped ////////////////////////////////////////////////////////////////
    it.skip('Should throw error if input is not a valid extension', () => {
      const file = FILES.synthese.bad_extension;
      cy.get(file.formErrorElement).should('not.exist');
      cy.fixture(file.fixture, null).as('import_file');
      cy.get(SELECTOR_IMPORT_UPLOAD_FILE).selectFile('@import_file');
      cy.contains(file.fixture.split(/(\\|\/)/g).pop());
      cy.get(file.formErrorElement).should('be.visible');
    });
  });
});
