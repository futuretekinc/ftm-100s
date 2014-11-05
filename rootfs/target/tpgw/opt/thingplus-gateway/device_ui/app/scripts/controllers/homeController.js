define(['controllers/controllers'],
  function(controllers) {
    'use strict';
    var connected = {
        on: true,
        text: 'Connected',
        style: 'success',
      }, 
      disconnected = {
        on: false,
        text: 'Disconnected',
        style: 'danger',
      };
    controllers.controller('HomeCtrl', ['$scope', '$q', '$http', '$$log',
      function($scope, $q, $http, $$log) {
        var MODEM_IF_NAME = 'ppp0';
        var modemIf, modems;

        $$log.setCategory('HomeCtrl');

        $scope.updatedTime = {};
        $scope.size = function (obj) {
          return _.size(obj);	
        };

        function _getInterfaces () {
          return $http({method: 'GET', url: '/api/interfaces'}).
          success(function(data/*, status, headers, config*/) {
            $$log.log('response of interfaces api', data);
            $scope.updatedTime.modem = new Date();

            modemIf = _.find(data, {id: MODEM_IF_NAME});
            if (modemIf) {
              modemIf.status = 'on';
              modemIf.name = MODEM_IF_NAME;
              $scope.modemIf = modemIf;
            } else {
              modemIf = {};
              modemIf.status = 'off';
              $scope.modemIf = modemIf;
            }
          }).
          error(function(data/*, status, headers, config*/) {
            $$log.error(data);
          });
        }
        function _getModems () {
          return $http({method: 'GET', url: '/api/modems'}).
          success(function(data/*, status, headers, config*/) {
            $$log.log('response of modems api', data);
            modems = data;
            $scope.updatedTime.modem = new Date();

            $scope.modems = data;
            if (data.length === 1) {
              $scope.selectedModem = data[0];
            }
          }).
          error(function(data/*, status, headers, config*/) {
            $$log.error(data);
          });
        }
        function _getInfo (filter) {
          var d = $q.defer(),
          promises = [], 
          sensorD,
          p;

          if (!filter || filter.server) {
            p = $http({method: 'GET', url: '/api/server/info'}).
              success(function(data/*, status, headers, config*/) {
                $$log.log('response of server api', data);
                $scope.server = data;
                $scope.connectionServerStatus = {
                  service: data.status.service.connected ? connected : 
                    _.defaults({text: data.status.service.lastError || 'Disconnected'}, disconnected), 
                  mqtt: data.status.mqtt.connected ? connected : 
                    _.defaults({text: data.status.mqtt.lastError || 'Disconnected'}, disconnected),
                  registered: data.registered,
                };
                $scope.updatedTime.server = new Date();
              }).
              error(function(data/*, status, headers, config*/) {
                $$log.error(data);
              });
            promises.push(p);
          }

          if (!filter || filter.sensor) {
            sensorD = $q.defer();
            promises.push(sensorD.promise);

            $http({method: 'GET', url: '/api/gateway/info'}).
            success(function(data/*, status, headers, config*/) {
              $$log.log('response of gateway api', data);
              $scope.gateway = data;

              $scope.gateway.nodes = {actuators: {}, sensors: {}};
              _.forEach($scope.gateway.sensors, function (sensor, key) {
                if (sensor.category === 'actuator') {
                  $scope.gateway.nodes.actuators[key] = sensor;
                } else {
                  $scope.gateway.nodes.sensors[key] = sensor;
                }
              });

              $http({method: 'GET', url: '/api/sensor/data'}).
              success(function(data/*, status, headers, config*/) {
                $$log.log('response of sensor data api', data);
                $scope.sensorsData = data;
                $scope.updatedTime.sensor = new Date();
                sensorD.resolve();
              }).
              error(function(data/*, status, headers, config*/) {
                $$log.error(data);
                sensorD.reject();
              });
            }).
            error(function(data/*, status, headers, config*/) {
              $$log.error(data);
              sensorD.reject();
            });
          }

          $q.all(promises).then(function(result) {
            d.resolve(result);
          }, function(rejection) {
            d.reject(rejection);
          });
          return d.promise;
        }

        $scope.deleteSensor = function (sensorId) {
          return $http({method: 'DELETE', url: '/api/sensors/' + sensorId}).
          success(function(data/*, status, headers, config*/) {
            $$log.log('response of sensors delete api', data);
            $scope.gateway = data;

            $scope.gateway.nodes = {actuators: {}, sensors: {}};
            _.forEach($scope.gateway.sensors, function (sensor, key) {
              if (sensor.category === 'actuator') {
                $scope.gateway.nodes.actuators[key] = sensor;
              } else {
                $scope.gateway.nodes.sensors[key] = sensor;
              }
            });
          }).
          error(function(data/*, status, headers, config*/) {
            $$log.error(data);
          });
        };

        $scope.refresh = function (filter) {
          return _getInfo(filter);
        };

        _getInfo(); // init at first time

        _getModems();
        _getInterfaces();
        
          
        $scope.changeModemConfiguration = function (selectedModem) {
          return $http.put('/api/modems/' + encodeURIComponent(selectedModem.USB_ID),  
            selectedModem.config 
          ).
          success(function(data/*, status, headers, config*/) {
            $$log.log('response of modems put api', data);
            $scope.updatedTime.modem = new Date();

            $scope.selectedModem = data;
          }).
          error(function(data/*, status, headers, config*/) {
            $$log.error(data);
          });
        };
        $scope.refreshModem = function () {
          var d = $q.defer();

          $q.all([_getModems(), _getInterfaces()]).then(function(result) {
            d.resolve(result);
          }, function(rejection) {
            d.reject(rejection);
          });
          return d.promise;
        };

        $scope.controlActuator = function (actuator, command) {
          if (!command) {
            $$log.warn('command is not selected');
            return;
          }

          actuator.cmd = command;
          actuator.id = actuator.id || actuator.reqId;

          $$log.info('[controlActuator]', actuator);

          $http({
            method: 'POST',
            url: '/api/actuator/control',
            data: actuator
          }).
          success(function (data) {
            $$log.info('response of actuator api', data);
            $scope.testResult = data;
          }).
          error(function (data) {
            $$log.error(data);
          });
        }
      }
    ]);
  }
);
