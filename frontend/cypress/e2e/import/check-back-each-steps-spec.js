import { STEP_NAMES, getSelectorsForStep, SELECTORS_NAVIGATION } from './constants/selectors';
import { USERS } from './constants/users';
import { VIEWPORTS } from './constants/common';
import { FILES } from './constants/files';
import {
  FIELDS_CONTENT_STEP_UPLOAD,
  FIELDS_CONTENT_STEP_FILE_DECODE,
} from './constants/fieldsContent';

function getURLStepImport(destination_label, id_import) {
  const baseUrl = Cypress.env('urlApplication');
  console.log(baseUrl);
  const urlStepsImport = {
    step_1_upload: {
      url: `${baseUrl}import/${destination_label}/process/${id_import}/upload`,
    },
    step_2_decode_file: {
      url: `${baseUrl}import/${destination_label}/process/${id_import}/decode`,
    },
    step_3_fieldmapping: {
      url: `${baseUrl}import/${destination_label}/process/${id_import}/fieldmapping`,
    },
    step_4_contentmapping: {
      url: `${baseUrl}import/${destination_label}/process/${id_import}/contentmapping`,
    },
    step_5_import_data: {
      url: `${baseUrl}import/${destination_label}/process/${id_import}/import`,
    },
  };

  return urlStepsImport;
}

Cypress.Commands.add('getRowIndexByCellValue', (tableSelector, columnName, cellValue) => {
  cy.get(`${tableSelector} datatable-body-row`).each(($row, rowIndex) => {
    const cellSelector = `[data-qa="import-list-table-row-${rowIndex}-${columnName
      .replace(/\s+/g, '-')
      .toLowerCase()}"]`;
    cy.wrap($row)
      .find(cellSelector)
      .then(($cell) => {
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
      const timeoutWait = 1000;
      const tableSelector = '[data-qa=import-list-table]';
      const columnName = 'Id Import';
      const selectorNavigationGeneral = SELECTORS_NAVIGATION.general;
      const selectorNavigationStepUpload = getSelectorsForStep(STEP_NAMES[0]);
      const selectorNavigationStepDecodeFile = getSelectorsForStep(STEP_NAMES[1]);
      const selectorNavigationStepFieldMapping = getSelectorsForStep(STEP_NAMES[2]);
      let importID; // Declare importID variable
      //   const selectorNavigationStepContentMapping = getSelectorsForStep(STEP_NAMES[3]);
      //   const selectorNavigationStepImportData = getSelectorsForStep(STEP_NAMES[4]);
      before(() => {
        cy.viewport(viewport.width, viewport.height);
        cy.geonatureLogin(user.login.username, user.login.password);
        cy.visitImport();
        cy.wait(timeoutWait);
        cy.startImport();
        cy.pickDestination(destination);

        // STEP 1 - UPLOAD
        cy.pickDataset(FIELDS_CONTENT_STEP_UPLOAD.datasetField.defaultValue);
        cy.loadImportFile(FIELDS_CONTENT_STEP_UPLOAD.fileUploadField.defaultValue);
        cy.wait(timeoutWait);
        cy.url().then((url) => {
          // Log the current URL
          cy.log('Current URL:', url);
          // Extract the ID using string manipulation
          const parts = url.split('/');
          const id = parts[parts.length - 2]; // Get the penultimate element
          // Log the extracted ID
          importID = id;
          cy.log('Extracted ID:', id);
          // Save the ID as a Cypress variable
          // cy.wrap(id).as('newImportID');
        });
        cy.visitImport();
      });

      it(`should navigate correctly from step ${STEP_NAMES[0]} to step ${STEP_NAMES[1]} and save fields content`, function () {
        // Wait for the alias to be available
        cy.wrap(importID)
          .as('newImportID')
          .then((importID) => {
            // Define selectors and URLs using the newImportID
            const urlStepsImport = getURLStepImport(destination_url, importID);
            cy.getRowIndexByCellValue(tableSelector, columnName, importID);
            // Navigation from list to upload by using Edit action
            cy.get('@rowIndex').then((rowIndex) => {
              cy.get(`[data-qa="import-list-table-row-${rowIndex}-actions-edit"]`)
                .should('be.enabled')
                .click();
            });
            cy.wait(timeoutWait);
            // Should go on last step edited  --> decode file
            cy.url().should('eq', urlStepsImport.step_2_decode_file.url);

            //////////////////////////////////////////////////////////////////////////
            // Should contains the decode file form with default value
            cy.get(selectorNavigationStepDecodeFile.back_btn_selector).should('be.visible').click();
            // Verify the selected value in the ng-select input
            cy.get(FIELDS_CONTENT_STEP_UPLOAD.datasetField.selector).within(() => {
              cy.get('.ng-value').should(
                'contain.text',
                FIELDS_CONTENT_STEP_UPLOAD.datasetField.defaultValue
              );
            });
            cy.get(FIELDS_CONTENT_STEP_UPLOAD.fileUploadField.selector).then(($el) => {
              const expectedValue = $el
                .text()
                .trim()
                .replace(/\u00A0/g, ' ');
              const defaultValue = FIELDS_CONTENT_STEP_UPLOAD.fileUploadField.defaultValue.trim();
              expect(defaultValue).to.include(expectedValue);
            });
            // Change values in upload step
            cy.pickDataset(FIELDS_CONTENT_STEP_UPLOAD.datasetField.newValue);
            cy.loadImportFile(FIELDS_CONTENT_STEP_UPLOAD.fileUploadField.newValue);
            cy.get(selectorNavigationStepDecodeFile.back_btn_selector).should('be.visible').click();

            /////////// NOTES: not working (jdd is not saved if changed)
            // cy.get(FIELDS_CONTENT_STEP_UPLOAD.datasetField.selector).within(() => {
            // cy.get('.ng-value').should('contain.text', FIELDS_CONTENT_STEP_UPLOAD.datasetField.newValue);
            // });

            cy.get(FIELDS_CONTENT_STEP_UPLOAD.fileUploadField.selector).then(($el) => {
              const expectedValue = $el
                .text()
                .trim()
                .replace(/\u00A0/g, ' ');
              const newValue = FIELDS_CONTENT_STEP_UPLOAD.fileUploadField.newValue.trim();
              expect(newValue).to.include(expectedValue);
            });

            // Finalize step 2 (decode file and configuration)
            cy.get(selectorNavigationStepUpload.next_btn_selector).should('be.visible').click();
            cy.get(FIELDS_CONTENT_STEP_FILE_DECODE.sridField.selector).select(
              FIELDS_CONTENT_STEP_FILE_DECODE.sridField.defaultValue
            );
            cy.wait(timeoutWait);
            cy.get(selectorNavigationGeneral.save_and_quit_btn_selector)
              .should('be.visible')
              .click();
            cy.visitImport();

            // cy.get(selectorNavigationGeneral.save_and_quit_btn_selector).should('be.visible').click();
            // cy.url().should('eq', Cypress.env('urlApplication') + "import");
            // cy.get('@rowIndex').then((rowIndex) => {
            //     cy.log('Row index:', rowIndex);
            //     expect(rowIndex).to.not.be.null;
            // });
          });
      });

      it(`should navigate correctly from step ${STEP_NAMES[1]} to step ${STEP_NAMES[2]} and save fields content`, function () {
        cy.viewport(viewport.width, viewport.height);
        cy.geonatureLogin(user.login.username, user.login.password);
        cy.visitImport();
        cy.wrap(importID)
          .as('newImportID')
          .then((importID) => {
            const urlStepsImport = getURLStepImport(destination_url, importID);
            cy.getRowIndexByCellValue(tableSelector, columnName, importID);
            // Navigation from list to upload by using Edit action
            cy.get('@rowIndex').then((rowIndex) => {
              cy.get(`[data-qa="import-list-table-row-${rowIndex}-actions-edit"]`)
                .should('be.enabled')
                .click();
            });
            cy.wait(timeoutWait);
            // Should go on last step edited  --> decode file
            cy.url().should('eq', urlStepsImport.step_2_decode_file.url);

            //////////////////////////////////////////////////////////////////////////
            // Should contains the decode file form with default value
            // Verify the selected value in the ng-select input
            cy.get(FIELDS_CONTENT_STEP_FILE_DECODE.delimiterField.selector).then(($select) => {
              const selectedValue = $select.find(':selected').text().trim();
              expect(selectedValue).to.equal(
                FIELDS_CONTENT_STEP_FILE_DECODE.delimiterField.defaultValue
              );
            });
            cy.get(FIELDS_CONTENT_STEP_FILE_DECODE.encodeField.selector).then(($select) => {
              const selectedValue = $select.find(':selected').text().trim();
              expect(selectedValue).to.equal(
                FIELDS_CONTENT_STEP_FILE_DECODE.encodeField.defaultValue
              );
            });
            cy.get(FIELDS_CONTENT_STEP_FILE_DECODE.formatField.selector).then(($select) => {
              const selectedValue = $select.find(':selected').text().trim();
              expect(selectedValue).to.equal(
                FIELDS_CONTENT_STEP_FILE_DECODE.formatField.defaultValue
              );
            });
            cy.get(FIELDS_CONTENT_STEP_FILE_DECODE.sridField.selector).then(($select) => {
              const selectedValue = $select.find(':selected').text().trim();
              expect(selectedValue).to.equal(
                FIELDS_CONTENT_STEP_FILE_DECODE.sridField.defaultValue
              );
            });
            // Change values in decode step
            cy.get(selectorNavigationStepDecodeFile.next_btn_selector).should('be.visible').click();
            cy.wait(timeoutWait);
            cy.get(selectorNavigationStepFieldMapping.back_btn_selector)
              .scrollIntoView()
              .should('be.visible')
              .click();
            cy.wait(timeoutWait);

            cy.get(FIELDS_CONTENT_STEP_FILE_DECODE.sridField.selector).select(
              FIELDS_CONTENT_STEP_FILE_DECODE.sridField.newValue
            );
            cy.get(FIELDS_CONTENT_STEP_FILE_DECODE.formatField.selector).select(
              FIELDS_CONTENT_STEP_FILE_DECODE.formatField.newValue
            );
            cy.get(FIELDS_CONTENT_STEP_FILE_DECODE.encodeField.selector).select(
              FIELDS_CONTENT_STEP_FILE_DECODE.encodeField.newValue
            );
            cy.get(FIELDS_CONTENT_STEP_FILE_DECODE.delimiterField.selector).select(
              FIELDS_CONTENT_STEP_FILE_DECODE.delimiterField.newValue
            );

            cy.get(selectorNavigationStepDecodeFile.next_btn_selector).should('be.visible').click();
            cy.wait(timeoutWait);
            cy.get(selectorNavigationStepFieldMapping.back_btn_selector)
              .scrollIntoView()
              .should('be.visible')
              .click();
            //////////////////////////////////////////////////////////////////////////
            // Should contains the decode file form with new value
            cy.get(FIELDS_CONTENT_STEP_FILE_DECODE.delimiterField.selector).then(($select) => {
              const selectedValue = $select.find(':selected').text().trim();
              expect(selectedValue).to.equal(
                FIELDS_CONTENT_STEP_FILE_DECODE.delimiterField.newValue
              );
            });
            cy.get(FIELDS_CONTENT_STEP_FILE_DECODE.encodeField.selector).then(($select) => {
              const selectedValue = $select.find(':selected').text().trim();
              expect(selectedValue).to.equal(FIELDS_CONTENT_STEP_FILE_DECODE.encodeField.newValue);
            });
            cy.get(FIELDS_CONTENT_STEP_FILE_DECODE.formatField.selector).then(($select) => {
              const selectedValue = $select.find(':selected').text().trim();
              expect(selectedValue).to.equal(FIELDS_CONTENT_STEP_FILE_DECODE.formatField.newValue);
            });
            cy.get(FIELDS_CONTENT_STEP_FILE_DECODE.sridField.selector).then(($select) => {
              const selectedValue = $select.find(':selected').text().trim();
              expect(selectedValue).to.equal(FIELDS_CONTENT_STEP_FILE_DECODE.sridField.newValue);
            });
            cy.visitImport();
          });
      });

      after(() => {
        cy.wrap(importID)
          .as('newImportID')
          .then((importID) => {
            cy.visitImport();
            cy.getRowIndexByCellValue(tableSelector, columnName, importID);
            cy.get('@rowIndex').then((rowIndex) => {
              cy.get(`[data-qa="import-list-table-row-${rowIndex}-actions-delete"]`)
                .should('be.visible')
                .click();
              cy.get('[data-qa="modal-delete-validate"]').should('exist').click();
            });
          });
        // Delete file by using
        // cy.visit(urlStepsImport.step_2_decode_file.url);
        // cy.get(selectorNavigationGeneral.cancel_and_delete_import_btn_selector).should('be.visible').click();
        // cy.url().should('eq', Cypress.env('urlApplication') + "import");
      });
    });
  });
});
