'use strict';
var util = require('util'),
    fs = require('fs'),
    _ = require('lodash'),
    SensorLib = require('../index'),
    Actuator = SensorLib.Actuator,
    logger = Actuator.getLogger();

var DEFAULT_BLINK_INTERVAL = 5000;

var _channelValue = {};

// nmPowerSwitchActuator constructor
var nmPowerSwitchActuator = function (sensorInfo, options) {
  Actuator.call(this, sensorInfo, options);

  if (!_.isUndefined(sensorInfo.device.address)) {
    // address: serial device name ex) USB0
    this.deviceName = '/dev/tty' + sensorInfo.device.address;
        
    this.channel = this.id && Number(_.last(this.id.split('-'))) || 0;
    if (_.isUndefined(_channelValue[this.deviceName])) { 
      _channelValue[this.deviceName] = 0; //init
    }
    logger.info('nmPowerSwitchActuator sensor(deviceName: %s, channel: %d) is created at driver', this.deviceName, this.channel, sensorInfo);
  } else {
    logger.warn('nmPowerSwitchActuator sensor address or channel is not provided', sensorInfo);
  }
};

nmPowerSwitchActuator.properties = {
  supportedNetworks: ['serial'],
  dataTypes: ['powerSwitch'],
  discoverable: false,
  addressable: true,
  maxInstances: 5,
  idTemplate: '{gatewayId}-{deviceAddress}-{sequence}',
  model: 'powerSwitch',
  commands: ['on', 'off', 'blink'],
  category: 'actuator'
};
util.inherits(nmPowerSwitchActuator, Actuator);

nmPowerSwitchActuator.prototype.isOn = function() {
  /*jshint bitwise: false*/
  return (_channelValue[this.deviceName] & (1 << this.channel)) !== 0;
};

nmPowerSwitchActuator.prototype.writeCmd = function(cmd) {
  /*jshint bitwise: false*/
  var val = _channelValue[this.deviceName];
  
  if (cmd === 'on') {
    val =  val | (1 << this.channel);
  } else { //off
    val = val & ~(1 << this.channel);
  }

  try {
    fs.appendFileSync(this.deviceName, val.toString());
  } catch (e) {
    logger.error('[nmPowerSwitch] writeCmd error', this.id, e);
    throw e;
  }
  _channelValue[this.deviceName] = val;
};

/* Turn powerSwitch on */
/* options.duration: infinite if NaN, null, undefined, zero or minus */
nmPowerSwitchActuator.prototype.on = function (options, cb) {
  var self = this,
      duration = options && Number(options.duration, 10);

  this._clear();

  if (!duration || duration <= 0) {
    duration = 0; 
  }

  try {
    this.writeCmd('on');
  } catch (e) { /* handle error */
    return cb && cb(e);
  }

  if (duration) { 
    this.offTimer = setTimeout(function () {
      self.offTimer = null;
      self.off();
    }, duration);
  }

  logger.info('[nmPowerSwitchActuator] on command with ', options);

  return cb && typeof cb === 'function' && cb(null, this.id + ' is on');
};

/* Turn powerSwitch off */
nmPowerSwitchActuator.prototype.off = function (options, cb) {
  this._clear();
  try {
    this.writeCmd('off');
  } catch (e) { /* handle error */
    return cb && cb(e);
  }

  logger.info('[nmPowerSwitchActuator] off command with ', options);
  return cb && typeof cb === 'function' && cb(null, this.id + ' is off');
};
/* Blink 
 * interval: blink interval(default: 5 sec)
 * options.duration: infinite if NaN, null, undefined, zero or minus
 */
nmPowerSwitchActuator.prototype.blink = function (options, cb) {
  var self = this,
      interval = options && Number(options.interval, 10),
      duration = options && Number(options.duration, 10);

  this._clear();

  if (!interval || interval <= 0) {
    interval = DEFAULT_BLINK_INTERVAL; 
  }


  if (!duration || duration <= 0) {
    duration = 0; 
  }

  this.blinkTimer = setInterval(function () {
    try {
      this.writeCmd(self.isOn() ? 'off' : 'on');
    } catch (e) { /* handle error */
      logger.error('[blinkTimer] error', self.id, e);
    }
  }, interval || DEFAULT_BLINK_INTERVAL);

  if (duration) {
    this.offTimer = setTimeout(function () {
      clearInterval(self.blinkTimer);
      self.blinkTimer = null;
      self.offTimer = null;
      self.off();
    }, duration);
  }

  return cb && typeof cb === 'function' && cb(null, this.id + ' is blinking');
};
/* Clear powerSwitch */
nmPowerSwitchActuator.prototype._clear = function () {
  if (this.blinkTimer) {
    clearInterval(this.blinkTimer);
    this.blinkTimer = null;
  }
  if (this.offTimer) {
    clearTimeout(this.offTimer);
    this.offTimer = null;
  }
};

module.exports = nmPowerSwitchActuator;
