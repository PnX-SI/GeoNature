module.exports = (on, config) => {
  config.env.apiEndpoint = process.env.API_ENDPOINT || 'http://127.0.0.1:8000/';
  return config;
};
