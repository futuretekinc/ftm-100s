// the app/scripts/main.js file, which defines our RequireJS config
require.config({
  waitSeconds: 50,
  paths: {
    angular: '../components/angular/angular',
    angularRoute: '../components/angular-route/angular-route',
    angularResource: '../components/angular-resource/angular-resource',
    angularCookies: '../components/angular-cookies/angular-cookies',
    angularSanitize: '../components/angular-sanitize/angular-sanitize',
    angularUIRouter: '../components/angular-ui-router/release/angular-ui-router',
    jquery: '../components/jquery/jquery',
    sidr: '../components/sidr/jquery.sidr.min',
    jqueryAnimateEnhanced: '../components/jquery.animate-enhanced/jquery.animate-enhanced.min',
    touchSwipe: '../components/jquery-touchswipe/jquery.touchSwipe',
    domReady: '../components/requirejs-domready/domReady',
    i18n: '../components/requirejs-i18n/i18n',
    lodash: '../components/lodash/dist/lodash',
    bootstrapCollapse: '../components/bootstrap/js/collapse',
    bootstrapDropdown: '../components/bootstrap/js/dropdown',
    bootstrapButton: '../components/bootstrap/js/button',
    jqueryMobileOrientationChange: 'vendor/jquery-mobile/orientationchange',
    jqueryMobileSupportOrientation: 'vendor/jquery-mobile/jquery.mobile.support.orientation',
    jqueryMobileThrottledResize: 'vendor/jquery-mobile/throttledresize',
    moment: '../components/momentjs/min/moment.min',
    Spinner: '../components/spin.js/spin',
    ngUpload: '../components/ngUpload/ng-upload',
    jsMD5: '../components/js-md5/js/md5'
  },
  shim: {
    angular: {
      deps: [ 'jquery'],
      exports: 'angular'
    },
    angularRoute: {
      deps: [ 'angular' ]
    },
    angularResource: {
      deps: [ 'angular' ]
    },
    angularCookies: {
      deps: [ 'angular' ]
    },
    angularSanitize: {
      deps: [ 'angular' ]
    },
    angularUIRouter: {
      deps: [ 'angular' ]
    },
    ngUpload: {
      deps: [ 'angular' ]
    },
    sidr: {
      deps: [ 'jquery', 'jqueryAnimateEnhanced' ]
    },
    bootstrapCollapse: {
      deps: [ 'jquery' ]
    },
    bootstrapDropdown: {
      deps: [ 'jquery' ]
    },
    bootstrapButton: {
      deps: [ 'jquery' ]
    },
    jqueryAnimateEnhanced: {
      deps: [ 'jquery' ]
    },
    touchSwipe: {
      deps: [ 'jquery' ]
    },
    jqueryMobileOrientationChange: {
      deps: [ 'jquery', 'jqueryMobileSupportOrientation', 'jqueryMobileThrottledResize']
    }
  },
  locale: localStorage.getItem('locale') || 'en'
});

require([
  // for the direct use(included in function parameters) in this function as well as global
  'angular',
  'app',
  'domReady',

  // angular libraries
  'angularRoute',
  'angularResource',
  'angularCookies',
  'angularSanitize',
  'angularUIRouter',

  // 3rd party libraries
  'lodash',
  'bootstrapCollapse',
  'bootstrapDropdown',
  'bootstrapButton',
  'jqueryMobileOrientationChange',

  // User scripts - Any individual controller, service, directive or filter file
  'services/restService',
  'services/logger',
  'services/userService',
  'controllers/homeController',
  'controllers/menuController',
  'controllers/registerController',
  'controllers/settingController',
  'controllers/modemController',
  'controllers/httpController',
  'controllers/aboutController',
  'directives/dwAccordion',
  'directives/dwExpander',
  'directives/dwNoti',
  'directives/ngbkFocus',
  'directives/indiClick',
  'directives/dwTime'
],
  function (angular, app, domReady) {
    'use strict';

    var mainApp = null;

    app.config(['$stateProvider', '$urlRouterProvider',
          function ($stateProvider, $urlRouterProvider) {
            $urlRouterProvider.
                when('', '/home').
                when('/', '/home');

            $stateProvider.state('home', {
              url: '/home',
              templateUrl: 'views/home.html',
              controller: 'HomeCtrl'
            }).
            state('register', {
              url: '/register?sensor',
              templateUrl: 'views/register.html',
              controller: 'RegisterCtrl'
            }).
            state('setting', {
              url: '/setting',
              templateUrl: 'views/setting.html',
              controller: 'SettingCtrl',
              onEnter: function () {
                //
              },
              onExit: function () {
                //
              }
            }).
            state('modem', {
              url: '/modem',
              templateUrl: 'views/modem.html',
              controller: 'ModemCtrl'
            }).
            state('about', {
              url: '/about',
              abstract: true,
              templateUrl: 'views/about.html',
              controller: 'AboutCtrl'
            }).
            state('about.info', {
              url: '',
              views: {
                '@about': {
                  templateUrl: 'views/about.info.html',
                  controller: 'AboutInfoCtrl'
                },
                'hint@about': {
                  templateUrl: 'views/about.hint.html',
                  controller: 'AboutHintCtrl'
                }
              }
            });
          }
        ]).run(['$rootScope', '$state', '$stateParams', function ($rootScope, $state, $stateParams) {
          $rootScope.$state = $state;
          $rootScope.$stateParams = $stateParams;
        }]);

    domReady(function() {
      mainApp = mainApp || angular.bootstrap(document, ['seedsApp']);

      // The following is required if you want AngularJS Scenario tests to work
    });
  }
);
