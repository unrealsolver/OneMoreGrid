gulp = require 'gulp'
server = require 'gulp-express'
coffee = require 'gulp-coffee'
concat = require 'gulp-concat'
jade = require 'gulp-jade'
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


gulp.task 'watch', ->
  ## Jade
  gulp.watch ["#{SRC}/*.jade"], ['templates']

  ## Coffee
  gulp.watch ["#{SRC}/*.coffee"], ['scripts']

  gulp.watch [
    "#{DIST}/*.js"
    './demo/index.html'
  ], server.notify


gulp.task 'server', ->
  server.run ['server.js']


gulp.task 'default', ['scripts', 'server', 'templates', 'watch']
