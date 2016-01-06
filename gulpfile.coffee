gulp = require 'gulp'
server = require 'gulp-express'
coffee = require 'gulp-coffee'
concat = require 'gulp-concat'
jade = require 'gulp-jade'
sass = require 'gulp-sass'
tplCache = require 'gulp-angular-templatecache'

SRC = './src'
DIST = './dist'


gulp.task 'scripts', ->
  gulp.src "#{SRC}/*.coffee"
    .pipe coffee bare: true
    .pipe concat 'app.js'
    .pipe gulp.dest DIST


gulp.task 'templates', ->
  gulp.src "#{SRC}/*.jade"
    .pipe jade()
    .pipe tplCache 'templates.js', module: 'kxGrid'
    .pipe gulp.dest DIST


gulp.task 'styles', ->
  gulp.src "#{SRC}/*.sass"
    .pipe sass(), sass.logError
    .pipe gulp.dest DIST


gulp.task 'watch', ->
  ## Jade
  gulp.watch ["#{SRC}/*.jade"], ['templates']

  ## SASS
  gulp.watch ["#{SRC}/*.sass"], ['styles']

  ## Coffee
  gulp.watch ["#{SRC}/*.coffee"], ['scripts']

  gulp.watch [
    "#{DIST}/*.js",
    "#{DIST}/*.css",
    './demo/*'
  ], ['pack', server.notify]


gulp.task 'server', ->
  server.run ['server.js'], {}, 35728


gulp.task 'pack', ->
  gulp.src ["#{DIST}/app.js", "#{DIST}/templates.js"]
    .pipe concat 'dist.js'
    .pipe gulp.dest DIST


gulp.task 'default', [
  'scripts'
  'server'
  'styles'
  'templates'
  'pack'
  'watch'
]

