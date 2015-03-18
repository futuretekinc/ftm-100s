/* globals _, $, Blob, window, Image */
define(['controllers/controllers'],
  function(controllers) {
    'use strict';
    controllers.controller('RegisterCtrl', ['$scope', '$stateParams','$http', '$$log', '$q',
      function($scope, $stateParams, $http, $$log, $q) {
        $$log.setCategory('RegisterCtrl');

        var targetSensorId = $stateParams.sensor, // sensorId to edit
            targetSensor,
            sensorInfo = {},
            sensorInfoArr = []; // use arrya: workaround to sort network and label

        function template(str, tokens) {
          return str && str.replace(/\{(\w+)\}/g, function (x, key) {
            return tokens[key];
          });
        }

        $http({method: 'GET', url: '/api/sensorDrivers'}).
            success(function(data/*, status, headers, config*/) {
              console.log('response of sensor drivers api', data);
              //TODO: consider multi supported network, sorting
              _.forEach(data, function (sensorDriver) {
                sensorDriver.network = _.size(sensorDriver.supportedNetworks) > 0 && sensorDriver.supportedNetworks[0];
                sensorInfo[sensorDriver.id] = sensorDriver;
                sensorInfoArr.push(sensorDriver);
              });
              $scope.sensorInfo = sensorInfo;
              $scope.sensorInfoArr = sensorInfoArr;

              $http({method: 'GET', url: '/api/gateway/info'}).
                  success(function(data/*, status, headers, config*/) {
                    console.log('response of gateway api', data);
                    $scope.gateway = data;
                    if( targetSensorId && data.sensors && data.sensors[targetSensorId] ) {
                      $scope.targetSensor = targetSensor = data.sensors[targetSensorId];
                      $scope.selectedDriverName = targetSensor.driverName;
                      $scope.showNext(targetSensor.driverName);
                    }
                  }).
                  error(function(data/*, status, headers, config*/) {
                    $$log.error(data);
                  });
            }).
            error(function(data/*, status, headers, config*/) {
              $$log.error(data);
            });

        $scope.showNext = function (type) {
          var d;

          //add options like notification=true, recommendInteval=10000
          $scope.selectedAgentType = type;

          $scope.sensors = null;
          $scope.driverName = sensorInfo[type].driverName;
          $scope.models = sensorInfo[type].models;
          $scope.supportedNetworks = sensorInfo[type].supportedNetworks;
          $scope.commands = sensorInfo[type].commands;
          $scope.category = sensorInfo[type].category;
          $scope.addressable = !!JSON.parse(sensorInfo[type].addressable);
          $scope.sequenceable = !!(sensorInfo[type].sequenceable && JSON.parse(sensorInfo[type].sequenceable));
          $scope.discoverable = JSON.parse(sensorInfo[type].discoverable);

          if (targetSensor) {
            $scope.dataType = targetSensor.type;
            $scope.name = targetSensor.name;
            $scope.model = targetSensor.model;
            $scope.network = targetSensor.network;
            $scope.address = targetSensor.address;
            $scope.sequence = targetSensor.sequence;
            $scope.selectModel($scope.model);
          } else {
            $scope.name = null;
            if (_.size($scope.models) === 1) {
              $scope.model = _.first($scope.models);
              $scope.selectModel($scope.model);
            }
            $scope.network = $scope.supportedNetworks && $scope.supportedNetworks.length === 1 ? $scope.supportedNetworks[0] : null;
          }

          if (targetSensor) {
            $scope.sensorId = targetSensorId;
            $scope.sensors = [targetSensorId];
          } else if (JSON.parse(sensorInfo[type].discoverable)) {
            d = $q.defer();
            $scope.sensorId = null;

            $http({method: 'GET', url: '/api/sensor/discover', params: {driverName: type}}).
            success(function(data/*, status, headers, config*/) {
              console.log('response of discover api', data);
              if (!data.new || data.new.length === 0) {
                $('#form-validation').text('No more sensor to register').slideDown('slow');
                setTimeout(function () { $('#form-validation').slideUp('slow'); }, 5000);
              }
              $scope.discovered = data.new;
              $scope.sensors = _.pluck(data.new, 'id');
              d.resolve();
            }).
            error(function(data/*, status, headers, config*/) {
              $$log.error(data);
              d.reject();
            });
          } else {
            $scope.sensorId = template(sensorInfo[type].idTemplate, {
                model: $scope.models.length === 1 ? $scope.models[0] : null,
                gatewayId: $scope.gateway.id, 
                deviceAddress: sensorInfo[type].address || 0,
                sequence: sensorInfo[type].sequence || 0,
                type: $scope.dataType
              });
            $scope.sensors = [$scope.sensorId];
          }

          $('#setting-view').slideDown('slow');

          return (d && d.promise) || $q.reject();
        };

        $scope.selectAddress = function (address) {
          var type = $scope.selectedAgentType;

          $scope.sensorId = template(sensorInfo[type].idTemplate, {
              model: $scope.model,
              gatewayId: $scope.gateway.id,
              deviceAddress: address || 0,
              sequence: $scope.sequence || 0,
              type: $scope.dataType
            });
        };

        $scope.selectSequence = function (sequence) {
          var type = $scope.selectedAgentType;

          $scope.sensorId = template(sensorInfo[type].idTemplate, {
              model: $scope.model,
              gatewayId: $scope.gateway.id,
              deviceAddress: $scope.address || 0,
              sequence: sequence || 0,
              type: $scope.dataType
            });
        };

        $scope.selectModel = function (model) {
          var type = $scope.selectedAgentType;

          if (model) {
            $scope.dataTypes = sensorInfo[type].dataTypes[model] ||
              sensorInfo[type].dataTypes;
            $scope.dataType = _.size($scope.dataTypes) === 1 ? 
              _.first($scope.dataTypes) : null;
            $scope.sensors = _.chain($scope.discovered).where({model: model}).pluck('id').value();
          } else {
            $scope.dataTypes = undefined;
            $scope.dataType = undefined;
            $scope.sensors = undefined;
          }
          $scope.sensorId = template(sensorInfo[type].idTemplate, {
            model: model,
            gatewayId: $scope.gateway.id,
            deviceAddress: $scope.address || 0,
            sequence: $scope.sequence || 0,
            type: $scope.dataType
          });
        };

        $scope.selectDiscoveredSensor = function (sensorId) {
          var discoveredInfo = _.find($scope.discovered, {id: sensorId});
          $scope.address = discoveredInfo  && discoveredInfo.device && 
          discoveredInfo.device.address; //discovered addr
        };

        $scope.registerAgent = function () {
          var agentType = $scope.selectedAgentType,
              data;

          data = {
            id: $scope.sensorId,
            type: $scope.dataType,
            name: $scope.name,
            driverName: sensorInfo[agentType].driverName,
            model: $scope.model || agentType,
            network: $scope.network,
            address: $scope.address,
            sequence: $scope.sequence,
            category: $scope.category
          };

          if (sensorInfo[agentType].commands) {
            data.commands = sensorInfo[agentType].commands;
          }

          return $http({
            method: 'POST',
            url: '/api/sensor/register',
            data: data
          }).
          success(function(data/*, status, headers, config*/) {
            $$log.info('response of register api', data);
            if (!targetSensor) { 
              $scope.sensorId = null;
              $scope.dataType = null;
              $scope.name = null;
              $scope.model = null;
              $scope.testResult = null;
              $scope.address = null;
              $scope.sequence = undefined;

              $scope.showNext(agentType);
            }
          }).
          error(function(data/*, status, headers, config*/) {
            $$log.error(data);
          });
        };

        $scope.testAgent = function () {
          var agentType = $scope.selectedAgentType;

          return $http({
            method: 'GET',
            url: '/api/sensors/' + $scope.sensorId,
            params: {
              driverName: sensorInfo[agentType].driverName,
              model: $scope.model,
              network: $scope.network,
              address: $scope.address,
              sequence: $scope.sequence,
            }
          }).
          success(function(data/*, status, headers, config*/) {
            $$log.info('response of sensor api', data);
            $scope.testResult = data;
          }).
          error(function(data/*, status, headers, config*/) {
            $$log.error(data);
          });
        };

        $scope.testActuator = function () {
          if (!$scope.selectedCommand) {
            $scope.testResult = 'command is not selected';
            return;
          }

          $http({
            method: 'POST',
            url: '/api/actuator/control',
            data: {
              id: $scope.sensorId,
              cmd: $scope.selectedCommand,
              network: $scope.network,
              address: $scope.address,
              model: $scope.model,
              driverName: $scope.driverName
            }
          }).
          success(function (data) {
            $$log.info('response of actuator api', data);

            if (_.isObject(data)) {
              if (data.contentType && data.contentType.split('/')[0] === 'image') {
                $$log.info('actuator result with image/jpeg', data);
                var img = new Image();
                var arrayBufferView = new Uint8Array(data.content);
                var blob = new Blob([arrayBufferView], {'type': data.contentType});
                var objectUrl = window.URL.createObjectURL(blob);
                img.src = objectUrl;

                $('#test-result').html(img);
                $('#test-result img').css({
                  'max-height': '400px',
                  'position': 'relative',
                  'left': '200px',
                  'margin': '10px'
                });
              } else if (data.contentType === 'text/plain') {
                $$log.info('actuator result with text/plain', data);
                $('#test-result').html(data.content.message);
              }
            } else {
              $scope.testResult = data;
            }
          }).
          error(function (data) {
            $$log.error(data);
          });
        };

        $scope.cancel = function () {
          if (targetSensor && targetSensorId && 
            $scope.gateway && $scope.gateway.sensors && 
            $scope.gateway.sensors[targetSensorId]) { 
              targetSensor = $scope.gateway.sensors[targetSensorId];
              $scope.targetSensor = targetSensor;
              $scope.selectedDriverName = targetSensor.driverName;
              $scope.showNext(targetSensor.driverName);
          } else {
            $scope.sensorId = null;
            $scope.dataType = null;
            $scope.name = null;
            $scope.model = null;
            $scope.selectedDriverName = null;

            $scope.testResult = null;
            $('#setting-view').slideUp('slow');
          }
        };
      }
    ]);
  }
);
