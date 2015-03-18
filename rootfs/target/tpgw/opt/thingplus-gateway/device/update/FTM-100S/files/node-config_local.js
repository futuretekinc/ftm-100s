'use strict';
var path = require('path');

// curernt directory is {base_dir}/config
var baseDir = path.join(__dirname, '../../../../..');
console.log('config __dirname', __dirname, baseDir);
module.exports = {
  'Gateway': {
    //'port': 8088,
    'CERT_FILE_PATH': path.join(baseDir, 'config/cert.p12'),
  },
  'Store': {
    'baseDir': path.join(baseDir, 'store/')
  }
};
