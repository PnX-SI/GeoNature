const fs = require('fs');
const path = require('path');
module.exports = (on, config) => {
  config.env.apiEndpoint = process.env.API_ENDPOINT || 'http://localhost:8000/';
  config.env.urlApplication = process.env.URL_APPLICATION || 'http://127.0.0.1:4200/#/';

  // Define the deleteFile task
  on('task', {
    deleteFile(filePath) {
      if (fs.existsSync(filePath)) {
        fs.unlinkSync(filePath);
        return { success: true };
      }
      return { success: false };
    },
    fileExists(filePath) {
      return fs.existsSync(filePath);
    },
    getLastDownloadFileName(downloadsDirPath) {
      if (!fs.existsSync(downloadsDirPath)) {
        return null;
      }
      const filenames = fs.readdirSync(downloadsDirPath);
      return filenames[0];
    },
  });
  return config;
};
