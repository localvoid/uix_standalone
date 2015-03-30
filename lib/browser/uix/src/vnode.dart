// Copyright (c) 2015, the uix project authors. Please see the AUTHORS file for
// details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library uix.src.vnode;

import 'dart:html' as html;
import 'dart:collection';
import 'assert.dart';
import 'vcontext.dart';
import 'component.dart';

class VNode {
  static const int textFlag = 1;
  static const int elementFlag = 1 << 1;
  static const int componentFlag = 1 << 2;
  static const int rootFlag = 1 << 3;
  static const int svgFlag = 1 << 4;

  final int flags;
  final Object key;
  final dynamic tag;
  dynamic data;
  String type;
  Map<String, String> attrs;
  Map<String, String> style;
  List<String> classes;
  List<VNode> children;
  html.Node ref;
  Component cref;

  VNode(this.flags, {this.key, this.tag, this.data, this.type, this.attrs, this.style,
    this.classes, this.children});

  VNode.text(this.data, {this.key})
    : flags = textFlag,
    tag = null;

  VNode.element(this.tag, {this.key, this.type, this.attrs, this.style,
    this.classes, this.children})
    : flags = elementFlag;

  VNode.svgElement(this.tag, {this.key, this.type, this.attrs, this.style,
    this.classes, this.children})
    : flags = elementFlag | svgFlag;

  VNode.component(this.tag, {this.flags: componentFlag, this.key, this.data,
    this.type, this.attrs, this.style, this.classes, this.children});

  VNode.root({this.type, this.attrs, this.style, this.classes, this.children})
    : flags = rootFlag, key = null, tag = null;

  bool sameType(VNode other) => (flags == other.flags && tag == other.tag);

  VNode call(c) {
    if (c is List) {
      children = c;
    } else if (c is Iterable) {
      children = c.toList();
    } else if (c is String) {
      children = [new VNode.text(c)];
    } else {
      children = [c];
    }
    return this;
  }

  void create(VContext context) {
    if ((flags & textFlag) != 0) {
      ref = new html.Text(data);
    } else if ((flags & elementFlag) != 0) {
      if ((flags & svgFlag) == 0) {
        ref = html.document.createElement(tag);
      } else {
        ref = html.document.createElementNS('http://www.w3.org/2000/svg', tag);
      }
    } else if ((flags & componentFlag) != 0) {
      cref = (tag as componentConstructor)(data, children, context);
      cref.create();
      cref.init();
      ref = cref.element;
    }
  }

  void mount(html.Node node, VContext context) {
    ref = node;

    if ((flags & componentFlag) != 0) {
      cref = (tag as componentConstructor)(data, children, context);
      cref.mount(node);
      cref.init();
      if (context.isAttached) {
        attached();
      }
      cref.update();
    } else {
      if ((flags & elementFlag) != 0) {
        String className = type;
        if (classes != null) {
          final classesString = classes.join(' ');
          className = className == null ? classesString : className + ' ' + classesString;
        }
        if (className != null) {
          data = className;
        }
      }
      if (children != null && children.length > 0) {
        html.Node child = node.childNodes.first;
        for (int i = 0; i < children.length; i++) {
          children[i].mount(child, context);
          child = child.nextNode;
        }
      }
    }
  }

  void render(VContext context) {
    if ((flags & (elementFlag | componentFlag | rootFlag)) != 0) {
      final html.Element r = ref;

      if (attrs != null) {
        attrs.forEach((k, v) {
          r.attributes[k] = v;
        });
      }

      if (style != null) {
        style.forEach((k, v) {
          r.style.setProperty(k, v);
        });
      }

      if ((flags & (elementFlag | componentFlag)) != 0) {
        String className = type;
        if (classes != null) {
          final classesString = classes.join(' ');
          className = className == null ? classesString : className + ' ' + classesString;
        }
        if (className != null) {
          if ((flags & elementFlag) != 0) {
            data = className;
          }
          r.className = className;
        }
      } else {
//        html.DomTokenList classList;
        html.CssClassSet classList;

        if (type != null) {
//          classList = r.classList;
          classList = r.classes;
          classList.add(type);
        }

        if (classes != null) {
          if (classList == null) {
//            classList = r.classList;
            classList = r.classes;
          }
          for (var i = 0; i < classes.length; i++) {
            classList.add(classes[i]);
          }
        }
      }

      if ((flags & componentFlag) != 0) {
        cref.update();
      } else {
        if (children != null) {
          final bool attached = context.isAttached;
          for (var i = 0; i < children.length; i++) {
            insertChild(children[i], null, context, attached);
          }
        }
      }
    }
  }

  void update(VNode other, VContext context) {
    assert(invariant(other.ref == null || identical(ref, other.ref), 'VNode objects cannot be reused'));
    other.ref = ref;
    if ((flags & textFlag) != 0) {
      if (data != other.data) {
        ref.text = other.data;
      }
    } else if ((flags & (elementFlag | componentFlag | rootFlag)) !=
    0) {
      final html.Element r = ref;

      if (!identical(attrs, other.attrs)) {
        updateAttrs(attrs, other.attrs, r.attributes);
      }

      if (!identical(style, other.style)) {
        updateStyle(style, other.style, r.style);
      }

      if ((flags & elementFlag) != 0) {
        if (!identical(classes, other.classes)) {
          if (other.data == null) {
            String className = other.type;
            if (other.classes != null) {
              final classesString = other.classes.join(' ');
              className = className == null ? classesString : className + ' ' + classesString;
            }
            other.data = className;
          }
          if ((data as String) != (other.data as String)) {
            if (other.data == null) {
              r.className = '';
            } else {
              r.className = (other.data as String);
            }
          }
        } else {
          other.data = data;
        }
      } else if (!identical(classes, other.classes)) {
//        updateClasses(classes, other.classes, r.classList);
        updateClasses(classes, other.classes, r.classes);
      }

      if ((flags & componentFlag) != 0) {
        other.cref = cref;
        cref.data = other.data;
        cref.children = other.children;
        cref.update();
      } else {
        if (!identical(children, other.children)) {
          updateChildren(this, children, other.children, context);
        }
      }
    }
  }

  void insertChild(VNode node, VNode next, VContext context, bool attached) {
    final nextRef = next == null ? null : next.ref;
    node.create(context);
    ref.insertBefore(node.ref, nextRef);
    if (attached) {
      node.attached();
    }
    node.render(context);
  }

  void moveChild(VNode node, VNode next) {
    final nextRef = next == null ? null : next.ref;
    ref.insertBefore(node.ref, nextRef);
  }

  void removeChild(VNode node, bool attached) {
    node.ref.remove();
    node.dispose();
  }
  void dispose() {
    if ((flags & componentFlag) != 0) {
      cref.dispose();
    } else if (children != null) {
      for (var i = 0; i < children.length; i++) {
        children[i].dispose();
      }
    }
  }

  void attach() {
    attached();
    if (((flags & componentFlag) == 0) && (children != null)) {
      for (var i = 0; i < children.length; i++) {
        children[i].attach();
      }
    }
  }

  void detach() {
    if (((flags & componentFlag) == 0) && (children != null)) {
      for (var i = 0; i < children.length; i++) {
        children[i].detach();
      }
    }
    detached();
  }

  void attached() {
    if ((flags & componentFlag) != 0) {
      cref.attach();
    }
  }

  void detached() {
    if ((flags & componentFlag) != 0) {
      cref.detach();
    }
  }

  String toHtmlString() {
    final b = new StringBuffer();
    writeHtmlString(b);
    return b.toString();
  }

  void writeHtmlString(StringBuffer b) {
    if ((flags & textFlag) != 0) {
      b.write(data as String);
    } else if ((flags & elementFlag) != 0) {
      b.write('<$tag');
      if (attrs != null) {
        writeAttrsToHtmlString(b, attrs);
      }
      if (type != null || (classes != null && classes.isNotEmpty)) {
        b.write(' class="');
        if (type != null) {
          b.write(type);
        }
        if (classes != null && classes.isNotEmpty) {
          if (type != null) {
            b.write(' ');
          }
          writeClassesToHtmlString(b, classes);
        }
        b.write('"');
      }
      if (style != null && style.isNotEmpty) {
        b.write(' style="');
        writeStyleToHtmlString(b, style);
        b.write('"');
      }
      b.write('>');
      if (children != null) {
        for (var i = 0; i < children.length; i++) {
          children[i].writeHtmlString(b);
        }
      }
      b.write('</$tag>');
    } else if ((flags & componentFlag) != 0) {
      return cref.writeHtmlString(b, this);
    }
  }
}

void updateChildren(VNode parent, List<VNode> a, List<VNode> b, VContext context) {
  final bool attached = context.isAttached;
  if (a != null && a.isNotEmpty) {
    if (b == null || b.isEmpty) {
      // when [b] is empty, it means that all children from list [a] were
      // removed
      for (int i = 0; i < a.length; i++) {
        parent.removeChild(a[i], attached);
      }
    } else {
      if (a.length == 1 && b.length == 1) {
        // fast path when [a] and [b] have just 1 child
        //
        // if both lists have child with the same key, then just diff them,
        // otherwise return patch with [a] child removed and [b] child
        // inserted
        final VNode aNode = a.first;
        final VNode bNode = b.first;

        if ((aNode.key == null && aNode.sameType(bNode)) ||
        aNode.key != null && aNode.key == bNode.key) {
          aNode.update(bNode, context);
        } else {
          parent.removeChild(aNode, attached);
          parent.insertChild(bNode, null, context, attached);
        }
      } else if (a.length == 1) {
        // fast path when [a] have 1 child
        final aNode = a.first;

        // implicit keys
        if (aNode.key == null) {
          int i = 0;
          bool updated = false;
          while (i < b.length) {
            final VNode bNode = b[i++];
            if (aNode.sameType(bNode)) {
              aNode.update(bNode, context);
              updated = true;
              break;
            }
            parent.insertChild(bNode, aNode, context, attached);
          }

          if (!updated) {
            parent.removeChild(aNode, attached);
          } else {
            while (i < b.length) {
              parent.insertChild(b[i++], null, context, attached);
            }
          }
        } else {
          int i = 0;
          bool updated = false;
          while (i < b.length) {
            final VNode bNode = b[i++];
            if (aNode.key == bNode.key) {
              aNode.update(bNode, context);
              updated = true;
              break;
            }
            parent.insertChild(bNode, aNode, context, attached);
          }

          if (!updated) {
            parent.removeChild(aNode, attached);
          } else {
            while (i < b.length) {
              parent.insertChild(b[i++], null, context, attached);
            }
          }
        }
      } else if (b.length == 1) {
        // fast path when [b] have 1 child
        final bNode = b.first;

        // implicit keys
        if (bNode.key == null) {
          int i = 0;
          bool updated = false;
          while (i < a.length) {
            final VNode aNode = a[i++];
            if (aNode.sameType(bNode)) {
              aNode.update(bNode, context);
              updated = true;
              break;
            }
            parent.removeChild(aNode, attached);
          }

          if (!updated) {
            parent.insertChild(bNode, null, context, attached);
          } else {
            while (i < a.length) {
              parent.removeChild(a[i++], attached);
            }
          }
        } else {
          int i = 0;
          bool updated = false;
          while (i < a.length) {
            final VNode aNode = a[i++];
            if (aNode.key == bNode.key) {
              aNode.update(bNode, context);
              updated = true;
              break;
            }
            parent.removeChild(aNode, attached);
          }

          if (!updated) {
            parent.insertChild(bNode, null, context, attached);
          } else {
            while (i < a.length) {
              parent.removeChild(a[i++], attached);
            }
          }
        }
      } else {
        // both [a] and [b] have more then 1 child, so we should handle
        // more complex situations with inserting/removing and repositioning
        // children.
        if (a.first.key == null) {
          return _updateImplicitChildren(parent, a, b, context, attached);
        }
        return _updateExplicitChildren(parent, a, b, context, attached);
      }
    }
  } else if (b != null && b.length > 0) {
    // all children from list [b] were inserted
    for (int i = 0; i < b.length; i++) {
      parent.insertChild(b[i], null, context, attached);
    }
  }
}

void _updateImplicitChildren(VNode parent, List<VNode> a, List<VNode> b, VContext context, bool attached) {
  int aStart = 0;
  int bStart = 0;
  int aEnd = a.length - 1;
  int bEnd = b.length - 1;

  // Update nodes with the same type at the beginning.
  while (aStart <= aEnd && bStart <= bEnd) {
    final aNode = a[aStart];
    final bNode = b[bStart];

    if (!aNode.sameType(bNode)) {
      break;
    }

    aStart++;
    bStart++;

    aNode.update(bNode, context);
  }

  // Update nodes with the same type at the end.
  while (aStart <= aEnd && bStart <= bEnd) {
    final aNode = a[aEnd];
    final bNode = b[bEnd];

    if (!aNode.sameType(bNode)) {
      break;
    }

    aEnd--;
    bEnd--;

    aNode.update(bNode, context);
  }

  // Iterate through the remaining nodes and if they have the same
  // type, then update, otherwise just remove the old node and insert
  // the new one.
  while (aStart <= aEnd && bStart <= bEnd) {
    final aNode = a[aStart++];
    final bNode = b[bStart++];
    if (aNode.sameType(bNode)) {
      aNode.update(bNode, context);
    } else {
      parent.insertChild(bNode, aNode, context, attached);
      parent.removeChild(aNode, attached);
    }
  }

  // All nodes from [a] are updated, insert the rest from [b].
  while (aStart <= aEnd) {
    parent.removeChild(a[aStart++], attached);
  }

  final nextPos = bEnd + 1;
  final next = nextPos < b.length ? b[nextPos].ref : null;

  // All nodes from [b] are updated, remove the rest from [a].
  while (bStart <= bEnd) {
    parent.insertChild(b[bStart++], next, context, attached);
  }
}

void _updateExplicitChildren(VNode parent, List<VNode> a, List<VNode> b, VContext context, bool attached) {
  int aStart = 0;
  int bStart = 0;
  int aEnd = a.length - 1;
  int bEnd = b.length - 1;

  var aStartNode = a[aStart];
  var bStartNode = b[bStart];
  var aEndNode = a[aEnd];
  var bEndNode = b[bEnd];

  bool stop = false;

  // Algorithm that works on simple cases with basic list
  // transformations.
  //
  // It tries to reduce the diff problem by simultaneously iterating
  // from the beginning and the end of both lists, if keys are the
  // same, they're updated, if node is moved from the beginning to the
  // end of the current cursor positions or vice versa it just
  // performs move operation and continues to reduce the diff problem.
  outer: do {
    stop = true;

    // Update nodes with the same key at the beginning.
    while (aStartNode.key == bStartNode.key) {
      aStartNode.update(bStartNode, context);

      aStart++;
      bStart++;
      if (aStart > aEnd || bStart > bEnd) {
        break outer;
      }

      aStartNode = a[aStart];
      bStartNode = b[bStart];

      stop = false;
    }

    // Update nodes with the same key at the end.
    while (aEndNode.key == bEndNode.key) {
      aEndNode.update(bEndNode, context);

      aEnd--;
      bEnd--;
      if (aStart > aEnd || bStart > bEnd) {
        break outer;
      }

      aEndNode = a[aEnd];
      bEndNode = b[bEnd];

      stop = false;
    }

    // Move nodes from left to right.
    while (aStartNode.key == bEndNode.key) {
      aStartNode.update(bEndNode, context);

      final nextPos = bEnd + 1;
      final next = nextPos < b.length ? b[nextPos] : null;
      parent.moveChild(bEndNode, next);

      aStart++;
      bEnd--;
      if (aStart > aEnd || bStart > bEnd) {
        break outer;
      }

      aStartNode = a[aStart];
      bEndNode = b[bEnd];

      stop = false;
      continue outer;
    }

    // Move nodes from right to left.
    while (aEndNode.key == bStartNode.key) {
      aEndNode.update(bStartNode, context);

      parent.moveChild(aEndNode, a[aStart]);

      aEnd--;
      bStart++;
      if (aStart > aEnd || bStart > bEnd) {
        break outer;
      }

      aEndNode = a[aEnd];
      bStartNode = b[bStart];

      stop = false;
    }
  } while (!stop && aStart <= aEnd && bStart <= bEnd);

  if (aStart > aEnd) {
    // All nodes from [a] are updated, insert the rest from [b].
    final nextPos = bEnd + 1;
    final next = nextPos < b.length ? b[nextPos] : null;
    while (bStart <= bEnd) {
      parent.insertChild(b[bStart++], next, context, attached);
    }
  } else if (bStart > bEnd) {
    // All nodes from [b] are updated, remove the rest from [a].
    while (aStart <= aEnd) {
      parent.removeChild(a[aStart++], attached);
    }
  } else {
    // Perform more complex update algorithm on the remaining nodes.
    //
    // We start by marking all nodes from [b] as inserted, then we try
    // to find all removed nodes and simultaneously perform updates on
    // the nodes that exists in both lists and replacing "inserted"
    // marks with the position of the node from the list [b] in list [a].
    // Then we just need to perform slightly modified LIS algorith,
    // that ignores "inserted" marks and find common subsequence and
    // move all nodes that doesn't belong to this subsequence, or
    // insert if they have "inserted" mark.
    final aLength = aEnd - aStart + 1;
    final bLength = bEnd - bStart + 1;

    // -1 value means that it should be inserted.
    final sources = new List<int>.filled(bLength, -1);

    var moved = false;
    var removeOffset = 0;

    // when both lists are small, we are using naive O(M*N) algorithm to
    // find removed children.
    if (aLength * bLength <= 16) {
      var lastTarget = 0;

      for (var i = aStart; i <= aEnd; i++) {
        bool removed = true;
        final aNode = a[i];

        for (var j = bStart; j <= bEnd; j++) {
          final bNode = b[j];
          if (aNode.key == bNode.key) {
            sources[j - bStart] = i;

            if (lastTarget > j) {
              moved = true;
            } else {
              lastTarget = j;
            }

            aNode.update(bNode, context);

            removed = false;
            break;
          }
        }

        if (removed) {
          parent.removeChild(aNode, attached);
          removeOffset++;
        }
      }
    } else {
      final keyIndex = new HashMap<Object, int>();
      var lastTarget = 0;

      for (var i = bStart; i <= bEnd; i++) {
        final node = b[i];
        keyIndex[node.key] = i;
      }

      for (var i = aStart; i <= aEnd; i++) {
        final aNode = a[i];
        final j = keyIndex[aNode.key];
        if (j != null) {
          final bNode = b[j];
          sources[j - bStart] = i;

          if (lastTarget > j) {
            moved = true;
          } else {
            lastTarget = j;
          }

          aNode.update(bNode, context);
        } else {
          parent.removeChild(aNode, attached);
          removeOffset++;
        }
      }
    }

    if (moved) {
      final seq = _lis(sources);
      var j = seq.length - 1;

      // All modifications are performed from right to left, so we
      // can use insertBefore method and use reference to the html
      // element from the next VNode. All Nodes on the right side
      // should be in the correct state.
      for (var i = bLength - 1; i >= 0; i--) {
        if (sources[i] == -1) {
          final pos = i + bStart;
          final node = b[pos];
          final nextPos = pos + 1;
          final next = nextPos < b.length ? b[nextPos] : null;
          parent.insertChild(node, next, context, attached);
        } else {
          if (j < 0 || i != seq[j]) {
            final pos = i + bStart;
            final node = a[sources[i]];
            final nextPos = pos + 1;
            final next = nextPos < b.length ? b[nextPos] : null;
            parent.moveChild(node, next);
          } else {
            j--;
          }
        }
      }
    } else if (aLength - removeOffset != bLength) {
      for (var i = bLength - 1; i >= 0; i--) {
        if (sources[i] == -1) {
          final pos = i + bStart;
          final node = b[pos];
          final nextPos = pos + 1;
          final next = nextPos < b.length ? b[nextPos] : null;
          parent.insertChild(node, next, context, attached);
        }
      }
    }
  }
}

/// Algorithm that finds longest increasing subsequence. With one little
/// modification that it ignores items with -1 value, they're representing
/// items that doesn't exist in the old list.
///
/// It is used to find minimum number of move operations in children list.
///
/// http://en.wikipedia.org/wiki/Longest_increasing_subsequence
List<int> _lis(List<int> a) {
  final p = new List<int>.from(a, growable: false);
  final result = [0];

  for (var i = 0; i < a.length; i++) {
    if (a[i] == -1) {
      continue;
    }
    if (a[result.last] < a[i]) {
      p[i] = result.last;
      result.add(i);
      continue;
    }

    var u = 0;
    var v = result.length - 1;
    while (u < v) {
      int c = (u + v) ~/ 2;

      if (a[result[c]] < a[i]) {
        u = c + 1;
      } else {
        v = c;
      }
    }

    if (a[i] < a[result[u]]) {
      if (u > 0) {
        p[i] = result[u - 1];
      }

      result[u] = i;
    }
  }
  var u = result.length;
  var v = result.last;

  while (u-- > 0) {
    result[u] = v;
    v = p[v];
  }

  return result;
}

/// Find changes between maps [a] and [b] and apply this changes to CssStyleDeclaration [n].
void updateStyle(Map a, Map b, html.CssStyleDeclaration n) {
  if (a != null && a.length > 0) {
    if (b == null || b.length == 0) {
      // all keys removed
      for (final i in a.keys) {
        n.removeProperty(i);
      }
    } else {
      // find all modified and removed
      a.forEach((key, value) {
        final bValue = b[key];
        if (bValue == null) {
          n.removeProperty(key);
        } else if (value != bValue) {
          n.setProperty(key, bValue);
        }
      });

      // find all inserted
      b.forEach((key, value) {
        if (!a.containsKey(key)) {
          n.setProperty(key, value);
        }
      });
    }
  } else if (b != null && b.length > 0) {
    // all keys inserted
    b.forEach((key, value) {
      n.setProperty(key, value);
    });
  }
}

/// Find changes between maps [a] and [b] and apply this changes to map [n].
void updateAttrs(Map a, Map b, Map n) {
  if (a != null && a.length > 0) {
    if (b == null || b.length == 0) {
      // all keys removed
      for (final k in a.keys) {
        n.remove(k);
      }
    } else {
      // find all modified and removed
      a.forEach((key, value) {
        final bValue = b[key];
        if (bValue == null) {
          n.remove(key);
        } else if (value != bValue) {
          n[key] = bValue;
        }
      });

      // find all inserted
      b.forEach((key, value) {
        if (!a.containsKey(key)) {
          n[key] = value;
        }
      });
    }
  } else if (b != null && b.length > 0) {
    // all keys inserted
    n.addAll(b);
  }
}

/// Find changes between Lists [a] and [b] and apply this changes to Set [classList].
// TODO: https://code.google.com/p/dart/issues/detail?id=23012
//void updateClasses(List<String> a, List<String> b, html.DomTokenList classList) {
void updateClasses(List<String> a, List<String> b, html.CssClassSet classList) {
  if (a != null && a.length != 0) {
    if (b == null || b.length == 0) {
      for (int i = 0; i < a.length; i++) {
        classList.remove(a[i]);
      }
    } else {
      if (a.length == 1 && b.length == 1) {
        final String aItem = a[0];
        final String bItem = b[0];
        if (aItem != bItem) {
          classList.remove(aItem);
          classList.add(bItem);
        }
      } else if (a.length == 1) {
        final String aItem = a[0];
        int unchangedPosition = -1;
        for (int i = 0; i < b.length; i++) {
          final String bItem = b[i];
          if (aItem == bItem) {
            unchangedPosition = i;
            break;
          } else {
            classList.add(bItem);
          }
        }
        if (unchangedPosition != -1) {
          for (int i = unchangedPosition + 1; i < b.length; i++) {
            classList.add(b[i]);
          }
        } else {
          classList.remove(aItem);
        }
      } else if (b.length == 1) {
        final String bItem = b[0];
        int unchangedPosition = -1;
        for (int i = 0; i < a.length; i++) {
          final String aItem = a[i];
          if (aItem == bItem) {
            unchangedPosition = i;
            break;
          } else {
            classList.remove(aItem);
          }
        }
        if (unchangedPosition != -1) {
          for (int i = unchangedPosition + 1; i < a.length; i++) {
            classList.remove(a[i]);
          }
        } else {
          classList.add(bItem);
        }
      } else {
        int aStart = 0;
        int bStart = 0;
        int aEnd = a.length - 1;
        int bEnd = b.length - 1;

        while (aStart <= aEnd && bStart <= bEnd) {
          if (a[aStart] != b[bStart]) {
            break;
          }
          aStart++;
          bStart++;
        }
        while (aStart <= aEnd && bStart <= bEnd) {
          if (a[aEnd] != b[bEnd]) {
            break;
          }
          aEnd--;
          bEnd--;
        }

        final int aLength = aEnd - aStart + 1;
        final int bLength = bEnd - bStart + 1;

        if (aLength * bLength <= 16) {
          final List<bool> visited = new List<bool>(bLength);

          for (int i = aStart; i <= aEnd; i++) {
            final String aItem = a[i];
            bool removed = true;

            for (int j = bStart; j <= bEnd; j++) {
              final String bItem = b[j];

              if (aItem == bItem) {
                removed = false;
                visited[j - bStart] = true;
                break;
              }
            }
            if (removed) {
              classList.remove(aItem);
            }
          }
          for (int i = bStart; i <= bEnd; i++) {
            if (visited[i - bStart] != true) {
              classList.add(b[i]);
            }
          }
        } else {
          final HashMap<String, bool> bIndex = new HashMap<String, bool>();

          for (int i = bStart; i <= bEnd; i++) {
            bIndex[b[i]] = false;
          }

          for (int i = aStart; i <= aEnd; i++) {
            final String aItem = a[i];

            if (!bIndex.containsKey(aItem)) {
              classList.remove(aItem);
            } else {
              bIndex[aItem] = true;
            }
          }

          bIndex.forEach((k, v) {
            if (v == false) {
              classList.add(k);
            }
          });
        }
      }
    }
  } else if (b != null && b.length > 0) {
    for (int i = 0; i < b.length; i++) {
      classList.add(b[i]);
    }
  }
}
void writeAttrsToHtmlString(StringBuffer b, Map<String, String> attrs) {
  attrs.forEach((k, v) {
    b.write(' $k="$v"');
  });
}

void writeStyleToHtmlString(StringBuffer b, Map<String, String> attrs) {
  attrs.forEach((k, v) {
    b.write('$k: $v;');
  });
}

void writeClassesToHtmlString(StringBuffer b, List<String> classes) {
  b.write(classes.first);
  for (var i = 1; i < classes.length; i++) {
    b.write(' ');
    b.write(classes[i]);
  }
}
