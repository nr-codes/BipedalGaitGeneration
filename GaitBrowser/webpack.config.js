const path = require('path');
const CopyPlugin = require('copy-webpack-plugin');

module.exports = {
  mode: 'development',

  entry: {
    'app': './src/index.js'
  },

  devtool: 'inline-source-map',

  output: {
    filename: '[name]/public/bundle.js',
    path: path.resolve(__dirname)
  },

  plugins: [
    new CopyPlugin( [ { 
      from: './src/bipeds', 
      to: 'app/public/bipeds'
    } ] )
  ]
};
