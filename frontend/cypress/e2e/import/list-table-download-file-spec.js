import { USERS } from './constants/users';
import { TIMEOUT_WAIT, VIEWPORTS } from './constants/common';
import {
  getSelectorImportListTableRowFile,
  SELECTOR_IMPORT_LIST_TABLE,
} from './constants/selectors';

// ////////////////////////////////////////////////////////////////////////////
//
// ////////////////////////////////////////////////////////////////////////////

const USER = USERS[0];
const DESTINATION_CODE = USER.destinations.Synthèse.code;

const DOWNLOADS_FOLDER = Cypress.config('downloadsFolder');
const FILENAME = 'valid_file_test_link_list_import_synthese.csv';
const FILEPATH = `import/${DESTINATION_CODE}/${FILENAME}`; // Path relative to cypress/fixtures
const JDD_ID = 1002;

// ////////////////////////////////////////////////////////////////////////////
//
// ////////////////////////////////////////////////////////////////////////////

describe('File Upload and POST Request Test', () => {
  VIEWPORTS.forEach((viewport) => {
    context(`viewport: ${viewport.width}x${viewport.height}`, () => {
      context(`user: ${USER.login.username}`, () => {
        beforeEach(() => {
          cy.viewport(viewport.width, viewport.height);
          cy.geonatureLogin(USER.login.username, USER.login.password);
          cy.visitImport();
        });

        it('Uploads a file via POST request', () => {
          // Load the file content
          cy.fixture(FILEPATH, 'binary').then((fileContent) => {
            // Convert the binary file content to a Blob
            const blob = Cypress.Blob.binaryStringToBlob(fileContent, 'application/octet-stream');

            // Create a FormData object and append the file
            const formData = new FormData();
            formData.append('file', blob, FILENAME);

            // Make the POST request
            cy.request({
              method: 'PUT',
              url: `${Cypress.env(
                'apiEndpoint'
              )}import/${DESTINATION_CODE}/imports/${JDD_ID}/upload`,
              body: formData,
              headers: {
                'Content-Type': 'multipart/form-data',
              },
            }).then((response) => {
              // Assert the response status or body
              expect(response.status).to.equal(200);
            });
          });
        });

        it('Should download file in the folder', () => {
          cy.getRowIndexByCellValue(SELECTOR_IMPORT_LIST_TABLE, 'Id Import', `${JDD_ID}`).then(
            (rowIndex) => {
              //Delete file if exist before downdload it
              cy.deleteFileIfExist(FILENAME, DOWNLOADS_FOLDER);
              cy.get(getSelectorImportListTableRowFile(rowIndex)).click();
              cy.wait(TIMEOUT_WAIT);
              // Verify the file has been downloaded
              cy.verifyDownload(FILENAME, DOWNLOADS_FOLDER).then(() => {
                // Delete the file after verification
                cy.deleteFile(FILENAME, DOWNLOADS_FOLDER);
              });
            }
          );
        });
      });
    });
  });
});
