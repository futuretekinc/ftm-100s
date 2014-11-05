define(['controllers/controllers'],
  function(controllers) {
    'use strict';
    controllers.controller('HomeCtrl', ['$scope', '$http', '$$log',
      function($scope, $http, $$log) {
        $$log.setCategory('HomeCtrl');

        $http({method: 'GET', url: '/api/gateway'}).
            success(function(data, status, headers, config) {
              console.log(data);
              $scope.gateway = data;
            }).
            error(function(data, status, headers, config) {
              // called asynchronously if an error occurs
              // or server returns response with an error status.
            });
      }
    ]);
  }
);
