// Copyright (c) 2015, the uix project authors. Please see the AUTHORS file for
// details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library uix.src.utils;

import 'vnode.dart';
VNode vText(String data, {Object key}) => new VNode.text(data, key: key);

VNode vElement(String tag, {Object key, String type, Map<String, String> attrs,
  Map<String, String> style, List<String> classes, List<VNode> children}) =>
      new VNode.element(tag, key: key, type: type, attrs: attrs, style: style,
          classes: classes, children: children);

VNode vSvgElement(String tag, {Object key, String type, Map<String, String> attrs,
  Map<String, String> style, List<String> classes, List<VNode> children}) =>
      new VNode.svgElement(tag, key: key, type: type, attrs: attrs, style: style,
          classes: classes, children: children);

VNode vRoot({String type, Map<String, String> attrs, Map<String, String> style,
  List<String> classes, List<VNode> children}) =>
      new VNode.root(type: type, attrs: attrs, style: style,
          classes: classes, children: children);
