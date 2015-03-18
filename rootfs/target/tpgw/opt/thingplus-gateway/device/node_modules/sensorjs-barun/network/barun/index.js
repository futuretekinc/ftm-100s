'use strict';

var util = require('util');

var Network = require('../../index').Network;

function Barun(options) {
  Network.call(this, 'barun', options);
}

util.inherits(Barun, Network);

Barun.prototype.getDevice = function (addr, options, cb) {
  if (typeof options === 'function') {
    cb = options;
  }

  return cb && cb();
};

Barun.prototype.discover = function (driverOrModel, cb) {
  return cb && cb();
};

module.exports = new Barun();
