import { USERS } from './constants/users';
import { TIMEOUT_WAIT, VIEWPORTS } from './constants/common';
import { FILES } from './constants/files';
import {
  SELECTOR_IMPORT_REPORT,
  SELECTOR_IMPORT_REPORT_CHART,
  SELECTOR_IMPORT_REPORT_DOWNLOAD_PDF,
  SELECTOR_IMPORT_REPORT_ERRORS_CSV,
  SELECTOR_IMPORT_REPORT_ERRORS_TITLE,
  SELECTOR_IMPORT_REPORT_MAP,
} from './constants/selectors';

// ////////////////////////////////////////////////////////////////////////////
// Create a mapping with dummy values
// ////////////////////////////////////////////////////////////////////////////

const DOWNLOADS_FOLDER = Cypress.config('downloadsFolder');
const FILENAME_INVALID_DATA = 'invalid_data.csv';
const USER_ADMIN = USERS[0];
const VIEWPORT = VIEWPORTS[0];

function runTheProcess(user) {
  cy.visitImport();
  cy.startImport();
  cy.pickDestination();
  cy.pickDataset(user.dataset);
  cy.loadImportFile(FILES.synthese.valid.fixture);
  cy.configureImportFile();
  cy.configureImportFieldMapping();
  cy.configureImportContentMapping();
  cy.triggerImportVerification();
  cy.executeImport();
}

// ////////////////////////////////////////////////////////////////////////////
// Create a mapping with dummy values
// ////////////////////////////////////////////////////////////////////////////

describe('Import - Report step', () => {
  context(`viewport: ${VIEWPORT.width}x${VIEWPORT.height}`, () => {
    beforeEach(() => {
      cy.viewport(VIEWPORT.width, VIEWPORT.height);
      cy.geonatureLogin(USER_ADMIN.login.username, USER_ADMIN.login.password);
      runTheProcess(USER_ADMIN);
      cy.get(SELECTOR_IMPORT_REPORT).should('exist');
    });

    it('should contains the elements', () => {
      cy.get(SELECTOR_IMPORT_REPORT_MAP).should('exist');
      cy.get(SELECTOR_IMPORT_REPORT_CHART).should('exist').should('not.be.empty');
      cy.get(SELECTOR_IMPORT_REPORT_ERRORS_TITLE)
        .should('exist')
        .should('have.text', '2 erreur(s)');

      // Download a verify the error file
      cy.get(SELECTOR_IMPORT_REPORT_ERRORS_CSV).click({
        force: true,
      });
      cy.verifyDownload(FILENAME_INVALID_DATA, DOWNLOADS_FOLDER).then(() => {
        cy.fixture('import/synthese/invalid_data.csv').then((fixtureFileContent) => {
          cy.readFile(`${DOWNLOADS_FOLDER}/${FILENAME_INVALID_DATA}`).then(
            (downloadedFileContent) => {
              expect(downloadedFileContent).equals(fixtureFileContent);
            }
          );
        });
        // Delete the file after verification
        cy.deleteFile(FILENAME_INVALID_DATA, DOWNLOADS_FOLDER);
      });

      cy.url().then((url) => {
        // Extract the ID using string manipulation
        const parts = url.split('/');
        const importID = parts[parts.length - 2]; // Get the penultimate element
        const destination = parts[parts.length - 3];

        // PDF report
        cy.get(SELECTOR_IMPORT_REPORT_DOWNLOAD_PDF).click({
          force: true,
        });

        // https://github.com/cypress-io/cypress/issues/25443
        cy.intercept(
          {
            method: 'POST',
            url: `${Cypress.env('apiEndpoint')}/import/${destination}/export_pdf/${importID}`,
          },
          (req) => {
            cy.wait(TIMEOUT_WAIT);
            cy.task('getLastDownloadFileName', DOWNLOADS_FOLDER).then((filename) => {
              cy.verifyDownload(filename, DOWNLOADS_FOLDER);
              cy.deleteFile(filename, DOWNLOADS_FOLDER);
            });
          }
        );
      });
    });

    afterEach(() => {
      cy.url().then((url) => {
        // Extract the ID using string manipulation
        const parts = url.split('/');
        const importID = parts[parts.length - 2]; // Get the penultimate element
        const destination = parts[parts.length - 3];
        cy.deleteImport(importID, destination);
        cy.visitImport();
      });
    });
  });
});
