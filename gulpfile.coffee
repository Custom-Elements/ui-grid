gulp = require 'gulp'
less = require 'gulp-less'  
rename = require 'gulp-rename'
vulcanize = require 'gulp-vulcanize'
replace = require 'gulp-replace'
concat = require 'gulp-concat'
coffee = require 'gulp-coffee'
gutil = require 'gulp-util'
sourcemaps = require 'gulp-sourcemaps'
rm = require 'gulp-rm'

src ='./src'
dest = 'build/'

gulp.task 'litcoffee', ->
  gulp.src 'src/*.litcoffee'
    .pipe sourcemaps.init()
    .pipe coffee({bare: true}).on('error', gutil.log)
    .pipe sourcemaps.write()
    .pipe rename extname: '.js'
    .pipe gulp.dest dest    

gulp.task 'less', ->
  gulp.src 'src/*.less'
    .pipe sourcemaps.init()
    .pipe less()
    .pipe sourcemaps.write()
    .pipe gulp.dest dest

gulp.task 'rename', ['litcoffee'], ->
  gulp.src 'src/*.html'
    .pipe replace('.litcoffee', '.js')    
    .pipe replace('.less', '.css')    
    .pipe gulp.dest dest

gulp.task 'vulcanize', ['rename', 'less'], ->
  gulp.src 'build/*.html'
    .pipe vulcanize({ dest: dest, strip: true, inline: true })
    .pipe gulp.dest dest

gulp.task 'prepare-build', ['vulcanize'], ->
  gulp.src ['build/*.css', 'build/*.js']
    .pipe rm()

gulp.task 'clean', ->
  gulp.src 'build/*'
    .pipe rm()

gulp.task 'default', ['prepare-build']
gulp.task 'watch', -> 
  gulp.watch("#{src}/**", ['prepare-build'])