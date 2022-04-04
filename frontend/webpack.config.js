const webpack = require('webpack');
console.log('Use webpack here');
module.exports = {
  plugins: [
    new webpack.DefinePlugin({
      'process.env.NODE_ENV': process.env.NODE_ENV,
      'process.env.NODE_DEBUG': process.env.NODE_DEBUG,
    }),
  ],
};
