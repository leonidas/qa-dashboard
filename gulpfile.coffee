gulp       = require 'gulp'
less       = require 'gulp-less'
browserify = require 'gulp-browserify'
rename     = require 'gulp-rename'
uglify     = require 'gulp-uglify'
coffeeify  = require 'coffeeify'

compileCoffee = (debug = false) ->
  config =
    debug: debug
    transform: ['coffeeify']
    shim:
      'jquery':
        path:    './vendor/js/bower/jquery/dist/jquery.js'
        exports: '$'
      'jquery-ui-core':
        path:    './vendor/js/bower/jquery-ui/ui/jquery.ui.core.js'
        exports: '$'
        depends:
          'jquery': '$'
      'jquery-ui-widget':
        path: './vendor/js/bower/jquery-ui/ui/jquery.ui.widget.js'
        exports: '$'
        depends:
          'jquery': '$'
          'jquery-ui-core': '$'
      'jquery-ui-mouse':
        path: './vendor/js/bower/jquery-ui/ui/jquery.ui.mouse.js'
        exports: '$'
        depends:
          'jquery': '$'
          'jquery-ui-core': '$'
          'jquery-ui-widget': '$'
      'jquery-ui-draggable':
        path: './vendor/js/bower/jquery-ui/ui/jquery.ui.draggable.js'
        exports: '$'
        depends:
          'jquery': '$'
          'jquery-ui-core': '$'
          'jquery-ui-widget': '$'
          'jquery-ui-mouse': '$'
      'jquery-ui-droppable':
        path: './vendor/js/bower/jquery-ui/ui/jquery.ui.droppable.js'
        exports: '$'
        depends:
          'jquery': '$'
          'jquery-ui-core': '$'
          'jquery-ui-widget': '$'
          'jquery-ui-mouse': '$'
      'jquery-ui-sortable':
        path: './vendor/js/bower/jquery-ui/ui/jquery.ui.sortable.js'
        exports: '$'
        depends:
          'jquery': '$'
          'jquery-ui-core': '$'
          'jquery-ui-widget': '$'
          'jquery-ui-mouse': '$'
      'equal-heights':
        path: './vendor/js/jQuery.equalHeights.js'
        exports: '$'
        depends:
          'jquery': '$'
      'raphael':
        path: './vendor/js/bower/raphael/raphael.js'
        exports: 'Raphael'
        depends:
          'jquery': '$'
      'underscore':
        path:    './vendor/js/bower/underscore/underscore.js'
        exports: '_'
      'async':
        path:    './vendor/js/bower/async/lib/async.js'
        exports: 'async'

  bundle = gulp
    .src('./client/coffee/dashboard.coffee', read: false)
    .pipe(browserify(config))
    .pipe(rename('bundle.js'))

  bundle.pipe(uglify()) unless debug

  bundle
    .pipe(gulp.dest('./public/js/'))

compileLess = (debug = false) ->
  gulp
    .src('client/less/*.less')
    .pipe(less(compress: !debug))
    .pipe(gulp.dest('public/css/'))

# Build tasks
gulp.task 'less-production',   -> compileLess()
gulp.task 'coffee-production', -> compileCoffee()

# Development tasks
gulp.task 'less',   -> compileLess   true
gulp.task 'coffee', -> compileCoffee true

gulp.task 'watch', ->
  gulp.watch 'client/coffee/*.coffee', ['coffee']
  gulp.watch 'client/less/*.less',     ['less']

gulp.task 'build', ['coffee-production', 'less-production']

gulp.task 'default', ['coffee', 'less', 'watch']
