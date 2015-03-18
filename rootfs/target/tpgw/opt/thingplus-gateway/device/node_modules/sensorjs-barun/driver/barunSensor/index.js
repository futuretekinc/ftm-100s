'use strict';

var util = require('util'),
    net = require('net');

var SensorLib = require('../../index'),
    Sensor = SensorLib.Sensor,
    logger = Sensor.getLogger();

//constants
var BARUN_PORT = 6000,
  BODY_SEP = '\n\n',
  RECONNECT_INTERVAL = 60*1000;

//func decl
var finClient, initClient;

function BarunSensor(sensorInfo, options) {
  Sensor.call(this, sensorInfo, options);

  if (sensorInfo.model) {
    this.model = sensorInfo.model;
  }
  if (sensorInfo.device) {
    this.ipAddr = sensorInfo.device.address;
  }

  if (!this.ipAddr) {
    logger.fatal('[BarunSensor] no ipAddr', sensorInfo);
    //FIXME: throw error
    return;
  }

  initClient(this);

  logger.debug('BarunSensor', sensorInfo);
}

BarunSensor.properties = {
  supportedNetworks: ['barun'],
  dataTypes: ['temperature'],
  onChange: false,
  discoverable: false,
  addressable: true,
  recommendedInterval: 10000,
  maxInstances: 1,
  idTemplate: '{model}-{address}',
  models: ['CC3200S'],
  category: 'sensor'
};

util.inherits(BarunSensor, Sensor);

BarunSensor.prototype._get = function () {
  var self = this; 
  var rtn = {status: 'error', id : self.id}; 

  if (self.client) {
    self.client.write(new Buffer('GET / HTTP/1.1')); 
  } else {
   // FIXME: not to be here
    rtn.message = 'no client connection';
    self.emit('data', rtn);
    logger.error('[BarunSensor] no connection');
  }
  return;
};

BarunSensor.prototype._clear = function () {
  var self = this;
  logger.warn('[BarunSensor] _clear', self.ipAddr);
  finClient(self);
  if (self._connTimer) { //clear reconnect timer
    clearInterval(self._connTimer);
    self._connTimer = null;
  }
  return;
};

finClient = function finClient(self) {
  if (self.client) {
    self.client.destroy();
    self.client = null;
    logger.warn('[BarunSensor] finClient', self.ipAddr);
  }
};

initClient = function initClient(self) {

  finClient(self);

  logger.warn('[BarunSensor] initClient', self.ipAddr);
  self.client = net.connect(BARUN_PORT, self.ipAddr, function (err) {
    var rtn = {status: 'error', id : self.id}; 
    if (err) {
      logger.error('[BarunSensor] connect err', self.ipAddr, err);
      finClient(self);
      rtn.message = 'connection error';
      self.emit('data', rtn);
    }
  });

  self.client.on('data', function (buf) {
    var rtn = {status: 'error', id : self.id}; 
    var msg = buf.toString(),
        v, bodyStart;
    bodyStart = msg.indexOf(BODY_SEP) + BODY_SEP.length;

    try { v = JSON.parse(msg.substr(bodyStart)); } catch (e) {}
    if (v && v.sensors && v.sensors[0]) {
      rtn = {status: 'ok', id : self.id, result: {}};
      rtn.result[v.sensors[0].type] = v.sensors[0].value;
      logger.info('[BarunSensor] _get', self.ipAddr, rtn);
    } else {
      rtn.message = 'unknown val:' + (v && JSON.stringify(v));
      logger.error('[BarunSensor] _get', self.ipAddr, rtn);
    }
    self.emit('data', rtn);
  });

  self.client.on('error', function (e) {
    var rtn = {status: 'error', id : self.id}; 
    rtn.message = 'get error:' + e.toString();
    logger.error('[BarunSensor] _get', self.ipAddr, rtn);
    finClient(self);
    self.emit('data', rtn);
  });
  self.client.on('close', function () {
    logger.error('[BarunSensor] _get close', self.ipAddr);
    finClient(self);
  });
  // FIXME: timeout must be enhanced.
  self.client.setTimeout(BarunSensor.properties.recommendedInterval * 1.5, function () {
    var rtn = {status: 'error', id : self.id}; 
    rtn.message = 'get timeout';
    logger.error('[BarunSensor] _get', self.ipAddr, rtn);
    finClient(self);
    self.emit('data', rtn);
  });
  if (!self._connTimer) { // reconnect timer
    self._connTimer = setInterval(function () {
      if (!self.client) { // not finalized
        logger.warn('[BarunSensor] reconnect', self.ipAddr);
        initClient(self);
      }
    }, RECONNECT_INTERVAL);  
  }

  return;
};

module.exports = BarunSensor;
