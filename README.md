# Isomorphic Dart Web Application built with uix library

Proof of Concept of building Isomorphic Dart Web Apps with simple
preprocessor. Unfortunately Dart doesn't support conditional
compilation natively, so it is an ugly solution.

## Code structure

- `src` - source code with preprocessor directives
- `lib` - automatically generated from `src`
- `server` - backend
- `web` - frontend

## Install

- `$ pub build`
- `$ dart ./server/main.dart`
