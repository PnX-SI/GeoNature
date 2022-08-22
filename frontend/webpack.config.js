const webpack = require('webpack');
module.exports = {
  plugins: [
    new webpack.DefinePlugin({
      'process.env.NODE_ENV': process.env.NODE_ENV,
      'process.env.NODE_DEBUG': process.env.NODE_DEBUG,
    }),
  ],
};
