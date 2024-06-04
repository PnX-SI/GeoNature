module.exports = (on, config) => {
  config.env.apiEndpoint = process.env.API_ENDPOINT || 'http://localhost:8000/';
  return config;
};
