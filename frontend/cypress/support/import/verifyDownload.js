Cypress.Commands.add('verifyDownload', (fileName, downloadFolder) => {
  const filePath = `${downloadFolder}/${fileName}`;

  // Check if the file exists and is not empty
  cy.readFile(filePath, { timeout: 15000 }).then((fileContent) => {
    expect(fileContent).to.not.be.empty;
  });
});
