'use strict';
var os = require('os'),
  path = require('path');

module.exports = {
  Auth: {
    admin: '93f77339234c8e6717412baad4f53dae' //crypto.createHash('md5').update('admin:Sensor.js:admin123').digest('hex'),
  },
  Init: {
    timeout: 5 * 60 * 1000, // 5min
  },
  Gateway: {
    name: os.hostname(),
    firstDelay: 5000,
    reportInterval: 60000,
    CERT_FILE_PATH: path.normalize(__dirname + '/..' + '/ssl/cert.p12'),
    CA_FILE_PATH: path.normalize(__dirname + '/..' + '/ssl/ca-cert.pem'),
    port: 80,
    logBaseDir: '/var/log/thingplus/',
  },
  Server: {
    timeSyncCheckInterval: 60 * 1000, // 1min
    mqtt: {
      protocol: 'mqtts',
      host: 'mqtt.thingplus.net',
      port: '8883',
      retryConnectInterval: 1*60*1000, //1min
      ackTimeout: 30*1000, // 30 sec
    },
    service: {
      protocol: 'https',
      host: 'www.thingplus.net',
      port: '8443'
    },
  },
  Store: {
    baseDir: '/var/lib/thingplus/',
    currentFile: 'db.dirty',
    cleanUpInterval: 60 * 60 * 1000, // 1hour
    logFlushFilesystemLimit: 10, //10%
    storeDisableFilesystemLimit: 3, //3%
    storeDisableMemoryLimit: 0, //0%
    rebootInOfflineInterval: 6*3600, //6 hours
  },
  ServerTemplate: {
    mqtt: {
      protocol: { default: 'mqtt', required: true},
      host: { default: 'ving.daliworks.net', required: true},
      port: { default: 1883, required: true},
    },
    service: {
      protocol: { default: 'http', required: true},
      host: { default: 'ving.daliworks.net', required: true},
      port: { default: 80, required: true},
    }
  },
  SensorTemplate: {
    ds18b20: {
      id: { required: true, autodetect: true},
      name: {required: true},
      desc: { default: 'ds18b20(oneWire thermameter)', required: true},
      storage: {required: true},
      type: { default: 'temperature', required: true, immutable: true},
      interface: { default: 'oneWire', required: true, immutable: true},
      gpio: { default: 2, required: true, immutable: true},
      model: {default: 'ds18b20', required: true, immutable: true},
      description: {},
    },
    dht: {
      id: { default: 'dht-1', required: true},
      name: {required: true},
      desc: { default: 'dht(hydro meter)', required: true},
      storage: {required: true},
      interface: { default: 'gpio', required: true, immutable: true},
      gpio: { default: 47, required: true, immutable: true, number: true},
      model: { default: 'dht11', required: true, selections: ['dht11', 'dht22']},
      description: {},
    },
    'switch': {
      id: { default: 'switch-1', required: true},
      name: {required: true},
      desc: { default: 'magnetic switch', required: true},
      storage: {required: true},
      interface: { default: 'gpio', required: true, immutable: true},
      gpio: { default: 45, required: true, immutable: true, number: true},
      description: {},
    }
  },
  Sensors: {
  },
  Modem: {
  }
};
