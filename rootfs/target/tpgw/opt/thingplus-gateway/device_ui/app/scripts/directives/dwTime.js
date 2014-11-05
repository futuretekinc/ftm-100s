define(['directives/directives'], function (directives) {
  'use strict';
  directives.directive('dwTime', ['$timeout', 'fromNowFilter',
    function($timeout, fromNowFilter) {
      return function(scope, element, attrs) {
        var time = attrs.dwTime;
        var intervalLength = 1000 * 60; // 1 min
        var timeoutId;

        function updateTime() {
          //console.log(fromNowFilter(time));
          element.text(fromNowFilter(time) || '');
        }
        scope.$watch(attrs.dwTime, function(value) {
          time = value;
          updateTime();
        });

        function updateLater() {
          timeoutId = $timeout(function() {
            updateTime();
            updateLater();
          }, intervalLength);
        }

        element.bind('$destroy', function() {
          $timeout.cancel(timeoutId);
        });

        updateTime();
        updateLater();
      };
    }  
  ]);
});
