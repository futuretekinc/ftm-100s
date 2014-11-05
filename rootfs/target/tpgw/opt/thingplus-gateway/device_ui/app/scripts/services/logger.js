define(['services/services'],
  function(services) {
    'use strict';
    services.factory('$$log', ['$log', function ($log) {
      var logLevelPriority = {
        error: 4,
        warn: 3,
        info: 2,
        log: 1
      }, 
        logCategory = 'global',
        logLevel = 'log';

      return {
        log: function () {
          if (logLevelPriority[logLevel] < 2) {
            $log.log('[' + logCategory + '] ', arguments);
          }
        },
        info: function (message) {
          if (logLevelPriority[logLevel] < 3) {
            $log.info('[' + logCategory + '] ', arguments);
          }
        },          
        warn: function (message) {
          if (logLevelPriority[logLevel] < 4) {
            $log.warn('[' + logCategory + '] ', arguments);
          }
        },          
        error: function (message) {
          if (logLevelPriority[logLevel] < 5) {
            $log.error('[' + logCategory + '] ', arguments);
          }
        },          
        setCategory: function (category) {
          logCategory = category;
        },
        setLevel: function (level) {
          logLevel = level;
        }
      };
    }]);
  }
);
