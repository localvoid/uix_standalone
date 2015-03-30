library web.main;

import 'dart:html' as html;
import 'package:uix_standalone/browser/uix/uix.dart';
import 'package:uix_standalone/browser/app/app.dart';

const int I = 0;
const int N = 100;

final List<BoxData> boxes = [];

void main() {
  initUix();

  for (var i = 0; i < N; i++) {
    boxes.add(new BoxData());
  }

  mountComponent(createBoxList(boxes), html.querySelector('.BoxList'));
}
