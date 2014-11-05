'use strict';
//var lrSnippet = require('grunt-contrib-livereload/lib/utils').livereloadSnippet;
//var mountFolder = function (connect, dir) {
//  return connect.static(require('path').resolve(dir));
//};

module.exports = function (grunt) {
  // load all grunt tasks
  require('matchdep').filterDev('grunt-*').forEach(grunt.loadNpmTasks);

  // configurable paths
  var yeomanConfig = {
    app: 'app',
    dist: 'dist'
  };

  try {
    yeomanConfig.app = require('./bower.json').appPath || yeomanConfig.app;
  } catch (e) {}

  grunt.initConfig({
    yeoman: yeomanConfig,
    watch: {
      coffee: {
        files: ['<%= yeoman.app %>/scripts/{,*/}*.coffee'],
        tasks: ['coffee:dist']
      },
      coffeeTest: {
        files: ['test/spec/{,*/}*.coffee'],
        tasks: ['coffee:test']
      },
      recess: {
        files: ['<%= yeoman.app %>/styles/{,*/}*.less'],
        tasks: ['recess']
      },
      compass: {
        files: ['<%= yeoman.app %>/styles/{,*/}*.{scss,sass}'],
        tasks: ['compass']
      },
      livereload: {
        files: [
          '<%= yeoman.app %>/{,*/}*.html',
          '{.tmp,<%= yeoman.app %>}/styles/{,*/}*.css',
          '{.tmp,<%= yeoman.app %>}/scripts/{,*/}*.js',
          '<%= yeoman.app %>/images/{,*/}*.{png,jpg,jpeg,gif,webp,svg}'
        ],
        options: {
          livereload: true
        }
      }
    },
    connect: {
      options: {
        port: 9000,
        // Change this to '0.0.0.0' to access the server from outside.
        hostname: 'localhost'
      },
      server: {
        options: {
          base: yeomanConfig.app
        }
      }
//      livereload: {
//        options: {
//          middleware: function (connect) {
//            return [
//              lrSnippet,
//              mountFolder(connect, '.tmp'),
//              mountFolder(connect, yeomanConfig.app)
//            ];
//          }
//        }
//      },
//      test: {
//        options: {
//          middleware: function (connect) {
//            return [
//              mountFolder(connect, '.tmp'),
//              mountFolder(connect, 'test')
//            ];
//          }
//        }
//      }
    },
    open: {
      server: {
        url: 'http://localhost:<%= connect.options.port %>'
      }
    },
    clean: {
      dist: {
        files: [{
          dot: true,
          src: [
            '.tmp',
            '<%= yeoman.dist %>/*',
            '!<%= yeoman.dist %>/.git*'
          ]
        }]
      },
      server: '.tmp'
    },
    jshint: {
      options: {
        jshintrc: '.jshintrc'
      },
      all: [
        'Gruntfile.js',
        '<%= yeoman.app %>/scripts/{,*/}*.js'
      ]
    },
    karma: {
      unit: {
        configFile: 'karma.conf.js',
        singleRun: true
      }
    },
    coffee: {
      dist: {
        files: [{
          expand: true,
          cwd: '<%= yeoman.app %>/scripts',
          src: '{,*/}*.coffee',
          dest: '.tmp/scripts',
          ext: '.js'
        }]
      },
      test: {
        files: [{
          expand: true,
          cwd: 'test/spec',
          src: '{,*/}*.coffee',
          dest: '.tmp/spec',
          ext: '.js'
        }]
      }
    },
    less: {
      server: {
        files: {
          '.tmp/styles/bootstrap.css': '<%= yeoman.app %>/styles/less_twitter_bootstrap/bootstrap.less',
          '.tmp/styles/app.css': '<%= yeoman.app %>/styles/*.less',
          '<%= yeoman.app %>/styles/bootstrap.css': '<%= yeoman.app %>/styles/less_twitter_bootstrap/bootstrap.less',
          '<%= yeoman.app %>/styles/app.css': '<%= yeoman.app %>/styles/*.less'
        }
      },
      dist: {
        files: {
          '.tmp/styles/bootstrap.css': '<%= yeoman.app %>/styles/less_twitter_bootstrap/bootstrap.less',
          '.tmp/styles/app.css': '<%= yeoman.app %>/styles/*.less'
        }
      }
    },
    recess: {
      options: {
        compile: true
      },
      server: {
        files: {
          '.tmp/styles/bootstrap.css': '<%= yeoman.app %>/styles/less_twitter_bootstrap/bootstrap.less',
          '.tmp/styles/app.css': '<%= yeoman.app %>/styles/*.less',
          '<%= yeoman.app %>/styles/bootstrap.css': '<%= yeoman.app %>/styles/less_twitter_bootstrap/bootstrap.less',
          '<%= yeoman.app %>/styles/app.css': '<%= yeoman.app %>/styles/*.less'
        }
      },
      dist: {
        files: {
          '.tmp/styles/bootstrap.css': '<%= yeoman.app %>/styles/less_twitter_bootstrap/bootstrap.less',
          '.tmp/styles/app.css': '<%= yeoman.app %>/styles/*.less'
        }
      }
    },
    compass: {
      options: {
        sassDir: '<%= yeoman.app %>/styles',
        cssDir: '.tmp/styles',
        imagesDir: '<%= yeoman.app %>/images',
        javascriptsDir: '<%= yeoman.app %>/scripts',
        fontsDir: '<%= yeoman.app %>/styles/fonts',
        importPath: '<%= yeoman.app %>/components',
        relativeAssets: true
      },
      dist: {},
      server: {
        options: {
          debugInfo: true
        }
      }
    },
    requirejs: {
      compile: {
        options: {
          name: 'main',
          optimize: 'none', // requirejs has own copy of uglifyjs that breaks the build
          baseUrl: '<%= yeoman.app %>/scripts/',
          mainConfigFile: '<%= yeoman.app %>/scripts/main.js',
          out: '.tmp/requirejs/main-src.js'
        }
      }
    },
    concat: {
      dist: {
        files: {
          '<%= yeoman.dist %>/scripts/main.js': [
            '.tmp/requirejs/main-src.js',
            '.tmp/scripts/{,*/}*.js'
//            '<%= yeoman.app %>/scripts/vendor/{,*/}*.js'
          ]
        }
      }
    },
    useminPrepare: {
      html: ['<%= yeoman.app %>/index.html', '<%= yeoman.app %>/views/**/*.html'],
      options: {
        dest: '<%= yeoman.dist %>'
      }
    },
    usemin: {
      html: ['<%= yeoman.dist %>/{,*/}*.html', '<%= yeoman.dist %>/views/**/*.html'],
      css: ['<%= yeoman.dist %>/styles/{,*/}*.css'],
      options: {
        dirs: ['<%= yeoman.dist %>']
      }
    },
    imagemin: {
      dist: {
        files: [{
          expand: true,
          cwd: '<%= yeoman.app %>/images',
          src: '**/*.{png,jpg,jpeg}',
          dest: '<%= yeoman.dist %>/images'
        }]
      }
    },
    cssmin: {
      dist: {
        files: {
          '<%= yeoman.dist %>/styles/main.css': [
            '.tmp/styles/{,*/}*.css',
            '<%= yeoman.app %>/styles/{,*/}*.css'
          ]
        }
      }
    },
    htmlmin: {
      dist: {
        options: {
          /*removeCommentsFromCDATA: true,
           // https://github.com/yeoman/grunt-usemin/issues/44
           //collapseWhitespace: true,
           collapseBooleanAttributes: true,
           removeAttributeQuotes: true,
           removeRedundantAttributes: true,
           useShortDoctype: true,
           removeEmptyAttributes: true,
           removeOptionalTags: true*/
        },
        files: [{
          expand: true,
          cwd: '<%= yeoman.app %>',
          src: ['*.html', 'views/*.html', 'views/templates/*.html'],
          dest: '<%= yeoman.dist %>'
        }]
      }
    },
    cdnify: {
      dist: {
        html: ['<%= yeoman.dist %>/*.html']
      }
    },
    ngmin: {
      dist: {
        files: [{
          expand: true,
          cwd: '<%= yeoman.dist %>/scripts',
          src: '*.js',
          dest: '<%= yeoman.dist %>/scripts'
        }]
      }
    },
    uglify: {
      dist: {
        files: {
          '<%= yeoman.dist %>/scripts/main.js': [
            '<%= yeoman.dist %>/scripts/main.js'
          ]
        }
      }
    },
    rev: {
      dist: {
        files: {
          src: [
            '<%= yeoman.dist %>/scripts/{,*/}*.js',
            '<%= yeoman.dist %>/styles/{,*/}*.css',
            '<%= yeoman.dist %>/styles/fonts/*'
          ]
        }
      },
      distall: {
        files: {
          src: [
            '<%= yeoman.dist %>/scripts/{,*/}*.js',
            '<%= yeoman.dist %>/styles/{,*/}*.css',
            '<%= yeoman.dist %>/images/{,*/}*.{png,jpg,jpeg,gif,webp,svg}',
            '<%= yeoman.dist %>/styles/fonts/*'
          ]
        }
      }
    },
    copy: {
      dist: {
        files: [{
          expand: true,
          dot: true,
          cwd: '<%= yeoman.app %>',
          dest: '<%= yeoman.dist %>',
          src: [
            '*.{ico,txt}',
            '.htaccess',
            'components/**/*',
            'images/{,*/}*.{gif,webp}',
            'fonts/*',
            'styles/font-awesome/font/*'
          ]
        }]
      }
    },
    shell: {
      vsync: {
        options: {                      // Options
          stdout: true
        },
        command: function (host) {
          return 'fswatch . "vsync ' + host + '"';
        }
      }
    }
  });

  grunt.registerTask('server', [
    'clean:server',
//    'coffee:dist',
    'recess:server',
//    'compass:server',
//    'livereload-start',
    'connect',
    'open',
    'watch'
  ]);

  grunt.registerTask('test', [
    'clean:server',
    'coffee',
    'recess:server',
//    'compass',
    'connect:test',
    'karma'
  ]);

  grunt.registerTask('build', [
    'clean:dist',
    'jshint',
//    'test',
//    'coffee',
    'recess:dist',
//    'compass:dist',
    'useminPrepare',
    'imagemin',
    'cssmin',
    'htmlmin',
    'requirejs',
    'concat',
    'copy',
    'cdnify',
    'ngmin',
    'uglify',
    'rev:dist',
    'usemin'
  ]);

  grunt.registerTask('default', ['build']);
};
