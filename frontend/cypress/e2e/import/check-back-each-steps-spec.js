import { STEP_NAMES, getSelectorsForStep, SELECTORS_NAVIGATION } from './constants/selectors';
import { USERS } from './constants/users';
import { VIEWPORTS } from './constants/common';
import { FILES } from './constants/files';


function getURLStepImport(destination_label, id_import) {
    const baseUrl = Cypress.env('urlApplication');
    console.log(baseUrl)
    const urlStepsImport = {
        "step_1_upload": {
            "url": `${baseUrl}import/${destination_label}/process/upload`,
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


function findRowIndexByColumnValue(tableSelector, columnName, cellValue) {
    cy.get(tableSelector).within(() => {
        // Find the index of the column with the specified name
        cy.get('datatable-header-cell')
            .contains(columnName)
            .invoke('index')
            .then((columnIndex) => {
                // Iterate over each row and find the cell in the column with the specified index
                cy.get('datatable-body-row').each(($row, rowIndex) => {
                    cy.wrap($row)
                        .find(`datatable-body-cell:nth-child(${columnIndex + 1})`)
                        .invoke('text')
                        .then((text) => {
                            if (text.trim() === cellValue) {
                                // Return the row index
                                cy.wrap(rowIndex).as('rowIndex');
                            }
                        });
                });
            });
    });
}


describe('Import Process Navigation', () => {
  VIEWPORTS.forEach((viewport) => {
    context(`viewport: ${viewport.width}x${viewport.height}`, () => {
      const user = USERS[0];
      const destination = 'Synthèse';
      const destination_url = 'synthese';
      const stepUpload = 'upload';
      const timeoutWait = 1000;
    //   context(`user: ${user.login.username}`, () => {
    //     beforeEach(() => {
    //       cy.viewport(viewport.width, viewport.height);
    //       cy.geonatureLogin(user.login.username, user.login.password);
    //       cy.visitImport();
    //     });
        before(() => {
            cy.viewport(viewport.width, viewport.height);
            cy.geonatureLogin(user.login.username, user.login.password);
            cy.visitImport();
            cy.wait(timeoutWait);
            cy.startImport();
            cy.pickDestination(destination);
    
            // STEP 1 - UPLOAD
            cy.pickDataset(user.dataset);
            // Intercept the POST request http://127.0.0.1:8000/import/synthese/imports/upload
            cy.log(Cypress.env('apiEndpoint') + `/import/${destination_url}/imports/${stepUpload}`)
            // cy.intercept(
            //     'POST',
            //     Cypress.env('apiEndpoint') + `/import/${destination_url}/imports/${stepUpload}`
            // ).as('validateUpload');
            cy.loadImportFile(FILES.synthese.valid.fixture);
            // Wait for the intercepted request and then extract the id
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
        });


        it(`should navigate correctly from step ${STEP_NAMES[0]} to step ${STEP_NAMES[1]} and save fields content`, function() {
            // Wait for the alias to be available
            cy.get('@newImportID').then((importID) => {    
                // Define selectors and URLs using the newImportID
                const selectors = getSelectorsForStep(STEP_NAMES[0]);
                cy.log("selectors",selectors);
                const selectorNavigationGeneral = SELECTORS_NAVIGATION.general;
                const urlStepsImport = getURLStepImport(destination_url, importID);
                cy.log("urlStepsImport",urlStepsImport["step_2_decode_file"].url);
                // Perform the navigation and checks
                cy.url().should('eq', urlStepsImport.step_2_decode_file.url);
                cy.visitImport();
    
                // Check fields upload are all filled
                // cy.get(selectorNavigationGeneral.save_and_quit_btn_selector).should('be.visible').click();
    
                // Check if the import ID exists in the table
                const tableSelector = '[data-qa=import-list-table]';
                const columnName = 'Id Import';

                // Call the function to find the row index
                findRowIndexByColumnValue(tableSelector, columnName, importID);

                // Use the row index alias for further actions or assertions
                cy.get('@rowIndex').then((rowIndex) => {
                    cy.log('Row index:', rowIndex);
                    expect(rowIndex).to.not.be.null; // Adjust based on your test requirements
                });
                // cy.checkCellValueExistsInColumn(tableSelector, columnName, importID).then((cellValueExists) => {
                //     if (cellValueExists) {
                //         cy.log('The cell value exists in the specified column');
                //     } else {
                //         cy.log('The cell value does not exist in the specified column');
                //     }
                //     expect(cellValueExists).to.be.true; // Adjust assertion as needed
                // });
    
                // Use the result in your test
                // cy.get('@cellValueExists').then((exists) => {
                //     if (cellValueExists) {
                //         cy.log('The cell value exists in the specified column');
                //     } else {
                //         cy.log('The cell value does not exist in the specified column');
                //     }
                //     expect(cellValueExists).to.be.true; // Adjust assertion as needed
                // });
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
