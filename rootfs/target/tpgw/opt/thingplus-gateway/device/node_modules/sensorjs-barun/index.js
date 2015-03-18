'use strict';
var logger = require('log4js').getLogger('Sensor');

function initNetworks() {
  var barunNetwork;

  try {
    barunNetwork = require('./network/barun');
  } catch (e) {
    logger.error('[barun] init networks error', e);
  }

  return {
    barun: barunNetwork
  };
}

function initDrivers() {
  var barunSensor, barunActuator;

  try {
    barunSensor = require('./driver/barunSensor');
    barunActuator = require('./driver/barunActuator');
  } catch(e) {
    logger.error('[barun] init drivers error', e);
  }

  return {
    barunSensor: barunSensor,
    barunActuator: barunActuator
  };
}

module.exports = {
  networks: ['barun'],
  drivers: {
    barunSensor: ['CC3200S'],
    barunActuator: ['CC3200A']
  },
  initNetworks: initNetworks,
  initDrivers: initDrivers
};
