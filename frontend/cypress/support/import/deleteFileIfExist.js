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
