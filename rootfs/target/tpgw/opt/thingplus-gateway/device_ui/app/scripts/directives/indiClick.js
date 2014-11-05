define(['directives/directives', 'Spinner'], function (directives, Spinner) {
  'use strict';
  directives.directive('indiClick', ['$parse', function ($parse) {
    return {
      restrict: 'A',
      link: function (scope, element, attr) {
        var fn = $parse(attr['indiClick']),
            target = element[0];

        element.on('click', function (event) {
          scope.$apply(function () {
            var height = element.height(),
                oldWidth = element.width(),
                opts = {
              length: Math.round(height / 4),
              radius: Math.round(height / 6),
              width: Math.round(height / 10),
              color: element.css('color'),
//              shadow: true,
              hwaccel: true,
              left: -10
            }; // customize this "resizing and coloring" algorithm

            attr.$set('disabled', true);
            element.width(oldWidth + oldWidth / 2); // make room for spinner

            var spinner = new Spinner(opts).spin(target);
            // expects a promise
            // http://docs.angularjs.org/api/ng.$q
            fn(scope, { $event: event })
                .then(function (res) {
                  element.width(oldWidth); // restore size
                  attr.$set('disabled', false);
                  spinner.stop();
                  return res;
                }, function (/*res*/) {
                  element.width(oldWidth); // restore size
                  attr.$set('disabled', false);
                  spinner.stop();
                });
          });
        });
      }
    };
  }]);
});
