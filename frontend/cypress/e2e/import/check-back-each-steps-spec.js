import { STEP_NAMES, getSelectorsForStep, SELECTORS_NAVIGATION } from './constants/selectors';
import { USERS } from './constants/users';
import { VIEWPORTS } from './constants/common';
import { FILES } from './constants/files';


function getURLStepImport(destination_label, id_import) {
    const baseUrl = Cypress.env('urlApplication');
    console.log(baseUrl)
    const urlStepsImport = {
        "step_1_upload": {
            "url": `${baseUrl}import/${destination_label}/process/${id_import}/upload`,
        },
        "step_2_decode_file": {
            "url": `${baseUrl}import/${destination_label}/process/${id_import}/decode`,
        },
        "step_3_fieldmapping": {
            "url": `${baseUrl}import/${destination_label}/process/${id_import}/fieldmapping`,
        },
        "step_4_contentmapping": {
            "url": `${baseUrl}import/${destination_label}/process/${id_import}/contentmapping`,
        },
        "step_5_import_data": {
            "url": `${baseUrl}import/${destination_label}/process/${id_import}/import`,
        }
    };

    return urlStepsImport;
}


// function findRowIndexByColumnValue(tableSelector, columnName, cellValue) {
//     cy.get(tableSelector).within(() => {
//         // Find the index of the column with the specified name
//         cy.get('datatable-header-cell')
//             .contains(columnName)
//             .invoke('index')
//             .then((columnIndex) => {
//                 console.log("columnIndex: " + columnIndex)
//                 // Iterate over each row and find the cell in the column with the specified index
//                 cy.get('datatable-body-row').each(($row, rowIndex) => {
//                     console.log("rowIndex: " + rowIndex)
//                     console.log("$row: ", $row)
//                     const cellSelector = `[data-qa="import-list-table-row-${rowIndex}-${columnName.replace(/\s+/g, '-').toLowerCase()}"]`;
//                     cy.wrap($row)
//                         .find( cellSelector)
//                         .invoke('text')
//                         .then((text) => {
//                             console.log("text: ", text)
//                             if (text.trim() === cellValue) {
//                                 // Return the row index
//                                 cy.wrap(rowIndex).as('rowIndex');
//                             }
//                         });
//                 });
//             });
//     });
// }

Cypress.Commands.add('getRowIndexByCellValue', (tableSelector, columnName, cellValue) => {
    cy.get(`${tableSelector} datatable-body-row`).each(($row, rowIndex) => {
        const cellSelector = `[data-qa="import-list-table-row-${rowIndex}-${columnName.replace(/\s+/g, '-').toLowerCase()}"]`;
        cy.wrap($row).find(cellSelector).then(($cell) => {
            if ($cell.text().trim() === cellValue) {
                cy.wrap(rowIndex).as('rowIndex');
            }
        });
    });
});


describe('Import Process Navigation', () => {
  VIEWPORTS.forEach((viewport) => {
    context(`viewport: ${viewport.width}x${viewport.height}`, () => {
      const user = USERS[0];
      const destination = 'Synthèse';
      const destination_url = 'synthese';
      const stepUpload = 'upload';
      const timeoutWait = 1000;
      const selectorNavigationGeneral = SELECTORS_NAVIGATION.general;
      before(() => {
            cy.viewport(viewport.width, viewport.height);
            cy.geonatureLogin(user.login.username, user.login.password);
            cy.visitImport();
            cy.wait(timeoutWait);
            cy.startImport();
            cy.pickDestination(destination);
    
            // STEP 1 - UPLOAD
            cy.pickDataset(user.dataset);
          
            cy.log(Cypress.env('apiEndpoint') + `/import/${destination_url}/imports/${stepUpload}`)

            cy.loadImportFile(FILES.synthese.valid.fixture);
            // Get the current URL
            cy.wait(timeoutWait);
            cy.url().then(url => {
                // Log the current URL
                cy.log('Current URL:', url);
                // Extract the ID using string manipulation
                const parts = url.split('/');
                const id = parts[parts.length - 2]; // Get the penultimate element
                // Log the extracted ID
                cy.log('Extracted ID:', id);
                // Save the ID as a Cypress variable
                cy.wrap(id).as('newImportID');
            });
            cy.visitImport()
            // cy.get(selectorNavigationGeneral.save_and_quit_btn_selector).should('be.visible').click();
        });


        it(`should navigate correctly from step ${STEP_NAMES[0]} to step ${STEP_NAMES[1]} and save fields content`, function() {
            // Wait for the alias to be available
            cy.get('@newImportID').then((importID) => {    
                // Define selectors and URLs using the newImportID
                const selectorNavigationStepUpload = getSelectorsForStep(STEP_NAMES[0]);
                const selectorNavigationStepFile = getSelectorsForStep(STEP_NAMES[1]);
                const urlStepsImport = getURLStepImport(destination_url, importID);
                const tableSelector = '[data-qa=import-list-table]';
                const columnName = 'Id Import';
                cy.log("urlStepsImport",urlStepsImport["step_2_decode_file"].url);
                // Call the command to find the row index
                cy.getRowIndexByCellValue(tableSelector, columnName, importID);
                // Perform the navigation and checks

                cy.get('@rowIndex').then((RowIndex) => {
                    // Perform actions with the found row index
                   cy.get(`[data-qa="import-list-table-row-${RowIndex}-actions-edit"]`).should('be.enabled').click();
                });
                cy.wait(timeoutWait);
                cy.get(selectorNavigationStepFile.back_btn_selector).should('be.visible').click();
                cy.wait(timeoutWait);
                cy.url().should('eq', urlStepsImport.step_1_upload.url);
    

                // Use the row index alias for further actions or assertions
                cy.get(selectorNavigationStepUpload.next_btn_selector).should('be.enabled').click();
                cy.get(selectorNavigationGeneral.save_and_quit_btn_selector).should('be.visible').click();
                cy.get('@rowIndex').then((rowIndex) => {
                    cy.log('Row index:', rowIndex);
                    expect(rowIndex).to.not.be.null;
                });
                // Delete file by using 
                cy.visit(urlStepsImport.step_2_decode_file.url);
                cy.get(selectorNavigationGeneral.cancel_and_delete_import_btn_selector).should('be.visible').click();
                cy.url().should('eq', Cypress.env('urlApplication') + "import");
            });
        });

    

        // it(`should navigate correctly from step ${STEP_NAMES[1]} to step ${STEP_NAMES[2]}`, () => {
        //     const selectors = getSelectorsForStep(STEP_NAMES[0]);
        //     const selectorNavigationGeneral = SELECTORS_NAVIGATION.general;
        //     const urlStepsImport = getURLStepImport(destination, '@newImportID');
        //   cy.get(selectors.next_btn_selector).click();
        //   cy.url().should('eq', urlStepsImport.step_2_decode_file.url);
        // });

        // STEP_NAMES.forEach((stepName) => {
        //   it(`should navigate correctly for the ${stepName} step`, () => {
        //     const selectors = getSelectorsForStep(stepName);

        //     // Example usage of the selectors
        //     if (selectors.back_btn_selector) {
        //       cy.get(selectors.back_btn_selector).should('be.visible');
        //     }
        //     if (selectors.step_btn_selector) {
        //       cy.get(selectors.step_btn_selector).should('be.visible');
        //     }
        //     if (selectors.next_btn_selector) {
        //       cy.get(selectors.next_btn_selector).should('be.visible');
        //     }
        //   });
        // });
        // afterEach(() => {
        //   cy.deleteCurrentImport();
        // });
      });
    });
  });
