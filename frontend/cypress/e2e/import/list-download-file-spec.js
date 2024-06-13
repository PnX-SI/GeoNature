import { USERS } from './constants/users';
import { VIEWPORTS } from './constants/common';

const timeoutWait = 1000;
const columnName = 'Fichier';
const fileName = 'valid_file_test_link_list_import_synthese.csv';
const jddId = 1002;
const destination = 'synthese';
const downloadsFolder = Cypress.config('downloadsFolder');

Cypress.Commands.add('deleteFileIfExist', (fileName, downloadFolder) => {
    const filePath = `${downloadFolder}/${fileName}`;
    cy.task('fileExists', filePath).then((exists) => {
        if (exists) {
            cy.task('deleteFile', filePath).then((result) => {
                expect(result.success).to.be.true;
                cy.log(`File ${fileName} deleted: ${result.success}`);
            });
        } else {
            cy.log(`File ${fileName} does not exist.`);
        }
    });
});

Cypress.Commands.add('deleteFile', (fileName, downloadFolder) => {
    const filePath = `${downloadFolder}/${fileName}`;
    cy.task('deleteFile', filePath);
});

Cypress.Commands.add('verifyDownload', (fileName, downloadFolder) => {
    const filePath = `${downloadFolder}/${fileName}`;

    // Check if the file exists and is not empty
    cy.readFile(filePath, 'binary', { timeout: 15000 }).should((fileContent) => {
        expect(fileContent).to.not.be.empty;
    });
});

Cypress.Commands.add('getCellValueByColumnName', (tableSelector, columnName, cellValue) => {
    cy.get(`${tableSelector} datatable-body-row`).each(($row, rowIndex) => {
        const cellSelector = `[data-qa="import-list-table-row-${rowIndex}-${columnName.replace(/\s+/g, '-').toLowerCase()}"]`;
        cy.wrap($row).find(cellSelector).then(($cell) => {
            if ($cell.text().trim() === cellValue) {
                cy.wrap($cell).find('a').should('exist').then(($link) => {
                    cy.wrap($link).as('targetLink');
                });
            }
        });
    });
});

describe('File Upload and POST Request Test', () => {
    VIEWPORTS.forEach((viewport) => {
        context(`viewport: ${viewport.width}x${viewport.height}`, () => {
            const user = USERS[0];
            context(`user: ${user.login.username}`, () => {
                beforeEach(() => {
                    cy.viewport(viewport.width, viewport.height);
                    cy.geonatureLogin(user.login.username, user.login.password);
                    cy.visitImport();
                });

                it('Uploads a file via POST request', () => {
                    const filePath = `import/synthese/${fileName}`; // Path relative to cypress/fixtures

                    // Load the file content
                    cy.fixture(filePath, 'binary').then((fileContent) => {
                        // Convert the binary file content to a Blob
                        const blob = Cypress.Blob.binaryStringToBlob(fileContent, 'application/octet-stream');

                        // Create a FormData object and append the file
                        const formData = new FormData();
                        formData.append('file', blob, fileName);

                        // Make the POST request
                        cy.request({
                            method: 'PUT',
                            url: `${Cypress.env('apiEndpoint')}import/${destination}/imports/${jddId}/upload`,
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

                it("Should download file in the folder", () => {
                    cy.log("File name: " + fileName);
                    cy.getCellValueByColumnName('[data-qa="import-list-table"]', columnName, fileName).then(() => {
                        //Delete file if exist before downdload it
                        cy.deleteFileIfExist(fileName, downloadsFolder);
                        cy.get('@targetLink').click();
                        cy.wait(timeoutWait);
                        // Verify the file has been downloaded
                        cy.verifyDownload(fileName, downloadsFolder).then(() => {
                            // Delete the file after verification
                            cy.deleteFile(fileName, downloadsFolder);
                        });
                    });
                });
            });
        });
    });
});
