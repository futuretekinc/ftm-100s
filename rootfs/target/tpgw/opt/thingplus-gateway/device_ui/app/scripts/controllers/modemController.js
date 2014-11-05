define(['controllers/controllers'],
  function(controllers) {
    'use strict';
    controllers.controller('ModemCtrl', ['$scope', '$http', '$$log',
      function($scope, $http, $$log) {
        $$log.setCategory('ModemCtrl');

        $scope.reload = function () {
          $http({method: 'GET', url: '/api/modem/stats'}).
              success(function(data/*, status, headers, config*/) {
                $$log.log('response of modem stats api', data);
                $scope.stats = data.stats;
		$scope.gateway = data.gateway;
              }).
              error(function(data/*, status, headers, config*/) {
                $$log.error(data);
              });

          $http({method: 'GET', url: '/api/sensor/data'}).
              success(function(data/*, status, headers, config*/) {
                $$log.log('response of sensor data api', data);
                $scope.sensorsData = data;
              }).
              error(function(data/*, status, headers, config*/) {
                $$log.error(data);
              });
        };

        $scope.reload();
      }
    ]);
  }
);
