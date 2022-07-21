const webpack = require('webpack');
console.log('Use webpack there');
module.exports = {
  plugins: [
    new webpack.ProvidePlugin({
      process: 'process/browser',
    }),
  ],
};
