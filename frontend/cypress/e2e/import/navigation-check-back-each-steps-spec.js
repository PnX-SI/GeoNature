import {
  STEP_NAMES,
  getSelectorsForStep,
  SELECTORS_NAVIGATION,
  SELECTOR_IMPORT_LIST_TABLE,
  getSelectorImportListTableRowEdit,
  getSelectorImportListTableRowDelete,
  SELECTOR_IMPORT_MODAL_DELETE_VALIDATE,
} from './constants/selectors';
import { USERS } from './constants/users';
import { TIMEOUT_WAIT, VIEWPORTS } from './constants/common';

import {
  FIELDS_CONTENT_STEP_UPLOAD,
  FIELDS_CONTENT_STEP_FILE_DECODE,
} from './constants/fieldsContent';

// ////////////////////////////////////////////////////////////////////////////
//
// ////////////////////////////////////////////////////////////////////////////

function getURLStepImport(destination_label, id_import) {
  const baseUrl = Cypress.env('urlApplication');
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

// ////////////////////////////////////////////////////////////////////////////
//
// ////////////////////////////////////////////////////////////////////////////

describe('Import Process Navigation', () => {
  VIEWPORTS.forEach((viewport) => {
    context(`viewport: ${viewport.width}x${viewport.height}`, () => {
      const user = USERS[0];
      const DESTINATION = 'Synthèse';
      const DESTINATION_URL = 'synthese';
      const COLUMN_NAME = 'Id Import';
      const SELECTOR_NAVIGATION_GENERAL = SELECTORS_NAVIGATION.general;
      const SELECTOR_NAVIGATION_STEP_UPLOAD = getSelectorsForStep(STEP_NAMES[0]);
      const SELECTOR_NAVIGATION_STEP_DECODE_FILE = getSelectorsForStep(STEP_NAMES[1]);
      const SELECTOR_NAVIGATION_STEP_FIELDMAPPING = getSelectorsForStep(STEP_NAMES[2]);
      let importID; // Declare importID variable
      //   const selectorNavigationStepContentMapping = getSelectorsForStep(STEP_NAMES[3]);
      //   const selectorNavigationStepImportData = getSelectorsForStep(STEP_NAMES[4]);
      before(() => {
        cy.viewport(viewport.width, viewport.height);
        cy.geonatureLogin(user.login.username, user.login.password);
        cy.visitImport();
        cy.wait(TIMEOUT_WAIT);
        cy.startImport();
        cy.pickDestination(DESTINATION);

        // STEP 1 - UPLOAD
        cy.loadImportFile(FIELDS_CONTENT_STEP_UPLOAD.fileUploadField.defaultValue);
        cy.wait(TIMEOUT_WAIT);
        cy.url().then((url) => {
          // Extract the ID using string manipulation
          const parts = url.split('/');
          const id = parts[parts.length - 2]; // Get the penultimate element
          // Log the extracted ID
          importID = id;
        });
        cy.visitImport();
      });

      it(`should navigate correctly from step ${STEP_NAMES[0]} to step ${STEP_NAMES[1]} and save fields content`, function () {
        // Wait for the alias to be available
        cy.wrap(importID)
          .as('newImportID')
          .then((importID) => {
            // Define selectors and URLs using the newImportID
            const urlStepsImport = getURLStepImport(DESTINATION_URL, importID);
            cy.getRowIndexByCellValue(SELECTOR_IMPORT_LIST_TABLE, COLUMN_NAME, importID);
            // Navigation from list to upload by using Edit action
            cy.get('@rowIndex').then((rowIndex) => {
              cy.get(getSelectorImportListTableRowEdit(rowIndex)).should('be.enabled').click();
            });
            cy.wait(TIMEOUT_WAIT);
            // Should go on last step edited  --> decode file
            cy.url().should('eq', urlStepsImport.step_2_decode_file.url);

            //////////////////////////////////////////////////////////////////////////
            // Should contains the decode file form with default value
            cy.get(SELECTOR_NAVIGATION_STEP_DECODE_FILE.back_btn_selector)
              .should('be.visible')
              .click();
            cy.get(FIELDS_CONTENT_STEP_UPLOAD.fileUploadField.selector).then(($el) => {
              const expectedValue = $el
                .text()
                .trim()
                .replace(/\u00A0/g, ' ');
              const defaultValue = FIELDS_CONTENT_STEP_UPLOAD.fileUploadField.defaultValue.trim();
              expect(defaultValue).to.include(expectedValue);
            });
            // Change values in upload step
            cy.loadImportFile(FIELDS_CONTENT_STEP_UPLOAD.fileUploadField.newValue);
            cy.get(SELECTOR_NAVIGATION_STEP_DECODE_FILE.back_btn_selector)
              .should('be.visible')
              .click();

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
            cy.get(SELECTOR_NAVIGATION_STEP_UPLOAD.next_btn_selector).should('be.visible').click();
            cy.get(FIELDS_CONTENT_STEP_FILE_DECODE.sridField.selector).select(
              FIELDS_CONTENT_STEP_FILE_DECODE.sridField.defaultValue
            );
            cy.wait(TIMEOUT_WAIT);
            cy.get(SELECTOR_NAVIGATION_GENERAL.save_and_quit_btn_selector)
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
            const urlStepsImport = getURLStepImport(DESTINATION_URL, importID);
            cy.getRowIndexByCellValue(SELECTOR_IMPORT_LIST_TABLE, COLUMN_NAME, importID);
            // Navigation from list to upload by using Edit action
            cy.get('@rowIndex').then((rowIndex) => {
              cy.get(getSelectorImportListTableRowEdit(rowIndex)).should('be.enabled').click();
            });
            cy.wait(TIMEOUT_WAIT);
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
            cy.get(SELECTOR_NAVIGATION_STEP_DECODE_FILE.next_btn_selector)
              .should('be.visible')
              .click();
            cy.wait(TIMEOUT_WAIT);
            cy.get(SELECTOR_NAVIGATION_STEP_FIELDMAPPING.back_btn_selector)
              .scrollIntoView()
              .should('be.visible')
              .click();
            cy.wait(TIMEOUT_WAIT);

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

            cy.get(SELECTOR_NAVIGATION_STEP_DECODE_FILE.next_btn_selector)
              .should('be.visible')
              .click();
            cy.wait(TIMEOUT_WAIT);
            cy.get(SELECTOR_NAVIGATION_STEP_FIELDMAPPING.back_btn_selector)
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
            cy.getRowIndexByCellValue(SELECTOR_IMPORT_LIST_TABLE, COLUMN_NAME, importID);
            cy.get('@rowIndex').then((rowIndex) => {
              cy.get(getSelectorImportListTableRowDelete(rowIndex)).should('be.visible').click();
              cy.get(SELECTOR_IMPORT_MODAL_DELETE_VALIDATE).should('exist').click();
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
