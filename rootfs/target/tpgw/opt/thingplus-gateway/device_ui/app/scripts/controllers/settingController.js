define(['controllers/controllers', 'ngUpload', 'jsMD5'],
  function (controllers, ngupload, md5) {
    'use strict';
    controllers.controller('SettingCtrl', ['$scope', '$http', '$$log', '$q', '$timeout',
      function ($scope, $http, $$log, $q, $timeout) {
        $$log.setCategory('SettingCtrl');
        var DEFAULT_INTERVAL = 60000,
        PING_INTERVAL = 5000,
        PROGRESS_INDI = ' ->',
        MAX_PING_TRIES = 30; // 150 secs

        var gwCtrTimer; //gatewayControl progress timer

        $scope.gatewayControlAlert = {};
        $scope.certUploadAlert = {};
        $scope.softwareUpdateAlert = {};
        $scope.underGatewayControl = false;

        function waitGateway(waitingStatusList, targetAlert, cb) {
          var progress = '';

          targetAlert.msg = '';
          $scope.underGatewayControl = true;

          if (gwCtrTimer) { $timeout.cancel(gwCtrTimer); gwCtrTimer = null;}

          (function pingGateway () {
            $$log.info('pingGateway start');
            function _checkStatus(status) {
              if (gwCtrTimer) { $timeout.cancel(gwCtrTimer); gwCtrTimer = null;}
              targetAlert.msg = 'Waiting gateway [' + status + '] ';
              targetAlert.type = 'danger';

              if (_.isEmpty(waitingStatusList)) {//dismiss
                targetAlert.msg = undefined;
                return;
              }

              if (waitingStatusList[0] !== status) {
                if (_.size(progress)/_.size(PROGRESS_INDI) > MAX_PING_TRIES) {
                  $$log.error('failure to wait', status);
                  return;
                }
                gwCtrTimer = $timeout(pingGateway, PING_INTERVAL);
                progress += PROGRESS_INDI;
                targetAlert.msg += progress;
                return;
              } else {
                progress += PROGRESS_INDI;
                targetAlert.msg += progress;
                waitingStatusList.shift();
              }

              gwCtrTimer = $timeout(pingGateway, PING_INTERVAL);

              if (_.isEmpty(waitingStatusList)) {
                targetAlert.type = 'success';
                targetAlert.msg += ' done.';
                $scope.underGatewayControl = false;
                return cb && cb();
              }
            }
            $http({
              method: 'GET',
              url: '/api/gateway/ping',
            }).
            success(function(/*data, status, headers, config*/) {
              $$log.info('pingGateway success', waitingStatusList.toString());
              _checkStatus('on');
            }).
            error(function(data, status/*, headers, config*/) {
              $$log.info('pingGateway error', data, status, waitingStatusList.toString());
              _checkStatus('off');
            });
          })();
          $scope.$on('$destroy', function () {
            if (gwCtrTimer) { $timeout.cancel(gwCtrTimer); gwCtrTimer = null;}
          });
        }

        $scope.checkSoftware = function() {
          return $http({method: 'GET', url: '/api/software/info'})
          .success(function (data/*, status, headers, config*/) {
            $$log.info('response of software info api', data);
            $scope.software = data;
          })
          .error(function (data/*, status, headers, config*/) {
            $$log.error(data);
          });
        };

        $scope.refreshGateway = function() {
          return $http({method: 'GET', url: '/api/gateway/info'})
          .success(function (data/*, status, headers, config*/) {

            $$log.log('response of gateway api', data);

            data.reportInterval = parseInt(data.reportInterval, 10) || DEFAULT_INTERVAL;
            $scope.gateway = data;
          })
          .error(function (data/*, status, headers, config*/) {
            $$log.error(data);
          });
        };

        $scope.controlGateway = function (command, targetAlert) {
          if (confirm('Proceed?')) {
            var d = $q.defer();

            $http({
              method: 'GET',
              url: '/api/gateway/control',
              params: {
                command: command
              }
            }).
            success(function(data/*, status, headers, config*/) {

              $$log.log('response of gatewayControl api', data);

              switch (command) {
              case 'swUpdate':
                waitGateway(['off', 'on'], targetAlert,
                  function() {
                    $scope.checkSoftware().then(d.resolve, d.reject);
                  });
                break;
              case 'poweroff':
                waitGateway(['off'], targetAlert, d.resolve);
                break;
              case 'reboot':
              case 'resetConfig':
              case 'restart':
                waitGateway(['off', 'on'], targetAlert, d.resolve);
                break;
              
              default:
                d.resolve();
              }
            }).
            error( function(data, status/*, headers, config*/) {
              $$log.error(data, status);
              targetAlert.type  = 'danger';
              targetAlert.msg = '[' + command + '] ' + 'failed';
              d.reject();
            });

            return d.promise;
          } else {
            return $q.reject('no confirm');
          }
        };
 
        $scope.changePassword = function (currentPassword, newPassword, confirmPassword) {
          var updatePassword,
            userReleam = 'admin:Sensor.js:';
          if(!newPassword || newPassword.length <= 0 || newPassword !== confirmPassword) {
            $$log.error('invalid password', true);
            return;
          }

          //FIXME: vulnerable to replay hack
          //FIXME: enhance password security level
          updatePassword = {
            currentPassword: md5(userReleam + currentPassword),
            newPassword: md5(userReleam + newPassword)
          };

          var d = $q.defer();

          $http.post('/api/chpasswd', updatePassword).
          success(function(/*data, status, headers, config*/) {
            //clean input fields
            $scope.currentPassword = '';
            $scope.newPassword = '';
            $scope.confirmPassword = '';
            d.resolve();
          }).
          error(function(data, status/*, headers, config*/) {
            $$log.error(data, status);
            d.reject();
          });
          return d.promise;
        };

        $scope.upload = function (content) {
          if (content.statusCode === 200) {
            waitGateway(['off', 'on'], $scope.certUploadAlert);
          } else {
            $scope.certUploadAlert.type = 'danger';
            $scope.certUploadAlert.msg = content.msg;
          }
        };

        $scope.checkSoftware();
        $scope.refreshGateway();
      }
    ]);
  }
);
