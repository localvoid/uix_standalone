'use strict';

var gulp = require('gulp');
var del = require('del');
var preprocess = require('gulp-preprocess');

gulp.task('clean', del.bind(null, ['./build']));

gulp.task('dart', function() {
  gulp.src('./src/**/*.dart')
    .pipe(preprocess({context: { }, extension: 'js'}))
    .pipe(gulp.dest('./lib/standalone'));

  gulp.src('./src/**/*.dart')
    .pipe(preprocess({context: { BROWSER: true }, extension: 'js'}))
    .pipe(gulp.dest('./lib/browser'));
});

gulp.task('default', ['dart']);
