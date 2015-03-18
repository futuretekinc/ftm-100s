'use strict';
var util = require('util');

var SensorLib = require('../../index'),
    Actuator = SensorLib.Actuator,
    logger = Actuator.getLogger();

function BarunActuator(sensorInfo, options) {
  Actuator.call(this, sensorInfo, options);

  if (sensorInfo) {
    this.model = sensorInfo.model;
    this.domain = sensorInfo.device.address;
  }
}

BarunActuator.properties = {
  supportedNetworks: ['barun'],
  dataTypes: ['powerSwitch'],
  discoverable: false,
  addressable: true,
  maxInstances: 5,
  idTemplate: '{model}-{address}',
  models: ['CC3200A'],
  commands: ['on', 'off'],
  category: 'actuator'
};

util.inherits(BarunActuator, Actuator);

BarunActuator.prototype.on = function (options, cb) {
  logger.fatal('[BarunActuator] on NOT IMPLEMENTED');
  return cb && cb(new Error('NOT IMPLEMENTED'));
};

BarunActuator.prototype.off = function (options, cb) {
  logger.fatal('[BarunActuator] off NOT IMPLEMENTED');
  return cb && cb(new Error('NOT IMPLEMENTED'));
};

BarunActuator.prototype._clear = function () {
  return;
};

module.exports = BarunActuator;
