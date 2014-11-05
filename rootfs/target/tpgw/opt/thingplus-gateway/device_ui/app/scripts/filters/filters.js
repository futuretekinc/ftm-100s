define(['angular', 'moment'], function(angular, moment) {
  'use strict';
  return angular.module('filters', []).filter('fromNow', function() {
    return function(dateString) {
      var time = Number(dateString, 10);
      if (!time) {
        time = Date.parse(dateString);
      }
      return time && moment(time).fromNow();
    };
  });
});
