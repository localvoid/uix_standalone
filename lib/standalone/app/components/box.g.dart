// GENERATED CODE - DO NOT MODIFY BY HAND
// 2015-03-30T10:15:20.159Z

part of uix_standalone.app.component.box;

// **************************************************************************
// Generator: UixGenerator
// Target: class Box
// **************************************************************************

Box createBox([BoxData data, List<VNode> children, Component parent]) {
  return new Box()
    ..parent = parent
    ..data = data
    ..children = children;
}
VNode vBox({BoxData data, Object key, String type, Map<String, String> attrs,
    Map<String, String> style, List<String> classes,
    List<VNode> children}) => new VNode.component(createBox,
    flags: VNode.componentFlag,
    key: key,
    data: data,
    type: type,
    attrs: attrs,
    style: style,
    classes: classes,
    children: children);
