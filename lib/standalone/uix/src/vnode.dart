// Copyright (c) 2015, the uix project authors. Please see the AUTHORS file for
// details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library uix.src.vnode;

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
    if ((flags & componentFlag) != 0) {
      cref = (tag as componentConstructor)(data, children, context);
      cref.init();
    }
  }

  void render(VContext context) {
    if ((flags & (elementFlag | componentFlag | rootFlag)) != 0) {
      if ((flags & componentFlag) != 0) {
        cref.update();
      } else {
        if (children != null) {
          final bool attached = context.isAttached;
          for (var i = 0; i < children.length; i++) {
            insertChild(children[i], context, attached);
          }
        }
      }
    }
  }

  void update(VNode other, VContext context) {
    if ((flags & componentFlag) != 0) {
      other.cref = cref;
      cref.data = other.data;
      cref.children = other.children;
      cref.update();
    } else if ((flags & (elementFlag | rootFlag)) != 0) {
      if (!identical(children, other.children)) {
        updateChildren(this, children, other.children, context);
      }
    }
  }

  void insertChild(VNode node, VContext context, bool attached) {
    node.create(context);
    if (attached) {
      node.attached();
    }
    node.render(context);
  }

  void removeChild(VNode node, bool attached) {
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
          parent.insertChild(bNode, context, attached);
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
            parent.insertChild(bNode, context, attached);
          }

          if (!updated) {
            parent.removeChild(aNode, attached);
          } else {
            while (i < b.length) {
              parent.insertChild(b[i++], context, attached);
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
            parent.insertChild(bNode, context, attached);
          }

          if (!updated) {
            parent.removeChild(aNode, attached);
          } else {
            while (i < b.length) {
              parent.insertChild(b[i++], context, attached);
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
            parent.insertChild(bNode, context, attached);
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
            parent.insertChild(bNode, context, attached);
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
      parent.insertChild(b[i], context, attached);
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
      parent.insertChild(bNode, context, attached);
      parent.removeChild(aNode, attached);
    }
  }

  // All nodes from [a] are updated, insert the rest from [b].
  while (aStart <= aEnd) {
    parent.removeChild(a[aStart++], attached);
  }

  // All nodes from [b] are updated, remove the rest from [a].
  while (bStart <= bEnd) {
    parent.insertChild(b[bStart++], context, attached);
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
    while (bStart <= bEnd) {
      parent.insertChild(b[bStart++], context, attached);
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

    var removeOffset = 0;

    // when both lists are small, we are using naive O(M*N) algorithm to
    // find removed children.
    if (aLength * bLength <= 16) {
      for (var i = aStart; i <= aEnd; i++) {
        bool removed = true;
        final aNode = a[i];

        for (var j = bStart; j <= bEnd; j++) {
          final bNode = b[j];
          if (aNode.key == bNode.key) {
            sources[j - bStart] = i;

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

          aNode.update(bNode, context);
        } else {
          parent.removeChild(aNode, attached);
          removeOffset++;
        }
      }
    }

    if (aLength - removeOffset != bLength) {
      for (var i = bLength - 1; i >= 0; i--) {
        if (sources[i] == -1) {
          final pos = i + bStart;
          final node = b[pos];
          parent.insertChild(node, context, attached);
        }
      }
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
