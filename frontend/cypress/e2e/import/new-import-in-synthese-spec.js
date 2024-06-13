
describe('Import - create a new import', () => {
  beforeEach(() => {
    cy.geonatureInitImportList()
  });

  it('Should be able to import a valid-file in synthese', () => {
    cy.startImport();
    cy.pickDestination();
    cy.loadImportFile();
    cy.configureImportFile();
    cy.configureImportFieldMapping();
    cy.configureImportContentMapping();
    cy.verifyImport();
    cy.executeImport();
    cy.backToImportList();
    cy.removeFirstImportInTable();
  })
})
