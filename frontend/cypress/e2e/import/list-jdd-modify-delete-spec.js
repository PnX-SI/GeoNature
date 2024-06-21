import { USERS } from './constants/users';
import { VIEWPORTS } from './constants/common';

const tableSelector = '[data-qa=import-list-table]';
const timeoutWait = 1000;

const columnName = 'Voir la fiche du JDD';
const JDD_LIST = [
    {
        'jdd_name': 'JDD-TEST-IMPORT-ADMIN',
        'jdd_is_active': true,
        'url_on_click_edit': Cypress.env('urlApplication') + 'import/occhab/process/1001',
    },
    {
        'jdd_name': 'JDD-TEST-IMPORT-INACTIF',
        'jdd_is_active': false,
        'url_on_click_edit': Cypress.env('urlApplication') + 'import',
    }
];

describe('Tests actions on active/inactive list JDD ', () => {
    VIEWPORTS.forEach(viewport => {
        context(`viewport: ${viewport.width}x${viewport.height}`, () => {
            const user = USERS[0];

            context(`user: ${user.login.username}`, () => {
                beforeEach(() => {
                    cy.viewport(viewport.width, viewport.height);
                    cy.geonatureLogin(user.login.username, user.login.password);
                    cy.visitImport();
                    cy.get(tableSelector, { timeout: timeoutWait }).should('be.visible');
                });

                JDD_LIST.forEach(jdd_item => {
                    it(`should verify actions for ${jdd_item.jdd_name} (${jdd_item.jdd_is_active ? 'active' : 'inactive'})`, () => {
                        cy.getRowIndexByCellValue(tableSelector, columnName, jdd_item.jdd_name).then(rowIndex => {
                            verifyEditAction(rowIndex, jdd_item);
                            verifyDeleteAction(rowIndex, jdd_item);
                        });
                    });
                });
            });
        });
    });
});

function verifyEditAction(rowIndex, jdd_item) {
    const actionStatus = jdd_item.jdd_is_active ? 'not.be.disabled' : 'be.disabled';
    cy.get(`[data-qa="import-list-table-row-${rowIndex}-actions-edit"]`)
        .should('exist')
        .should('be.visible')
        .should(actionStatus)
        .then($btn => {
            if (!$btn.prop('disabled')) {
                cy.wrap($btn).click();
                cy.url().should('contain', jdd_item.url_on_click_edit);
                cy.visitImport(); // Reset state for the next action
                cy.get(tableSelector, { timeout: timeoutWait }).should('be.visible');
            }
        });
}

function verifyDeleteAction(rowIndex, jdd_item) {
    const actionStatus = jdd_item.jdd_is_active ? 'not.be.disabled' : 'be.disabled';
    cy.get(`[data-qa="import-list-table-row-${rowIndex}-actions-delete"]`)
        .should('exist')
        .should('be.visible')
        .should(actionStatus)
        .then($btn => {
            if (!$btn.prop('disabled')) {
                cy.wrap($btn).click();
                cy.get('[data-qa="import-modal-delete"]').should('be.visible');
            }
        });
}


  Cypress.Commands.add('getRowIndexByCellValue', (tableSelector, columnName, cellValue) => {
    // Define a new Cypress command to get the row index by cell value
    return cy.get(`${tableSelector} datatable-body-row`).each(($row, rowIndex) => {
        const cellSelector = `[data-qa="import-list-table-row-${rowIndex}-${columnName.replace(/\s+/g, '-').toLowerCase()}"]`;
        cy.wrap($row).find(cellSelector).then(($cell) => {
            if ($cell.text().trim() === cellValue) {
                cy.wrap(rowIndex).as('targetRowIndex');
            }
        });
    }).then(() => {
        // Return the aliased row index value
        return cy.get('@targetRowIndex');
    });
});
